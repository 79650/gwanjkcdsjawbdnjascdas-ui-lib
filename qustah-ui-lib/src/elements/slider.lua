-- card:Slider({ Title, Desc, Flag, Min, Max, Default, Step, Suffix, Callback, Locked, Icons = { From = "volume", To = "volume-2" }, Bubble = true })
-- Drag the track, or click the value and type a number. Icons puts an icon at each end of the track (clicking one
-- steps the value); while dragging a bubble over the knob shows the value (Bubble = false turns it off).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

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

    if desc then desc.Size = UDim2.new(1, 0, 0, 14) end -- the value sits on the title line only
    local box = create("TextBox", {
        Name = "Value", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 1), Size = UDim2.fromOffset(78, 20),
        BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", TextSize = 10, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Right, ClearTextOnFocus = false, Parent = row,
    })
    -- value sits flush right like the other controls; while typing it gets a small field
    local boxPad = Util.padding(box, 0, 0, 0, 0)
    box.Focused:Connect(function() box.BackgroundTransparency = 0.2 boxPad.PaddingRight = UDim.new(0, 6) boxPad.PaddingLeft = UDim.new(0, 6) end)
    box.FocusLost:Connect(function() box.BackgroundTransparency = 1 boxPad.PaddingRight = UDim.new(0, 0) boxPad.PaddingLeft = UDim.new(0, 0) end)
    Theme.bind(box, "TextColor3", "text")
    Theme.bind(box, "BackgroundColor3", "base")
    corner(box, 6)
    local sideIcons = type(cfg.Icons) == "table" and cfg.Icons or nil
    local inset = sideIcons and 20 or 0
    local track = create("Frame", { Name = "Track", Position = UDim2.new(0, inset, 0, top + 8), Size = UDim2.new(1, -inset * 2, 0, 2), BorderSizePixel = 0, Parent = row })
    Theme.bind(track, "BackgroundColor3", "buttonEdge")
    corner(track, 1)
    local fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = track })
    Theme.bind(fill, "BackgroundColor3", "accent")
    corner(fill, 1)
    local knob = create("Frame", { Name = "Knob", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(10, 10), BorderSizePixel = 0, ZIndex = 2, Parent = track })
    Theme.bind(knob, "BackgroundColor3", "accent")
    corner(knob, 5)
    local hit = create("TextButton", { Name = "Hit", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.new(0, inset - 6, 0, top), Size = UDim2.new(1, 12 - inset * 2, 0, 18), ZIndex = 3, Parent = row })
    -- value bubble over the knob while dragging
    local bubble = create("TextLabel", {
        Name = "Bubble", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -6), Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X,
        BorderSizePixel = 0, Text = "", TextSize = 9, Font = Enum.Font.GothamMedium, Visible = false, ZIndex = 6, Parent = knob,
    })
    Theme.bind(bubble, "BackgroundColor3", "selected")
    Theme.bind(bubble, "TextColor3", "heading")
    corner(bubble, 5)
    Util.padding(bubble, 7, 7, 0, 0)
    Theme.bind(Util.stroke(bubble), "Color", "buttonEdge")

    local element = Base.element(card, "Slider", cfg, row, title, desc)
    local focused = false

    local function format(value)
        return (decimals > 0 and string.format("%." .. decimals .. "f", value) or tostring(math.floor(value + 0.5))) .. suffix
    end
    local function render()
        local ratio = max > min and (element.Value - min) / (max - min) or 0
        fill.Size = UDim2.new(ratio, 5 - 10 * ratio, 1, 0)
        knob.Position = UDim2.new(ratio, 5 - 10 * ratio, 0.5, 0)
        if not focused then box.Text = format(element.Value) end
        bubble.Text = format(element.Value)
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
        local inset = 5 * (window.scale and window.scale.Scale or 1)
        element:Set(min + math.clamp((point.X - track.AbsolutePosition.X - inset) / math.max(1, width - inset * 2), 0, 1) * (max - min))
    end
    hit.InputBegan:Connect(function(input)
        if not Util.isPress(input) or element.Locked then return end
        bubble.Visible = cfg.Bubble ~= false
        fromPoint(Util.pointer(input))
        window:_beginDrag(input, fromPoint, function() bubble.Visible = false end)
    end)
    if sideIcons then
        -- icons at both ends; a click moves one step (or a tenth of the range) that way
        local stride = step > 0 and math.max(step, (max - min) / 10) or (max - min) / 10
        for index, key in ipairs({ "From", "To" }) do
            local name = sideIcons[key] or sideIcons[index]
            local icon = name and Icons.themed(row, name, 13, "muted", {
                Name = key .. "Icon", AnchorPoint = Vector2.new(index == 1 and 0 or 1, 0.5), Position = UDim2.new(index == 1 and 0 or 1, 0, 0, top + 9),
            })
            if icon then
                local click = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 6, 1, 6), Position = UDim2.fromOffset(-3, -3), ZIndex = 4, Parent = icon })
                click.Activated:Connect(function()
                    if element.Locked then return end
                    element:Set(element.Value + (index == 1 and -stride or stride))
                end)
                click.MouseEnter:Connect(function() Theme.tweenTo(icon, "ImageColor3", "heading", 0.1) end)
                click.MouseLeave:Connect(function() Theme.tweenTo(icon, "ImageColor3", "muted", 0.1) end)
            end
        end
    end
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
