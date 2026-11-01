-- card:Timeline({ Max = 50, Height = 220, Compact = false, Filters = { "All", "Modules", "Combat" } })
-- An activity feed, newest on top. timeline:Add({ Title = "Click TP", Desc = "212 studs", Icon = "navigation",
-- Kind = "success" | "warning" | "danger" | nil, Tag = "Combat", Time = "19:21" (now when left out) }).
-- Full: a round icon per event joined by a line, the description under the title, the time on the right.
-- Compact = true: one line per event - time, a coloured dot, the text. Filters: a row of chips that show only events
-- with that Tag ("All" shows everything). :Clear(), :GetEvents(). No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")
local Parts = require("elements/parts")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local compact = cfg.Compact == true
    local max = math.max(1, tonumber(cfg.Max) or 50)
    local height = tonumber(cfg.Height) or (compact and 130 or 220)
    local top = cfg.Filters and 28 or 0
    local holder = create("Frame", { Name = tostring(cfg.Title or "Timeline"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height + top), LayoutOrder = card:_order(), Parent = card.body })
    local scroller = create("ScrollingFrame", {
        Name = "Events", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 1, -top),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, Parent = holder,
    })
    Theme.bind(scroller, "ScrollBarImageColor3", "buttonEdge")
    Util.list(scroller, compact and 0 or 2)
    local element = Base.element(card, "Timeline", { Title = cfg.Title }, holder, nil, nil)
    local events, filter, order = {}, "All", 0
    local empty = label(scroller, tostring(cfg.Empty or "Nothing yet"), 10, { Name = "Empty", Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 1e9 })
    Theme.bind(empty, "TextColor3", "muted")

    local function refresh()
        local shown = 0
        for index, event in ipairs(events) do
            local visible = filter == "All" or event.data.Tag == filter
            event.row.Visible = visible
            if visible then shown = shown + 1 end
            if event.line then event.line.Visible = index < #events end
        end
        empty.Visible = shown == 0
    end
    if cfg.Filters then
        local chips = {}
        local x = 0
        for _, name in ipairs(cfg.Filters) do
            local width = Util.textWidth(name, 9, Enum.Font.GothamMedium) + 18
            local button = create("TextButton", { Name = name, Text = name, AutoButtonColor = false, BorderSizePixel = 0, Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(width, 20), TextSize = 9, Font = Enum.Font.GothamMedium, Parent = holder })
            corner(button, 10)
            chips[name] = button
            x = x + width + 4
            button.Activated:Connect(function()
                filter = name
                for other, chip in pairs(chips) do
                    Theme.tweenTo(chip, "BackgroundColor3", other == filter and "selected" or "input", 0.1)
                    Theme.tweenTo(chip, "TextColor3", other == filter and "heading" or "muted", 0.1)
                end
                refresh()
            end)
            Theme.bind(button, "BackgroundColor3", name == filter and "selected" or "input")
            Theme.bind(button, "TextColor3", name == filter and "heading" or "muted")
        end
    end

    function element:Add(data)
        if type(data) ~= "table" then data = { Title = tostring(data) } end
        data.Time = data.Time or os.date("%H:%M")
        order = order - 1
        local role = data.Kind and Parts.stateRole(data.Kind) or nil
        local row
        if compact then
            row = create("Frame", { Name = "Event", BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, 18), LayoutOrder = order, Parent = scroller })
            local time = label(row, tostring(data.Time), 9, { Name = "Time", Size = UDim2.fromOffset(40, 18), Font = Enum.Font.Code })
            Theme.bind(time, "TextColor3", "muted")
            Parts.dot(row, role or "muted", 6, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 44, 0.5, 0) })
            local text = label(row, tostring(data.Title) .. (data.Desc and (" · " .. tostring(data.Desc)) or ""), 10, { Name = "Text", Position = UDim2.fromOffset(56, 0), Size = UDim2.new(1, -56, 1, 0) })
            Theme.bind(text, "TextColor3", "text")
        else
            local h = data.Desc and 38 or 30
            row = create("Frame", { Name = "Event", BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, h), LayoutOrder = order, Parent = scroller })
            local bubble = create("Frame", { Name = "Bubble", Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(0, 3), BorderSizePixel = 0, ZIndex = 2, Parent = row })
            corner(bubble, 12)
            Theme.bind(bubble, "BackgroundColor3", "input")
            Theme.bind(Util.stroke(bubble, nil, 0.2), "Color", "buttonEdge")
            local icon = Icons.themed(bubble, data.Icon or "circle", 11, role or "icon", { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 2 })
            if not icon then Parts.dot(bubble, role or "muted", 6, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 2 }) end
            local line = create("Frame", { Name = "Line", Position = UDim2.fromOffset(12, 27), Size = UDim2.new(0, 1, 1, -22), BorderSizePixel = 0, Parent = row })
            Theme.bind(line, "BackgroundColor3", "line")
            local title = label(row, tostring(data.Title), 11, { Name = "Title", Position = UDim2.fromOffset(34, 4), Size = UDim2.new(1, -90, 0, 14) })
            Theme.bind(title, "TextColor3", "heading")
            if data.Desc then
                local desc = label(row, tostring(data.Desc), 9, { Name = "Desc", Position = UDim2.fromOffset(34, 19), Size = UDim2.new(1, -90, 0, 12) })
                Theme.bind(desc, "TextColor3", "muted")
            end
            local time = label(row, tostring(data.Time), 9, { Name = "Time", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, 4), Size = UDim2.fromOffset(52, 14), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.Code })
            Theme.bind(time, "TextColor3", "muted")
            -- (the line joins this event to the older one below it)
            table.insert(events, 1, { data = data, row = row, line = line })
        end
        if compact then table.insert(events, 1, { data = data, row = row }) end
        while #events > max do local old = table.remove(events) old.row:Destroy() end
        refresh()
        return row
    end
    function element:Clear()
        for _, event in ipairs(events) do event.row:Destroy() end
        table.clear(events)
        refresh()
    end
    function element:GetEvents()
        local out = {}
        for _, event in ipairs(events) do out[#out + 1] = event.data end
        return out
    end
    for _, data in ipairs(cfg.Events or {}) do element:Add(data) end
    refresh()
    return Base.finish(element, cfg)
end
