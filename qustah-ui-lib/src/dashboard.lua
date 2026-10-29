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
    local session = page:Card({ Title = "Session", Side = "Left" })
    local userId = session:Info({ Title = "User ID", Value = "#" .. player.UserId, Copy = function() return tostring(player.UserId) end })
    if window.OnAnonymousChanged then window:OnAnonymousChanged(function(on) userId:Set(on and "hidden" or ("#" .. player.UserId)) end) end
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
        local modulesCard = page:Card({ Title = "Modules", Side = "Left" })
        local empty = modulesCard:Label("Modules report here with Window:SetModule(name, state)")
        local rows = {}
        local COLORS = { On = "success", Limited = "warning", Error = "danger" }
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
