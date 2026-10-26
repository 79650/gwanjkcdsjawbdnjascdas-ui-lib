-- qustah-ui-lib v1.0.1 | bundled from src/ by build.py - edit the source files, not this one.
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
end

__modules["dashboard"] = function()
-- Window:DashboardTab({ Title, Icon, Info = { { "Code revision", "571" }, ... }, Server = true })
-- Qustah's overview: profile card (avatar, names, session timer), Session, Info and Server cards.
-- Call it before the other tabs; a divider goes between it and the next tab in the dock.
local Util = require("util")
local Theme = require("theme")

local Services = Util.Services
local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

return function(window, cfg)
    cfg = cfg or {}
    local Players = Services.Players
    local player = Players.LocalPlayer
    local tab = window:Tab({ Title = cfg.Title or "Dashboard", Icon = cfg.Icon or "rbxassetid://111637692403997" })
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
    local element = { Type = kind, Flag = cfg.Flag, Row = row, Card = card, Locked = false, _changed = {} }

    function element:OnChanged(callback)
        self._changed[#self._changed + 1] = callback
        return self
    end
    -- Stores the flag value; unless silent, runs Callback and the OnChanged listeners.
    function element:_fire(value, silent)
        if self.Flag then window.Lib.Flags[self.Flag] = value end
        if silent then return end
        Util.safe(cfg.Callback, value)
        for _, callback in ipairs(self._changed) do Util.safe(callback, value) end
    end
    function element:SetTitle(text) if title then title.Text = tostring(text) end end
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
    function element:Fire() Util.safe(cfg.Callback) end

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
        Util.safe(cfg.Callback)
    end)
    return Base.finish(element, cfg)
end
end

