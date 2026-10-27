-- card:Radio({ Title, Flag, Options = { "Closest", "Lowest HP", { Title = "Random", Desc = "Any target" } }, Default, Callback, Locked })
-- One choice from a short list, every option visible with a round marker. Value is the chosen option's text
-- (or its Value, when an option is { Value = "hp", Title = "Lowest HP" }). :SetOptions(list).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

local function normalize(list)
    local out = {}
    for _, option in ipairs(list or {}) do
        if type(option) == "table" then
            local text = tostring(option.Title or option.Value or "")
            out[#out + 1] = { value = option.Value ~= nil and option.Value or text, title = text, desc = option.Desc, locked = option.Locked == true }
        else
            out[#out + 1] = { value = option, title = tostring(option) }
        end
    end
    return out
end

return function(card, cfg)
    local holder = create("Frame", { Name = tostring(cfg.Title or "Radio"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = card:_order(), Parent = card.body })
    Util.list(holder, 2)
    local title
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 0 })
        Theme.bind(title, "TextColor3", cfg.Risky and "danger" or "text")
    end
    local list = create("Frame", { Name = "Options", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = holder })
    Util.list(list, 2)

    local element = Base.element(card, "Radio", cfg, holder, title, nil)
    local options, rows = {}, {}
    local function render(animate)
        local duration = animate and 0.12 or nil
        for _, entry in ipairs(rows) do
            local on = entry.option.value == element.Value
            Theme.tweenTo(entry.ring, "Color", on and "accent" or "buttonEdge", duration)
            entry.dot.Visible = on
            Theme.tweenTo(entry.text, "TextColor3", entry.option.locked and "muted" or (on and "heading" or "text"), duration)
        end
    end
    local function build()
        for _, entry in ipairs(rows) do entry.button:Destroy() end
        rows = {}
        for index, option in ipairs(options) do
            local height = option.desc and 36 or 26
            local button = create("TextButton", { Name = tostring(option.title), Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height), LayoutOrder = index, Parent = list })
            local circle = create("Frame", { Name = "Circle", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 1, 0, option.desc and 12 or height / 2), Size = UDim2.fromOffset(14, 14), BorderSizePixel = 0, Parent = button })
            corner(circle, 7)
            Theme.bind(circle, "BackgroundColor3", "input")
            local ring = stroke(circle)
            local dot = create("Frame", { Name = "Dot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, Visible = false, Parent = circle })
            corner(dot, 3)
            Theme.bind(dot, "BackgroundColor3", "accent")
            local text = label(button, option.title, 10, { Name = "Text", Position = UDim2.fromOffset(24, option.desc and 3 or 0), Size = UDim2.new(1, -24, 0, option.desc and 18 or height) })
            if option.desc then
                local sub = label(button, tostring(option.desc), 9, { Name = "Desc", Position = UDim2.fromOffset(24, 20), Size = UDim2.new(1, -24, 0, 13) })
                Theme.bind(sub, "TextColor3", "muted")
            end
            button.Activated:Connect(function()
                if element.Locked or option.locked then return end
                element:Set(option.value)
            end)
            button.MouseEnter:Connect(function() if option.value ~= element.Value and not option.locked then Theme.tweenTo(text, "TextColor3", "heading", 0.1) end end)
            button.MouseLeave:Connect(function() render(true) end)
            rows[index] = { option = option, button = button, ring = ring, dot = dot, text = text }
        end
        render(false)
    end
    local function has(value)
        for _, option in ipairs(options) do if option.value == value then return true end end
        return false
    end
    function element:Set(value, silent)
        if not has(value) then -- also accept an option's title
            for _, option in ipairs(options) do if option.title == value then value = option.value break end end
        end
        if not has(value) then return end
        local changed = value ~= self.Value
        self.Value = value
        render(true)
        self:_fire(value, silent or not changed)
    end
    function element:Get() return self.Value end
    function element:SetOptions(list)
        options = normalize(list)
        build()
        if not has(self.Value) then self.Value = options[1] and options[1].value or nil self:_fire(self.Value, true) end
    end

    options = normalize(cfg.Options)
    build()
    element.Value = has(cfg.Default) and cfg.Default or (options[1] and options[1].value)
    render(false)
    element:_fire(element.Value, true)
    return Base.finish(element, cfg)
end
