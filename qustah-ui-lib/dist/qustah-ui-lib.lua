-- qustah-ui-lib v1.1.0 | bundled from src/ by build.py - edit the source files, not this one.
-- local Lib = loadstring(game:HttpGet("<raw url>/dist/qustah-ui-lib.lua"))()
local __modules, __loaded = {}, {}
local function require(name)
    local loaded = __loaded[name]
    if loaded == nil then
        local module = __modules[name]
        if not module then error("[qustah-ui-lib] missing module: " .. tostring(name), 2) end
        loaded = module()
        __loaded[name] = loaded
    end
    return loaded
end

__modules["card"] = function()
-- A card: rounded panel with an optional title (accent dot + bold heading) that stacks its elements.
-- Every element constructor (Toggle, Slider, ...) is available as a method: card:Toggle({ ... }).
local Util = require("util")
local Theme = require("theme")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

local Card = {}
Card.Elements = {
    Toggle      = require("elements/toggle"),
    Slider      = require("elements/slider"),
    Dropdown    = require("elements/dropdown"),
    Keybind     = require("elements/keybind"),
    ColorPicker = require("elements/colorpicker"),
    Input       = require("elements/input"),
    Button      = require("elements/button"),
    Label       = require("elements/label"),
    Paragraph   = require("elements/paragraph"),
    Divider     = require("elements/divider"),
    Segment     = require("elements/segment"),
    Info        = require("elements/info"),
    Range       = require("elements/range"),
    PlayerList  = require("elements/playerlist"),
    ImagePicker = require("elements/imagepicker"),
    Swatches    = require("elements/swatches"),
    Graph       = require("elements/graph"),
}
Card.__index = function(_, key)
    local method = rawget(Card, key)
    if method ~= nil then return method end
    local constructor = Card.Elements[key]
    if constructor then
        return function(self, cfg)
            if type(cfg) == "string" then cfg = { Title = cfg } end
            return constructor(self, cfg or {})
        end
    end
    return nil
end

function Card.new(page, column, cfg, order)
    local self = setmetatable({ page = page, window = page.window, order = 0 }, Card)
    local frame = create("Frame", {
        Name = cfg.Title or "Card", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0, LayoutOrder = order or 0, Parent = column,
    })
    Theme.bind(frame, "BackgroundColor3", "card")
    corner(frame, 8)
    Theme.bind(stroke(frame), "Color", "line")
    Util.padding(frame, 14, 14, 8, 10)
    Util.list(frame, 4)
    if cfg.Title then
        -- accent dot with a soft glow + medium heading (Qustah card title)
        local head = create("Frame", { Name = "Heading", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 0, Parent = frame })
        for ring = 3, 0, -1 do
            local dot = create("Frame", {
                Name = ring == 0 and "Dot" or "Glow", Position = UDim2.fromOffset(-ring, 7 - ring), Size = UDim2.fromOffset(6 + ring * 2, 6 + ring * 2),
                BorderSizePixel = 0, BackgroundTransparency = ring == 0 and 0 or 0.91, Parent = head,
            })
            Theme.bind(dot, "BackgroundColor3", "accent")
            corner(dot, ring == 0 and 3 or 6)
        end
        local title = label(head, tostring(cfg.Title), 10, { Position = UDim2.fromOffset(13, 0), Size = UDim2.new(1, -13, 1, 0), Font = Enum.Font.GothamMedium })
        Theme.bind(title, "TextColor3", "heading")
        self.titleLabel = title
    end
    self.frame, self.body = frame, frame
    return self
end

-- Layout order for the next row (steps of 2 so a colour picker can open its panel right under its row).
function Card:_order()
    self.order = self.order + 2
    return self.order
end

-- card:Tabs({ "Main", "Extra" }) -> { Main = section, Extra = section }, selector
-- Sub-sections inside one card, switched with a capsule selector in the card header (or a row when the card
-- has no title). Each section works like a card: section:Toggle({...}).
function Card:Tabs(names, cfg)
    cfg = cfg or {}
    local holder
    if self.titleLabel then
        holder = create("Frame", { Name = "Tabs", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 1), Size = UDim2.new(0.6, 0, 0, 18), Parent = self.titleLabel.Parent })
        self.titleLabel.Size = UDim2.new(0.4, -13, 1, 0)
    else
        holder = create("Frame", { Name = "Tabs", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = self:_order(), Parent = self.body })
    end
    local layout = Util.list(holder, 4, Enum.FillDirection.Horizontal)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    local sections, buttons, current = {}, {}, nil
    local selector = {}
    local function render()
        for name, button in pairs(buttons) do
            local on = name == current
            Theme.tweenTo(button, "BackgroundColor3", on and "selected" or "input", 0.1)
            Theme.tweenTo(button, "TextColor3", on and "heading" or "muted", 0.1)
            sections[name].body.Visible = on
        end
    end
    function selector:Select(name)
        if not sections[name] then return end
        current = name
        render()
        if cfg.Callback then task.spawn(cfg.Callback, name) end
    end
    function selector:Get() return current end
    for index, name in ipairs(names) do
        name = tostring(name)
        local button = create("TextButton", {
            Name = name, AutoButtonColor = false, BorderSizePixel = 0, Text = name, TextSize = 9, Font = Enum.Font.GothamMedium,
            Size = UDim2.fromOffset(Util.textWidth(name, 9, Enum.Font.GothamMedium) + 16, 18), LayoutOrder = index, Parent = holder,
        })
        corner(button, 9)
        buttons[name] = button
        local body = create("Frame", { Name = "Section_" .. name, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = self:_order(), Visible = false, Parent = self.body })
        Util.list(body, 4)
        sections[name] = setmetatable({ page = self.page, window = self.window, order = 0, body = body, frame = self.frame }, Card)
        button.Activated:Connect(function() selector:Select(name) end)
    end
    current = tostring(cfg.Default or names[1])
    render()
    return sections, selector
end

function Card:SetTitle(text) if self.titleLabel then self.titleLabel.Text = tostring(text) end end
function Card:SetVisible(visible) self.frame.Visible = visible ~= false end

return Card
end

__modules["config"] = function()
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
    local failed = self:Apply(data.flags)
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

-- Window memory: position / size of the window and the floating panels, in <Folder>/window.json.
function Config:ReadMemory()
    if not can("readfile", "isfile") or not isfile(self.folder .. "/window.json") then return {} end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(self.folder .. "/window.json")) end)
    return ok and type(data) == "table" and data or {}
end
function Config:WriteMemory(data)
    if not can("writefile") then return false end
    self:_ensure()
    return pcall(writefile, self.folder .. "/window.json", HttpService:JSONEncode(data))
end

-- Profiles keep extra info (when saved) in <Folder>/profiles.json.
function Config:ReadMeta()
    if not can("readfile", "isfile") or not isfile(self.folder .. "/profiles.json") then return {} end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(self.folder .. "/profiles.json")) end)
    return ok and type(data) == "table" and data or {}
end
function Config:WriteMeta(data)
    if not can("writefile") then return false end
    self:_ensure()
    return pcall(writefile, self.folder .. "/profiles.json", HttpService:JSONEncode(data))
end

-- Snapshot of every flag right now (used as the locked "Default" profile).
function Config:Snapshot()
    local data = {}
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
        if element and not pcall(element._load, element, value) then failed = failed + 1 end
    end
    return failed
end
function Config:Exists(name)
    name = cleanName(name)
    return can("isfile") and name ~= "" and isfile(self.path .. "/" .. name .. ".json") or false
end
function Config:Rename(old, new)
    old, new = cleanName(old), cleanName(new)
    if new == "" then return false, "Empty name" end
    if self:Exists(new) then return false, "A profile with that name exists" end
    if not can("readfile", "writefile", "delfile", "isfile") then return false, "File functions are not available" end
    local ok, text = pcall(readfile, self.path .. "/" .. old .. ".json")
    if not ok then return false, "Profile not found" end
    pcall(writefile, self.path .. "/" .. new .. ".json", text)
    pcall(delfile, self.path .. "/" .. old .. ".json")
    if self:GetAutoLoad() == old then self:SetAutoLoad(new) end
    return true
end
function Config:Copy(name, new)
    name, new = cleanName(name), cleanName(new)
    if self:Exists(new) then return false, "A profile with that name exists" end
    if not can("readfile", "writefile") then return false, "File functions are not available" end
    local ok, text = pcall(readfile, self.path .. "/" .. name .. ".json")
    if not ok then return false, "Profile not found" end
    return pcall(writefile, self.path .. "/" .. new .. ".json", text)
end
function Config:ClearAutoLoad()
    if can("delfile", "isfile") and isfile(self.folder .. "/autoload.txt") then pcall(delfile, self.folder .. "/autoload.txt") end
end

return Config
end

__modules["dashboard"] = function()
-- Window:DashboardTab({ Title, Icon, Info = { { "Code revision", "571" }, ... }, Server = true })
-- Qustah's overview: profile card (avatar, names, session timer), Session, Info and Server cards.
-- Call it before the other tabs; a divider goes between it and the next tab in the dock.
local Util = require("util")
local Theme = require("theme")
local Glow = require("glow")

local Services = Util.Services
local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

return function(window, cfg)
    cfg = cfg or {}
    local Players = Services.Players
    local player = Players.LocalPlayer
    local tab = window:Tab({ Title = cfg.Title or "Dashboard", Icon = cfg.Icon or "rbxassetid://111637692403997", Header = cfg.Header ~= false })
    window._dividerNext = true
    local page = tab:Page(tab.Title)
    local started = os.clock()

    ------------------------------------------------------------ profile
    local profile = page:Card({ Wide = true })
    local body = create("Frame", { Name = "Profile", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 68), LayoutOrder = profile:_order(), Parent = profile.body })
    local ring = create("Frame", { Name = "Ring", Position = UDim2.fromOffset(0, 2), Size = UDim2.fromOffset(62, 62), BorderSizePixel = 0, BackgroundTransparency = 0.85, Parent = body })
    Theme.bind(ring, "BackgroundColor3", "accent")
    corner(ring, 31)
    local avatar = create("ImageLabel", { Name = "Avatar", Position = UDim2.fromOffset(3, 5), Size = UDim2.fromOffset(56, 56), BorderSizePixel = 0, Parent = body })
    Theme.bind(avatar, "BackgroundColor3", "input")
    corner(avatar, 28)
    local online = create("Frame", { Name = "Online", Position = UDim2.fromOffset(47, 49), Size = UDim2.fromOffset(10, 10), BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(70, 205, 105), Parent = body })
    corner(online, 5)
    Theme.bind(stroke(online, nil, 0, 2), "Color", "card")
    local display = label(body, player.DisplayName, 15, { Name = "DisplayName", Position = UDim2.fromOffset(76, 10), Size = UDim2.new(1, -250, 0, 20) })
    pcall(function() display.FontFace = Font.new(Font.fromEnum(Enum.Font.Gotham).Family, Enum.FontWeight.SemiBold) end)
    Theme.bind(display, "TextColor3", "heading")
    local username = label(body, "@" .. player.Name .. " · #" .. player.UserId, 10, { Name = "Username", Position = UDim2.fromOffset(76, 32), Size = UDim2.new(1, -250, 0, 15) })
    Theme.bind(username, "TextColor3", "muted")
    local caption = label(body, "SESSION", 8, { Name = "SessionCaption", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 12), Size = UDim2.fromOffset(150, 12), TextXAlignment = Enum.TextXAlignment.Right })
    Theme.bind(caption, "TextColor3", "muted")
    local uptime = label(body, "00:00:00", 18, { Name = "Uptime", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 28), Size = UDim2.fromOffset(150, 24), TextXAlignment = Enum.TextXAlignment.Right })
    Theme.bind(uptime, "TextColor3", "accent")
    Glow.add(display, { Base = "heading", Phase = 0.1 })
    Glow.add(uptime, { Base = "accent", Phase = 0.45 })
    task.spawn(function()
        local ok, image = pcall(function()
            return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if ok and avatar.Parent then avatar.Image = image end
    end)

    ------------------------------------------------------------ session / info / server
    local session = page:Card({ Title = "Session", Side = "Left" })
    session:Info({ Title = "User ID", Value = "#" .. player.UserId, Copy = function() return tostring(player.UserId) end })
    session:Info({ Title = "Account created", Value = os.date("%d %b %Y", os.time() - player.AccountAge * 86400) })
    local executor = "Unknown"
    pcall(function()
        if type(identifyexecutor) == "function" then executor = table.concat({ identifyexecutor() }, " ")
        elseif type(getexecutorname) == "function" then executor = tostring(getexecutorname()) end
    end)
    session:Info({ Title = "Executor", Value = executor })
    session:Divider()
    session:Info({ Title = "Game ID", Value = "#" .. game.GameId, Copy = function() return tostring(game.GameId) end })
    session:Info({ Title = "Place ID", Value = "#" .. game.PlaceId, Copy = function() return tostring(game.PlaceId) end })

    local info = page:Card({ Title = "Info", Side = "Right" })
    if window.Version ~= "" then info:Info({ Title = "GUI version", Value = window.Version }) end
    for _, entry in ipairs(cfg.Info or {}) do info:Info({ Title = entry[1], Value = entry[2], Copy = entry.Copy }) end
    local playerCount = info:Info({ Title = "Players", Value = "--" })
    local ping = info:Info({ Title = "Ping", Value = "--" })

    if cfg.Server ~= false then
        local server = page:Card({ Title = "Server", Side = "Right" })
        local busy = false
        local function teleport(hop)
            if busy then window:Notify({ Title = "Server", Content = "Teleport already pending" }) return end
            local TeleportService = Services.TeleportService
            busy = true
            task.delay(12, function() busy = false end)
            window:Notify({ Title = hop and "Server hop" or "Rejoin", Content = hop and "Finding a server..." or "Rejoining..." })
            task.spawn(function()
                local ok, err = pcall(function()
                    if not hop then
                        if game.JobId ~= "" and #Players:GetPlayers() > 1 then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
                        else
                            TeleportService:Teleport(game.PlaceId, player)
                        end
                        return
                    end
                    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
                    local data = Services.HttpService:JSONDecode(game:HttpGet(url))
                    local list = {}
                    for _, item in ipairs(data.data or {}) do
                        if item.id ~= game.JobId and item.playing and item.maxPlayers and item.playing < item.maxPlayers then list[#list + 1] = item end
                    end
                    assert(#list > 0, "No other public server found")
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, list[math.random(1, #list)].id, player)
                end)
                if not ok then busy = false window:Notify({ Title = "Teleport failed", Content = tostring(err), Color = Color3.fromRGB(215, 130, 130) }) end
            end)
        end
        server:Button({ Title = "Rejoin", Callback = function() teleport(false) end })
        server:Button({ Title = "Server hop", Confirm = true, Callback = function() teleport(true) end })
        server:Info({ Title = "Job ID", Value = game.JobId ~= "" and (game.JobId:sub(1, 8) .. "...") or "studio", Copy = function() return game.JobId end })
    end

    ------------------------------------------------------------ modules (Window:SetModule)
    if cfg.Modules ~= false then
        local modulesCard = page:Card({ Title = "Modules", Side = "Left" })
        local empty = modulesCard:Label("Modules report here with Window:SetModule(name, state)")
        local rows = {}
        local COLORS = { On = Color3.fromRGB(110, 200, 130), Limited = Color3.fromRGB(215, 180, 120), Error = Color3.fromRGB(215, 130, 130) }
        local function update()
            local order, modules = window:GetModules()
            empty:SetVisible(#order == 0)
            for _, name in ipairs(order) do
                rows[name] = rows[name] or modulesCard:Info({ Title = name })
                local module = modules[name]
                rows[name]:Set(module.state)
                rows[name]:SetColor(COLORS[module.state] or "muted")
            end
        end
        window:OnStatusChanged(update)
        update()
    end

    ------------------------------------------------------------ live values (only while the dashboard is open)
    task.spawn(function()
        while window.alive do
            if window.visible and window.current == tab then
                local seconds = math.floor(os.clock() - started)
                uptime.Text = string.format("%02d:%02d:%02d", seconds // 3600, (seconds // 60) % 60, seconds % 60)
                playerCount:Set(#Players:GetPlayers() .. " / " .. Players.MaxPlayers)
                local ok, value = pcall(function() return player:GetNetworkPing() end)
                ping:Set(ok and (math.floor(value * 1000 + 0.5) .. " ms") or "--")
            end
            task.wait(1)
        end
    end)
    return tab
end
end

__modules["dialog"] = function()
-- In-window dialogs.
--   Window:Dialog({ Title, Content, Buttons = { { Title = "Cancel" }, { Title = "Enable", Style = "Danger", Callback = fn } } })
--   Window:Confirm(title, content, onConfirm, confirmText, danger)
-- The menu behind is dimmed and blocked; Escape or a click on the dim area closes it (as "cancel").
local Util = require("util")
local Theme = require("theme")

local create, corner, stroke, label, tween = Util.create, Util.corner, Util.stroke, Util.label, Util.tween

return function(Window)
    function Window:Dialog(cfg)
        cfg = cfg or {}
        if self._dialog then self._dialog:Close() end
        local window = self
        local overlay = create("TextButton", {
            Name = "Dialog", Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 200, Parent = self.main,
        })
        local panel = create("Frame", {
            Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 330, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, ZIndex = 201, Active = true, Parent = overlay,
        })
        create("UISizeConstraint", { MaxSize = Vector2.new(330, 400), MinSize = Vector2.new(200, 0), Parent = panel })
        Theme.bind(panel, "BackgroundColor3", "card")
        corner(panel, 8)
        Theme.bind(stroke(panel), "Color", "line")
        Util.padding(panel, 16, 16, 12, 12)
        Util.list(panel, 8)
        local title = label(panel, tostring(cfg.Title or ""), 13, { Name = "Title", Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.GothamMedium, ZIndex = 202, LayoutOrder = 1 })
        Theme.bind(title, "TextColor3", "heading")
        if cfg.Content then
            local content = label(panel, tostring(cfg.Content), 10, {
                Name = "Content", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
                TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top, RichText = true, ZIndex = 202, LayoutOrder = 2,
            })
            Theme.bind(content, "TextColor3", "muted")
        end
        local row = create("Frame", { Name = "Buttons", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 3, ZIndex = 202, Parent = panel })
        Util.list(row, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

        local dialog = { Frame = overlay }
        function dialog:Close(result)
            if not overlay.Parent then return end
            if window._dialog == dialog then window._dialog = nil end
            overlay:Destroy()
            if result == nil then window:_safe("Dialog", cfg.OnCancel) end
        end
        local buttons = cfg.Buttons or { { Title = "OK" } }
        for index, spec in ipairs(buttons) do
            local style = spec.Style
            local button = create("TextButton", {
                Name = tostring(spec.Title or "OK"), Text = tostring(spec.Title or "OK"), TextSize = 10, Font = Enum.Font.GothamMedium,
                AutoButtonColor = false, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(70, 28),
                LayoutOrder = index, ZIndex = 203, Parent = row,
            })
            Util.padding(button, 14, 14, 0, 0)
            corner(button, 6)
            local outline = stroke(button)
            if style == "Danger" then
                button.BackgroundColor3, button.TextColor3, outline.Color = Color3.fromRGB(150, 52, 58), Color3.new(1, 1, 1), Color3.fromRGB(226, 101, 107)
            elseif style == "Primary" then
                Theme.bind(button, "BackgroundColor3", "accentDeep")
                Theme.bind(button, "TextColor3", "accent")
                Theme.bind(outline, "Color", "accent")
                outline.Transparency = 0.45
            else
                Theme.bind(button, "BackgroundColor3", "input")
                Theme.bind(button, "TextColor3", "text")
                Theme.bind(outline, "Color", "buttonEdge")
            end
            button.Activated:Connect(function()
                dialog:Close(true)
                window:_safe("Dialog", spec.Callback)
            end)
        end
        overlay.Activated:Connect(function() dialog:Close() end)
        tween(overlay, 0.15, { BackgroundTransparency = 0.35 })
        self._dialog = dialog
        return dialog
    end

    function Window:Confirm(title, content, onConfirm, confirmText, danger)
        return self:Dialog({
            Title = title, Content = content,
            Buttons = { { Title = "Cancel" }, { Title = confirmText or "Confirm", Style = danger and "Danger" or "Primary", Callback = onConfirm } },
        })
    end
end
end

__modules["elements/base"] = function()
-- Shared parts of every element: the row (title + optional description), callbacks / OnChanged, flags,
-- Lock / Unlock with a reason tooltip, and the default save / load used by configs.
local Util = require("util")
local Theme = require("theme")

local create, corner, label = Util.create, Util.corner, Util.label

local Base = {}

-- opts.right: pixels kept free on the right for the control; opts.button: the whole row is clickable.
function Base.row(card, cfg, height, opts)
    opts = opts or {}
    local row = create(opts.button and "TextButton" or "Frame", {
        Name = tostring(cfg.Title or "Row"), BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height), LayoutOrder = card:_order(), Parent = card.body,
    })
    if opts.button then row.Text = "" row.AutoButtonColor = false end
    local right = opts.right or 0
    local title = label(row, tostring(cfg.Title or ""), 11, {
        Name = "Title", Position = UDim2.fromOffset(0, cfg.Desc and 3 or 0),
        Size = UDim2.new(1, -right, 0, cfg.Desc and 18 or (opts.titleHeight or height)),
    })
    Theme.bind(title, "TextColor3", "text")
    local desc
    if cfg.Desc then
        desc = label(row, tostring(cfg.Desc), 9, { Name = "Desc", Position = UDim2.fromOffset(0, 23), Size = UDim2.new(1, -right, 0, 14) })
        Theme.bind(desc, "TextColor3", "muted")
    end
    -- Help = "text": a small "i" left of the control; click shows the text next to the mouse.
    if cfg.Help then
        local help = create("TextButton", {
            Name = "Help", Text = "i", TextSize = 10, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(opts.helpRight or right), 0, opts.helpY or height / 2),
            Size = UDim2.fromOffset(14, 16), ZIndex = 5, Parent = row,
        })
        Theme.bind(help, "TextColor3", "muted")
        help.Activated:Connect(function() card.window:_tip(cfg.Help) end)
        help.MouseLeave:Connect(function() card.window:_hideTip() end)
        title.Size = UDim2.new(1, -(opts.helpRight or right) - 16, 0, title.Size.Y.Offset)
    end
    return row, title, desc
end

function Base.element(card, kind, cfg, row, title, desc)
    local window = card.window
    local element = { Type = kind, Title = cfg.Title, Flag = cfg.Flag, Row = row, Card = card, Locked = false, _changed = {} }

    function element:OnChanged(callback)
        self._changed[#self._changed + 1] = callback
        return self
    end
    -- Stores the flag value; unless silent, runs Callback and the OnChanged listeners.
    function element:_fire(value, silent)
        if self.Flag then window.Lib.Flags[self.Flag] = value end
        if silent then return end
        -- errors in user callbacks are reported to the window (footer "Errors: N", Settings › Info)
        local source = tostring(self.Title or kind)
        window:_safe(source, cfg.Callback, value)
        for _, callback in ipairs(self._changed) do window:_safe(source, callback, value) end
    end
    function element:SetTitle(text) self.Title = text if title then title.Text = tostring(text) end end
    function element:SetDesc(text) if desc then desc.Text = tostring(text) end end
    function element:SetVisible(visible) row.Visible = visible ~= false end
    function element:Lock(reason)
        self.Locked = true
        self._lockReason = reason
        if not self._lock then
            local cover = create("TextButton", {
                Name = "Lock", Text = "", AutoButtonColor = false, BackgroundTransparency = 0.45, BorderSizePixel = 0,
                Position = UDim2.fromOffset(-4, -2), Size = UDim2.new(1, 8, 1, 4), ZIndex = 20, Parent = row,
            })
            Theme.bind(cover, "BackgroundColor3", "card")
            corner(cover, 6)
            cover.MouseEnter:Connect(function() if self._lockReason then window:_tip(self._lockReason) end end)
            cover.MouseLeave:Connect(function() window:_hideTip() end)
            self._lock = cover
        end
        self._lock.Visible = true
    end
    function element:Unlock()
        self.Locked = false
        if self._lock then self._lock.Visible = false end
        window:_hideTip()
    end
    function element:Destroy()
        if self.Flag and window.flags[self.Flag] == self then window.flags[self.Flag] = nil end
        window.binds[self] = nil
        row:Destroy()
    end
    function element:_save() return self.Value end
    function element:_load(value) self:Set(value) end

    if cfg.Flag then window:_register(cfg.Flag, element) end
    return element
end

-- Applied by every element after its first Set: initial lock state.
function Base.finish(element, cfg)
    if cfg.Locked then element:Lock(cfg.LockedTitle or cfg.LockedReason) end
    return element
end

return Base
end

__modules["elements/button"] = function()
-- card:Button({ Title, Desc, Callback, Confirm, Locked })
-- Confirm = true (or a text) asks for a second click within 2 seconds before running the callback.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local height = cfg.Desc and 44 or 28
    local row = create("Frame", { Name = tostring(cfg.Title or "Button"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height), LayoutOrder = card:_order(), Parent = card.body })
    local button = create("TextButton", {
        Name = "Button", Size = UDim2.new(1, 0, 0, 28), BorderSizePixel = 0, Text = tostring(cfg.Title or "Button"),
        TextSize = 10, Font = Enum.Font.Gotham, AutoButtonColor = false, Parent = row,
    })
    Theme.bind(button, "BackgroundColor3", "input")
    Theme.bind(button, "TextColor3", "text")
    corner(button, 6)
    local outline = stroke(button)
    Theme.bind(outline, "Color", "buttonEdge")
    local desc
    if cfg.Desc then
        desc = Util.label(row, tostring(cfg.Desc), 9, { Position = UDim2.fromOffset(2, 30), Size = UDim2.new(1, -4, 0, 14) })
        Theme.bind(desc, "TextColor3", "muted")
    end

    local element = Base.element(card, "Button", cfg, row, button, desc)
    element.Text = button.Text
    function element:SetTitle(text) self.Text = tostring(text) button.Text = self.Text end
    function element:Fire() card.window:_safe(element.Text, cfg.Callback) end

    button.MouseEnter:Connect(function() Theme.tweenTo(button, "BackgroundColor3", "hover", 0.12) Theme.tweenTo(button, "TextColor3", "heading", 0.12) end)
    button.MouseLeave:Connect(function() Theme.tweenTo(button, "BackgroundColor3", "input", 0.12) Theme.tweenTo(button, "TextColor3", "text", 0.12) end)
    local armed = 0
    button.Activated:Connect(function()
        if element.Locked then return end
        if cfg.Confirm then
            if armed == 0 then
                armed = armed + 1
                local token = armed
                button.Text = type(cfg.Confirm) == "string" and cfg.Confirm or "Click again to confirm"
                Theme.tweenTo(outline, "Color", "accent", 0.1)
                task.delay(2, function()
                    if armed == token and button.Parent then armed = 0 button.Text = element.Text Theme.tweenTo(outline, "Color", "buttonEdge", 0.1) end
                end)
                return
            end
            armed = 0
            button.Text = element.Text
            Theme.tweenTo(outline, "Color", "buttonEdge", 0.1)
        end
        card.window:_safe(element.Text, cfg.Callback)
    end)
    return Base.finish(element, cfg)
end
end

__modules["elements/colorpicker"] = function()
-- card:ColorPicker({ Title, Desc, Flag, Default = Color3, Callback = function(color) end, Locked })
-- Click the swatch to open the picker under the row: saturation / brightness square, hue bar, HEX box, Random, Rainbow.
-- Apply = true: edits only preview until Apply is pressed (closing without Apply reverts).
-- Rainbow = true / :SetRainbow(on): cycles the hue (RainbowSpeed = seconds per cycle, default 5); saved with the config.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

local HUE = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)), ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
    ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)), ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
    ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)), ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
    ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
})

