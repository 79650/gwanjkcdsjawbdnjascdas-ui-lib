-- Window:DashboardTab({ Title, Icon, Info = { { "Code revision", "571" }, ... }, Server = true, Modules = true })
-- Qustah's overview: profile card (avatar, names, session timer, live FPS / ping / players chips), Session (with the
-- ids folded under "Details"), Server and Modules (a grid of tiles: Window:SetModule(name, state, detail,
-- { Icon = "eye", Tab = "ESP" }) - a click on a tile opens its tab).
-- Call it before the other tabs; a divider goes between it and the next tab in the dock.
local Util = require("util")
local Theme = require("theme")
local Glow = require("glow")
local Icons = require("icons")
local Stats = require("stats")

local Services = Util.Services
local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

return function(window, cfg)
    cfg = cfg or {}
    local Players = Services.Players
    local player = Players.LocalPlayer
    local tab = window:Tab({ Title = cfg.Title or "Dashboard", Icon = cfg.Icon or "layout-dashboard", Header = cfg.Header ~= false })
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
    -- live chips under the name: FPS · ping · players (updated with the session timer)
    local chipRow = create("Frame", { Name = "Chips", BackgroundTransparency = 1, Position = UDim2.fromOffset(76, 50), Size = UDim2.new(1, -250, 0, 16), Parent = body })
    Util.list(chipRow, 5, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    local function chip(name, icon, order)
        local holder = create("Frame", { Name = name, Size = UDim2.fromOffset(0, 16), AutomaticSize = Enum.AutomaticSize.X, BorderSizePixel = 0, LayoutOrder = order, Parent = chipRow })
        Theme.bind(holder, "BackgroundColor3", "input")
        corner(holder, 8)
        Theme.bind(stroke(holder), "Color", "line")
        Util.padding(holder, 6, 7, 0, 0)
        Util.list(holder, 4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
        Icons.themed(holder, icon, 9, "muted", { Name = "Icon", LayoutOrder = 1 })
        local text = label(holder, "--", 9, { Name = "Text", Size = UDim2.fromOffset(0, 16), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2, Font = Enum.Font.GothamMedium })
        Theme.bind(text, "TextColor3", "text")
        return text
    end
    local fpsChip, pingChip, playersChip = chip("FPS", "gauge", 1), chip("Ping", "wifi", 2), chip("Players", "users", 3)
    Stats.start(window.Lib.maid)
    local caption = label(body, "SESSION", 8, { Name = "SessionCaption", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 12), Size = UDim2.fromOffset(150, 12), TextXAlignment = Enum.TextXAlignment.Right })
    Theme.bind(caption, "TextColor3", "muted")
    local uptime = label(body, "00:00:00", 18, { Name = "Uptime", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 28), Size = UDim2.fromOffset(150, 24), TextXAlignment = Enum.TextXAlignment.Right })
    Theme.bind(uptime, "TextColor3", "accent")
    Glow.add(display, { Base = "heading", Phase = 0.1 })
    Glow.add(uptime, { Base = "accent", Phase = 0.45 })
    -- rbxthumb content: shows at once, no web request (fine in secure mode)
    local avatarImage = Util.avatar(player.UserId, 150)
    if not window.anonymous then avatar.Image = avatarImage end
    -- anonymous mode (dock profile button): no name, no id, no avatar
    if window.OnAnonymousChanged then
        window:OnAnonymousChanged(function(on)
            display.Text = on and "Anonymous" or player.DisplayName
            username.Text = on and "hidden" or ("@" .. player.Name .. " · #" .. player.UserId)
            avatar.Image = on and "" or avatarImage
        end)
    end

    ------------------------------------------------------------ session / info / server
    local session = page:Card({ Title = "Session", Side = "Left", Icon = "id-card" })
    session:Info({ Title = "Account created", Value = os.date("%d %b %Y", os.time() - player.AccountAge * 86400) })
    local executor = "Unknown"
    pcall(function()
        if type(identifyexecutor) == "function" then executor = table.concat({ identifyexecutor() }, " ")
        elseif type(getexecutorname) == "function" then executor = tostring(getexecutorname()) end
    end)
    session:Info({ Title = "Executor", Value = executor })
    if window.Version ~= "" then session:Info({ Title = "GUI version", Value = window.Version }) end
    for _, entry in ipairs(cfg.Info or {}) do session:Info({ Title = entry[1], Value = entry[2], Copy = entry.Copy }) end
    -- the ids are rarely needed: folded away under "Details"
    local details = session:Section({ Title = "Details", Icon = "hash", Opened = false })
    local userId = details:Info({ Title = "User ID", Value = "#" .. player.UserId, Copy = function() return tostring(player.UserId) end })
    if window.OnAnonymousChanged then window:OnAnonymousChanged(function(on) userId:Set(on and "hidden" or ("#" .. player.UserId)) end) end
    details:Info({ Title = "Game ID", Value = "#" .. game.GameId, Copy = function() return tostring(game.GameId) end })
    details:Info({ Title = "Place ID", Value = "#" .. game.PlaceId, Copy = function() return tostring(game.PlaceId) end })

    if cfg.Server ~= false then
        local server = page:Card({ Title = "Server", Side = "Right", Icon = "server" })
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
                if not ok then busy = false window:Notify({ Title = "Teleport failed", Content = tostring(err), Color = "danger" }) end
            end)
        end
        local actions = server:Row()
        actions:Button({ Title = "Rejoin", Icon = "refresh-cw", Callback = function() teleport(false) end })
        actions:Button({ Title = "Server hop", Icon = "shuffle", Confirm = true, Callback = function() teleport(true) end })
        server:Info({ Title = "Job ID", Value = game.JobId ~= "" and (game.JobId:sub(1, 8) .. "...") or "studio", Copy = function() return game.JobId end })
    end

    ------------------------------------------------------------ modules (Window:SetModule)
    if cfg.Modules ~= false then
        local modulesCard = page:Card({ Title = "Modules", Side = "Right", Icon = "boxes" })
        local empty = modulesCard:Label("Modules report here with Window:SetModule(name, state)")
        -- a grid of tiles: icon, name and a coloured state pill; a click opens the module's tab
        local grid = create("Frame", { Name = "ModuleGrid", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = modulesCard:_order(), Parent = modulesCard.body })
        Util.list(grid, 6)
        local tiles, gridRows = {}, {}
        -- two tiles per row (plain rows: they size with the card at any width / UI scale)
        local function rowFor(index)
            local number = math.ceil(index / 2)
            if not gridRows[number] then
                local holder = create("Frame", { Name = "Row" .. number, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), LayoutOrder = number, Parent = grid })
                Util.list(holder, 6, Enum.FillDirection.Horizontal)
                gridRows[number] = holder
            end
            return gridRows[number]
        end
        local COLORS = { On = "success", Limited = "warning", Error = "danger" }
        local function tabNamed(name)
            for _, t in ipairs(window.Tabs) do if t.Title == name then return t end end
        end
        local function tile(name, index)
            local button = create("TextButton", { Name = "Tile_" .. name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Size = UDim2.new(0.5, -3, 1, 0), LayoutOrder = index, Parent = rowFor(index) })
            Theme.bind(button, "BackgroundColor3", "input")
            corner(button, 7)
            local edge = stroke(button)
            Theme.bind(edge, "Color", "line")
            local icon = create("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(14, 14), Visible = false, Parent = button })
            local title = label(button, name, 10, { Name = "Title", Position = UDim2.fromOffset(10, 5), Size = UDim2.new(1, -18, 0, 15), Font = Enum.Font.GothamMedium })
            Theme.bind(title, "TextColor3", "text")
            -- the state under the name: a small dot and the word, in the state's colour
            local pill = label(button, "", 8, { Name = "State", Position = UDim2.fromOffset(20, 20), Size = UDim2.new(1, -28, 0, 12), Font = Enum.Font.GothamBold })
            local stateDot = create("Frame", { Name = "StateDot", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(10, 26), Size = UDim2.fromOffset(5, 5), BorderSizePixel = 0, Parent = button })
            corner(stateDot, 3)
            button.MouseEnter:Connect(function() Theme.tweenTo(edge, "Color", "accentEdge", 0.1) end)
            button.MouseLeave:Connect(function() Theme.tweenTo(edge, "Color", "line", 0.1) end)
            button.Activated:Connect(function()
                local meta = window.moduleMeta and window.moduleMeta[name]
                local target = meta and meta.Tab and tabNamed(meta.Tab)
                if target then require("sounds").Play("click") target:Select() end
            end)
            tiles[name] = { button = button, icon = icon, title = title, pill = pill, dot = stateDot }
            return tiles[name]
        end
        local function update()
            local order, modules = window:GetModules()
            empty:SetVisible(#order == 0)
            for index, name in ipairs(order) do
                local t = tiles[name] or tile(name, index)
                local module = modules[name]
                local meta = window.moduleMeta and window.moduleMeta[name]
                local hasIcon = meta and meta.Icon and Icons.Apply(t.icon, meta.Icon) or false
                t.icon.Visible = hasIcon
                if hasIcon then Theme.bind(t.icon, "ImageColor3", module.state == "Off" and "muted" or "heading") end
                local role = COLORS[module.state] or "muted"
                t.pill.Text = string.upper(module.state)
                local lead = hasIcon and 31 or 10
                t.title.Position = UDim2.fromOffset(lead, 5)
                t.title.Size = UDim2.new(1, -lead - 8, 0, 15)
                t.dot.Position = UDim2.fromOffset(lead, 26)
                t.pill.Position = UDim2.fromOffset(lead + 9, 20)
                t.pill.Size = UDim2.new(1, -lead - 17, 0, 12)
                Theme.bind(t.pill, "TextColor3", role)
                Theme.bind(t.dot, "BackgroundColor3", role)
                Theme.bind(t.title, "TextColor3", module.state == "Off" and "muted" or "text")
                t.button:SetAttribute("Detail", module.detail)
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
                playersChip.Text = #Players:GetPlayers() .. " / " .. Players.MaxPlayers
                fpsChip.Text = (Stats.fps or 0) .. " FPS"
                local ok, value = pcall(function() return player:GetNetworkPing() end)
                pingChip.Text = ok and (math.floor(value * 1000 + 0.5) .. " ms") or "--"
            end
            task.wait(1)
        end
    end)
    return tab
end
