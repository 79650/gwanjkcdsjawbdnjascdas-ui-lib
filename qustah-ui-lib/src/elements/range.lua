-- card:Range({ Title, Desc, Flag, Min, Max, Default = { 20, 80 }, Step, Suffix, MinGap, Callback = function(range) end })
-- A slider with two handles; Value is { low, high }. Dragging moves the nearer handle; the values can be typed.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner = Util.create, Util.corner

return function(card, cfg)
    local window = card.window
    local min, max = tonumber(cfg.Min) or 0, tonumber(cfg.Max) or 100
    if max < min then min, max = max, min end
    local step = tonumber(cfg.Step) or 1
    local gap = math.max(0, tonumber(cfg.MinGap) or 0)
    local suffix = cfg.Suffix and (" " .. tostring(cfg.Suffix)) or ""
    local decimals = Util.decimals(step)
    local top = cfg.Desc and 38 or 22
    local row, title, desc = Base.row(card, cfg, top + 18, { right = 150, titleHeight = 22, helpRight = 146, helpY = 11 })

    -- "low – high suffix": two small boxes
    local boxes = create("Frame", { Name = "Values", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 1), Size = UDim2.fromOffset(150, 20), Parent = row })
    local function box(name, x, align)
        local object = create("TextBox", {
            Name = name, Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(52, 20), BackgroundTransparency = 1, BorderSizePixel = 0,
            Text = "", TextSize = 10, Font = Enum.Font.GothamMedium, ClearTextOnFocus = false, TextXAlignment = align, Parent = boxes,
        })

        Theme.bind(object, "BackgroundColor3", "base")
        Theme.bind(object, "TextColor3", "text")
        corner(object, 6)
        return object
    end
    local lowBox, highBox = box("Low", 0, Enum.TextXAlignment.Right), box("High", 64, Enum.TextXAlignment.Right)
    local dash = Util.label(boxes, "–", 10, { Name = "Dash", Position = UDim2.fromOffset(52, 0), Size = UDim2.fromOffset(14, 20), TextXAlignment = Enum.TextXAlignment.Center })
    Theme.bind(dash, "TextColor3", "muted")

    if desc then desc.Size = UDim2.new(1, 0, 0, 14) end -- the values sit on the title line only
    local track = create("Frame", { Name = "Track", Position = UDim2.new(0, 0, 0, top + 8), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, Parent = row })
    Theme.bind(track, "BackgroundColor3", "buttonEdge")
    corner(track, 1)
    local fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = track })
    Theme.bind(fill, "BackgroundColor3", "accent")
    local function knob(name)
        local object = create("Frame", { Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(10, 10), BorderSizePixel = 0, ZIndex = 2, Parent = track })
        Theme.bind(object, "BackgroundColor3", "accent")
        corner(object, 5)
        return object
    end
    local lowKnob, highKnob = knob("LowKnob"), knob("HighKnob")
    local reach = Util.isTouch() and 8 or 0 -- (taller on touch screens)
    local hit = create("TextButton", { Name = "Hit", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.new(0, -6, 0, top - reach), Size = UDim2.new(1, 12, 0, 18 + reach * 2), ZIndex = 3, Parent = row })

    local element = Base.element(card, "Range", cfg, row, title, desc)
    local focused = {}
    local function format(value)
        return decimals > 0 and string.format("%." .. decimals .. "f", value) or tostring(math.floor(value + 0.5))
    end
    local function snap(value)
        value = math.clamp(Util.round(value - min, step) + min, min, max)
        if decimals > 0 then value = tonumber(string.format("%." .. decimals .. "f", value)) end
        return value
    end
    local function ratio(value) return max > min and (value - min) / (max - min) or 0 end
    local function render()
        local low, high = element.Value[1], element.Value[2]
        local a, b = ratio(low), ratio(high)
        lowKnob.Position = UDim2.new(a, 5 - 10 * a, 0.5, 0)
        highKnob.Position = UDim2.new(b, 5 - 10 * b, 0.5, 0)
        fill.Position = UDim2.new(a, 5 - 10 * a, 0, 0)
        fill.Size = UDim2.new(b - a, -10 * (b - a), 1, 0)
        if not focused.low then lowBox.Text = format(low) .. suffix end
        if not focused.high then highBox.Text = format(high) .. suffix end
        -- "low – high" packed against the right edge (boxes as wide as their text)
        local function width(object) return math.max(18, Util.textWidth(object.Text, 10, Enum.Font.GothamMedium) + (focused[object == lowBox and "low" or "high"] and 14 or 2)) end
        local highWidth, lowWidth = width(highBox), width(lowBox)
        highBox.Position, highBox.Size = UDim2.new(1, -highWidth, 0, 0), UDim2.fromOffset(highWidth, 20)
        dash.Position = UDim2.new(1, -highWidth - 14, 0, 0)
        lowBox.Position, lowBox.Size = UDim2.new(1, -highWidth - 14 - lowWidth, 0, 0), UDim2.fromOffset(lowWidth, 20)
        if not cfg.Help then title.Size = UDim2.new(1, -(highWidth + 14 + lowWidth + 10), 0, title.Size.Y.Offset) end
    end
    function element:Set(value, silent)
        if type(value) ~= "table" then return end
        local low, high = tonumber(value[1]) or min, tonumber(value[2]) or max
        if low > high then low, high = high, low end
        low, high = snap(low), snap(high)
        if high - low < gap then
            if low + gap <= max then high = snap(low + gap) else low = snap(high - gap) end
        end
        local old = self.Value
        self.Value = { low, high }
        render()
        self:_fire(self.Value, silent or (old and old[1] == low and old[2] == high))
    end
    function element:Get() return self.Value[1], self.Value[2] end

    local dragging
    local function fromPoint(point)
        local width = track.AbsoluteSize.X
        if width <= 0 then return end
        local inset = 5 * (window.scale and window.scale.Scale or 1)
        local value = min + math.clamp((point.X - track.AbsolutePosition.X - inset) / math.max(1, width - inset * 2), 0, 1) * (max - min)
        if not dragging then
            -- grab the nearer handle (the high one when both sit on the same spot at the top end)
            local low, high = element.Value[1], element.Value[2]
            dragging = (math.abs(value - low) < math.abs(value - high) or (low == high and value < low)) and 1 or 2
        end
        local next = { element.Value[1], element.Value[2] }
        next[dragging] = value
        if dragging == 1 then next[1] = math.min(value, element.Value[2] - gap) else next[2] = math.max(value, element.Value[1] + gap) end
        element:Set(next)
    end
    hit.InputBegan:Connect(function(input)
        if not Util.isPress(input) or element.Locked then return end
        dragging = nil
        fromPoint(Util.pointer(input))
        window:_beginDrag(input, fromPoint, function() dragging = nil end)
    end)
    for key, object in pairs({ low = lowBox, high = highBox }) do
        object.Focused:Connect(function() focused[key] = true object.BackgroundTransparency = 0.2 render() end)
        object.FocusLost:Connect(function()
            focused[key] = false
            object.BackgroundTransparency = 1
            local number = tonumber((object.Text:gsub("[^%d%.%-]", "")))
            if number then
                local next = { element.Value[1], element.Value[2] }
                next[key == "low" and 1 or 2] = number
                element:Set(next)
            end
            render()
        end)
    end

    local default = type(cfg.Default) == "table" and cfg.Default or { min, max }
    element.Value = { min, max }
    element:Set(default, true)
    return Base.finish(element, cfg)
end