return function(card, cfg)
    local window = card.window
    local row, title, desc = Base.row(card, cfg, cfg.Desc and 40 or 30, { right = 60, button = true })
    local swatch = create("TextButton", {
        Name = "Swatch", Text = "", AutoButtonColor = false, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(34, 18), Parent = row,
    })
    corner(swatch, 5)
    Theme.bind(stroke(swatch, nil, 0.2), "Color", "buttonEdge")

    -- panel (opens under the row)
    local panel = create("Frame", {
        Name = "Picker", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 158), LayoutOrder = row.LayoutOrder + 1,
        Visible = false, Parent = card.body,
    })
    local square = create("TextButton", {
        Name = "Square", Text = "", AutoButtonColor = false, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 4),
        Size = UDim2.new(1, -104, 0, 104), Parent = panel,
    })
    corner(square, 6)
    local white = create("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), Parent = square })
    corner(white, 6)
    create("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
    local black = create("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0), Parent = square })
    corner(black, 6)
    create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = black })
    local cursor = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(8, 8), BackgroundTransparency = 1, ZIndex = 3, Parent = square })
    corner(cursor, 4)
    stroke(cursor, Color3.new(1, 1, 1), 0, 1.5)
    local hueBar = create("TextButton", {
        Name = "Hue", Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
        Position = UDim2.fromOffset(0, 116), Size = UDim2.new(1, -104, 0, 10), Parent = panel,
    })
    corner(hueBar, 5)
    create("UIGradient", { Color = HUE, Parent = hueBar })
    local hueCursor = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(4, 14), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3, Parent = hueBar })
    corner(hueCursor, 2)

    local side = create("Frame", { Name = "Side", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 4), Size = UDim2.fromOffset(92, 150), Parent = panel })
    local preview = create("Frame", { Size = UDim2.new(1, 0, 0, 26), BorderSizePixel = 0, Parent = side })
    corner(preview, 6)
    Theme.bind(stroke(preview, nil, 0.2), "Color", "buttonEdge")
    local hex = create("TextBox", {
        Name = "Hex", Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 24), BorderSizePixel = 0, Text = "",
        TextSize = 10, Font = Enum.Font.GothamMedium, ClearTextOnFocus = false, Parent = side,
    })
    Theme.bind(hex, "BackgroundColor3", "input")
    Theme.bind(hex, "TextColor3", "text")
    corner(hex, 6)
    Theme.bind(stroke(hex), "Color", "buttonEdge")
    local random = create("TextButton", {
        Name = "Random", Position = UDim2.fromOffset(0, 62), Size = UDim2.new(1, 0, 0, 24), BorderSizePixel = 0,
        Text = "Random", TextSize = 10, Font = Enum.Font.Gotham, AutoButtonColor = false, Parent = side,
    })
    Theme.bind(random, "BackgroundColor3", "input")
    Theme.bind(random, "TextColor3", "text")
    corner(random, 6)
    Theme.bind(stroke(random), "Color", "buttonEdge")
    local rainbow = create("TextButton", {
        Name = "Rainbow", Position = UDim2.fromOffset(0, 92), Size = UDim2.new(1, 0, 0, 24), BorderSizePixel = 0,
        Text = "Rainbow", TextSize = 10, Font = Enum.Font.Gotham, AutoButtonColor = false, Parent = side,
    })
    Theme.bind(rainbow, "BackgroundColor3", "input")
    Theme.bind(rainbow, "TextColor3", "text")
    corner(rainbow, 6)
    local rainbowEdge = stroke(rainbow)
    Theme.bind(rainbowEdge, "Color", "buttonEdge")
    local done = create("TextButton", {
        Name = "Done", Position = UDim2.fromOffset(0, 122), Size = UDim2.new(1, 0, 0, 24), BorderSizePixel = 0,
        Text = cfg.Apply and "Apply" or "Done", TextSize = 10, Font = Enum.Font.GothamMedium, AutoButtonColor = false, Parent = side,
    })
    Theme.bind(done, "BackgroundColor3", "accentDeep")
    Theme.bind(done, "TextColor3", "accent")
    corner(done, 6)
    Theme.bind(stroke(done, nil, 0.45), "Color", "accent")

    local element = Base.element(card, "ColorPicker", cfg, row, title, desc)
    local h, s, v = 0, 0, 1

    local function render()
        local color = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3, preview.BackgroundColor3 = color, color
        square.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        cursor.Position = UDim2.fromScale(s, 1 - v)
        hueCursor.Position = UDim2.fromScale(h, 0.5)
        hex.Text = "#" .. Util.toHex(color)
    end
    local applyMode = cfg.Apply == true
    local function commit(silent, force)
        local color = Color3.fromHSV(h, s, v)
        if applyMode and not force and panel.Visible and not silent then render() swatch.BackgroundColor3 = element.Value or color return end
        local changed = color ~= element.Value
        element.Value = color
        render()
        element:_fire(color, silent or not changed)
    end
    function element:Set(color, silent)
        if type(color) == "string" then color = Util.fromHex(color) end
        if typeof(color) ~= "Color3" then return end
        h, s, v = color:ToHSV()
        commit(silent, true)
    end
    function element:Get() return self.Value end
    function element:_save() return self.Rainbow and { Color = Util.toHex(self.Value), Rainbow = true } or Util.toHex(self.Value) end
    function element:_load(data)
        if type(data) == "table" then self:Set(data.Color) self:SetRainbow(data.Rainbow == true) else self:SetRainbow(false) self:Set(data) end
    end
    local function revert()
        if applyMode and element.Value then h, s, v = element.Value:ToHSV() render() end
    end
    function element:SetOpen(open)
        if not open then revert() end
        panel.Visible = open == true
    end

    -- rainbow: hue walks around the wheel; callbacks are throttled to ~20 per second
    element.Rainbow = false
    local rainbowConnection
    local function renderRainbow()
        Theme.tweenTo(rainbow, "BackgroundColor3", element.Rainbow and "accentDeep" or "input", 0.1)
        Theme.tweenTo(rainbow, "TextColor3", element.Rainbow and "accent" or "text", 0.1)
        Theme.tweenTo(rainbowEdge, "Color", element.Rainbow and "accent" or "buttonEdge", 0.1)
    end
    function element:SetRainbow(on)
        on = on == true
        if on == self.Rainbow then return end
        self.Rainbow = on
        if rainbowConnection then rainbowConnection:Disconnect() rainbowConnection = nil end
        if on then
            local period = math.max(0.5, tonumber(cfg.RainbowSpeed) or 5)
            local last = 0
            rainbowConnection = window.maid:connect(Util.Services.RunService.Heartbeat, function()
                local now = os.clock()
                if now - last < 0.05 then return end
                last = now
                h = (now / period) % 1
                if s < 0.05 then s = 0.75 end
                commit(false, true)
            end)
        end
        renderRainbow()
    end

    local function drag(target, apply)
        target.InputBegan:Connect(function(input)
            if not Util.isPress(input) or element.Locked then return end
            local function move(point)
                local p, size = target.AbsolutePosition, target.AbsoluteSize
                if size.X <= 0 or size.Y <= 0 then return end
                apply(math.clamp((point.X - p.X) / size.X, 0, 1), math.clamp((point.Y - p.Y) / size.Y, 0, 1))
                commit()
            end
            move(Util.pointer(input))
            window:_beginDrag(input, move)
        end)
    end
    drag(square, function(x, y) s, v = x, 1 - y end)
    drag(hueBar, function(x) h = math.min(x, 0.999) end)
    hex.FocusLost:Connect(function()
        local color = Util.fromHex(hex.Text)
        if color then h, s, v = color:ToHSV() commit() else render() end
    end)
    random.Activated:Connect(function() if not element.Locked then h, s, v = math.random(), 0.45 + math.random() * 0.5, 0.6 + math.random() * 0.4 commit() end end)
    rainbow.Activated:Connect(function() if not element.Locked then element:SetRainbow(not element.Rainbow) end end)
    done.Activated:Connect(function()
        if applyMode then commit(false, true) end
        panel.Visible = false
    end)
    local function toggleOpen() if not element.Locked then element:SetOpen(not panel.Visible) end end
    row.Activated:Connect(toggleOpen)
    swatch.Activated:Connect(toggleOpen)

    local default = cfg.Default
    if type(default) == "string" then default = Util.fromHex(default) end
    element:Set(typeof(default) == "Color3" and default or Color3.new(1, 1, 1), true)
    renderRainbow()
    if cfg.Rainbow then element:SetRainbow(true) end
    return Base.finish(element, cfg)
end
end

__modules["elements/divider"] = function()
-- card:Divider() - a thin line between groups of rows.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create = Util.create

return function(card)
    local holder = create("Frame", { Name = "Divider", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 7), LayoutOrder = card:_order(), Parent = card.body })
    local line = create("Frame", { Position = UDim2.fromOffset(0, 3), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, BackgroundTransparency = 0.3, Parent = holder })
    Theme.bind(line, "BackgroundColor3", "line")
    return Base.element(card, "Divider", {}, holder, nil, nil)
end
end

__modules["elements/dropdown"] = function()
-- card:Dropdown({ Title, Desc, Flag, Options = {...}, Default, Multi, Callback, Locked })
-- Single: Value is the chosen option (string). Multi: Value is a list of chosen options.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label
local ITEM, MAX_VISIBLE = 24, 7

