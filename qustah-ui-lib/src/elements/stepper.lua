-- card:Stepper({ Title, Desc, Flag, Min = 0, Max = 10, Step = 1, Default, Suffix, Callback, Locked })
-- [-] value [+]: exact numbers without a slider. Hold a button to repeat (it speeds up); click the value to type.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local min, max = tonumber(cfg.Min) or 0, tonumber(cfg.Max) or 10
    if max < min then min, max = max, min end
    local step = tonumber(cfg.Step) or 1
    if step <= 0 then step = 1 end
    local decimals = Util.decimals(step)
    local suffix = cfg.Suffix and (" " .. tostring(cfg.Suffix)) or ""
    local row, title, desc = Base.row(card, cfg, cfg.Desc and 40 or 30, { right = 106, helpRight = 100 })
    local box = create("Frame", { Name = "Stepper", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(96, 24), BorderSizePixel = 0, Parent = row })
    Theme.bind(box, "BackgroundColor3", "input")
    corner(box, 6)
    Theme.bind(stroke(box), "Color", "buttonEdge")
    local function sideButton(name, icon, side)
        local button = create("TextButton", {
            Name = name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(side, 0.5), Position = UDim2.new(side, 0, 0.5, 0), Size = UDim2.fromOffset(24, 24), Parent = box,
        })
        Theme.bind(button, "BackgroundColor3", "hover")
        corner(button, 6)
        local image = Icons.themed(button, icon, 12, "text", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
        button.MouseEnter:Connect(function() Util.tween(button, 0.1, { BackgroundTransparency = 0 }) if image then Theme.tweenTo(image, "ImageColor3", "heading", 0.1) end end)
        button.MouseLeave:Connect(function() Util.tween(button, 0.1, { BackgroundTransparency = 1 }) if image then Theme.tweenTo(image, "ImageColor3", "text", 0.1) end end)
        return button, image
    end
    local minus = sideButton("Minus", "minus", 0)
    local plus = sideButton("Plus", "plus", 1)
    local value = create("TextBox", {
        Name = "Value", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -48, 1, 0), Text = "", TextSize = 10, Font = Enum.Font.GothamMedium, ClearTextOnFocus = false,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = box,
    })
    Theme.bind(value, "TextColor3", "heading")
    Theme.bind(value, "PlaceholderColor3", "muted")

    local element = Base.element(card, "Stepper", cfg, row, title, desc)
    local focused = false
    local function format(number)
        return (decimals > 0 and string.format("%." .. decimals .. "f", number) or tostring(math.floor(number + 0.5))) .. suffix
    end
    local function render()
        if not focused then value.Text = format(element.Value) end
        -- the ends dim their button
        minus.Active, plus.Active = element.Value > min, element.Value < max
        for _, button in ipairs({ minus, plus }) do
            local icon = button:FindFirstChildWhichIsA("ImageLabel")
            if icon then icon.ImageTransparency = button.Active and 0 or 0.6 end
        end
    end
    function element:Set(number, silent)
        number = tonumber(number)
        if not number or number ~= number then render() return end
        number = math.clamp(Util.round(number - min, step) + min, min, max)
        if decimals > 0 then number = tonumber(string.format("%." .. decimals .. "f", number)) end
        local changed = number ~= self.Value
        self.Value = number
        render()
        self:_fire(number, silent or not changed)
    end
    function element:Get() return self.Value end
    function element:SetRange(newMin, newMax)
        min, max = tonumber(newMin) or min, tonumber(newMax) or max
        self:Set(self.Value)
    end

    -- press and hold: one step, then repeats that get quicker
    local function hold(button, direction)
        local holding = 0
        button.InputBegan:Connect(function(input)
            if not Util.isPress(input) or element.Locked then return end
            holding = holding + 1
            local mine = holding
            element:Set(element.Value + step * direction)
            task.spawn(function()
                task.wait(0.4)
                local delay = 0.12
                while holding == mine and button.Parent and not element.Locked do
                    local before = element.Value
                    element:Set(element.Value + step * direction)
                    if element.Value == before then break end
                    task.wait(delay)
                    delay = math.max(0.03, delay * 0.85)
                end
            end)
        end)
        button.InputEnded:Connect(function(input) if Util.isPress(input) then holding = holding + 1 end end)
        button.MouseLeave:Connect(function() holding = holding + 1 end)
    end
    hold(minus, -1)
    hold(plus, 1)
    value.Focused:Connect(function() focused = true value.Text = format(element.Value):gsub(suffix:gsub("%p", "%%%0") .. "$", "") end)
    value.FocusLost:Connect(function()
        focused = false
        local number = tonumber((value.Text:gsub("[^%d%.%-]", "")))
        if number then element:Set(number) else render() end
        render()
    end)

    element.Value = math.clamp(tonumber(cfg.Default) or min, min, max)
    render()
    element:_fire(element.Value, true)
    return Base.finish(element, cfg)
end
