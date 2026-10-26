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