return function(card, cfg)
    local window = card.window
    local multi = cfg.Multi == true
    local options = {}
    for _, option in ipairs(cfg.Options or cfg.Values or {}) do options[#options + 1] = tostring(option) end

    local row, title, desc = Base.row(card, cfg, cfg.Desc and 40 or 30, { right = 160 })
    -- the title takes the left half, the box the right half (up to 170 px)
    title.Size = UDim2.new(0.55, -8, 0, title.Size.Y.Offset)
    if desc then desc.Size = UDim2.new(0.55, -8, 0, 14) end
    local button = create("TextButton", {
        Name = "Select", Text = "", AutoButtonColor = false, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0.45, 0, 0, 24), Parent = row,
    })
    Theme.bind(button, "BackgroundColor3", "input")
    corner(button, 6)
    Theme.bind(stroke(button), "Color", "buttonEdge")
    create("UISizeConstraint", { MaxSize = Vector2.new(170, 24), Parent = button })
    local valueLabel = label(button, "", 10, { Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -28, 1, 0) })
    Theme.bind(valueLabel, "TextColor3", "text")
    -- chevron drawn with two bars (fonts may not have an arrow glyph)
    local arrow = create("Frame", { Name = "Chevron", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 1), Size = UDim2.fromOffset(10, 6), Parent = button })
    local arrowBars = {}
    for index, rotation in ipairs({ 45, -45 }) do
        local bar = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(index == 1 and 3 or 7, 3), Size = UDim2.fromOffset(6, 1.5),
            Rotation = rotation, BorderSizePixel = 0, Parent = arrow,
        })
        Theme.bind(bar, "BackgroundColor3", "muted")
        arrowBars[index] = bar
    end
    local function tintArrow(role) for _, bar in ipairs(arrowBars) do Theme.tweenTo(bar, "BackgroundColor3", role, 0.1) end end

    local element = Base.element(card, "Dropdown", cfg, row, title, desc)
    element.Options = options

    local function chosen(option)
        if multi then return table.find(element.Value, option) ~= nil end
        return element.Value == option
    end
    local function render()
        if multi then
            valueLabel.Text = #element.Value > 0 and table.concat(element.Value, ", ") or "None"
        else
            valueLabel.Text = element.Value or "None"
        end
    end

    ------------------------------------------------------------ list popup
    local popup
    local function closeList()
        if popup then popup:Destroy() popup = nil end
        tintArrow("muted")
    end
    local function openList()
        closeList()
        -- The list opens over the button: header (value + upturned chevron), divider, options. It opens upwards
        -- when there is more room above.
        local position, size = button.AbsolutePosition, button.AbsoluteSize
        local viewport = Util.viewport()
        local listHeight = math.min(#options, MAX_VISIBLE) * ITEM + 8
        local total = 25 + listHeight
        local width = math.max(size.X, 120)
        local roomBelow, roomAbove = viewport.Y - 8 - position.Y, position.Y + size.Y - 8
        local below = roomBelow >= total or roomBelow >= roomAbove
        popup = create("Frame", {
            Name = "DropdownList", BorderSizePixel = 0, ZIndex = 260,
            Position = UDim2.fromOffset(math.clamp(position.X, 8, math.max(8, viewport.X - width - 8)), below and position.Y or position.Y + size.Y - total),
            Size = UDim2.fromOffset(width, total), Parent = window.gui,
        })
        Theme.bind(popup, "BackgroundColor3", "input")
        corner(popup, 6)
        Theme.bind(stroke(popup), "Color", "buttonEdge")
        local header = create("TextButton", {
            Name = "Header", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, ZIndex = 261,
            Position = UDim2.fromOffset(0, below and 0 or total - 24), Size = UDim2.new(1, 0, 0, 24), Parent = popup,
        })
        local headerText = label(header, valueLabel.Text, 10, { Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -28, 1, 0), ZIndex = 262 })
        Theme.bind(headerText, "TextColor3", "text")
        for index, rotation in ipairs({ -40, 40 }) do
            local bar = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, index == 1 and -16 or -12, 0.5, 0), Size = UDim2.fromOffset(6, 1.5),
                Rotation = rotation, BorderSizePixel = 0, ZIndex = 262, Parent = header,
            })
            Theme.bind(bar, "BackgroundColor3", "accent")
        end
        header.Activated:Connect(function() window:_closePopup() end)
        local separator = create("Frame", {
            Position = UDim2.new(0, 6, 0, below and 24 or total - 25), Size = UDim2.new(1, -12, 0, 1), BorderSizePixel = 0, ZIndex = 261, Parent = popup,
        })
        Theme.bind(separator, "BackgroundColor3", "line")
        local scroller = create("ScrollingFrame", {
            Name = "Options", BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 261, ScrollBarThickness = 2,
            Position = UDim2.fromOffset(0, below and 25 or 0), Size = UDim2.new(1, 0, 0, listHeight),
            CanvasSize = UDim2.fromOffset(0, #options * ITEM + 8), ScrollingDirection = Enum.ScrollingDirection.Y, Parent = popup,
        })
        Theme.bind(scroller, "ScrollBarImageColor3", "muted")
        Util.padding(scroller, 4, 4, 4, 4)
        Util.list(scroller, 0)
        local function refreshHeader() headerText.Text = valueLabel.Text end
        for index, option in ipairs(options) do
            local item = create("TextButton", {
                Name = option, Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, ITEM), LayoutOrder = index, ZIndex = 262, Parent = scroller,
            })
            Theme.bind(item, "BackgroundColor3", "hover")
            corner(item, 5)
            local text = label(item, option, 10, { Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -28, 1, 0), ZIndex = 263 })
            Theme.bind(text, "TextColor3", chosen(option) and "accent" or "text")
            local check = create("Frame", { Name = "Check", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, ZIndex = 263, Visible = chosen(option), Parent = item })
            corner(check, 3)
            Theme.bind(check, "BackgroundColor3", "accent")
            item.MouseEnter:Connect(function() item.BackgroundTransparency = 0 end)
            item.MouseLeave:Connect(function() item.BackgroundTransparency = 1 end)
            item.Activated:Connect(function()
                if multi then
                    local list = table.clone(element.Value)
                    local at = table.find(list, option)
                    if at then table.remove(list, at) else list[#list + 1] = option end
                    element:Set(list)
                    Theme.tweenTo(text, "TextColor3", chosen(option) and "accent" or "text", 0.1)
                    check.Visible = chosen(option)
                    refreshHeader()
                else
                    element:Set(option)
                    window:_closePopup()
                end
            end)
        end
        tintArrow("accent")
        window:_openPopup(popup, button, closeList)
    end
    button.Activated:Connect(function()
        if element.Locked then return end
        if popup then window:_closePopup() else openList() end
    end)

    function element:Set(value, silent)
        if multi then
            local list = {}
            for _, option in ipairs(type(value) == "table" and value or { value }) do
                option = tostring(option)
                if table.find(options, option) and not table.find(list, option) then list[#list + 1] = option end
            end
            self.Value = list
        else
            value = value ~= nil and tostring(value) or nil
            self.Value = (value and table.find(options, value)) and value or nil
        end
        render()
        self:_fire(self.Value, silent)
    end
    function element:Get() return self.Value end
    function element:SetOptions(list, keep)
        options = {}
        for _, option in ipairs(list or {}) do options[#options + 1] = tostring(option) end
        self.Options = options
        if popup then window:_closePopup() end
        self:Set(keep and self.Value or (multi and {} or nil), true)
    end

    if multi then
        element.Value = {}
        element:Set(cfg.Default or {}, true)
    else
        element:Set(cfg.Default, true)
    end
    return Base.finish(element, cfg)
end
end

__modules["elements/graph"] = function()
-- card:Graph({ Title, Source = "FPS" | "Ping" | function() return number end, Max, Suffix, Height = 70, Points = 40, Interval = 0.5 })
-- A small live bar chart. "FPS" / "Ping" use the library's shared sampler; a function is sampled every Interval
-- seconds while the graph is on screen. :Push(value) adds a sample by hand.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Stats = require("stats")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local window = card.window
    local points = math.clamp(tonumber(cfg.Points) or 40, 5, 120)
    local height = tonumber(cfg.Height) or 70
    local suffix = cfg.Suffix or (cfg.Source == "Ping" and " ms" or (cfg.Source == "FPS" and " FPS" or ""))
    local holder = create("Frame", { Name = tostring(cfg.Title or "Graph"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height + 24), LayoutOrder = card:_order(), Parent = card.body })
    local title = label(holder, tostring(cfg.Title or cfg.Source or "Graph"), 11, { Name = "Title", Size = UDim2.new(1, -90, 0, 20) })
    Theme.bind(title, "TextColor3", "text")
    local value = label(holder, "--", 10, { Name = "Value", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(90, 20), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium })
    Theme.bind(value, "TextColor3", "heading")
    local area = create("Frame", { Name = "Area", Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, BackgroundTransparency = 0.4, ClipsDescendants = true, Parent = holder })
    Theme.bind(area, "BackgroundColor3", "base")
    corner(area, 6)
    local bars = {}
    for index = 1, points do
        local bar = create("Frame", {
            AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((index - 1) / points, 1, 1, 0), Size = UDim2.new(1 / points, -2, 0, 0),
            BorderSizePixel = 0, BackgroundTransparency = 0.3, Parent = area,
        })
        Theme.bind(bar, "BackgroundColor3", "accent")
        bars[index] = bar
    end

    local element = Base.element(card, "Graph", {}, holder, title, nil)
    local samples = {}
    local function render()
        local top = tonumber(cfg.Max) or 1
        for _, sample in ipairs(samples) do top = math.max(top, sample) end
        for index = 1, points do
            local sample = samples[#samples - points + index]
            bars[index].Size = UDim2.new(1 / points, -2, sample and math.clamp(sample / top, 0.02, 1) or 0, 0)
        end
        local last = samples[#samples]
        value.Text = last and (tostring(math.floor(last + 0.5)) .. suffix) or "--"
    end
    function element:Push(sample)
        sample = tonumber(sample)
        if not sample then return end
        samples[#samples + 1] = sample
        if #samples > points then table.remove(samples, 1) end
        render()
    end
    function element:Set(list) samples = {} for _, sample in ipairs(list or {}) do self:Push(sample) end render() end

    local function onScreen()
        local object = holder
        while object and object ~= window.gui do
            if object:IsA("GuiObject") and not object.Visible then return false end
            object = object.Parent
        end
        return window.visible
    end
    if cfg.Source == "FPS" or cfg.Source == "Ping" then
        Stats.start(window.Lib.maid)
        local key = cfg.Source == "FPS" and "fps" or "ping"
        window.maid:give(Stats.listen(function(stats) if holder.Parent then element:Push(stats[key]) end end))
    elseif type(cfg.Source) == "function" then
        task.spawn(function()
            while window.alive and holder.Parent do
                if onScreen() then
                    local ok, sample = pcall(cfg.Source)
                    if ok then element:Push(sample) end
                end
                task.wait(tonumber(cfg.Interval) or 0.5)
            end
        end)
    end
    render()
    return element
end
end

__modules["elements/imagepicker"] = function()
-- card:ImagePicker({ Title, Flag, Images = { "251497633", "rbxassetid://12140499119", ... }, Default, Columns = 5, Callback })
-- A grid of images (crosshairs, icons...); the chosen one is outlined. Value is the image exactly as given.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

return function(card, cfg)
    local images = cfg.Images or {}
    local columns = math.max(1, tonumber(cfg.Columns) or 5)
    local cell = tonumber(cfg.CellSize) or 40
    local rowsCount = math.ceil(#images / columns)
    local top = cfg.Title and 24 or 0
    local holder = create("Frame", { Name = tostring(cfg.Title or "Images"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, top + rowsCount * (cell + 6)), LayoutOrder = card:_order(), Parent = card.body })
    local title
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Size = UDim2.new(1, 0, 0, 20) })
        Theme.bind(title, "TextColor3", "text")
    end
    local grid = create("Frame", { Name = "Grid", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 1, -top), Parent = holder })

    local element = Base.element(card, "ImagePicker", cfg, holder, title, nil)
    local buttons = {}
    local function asset(image)
        image = tostring(image)
        return image:match("^%d+$") and ("rbxassetid://" .. image) or image
    end
    local function render()
        for image, entry in pairs(buttons) do
            local on = image == element.Value
            Theme.tweenTo(entry.button, "BackgroundColor3", on and "selected" or "input", 0.1)
            Theme.tweenTo(entry.outline, "Color", on and "accent" or "line", 0.1)
            entry.outline.Transparency = on and 0.2 or 0.6
        end
    end
    for index, image in ipairs(images) do
        local key = tostring(image)
        local button = create("ImageButton", {
            Name = "Image" .. index, AutoButtonColor = false, BorderSizePixel = 0, Image = "", LayoutOrder = index, Parent = grid,
            Position = UDim2.new(((index - 1) % columns) / columns, 3, 0, ((index - 1) // columns) * (cell + 6)), Size = UDim2.new(1 / columns, -6, 0, cell),
        })
        corner(button, 6)
        local outline = stroke(button)
        create("ImageLabel", {
            Name = "Preview", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.62, 0.62),
            BackgroundTransparency = 1, Image = asset(image), ScaleType = Enum.ScaleType.Fit, Parent = button,
        })
        buttons[key] = { button = button, outline = outline }
        button.Activated:Connect(function() if not element.Locked then element:Set(key) end end)
    end

    function element:Set(image, silent)
        image = image ~= nil and tostring(image) or nil
        if image and not buttons[image] then return end
        local changed = image ~= self.Value
        self.Value = image
        render()
        self:_fire(image, silent or not changed)
    end
    function element:Get() return self.Value end

    element:Set(cfg.Default ~= nil and cfg.Default or images[1], true)
    return Base.finish(element, cfg)
end
end

__modules["elements/info"] = function()
-- card:Info({ Title = "User ID", Value = "#123", Copy = true | "text to copy" | function() return ... end })
-- A read-only "name ........ value" row; :Set(value) updates it. With Copy a small Copy button copies the value.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

return function(card, cfg)
    local row = create("Frame", { Name = tostring(cfg.Title or "Info"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = card:_order(), Parent = card.body })
    local title = label(row, tostring(cfg.Title or ""), 10, { Name = "Title", Size = UDim2.new(0.42, -6, 1, 0) })
    Theme.bind(title, "TextColor3", "muted")
    local copyWidth = cfg.Copy and 40 or 0
    local value = label(row, "", 10, {
        Name = "Value", Position = UDim2.new(0.42, copyWidth, 0, 0), Size = UDim2.new(0.58, -copyWidth, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium,
    })
    Theme.bind(value, "TextColor3", "text")

    local element = Base.element(card, "Info", {}, row, title, nil)
    function element:Set(text) self.Value = text value.Text = tostring(text) end
    function element:Get() return self.Value end
    function element:SetColor(color) if typeof(color) == "Color3" then value.TextColor3 = color else Theme.bind(value, "TextColor3", color or "text") end end

    if cfg.Copy then
        local copy = create("TextButton", {
            Name = "Copy", Text = "Copy", TextSize = 8, Font = Enum.Font.Gotham, AutoButtonColor = false, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.42, 0, 0.5, 0), Size = UDim2.fromOffset(34, 16), Parent = row,
        })
        Theme.bind(copy, "BackgroundColor3", "input")
        Theme.bind(copy, "TextColor3", "text")
        corner(copy, 5)
        Theme.bind(stroke(copy), "Color", "buttonEdge")
        copy.Activated:Connect(function()
            local text = cfg.Copy
            if type(text) == "function" then local ok, result = pcall(text) text = ok and result or nil end
            if text == true or text == nil then text = tostring(element.Value):gsub("^#", "") end
            local clipboard = setclipboard or toclipboard
            local ok = type(clipboard) == "function" and pcall(clipboard, tostring(text))
            copy.Text = ok and "OK" or "!"
            task.delay(1.2, function() if copy.Parent then copy.Text = "Copy" end end)
            if ok then card.window:Notify({ Title = "Copied", Content = tostring(cfg.Title or "Value") .. " copied to clipboard" }) end
        end)
    end
    element:Set(cfg.Value ~= nil and cfg.Value or "--")
    return element
end
end

__modules["elements/input"] = function()
-- card:Input({ Title, Desc, Flag, Default, Placeholder, Numeric, ClearOnFocus, Finished, Callback, Locked })
-- Callback runs when the box loses focus (with Finished = false it runs on every change).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local row, title, desc = Base.row(card, cfg, cfg.Desc and 40 or 30, { right = 160 })
    -- the title takes the left half, the box the right half (up to 170 px)
    title.Size = UDim2.new(0.55, -8, 0, title.Size.Y.Offset)
    if desc then desc.Size = UDim2.new(0.55, -8, 0, 14) end
    local box = create("TextBox", {
        Name = "Box", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0.45, 0, 0, 24),
        BorderSizePixel = 0, Text = "", PlaceholderText = tostring(cfg.Placeholder or ""), TextSize = 10, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = cfg.ClearOnFocus == true, ClipsDescendants = true, Parent = row,
    })
    Theme.bind(box, "BackgroundColor3", "input")
    Theme.bind(box, "TextColor3", "text")
    Theme.bind(box, "PlaceholderColor3", "muted")
    corner(box, 6)
    local outline = stroke(box)
    Theme.bind(outline, "Color", "buttonEdge")
    Util.padding(box, 8, 8, 0, 0)
    create("UISizeConstraint", { MaxSize = Vector2.new(170, 24), Parent = box })

    local element = Base.element(card, "Input", cfg, row, title, desc)
    local function clean(text)
        text = tostring(text or "")
        if cfg.Numeric then text = text:gsub("[^%d%.%-]", "") end
        return text
    end
    function element:Set(text, silent)
        text = clean(text)
        local changed = text ~= self.Value
        self.Value = text
        if box.Text ~= text then box.Text = text end
        self:_fire(text, silent or not changed)
    end
    function element:Get() return self.Value end

    box.Focused:Connect(function() Theme.tweenTo(outline, "Color", "accent", 0.1) end)
    box.FocusLost:Connect(function()
        Theme.tweenTo(outline, "Color", "buttonEdge", 0.1)
        element:Set(box.Text)
    end)
    if cfg.Finished == false then
        box:GetPropertyChangedSignal("Text"):Connect(function() element:Set(box.Text) end)
    end
    element:Set(cfg.Default or "", true)
    if cfg.Locked then box.TextEditable = false end
    return Base.finish(element, cfg)
end
end

__modules["elements/keybind"] = function()
-- card:Keybind({ Title, Desc, Flag, Default = Enum.KeyCode.X, Callback = function(key) end, Pressed = function() end })
-- Click the badge, then press a key (Backspace clears, Escape cancels). Callback runs when the key changes,
-- Pressed runs every time the key is pressed (outside text boxes).
-- Chord = true: a modifier plus a key or mouse button, e.g. CTRL + M1 (press the modifier first, then the key);
-- Default = { Enum.KeyCode.LeftControl, Enum.UserInputType.MouseButton1 }. Value is then { modifier, key }.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local window = card.window
    local chordMode = cfg.Chord == true
    local row, title, desc = Base.row(card, cfg, cfg.Desc and 40 or 30, { right = chordMode and 130 or 100 })
    local badge = create("TextButton", {
        Name = "Key", AutoButtonColor = false, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(48, 22), Text = "", TextSize = 10,
        Font = Enum.Font.GothamMedium, Parent = row,
    })
    Theme.bind(badge, "BackgroundColor3", "input")
    Theme.bind(badge, "TextColor3", "heading")
    corner(badge, 6)
    local outline = stroke(badge)
    Theme.bind(outline, "Color", "buttonEdge")

    local element = Base.element(card, "Keybind", cfg, row, title, desc)
    local function show(text)
        badge.Text = text
        badge.Size = UDim2.fromOffset(math.max(48, Util.textWidth(text, 10, Enum.Font.GothamMedium) + 18), 22)
    end
    local function chordName(chord)
        if not chord or not chord[2] then return "None" end
        return (chord[1] and (Util.keyName(chord[1]) .. " + ") or "") .. Util.keyName(chord[2])
    end

    function element:Set(key, silent)
        if chordMode then
            -- accepts { modifier, key }, a single key, or a saved "LeftControl+MouseButton1"
            if type(key) == "string" then
                local first, second = key:match("^([^+]+)%+(.+)$")
                key = first and { Util.toKey(first), Util.toKey(second) } or { nil, Util.toKey(key) }
            elseif typeof(key) == "EnumItem" then
                key = { nil, key }
            elseif type(key) == "table" then
                key = { Util.toKey(key[1]), Util.toKey(key[2]) }
                if not key[2] and key[1] then key = { nil, key[1] } end
            else
                key = nil
            end
            if key and not key[2] then key = nil end
            local changed = chordName(key) ~= chordName(self.Value)
            self.Value, self.Chord = key, key
            window:_bind(self, key and key[2] or nil)
            show(chordName(key))
            Theme.tweenTo(outline, "Color", "buttonEdge", 0.1)
            self:_fire(key, silent or not changed)
            return
        end
        key = Util.toKey(key)
        local changed = key ~= self.Value
        self.Value = key
        window:_bind(self, key)
        show(Util.keyName(key))
        Theme.tweenTo(outline, "Color", "buttonEdge", 0.1)
        if changed then self:_fire(key, silent) else self:_fire(key, true) end
    end
    function element:Get() return self.Value end
    function element:_onBind() window:_safe(tostring(cfg.Title or "Keybind"), cfg.Pressed, self.Value) end
    function element:_save()
        if chordMode then
            local chord = self.Value
            if not chord then return "None" end
            return (chord[1] and (chord[1].Name .. "+") or "") .. chord[2].Name
        end
        return self.Value and self.Value.Name or "None"
    end

    badge.Activated:Connect(function()
        if element.Locked then return end
        show("...")
        Theme.tweenTo(outline, "Color", "accent", 0.1)
        local modifier
        local function capture(key)
            window._captureMouse = nil
            if key == Enum.KeyCode.Escape then element:Set(element.Value, true) return end
            if key == Enum.KeyCode.Backspace then element:Set(nil) return end
            if chordMode then
                if not modifier and Util.isModifier(key) then
                    -- wait for the main key / mouse button
                    modifier = key
                    show(Util.keyName(key) .. " + ...")
                    window._captureMouse = true
                    window._capture = capture
                    return
                end
                element:Set({ modifier, key })
                return
            end
            if key == window.key then element:Set(element.Value, true) return end -- the menu key stays the menu key
            element:Set(key)
        end
        window._capture = capture
    end)

    element:Set(cfg.Default, true)
    return Base.finish(element, cfg)
end
end

__modules["elements/label"] = function()
-- card:Label("text") or card:Label({ Title = "text", Color = Color3 }) - a wrapped line of muted text.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

return function(card, cfg)
    local text = Util.label(card.body, tostring(cfg.Title or cfg.Text or ""), 10, {
        Name = "Label", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None, RichText = true, LayoutOrder = card:_order(),
    })
    if typeof(cfg.Color) == "Color3" then text.TextColor3 = cfg.Color else Theme.bind(text, "TextColor3", "muted") end
    local element = Base.element(card, "Label", {}, text, text, nil)
    function element:Set(value) text.Text = tostring(value) end
    function element:SetColor(color) if typeof(color) == "Color3" then text.TextColor3 = color end end
    return element
end
end

__modules["elements/paragraph"] = function()
-- card:Paragraph({ Title = "Heading", Content = "Longer text, wraps to any number of lines." })
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create = Util.create

return function(card, cfg)
    local holder = create("Frame", {
        Name = "Paragraph", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = card:_order(), Parent = card.body,
    })
    Util.list(holder, 2)
    local title = Util.label(holder, tostring(cfg.Title or ""), 11, { Name = "Title", Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamMedium, LayoutOrder = 1 })
    Theme.bind(title, "TextColor3", "heading")
    title.Visible = cfg.Title ~= nil
    local content = Util.label(holder, tostring(cfg.Content or ""), 10, {
        Name = "Content", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top, RichText = true, LayoutOrder = 2,
    })
    Theme.bind(content, "TextColor3", "muted")
    local element = Base.element(card, "Paragraph", {}, holder, title, content)
    function element:Set(text) content.Text = tostring(text) end
    function element:SetContent(text) content.Text = tostring(text) end
    return element
end
end

__modules["elements/playerlist"] = function()
-- card:PlayerList({ Title, Flag, Multi = true, Height = 150, IncludeSelf = false, Callback = function(ids) end })
-- Searchable list of the players in the server (avatar, display name, @name); updates when players join / leave.
-- Value is a list of UserIds (Multi) or one UserId; :GetPlayers() returns the chosen Player objects in the server.
-- Chosen players who leave stay chosen and come back selected.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local Services = Util.Services
local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label
local ROW = 30

return function(card, cfg)
    local window = card.window
    local Players = Services.Players
    local multi = cfg.Multi ~= false
    local height = tonumber(cfg.Height) or 150
    local holder = create("Frame", { Name = tostring(cfg.Title or "Players"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height + (cfg.Title and 56 or 34)), LayoutOrder = card:_order(), Parent = card.body })
    local top = 0
    local title
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Size = UDim2.new(1, -90, 0, 20) })
        Theme.bind(title, "TextColor3", "text")
        top = 22
    end
    local count = label(holder, "", 9, { Name = "Count", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(90, 20), TextXAlignment = Enum.TextXAlignment.Right })
    Theme.bind(count, "TextColor3", "muted")
    local search = create("TextBox", {
        Name = "Search", Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, 26), BorderSizePixel = 0, Text = "",
        PlaceholderText = "Search players...", TextSize = 10, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false, Parent = holder,
    })
    Theme.bind(search, "BackgroundColor3", "input")
    Theme.bind(search, "TextColor3", "text")
    Theme.bind(search, "PlaceholderColor3", "muted")
    corner(search, 6)
    Theme.bind(stroke(search), "Color", "buttonEdge")
    Util.padding(search, 9, 9, 0, 0)
    local list = create("ScrollingFrame", {
        Name = "List", Position = UDim2.fromOffset(0, top + 32), Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = holder,
    })
    Theme.bind(list, "BackgroundColor3", "base")
    Theme.bind(list, "ScrollBarImageColor3", "muted")
    list.BackgroundTransparency = 0.4
    corner(list, 6)
    Theme.bind(stroke(list), "Color", "line")
    local inner = create("Frame", { Name = "Rows", BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = list })
    Util.list(inner, 2)
    Util.padding(inner, 0, 0, 0, 6)
    local empty = label(list, "No players", 10, { Name = "Empty", Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Center, Visible = false })
    Theme.bind(empty, "TextColor3", "muted")

    local element = Base.element(card, "PlayerList", cfg, holder, title, nil)
    local chosen = {} -- [userId] = true
    local rows = {}
    local function valueList()
        local ids = {}
        for id in pairs(chosen) do ids[#ids + 1] = id end
        table.sort(ids)
        return ids
    end
    local function renderRow(entry)
        local on = chosen[entry.player.UserId] == true
        entry.button.BackgroundTransparency = on and 0 or 1
        Theme.bind(entry.name, "TextColor3", on and "accent" or "text")
        entry.check.Visible = on
    end
    local function filter()
        local query = search.Text:lower()
        local shown = 0
        for _, entry in pairs(rows) do
            local player = entry.player
            local match = query == "" or player.Name:lower():find(query, 1, true) or player.DisplayName:lower():find(query, 1, true)
            entry.button.Visible = match ~= nil and match ~= false
            if entry.button.Visible then shown = shown + 1 end
        end
        empty.Visible = shown == 0
        local selected = 0
        for _ in pairs(chosen) do selected = selected + 1 end
        count.Text = selected > 0 and (selected .. " selected") or (#Players:GetPlayers() .. " players")
    end
    local function commit()
        element.Value = multi and valueList() or valueList()[1]
        for _, entry in pairs(rows) do renderRow(entry) end
        filter()
        element:_fire(element.Value)
    end
    local function addRow(player)
        if rows[player] or (player == Players.LocalPlayer and not cfg.IncludeSelf) then return end
        local button = create("TextButton", {
            Name = player.Name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, ROW), Parent = inner,
        })
        Theme.bind(button, "BackgroundColor3", "selected")
        corner(button, 5)
        local avatar = create("ImageLabel", { Position = UDim2.fromOffset(4, 3), Size = UDim2.fromOffset(24, 24), BorderSizePixel = 0, Parent = button })
        Theme.bind(avatar, "BackgroundColor3", "input")
        corner(avatar, 12)
        local name = label(button, player.DisplayName, 10, { Position = UDim2.fromOffset(36, 2), Size = UDim2.new(1, -60, 0, 14), Font = Enum.Font.GothamMedium })
        local user = label(button, "@" .. player.Name, 9, { Position = UDim2.fromOffset(36, 15), Size = UDim2.new(1, -60, 0, 12) })
        Theme.bind(user, "TextColor3", "muted")
        local check = create("Frame", { Name = "Check", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, Visible = false, Parent = button })
        Theme.bind(check, "BackgroundColor3", "accent")
        corner(check, 3)
        local entry = { player = player, button = button, name = name, check = check }
        rows[player] = entry
        button.MouseEnter:Connect(function() if not chosen[player.UserId] then button.BackgroundTransparency = 0.5 end end)
        button.MouseLeave:Connect(function() renderRow(entry) end)
        button.Activated:Connect(function()
            if element.Locked then return end
            local id = player.UserId
            if multi then
                chosen[id] = not chosen[id] or nil
            else
                local was = chosen[id]
                chosen = {}
                if not was then chosen[id] = true end
            end
            commit()
        end)
        task.spawn(function()
            local ok, image = pcall(function()
                return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
            if ok and avatar.Parent then avatar.Image = image end
        end)
        renderRow(entry)
        filter()
    end
    local function removeRow(player)
        local entry = rows[player]
        if entry then entry.button:Destroy() rows[player] = nil filter() end
    end
    for _, player in ipairs(Players:GetPlayers()) do addRow(player) end
    window.maid:connect(Players.PlayerAdded, addRow)
    window.maid:connect(Players.PlayerRemoving, removeRow)
    search:GetPropertyChangedSignal("Text"):Connect(filter)

    function element:Set(ids, silent)
        chosen = {}
        for _, id in ipairs(type(ids) == "table" and ids or { ids }) do
            id = tonumber(id)
            if id then chosen[id] = true end
            if not multi then break end
        end
        self.Value = multi and valueList() or valueList()[1]
        for _, entry in pairs(rows) do renderRow(entry) end
        filter()
        self:_fire(self.Value, silent)
    end
    function element:Get() return self.Value end
    function element:GetPlayers()
        local out = {}
        for _, player in ipairs(Players:GetPlayers()) do if chosen[player.UserId] then out[#out + 1] = player end end
        return out
    end
    function element:Clear() self:Set({}) end

    element:Set(cfg.Default or {}, true)
    return Base.finish(element, cfg)
end
end

__modules["elements/range"] = function()
-- card:Range({ Title, Desc, Flag, Min, Max, Default = { 20, 80 }, Step, Suffix, MinGap, Callback = function(range) end })
-- A slider with two handles; Value is { low, high }. Dragging moves the nearer handle; the values can be typed.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner = Util.create, Util.corner

return function(card, cfg)
    local window = card.window
    local min, max = tonumber(cfg.Min) or 0, tonumber(cfg.Max) or 100
    if max < min then min, max = max, min end
    local step = tonumber(cfg.Step) or 1
    local gap = math.max(0, tonumber(cfg.MinGap) or 0)
    local suffix = cfg.Suffix and (" " .. tostring(cfg.Suffix)) or ""
    local decimals = Util.decimals(step)
    local top = cfg.Desc and 38 or 22
    local row, title, desc = Base.row(card, cfg, top + 18, { right = 120, titleHeight = 22, helpRight = 116, helpY = 11 })

    -- "low – high suffix": two small boxes
    local boxes = create("Frame", { Name = "Values", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 1), Size = UDim2.fromOffset(116, 20), Parent = row })
    local function box(name, x)
        local object = create("TextBox", {
            Name = name, Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(52, 20), BackgroundTransparency = 0.7, BorderSizePixel = 0,
            Text = "", TextSize = 10, Font = Enum.Font.GothamMedium, ClearTextOnFocus = false, Parent = boxes,
        })
        Theme.bind(object, "BackgroundColor3", "base")
        Theme.bind(object, "TextColor3", "text")
        corner(object, 6)
        return object
    end
    local lowBox, highBox = box("Low", 0), box("High", 64)
    local dash = Util.label(boxes, "–", 10, { Position = UDim2.fromOffset(52, 0), Size = UDim2.fromOffset(12, 20), TextXAlignment = Enum.TextXAlignment.Center })
    Theme.bind(dash, "TextColor3", "muted")

    local track = create("Frame", { Name = "Track", Position = UDim2.new(0, 0, 0, top + 8), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, Parent = row })
    Theme.bind(track, "BackgroundColor3", "buttonEdge")
    corner(track, 1)
    local fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = track })
    Theme.bind(fill, "BackgroundColor3", "accent")
    local function knob(name)
        local object = create("Frame", { Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(10, 10), BorderSizePixel = 0, ZIndex = 2, Parent = track })
        Theme.bind(object, "BackgroundColor3", "accent")
        corner(object, 5)
        return object
    end
    local lowKnob, highKnob = knob("LowKnob"), knob("HighKnob")
    local hit = create("TextButton", { Name = "Hit", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.new(0, -6, 0, top), Size = UDim2.new(1, 12, 0, 18), ZIndex = 3, Parent = row })

    local element = Base.element(card, "Range", cfg, row, title, desc)
    local focused = {}
    local function format(value)
        return decimals > 0 and string.format("%." .. decimals .. "f", value) or tostring(math.floor(value + 0.5))
    end
    local function snap(value)
        value = math.clamp(Util.round(value - min, step) + min, min, max)
        if decimals > 0 then value = tonumber(string.format("%." .. decimals .. "f", value)) end
        return value
    end
    local function ratio(value) return max > min and (value - min) / (max - min) or 0 end
    local function render()
        local low, high = element.Value[1], element.Value[2]
        lowKnob.Position = UDim2.fromScale(ratio(low), 0.5)
        highKnob.Position = UDim2.fromScale(ratio(high), 0.5)
        fill.Position = UDim2.fromScale(ratio(low), 0)
        fill.Size = UDim2.fromScale(ratio(high) - ratio(low), 1)
        if not focused.low then lowBox.Text = format(low) .. (suffix ~= "" and suffix:sub(1, 3) or "") end
        if not focused.high then highBox.Text = format(high) .. (suffix ~= "" and suffix:sub(1, 3) or "") end
    end
    function element:Set(value, silent)
        if type(value) ~= "table" then return end
        local low, high = tonumber(value[1]) or min, tonumber(value[2]) or max
        if low > high then low, high = high, low end
        low, high = snap(low), snap(high)
        if high - low < gap then
            if low + gap <= max then high = snap(low + gap) else low = snap(high - gap) end
        end
        local old = self.Value
        self.Value = { low, high }
        render()
        self:_fire(self.Value, silent or (old and old[1] == low and old[2] == high))
    end
    function element:Get() return self.Value[1], self.Value[2] end

    local dragging
    local function fromPoint(point)
        local width = track.AbsoluteSize.X
        if width <= 0 then return end
        local value = min + math.clamp((point.X - track.AbsolutePosition.X) / width, 0, 1) * (max - min)
        if not dragging then
            -- grab the nearer handle (the high one when both sit on the same spot at the top end)
            local low, high = element.Value[1], element.Value[2]
            dragging = (math.abs(value - low) < math.abs(value - high) or (low == high and value < low)) and 1 or 2
        end
        local next = { element.Value[1], element.Value[2] }
        next[dragging] = value
        if dragging == 1 then next[1] = math.min(value, element.Value[2] - gap) else next[2] = math.max(value, element.Value[1] + gap) end
        element:Set(next)
    end
    hit.InputBegan:Connect(function(input)
        if not Util.isPress(input) or element.Locked then return end
        dragging = nil
        fromPoint(Util.pointer(input))
        window:_beginDrag(input, fromPoint, function() dragging = nil end)
    end)
    for key, object in pairs({ low = lowBox, high = highBox }) do
        object.Focused:Connect(function() focused[key] = true end)
        object.FocusLost:Connect(function()
            focused[key] = false
            local number = tonumber((object.Text:gsub("[^%d%.%-]", "")))
            if number then
                local next = { element.Value[1], element.Value[2] }
                next[key == "low" and 1 or 2] = number
                element:Set(next)
            end
            render()
        end)
    end

    local default = type(cfg.Default) == "table" and cfg.Default or { min, max }
    element.Value = { min, max }
    element:Set(default, true)
    return Base.finish(element, cfg)
end
end

__modules["elements/segment"] = function()
-- card:Segment({ Title, Desc, Flag, Options = { "Head", "Body", "Closest" }, Default, Callback, Locked })
-- One choice shown as a row of buttons (Qustah's Aim Part / Priority rows). On a narrow card the buttons move
-- under the title.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local options = {}
    for _, option in ipairs(cfg.Options or cfg.Values or {}) do options[#options + 1] = tostring(option) end
    local row, title, desc = Base.row(card, cfg, 40, {})
    title.Size = UDim2.new(0, 110, 0, cfg.Desc and 18 or 40)
    if desc then desc.Size = UDim2.new(0, 110, 0, 14) end
    local strip = create("Frame", {
        Name = "Segments", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 120, 0.5, 0),
        Size = UDim2.new(1, -120, 0, 28), Parent = row,
    })

    local element = Base.element(card, "Segment", cfg, row, title, desc)
    local buttons, outlines = {}, {}
    local function render(animate)
        local duration = animate and 0.12 or nil
        for index, option in ipairs(options) do
            local selected = option == element.Value
            Theme.tweenTo(buttons[index], "BackgroundColor3", selected and "selected" or "input", duration)
            Theme.tweenTo(buttons[index], "TextColor3", selected and "accent" or "muted", duration)
            Theme.tweenTo(outlines[index], "Color", selected and "accent" or "line", duration)
            outlines[index].Transparency = selected and 0.25 or 0.65
        end
    end
    for index, option in ipairs(options) do
        local button = create("TextButton", {
            Name = option, Text = option, TextSize = 10, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((index - 0.5) / #options, 0, 0.5, 0),
            Size = UDim2.new(1 / #options, -4, 0, 24), TextTruncate = Enum.TextTruncate.AtEnd, Parent = strip,
        })
        corner(button, 6)
        buttons[index], outlines[index] = button, stroke(button)
        button.Activated:Connect(function() if not element.Locked then element:Set(option) end end)
    end

    -- narrow card: title on top, buttons underneath
    local function fit()
        local stacked = row.AbsoluteSize.X > 0 and row.AbsoluteSize.X < 300
        row.Size = UDim2.new(1, 0, 0, stacked and 70 or (cfg.Desc and 46 or 40))
        strip.AnchorPoint = stacked and Vector2.new(0, 0) or Vector2.new(0, 0.5)
        strip.Position = stacked and UDim2.fromOffset(0, cfg.Desc and 40 or 30) or UDim2.new(0, 120, 0.5, 0)
        strip.Size = stacked and UDim2.new(1, 0, 0, 28) or UDim2.new(1, -120, 0, 28)
        title.Size = UDim2.new(stacked and 1 or 0, stacked and 0 or 110, 0, cfg.Desc and 18 or (stacked and 28 or 40))
    end
    row:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)

    function element:Set(value, silent)
        value = value ~= nil and tostring(value) or nil
        if value and not table.find(options, value) then return end
        local changed = value ~= self.Value
        self.Value = value
        render(true)
        self:_fire(value, silent or not changed)
    end
    function element:Get() return self.Value end

    element.Value = cfg.Default ~= nil and table.find(options, tostring(cfg.Default)) and tostring(cfg.Default) or options[1]
    render(false)
    fit()
    element:_fire(element.Value, true)
    return Base.finish(element, cfg)
end
end

__modules["elements/slider"] = function()
-- card:Slider({ Title, Desc, Flag, Min, Max, Default, Step, Suffix, Callback, Locked })
-- Drag the track, or click the value and type a number.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner = Util.create, Util.corner

return function(card, cfg)
    local window = card.window
    local min, max = tonumber(cfg.Min) or 0, tonumber(cfg.Max) or 100
    if max < min then min, max = max, min end
    local step = tonumber(cfg.Step) or 1
    local suffix = cfg.Suffix and (" " .. tostring(cfg.Suffix)) or ""
    local decimals = Util.decimals(step)
    local top = cfg.Desc and 38 or 22
    local row, title, desc = Base.row(card, cfg, top + 18, { right = 90, titleHeight = 22, helpRight = 84, helpY = 11 })

    local box = create("TextBox", {
        Name = "Value", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 1), Size = UDim2.fromOffset(78, 20),
        BackgroundTransparency = 0.7, BorderSizePixel = 0, Text = "", TextSize = 10, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false, Parent = row,
    })
    Theme.bind(box, "TextColor3", "text")
    Theme.bind(box, "BackgroundColor3", "base")
    corner(box, 6)
    local track = create("Frame", { Name = "Track", Position = UDim2.new(0, 0, 0, top + 8), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, Parent = row })
    Theme.bind(track, "BackgroundColor3", "buttonEdge")
    corner(track, 1)
    local fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = track })
    Theme.bind(fill, "BackgroundColor3", "accent")
    corner(fill, 1)
    local knob = create("Frame", { Name = "Knob", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(10, 10), BorderSizePixel = 0, ZIndex = 2, Parent = track })
    Theme.bind(knob, "BackgroundColor3", "accent")
    corner(knob, 5)
    local hit = create("TextButton", { Name = "Hit", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.new(0, -6, 0, top), Size = UDim2.new(1, 12, 0, 18), ZIndex = 3, Parent = row })

    local element = Base.element(card, "Slider", cfg, row, title, desc)
    local focused = false

    local function format(value)
        return (decimals > 0 and string.format("%." .. decimals .. "f", value) or tostring(math.floor(value + 0.5))) .. suffix
    end
    local function render()
        local ratio = max > min and (element.Value - min) / (max - min) or 0
        fill.Size = UDim2.fromScale(ratio, 1)
        knob.Position = UDim2.fromScale(ratio, 0.5)
        if not focused then box.Text = format(element.Value) end
    end
    function element:Set(value, silent)
        value = tonumber(value)
        if not value then render() return end
        value = math.clamp(Util.round(value - min, step) + min, min, max)
        if decimals > 0 then value = tonumber(string.format("%." .. decimals .. "f", value)) end
        local changed = value ~= self.Value
        self.Value = value
        render()
        self:_fire(value, silent or not changed)
    end
    function element:Get() return self.Value end
    function element:SetRange(newMin, newMax)
        min, max = tonumber(newMin) or min, tonumber(newMax) or max
        self:Set(self.Value)
    end

    local function fromPoint(point)
        local width = track.AbsoluteSize.X
        if width <= 0 then return end
        element:Set(min + math.clamp((point.X - track.AbsolutePosition.X) / width, 0, 1) * (max - min))
    end
    hit.InputBegan:Connect(function(input)
        if not Util.isPress(input) or element.Locked then return end
        fromPoint(Util.pointer(input))
        window:_beginDrag(input, fromPoint)
    end)
    box.Focused:Connect(function() focused = true end)
    box.FocusLost:Connect(function()
        focused = false
        local number = tonumber((box.Text:gsub("[^%d%.%-]", "")))
        if number then element:Set(number) else render() end
        render()
    end)

    element.Value = math.clamp(tonumber(cfg.Default) or min, min, max)
    render()
    element:_fire(element.Value, true)
    return Base.finish(element, cfg)
end
end

__modules["elements/swatches"] = function()
-- card:Swatches({ Title, Desc, Flag, Colors = { { "Neutral", Color3 }, { "Blue", Color3 }, ... }, Default = "Blue", Columns = 4, Callback = function(color, name) end })
-- Named colour presets as a grid (Qustah's accent picker). Value is the chosen name; Callback gets the Color3 and the name.
-- Without Colors it uses Qustah's eight accent presets.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

local PRESETS = {
    { "Neutral", Color3.fromRGB(177, 178, 183) }, { "Blue", Color3.fromRGB(61, 151, 219) },
    { "Red", Color3.fromRGB(220, 110, 110) }, { "Purple", Color3.fromRGB(165, 125, 230) },
    { "Pink", Color3.fromRGB(225, 120, 180) }, { "Green", Color3.fromRGB(110, 200, 130) },
    { "Orange", Color3.fromRGB(215, 170, 105) }, { "Cyan", Color3.fromRGB(100, 200, 210) },
}

return function(card, cfg)
    local colors = cfg.Colors or PRESETS
    local maxColumns = math.max(1, tonumber(cfg.Columns) or 4)
    local columns = maxColumns
    local rowsCount = math.ceil(#colors / columns)
    local top = (cfg.Title and 20 or 0) + (cfg.Desc and 16 or 0) + (cfg.Title and 4 or 0)
    local holder = create("Frame", { Name = tostring(cfg.Title or "Swatches"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, top + rowsCount * 34), LayoutOrder = card:_order(), Parent = card.body })
    local title, desc
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Size = UDim2.new(1, 0, 0, 20) })
        Theme.bind(title, "TextColor3", "text")
    end
    if cfg.Desc then
        desc = label(holder, tostring(cfg.Desc), 9, { Name = "Desc", Position = UDim2.fromOffset(0, cfg.Title and 20 or 0), Size = UDim2.new(1, 0, 0, 14) })
        Theme.bind(desc, "TextColor3", "muted")
    end
    local grid = create("Frame", { Name = "Grid", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 1, -top), Parent = holder })

    local element = Base.element(card, "Swatches", cfg, holder, title, desc)
    local entries, byName = {}, {}
    local function render()
        for _, entry in ipairs(entries) do
            local on = entry.name == element.Value
            Theme.tweenTo(entry.button, "BackgroundColor3", on and "selected" or "card", 0.1)
            Theme.tweenTo(entry.text, "TextColor3", on and "heading" or "muted", 0.1)
            entry.outline.Transparency = on and 0.3 or 1
        end
    end
    for index, item in ipairs(colors) do
        local name, color = tostring(item[1] or item.Name), item[2] or item.Color
        local button = create("TextButton", { Name = name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = index, Parent = grid })
        corner(button, 6)
        local outline = stroke(button, Color3.new(1, 1, 1), 1)
        Theme.bind(outline, "Color", "accent")
        local dot = create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.fromOffset(14, 14), BorderSizePixel = 0, BackgroundColor3 = color, Parent = button })
        corner(dot, 4)
        local text = label(button, name, 10, { Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -32, 1, 0) })
        local entry = { name = name, color = color, button = button, text = text, outline = outline }
        entries[#entries + 1] = entry
        byName[name] = entry
        button.MouseEnter:Connect(function() if element.Value ~= name then Theme.tweenTo(button, "BackgroundColor3", "input", 0.1) end end)
        button.MouseLeave:Connect(render)
        button.Activated:Connect(function() if not element.Locked then element:Set(name) end end)
    end

    -- columns follow the width (about 90 px per chip, at most Columns)
    local function place()
        local width = holder.AbsoluteSize.X
        columns = width > 0 and math.clamp(math.floor((width + 6) / 90), 2, maxColumns) or maxColumns
        columns = math.min(columns, math.max(1, #entries))
        for index, entry in ipairs(entries) do
            local column, line = (index - 1) % columns, (index - 1) // columns
            entry.button.Position = UDim2.new(column / columns, column == 0 and 0 or 3, 0, line * 34)
            entry.button.Size = UDim2.new(1 / columns, -6 + (column == 0 and 3 or 0) + (column == columns - 1 and 3 or 0), 0, 28)
        end
        holder.Size = UDim2.new(1, 0, 0, top + math.ceil(#entries / columns) * 34)
    end
    holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        local before = columns
        local width = holder.AbsoluteSize.X
        local want = width > 0 and math.min(math.clamp(math.floor((width + 6) / 90), 2, maxColumns), #entries) or maxColumns
        if want ~= before then place() end
    end)
    place()

    function element:Set(name, silent)
        if typeof(name) == "Color3" then -- pick the preset with this colour
            for _, entry in ipairs(entries) do if entry.color == name then name = entry.name break end end
        end
        local entry = byName[tostring(name)]
        if not entry then return end
        local changed = entry.name ~= self.Value
        self.Value = entry.name
        self.Color = entry.color
        render()
        if self.Flag then card.window.Lib.Flags[self.Flag] = entry.name end
        if not silent and changed then
            local source = tostring(cfg.Title or "Swatches")
            card.window:_safe(source, cfg.Callback, entry.color, entry.name)
            for _, callback in ipairs(self._changed) do card.window:_safe(source, callback, entry.color, entry.name) end
        end
    end
    function element:Get() return self.Value, self.Color end

    element:Set(cfg.Default or (entries[1] and entries[1].name), true)
    return Base.finish(element, cfg)
end
end

__modules["elements/toggle"] = function()
-- card:Toggle({ Title, Desc, Flag, Default, Callback, Bindable, Bind, Locked, LockedTitle })
-- Click the row or the switch to flip it. With Bindable (or a Bind key) right-click the row to assign a key
-- (Backspace clears, Escape cancels); the key flips the toggle while the menu is closed too.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner = Util.create, Util.corner

return function(card, cfg)
    local window = card.window
    local bindable = cfg.Bindable or cfg.Bind ~= nil
    local row, title, desc = Base.row(card, cfg, cfg.Desc and 46 or 36, { button = true, right = 50, helpRight = 44 })
    local switch = create("TextButton", {
        Name = "Switch", Text = "", AutoButtonColor = false, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(34, 18), Parent = row,
    })
    corner(switch, 9)
    local rim = Util.stroke(switch, nil, 0.18)
    local knob = create("Frame", { Name = "Knob", Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(14, 14), BorderSizePixel = 0, Parent = switch })
    corner(knob, 7)

    -- Marker = true: accent bar on the left (a featured setting); Badge = "ANTI BB": small tag after the title
    if cfg.Marker then
        local marker = create("Frame", { Name = "Marker", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 24), BorderSizePixel = 0, BackgroundTransparency = 0.15, Parent = row })
        Theme.bind(marker, "BackgroundColor3", "accent")
        corner(marker, 2)
        title.Position = UDim2.new(0, 12, 0, title.Position.Y.Offset)
        if desc then desc.Position = UDim2.fromOffset(12, desc.Position.Y.Offset) end
    end
    if cfg.Badge then
        local text = tostring(cfg.Badge)
        local width = Util.textWidth(text, 9, Enum.Font.GothamMedium) + 16
        local titleWidth = Util.textWidth(tostring(cfg.Title or ""), 11, Enum.Font.Gotham)
        local badge = create("Frame", {
            Name = "Badge", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, title.Position.X.Offset + titleWidth + 10, 0, title.Position.Y.Offset + title.Size.Y.Offset / 2),
            Size = UDim2.fromOffset(width, 18), BorderSizePixel = 0, Parent = row,
        })
        Theme.bind(badge, "BackgroundColor3", "input")
        corner(badge, 6)
        Theme.bind(Util.stroke(badge, nil, 0.45), "Color", "buttonEdge")
        local badgeText = Util.label(badge, text, 9, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamMedium })
        Theme.bind(badgeText, "TextColor3", "muted")
    end

    local element = Base.element(card, "Toggle", cfg, row, title, desc)
    element.Value = cfg.Default == true

    local function render(animate)
        local on = element.Value
        local duration = animate and 0.15 or nil
        -- Qustah switch: on = input tinted with the accent, knob always light grey, accent rim when on
        Theme.tweenTo(switch, "BackgroundColor3", on and "toggleOn" or "buttonEdge", duration)
        Theme.bind(knob, "BackgroundColor3", "knob")
        Theme.tweenTo(rim, "Color", on and "accent" or "line", duration)
        rim.Transparency = on and 0.6 or 0.18
        local position = UDim2.fromOffset(on and 18 or 2, 2)
        if animate then Util.tween(knob, 0.15, { Position = position }) else knob.Position = position end
    end

    function element:Set(value, silent)
        value = value == true
        local changed = value ~= self.Value
        self.Value = value
        render(true)
        if changed then self:_fire(value, silent) else self:_fire(value, true) end
    end
    function element:Get() return self.Value end

    ------------------------------------------------------------ key bind
    local tag
    function element:SetBind(key)
        key = Util.toKey(key)
        self.BindKey = key
        window:_bind(self, key)
        if tag then
            tag.Text = key and ("[" .. Util.keyName(key) .. "]") or ""
            tag.Visible = key ~= nil
            -- make room for the key tag only while a key is bound
            local reserve = (key and 100 or 50) + (cfg.Help and 16 or 0)
            title.Size = UDim2.new(1, -reserve, 0, title.Size.Y.Offset)
            if desc then desc.Size = UDim2.new(1, -reserve, 0, 14) end
        end
    end
    function element:_onBind() if not self.Locked then self:Set(not self.Value) end end
    if bindable then
        tag = Util.label(row, "", 9, {
            Name = "Bind", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, cfg.Help and -62 or -42, 0.5, 0), Size = UDim2.fromOffset(48, 18),
            TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium, Visible = false,
        })
        Theme.bind(tag, "TextColor3", "muted")
        row.MouseButton2Click:Connect(function()
            if element.Locked then return end
            tag.Text, tag.Visible = "[...]", true
            title.Size = UDim2.new(1, -(100 + (cfg.Help and 16 or 0)), 0, title.Size.Y.Offset)
            window._capture = function(key)
                if key == Enum.KeyCode.Escape then element:SetBind(element.BindKey)
                elseif key == Enum.KeyCode.Backspace then element:SetBind(nil)
                else element:SetBind(key) end
            end
        end)
        element:SetBind(cfg.Bind)
        function element:_save() return { Value = self.Value, Bind = self.BindKey and self.BindKey.Name or nil } end
        function element:_load(data)
            if type(data) == "table" then self:SetBind(data.Bind) self:Set(data.Value) else self:Set(data) end
        end
    end

    local function flip() if not element.Locked then element:Set(not element.Value) end end
    row.Activated:Connect(flip)
    switch.Activated:Connect(flip)
    row.MouseEnter:Connect(function() Theme.tweenTo(title, "TextColor3", "heading", 0.12) end)
    row.MouseLeave:Connect(function() Theme.tweenTo(title, "TextColor3", "text", 0.12) end)

    render(false)
    element:_fire(element.Value, true)
    return Base.finish(element, cfg)
end
end

__modules["glow"] = function()
-- Text glow: a light band slides across a label every few seconds, with a soft outline (Qustah's text glow).
-- Glow.add(label, { Base = "accent", Shine = "heading", Period = 3.2, Phase = 0 }) - colours are theme roles.
-- Glow.setEnabled(false) turns every glow off (plain text colour again).
local Util = require("util")
local Theme = require("theme")

local Glow = { enabled = true, items = {}, started = false }

local WHITE = Color3.new(1, 1, 1)

local function colors(fx)
    local base = Theme.get(fx.base)
    local shine = fx.shine and Theme.get(fx.shine) or base:Lerp(WHITE, 0.6)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, base), ColorSequenceKeypoint.new(0.36, base), ColorSequenceKeypoint.new(0.5, shine),
        ColorSequenceKeypoint.new(0.64, base), ColorSequenceKeypoint.new(1, base),
    }), base
