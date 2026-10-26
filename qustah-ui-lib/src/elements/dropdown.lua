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
        -- the popup lives outside the scaled window, so it gets the window's scale itself
        local scale = window.scale and window.scale.Scale or 1
        local width = math.max(size.X / scale, 120)
        local roomBelow, roomAbove = viewport.Y - 8 - position.Y, position.Y + size.Y - 8
        local below = roomBelow >= total * scale or roomBelow >= roomAbove
        popup = create("Frame", {
            Name = "DropdownList", BorderSizePixel = 0, ZIndex = 260,
            Position = UDim2.fromOffset(math.clamp(position.X, 8, math.max(8, viewport.X - width * scale - 8)), below and position.Y or position.Y + size.Y - total * scale),
            Size = UDim2.fromOffset(width, total), Parent = window.gui,
        })
        create("UIScale", { Scale = scale, Parent = popup })
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
