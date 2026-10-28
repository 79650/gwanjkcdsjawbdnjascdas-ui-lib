-- Configs: every element with a Flag is saved to <Folder>/configs/<name>.json.
-- Writes are crash-safe (Util.writeAtomic): an interrupted save never leaves a broken profile, and a profile caught
-- half way is restored from its .tmp on the next read (Config.Recovered lists those, the window shows a toast).
-- Window.Config:Save(name), :Load(name), :Delete(name), :List(), :SetAutoLoad(name), :LoadAutoLoad()
local Util = require("util")

local HttpService = Util.Services.HttpService

local Config = {}
Config.__index = Config

-- True when the executor has every named file function.
local function can(...)
    local available = {
        isfolder = isfolder, makefolder = makefolder, writefile = writefile, readfile = readfile,
        isfile = isfile, delfile = delfile, listfiles = listfiles,
    }
    for _, name in ipairs({ ... }) do
        if type(available[name]) ~= "function" then return false end
    end
    return true
end
-- Windows can't create files named con / prn / aux / nul / com1-9 / lpt1-9, and paths must stay short
local RESERVED = { con = true, prn = true, aux = true, nul = true }
for i = 1, 9 do RESERVED["com" .. i] = true RESERVED["lpt" .. i] = true end
local function cleanName(name)
    name = tostring(name or ""):gsub("[^%w_%- ]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    name = name:sub(1, 60):gsub("%s+$", "")
    if RESERVED[name:lower()] then name = name .. "_" end
    return name
end

function Config.new(window, folder)
    local self = setmetatable({ window = window, folder = cleanName(folder) ~= "" and cleanName(folder) or "QustahUI" }, Config)
    self.path = self.folder .. "/configs"
    self.pending = {}  -- values for flags whose element does not exist yet (applied when it is created)
    self.Defaults = {} -- each flag's starting value (recorded when its element is created)
    self.Custom = {}   -- script data saved with the profile: Config:SetData(key, value)
    return self
end

-- Called by Window:_register once the element is fully built: remembers its default and applies a pending value.
function Config:_elementReady(flag, element)
    if self.Defaults[flag] == nil then
        local ok, value = pcall(element._save, element)
        if ok and value ~= nil then self.Defaults[flag] = value end
    end
    -- the reset button compares against this default
    if element._initReset then pcall(element._initReset, element, self.Defaults[flag]) end
    local value = self.pending[flag]
    if value ~= nil then
        self.pending[flag] = nil
        pcall(element._load, element, value)
    end
end

-- Custom data: anything JSON can hold (tables of numbers / strings / booleans), saved and loaded with profiles.
--   Window.Config:SetData("waypoints", { ... }), :GetData("waypoints"), :OnDataLoaded(function(custom) end)
function Config:SetData(key, value) self.Custom[tostring(key)] = value end
function Config:GetData(key) return self.Custom[tostring(key)] end
function Config:OnDataLoaded(callback)
    self._dataListeners = self._dataListeners or {}
    table.insert(self._dataListeners, callback)
end
function Config:_setCustom(custom)
    self.Custom = type(custom) == "table" and custom or {}
    for _, listener in ipairs(self._dataListeners or {}) do Util.safe(listener, self.Custom) end
end

-- Per-game profiles: Config:SetPerGame("Game" | "Place" | false) keeps profiles, their notes and the autoload in
-- <Folder>/configs/<GameId or PlaceId>/ (CreateWindow({ PerGame = "Game" }) or Settings › Profiles).
function Config:SetPerGame(mode)
    if mode == true then mode = "Game" end
    self.perGame = (mode == "Game" or mode == "Place") and mode or nil
    local id = self.perGame == "Place" and game.PlaceId or (self.perGame == "Game" and game.GameId) or nil
    self.path = self.folder .. "/configs" .. (id and ("/" .. tostring(id)) or "")
    self:_setActive(nil, nil)
end
-- files that belong to the current profile scope (shared folder or the game's folder)
function Config:_scopeFile(name)
    return (self.perGame and self.path or self.folder) .. "/" .. name
end

function Config:_ensure()
    if not can("isfolder", "makefolder") then return false end
    if not isfolder(self.folder) then makefolder(self.folder) end
    if not isfolder(self.folder .. "/configs") then makefolder(self.folder .. "/configs") end
    if not isfolder(self.path) then makefolder(self.path) end
    return true
end

-- Returns true, or false and the reason.
function Config:Save(name)
    name = cleanName(name)
    if name == "" then return false, "Empty config name" end
    if not can("writefile") then return false, "writefile is not available" end
    self:_ensure()
    local data = { version = 1, flags = self:Snapshot(), custom = self.Custom }
    local ok, err = Util.writeAtomic(self.path .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    if not ok then return false, err end
    self:_setActive(name, data.flags)
    return true
end

-- Writes a profile from a flag table (Snapshot format) without touching the current values.
function Config:SaveFlags(name, flags, custom)
    name = cleanName(name)
    if name == "" then return false, "Empty config name" end
    if not can("writefile") then return false, "writefile is not available" end
    self:_ensure()
    local ok, err = Util.writeAtomic(self.path .. "/" .. name .. ".json", HttpService:JSONEncode({ version = 1, flags = flags or {}, custom = custom }))
    if not ok then return false, err end
    return true
end

-- Reads <file>; notes a recovery from an interrupted save.
function Config:_readFile(file, label)
    local data, info = Util.readJSON(file)
    if data and info == true then
        self.Recovered = self.Recovered or {}
        table.insert(self.Recovered, label or file)
        for _, listener in ipairs(self._recoverListeners or {}) do Util.safe(listener, label or file) end
    end
    return data, info
end
-- Config:OnRecovered(function(name) end): a file was restored from an interrupted save
function Config:OnRecovered(callback)
    self._recoverListeners = self._recoverListeners or {}
    table.insert(self._recoverListeners, callback)
end
function Config:_readProfile(name)
    if not can("readfile", "isfile") then return nil, "readfile is not available" end
    local data, problem = self:_readFile(self.path .. "/" .. name .. ".json", name)
    if not data then return nil, problem == "missing" and "Config not found" or "Config file is damaged" end
    if type(data.flags) ~= "table" then return nil, "Config file is damaged" end
    return data
end

function Config:Load(name)
    name = cleanName(name)
    local data, err = self:_readProfile(name)
    if not data then return false, err end
    local failed = self:Apply(data.flags)
    self:_setCustom(data.custom)
    self:_setActive(name, data.flags)
    if failed > 0 then return true, failed .. " setting(s) could not be applied" end
    return true
end

-- Reads a profile's flags without applying them.
function Config:Read(name)
    local data, err = self:_readProfile(cleanName(name))
    if not data then return nil, err end
    return data.flags, data.custom
end

-- The profile the current settings came from (nil = the script's defaults) and what it held.
-- Config.Active, Config:OnActiveChanged(fn), Config:Changes() -> number of settings that differ from it.
function Config:_setActive(name, flags)
    self.Active, self.ActiveFlags = name, flags
    for _, listener in ipairs(self._activeListeners or {}) do Util.safe(listener, name) end
end
function Config:OnActiveChanged(callback)
    self._activeListeners = self._activeListeners or {}
    table.insert(self._activeListeners, callback)
end
local function same(a, b)
    if type(a) == "number" and type(b) == "number" then return math.abs(a - b) < 1e-6 end
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    for key, value in pairs(a) do if not same(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end
Config.same = same
-- Settings that differ between the current values and a flag table (default: the active profile's).
function Config:Changes(flags)
    flags = flags or self.ActiveFlags or self.DefaultFlags or {}
    local count, names = 0, {}
    for flag, value in pairs(self:Snapshot()) do
        if flags[flag] ~= nil and not same(value, flags[flag]) then
            count = count + 1
            names[#names + 1] = flag
        end
    end
    return count, names
end

-- Share codes: "QUSTAH1:" .. base64(JSON { n = name, f = flags }).
function Config:Export(name)
    local flags, custom
    if name then flags, custom = self:Read(name) else flags, custom = self:Snapshot(), self.Custom end
    if not flags then return nil, "Config not found" end
    local data = { n = name or "Shared", f = flags }
    if type(custom) == "table" and next(custom) ~= nil then data.c = custom end
    return "QUSTAH1:" .. Util.base64encode(HttpService:JSONEncode(data))
end
-- Returns name, flags (nothing is saved or applied).
function Config:Decode(code)
    code = tostring(code or ""):gsub("%s", "")
    local body = code:match("^QUSTAH1:(.+)$")
    if not body then return nil, "Not a profile code" end
    local json = Util.base64decode(body)
    local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
    if not ok or type(data) ~= "table" or type(data.f) ~= "table" then return nil, "The code is damaged or cut off" end
    return cleanName(data.n) ~= "" and cleanName(data.n) or "Imported", data.f, data.c
end
-- A free name: "pvp", "pvp 2", "pvp 3"...
function Config:FreeName(name)
    name = cleanName(name)
    if name == "" or name:lower() == "default" then name = "Profile" end
    if not self:Exists(name) then return name end
    local index = 2
    while self:Exists(name .. " " .. index) do index = index + 1 end
    return name .. " " .. index
end

function Config:Delete(name)
    name = cleanName(name)
    if self.Active == name then self:_setActive(nil, nil) end
    if not can("delfile", "isfile") then return false, "delfile is not available" end
    local file = self.path .. "/" .. name .. ".json"
    if not isfile(file) then return false, "Config not found" end
    local ok, err = pcall(delfile, file)
    return ok, not ok and tostring(err) or nil
end

function Config:List()
    local names = {}
    if not can("listfiles", "isfolder") or not isfolder(self.path) then return names end
    local ok, files = pcall(listfiles, self.path)
    if not ok or type(files) ~= "table" then return names end
    local seen = {}
    for _, file in ipairs(files) do
        -- (a profile whose first save was cut off only has its .tmp: listed, restored when read)
        local path = tostring(file):gsub("\\", "/")
        local name = path:match("([^/]+)%.json$") or path:match("([^/]+)%.json%.tmp$")
        local parent = path:match("^(.*)/[^/]+$") or ""
        if name and not seen[name] and (parent == "" or parent:sub(-#self.path) == self.path) then
            seen[name] = true
            names[#names + 1] = name
        end
    end
    table.sort(names)
    return names
end

function Config:SetAutoLoad(name)
    if not can("writefile") then return false end
    self:_ensure()
    return Util.writeAtomic(self:_scopeFile("autoload.txt"), cleanName(name))
end
function Config:GetAutoLoad()
    if not can("readfile", "isfile") or not isfile(self:_scopeFile("autoload.txt")) then return nil end
    local ok, name = pcall(readfile, self:_scopeFile("autoload.txt"))
    name = ok and cleanName(name) or ""
    return name ~= "" and name or nil
end
-- Call once after the whole UI is built.
function Config:LoadAutoLoad()
    local name = self:GetAutoLoad()
    if name and self:Exists(name) then return self:Load(name) end
    return false, "No autoload config"
end

-- Window memory: position / size of the window and the floating panels, in <Folder>/window.json.
function Config:ReadMemory()
    return self:_readFile(self.folder .. "/window.json", "window") or {}
end
function Config:WriteMemory(data)
    if not can("writefile") then return false end
    self:_ensure()
    return Util.writeAtomic(self.folder .. "/window.json", HttpService:JSONEncode(data))
end

-- Any small JSON file in the folder (custom themes...): Config:ReadJSON("themes"), :WriteJSON("themes", data)
function Config:ReadJSON(name)
    return self:_readFile(self.folder .. "/" .. cleanName(name) .. ".json", cleanName(name)) or {}
end
function Config:WriteJSON(name, data)
    if not can("writefile") then return false end
    self:_ensure()
    return Util.writeAtomic(self.folder .. "/" .. cleanName(name) .. ".json", HttpService:JSONEncode(data))
end

-- Profiles keep extra info (when saved) in <Folder>/profiles.json.
function Config:ReadMeta()
    return self:_readFile(self:_scopeFile("profiles.json"), "profiles") or {}
end
function Config:WriteMeta(data)
    if not can("writefile") then return false end
    self:_ensure()
    return Util.writeAtomic(self:_scopeFile("profiles.json"), HttpService:JSONEncode(data))
end

-- Snapshot of every flag right now (used as the locked "Default" profile).
function Config:Snapshot()
    local data = {}
    for flag, value in pairs(self.pending) do data[flag] = value end -- not created yet: keep what was loaded
    for flag, element in pairs(self.window.flags) do
        local ok, value = pcall(element._save, element)
        if ok and value ~= nil then data[flag] = value end
    end
    return data
end
function Config:Apply(flags)
    local failed = 0
    for flag, value in pairs(flags or {}) do
        local element = self.window.flags[flag]
        if element and self.Defaults[flag] == nil then -- (a load right after building: remember the start value first)
            local ok, current = pcall(element._save, element)
            if ok and current ~= nil then self.Defaults[flag] = current end
        end
        if not element then
            self.pending[flag] = value -- applied when the element is created
        elseif not pcall(element._load, element, value) then
            failed = failed + 1
        end
    end
    return failed
end
function Config:Exists(name)
    name = cleanName(name)
    if not can("isfile") or name == "" then return false end
    local file = self.path .. "/" .. name .. ".json"
    return isfile(file) or isfile(file .. ".tmp")
end
function Config:Rename(old, new)
    old, new = cleanName(old), cleanName(new)
    if new == "" then return false, "Empty name" end
    if self:Exists(new) then return false, "A profile with that name exists" end
    if not can("readfile", "writefile", "delfile", "isfile") then return false, "File functions are not available" end
    local ok, text = pcall(readfile, self.path .. "/" .. old .. ".json")
    if not ok then return false, "Profile not found" end
    local written, err = Util.writeAtomic(self.path .. "/" .. new .. ".json", text)
    if not written then return false, err end
    pcall(delfile, self.path .. "/" .. old .. ".json")
    if self:GetAutoLoad() == old then self:SetAutoLoad(new) end
    if self.Active == old then self:_setActive(new, self.ActiveFlags) end
    return true
end
function Config:Copy(name, new)
    name, new = cleanName(name), cleanName(new)
    if self:Exists(new) then return false, "A profile with that name exists" end
    if not can("readfile", "writefile") then return false, "File functions are not available" end
    local ok, text = pcall(readfile, self.path .. "/" .. name .. ".json")
    if not ok then return false, "Profile not found" end
    return Util.writeAtomic(self.path .. "/" .. new .. ".json", text)
end
function Config:ClearAutoLoad()
    if can("delfile", "isfile") and isfile(self:_scopeFile("autoload.txt")) then pcall(delfile, self:_scopeFile("autoload.txt")) end
end

return Config