end

local function apply(fx)
    local sequence, base = colors(fx)
    fx.gradient.Color = sequence
    fx.outline.Color = base
    fx.gradient.Enabled, fx.outline.Enabled = Glow.enabled, Glow.enabled
    -- with the glow on, the label is white and the gradient carries the colour
    Theme.bind(fx.label, "TextColor3", Glow.enabled and WHITE or fx.base)
end

-- The label must already be parented; it keeps its own theme role as Base.
function Glow.add(label, opts)
    opts = opts or {}
    local fx = {
        label = label, base = opts.Base or "text", shine = opts.Shine, period = opts.Period or 3.2, phase = opts.Phase or 0,
        gradient = Util.create("UIGradient", { Name = "Shine", Offset = Vector2.new(-1.2, 0), Parent = label }),
        outline = Util.create("UIStroke", {
            Name = "Glow", ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Round,
            Thickness = 1, Transparency = opts.GlowTransparency or 0.88, Parent = label,
        }),
    }
    Glow.items[#Glow.items + 1] = fx
    apply(fx)
    return fx
end

function Glow.setEnabled(enabled)
    Glow.enabled = enabled ~= false
    for _, fx in ipairs(Glow.items) do if fx.label.Parent then apply(fx) end end
end

local function visible(object)
    while object do
        if object:IsA("GuiObject") and not object.Visible then return false end
        if object:IsA("LayerCollector") then return object.Enabled end
        object = object.Parent
    end
    return false
end

-- One RenderStepped loop for all glows; hidden labels are skipped, destroyed ones dropped.
function Glow.start(maid)
    if Glow.started then return end
    Glow.started = true
    maid:connect(Util.Services.RunService.RenderStepped, function()
        if not Glow.enabled then return end
        local now = os.clock()
        for index = #Glow.items, 1, -1 do
            local fx = Glow.items[index]
            if not fx.label.Parent then
                table.remove(Glow.items, index)
            elseif visible(fx.label) then
                local p = ((now / fx.period) + fx.phase) % 1
                fx.gradient.Offset = Vector2.new(p < 0.6 and (-1.2 + (p / 0.6) * 2.4) or 1.2, 0)
            end
        end
    end)
    maid:give(function() Glow.started = false end)
    Theme.onChange(function() for _, fx in ipairs(Glow.items) do if fx.label.Parent then apply(fx) end end end)
end

return Glow
end

__modules["hud"] = function()
-- On-screen overlays outside the menu (they stay while the menu is hidden):
--   Window:KeybindList(true / false)   draggable list of bound keys; toggles that are on are bright
--   Window:SessionBar(true / false)    "60 FPS · 40 ms · 2/50 · 00:12:03" at the top of the screen
--   Window:StatsMonitor("Header" | "Floating" | "Off")   FPS / ping in the header or in a small draggable graph
-- Positions of the draggable panels are remembered with the window (see Window memory).
local Util = require("util")
local Theme = require("theme")
local Stats = require("stats")

local Services = Util.Services
local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

return function(Window)
    -- A small draggable panel in the window's ScreenGui, kept on screen; position saved as a 0-1 fraction.
    function Window:_floating(name, width, height, default)
        local panel = create("Frame", {
            Name = name, Size = UDim2.fromOffset(width, height), BorderSizePixel = 0, BackgroundTransparency = 0.04,
            Visible = false, ZIndex = 70, Parent = self.gui,
        })
        Theme.bind(panel, "BackgroundColor3", "base")
        corner(panel, 8)
        Theme.bind(stroke(panel, nil, 0.4), "Color", "line")
        local handle = create("TextButton", { Name = "Handle", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), ZIndex = 71, Parent = panel })
        local saved = self.memory and self.memory.hud and self.memory.hud[name]
        local fraction = saved and Vector2.new(tonumber(saved[1]) or default.X, tonumber(saved[2]) or default.Y) or default
        local function place()
            local viewport = Util.viewport()
            local room = Vector2.new(math.max(0, viewport.X - panel.AbsoluteSize.X), math.max(0, viewport.Y - panel.AbsoluteSize.Y))
            panel.Position = UDim2.fromOffset(math.floor(fraction.X * room.X), math.floor(fraction.Y * room.Y))
        end
        handle.InputBegan:Connect(function(input)
            if not Util.isPress(input) then return end
            local start, origin = Util.pointer(input), Vector2.new(panel.Position.X.Offset, panel.Position.Y.Offset)
            self:_beginDrag(input, function(point)
                local viewport = Util.viewport()
                local room = Vector2.new(math.max(1, viewport.X - panel.AbsoluteSize.X), math.max(1, viewport.Y - panel.AbsoluteSize.Y))
                local target = origin + (point - start)
                fraction = Vector2.new(math.clamp(target.X / room.X, 0, 1), math.clamp(target.Y / room.Y, 0, 1))
                place()
            end, function()
                self.memory.hud = self.memory.hud or {}
                self.memory.hud[name] = { fraction.X, fraction.Y }
                self:_saveMemory()
            end)
        end)
        self.maid:connect(panel:GetPropertyChangedSignal("AbsoluteSize"), place)
        self._placers = self._placers or {}
        table.insert(self._placers, place)
        place()
        return panel, handle
    end

    ------------------------------------------------------------------ keybind list
    local function chordText(element)
        if element.Chord then
            local mod, key = element.Chord[1], element.Chord[2]
            return (mod and (Util.keyName(mod) .. " + ") or "") .. Util.keyName(key)
        end
        return Util.keyName(element.Value or element.BindKey)
    end
    function Window:KeybindList(visible)
        visible = visible ~= false
        if not self._keybindHud then
            local panel, handle = self:_floating("Keybinds", 210, 60, Vector2.new(0.02, 0.18))
            local caption = label(handle, "Keybinds", 10, { Position = UDim2.fromOffset(12, 3), Size = UDim2.new(1, -24, 1, -3), ZIndex = 72 })
            Theme.bind(caption, "TextColor3", "muted")
            local list = create("Frame", { Name = "List", BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 30), Size = UDim2.new(1, -24, 1, -36), ZIndex = 71, Parent = panel })
            Util.list(list, 2)
            local rows = {}
            local function row(index)
                if rows[index] then return rows[index] end
                local holder = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = index, ZIndex = 72, Parent = list })
                local name = label(holder, "", 10, { Size = UDim2.new(1, -74, 1, 0), ZIndex = 73 })
                local key = label(holder, "", 9, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 72, 1, 0), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium, ZIndex = 73 })
                Theme.bind(key, "TextColor3", "muted")
                rows[index] = { holder = holder, name = name, key = key }
                return rows[index]
            end
            local function refresh()
                local entries = { { title = "Menu", key = Util.keyName(self.key), on = true } }
                for element, bound in pairs(self.binds) do
                    if bound and element.Row and element.Row.Parent and element.Title then
                        local on = element.Type == "Toggle" and element.Value == true or element.Type ~= "Toggle"
                        entries[#entries + 1] = { title = tostring(element.Title), key = chordText(element), on = on, toggle = element.Type == "Toggle" }
                    end
                end
                table.sort(entries, function(a, b)
                    if a.on ~= b.on then return a.on end
                    return a.title < b.title
                end)
                for index, entry in ipairs(entries) do
                    local r = row(index)
                    r.holder.Visible = true
                    r.name.Text, r.key.Text = entry.title, "[" .. entry.key .. "]"
                    Theme.bind(r.name, "TextColor3", entry.on and "heading" or "muted")
                end
                for index = #entries + 1, #rows do rows[index].holder.Visible = false end
                panel.Size = UDim2.fromOffset(210, 36 + #entries * 22)
            end
            self._keybindHud = { panel = panel, refresh = refresh }
            task.spawn(function()
                while self.alive do
                    if panel.Visible then refresh() end
                    task.wait(0.5)
                end
            end)
        end
        self._keybindHud.panel.Visible = visible
        if visible then self._keybindHud.refresh() end
    end

    ------------------------------------------------------------------ session bar
    function Window:SessionBar(visible)
        visible = visible ~= false
        if not self._sessionBar then
            Stats.start(self.Lib.maid)
            local started = os.clock()
            local bar = create("Frame", {
                Name = "SessionBar", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 20), Size = UDim2.fromOffset(300, 30),
                BorderSizePixel = 0, BackgroundTransparency = 0.04, Visible = false, ZIndex = 70, Parent = self.gui,
            })
            Theme.bind(bar, "BackgroundColor3", "base")
            corner(bar, 8)
            Theme.bind(stroke(bar, nil, 0.4), "Color", "line")
            local text = label(bar, "", 10, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 71 })
            Theme.bind(text, "TextColor3", "text")
            local Players = Services.Players
            local function refresh()
                text.Text = string.format("%d FPS  ·  %d ms  ·  %d/%d  ·  %s", Stats.fps, Stats.ping, #Players:GetPlayers(), Players.MaxPlayers, Util.clock(os.clock() - started))
            end
            self.maid:give(Stats.listen(function() if bar.Visible then refresh() end end))
            self._sessionBar = { bar = bar, refresh = refresh }
        end
        self._sessionBar.bar.Visible = visible
        if visible then self._sessionBar.refresh() end
    end

    ------------------------------------------------------------------ stats monitor
    function Window:StatsMonitor(mode)
        mode = mode == true and "Header" or (mode == false and "Off" or tostring(mode or "Header"))
        Stats.start(self.Lib.maid)
        if not self._monitor then
            local header = label(self.main, "", 10, {
                Name = "HeaderStats", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(170, 20),
                TextXAlignment = Enum.TextXAlignment.Center, RichText = true, Visible = false,
            })
            Theme.bind(header, "TextColor3", "muted")
            local panel, handle = self:_floating("Performance", 190, 96, Vector2.new(0.98, 0.04))
            local caption = label(handle, "Performance", 10, { Position = UDim2.fromOffset(12, 3), Size = UDim2.new(0.5, 0, 1, -3), ZIndex = 72 })
            Theme.bind(caption, "TextColor3", "muted")
            local values = label(handle, "", 10, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 3), Size = UDim2.new(0.6, 0, 1, -3), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium, ZIndex = 72 })
            Theme.bind(values, "TextColor3", "text")
            local graph = create("Frame", { Name = "Graph", BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 32), Size = UDim2.new(1, -24, 1, -42), ZIndex = 71, Parent = panel })
            local bars = {}
            for index = 1, 30 do
                local bar = create("Frame", {
                    AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((index - 1) / 30, 0, 1, 0), Size = UDim2.new(1 / 30, -1, 0, 1),
                    BorderSizePixel = 0, BackgroundTransparency = 0.25, ZIndex = 72, Parent = graph,
                })
                Theme.bind(bar, "BackgroundColor3", "accent")
                bars[index] = bar
            end
            local function refresh()
                local text = string.format("FPS %d  ·  PING %d ms", Stats.fps, Stats.ping)
                header.Text, values.Text = text, string.format("%d FPS · %d ms", Stats.fps, Stats.ping)
                if panel.Visible then
                    local history = Stats.history.fps
                    local top = 60
                    for _, value in ipairs(history) do top = math.max(top, value) end
                    for index = 1, 30 do
                        local value = history[#history - 30 + index]
                        bars[index].Size = UDim2.new(1 / 30, -1, value and math.clamp(value / top, 0.03, 1) or 0, value and 0 or 1)
                    end
                end
            end
            self.maid:give(Stats.listen(function() if header.Visible or panel.Visible then refresh() end end))
            self._monitor = { header = header, panel = panel, refresh = refresh }
        end
        self.monitorMode = mode
        self._monitor.header.Visible = mode == "Header"
        self._monitor.panel.Visible = mode == "Floating"
        self._monitor.refresh()
        self:_updateLocation()
    end
end
end

__modules["init"] = function()
-- qustah-ui-lib: entry point. The build script bundles every module into dist/qustah-ui-lib.lua.
local Util = require("util")
local Theme = require("theme")
local Window = require("window")
local Notify = require("notify")
local Settings = require("settings")
local Dashboard = require("dashboard")
require("status")(Window)
require("dialog")(Window)
require("hud")(Window)

local Lib = {
    Version = "1.1.0",
    Flags = {},   -- Flag -> current value of every flagged element
    Windows = {},
    Theme = Theme,
    Util = Util,
}
Lib.maid = Util.maid()

-- Lib:CreateWindow({ Title, Version, Size = Vector2, ToggleKey = Enum.KeyCode, Accent = Color3, Folder, Footer, OnClose })
function Lib:CreateWindow(cfg) return Window.new(self, cfg) end
-- Lib:Notify({ Title, Content, Duration, Color })
function Lib:Notify(cfg) return Notify.show(self, cfg) end
function Lib:SetAccent(color) Theme.set("accent", color) end
-- Any colour role: base, card, input, line, text, muted, heading, accent ...
function Lib:SetColor(role, color) Theme.set(role, color) end
function Lib:GetFlag(flag) return self.Flags[flag] end
function Lib:Destroy()
    for index = #self.Windows, 1, -1 do self.Windows[index]:Destroy() end
    self.maid:clean()
end

function Window:SettingsTab(cfg) return Settings(self, cfg) end
function Window:DashboardTab(cfg) return Dashboard(self, cfg) end

return Lib
end

__modules["notify"] = function()
-- Toast notifications, bottom-right: Lib:Notify({ Title, Content, Duration = 3 }).
local Util = require("util")
local Theme = require("theme")

local create, corner, stroke, label, tween = Util.create, Util.corner, Util.stroke, Util.label, Util.tween

local Notify = {}

function Notify.holder(Lib)
    if Lib._notifyHolder and Lib._notifyHolder.Parent then return Lib._notifyHolder end
    local gui = Util.screenGui("QustahUI_Notifications", 60)
    Lib.maid:give(gui)
    local holder = create("Frame", {
        Name = "Toasts", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 250, 1, -32), Parent = gui,
    })
    Util.list(holder, 6, nil, nil, Enum.VerticalAlignment.Bottom)
    Lib._notifyHolder = holder
    return holder
