-- card:ListItem({ Title = "Theme", Icon = "palette", Value = "Dark", Callback = function() end })      -- a link row
-- card:ListItem({ Title = "Free mouse", Icon = "mouse-pointer", Toggle = true, Flag = "freeMouse", Default = true })
-- A settings-list row: the icon in a small rounded box, the title, then on the right a muted value with a chevron
-- (the row is a button: Callback) or, with Toggle = true, a switch (a normal saved toggle). Badge = "RISKY": a small
-- tag after the title; Risky = true: the title (and tag) red. Rows put one after the
-- other read as a grouped list (a thin line between them). :SetValue(text); toggles also :Set / :Get.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")
local Parts = require("elements/parts")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local row = create("TextButton", { Name = tostring(cfg.Title or "ListItem"), Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, cfg.Desc and 42 or 36), LayoutOrder = card:_order(), Parent = card.body })
    local line = create("Frame", { Name = "Line", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, cfg.Icon and 32 or 0, 1, 0), Size = UDim2.new(1, cfg.Icon and -32 or 0, 0, 1), BorderSizePixel = 0, Parent = row })
    Theme.bind(line, "BackgroundColor3", "line")
    local x = 0
    if cfg.Icon then
        local box = create("Frame", { Name = "IconBox", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(22, 22), BorderSizePixel = 0, Parent = row })
        Theme.bind(box, "BackgroundColor3", "input")
        corner(box, 6)
        Icons.themed(box, cfg.Icon, 12, cfg.IconColor or "icon", { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
        x = 32
    end
    -- room on the right: a switch needs less than a value + chevron (so a row half a card wide keeps its title)
    local reserve = cfg.Toggle and 44 or 130
    local title = label(row, tostring(cfg.Title or ""), 11, { Name = "Title", Position = UDim2.fromOffset(x, cfg.Desc and 5 or 0), Size = UDim2.new(1, -x - reserve, 0, cfg.Desc and 18 or 36) })
    Theme.bind(title, "TextColor3", cfg.Risky and "danger" or "text")
    if cfg.Badge then
        local tag = Parts.chip(row, tostring(cfg.Badge), cfg.Risky and "danger" or "muted", nil, { Name = "Badge", AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, x + Util.textWidth(tostring(cfg.Title or ""), 11, Enum.Font.Gotham) + 6, 0, cfg.Desc and 14 or 18) })
        tag.Size = UDim2.fromOffset(tag.Size.X.Offset, 15)
        tag:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 4)
    end
    local desc
    if cfg.Desc then
        desc = label(row, tostring(cfg.Desc), 9, { Name = "Desc", Position = UDim2.fromOffset(x, 22), Size = UDim2.new(1, -x - reserve, 0, 13) })
        Theme.bind(desc, "TextColor3", "muted")
    end
    local kind = cfg.Toggle and "Toggle" or "ListItem"
    local element = Base.element(card, kind, cfg, row, title, desc)
    if cfg.Toggle then
        local switch = create("Frame", { Name = "Switch", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(30, 16), BorderSizePixel = 0, Parent = row })
        corner(switch, 8)
        local knob = create("Frame", { Name = "Knob", Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(12, 12), BorderSizePixel = 0, Parent = switch })
        corner(knob, 6)
        Theme.bind(knob, "BackgroundColor3", "knob")
        element.Value = cfg.Default == true
        local function render(animate)
            Theme.tweenTo(switch, "BackgroundColor3", element.Value and "toggleOn" or "buttonEdge", animate and 0.15 or nil)
            Util.tween(knob, animate and 0.15 or 0, { Position = UDim2.fromOffset(element.Value and 16 or 2, 2) })
        end
        function element:Set(on, silent)
            on = on == true
            local changed = on ~= self.Value
            self.Value = on
            render(true)
            self:_fire(on, silent or not changed)
        end
        function element:Get() return self.Value end
        row.Activated:Connect(function() if not element.Locked then element:Set(not element.Value) end end)
        render(false)
        element:_fire(element.Value, true)
    else
        local chevron = Icons.themed(row, "chevron-right", 12, "muted", { Name = "Chevron", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0) })
        local value = label(row, tostring(cfg.Value or ""), 10, { Name = "Value", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, chevron and cfg.Chevron ~= false and -18 or 0, 0.5, 0), Size = UDim2.fromOffset(120, 16), TextXAlignment = Enum.TextXAlignment.Right })
        Theme.bind(value, "TextColor3", "muted")
        if chevron and cfg.Chevron == false then chevron.Visible = false end
        function element:SetValue(text) value.Text = tostring(text) end
        row.Activated:Connect(function() if not element.Locked and cfg.Callback then element:_call(cfg.Callback) end end)
    end
    row.MouseEnter:Connect(function() if not cfg.Risky then Theme.tweenTo(title, "TextColor3", "heading", 0.1) end end)
    row.MouseLeave:Connect(function() if not cfg.Risky then Theme.tweenTo(title, "TextColor3", "text", 0.1) end end)
    return Base.finish(element, cfg)
end
