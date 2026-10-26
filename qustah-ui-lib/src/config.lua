-- Configs: every element with a Flag is saved to <Folder>/configs/<name>.json.
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
local function cleanName(name)
    name = tostring(name or ""):gsub("[^%w_%- ]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    return name
end

function Config.new(window, folder)
    local self = setmetatable({ window = window, folder = cleanName(folder) ~= "" and cleanName(folder) or "QustahUI" }, Config)
    self.path = self.folder .. "/configs"
    return self
end

function Config:_ensure()
    if not can("isfolder", "makefolder") then return false end
    if not isfolder(self.folder) then makefolder(self.folder) end
    if not isfolder(self.path) then makefolder(self.path) end
    return true
end

-- Returns true, or false and the reason.
function Config:Save(name)
    name = cleanName(name)
    if name == "" then return false, "Empty config name" end
    if not can("writefile") then return false, "writefile is not available" end
    self:_ensure()
    local data = { version = 1, flags = {} }
    for flag, element in pairs(self.window.flags) do
        local ok, value = pcall(element._save, element)
        if ok and value ~= nil then data.flags[flag] = value end
    end
    local ok, err = pcall(writefile, self.path .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    if not ok then return false, tostring(err) end
    return true
end

function Config:Load(name)
    name = cleanName(name)
    if not can("readfile", "isfile") then return false, "readfile is not available" end
    local file = self.path .. "/" .. name .. ".json"
    if not isfile(file) then return false, "Config not found" end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(file)) end)
    if not ok or type(data) ~= "table" or type(data.flags) ~= "table" then return false, "Config file is damaged" end
    local failed = 0
    for flag, value in pairs(data.flags) do
        local element = self.window.flags[flag]
        if element then
            if not pcall(element._load, element, value) then failed = failed + 1 end
        end
    end
    if failed > 0 then return true, failed .. " setting(s) could not be applied" end
    return true
end

function Config:Delete(name)
    name = cleanName(name)
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
    for _, file in ipairs(files) do
        local name = tostring(file):gsub("\\", "/"):match("([^/]+)%.json$")
        if name then names[#names + 1] = name end
    end
    table.sort(names)
    return names
end

function Config:SetAutoLoad(name)
    if not can("writefile") then return false end
    self:_ensure()
    return pcall(writefile, self.folder .. "/autoload.txt", cleanName(name))
end
function Config:GetAutoLoad()
    if not can("readfile", "isfile") or not isfile(self.folder .. "/autoload.txt") then return nil end
    local ok, name = pcall(readfile, self.folder .. "/autoload.txt")
    name = ok and cleanName(name) or ""
    return name ~= "" and name or nil
end
-- Call once after the whole UI is built.
function Config:LoadAutoLoad()
    local name = self:GetAutoLoad()
    if name then return self:Load(name) end
    return false, "No autoload config"
end

return Config