end

function Notify.show(Lib, cfg)
    if type(cfg) == "string" then cfg = { Title = cfg } end
    cfg = cfg or {}
    local holder = Notify.holder(Lib)
    Lib._toastOrder = (Lib._toastOrder or 0) + 1
    local duration = tonumber(cfg.Duration) or 3
    local hasContent = cfg.Content ~= nil and cfg.Content ~= ""
    local height = hasContent and 50 or 34
    local toast = create("CanvasGroup", {
        Name = "Toast", Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, GroupTransparency = 1,
        LayoutOrder = Lib._toastOrder, Parent = holder,
    })
    Theme.bind(toast, "BackgroundColor3", "card")
    corner(toast, 8)
    Theme.bind(stroke(toast), "Color", "line")
    local marker = create("Frame", { Position = UDim2.fromOffset(12, 10), Size = UDim2.new(0, 3, 1, -20), BorderSizePixel = 0, Parent = toast })
    corner(marker, 2)
    local progress = create("Frame", { Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, Parent = toast })
    if typeof(cfg.Color) == "Color3" then
        marker.BackgroundColor3, progress.BackgroundColor3 = cfg.Color, cfg.Color
    else
        Theme.bind(marker, "BackgroundColor3", "accent")
        Theme.bind(progress, "BackgroundColor3", "accent")
    end
    local title = label(toast, tostring(cfg.Title or ""), 11, { Position = UDim2.fromOffset(23, hasContent and 8 or 0), Size = UDim2.new(1, -32, 0, hasContent and 17 or height), Font = Enum.Font.GothamBold })
    Theme.bind(title, "TextColor3", "heading")
    if hasContent then
        local content = label(toast, tostring(cfg.Content), 10, { Position = UDim2.fromOffset(23, 25), Size = UDim2.new(1, -32, 0, 16) })
        Theme.bind(content, "TextColor3", "muted")
    end
    tween(toast, 0.2, { GroupTransparency = 0 })
    tween(progress, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
    task.delay(duration, function()
        if not toast.Parent then return end
        tween(toast, 0.3, { GroupTransparency = 1 })
        task.delay(0.32, function() if toast.Parent then toast:Destroy() end end)
    end)
    return toast
end

return Notify
end

__modules["settings"] = function()
-- Window:SettingsTab({ Title, Icon, Divider }) - ready-made tab (create it LAST, after every other tab):
--   Interface  accent presets + custom colour, text glow, menu key, overlays (keybind list, session bar,
--              performance monitor), window reset / unload
--   Profiles   profile manager: create, load, overwrite, rename, duplicate, delete, autoload; a locked
--              "Default" profile holds the values the script started with
--   Info       versions, modules, error list with Copy report / Clear
local Util = require("util")
local Theme = require("theme")
local Glow = require("glow")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label
local RED, GREEN = Color3.fromRGB(215, 130, 130), Color3.fromRGB(110, 200, 130)

return function(window, cfg)
    cfg = cfg or {}
    local defaultSize = Vector2.new(window.width, window.height)
    local tab = window:Tab({ Title = cfg.Title or "Settings", Icon = cfg.Icon or "rbxassetid://11385220704", Divider = cfg.Divider ~= false, Header = cfg.Header ~= false })
    local interface = tab:Page("Interface")
    local profiles = tab:Page("Profiles", { Columns = 1 })
    local infoPage = tab:Page("Info")

    ------------------------------------------------------------ interface
    local look = interface:Card({ Title = "Appearance", Side = "Left" })
    local picker
    local swatches = look:Swatches({
        Title = "Accent", Default = "Neutral",
        Callback = function(color) if picker then picker:Set(color) end end,
    })
    picker = look:ColorPicker({
        Title = "Custom accent", Desc = "Any colour, saved with the profile", Flag = "__ui_accent", Default = Theme.get("accent"),
        Callback = function(color) Theme.set("accent", color) swatches:Set(color, true) end,
    })
    swatches:Set(Theme.get("accent"), true)
    look:Toggle({
        Title = "Text glow", Desc = "Shine on the title and highlights", Flag = "__ui_glow", Default = Glow.enabled,
        Callback = function(on) Glow.setEnabled(on) end,
    })

    local menu = interface:Card({ Title = "Menu", Side = "Right" })
    local menuKey = menu:Keybind({
        Title = "Menu key", Desc = "Opens and closes the menu", Flag = "__ui_menu_key", Default = window.key,
        Callback = function(key) window:SetToggleKey(key) end,
    })
    window._menuListeners = window._menuListeners or {}
    table.insert(window._menuListeners, function(key) if menuKey.Value ~= key then menuKey:Set(key, true) end end)
    menu:Button({
        Title = "Reset window", Desc = "Size and position",
        Callback = function()
            window.width, window.height, window.topLeft = defaultSize.X, defaultSize.Y, nil
            window.memory.window = nil
            window:_layout()
            window:_saveMemory()
        end,
    })
    menu:Button({
        Title = "Unload",
        Callback = function()
            window:Confirm("Unload " .. window.Title .. "?", "The menu and everything it runs will be removed.", function() window:Destroy() end, "Unload", true)
        end,
    })

    local overlays = interface:Card({ Title = "Overlays", Side = "Right" })
    overlays:Toggle({ Title = "Keybind list", Desc = "Bound keys on screen", Flag = "__ui_hud_keys", Callback = function(on) window:KeybindList(on) end })
    overlays:Toggle({ Title = "Session bar", Desc = "FPS · ping · players · time", Flag = "__ui_hud_session", Callback = function(on) window:SessionBar(on) end })
    overlays:Dropdown({
        Title = "Performance", Options = { "Off", "Header", "Floating" }, Default = "Off", Flag = "__ui_hud_stats",
        Callback = function(mode) window:StatsMonitor(mode) end,
    })

    ------------------------------------------------------------ profiles
    local store = window.Config
    local defaults = store:Snapshot() -- values every flag had before any profile was loaded
    local manager = profiles:Card({ Title = "Profiles" })
    local nameInput = manager:Input({ Title = "New profile", Placeholder = "profile name" })
    local feedback
    local refresh
    local function say(text, bad)
        feedback:Set(text)
        feedback:SetColor(bad and RED or GREEN)
    end
    manager:Button({
        Title = "Create from current settings",
        Callback = function()
            local name = nameInput.Value
            if not name or name == "" then return say("Type a name first", true) end
            if name:lower() == "default" then return say("\"Default\" is reserved", true) end
            if store:Exists(name) then return say("\"" .. name .. "\" already exists - open it and press Overwrite", true) end
            local ok, err = store:Save(name)
            if ok then
                local meta = store:ReadMeta()
                meta[name] = { saved = os.time() }
                store:WriteMeta(meta)
                nameInput:Set("", true)
            end
            say(ok and ("Created \"" .. name .. "\"") or err, not ok)
            refresh()
        end,
    })
    feedback = manager:Label("")

    local listCard = profiles:Card({ Title = "Saved" })
    local holder = create("Frame", { Name = "ProfileList", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = listCard:_order(), Parent = listCard.body })
    Util.list(holder, 4)
    local open -- name of the expanded profile

    local function smallButton(parent, text, order, style)
        local button = create("TextButton", {
            Name = text, Text = text, TextSize = 9, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BorderSizePixel = 0,
            Size = UDim2.fromOffset(Util.textWidth(text, 9, Enum.Font.GothamMedium) + 18, 22), LayoutOrder = order, Parent = parent,
        })
        corner(button, 6)
        local outline = stroke(button)
        if style == "Danger" then
            button.BackgroundColor3, button.TextColor3, outline.Color, outline.Transparency = Color3.fromRGB(70, 32, 36), Color3.fromRGB(235, 150, 155), Color3.fromRGB(150, 60, 66), 0.3
        elseif style == "Primary" then
            Theme.bind(button, "BackgroundColor3", "accentDeep")
            Theme.bind(button, "TextColor3", "accent")
            Theme.bind(outline, "Color", "accent")
            outline.Transparency = 0.5
        else
            Theme.bind(button, "BackgroundColor3", "input")
            Theme.bind(button, "TextColor3", "text")
            Theme.bind(outline, "Color", "buttonEdge")
        end
        return button
    end

    local function profileRow(name, order, locked, autoload, meta)
        local frame = create("Frame", { Name = "Profile_" .. name, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, LayoutOrder = order, Parent = holder })
        Theme.bind(frame, "BackgroundColor3", open == name and "selected" or "input")
        corner(frame, 6)
        Theme.bind(stroke(frame), "Color", open == name and "buttonEdge" or "line")
        Util.list(frame, 0)
        local head = create("TextButton", { Name = "Head", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 1, Parent = frame })
        local dot = create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, Parent = head })
        Theme.bind(dot, "BackgroundColor3", autoload and "accent" or "buttonEdge")
        corner(dot, 3)
        local title = label(head, name, 11, { Position = UDim2.fromOffset(26, 0), Size = UDim2.new(0.5, -26, 1, 0), Font = Enum.Font.GothamMedium })
        Theme.bind(title, "TextColor3", open == name and "heading" or "text")
        local tags = {}
        if locked then tags[#tags + 1] = "locked" end
        if autoload then tags[#tags + 1] = "autoload" end
        if meta and meta.saved then tags[#tags + 1] = os.date("%d %b %H:%M", meta.saved) end
        local info = label(head, table.concat(tags, "  ·  "), 9, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0.5, -12, 1, 0), TextXAlignment = Enum.TextXAlignment.Right })
        Theme.bind(info, "TextColor3", "muted")
        head.Activated:Connect(function()
            open = open ~= name and name or nil
            refresh()
        end)
        if open ~= name then return end

        local actions = create("Frame", { Name = "Actions", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = frame })
        Util.padding(actions, 12, 12, 0, 10)
        Util.list(actions, 6)
        local buttons = create("Frame", { Name = "Buttons", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = actions })
        local flow = Util.list(buttons, 6, Enum.FillDirection.Horizontal)
        pcall(function() flow.Wraps = true end)

        smallButton(buttons, "Load", 1, "Primary").Activated:Connect(function()
            if locked then
                local failed = store:Apply(defaults)
                say(failed > 0 and (failed .. " setting(s) could not be reset") or "Default settings restored", failed > 0)
            else
                local ok, err = store:Load(name)
                say(ok and (err or ("Loaded \"" .. name .. "\"")) or err, not ok)
            end
        end)
        if not locked then
            smallButton(buttons, "Overwrite", 2).Activated:Connect(function()
                window:Confirm("Overwrite \"" .. name .. "\"?", "It will hold your current settings.", function()
                    local ok, err = store:Save(name)
                    if ok then local m = store:ReadMeta() m[name] = { saved = os.time() } store:WriteMeta(m) end
                    say(ok and ("Saved \"" .. name .. "\"") or err, not ok)
                    refresh()
                end, "Overwrite")
            end)
        end
        smallButton(buttons, autoload and "Autoload off" or "Autoload", 3).Activated:Connect(function()
            if autoload then store:ClearAutoLoad() say("Autoload off")
            elseif locked then store:ClearAutoLoad() say("Default needs no autoload - autoload off")
            else store:SetAutoLoad(name) say("\"" .. name .. "\" loads on start") end
            refresh()
        end)
        if not locked then
            smallButton(buttons, "Delete", 6, "Danger").Activated:Connect(function()
                window:Confirm("Delete \"" .. name .. "\"?", "This cannot be undone.", function()
                    local ok, err = store:Delete(name)
                    if ok then
                        local m = store:ReadMeta() m[name] = nil store:WriteMeta(m)
                        if store:GetAutoLoad() == name then store:ClearAutoLoad() end
                        open = nil
                    end
                    say(ok and ("Deleted \"" .. name .. "\"") or err, not ok)
                    refresh()
                end, "Delete", true)
            end)
        end

        -- name box: Rename / Duplicate use it
        local nameRow = create("Frame", { Name = "NameRow", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 1, Parent = actions })
        local box = create("TextBox", {
            Name = "NewName", Text = "", PlaceholderText = locked and "name for the copy" or "new name", TextSize = 10, Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, BorderSizePixel = 0, Size = UDim2.new(1, locked and -86 or -172, 1, 0), Parent = nameRow,
        })
        Theme.bind(box, "BackgroundColor3", "base")
        Theme.bind(box, "TextColor3", "text")
        Theme.bind(box, "PlaceholderColor3", "muted")
        corner(box, 6)
        Util.padding(box, 8, 8, 0, 0)
        local side = create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, locked and 80 or 166, 1, 0), Parent = nameRow })
        Util.list(side, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right)
        local function typed()
            local text = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
            if text == "" then say("Type a name in the box", true) return nil end
            if text:lower() == "default" then say("\"Default\" is reserved", true) return nil end
            return text
        end
        if not locked then
            smallButton(side, "Rename", 1).Activated:Connect(function()
                local new = typed()
                if not new then return end
                local ok, err = store:Rename(name, new)
                if ok then local m = store:ReadMeta() m[new], m[name] = m[name], nil store:WriteMeta(m) open = new end
                say(ok and ("Renamed to \"" .. new .. "\"") or err, not ok)
                refresh()
            end)
        end
        smallButton(side, "Duplicate", 2).Activated:Connect(function()
            local new = typed()
            if not new then return end
            local ok, err
            if locked then
                if store:Exists(new) then ok, err = false, "A profile with that name exists"
                else
                    -- write the default values as a normal profile
                    local current = store:Snapshot()
                    store:Apply(defaults)
                    ok, err = store:Save(new)
                    store:Apply(current)
                end
            else
                ok, err = store:Copy(name, new)
            end
            if ok then local m = store:ReadMeta() m[new] = { saved = os.time() } store:WriteMeta(m) open = new end
            say(ok and ("Copied to \"" .. new .. "\"") or (err or "Copy failed"), not ok)
            refresh()
        end)
    end

    function refresh()
        for _, child in ipairs(holder:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
        local auto = store:GetAutoLoad()
        local meta = store:ReadMeta()
        profileRow("Default", 1, true, auto == nil, nil)
        for index, name in ipairs(store:List()) do profileRow(name, index + 1, false, auto == name, meta[name]) end
    end
    refresh()

    ------------------------------------------------------------ info
    local about = infoPage:Card({ Title = "About", Side = "Left" })
    if window.Version ~= "" then about:Info({ Title = window.Title, Value = window.Version }) end
    about:Info({ Title = "qustah-ui-lib", Value = "v" .. tostring(window.Lib.Version) })
    for _, entry in ipairs(cfg.Info or {}) do about:Info({ Title = entry[1], Value = entry[2], Copy = entry.Copy }) end
    local files = type(writefile) == "function" and type(readfile) == "function"
    about:Info({ Title = "File access", Value = files and "Yes" or "No (profiles off)" })

    local modulesCard = infoPage:Card({ Title = "Modules", Side = "Left" })
    local moduleRows = {}
    local noModules = modulesCard:Label("No modules reported")

    local errorsCard = infoPage:Card({ Title = "Errors", Side = "Right" })
    local errorCount = errorsCard:Info({ Title = "Errors", Value = "0" })
    local errorText = errorsCard:Paragraph({ Content = "No errors" })
    errorsCard:Button({
        Title = "Copy report",
        Callback = function()
            local clipboard = setclipboard or toclipboard
            if type(clipboard) == "function" and pcall(clipboard, window:GetErrorReport()) then
                window:Notify({ Title = "Copied", Content = "Error report copied to clipboard" })
            else
                window:Notify({ Title = "Clipboard", Content = "setclipboard is not available", Color = RED })
            end
        end,
    })
    errorsCard:Button({ Title = "Clear", Callback = function() window:ClearErrors() end })

    local STATE = { On = GREEN, Off = nil, Limited = Color3.fromRGB(215, 180, 120), Error = RED }
    local function update()
        local order, modules = window:GetModules()
        noModules:SetVisible(#order == 0)
        for _, name in ipairs(order) do
            local row = moduleRows[name] or modulesCard:Info({ Title = name })
            moduleRows[name] = row
            local module = modules[name]
            row:Set(module.state .. (module.detail and module.state ~= "Error" and (" · " .. tostring(module.detail)) or ""))
            row:SetColor(STATE[module.state] or "muted")
        end
        local errors = window:GetErrors()
        local total = 0
        local lines = {}
        for index, entry in ipairs(errors) do
            total = total + entry.count
            if index <= 8 then
                lines[#lines + 1] = string.format("<font color=\"#d78282\">%s</font>%s  %s", entry.source, entry.count > 1 and (" ×" .. entry.count) or "", (tostring(entry.message):gsub("<", "&lt;")))
            end
        end
        if #errors > 8 then lines[#lines + 1] = "+" .. (#errors - 8) .. " more (Copy report)" end
        errorCount:Set(#errors == 0 and "0" or (#errors .. (total > #errors and (" (" .. total .. "×)") or "")))
        errorCount:SetColor(#errors > 0 and RED or "text")
        errorText:Set(#lines > 0 and table.concat(lines, "\n") or "No errors")
    end
    window:OnStatusChanged(update)
    update()
    return tab
end
end

__modules["stats"] = function()
-- Shared FPS / ping sampler (one RenderStepped counter for the whole library, started on first use).
-- Stats.fps, Stats.ping (ms), Stats.history.fps / .ping (last 60 samples, one every 0.5 s).
local Util = require("util")

local Services = Util.Services

local Stats = { fps = 0, ping = 0, history = { fps = {}, ping = {} }, running = false }
local listeners = {}
local HISTORY = 60

function Stats.start(maid)
    if Stats.running then return end
    Stats.running = true
    local frames, last = 0, os.clock()
    maid:connect(Services.RunService.RenderStepped, function() frames = frames + 1 end)
    task.spawn(function()
        while Stats.running do
            task.wait(0.5)
            local now = os.clock()
            Stats.fps = math.floor(frames / math.max(now - last, 1e-3) + 0.5)
            frames, last = 0, now
            local ok, ping = pcall(function() return Services.Players.LocalPlayer:GetNetworkPing() * 1000 end)
            Stats.ping = ok and math.floor(ping + 0.5) or Stats.ping
            for key, value in pairs({ fps = Stats.fps, ping = Stats.ping }) do
                local list = Stats.history[key]
                list[#list + 1] = value
                if #list > HISTORY then table.remove(list, 1) end
            end
            for _, listener in ipairs(listeners) do Util.safe(listener, Stats) end
        end
    end)
    maid:give(function() Stats.running = false end)
end

-- Runs callback(Stats) after every sample; returns a function that removes it.
function Stats.listen(callback)
    listeners[#listeners + 1] = callback
    return function()
        local index = table.find(listeners, callback)
        if index then table.remove(listeners, index) end
    end
end

return Stats
end

__modules["status"] = function()
-- Health of the script, shown in the footer, the Dashboard "Modules" card and the Settings "Info" page.
--   Window:SetModule("ESP", "On" | "Off" | "Error" | "Limited", detail)
--   Window:ReportError(source, message)   (callback errors are reported here automatically)
--   Window:SetStatus(text, color)          manual footer text; SetStatus(nil) goes back to automatic
--   Window:GetErrors(), Window:GetErrorReport(), Window:ClearErrors(), Window:OnStatusChanged(fn)
local Util = require("util")

local GREEN, YELLOW, RED = Color3.fromRGB(82, 207, 132), Color3.fromRGB(215, 180, 120), Color3.fromRGB(215, 130, 130)

return function(Window)
    local function changed(self)
        self:_refreshStatus()
        for _, listener in ipairs(self._statusListeners or {}) do Util.safe(listener, self) end
    end

    function Window:OnStatusChanged(callback)
        self._statusListeners = self._statusListeners or {}
        table.insert(self._statusListeners, callback)
    end

    function Window:SetModule(name, state, detail)
        name = tostring(name)
        self.modules = self.modules or {}
        self.moduleOrder = self.moduleOrder or {}
        if not self.modules[name] then table.insert(self.moduleOrder, name) end
        self.modules[name] = { state = tostring(state or "Off"), detail = detail }
        if state == "Error" then self:ReportError(name, detail or "Module stopped with an error") return end
        changed(self)
    end
    function Window:GetModules() return self.moduleOrder or {}, self.modules or {} end

    function Window:ReportError(source, message)
        source, message = tostring(source or "Script"), tostring(message or "Unknown error")
        self.errors = self.errors or {}
        self._errorIndex = self._errorIndex or {}
        local key = source .. "\0" .. message
        local entry = self._errorIndex[key]
        if entry then
            entry.count = entry.count + 1
            entry.last = os.time()
        else
            entry = { source = source, message = message, count = 1, first = os.time(), last = os.time() }
            self._errorIndex[key] = entry
            table.insert(self.errors, entry)
            warn(string.format("[%s / %s] %s", self.Title, source, message))
        end
        changed(self)
    end
    function Window:GetErrors() return self.errors or {} end
    function Window:ClearErrors()
        self.errors, self._errorIndex = {}, {}
        for _, module in pairs(self.modules or {}) do if module.state == "Error" then module.state = "Off" end end
        changed(self)
    end
    function Window:GetErrorReport()
        local lines = { string.format("%s %s - error report (%s)", self.Title, self.Version, os.date("%Y-%m-%d %H:%M")) }
        for _, name in ipairs(self.moduleOrder or {}) do
            local module = self.modules[name]
            lines[#lines + 1] = string.format("module %s: %s%s", name, module.state, module.detail and (" (" .. tostring(module.detail) .. ")") or "")
        end
        for _, entry in ipairs(self.errors or {}) do
            lines[#lines + 1] = string.format("x%d %s: %s", entry.count, entry.source, entry.message)
        end
        if #(self.errors or {}) == 0 then lines[#lines + 1] = "no errors" end
        return table.concat(lines, "\n")
    end

    function Window:SetStatus(text, color)
        self._manualStatus = text ~= nil and { text = tostring(text), color = color } or nil
        self:_refreshStatus()
    end

    -- Footer: manual text > "Errors: N" > "Limited" > "Connected".
    function Window:_refreshStatus()
        if not self.statusLabel then return end
        local text, color
        local errorCount = #(self.errors or {})
        local limited = false
        for _, module in pairs(self.modules or {}) do if module.state == "Limited" then limited = true end end
        if self._manualStatus then
            text, color = self._manualStatus.text, self._manualStatus.color
        elseif errorCount > 0 then
            text, color = "Errors: " .. errorCount, RED
        elseif limited then
            text, color = "Limited", YELLOW
        else
            text, color = "Connected", GREEN
        end
        self.statusLabel.Text = text
        if typeof(color) == "Color3" then self.statusDot.BackgroundColor3 = color end
    end

    -- Runs a user callback; an error is reported (footer, Info page) instead of breaking the UI.
    function Window:_safe(source, callback, ...)
        if type(callback) ~= "function" then return end
        local ok, err = pcall(callback, ...)
        if not ok then self:ReportError(source, err) end
    end
end
end

__modules["theme"] = function()
-- Colour roles. Objects bind a property to a role; changing a role (e.g. the accent) recolours every bound object.
local Util = require("util")

local Theme = {}
local rgb = Color3.fromRGB

Theme.colors = {
    base       = rgb(15, 15, 16),    -- window background
    footer     = rgb(12, 12, 13),
    dock       = rgb(16, 16, 16),
    selected   = rgb(33, 33, 36),
    icon       = rgb(192, 192, 192),
    card       = rgb(19, 19, 20),
    input      = rgb(25, 25, 27),    -- buttons, boxes
    hover      = rgb(33, 33, 36),
    line       = rgb(36, 36, 39),    -- card outlines, dividers
    edge       = rgb(30, 30, 30),    -- window outline
    buttonEdge = rgb(46, 46, 50),    -- button outline, switch off
    text       = rgb(168, 168, 172),
    muted      = rgb(118, 118, 124),
    heading    = rgb(205, 205, 210),
    knob       = rgb(190, 190, 195),
    accent     = rgb(177, 178, 183), -- Qustah neutral; Lib:SetAccent changes it
}

-- Roles computed from the accent.
local function derive()
    local colors = Theme.colors
    colors.accentDeep = colors.base:Lerp(colors.accent, 0.12) -- selected dock button / indicator fill
    colors.toggleOn = colors.input:Lerp(colors.accent, 0.42)
    colors.accentEdge = colors.base:Lerp(colors.accent, 0.35)
    local a = colors.accent
    local luminance = 0.299 * a.R + 0.587 * a.G + 0.114 * a.B
    colors.onAccent = luminance > 0.6 and colors.base or Color3.new(1, 1, 1) -- knob / text on an accent fill
end
derive()

local bound = setmetatable({}, { __mode = "k" })
local listeners = {}

function Theme.get(role)
    return Theme.colors[role] or role
end

-- bind(object, "BackgroundColor3", "card")
function Theme.bind(object, property, role)
    local entry = bound[object]
    if not entry then entry = {} bound[object] = entry end
    entry[property] = role
    object[property] = Theme.get(role)
    return object
end

-- Rebinds and animates to the role's colour (state changes such as a toggle turning on).
function Theme.tweenTo(object, property, role, duration)
    local entry = bound[object]
    if not entry then entry = {} bound[object] = entry end
    entry[property] = role
    if duration and duration > 0 then
        Util.tween(object, duration, { [property] = Theme.get(role) })
    else
        object[property] = Theme.get(role)
    end
end

function Theme.set(role, color)
    if typeof(color) ~= "Color3" then return end
    Theme.colors[role] = color
    if role == "accent" or role == "base" or role == "input" then derive() end
    for object, properties in pairs(bound) do
        if object.Parent then
            for property, boundRole in pairs(properties) do
                pcall(function() object[property] = Theme.get(boundRole) end)
            end
        end
    end
    for _, listener in ipairs(listeners) do Util.safe(listener, role, color) end
end

function Theme.onChange(callback)
    listeners[#listeners + 1] = callback
end

return Theme
end

__modules["util"] = function()
-- Shared helpers: services, instance creation, tweens, cleanup (maid), text / colour / key helpers.
local Util = {}

local cloneref = cloneref or clonereference or function(object) return object end
Util.Services = setmetatable({}, {
    __index = function(cache, name)
        local service = cloneref(game:GetService(name))
        rawset(cache, name, service)
        return service
    end,
})
local Services = Util.Services

-- create("Frame", { Size = ..., Parent = ... }, { children }) - Parent is applied last.
function Util.create(class, props, children)
    local object = Instance.new(class)
    local parent
    for key, value in pairs(props or {}) do
        if key == "Parent" then parent = value else object[key] = value end
    end
    for _, child in ipairs(children or {}) do child.Parent = object end
    if parent then object.Parent = parent end
    return object
end
local create = Util.create

function Util.corner(object, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = object })
end
function Util.stroke(object, color, transparency, thickness)
    return create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = color or Color3.new(1, 1, 1),
        Transparency = transparency or 0, Thickness = thickness or 1, Parent = object,
    })
end
function Util.padding(object, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0), PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or 0), PaddingBottom = UDim.new(0, bottom or top or 0), Parent = object,
    })
end
function Util.list(object, padding, direction, horizontal, vertical)
    return create("UIListLayout", {
        Padding = UDim.new(0, padding or 0), FillDirection = direction or Enum.FillDirection.Vertical,
        HorizontalAlignment = horizontal or Enum.HorizontalAlignment.Left,
        VerticalAlignment = vertical or Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder, Parent = object,
    })
end
function Util.label(parent, text, size, props)
    local object = create("TextLabel", {
        BackgroundTransparency = 1, Text = text or "", TextSize = size or 11, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd, BorderSizePixel = 0, Parent = parent,
    })
    for key, value in pairs(props or {}) do object[key] = value end
    return object
end

function Util.tween(object, duration, props, style, direction)
    local tween = Services.TweenService:Create(object,
        TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end

-- Runs a user callback; an error is reported but never breaks the UI.
function Util.safe(callback, ...)
    if type(callback) ~= "function" then return end
    local ok, err = pcall(callback, ...)
    if not ok then warn("[qustah-ui-lib] callback error: " .. tostring(err)) end
end

-- A maid owns connections, instances and cleanup functions; clean() releases all of them (newest first).
function Util.maid()
    local maid = { items = {} }
    function maid:give(item) self.items[#self.items + 1] = item return item end
    function maid:connect(signal, callback) return self:give(signal:Connect(callback)) end
    function maid:clean()
        for index = #self.items, 1, -1 do
            local item = self.items[index]
            self.items[index] = nil
            if typeof(item) == "Instance" then
                pcall(item.Destroy, item)
            elseif type(item) == "function" then
                pcall(item)
            elseif item and (typeof(item) == "RBXScriptConnection" or type(item) == "table") and item.Disconnect then
                pcall(item.Disconnect, item)
            end
        end
    end
    return maid
end

function Util.textWidth(text, size, font)
    return Services.TextService:GetTextSize(tostring(text), size, font or Enum.Font.Gotham, Vector2.new(10000, 100)).X
end

function Util.round(value, step)
    step = step or 1
    if step <= 0 then return value end
    return math.floor(value / step + 0.5) * step
end
function Util.decimals(step)
    local text = tostring(step)
    local dot = text:find("%.")
    return dot and #text - dot or 0
end

function Util.toHex(color)
    return string.format("%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end
function Util.fromHex(text)
    text = tostring(text or ""):gsub("#", ""):gsub("%s", "")
    if not text:match("^%x%x%x%x%x%x$") then return nil end
    return Color3.fromRGB(tonumber(text:sub(1, 2), 16), tonumber(text:sub(3, 4), 16), tonumber(text:sub(5, 6), 16))
end

local SHORT_KEYS = {
    LeftShift = "LSHIFT", RightShift = "RSHIFT", LeftControl = "LCTRL", RightControl = "RCTRL",
    LeftAlt = "LALT", RightAlt = "RALT", MouseButton1 = "M1", MouseButton2 = "M2", MouseButton3 = "M3", Return = "ENTER",
    KeypadZero = "NUM 0", KeypadOne = "NUM 1", KeypadTwo = "NUM 2", KeypadThree = "NUM 3", KeypadFour = "NUM 4",
    KeypadFive = "NUM 5", KeypadSix = "NUM 6", KeypadSeven = "NUM 7", KeypadEight = "NUM 8", KeypadNine = "NUM 9",
}
-- KeyCode / UserInputType / name -> short label ("RSHIFT", "NUM 8", "F").
function Util.keyName(key)
    if key == nil then return "None" end
    local name = typeof(key) == "EnumItem" and key.Name or tostring(key)
    if name == "None" or name == "" or name == "Unknown" then return "None" end
    return SHORT_KEYS[name] or name:upper()
end
-- Saved key names back to an Enum (KeyCode first, then mouse buttons).
function Util.toKey(name)
    if typeof(name) == "EnumItem" then return name end
    if type(name) ~= "string" or name == "" or name == "None" then return nil end
    if name:match("^MouseButton%d$") then
        local found, button = pcall(function() return Enum.UserInputType[name] end)
        if found and button then return button end
    end
    local ok, key = pcall(function() return Enum.KeyCode[name] end)
    if ok and key then return key end
    ok, key = pcall(function() return Enum.UserInputType[name] end)
    if ok and key then return key end
    return nil
end
-- The key an input means for binds: the KeyCode for keyboards, the UserInputType for mouse buttons 2/3
-- (and mouse button 1 when allowPrimary is set - only chords like CTRL + M1 use it).
function Util.inputKey(input, allowPrimary)
    if input.UserInputType == Enum.UserInputType.Keyboard then return input.KeyCode end
    if input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
        return input.UserInputType
    end
    if allowPrimary and input.UserInputType == Enum.UserInputType.MouseButton1 then return input.UserInputType end
    return nil
end
local MODIFIERS = {
    LeftShift = true, RightShift = true, LeftControl = true, RightControl = true, LeftAlt = true, RightAlt = true,
}
function Util.isModifier(key) return typeof(key) == "EnumItem" and MODIFIERS[key.Name] == true end
-- Is this key (KeyCode or mouse UserInputType) held down right now?
function Util.isDown(key)
    if typeof(key) ~= "EnumItem" then return false end
    local UserInputService = Services.UserInputService
    local ok, down = pcall(function()
        if tostring(key):match("^Enum%.KeyCode%.") then return UserInputService:IsKeyDown(key) end
        return UserInputService:IsMouseButtonPressed(key)
    end)
    return ok and down == true
end

-- Screen position of a pointer input (same space as AbsolutePosition in an IgnoreGuiInset ScreenGui).
function Util.pointer(input)
    if input and input.UserInputType == Enum.UserInputType.Touch then
        local inset = Services.GuiService:GetGuiInset()
        return Vector2.new(input.Position.X + inset.X, input.Position.Y + inset.Y)
    end
    return Services.UserInputService:GetMouseLocation()
end
function Util.isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

-- HH:MM:SS
function Util.clock(seconds)
    seconds = math.max(0, math.floor(seconds))
    return string.format("%02d:%02d:%02d", seconds // 3600, (seconds // 60) % 60, seconds % 60)
end

function Util.viewport()
    local camera = workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

-- gethui() > CoreGui (if writable) > PlayerGui.
function Util.guiParent()
    local ok, hidden = pcall(function() return gethui and gethui() end)
    if ok and hidden then return hidden end
    local probe = Instance.new("Folder")
    local coreOk = pcall(function() probe.Parent = Services.CoreGui end)
    probe:Destroy()
    if coreOk then return Services.CoreGui end
    return Services.Players.LocalPlayer:WaitForChild("PlayerGui")
end
function Util.screenGui(name, order)
    local gui = create("ScreenGui", {
        Name = name, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = order or 50,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) elseif protectgui then protectgui(gui) end end)
    gui.Parent = Util.guiParent()
    return gui
end

return Util
end

__modules["window"] = function()
-- Window shell (Qustah layout): header (title, version badge, "Tab › Page" location, minimize / close), sub-page
-- strip, scrolling pages with two card columns, key hint bar, footer (status, centre text, resize grip) and the
-- dock to the right (drag handle, tab icons, group dividers).
local Util = require("util")
local Theme = require("theme")
local Card = require("card")
local Config = require("config")
local Glow = require("glow")

local Services = Util.Services
local create, corner, stroke, label, tween = Util.create, Util.corner, Util.stroke, Util.label, Util.tween

local HEADER, FOOTER = 44, 26
local DOCK_WIDTH, DOCK_GAP, DOCK_BUTTON, DOCK_STEP, DOCK_TOP = 40, 12, 30, 37, 42
local HINTS = 34 -- height taken by the key hint bar
local NARROW = 470 -- below this width the two card columns stack

local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Page = {}
Page.__index = Page

-------------------------------------------------------------------------------- Page
function Page.new(tab, name, cfg)
    local window = tab.window
    local self = setmetatable({ tab = tab, window = window, Name = name, cfg = cfg or {}, cards = 0, order = 0 }, Page)
    local frame = create("ScrollingFrame", {
        Name = name, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 2, ScrollBarImageTransparency = 0.4, ElasticBehavior = Enum.ElasticBehavior.Never,
        VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar, Visible = false, Parent = window.pages,
    })
    Theme.bind(frame, "ScrollBarImageColor3", "muted")
    -- Margins come from the content frame's position / size, not from a UIPadding on the ScrollingFrame:
    -- Roblox sizes scale children of a padded ScrollingFrame from the unpadded width, which pushed the right
    -- column past the window edge.
    local content = create("Frame", {
        Name = "Content", BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 2), Size = UDim2.new(1, -30, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, Parent = frame,
    })
    Util.list(content, 10)
    Util.padding(content, 0, 0, 0, 14)
    -- full-width cards (Card({ Wide = true })) above the two columns
    local wide = create("Frame", { Name = "Wide", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = content })
    Util.list(wide, 10)
    local holder = create("Frame", {
        Name = "Columns", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2, Parent = content,
    })
    self.layout = Util.list(holder, 10, Enum.FillDirection.Horizontal)
    local function column(name, order)
        local object = create("Frame", {
            Name = name, BackgroundTransparency = 1, Size = UDim2.new(0.5, -5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = order, Parent = holder,
        })
        Util.list(object, 10)
        return object
    end
    self.frame, self.wide, self.left, self.right = frame, wide, column("Left", 1), column("Right", 2)

    -- soft fades at the top / bottom edge while there is more to scroll that way
    local function fade(top)
        local object = create("Frame", {
            Name = top and "FadeTop" or "FadeBottom", AnchorPoint = Vector2.new(0, top and 0 or 1),
            Position = UDim2.new(0, 0, top and 0 or 1, 0), Size = UDim2.new(1, -4, 0, 18), BorderSizePixel = 0,
            Visible = false, ZIndex = 20, Active = false, Parent = window.pages,
        })
        Theme.bind(object, "BackgroundColor3", "base")
        create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(top and 0 or 1, top and 1 or 0), Parent = object })
        return object
    end
    local fadeTop, fadeBottom = fade(true), fade(false)
    local function refreshFades()
        local shown = frame.Visible
        local scrolled = frame.CanvasPosition.Y
        local hidden = frame.AbsoluteCanvasSize.Y - frame.AbsoluteWindowSize.Y - scrolled
        fadeTop.Visible = shown and scrolled > 2
        fadeBottom.Visible = shown and hidden > 2
    end
    for _, property in ipairs({ "CanvasPosition", "AbsoluteCanvasSize", "AbsoluteWindowSize", "Visible" }) do
        frame:GetPropertyChangedSignal(property):Connect(refreshFades)
    end

    -- strip button (shown when the tab has more than one page)
    local button = create("TextButton", {
        Name = name, BackgroundTransparency = 1, Text = name, TextSize = 10, Font = Enum.Font.GothamMedium,
        AutoButtonColor = false, Parent = tab.strip,
    })
    Theme.bind(button, "TextColor3", "text")
    local underline = create("Frame", {
        Name = "Underline", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.fromOffset(math.max(12, Util.textWidth(name, 10, Enum.Font.GothamMedium)), 1),
        BorderSizePixel = 0, Visible = false, Parent = button,
    })
    Theme.bind(underline, "BackgroundColor3", "accent")
    self.button, self.underline = button, underline
    button.MouseEnter:Connect(function() if tab.current ~= self then Theme.tweenTo(button, "TextColor3", "heading", 0.12) end end)
    button.MouseLeave:Connect(function() if tab.current ~= self then Theme.tweenTo(button, "TextColor3", "text", 0.12) end end)
    button.Activated:Connect(function() self:Select() end)
    self:_columns(window.width)
    return self
end

-- Two columns side by side, or stacked when the window is narrow / the page asked for one column.
function Page:_columns(width)
    local single = self.cfg.Columns == 1 or width < NARROW
    self.layout.FillDirection = single and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
    local size = single and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -5, 0, 0)
    self.left.Size, self.right.Size = size, size
end

-- Page:Card({ Title = "General", Side = "Left" | "Right", Wide = true }) - without Side the cards alternate
-- left / right; Wide cards span both columns and sit above them.
function Page:Card(cfg)
    cfg = cfg or {}
    self.cards = self.cards + 1
    local side = cfg.Side
    if self.cfg.Columns == 1 then side = "Left" end
    if side ~= "Left" and side ~= "Right" then side = (self.cards % 2 == 1) and "Left" or "Right" end
    self.order = self.order + 1
    if cfg.Wide then
        self.cards = self.cards - 1 -- a wide card does not take a turn in the left / right alternation
        return Card.new(self, self.wide, cfg, self.order)
    end
    return Card.new(self, side == "Right" and self.right or self.left, cfg, self.order)
end

function Page:Select()
    local tab = self.tab
    tab.current = self
    for _, page in ipairs(tab.Pages) do
        local selected = page == self
        page.frame.Visible = selected and tab.window.current == tab
        page.underline.Visible = selected
        Theme.tweenTo(page.button, "TextColor3", selected and "accent" or "text", 0.12)
    end
    tab.window:_updateLocation()
end

-------------------------------------------------------------------------------- Tab
function Tab.new(window, cfg)
    local index = #window.Tabs + 1
    local self = setmetatable({ window = window, Title = cfg.Title or ("Tab " .. index), Pages = {}, index = index }, Tab)
    self.strip = create("Frame", { Name = self.Title, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = window.stripHolder })

    self.Header = cfg.Header == true -- also shown as a text tab in the header (Overview / Settings)
    self.Divider = cfg.Divider == true or window._dividerNext == true -- a short line above this tab in the dock
    window._dividerNext = nil
    local button = create("TextButton", {
        Name = self.Title .. "Tab", BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0,
        Position = UDim2.fromOffset(5, DOCK_TOP), Size = UDim2.fromOffset(DOCK_BUTTON, DOCK_BUTTON), ZIndex = 42, Parent = window.dock,
    })
    Theme.bind(button, "BackgroundColor3", "accentDeep")
    corner(button, 15)
    local icon
    local image = cfg.Icon
    if type(image) == "number" or (type(image) == "string" and image:match("^%d+$")) then image = "rbxassetid://" .. tostring(image) end
    if type(image) == "string" and image ~= "" then
        icon = create("ImageLabel", {
            Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 18),
            BackgroundTransparency = 1, Image = image, ScaleType = Enum.ScaleType.Fit, ZIndex = 43, Parent = button,
        })
        self.iconProperty = "ImageColor3"
    else
        icon = label(button, self.Title:sub(1, 1):upper(), 13, {
            Name = "Icon", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, ZIndex = 43,
        })
        self.iconProperty = "TextColor3"
    end
    self.button, self.icon, self.hovered = button, icon, false
    self:_render(false)
    button.MouseEnter:Connect(function()
        self.hovered = true
        self:_render(true)
        window:_dockTip(self.Title, self.y or DOCK_TOP)
    end)
    button.MouseLeave:Connect(function()
        self.hovered = false
        self:_render(true)
        window:_hideTip()
    end)
    button.Activated:Connect(function() window:_hideTip() self:Select() end)
    return self
end

-- Dock button look: selected = filled + accent icon, hover = half fill + bright icon.
function Tab:_render(animate)
    local selected = self.window.current == self
    local duration = animate and 0.14 or nil
    local transparency = selected and 0 or (self.hovered and 0.6 or 1)
    if duration then tween(self.button, duration, { BackgroundTransparency = transparency }) else self.button.BackgroundTransparency = transparency end
    Theme.tweenTo(self.icon, self.iconProperty, selected and "accent" or (self.hovered and "heading" or "icon"), duration)
end

-- Tab:Page("Overview") adds a sub-page; with two or more pages the strip of page names appears.
function Tab:Page(name, cfg)
    local page = Page.new(self, tostring(name or ("Page " .. (#self.Pages + 1))), cfg)
    self.Pages[#self.Pages + 1] = page
    local count = #self.Pages
    for index, item in ipairs(self.Pages) do
        item.button.Position = UDim2.new((index - 1) / count, 0, 0, 0)
        item.button.Size = UDim2.new(1 / count, 0, 1, 0)
    end
    if not self.current then self.current = page end
    if self.window.current == self then self:Select() end
    return page
end

-- Cards straight on a tab go to its first page.
function Tab:Card(cfg)
    if #self.Pages == 0 then self:Page(self.Title) end
    return self.Pages[1]:Card(cfg)
end

function Tab:Select()
    local window = self.window
    window.current = self
    for _, tab in ipairs(window.Tabs) do
        tab.strip.Visible = tab == self and #tab.Pages > 1
        for _, page in ipairs(tab.Pages) do page.frame.Visible = false end
        tab:_render(true)
    end
    window:_layoutBody()
    local page = self.current or self.Pages[1]
    if page then page:Select() else window:_updateLocation() end
end

-------------------------------------------------------------------------------- Window
function Window.new(Lib, cfg)
    cfg = cfg or {}
    local size = cfg.Size or Vector2.new(540, 390)
    local self = setmetatable({
        Lib = Lib, cfg = cfg, Title = tostring(cfg.Title or "Qustah UI"), Version = tostring(cfg.Version or ""),
        Tabs = {}, flags = {}, binds = {}, maid = Util.maid(),
        width = size.X, height = size.Y,
        minSize = cfg.MinSize or Vector2.new(400, 300), maxSize = cfg.MaxSize or Vector2.new(920, 660),
        key = cfg.ToggleKey or Enum.KeyCode.RightShift, visible = true, folded = false, alive = true,
    }, Window)

    -- Running the same script again replaces its old window instead of stacking a second one.
    local env = (getgenv and getgenv()) or _G
    env.__QustahUIWindows = env.__QustahUIWindows or {}
    local previous = env.__QustahUIWindows[self.Title]
    if previous and previous.Destroy then pcall(previous.Destroy, previous) end
    env.__QustahUIWindows[self.Title] = self

    if typeof(cfg.Accent) == "Color3" then Theme.set("accent", cfg.Accent) end
    self.Config = Config.new(self, cfg.Folder or self.Title:gsub("[^%w_%- ]", ""))
    -- window memory: last position / size (SaveWindow = false turns it off)
    self.memory = cfg.SaveWindow ~= false and self.Config:ReadMemory() or {}
    local saved = self.memory.window
    if type(saved) == "table" and tonumber(saved.w) and tonumber(saved.h) then
        self.width = math.clamp(tonumber(saved.w), self.minSize.X, self.maxSize.X)
        self.height = math.clamp(tonumber(saved.h), self.minSize.Y, self.maxSize.Y)
    end
    Glow.start(Lib.maid)
    self:_build()
    self:_refreshStatus()
    Lib.Windows[#Lib.Windows + 1] = self
    return self
end

function Window:_build()
    local maid = self.maid
    local gui = Util.screenGui("QustahUI_" .. self.Title:gsub("%W", ""), 50)
    maid:give(gui)
    self.gui = gui

    local main = create("CanvasGroup", {
        Name = "Window", Size = UDim2.fromOffset(self.width, self.height), BorderSizePixel = 0,
        GroupTransparency = 0, ClipsDescendants = true, Parent = gui,
    })
    Theme.bind(main, "BackgroundColor3", "base")
    corner(main, 12)
    Theme.bind(stroke(main), "Color", "edge")
    self.main = main
    self.scale = create("UIScale", { Scale = 1, Parent = main })

    ---------------------------------------------------------------- header
    local header = create("Frame", { Name = "Header", BackgroundTransparency = 1, Size = UDim2.new(1, -90, 0, HEADER), Active = true, Parent = main })
    local titleRow = create("Frame", { Name = "TitleRow", BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -16, 1, 0), Parent = header })
    Util.list(titleRow, 6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    local title = label(titleRow, self.Title, 16, {
        Name = "Title", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 24),
        TextTruncate = Enum.TextTruncate.None, LayoutOrder = 1,
    })
    pcall(function() title.FontFace = Font.new(Font.fromEnum(Enum.Font.Gotham).Family, Enum.FontWeight.SemiBold) end)
    Theme.bind(title, "TextColor3", "accent")
    Glow.add(title, { Base = "accent", Period = 3.6, GlowTransparency = 0.8 })
    if self.Version ~= "" then
        local badge = create("Frame", { Name = "Version", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 16), LayoutOrder = 2, Parent = titleRow })
        Theme.bind(badge, "BackgroundColor3", "card")
        corner(badge, 6)
        Theme.bind(stroke(badge, nil, 0.5), "Color", "accent")
        Util.padding(badge, 6, 6, 0, 0)
        local text = label(badge, self.Version, 9, {
            AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.None,
        })
        Theme.bind(text, "TextColor3", "accent")
    end
    self.titleLabel = title

    local function windowButton(name, offset, cross)
        local button = create("TextButton", {
            Name = name, Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
            Position = UDim2.new(1, offset, 0, 8), Size = UDim2.fromOffset(30, 28), Parent = main,
        })
        corner(button, 6)
        Theme.bind(button, "BackgroundColor3", "input")
        local bars = {}
        for _, rotation in ipairs(cross and { 45, -45 } or { 0 }) do
            local bar = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 2),
                Rotation = rotation, BorderSizePixel = 0, Parent = button,
            })
            corner(bar, 1)
            Theme.bind(bar, "BackgroundColor3", "muted")
            bars[#bars + 1] = bar
        end
        button.MouseEnter:Connect(function()
            tween(button, 0.12, { BackgroundTransparency = 0, BackgroundColor3 = cross and Color3.fromRGB(60, 24, 26) or Theme.get("input") })
            for _, bar in ipairs(bars) do Theme.tweenTo(bar, "BackgroundColor3", cross and Color3.fromRGB(235, 90, 90) or "heading", 0.12) end
        end)
        button.MouseLeave:Connect(function()
            tween(button, 0.12, { BackgroundTransparency = 1 })
            for _, bar in ipairs(bars) do Theme.tweenTo(bar, "BackgroundColor3", "muted", 0.12) end
        end)
        return button
    end
    local minimize = windowButton("Minimize", -74, false)
    local close = windowButton("Close", -40, true)
    -- fading accent line under the header
    local headerLine = create("Frame", { Name = "HeaderLine", Position = UDim2.fromOffset(18, HEADER), Size = UDim2.new(1, -36, 0, 1), BorderSizePixel = 0, Parent = main })
    Theme.bind(headerLine, "BackgroundColor3", "accent")
    create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 1),
        }), Parent = headerLine,
    })
    -- "Visuals › Overview" on the right of the header
    local location = label(main, "", 10, {
        Name = "Location", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -90, 0, 12), Size = UDim2.new(0.45, 0, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    Theme.bind(location, "TextColor3", "muted")
    self.locationLabel = location
    -- text tabs in the header for tabs created with Header = true (shown while one of them is open)
    self.headerTabs = create("Frame", {
        Name = "HeaderTabs", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -90, 0, 0),
        Size = UDim2.new(0, 0, 0, HEADER), AutomaticSize = Enum.AutomaticSize.X, Visible = false, Parent = main,
    })
    Util.list(self.headerTabs, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right)

    ---------------------------------------------------------------- body
    local body = create("Frame", {
        Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, HEADER + 1),
        Size = UDim2.new(1, 0, 1, -(HEADER + 1 + FOOTER)), ClipsDescendants = true, Parent = main,
    })
    self.body = body
    self.stripHolder = create("Frame", { Name = "Strip", BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 6), Size = UDim2.new(1, -32, 0, 26), Parent = body })
    self.pages = create("Frame", { Name = "Pages", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 1, -6), Parent = body })
    -- key hints: [NUM 8] • ESP / SILENT AIM ............ MENU • [RSHIFT]
    self.hintBar = create("Frame", { Name = "KeyHints", BackgroundTransparency = 1, Position = UDim2.new(0, 20, 1, -30), Size = UDim2.new(1, -40, 0, 26), Visible = false, Parent = body })
    self.hintLeft = create("Frame", { Name = "Left", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = self.hintBar })
    Util.list(self.hintLeft, 8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    self.hintRight = create("Frame", { Name = "Right", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = self.hintBar })
    Util.list(self.hintRight, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
    self.hints = {}

    ---------------------------------------------------------------- footer
    local footer = create("Frame", { Name = "Footer", Position = UDim2.new(0, 0, 1, -FOOTER), Size = UDim2.new(1, 0, 0, FOOTER), BorderSizePixel = 0, Parent = main })
    Theme.bind(footer, "BackgroundColor3", "footer")
    local footerLine = create("Frame", { Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, BackgroundTransparency = 0.45, Parent = footer })
    Theme.bind(footerLine, "BackgroundColor3", "line")
    local dot = create("Frame", { Name = "StatusDot", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 22, 0.5, 0), Size = UDim2.fromOffset(5, 5), BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(82, 207, 132), Parent = footer })
    corner(dot, 3)
    local status = label(footer, "Connected", 9, { Name = "Status", Position = UDim2.fromOffset(32, 0), Size = UDim2.new(0, 150, 1, 0) })
    Theme.bind(status, "TextColor3", "muted")
    Glow.add(status, { Base = "muted", Shine = "heading", GlowTransparency = 0.92 })
    local centre = label(footer, tostring(self.cfg.Footer or ""), 9, {
        Name = "Centre", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(1, -240, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    Theme.bind(centre, "TextColor3", "muted")
    self.footer, self.statusDot, self.statusLabel, self.footerText = footer, dot, status, centre
    if self.cfg.Footer == nil then
        task.spawn(function()
            local ok, info = pcall(function() return Services.MarketplaceService:GetProductInfo(game.PlaceId) end)
            if ok and type(info) == "table" and info.Name and centre.Parent and centre.Text == "" then centre.Text = tostring(info.Name) end
        end)
    end
    local grip = create("TextButton", {
        Name = "ResizeGrip", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -4, 1, -4), Size = UDim2.fromOffset(18, 18), ZIndex = 10, Parent = main,
    })
    for _, line in ipairs({ { 10, 10, 9 }, { 13, 13, 4 } }) do
        local mark = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(line[1], line[2]), Size = UDim2.fromOffset(line[3], 1),
            Rotation = -45, BorderSizePixel = 0, ZIndex = 11, Parent = grip,
        })
        Theme.bind(mark, "BackgroundColor3", "muted")
    end
    self.grip = grip

    ---------------------------------------------------------------- dock
    local dock = create("CanvasGroup", { Name = "Dock", Size = UDim2.fromOffset(DOCK_WIDTH, DOCK_TOP), BorderSizePixel = 0, BackgroundTransparency = 0.03, ZIndex = 40, ClipsDescendants = true, Parent = gui })
    Theme.bind(dock, "BackgroundColor3", "dock")
    corner(dock, 20)
    Theme.bind(stroke(dock), "Color", "line")
    self.dock = dock
    self.dockScale = create("UIScale", { Scale = 1, Parent = dock })
    -- drag handle (three lines) at the top of the dock moves the window like the header
    local dockGrip = create("TextButton", { Name = "DragHandle", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromOffset(5, 6), Size = UDim2.fromOffset(30, 28), ZIndex = 42, Parent = dock })
    for _, lineY in ipairs({ 9, 13, 17 }) do
        local bar = create("Frame", { Position = UDim2.fromOffset(9, lineY), Size = UDim2.fromOffset(12, 1), BorderSizePixel = 0, ZIndex = 43, Parent = dockGrip })
        Theme.bind(bar, "BackgroundColor3", "muted")
    end
    self.dockGrip, self.dockDividers = dockGrip, {}

    ---------------------------------------------------------------- tooltip
    local tip = create("Frame", { Name = "Tooltip", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 22), BorderSizePixel = 0, Visible = false, ZIndex = 300, Parent = gui })
    Theme.bind(tip, "BackgroundColor3", "card")
    corner(tip, 6)
    Theme.bind(stroke(tip), "Color", "line")
    Util.padding(tip, 8, 8, 0, 0)
    local tipText = label(tip, "", 10, { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), ZIndex = 301, TextTruncate = Enum.TextTruncate.None })
    Theme.bind(tipText, "TextColor3", "heading")
    self.tip, self.tipText = tip, tipText

    ---------------------------------------------------------------- behaviour
    local function moveWindow(input)
        if not Util.isPress(input) then return end
        local start, origin = Util.pointer(input), self.topLeft
        self:_hideTip()
        self:_beginDrag(input, function(point)
            self.topLeft = origin + (point - start)
            self:_layout()
        end, function() self:_saveMemory() end)
    end
    maid:connect(header.InputBegan, moveWindow)
    maid:connect(dockGrip.InputBegan, moveWindow)
    maid:connect(dockGrip.MouseEnter, function() self:_dockTip("Drag", 6) end)
    maid:connect(dockGrip.MouseLeave, function() self:_hideTip() end)
    maid:connect(grip.InputBegan, function(input)
        if not Util.isPress(input) or self.folded then return end
        local start, width, height = Util.pointer(input), self.width, self.height
        self:_beginDrag(input, function(point)
            local s = self.scale.Scale
            self.width = math.clamp(math.floor(width + (point.X - start.X) / s), self.minSize.X, self.maxSize.X)
            self.height = math.clamp(math.floor(height + (point.Y - start.Y) / s), self.minSize.Y, self.maxSize.Y)
            self:_layout()
        end, function() self:_saveMemory() end)
    end)
    maid:connect(minimize.Activated, function() self:Minimize() end)
    -- X closes straight away (no extra popup) and says how to get the menu back.
    -- CloseAction = "Destroy" unloads the whole UI instead of hiding it.
    maid:connect(close.Activated, function()
        if self.cfg.CloseAction == "Destroy" then
            self:Notify({ Title = self.Title, Content = "Unloaded" })
            self:Destroy()
            return
        end
        self:SetVisible(false)
        self:Notify({ Title = self.Title .. " hidden", Content = "Press " .. Util.keyName(self.key) .. " to open it again" })
    end)

    local UserInputService = Services.UserInputService
    maid:connect(UserInputService.InputChanged, function(input)
        local drag = self._drag
        if not drag then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or (input.UserInputType == Enum.UserInputType.Touch and input == drag.input) then
            Util.safe(drag.move, Util.pointer(input))
        end
    end)
    maid:connect(UserInputService.InputEnded, function(input)
        local drag = self._drag
        if drag and (input.UserInputType == Enum.UserInputType.MouseButton1 or input == drag.input) then
            self._drag = nil
            Util.safe(drag.finish)
        end
    end)
    maid:connect(UserInputService.InputBegan, function(input, processed)
        -- 1. a keybind waiting for a key takes the next key
        if self._capture then
            local key = Util.inputKey(input, self._captureMouse)
            if key then
                local capture = self._capture
                self._capture = nil
                Util.safe(capture, key)
                return
            end
        end
        -- 2. clicks outside an open popup close it
        if self._popup and Util.isPress(input) then
            local point = Util.pointer(input)
            local function inside(object)
                if not object or not object.Parent then return false end
                local p, s = object.AbsolutePosition, object.AbsoluteSize
                return point.X >= p.X and point.X <= p.X + s.X and point.Y >= p.Y and point.Y <= p.Y + s.Y
            end
            if not inside(self._popup.frame) and not inside(self._popup.owner) then self:_closePopup() end
        end
        -- 3. Escape closes an open dialog
        if self._dialog and input.KeyCode == Enum.KeyCode.Escape then self._dialog:Close() return end
        if processed or UserInputService:GetFocusedTextBox() then return end
        local key = Util.inputKey(input, true)
        if not key then return end
        -- 4. menu key, then toggle / keybind binds (chords like CTRL + M1 fire when their modifier is held)
        if key == self.key then self:Toggle() return end
        for element, bound in pairs(self.binds) do
            if element.Row and element.Row.Parent then
                local chord = element.Chord
                if chord then
                    if chord[2] == key and (chord[1] == nil or Util.isDown(chord[1])) then self:_safe(element.Title or "Keybind", element._onBind, element) end
                elseif bound == key and key ~= Enum.UserInputType.MouseButton1 then
                    self:_safe(element.Title or "Keybind", element._onBind, element)
                end
            end
        end
    end)

    if self.cfg.KeyHints ~= false then
        self.menuHint = self:KeyHint({ Title = "MENU", Side = "Right", Key = self.key, Menu = true, Callback = function(key) self:SetToggleKey(key) end })
    end

    local function watchCamera()
        local camera = workspace.CurrentCamera
        if camera then
            maid:connect(camera:GetPropertyChangedSignal("ViewportSize"), function()
                self:_layout()
                for _, place in ipairs(self._placers or {}) do Util.safe(place) end
            end)
        end
        self:_layout()
    end
    maid:connect(workspace:GetPropertyChangedSignal("CurrentCamera"), watchCamera)
    watchCamera()
