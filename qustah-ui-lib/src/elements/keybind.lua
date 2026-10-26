-- card:Keybind({ Title, Desc, Flag, Default = Enum.KeyCode.X, Callback = function(key) end, Pressed = function() end })
-- Click the badge, then press a key (Backspace clears, Escape cancels). Callback runs when the key changes,
-- Pressed runs every time the key is pressed (outside text boxes).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local window = card.window
    local row, title, desc = Base.row(card, cfg, cfg.Desc and 40 or 30, { right = 100 })
    local badge = create("TextButton", {
        Name = "Key", AutoButtonColor = false, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(48, 22), Text = "", TextSize = 10,
        Font = Enum.Font.GothamMedium, Parent = row,
    })
    Theme.bind(badge, "BackgroundColor3", "input")
    Theme.bind(badge, "TextColor3", "heading")
    corner(badge, 6)
    local outline = stroke(badge)
    Theme.bind(outline, "Color", "buttonEdge")

    local element = Base.element(card, "Keybind", cfg, row, title, desc)
    local function show(text)
        badge.Text = text
        badge.Size = UDim2.fromOffset(math.max(48, Util.textWidth(text, 10, Enum.Font.GothamMedium) + 18), 22)
    end

    function element:Set(key, silent)
        key = Util.toKey(key)
        local changed = key ~= self.Value
        self.Value = key
        window:_bind(self, key)
        show(Util.keyName(key))
        Theme.tweenTo(outline, "Color", "buttonEdge", 0.1)
        if changed then self:_fire(key, silent) else self:_fire(key, true) end
    end
    function element:Get() return self.Value end
    function element:_onBind() Util.safe(cfg.Pressed, self.Value) end
    function element:_save() return self.Value and self.Value.Name or "None" end

    badge.Activated:Connect(function()
        if element.Locked then return end
        show("...")
        Theme.tweenTo(outline, "Color", "accent", 0.1)
        window._capture = function(key)
            if key == Enum.KeyCode.Escape then element:Set(element.Value, true)
            elseif key == Enum.KeyCode.Backspace then element:Set(nil)
            elseif key == window.key then element:Set(element.Value, true) -- the menu key stays the menu key
            else element:Set(key) end
        end
    end)

    element:Set(cfg.Default, true)
    return Base.finish(element, cfg)
end
