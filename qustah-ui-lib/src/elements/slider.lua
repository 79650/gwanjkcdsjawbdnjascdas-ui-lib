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
        fill.Size = UDim2.new(ratio, 5 - 10 * ratio, 1, 0)
        knob.Position = UDim2.new(ratio, 5 - 10 * ratio, 0.5, 0)
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
        local inset = 5 * (window.scale and window.scale.Scale or 1)
        element:Set(min + math.clamp((point.X - track.AbsolutePosition.X - inset) / math.max(1, width - inset * 2), 0, 1) * (max - min))
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