end

-- Positions everything from width / height / topLeft and fits the window on small screens.
function Window:_layout()
    if not self.alive then return end
    local viewport = Util.viewport()
    local total = self.width + DOCK_GAP + DOCK_WIDTH
    local s = math.clamp(math.min(1, (viewport.X - 24) / total, (viewport.Y - 24) / self.height), 0.4, 1)
    self.scale.Scale, self.dockScale.Scale = s, s
    local height = self.folded and HEADER or self.height
    self.main.Size = UDim2.fromOffset(self.width, height)
    if not self.topLeft then
        local saved = self.memory and self.memory.window
        if type(saved) == "table" and tonumber(saved.x) and tonumber(saved.y) then
            local room = Vector2.new(viewport.X - total * s, viewport.Y - self.height * s)
            self.topLeft = Vector2.new(tonumber(saved.x) * room.X, tonumber(saved.y) * room.Y)
        else
            self.topLeft = Vector2.new((viewport.X - total * s) / 2, (viewport.Y - self.height * s) / 2)
        end
    end
    local x = math.clamp(self.topLeft.X, 8, math.max(8, viewport.X - total * s - 8))
    local y = math.clamp(self.topLeft.Y, 8, math.max(8, viewport.Y - height * s - 8))
    self.topLeft = Vector2.new(x, y)
    self.main.Position = UDim2.fromOffset(x, y)
    self.dock.Size = UDim2.fromOffset(DOCK_WIDTH, self.dockHeight or DOCK_TOP)
    self.dock.Position = UDim2.fromOffset(x + (self.width + DOCK_GAP) * s, y)
    self.dock.Visible = self.main.Visible and not self.folded and #self.Tabs > 0
    self.grip.Visible = not self.folded
    for _, tab in ipairs(self.Tabs) do for _, page in ipairs(tab.Pages) do page:_columns(self.width) end end
    self:_updateLocation()
