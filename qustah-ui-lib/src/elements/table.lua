-- card:Table({
--     Title = "Players", Height = 160, Search = false, Sortable = true,
--     Columns = { "Name", { Title = "Kills", Width = 0.2, Align = "Right" }, { Title = "Team", Width = 0.25 } },
--     Rows = { { "Player1", 12, "Red" }, ... },
--     OnRowClick = function(row, index) end,
-- })
-- A scrolling table. Click a column header to sort by it (again for the other direction); numbers sort as
-- numbers. Search = true adds a filter box. :SetRows(rows), :AddRow(row), :RemoveRow(index), :UpdateRow(index, row),
-- :Clear(), :Sort(column, descending), :GetRows(). No flag (it shows data).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

local ROW = 24

return function(card, cfg)
    -- columns: widths default to an equal share of what the sized ones leave
    local columns, fixed, open = {}, 0, 0
    for index, spec in ipairs(cfg.Columns or { "Value" }) do
        if type(spec) ~= "table" then spec = { Title = spec } end
        local width = tonumber(spec.Width)
        columns[index] = { title = tostring(spec.Title or ("Column " .. index)), width = width, align = spec.Align == "Right" and Enum.TextXAlignment.Right or (spec.Align == "Center" and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left) }
        if width then fixed = fixed + width else open = open + 1 end
    end
    for _, column in ipairs(columns) do
        if not column.width then column.width = open > 0 and math.max(0.05, (1 - fixed) / open) or 0.1 end
    end
    local height = tonumber(cfg.Height) or 160
    local top = (cfg.Title and 22 or 0) + (cfg.Search and 30 or 0)
    local holder = create("Frame", { Name = tostring(cfg.Title or "Table"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, top + height), LayoutOrder = card:_order(), Parent = card.body })
    local title
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Size = UDim2.new(1, -80, 0, 20) })
        Theme.bind(title, "TextColor3", "text")
    end
    local count = label(holder, "", 9, { Name = "Count", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(80, 20), TextXAlignment = Enum.TextXAlignment.Right })
    Theme.bind(count, "TextColor3", "muted")
    local search
    if cfg.Search then
        search = create("TextBox", {
            Name = "Search", Position = UDim2.fromOffset(0, cfg.Title and 22 or 0), Size = UDim2.new(1, 0, 0, 24), BorderSizePixel = 0,
            Text = "", PlaceholderText = "Search...", TextSize = 10, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false, Parent = holder,
        })
        Theme.bind(search, "BackgroundColor3", "input")
        Theme.bind(search, "TextColor3", "text")
        Theme.bind(search, "PlaceholderColor3", "muted")
        corner(search, 6)
        Theme.bind(stroke(search), "Color", "buttonEdge")
        Util.padding(search, 8, 8, 0, 0)
    end
    local box = create("Frame", { Name = "Box", Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, ClipsDescendants = true, Parent = holder })
    Theme.bind(box, "BackgroundColor3", "base")
    corner(box, 7)
    Theme.bind(stroke(box), "Color", "line")
    local head = create("Frame", { Name = "Head", Size = UDim2.new(1, 0, 0, ROW), BorderSizePixel = 0, Parent = box })
    Theme.bind(head, "BackgroundColor3", "input")
    local headLine = create("Frame", { Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = head })
    Theme.bind(headLine, "BackgroundColor3", "line")
    local body = create("ScrollingFrame", {
        Name = "Rows", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, ROW), Size = UDim2.new(1, 0, 1, -ROW),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = box,
    })
    Theme.bind(body, "ScrollBarImageColor3", "muted")
    Util.fadeScrollbar(body)
    Util.fitCanvas(body, Util.list(body, 0))
    local empty = label(box, cfg.Empty or "No rows", 10, { Name = "Empty", Position = UDim2.fromOffset(0, ROW), Size = UDim2.new(1, 0, 1, -ROW), TextXAlignment = Enum.TextXAlignment.Center })
    Theme.bind(empty, "TextColor3", "muted")

    local element = Base.element(card, "Table", {}, holder, title, nil)
    local rows = {}
    local sortColumn, descending = nil, false
    local headers = {}

    -- x position (scale) where each column starts
    local function starts()
        local out, x = {}, 0
        for index, column in ipairs(columns) do out[index] = x x = x + column.width end
        return out
    end
    local function cell(parent, index, text, x, bold)
        local column = columns[index]
        local object = label(parent, tostring(text == nil and "" or text), 10, {
            Name = "Cell" .. index, Position = UDim2.new(x, 8, 0, 0), Size = UDim2.new(column.width, -16, 1, 0),
            TextXAlignment = column.align, Font = bold and Enum.Font.GothamMedium or Enum.Font.Gotham,
        })
        return object
    end

    local sortable = cfg.Sortable ~= false
    for index, column in ipairs(columns) do
        local x = starts()[index]
        local button = create("TextButton", { Name = column.title, Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromScale(x, 0), Size = UDim2.new(column.width, 0, 1, 0), Parent = head })
        local text = label(button, column.title, 9, { Name = "Text", Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), TextXAlignment = column.align, Font = Enum.Font.GothamMedium })
        Theme.bind(text, "TextColor3", "muted")
        -- the sort arrow sits right next to the column name (before it in right-aligned columns)
        local nameWidth = Util.textWidth(column.title, 9, Enum.Font.GothamMedium)
        local arrowPos
        if column.align == Enum.TextXAlignment.Right then arrowPos = UDim2.new(1, -(8 + nameWidth + 2), 0.5, 0)
        elseif column.align == Enum.TextXAlignment.Center then arrowPos = UDim2.new(0.5, nameWidth / 2 + 2, 0.5, 0)
        else arrowPos = UDim2.new(0, 8 + nameWidth + 2, 0.5, 0) end
        local arrow = Icons.themed(button, "chevron-down", 10, "accent", { Name = "Arrow", AnchorPoint = Vector2.new(column.align == Enum.TextXAlignment.Right and 1 or 0, 0.5), Position = arrowPos, Visible = false })
        headers[index] = { text = text, arrow = arrow }
        if sortable then
            button.MouseEnter:Connect(function() Theme.tweenTo(text, "TextColor3", "heading", 0.1) end)
            button.MouseLeave:Connect(function() Theme.tweenTo(text, "TextColor3", sortColumn == index and "accent" or "muted", 0.1) end)
            button.Activated:Connect(function() element:Sort(index, sortColumn == index and not descending) end)
        end
    end

    local function matches(row)
        local query = search and search.Text:lower() or ""
        if query == "" then return true end
        for index = 1, #columns do
            local value = row[index]
            if value ~= nil and tostring(value):lower():find(query, 1, true) then return true end
        end
        return false
    end
    local function ordered()
        local list = {}
        for index, row in ipairs(rows) do list[#list + 1] = { row = row, index = index } end
        if sortColumn then
            table.sort(list, function(a, b)
                local x, y = a.row[sortColumn], b.row[sortColumn]
                -- empty cells always go last, whichever direction
                local emptyX, emptyY = x == nil or x == "", y == nil or y == ""
                if emptyX or emptyY then
                    if emptyX and emptyY then return a.index < b.index end
                    return emptyY
                end
                if tostring(x) == tostring(y) then return a.index < b.index end -- stable
                local nx, ny = tonumber(x), tonumber(y)
                local less
                if nx and ny then less = nx < ny
                elseif nx or ny then less = nx ~= nil -- numbers before text
                else less = tostring(x):lower() < tostring(y):lower() end
                if descending then return not less end
                return less
            end)
        end
        return list
    end
    local drawn = {}
    local function render()
        for _, object in ipairs(drawn) do object:Destroy() end
        drawn = {}
        local x = starts()
        local shown = 0
        for position, item in ipairs(ordered()) do
            if matches(item.row) then
                shown = shown + 1
                local line = create("TextButton", { Name = "Row" .. item.index, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, ROW), LayoutOrder = position, Parent = body })
                Theme.bind(line, "BackgroundColor3", "card")
                local stripe = shown % 2 == 0 and 0.4 or 1 -- every other row slightly lighter
                line.BackgroundTransparency = stripe
                for index = 1, #columns do
                    local object = cell(line, index, item.row[index], x[index], index == 1)
                    Theme.bind(object, "TextColor3", index == 1 and "heading" or "text")
                end
                line.MouseEnter:Connect(function() Theme.tweenTo(line, "BackgroundColor3", "hover", 0.08) line.BackgroundTransparency = 0 end)
                line.MouseLeave:Connect(function() Theme.tweenTo(line, "BackgroundColor3", "card", 0.08) line.BackgroundTransparency = stripe end)
                if cfg.OnRowClick then
                    local rowData, rowIndex = item.row, item.index
                    line.Activated:Connect(function() element:_call(cfg.OnRowClick, rowData, rowIndex) end)
                end
                drawn[#drawn + 1] = line
            end
        end
        empty.Visible = shown == 0
        empty.Text = #rows > 0 and "No matches" or (cfg.Empty or "No rows")
        count.Text = (shown == #rows) and (#rows .. (#rows == 1 and " row" or " rows")) or (shown .. " / " .. #rows)
        for index, header in ipairs(headers) do
            local on = sortColumn == index
            Theme.bind(header.text, "TextColor3", on and "accent" or "muted")
            if header.arrow then
                header.arrow.Visible = on
                header.arrow.Rotation = descending and 0 or 180
            end
        end
    end

    -- (by column count, so a nil in the middle of a row doesn't cut it short)
    local function copy(row)
        local out = {}
        row = row or {}
        for index = 1, math.max(#columns, #row) do out[index] = row[index] end
        return out
    end
    function element:SetRows(list)
        rows = {}
        for _, row in ipairs(list or {}) do rows[#rows + 1] = copy(row) end
        render()
    end
    function element:AddRow(row) rows[#rows + 1] = copy(row) render() return #rows end
    function element:RemoveRow(index) if rows[index] then table.remove(rows, index) render() end end
    function element:UpdateRow(index, row) if rows[index] then rows[index] = copy(row) render() end end
    function element:Clear() rows = {} render() end
    function element:GetRows() return rows end
    function element:Sort(column, desc)
        if column ~= nil and not columns[column] then
            for index, item in ipairs(columns) do if item.title == column then column = index break end end
        end
        sortColumn = columns[column] and column or nil
        descending = desc == true
        render()
    end
    function element:Get() return rows end
    function element:Set(list) self:SetRows(list) end
    if search then search:GetPropertyChangedSignal("Text"):Connect(render) end

    element:SetRows(cfg.Rows)
    if cfg.SortBy then element:Sort(cfg.SortBy, cfg.Descending) end
    return element
end
