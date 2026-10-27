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
        local total = 0
        for _ in pairs(rows) do total = total + 1 end
        count.Text = selected > 0 and (selected .. " selected") or (total .. (total == 1 and " player" or " players"))
    end
    local function commit()
        element.Value = multi and valueList() or valueList()[1]
        for _, entry in pairs(rows) do renderRow(entry) end
        filter()
        element:_fire(element.Value)
    end
    local function addRow(player)
        if rows[player] or not holder.Parent or (player == Players.LocalPlayer and not cfg.IncludeSelf) then return end
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
        avatar.Image = Util.avatar(player.UserId) -- rbxthumb: no web request
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