end

-- Saves position (as a 0-1 fraction of the free screen space) and size; written at most twice a second.
function Window:_saveMemory()
    if self.cfg.SaveWindow == false or not self.alive then return end
    local viewport = Util.viewport()
    local s = self.scale.Scale
    local room = Vector2.new(math.max(1, viewport.X - (self.width + DOCK_GAP + DOCK_WIDTH) * s), math.max(1, viewport.Y - self.height * s))
    self.memory.window = {
        x = math.clamp(self.topLeft.X / room.X, 0, 1), y = math.clamp(self.topLeft.Y / room.Y, 0, 1), w = self.width, h = self.height,
    }
    if self._memoryQueued then return end
    self._memoryQueued = true
    task.delay(0.5, function()
        self._memoryQueued = false
        if self.alive then self.Config:WriteMemory(self.memory) end
    end)
end

function Window:_beginDrag(input, move, finish)
    self._drag = { input = input, move = move, finish = finish }
end

function Window:_openPopup(frame, owner, onClose)
    if self._popup and self._popup.frame ~= frame then self:_closePopup() end
    self._popup = { frame = frame, owner = owner, close = onClose }
end
function Window:_closePopup()
    local popup = self._popup
    self._popup = nil
    if popup then Util.safe(popup.close) end
end