__modules["elements/colorpicker"] = function()
-- card:ColorPicker({ Title, Desc, Flag, Default = Color3, Callback = function(color) end, Locked })
-- Click the swatch to open the picker under the row: saturation / brightness square, hue bar, HEX box, Random.
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
        Name = "Picker", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 132), LayoutOrder = row.LayoutOrder + 1,
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

    local side = create("Frame", { Name = "Side", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 4), Size = UDim2.fromOffset(92, 122), Parent = panel })
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
    local done = create("TextButton", {
        Name = "Done", Position = UDim2.fromOffset(0, 92), Size = UDim2.new(1, 0, 0, 24), BorderSizePixel = 0,
        Text = "Done", TextSize = 10, Font = Enum.Font.GothamMedium, AutoButtonColor = false, Parent = side,
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
    local function commit(silent)
        local color = Color3.fromHSV(h, s, v)
        local changed = color ~= element.Value
        element.Value = color
        render()
        element:_fire(color, silent or not changed)
    end
    function element:Set(color, silent)
        if type(color) == "string" then color = Util.fromHex(color) end
        if typeof(color) ~= "Color3" then return end
        h, s, v = color:ToHSV()
        commit(silent)
    end
    function element:Get() return self.Value end
    function element:_save() return Util.toHex(self.Value) end
    function element:_load(data) self:Set(data) end
    function element:SetOpen(open) panel.Visible = open == true end

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
        if color then element:Set(color) else render() end
    end)
    random.Activated:Connect(function() if not element.Locked then element:Set(Color3.fromHSV(math.random(), 0.45 + math.random() * 0.5, 0.6 + math.random() * 0.4)) end end)
    done.Activated:Connect(function() panel.Visible = false end)
    local function toggleOpen() if not element.Locked then panel.Visible = not panel.Visible end end
    row.Activated:Connect(toggleOpen)
    swatch.Activated:Connect(toggleOpen)

    local default = cfg.Default
    if type(default) == "string" then default = Util.fromHex(default) end
    element:Set(typeof(default) == "Color3" and default or Color3.new(1, 1, 1), true)
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
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local window = card.window
    local row, title, desc = Base.row(card, cfg, cfg.Desc and 40 or 30, { right = 100 })
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

    function element:Set(key, silent)
        key = Util.toKey(key)
        local changed = key ~= self.Value
        self.Value = key
        window:_bind(self, key)
        show(Util.keyName(key))
        Theme.tweenTo(outline, "Color", "buttonEdge", 0.1)
        if changed then self:_fire(key, silent) else self:_fire(key, true) end
    end
    function element:Get() return self.Value end
    function element:_onBind() Util.safe(cfg.Pressed, self.Value) end
    function element:_save() return self.Value and self.Value.Name or "None" end

    badge.Activated:Connect(function()
        if element.Locked then return end
        show("...")
        Theme.tweenTo(outline, "Color", "accent", 0.1)
        window._capture = function(key)
            if key == Enum.KeyCode.Escape then element:Set(element.Value, true)
            elseif key == Enum.KeyCode.Backspace then element:Set(nil)
            elseif key == window.key then element:Set(element.Value, true) -- the menu key stays the menu key
            else element:Set(key) end
        end
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

__modules["init"] = function()
-- qustah-ui-lib: entry point. The build script bundles every module into dist/qustah-ui-lib.lua.
local Util = require("util")
local Theme = require("theme")
local Window = require("window")
local Notify = require("notify")
local Settings = require("settings")
local Dashboard = require("dashboard")

local Lib = {
    Version = "1.0.1",
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
-- Window:SettingsTab({ Title, Icon }) - ready-made tab: accent colour, menu key, window reset, unload and configs.
local Theme = require("theme")

return function(window, cfg)
    cfg = cfg or {}
    local defaultSize = Vector2.new(window.width, window.height)
    local tab = window:Tab({ Title = cfg.Title or "Settings", Icon = cfg.Icon or "rbxassetid://11385220704", Divider = cfg.Divider ~= false })
    local interface = tab:Page("Interface")
    local configs = tab:Page("Configs", { Columns = 1 })

    ------------------------------------------------------------ interface
    local look = interface:Card({ Title = "Interface", Side = "Left" })
    look:ColorPicker({
        Title = "Accent color", Desc = "Saved with your config", Flag = "__ui_accent", Default = Theme.get("accent"),
        Callback = function(color) Theme.set("accent", color) end,
    })
    local menuKey = look:Keybind({
        Title = "Menu key", Desc = "Opens and closes the menu", Flag = "__ui_menu_key", Default = window.key,
        Callback = function(key) window:SetToggleKey(key) end,
    })
    window._menuListeners = window._menuListeners or {}
    table.insert(window._menuListeners, function(key) if menuKey.Value ~= key then menuKey:Set(key, true) end end)
    local windowCard = interface:Card({ Title = "Window", Side = "Right" })
    windowCard:Label("Drag the bottom-right corner to resize the window.")
    windowCard:Button({
        Title = "Reset window size",
        Callback = function()
            window.width, window.height, window.topLeft = defaultSize.X, defaultSize.Y, nil
            window:_layout()
        end,
    })
    windowCard:Button({ Title = "Unload", Confirm = "Click again to unload", Callback = function() window:Destroy() end })

    ------------------------------------------------------------ configs
    local store = window.Config
    local card = configs:Card({ Title = "Configs" })
    local nameInput = card:Input({ Title = "Config name", Placeholder = "my config" })
    local list = card:Dropdown({ Title = "Saved configs", Options = store:List() })
    local autoload = card:Label("")
    local function refresh()
        list:SetOptions(store:List(), true)
        local name = store:GetAutoLoad()
        autoload:Set("Autoload: " .. (name or "none"))
    end
    local function target()
        local typed = nameInput.Value
        if typed and typed ~= "" then return typed end
        return list.Value
    end
    local function report(ok, message, done)
        window:Notify({ Title = ok and done or "Config", Content = message or "", Color = not ok and Color3.fromRGB(215, 130, 130) or nil })
    end
    card:Divider()
    card:Button({ Title = "Save", Callback = function()
        local name = target()
        if not name then return report(false, "Type a name or pick a config") end
        local ok, err = store:Save(name)
        report(ok, ok and name or err, "Saved")
        refresh()
    end })
    card:Button({ Title = "Load", Callback = function()
        local name = target()
        if not name then return report(false, "Pick a config") end
        local ok, err = store:Load(name)
        report(ok, err or name, "Loaded")
    end })
    card:Button({ Title = "Set as autoload", Callback = function()
        local name = target()
        if not name then return report(false, "Pick a config") end
        store:SetAutoLoad(name)
        report(true, name, "Autoload set")
        refresh()
    end })
    card:Button({ Title = "Delete", Confirm = "Click again to delete", Callback = function()
        local name = target()
        if not name then return report(false, "Pick a config") end
        local ok, err = store:Delete(name)
        report(ok, ok and name or err, "Deleted")
        refresh()
    end })
    card:Button({ Title = "Refresh list", Callback = refresh })
    refresh()
    return tab
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
    LeftAlt = "LALT", RightAlt = "RALT", MouseButton2 = "M2", MouseButton3 = "M3", Return = "ENTER",
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
    local ok, key = pcall(function() return Enum.KeyCode[name] end)
    if ok and key then return key end
    ok, key = pcall(function() return Enum.UserInputType[name] end)
    if ok and key then return key end
    return nil
end
-- The key an input means for binds: the KeyCode for keyboards, the UserInputType for mouse buttons 2/3.
function Util.inputKey(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then return input.KeyCode end
    if input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
        return input.UserInputType
    end
    return nil
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
    self:_build()
    self.Config = Config.new(self, cfg.Folder or self.Title:gsub("[^%w_%- ]", ""))
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

    ---------------------------------------------------------------- close popup (Minimize / Close)
    local popup = create("Frame", { Name = "ClosePopup", Size = UDim2.fromOffset(190, 68), BorderSizePixel = 0, Visible = false, ZIndex = 250, Parent = gui })
    Theme.bind(popup, "BackgroundColor3", "card")
    corner(popup, 8)
    Theme.bind(stroke(popup), "Color", "line")
    local popupTitle = label(popup, self.Title, 11, { Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 24), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamMedium, ZIndex = 251 })
    Theme.bind(popupTitle, "TextColor3", "text")
    local function popupButton(text, x, danger)
        local button = create("TextButton", {
            Text = text, TextSize = 10, Font = Enum.Font.Gotham, AutoButtonColor = false, BorderSizePixel = 0,
            Position = UDim2.fromOffset(x, 32), Size = UDim2.fromOffset(82, 26), ZIndex = 251, Parent = popup,
        })
        Theme.bind(button, "BackgroundColor3", "input")
        if danger then button.TextColor3 = Color3.fromRGB(210, 105, 105) else Theme.bind(button, "TextColor3", "text") end
        corner(button, 6)
        Theme.bind(stroke(button), "Color", "buttonEdge")
        return button
    end
    local popupMinimize = popupButton("Minimize", 10, false)
    local popupClose = popupButton("Close", 98, true)

    ---------------------------------------------------------------- behaviour
    local function moveWindow(input)
        if not Util.isPress(input) then return end
        local start, origin = Util.pointer(input), self.topLeft
        self:_hideTip()
        self:_beginDrag(input, function(point)
            self.topLeft = origin + (point - start)
            self:_layout()
        end)
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
        end)
    end)
    maid:connect(minimize.Activated, function() self:Minimize() end)
    maid:connect(close.Activated, function()
        if popup.Visible then self:_closePopup() return end
        local position = close.AbsolutePosition
        local viewport = Util.viewport()
        popup.Position = UDim2.fromOffset(
            math.clamp(position.X + close.AbsoluteSize.X - 190, 8, math.max(8, viewport.X - 198)),
            math.clamp(position.Y + close.AbsoluteSize.Y + 6, 8, math.max(8, viewport.Y - 76)))
        self:_openPopup(popup, close, function() popup.Visible = false end)
        popup.Visible = true
    end)
    maid:connect(popupMinimize.Activated, function() self:_closePopup() if not self.folded then self:Minimize() end end)
    maid:connect(popupClose.Activated, function() self:_closePopup() self:Destroy() end)

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
            local key = Util.inputKey(input)
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
        if processed or UserInputService:GetFocusedTextBox() then return end
        local key = Util.inputKey(input)
        if not key then return end
        -- 3. menu key, then toggle / keybind binds
        if key == self.key then self:Toggle() return end
        for element, bound in pairs(self.binds) do
            if bound == key and element.Row and element.Row.Parent then Util.safe(element._onBind, element) end
        end
    end)

    if self.cfg.KeyHints ~= false then
        self.menuHint = self:KeyHint({ Title = "MENU", Side = "Right", Key = self.key, Menu = true, Callback = function(key) self:SetToggleKey(key) end })
    end

    local function watchCamera()
        local camera = workspace.CurrentCamera
        if camera then maid:connect(camera:GetPropertyChangedSignal("ViewportSize"), function() self:_layout() end) end
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
        self.topLeft = Vector2.new((viewport.X - total * s) / 2, (viewport.Y - self.height * s) / 2)
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
    self.locationLabel.Visible = self.width >= 440
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

function Window:_updateLocation()
    local tab = self.current
    if not tab then self.locationLabel.Text = "" return end
    local page = tab.current
    self.locationLabel.Text = (page and #tab.Pages > 1) and (tab.Title .. " › " .. page.Name) or tab.Title
    self.locationLabel.Visible = self.width >= 440
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
    self:_layoutDock()
    self:_layout()
    if not self.current then tab:Select() end
    return tab
end

function Window:SetVisible(visible)
    self.visible = visible
    self:_closePopup()
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
    local hint = { Type = "KeyHint", Row = group, Flag = cfg.Flag }
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
        if not silent then Util.safe(cfg.Callback, key) end
    end
    function hint:Get() return self.Value end
    function hint:SetTitle(text) caption.Text = tostring(text) end
    function hint:_onBind() Util.safe(cfg.Pressed, self.Value) end
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
function Window:SetStatus(text, color)
    self.statusLabel.Text = tostring(text)
    if typeof(color) == "Color3" then self.statusDot.BackgroundColor3 = color end
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
