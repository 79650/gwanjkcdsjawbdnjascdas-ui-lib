-- card:ItemList({ Items = { { Title = "Kage Office", Desc = "312 studs", Icon = "map-pin" }, ... }, Button = "Go",
--     Search = true, Placeholder = "Search…", Rows = 4, Empty = "Nothing found", Callback = function(item, index) end })
-- A list of rows (icon, title, muted line, a small button on the right) with a search box over it. At most Rows rows
-- show at once; the rest scroll. Clicking a row or its button runs Callback with the item table.
-- :SetItems(items) replaces the list (the search text stays), :SetDesc(title, text) changes one row's muted line,
-- :SetFilter(text). No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

local ROW = 36

return function(card, cfg)
    local window = card.window
    local rowsShown = math.max(1, tonumber(cfg.Rows) or 4)
    local searchable = cfg.Search ~= false
    local top = searchable and 34 or 0
    local holder = create("Frame", { Name = tostring(cfg.Title or "ItemList"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, top + ROW), LayoutOrder = card:_order(), Parent = card.body })

    -- search box
    local box
    if searchable then
        local field = create("Frame", { Name = "Search", Size = UDim2.new(1, 0, 0, 28), BorderSizePixel = 0, Parent = holder })
        Theme.bind(field, "BackgroundColor3", "input")
        corner(field, 7)
        Theme.bind(stroke(field, nil, 0.2), "Color", "buttonEdge")
        Icons.themed(field, "search", 12, "muted", { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0) })
        box = create("TextBox", {
            Name = "Box", BackgroundTransparency = 1, Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -36, 1, 0), Text = "", ClearTextOnFocus = false,
            PlaceholderText = tostring(cfg.Placeholder or "Search…"), TextSize = 10, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = field,
        })
        Theme.bind(box, "TextColor3", "heading")
    end

    -- the rows: a scrolling frame as tall as Rows rows (shorter lists shrink to fit)
    local scroller = create("ScrollingFrame", {
        Name = "Rows", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, ROW),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 3, ScrollBarImageTransparency = 0.35, VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
        ElasticBehavior = Enum.ElasticBehavior.Never, Parent = holder,
    })
    Theme.bind(scroller, "ScrollBarImageColor3", "muted")
    Util.list(scroller, 0)
    local empty = label(holder, tostring(cfg.Empty or "Nothing found"), 10, { Name = "Empty", Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, ROW), TextXAlignment = Enum.TextXAlignment.Center, Visible = false })
    Theme.bind(empty, "TextColor3", "muted")

    local element = Base.element(card, "ItemList", { Title = cfg.Title }, holder, nil, nil)
    element.Items = {}
    local rows, filter = {}, ""

    local function fit()
        local shown = 0
        for _, row in ipairs(rows) do if row.frame.Visible then shown = shown + 1 end end
        local height = math.max(1, math.min(shown, rowsShown)) * ROW
        scroller.Size = UDim2.new(1, 0, 0, height)
        holder.Size = UDim2.new(1, 0, 0, top + height)
        empty.Visible = shown == 0
        scroller.Visible = shown > 0
    end
    local function applyFilter()
        local query = string.lower(filter)
        for _, row in ipairs(rows) do
            local text = string.lower(tostring(row.item.Title or "") .. " " .. tostring(row.item.Desc or ""))
            row.frame.Visible = query == "" or string.find(text, query, 1, true) ~= nil
        end
        fit()
    end
    local function press(row)
        if element.Locked then return end
        element:_call(cfg.Callback, row.item, row.index)
    end

    function element:SetItems(items)
        for _, row in ipairs(rows) do row.frame:Destroy() end
        table.clear(rows)
        self.Items = items or {}
        for index, item in ipairs(self.Items) do
            if type(item) ~= "table" then item = { Title = tostring(item) } end
            local frame = create("TextButton", { Name = tostring(item.Title), Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, ROW), LayoutOrder = index, Parent = scroller })
            if index > 1 then
                local line = create("Frame", { Name = "Line", BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1), Parent = frame })
                Theme.bind(line, "BackgroundColor3", "line")
            end
            local iconBox = create("Frame", { Name = "IconBox", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(24, 24), BorderSizePixel = 0, Parent = frame })
            Theme.bind(iconBox, "BackgroundColor3", "input")
            corner(iconBox, 7)
            Icons.themed(iconBox, item.Icon or cfg.Icon or "map-pin", 12, "muted", { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
            local hasDesc = item.Desc ~= nil and item.Desc ~= ""
            local buttonWidth = Util.textWidth(tostring(item.Button or cfg.Button or "Go"), 9, Enum.Font.GothamMedium) + 18
            local title = label(frame, tostring(item.Title or ""), 10, { Name = "Title", Position = UDim2.fromOffset(32, hasDesc and 4 or 0), Size = UDim2.new(1, -(40 + buttonWidth), 0, hasDesc and 16 or ROW) })
            Theme.bind(title, "TextColor3", "text")
            local desc = label(frame, tostring(item.Desc or ""), 8, { Name = "Desc", Position = UDim2.fromOffset(32, 19), Size = UDim2.new(1, -(40 + buttonWidth), 0, 12), Visible = hasDesc })
            Theme.bind(desc, "TextColor3", "muted")
            local go = create("TextButton", {
                Name = "Go", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(buttonWidth, 22),
                BorderSizePixel = 0, Text = tostring(item.Button or cfg.Button or "Go"), TextSize = 9, Font = Enum.Font.GothamMedium, Parent = frame,
            })
            Theme.bind(go, "BackgroundColor3", "input")
            Theme.bind(go, "TextColor3", "text")
            corner(go, 6)
            Theme.bind(stroke(go, nil, 0.2), "Color", "buttonEdge")
            local row = { frame = frame, item = item, index = index, title = title, desc = desc }
            frame.MouseEnter:Connect(function() Theme.tweenTo(title, "TextColor3", "heading", 0.1) Theme.tweenTo(go, "TextColor3", "heading", 0.1) end)
            frame.MouseLeave:Connect(function() Theme.tweenTo(title, "TextColor3", "text", 0.1) Theme.tweenTo(go, "TextColor3", "text", 0.1) end)
            frame.Activated:Connect(function() press(row) end)
            go.Activated:Connect(function() press(row) end)
            rows[#rows + 1] = row
        end
        applyFilter()
    end
    function element:SetDesc(which, text)
        for _, row in ipairs(rows) do
            if row.item.Title == which or row.index == which then
                row.item.Desc = text
                row.desc.Text = tostring(text or "")
                row.desc.Visible = text ~= nil and text ~= ""
                row.title.Position = UDim2.fromOffset(32, row.desc.Visible and 4 or 0)
                row.title.Size = UDim2.new(row.title.Size.X.Scale, row.title.Size.X.Offset, 0, row.desc.Visible and 16 or ROW)
                return
            end
        end
    end
    function element:SetFilter(text)
        filter = tostring(text or "")
        if box and box.Text ~= filter then box.Text = filter end
        applyFilter()
    end
    function element:Get() return filter end
    if box then box:GetPropertyChangedSignal("Text"):Connect(function() filter = box.Text applyFilter() end) end
    -- (the page stays put while the wheel scrolls the list)
    local capture = Util.captureScroll(scroller, function()
        return scroller.AbsoluteCanvasSize.Y > scroller.AbsoluteSize.Y + 1
    end)
    element.Maid:give(capture.Destroy)
    element:SetItems(cfg.Items)
    return Base.finish(element, cfg)
end