-- Dock slots: drag handle, then one button per tab (37 px apart) with a divider above tabs marked Divider.
function Window:_layoutDock()
    for _, divider in ipairs(self.dockDividers) do divider:Destroy() end
    self.dockDividers = {}
    local cursor = DOCK_TOP
    for _, tab in ipairs(self.Tabs) do
        if tab.Divider then
            local divider = create("Frame", { Name = "Divider", Position = UDim2.fromOffset(9, cursor + 1), Size = UDim2.fromOffset(22, 1), BorderSizePixel = 0, ZIndex = 42, Parent = self.dock })
            Theme.bind(divider, "BackgroundColor3", "line")
            self.dockDividers[#self.dockDividers + 1] = divider
            cursor = cursor + 8
        end
        tab.y = cursor
        tab.button.Position = UDim2.fromOffset(5, cursor)
        cursor = cursor + DOCK_STEP
    end
    self.dockHeight = cursor + 8
end

-- Page area: below the strip (if the open tab has pages) and above the key hint bar (if there are hints).
function Window:_layoutBody()
    local tab = self.current
    local top = (tab and #tab.Pages > 1) and 38 or 6
    local bottom = self.hintBar.Visible and HINTS or 0
    self.pages.Position = UDim2.fromOffset(0, top)
    self.pages.Size = UDim2.new(1, 0, 1, -(top + bottom))
end

-- Header right side: the header tabs while one of them is open, otherwise "Tab › Page".
function Window:_updateLocation()
    local tab = self.current
    local wide = self.width >= 440
    local onHeaderTab = tab ~= nil and tab.Header and self.cfg.HeaderTabs ~= false
    self.headerTabs.Visible = onHeaderTab and wide
    for _, item in ipairs(self._headerButtons or {}) do
        local selected = item.tab == tab
        Theme.tweenTo(item.button, "TextColor3", selected and "heading" or "muted", 0.12)
        item.line.Visible = selected
    end
    if not tab then self.locationLabel.Text = "" return end
    local page = tab.current
    self.locationLabel.Text = (page and #tab.Pages > 1) and (tab.Title .. " › " .. page.Name) or tab.Title
    self.locationLabel.Visible = wide and not self.headerTabs.Visible
    -- leave room for the header stats in the middle
    self.locationLabel.Size = UDim2.new(self.monitorMode == "Header" and 0.25 or 0.45, 0, 0, 20)
end

function Window:_addHeaderTab(tab)
    local width = math.max(56, Util.textWidth(tab.Title, 11, Enum.Font.GothamMedium) + 14)
    local button = create("TextButton", {
        Name = tab.Title, Text = tab.Title, TextSize = 11, Font = Enum.Font.GothamMedium, AutoButtonColor = false,
        BackgroundTransparency = 1, Size = UDim2.fromOffset(width, HEADER), LayoutOrder = #(self._headerButtons or {}) + 1,
        Parent = self.headerTabs,
    })
    Theme.bind(button, "TextColor3", "muted")
    local line = create("Frame", { Name = "SelectionLine", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(1, -14, 0, 2), BorderSizePixel = 0, Visible = false, Parent = button })
    Theme.bind(line, "BackgroundColor3", "accent")
    button.Activated:Connect(function() tab:Select() end)
    self._headerButtons = self._headerButtons or {}
    table.insert(self._headerButtons, { tab = tab, button = button, line = line })
end

function Window:_dockTip(text, y)
    local s = self.scale.Scale
    local dockX = self.dock.Position.X.Offset
    local top = self.dock.Position.Y.Offset + (y + 5) * s
    self.tipText.Text = text
    if dockX + (DOCK_WIDTH + 8) * s + 150 > Util.viewport().X then
        self.tip.AnchorPoint = Vector2.new(1, 0)
        self.tip.Position = UDim2.fromOffset(dockX - 8, top)
    else
        self.tip.AnchorPoint = Vector2.new(0, 0)
        self.tip.Position = UDim2.fromOffset(dockX + (DOCK_WIDTH + 8) * s, top)
    end
    self.tip.Visible = true
end
-- Tooltip next to the mouse (locked elements show why they are locked).
function Window:_tip(text)
    local mouse = Services.UserInputService:GetMouseLocation()
    local viewport = Util.viewport()
    self.tipText.Text = tostring(text)
    self.tip.AnchorPoint = Vector2.new(mouse.X > viewport.X - 220 and 1 or 0, 0)
    self.tip.Position = UDim2.fromOffset(mouse.X + (mouse.X > viewport.X - 220 and -12 or 14), math.min(mouse.Y + 14, viewport.Y - 30))
    self.tip.Visible = true
end
function Window:_hideTip() self.tip.Visible = false end

function Window:_register(flag, element)
    if self.flags[flag] then warn("[qustah-ui-lib] duplicate flag: " .. tostring(flag)) end
    self.flags[flag] = element
end
function Window:_bind(element, key)
    self.binds[element] = key
end

-------------------------------------------------------------------------------- public API
function Window:Tab(cfg)
    if type(cfg) == "string" then cfg = { Title = cfg } end
    local tab = Tab.new(self, cfg or {})
    self.Tabs[#self.Tabs + 1] = tab
    if tab.Header then self:_addHeaderTab(tab) end
    self:_layoutDock()
    self:_layout()
    if not self.current then tab:Select() end
    return tab
end

function Window:SetVisible(visible)
    self.visible = visible
    self:_closePopup()
    if not visible and self._dialog then self._dialog:Close() end
    self:_hideTip()
    self._token = (self._token or 0) + 1
    local token = self._token
    if visible then
        self.main.Visible = true
        tween(self.main, 0.14, { GroupTransparency = 0 })
        tween(self.dock, 0.14, { GroupTransparency = 0 })
        self:_layout()
    else
        self._drag = nil
        tween(self.main, 0.12, { GroupTransparency = 1 })
        tween(self.dock, 0.12, { GroupTransparency = 1 })
        task.delay(0.13, function()
            if self.alive and token == self._token and not self.visible then
                self.main.Visible = false
                self.dock.Visible = false
            end
        end)
    end
end
function Window:Toggle() self:SetVisible(not self.visible) end

function Window:Minimize()
    self.folded = not self.folded
    self:_closePopup()
    self.body.Visible = not self.folded
    self.footer.Visible = not self.folded
    self:_layout()
end

-- Window:KeyHint({ Title = "ESP / SILENT AIM", Key = Enum.KeyCode.KeypadEight, Side = "Left" | "Right",
--                  Pressed = function(key) end, Callback = function(newKey) end, Flag })
-- A key badge with a caption above the footer; click the badge to rebind (Backspace clears, Escape cancels).
function Window:KeyHint(cfg)
    cfg = cfg or {}
    local right = cfg.Side == "Right"
    local group = create("Frame", {
        Name = tostring(cfg.Title or "Hint"), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 26), LayoutOrder = #self.hints + 1, Parent = right and self.hintRight or self.hintLeft,
    })
    Util.list(group, 8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    local badge = create("TextButton", {
        Name = "Key", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", TextSize = 10,
        Font = Enum.Font.GothamMedium, Size = UDim2.fromOffset(48, 22), LayoutOrder = right and 3 or 1, Parent = group,
    })
    Theme.bind(badge, "TextColor3", "text")
    corner(badge, 6)
    local outline = stroke(badge, nil, 0.25)
    Theme.bind(outline, "Color", "line")
    local dot = label(group, "•", 10, { Name = "Dot", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 20), LayoutOrder = 2, TextTruncate = Enum.TextTruncate.None })
    Theme.bind(dot, "TextColor3", "muted")
    local caption = label(group, tostring(cfg.Title or ""), 9, { Name = "Caption", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 20), LayoutOrder = right and 1 or 3, TextTruncate = Enum.TextTruncate.None })
    Theme.bind(caption, "TextColor3", "muted")

    local window = self
    local hint = { Type = "KeyHint", Title = cfg.Title, Row = group, Flag = cfg.Flag }
    local function show(text)
        badge.Text = text
        badge.Size = UDim2.fromOffset(math.max(48, Util.textWidth(text, 10, Enum.Font.GothamMedium) + 18), 22)
    end
    function hint:Set(key, silent)
        key = Util.toKey(key)
        if cfg.Menu and not key then key = window.key end
        self.Value = key
        show(Util.keyName(key))
        if not cfg.Menu then window:_bind(self, key) end
        if self.Flag then window.Lib.Flags[self.Flag] = key end
        if not silent then window:_safe(tostring(cfg.Title or "Key"), cfg.Callback, key) end
    end
    function hint:Get() return self.Value end
    function hint:SetTitle(text) caption.Text = tostring(text) end
    function hint:_onBind() window:_safe(tostring(cfg.Title or "Key"), cfg.Pressed, self.Value) end
    function hint:_save() return self.Value and self.Value.Name or "None" end
    function hint:_load(value) self:Set(value) end
    badge.MouseEnter:Connect(function() Util.tween(outline, 0.12, { Transparency = 0.1 }) end)
    badge.MouseLeave:Connect(function() Util.tween(outline, 0.12, { Transparency = 0.25 }) end)
    badge.Activated:Connect(function()
        show("...")
        window._capture = function(key)
            if key == Enum.KeyCode.Escape then hint:Set(hint.Value, true)
            elseif key == Enum.KeyCode.Backspace and not cfg.Menu then hint:Set(nil)
            elseif not cfg.Menu and key == window.key then hint:Set(hint.Value, true)
            else hint:Set(key) end
        end
    end)
    if cfg.Flag then self:_register(cfg.Flag, hint) end
    self.hints[#self.hints + 1] = hint
    self.hintBar.Visible = true
    self:_layoutBody()
    hint:Set(cfg.Key, true)
    return hint
end

-- Changes the menu key everywhere (menu key hint, Settings tab).
function Window:SetToggleKey(key)
    key = Util.toKey(key)
    if not key then -- the menu always needs a key: put the current one back on every display
        if self.menuHint then self.menuHint:Set(self.key, true) end
        for _, listener in ipairs(self._menuListeners or {}) do Util.safe(listener, self.key) end
        return
    end
    self.key = key
    if self.menuHint and self.menuHint.Value ~= key then self.menuHint:Set(key, true) end
    for _, listener in ipairs(self._menuListeners or {}) do Util.safe(listener, key) end
end
function Window:SetFooter(text) self.footerText.Text = tostring(text or "") end
function Window:Notify(cfg) return self.Lib:Notify(cfg) end
function Window:SelectTab(target)
    for _, tab in ipairs(self.Tabs) do
        if tab == target or tab.Title == target then tab:Select() return tab end
    end
end

function Window:Destroy()
    if not self.alive then return end
    self.alive = false
    self._drag, self._capture = nil, nil
    self.maid:clean()
    local env = (getgenv and getgenv()) or _G
    if env.__QustahUIWindows and env.__QustahUIWindows[self.Title] == self then env.__QustahUIWindows[self.Title] = nil end
    for index, window in ipairs(self.Lib.Windows) do
        if window == self then table.remove(self.Lib.Windows, index) break end
    end
    Util.safe(self.cfg.OnClose)
end

return Window
end

return require("init")
