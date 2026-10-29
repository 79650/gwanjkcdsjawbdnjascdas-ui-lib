-- card:Toggle({ Title, Desc, Flag, Default, Callback, Bindable, Bind, BindMode = "Toggle" | "Hold", Locked, LockedTitle })
-- BindMode = "Hold": the toggle is on only while its key is held (aim while holding the key). :SetBindMode(mode)
-- Click the row or the switch to flip it. With Bindable (or a Bind key) right-click the row to assign a key
-- (Backspace clears, Escape cancels); the key flips the toggle while the menu is closed too.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner = Util.create, Util.corner

return function(card, cfg)
    local window = card.window
    local bindable = cfg.Bindable or cfg.Bind ~= nil
    local row, title, desc = Base.row(card, cfg, cfg.Desc and 46 or 36, { button = true, right = 50, helpRight = 44 })
    local switch = create("TextButton", {
        Name = "Switch", Text = "", AutoButtonColor = false, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(34, 18), Parent = row,
    })
    corner(switch, 9)
    local rim = Util.stroke(switch, nil, 0.18)
    local knob = create("Frame", { Name = "Knob", Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(14, 14), BorderSizePixel = 0, Parent = switch })
    corner(knob, 7)

    -- Marker = true: accent bar on the left (a featured setting); Badge = "ANTI BB": small tag after the title
    if cfg.Marker then
        local marker = create("Frame", { Name = "Marker", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 24), BorderSizePixel = 0, BackgroundTransparency = 0.15, Parent = row })
        Theme.bind(marker, "BackgroundColor3", "accent")
        corner(marker, 2)
        -- (an Icon already moved the title: the marker sits before both)
        local icon = row:FindFirstChild("RowIcon")
        if icon then icon.Position = UDim2.new(0, 12, icon.Position.Y.Scale, icon.Position.Y.Offset) end
        title.Position = UDim2.new(0, title.Position.X.Offset + 12, 0, title.Position.Y.Offset)
        if desc then desc.Position = UDim2.fromOffset(desc.Position.X.Offset + 12, desc.Position.Y.Offset) end
    end
    if cfg.Badge then
        local text = tostring(cfg.Badge)
        local width = Util.textWidth(text, 9, Enum.Font.GothamMedium) + 16
        local titleWidth = Util.textWidth(tostring(cfg.Title or ""), 11, Enum.Font.Gotham)
        local badge = create("Frame", {
            Name = "Badge", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, title.Position.X.Offset + titleWidth + 10, 0, title.Position.Y.Offset + title.Size.Y.Offset / 2),
            Size = UDim2.fromOffset(width, 18), BorderSizePixel = 0, Parent = row,
        })
        Theme.bind(badge, "BackgroundColor3", "input")
        corner(badge, 6)
        Theme.bind(Util.stroke(badge, nil, 0.45), "Color", "buttonEdge")
        local badgeText = Util.label(badge, text, 9, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamMedium })
        Theme.bind(badgeText, "TextColor3", "muted")
    end

    local element = Base.element(card, "Toggle", cfg, row, title, desc)
    element.Value = cfg.Default == true

    local function render(animate)
        local on = element.Value
        local duration = animate and 0.15 or nil
        -- Qustah switch: on = input tinted with the accent, knob always light grey, accent rim when on
        Theme.tweenTo(switch, "BackgroundColor3", on and "toggleOn" or "buttonEdge", duration)
        Theme.bind(knob, "BackgroundColor3", "knob")
        Theme.tweenTo(rim, "Color", on and "accent" or "line", duration)
        rim.Transparency = on and 0.6 or 0.18
        local position = UDim2.fromOffset(on and 18 or 2, 2)
        if animate then Util.tween(knob, 0.15, { Position = position }) else knob.Position = position end
    end

    function element:Set(value, silent)
        value = value == true
        local changed = value ~= self.Value
        self.Value = value
        render(true)
        if changed then self:_fire(value, silent) else self:_fire(value, true) end
    end
    function element:Get() return self.Value end

    ------------------------------------------------------------ key bind
    local tag
    function element:SetBind(key)
        key = Util.toKey(key)
        self.BindKey = key
        window:_bind(self, key)
        if tag then
            tag.Text = key and Util.keyName(key) or ""
            tag.Visible = key ~= nil
            -- make room for the key tag only while a key is bound
            local reserve = (key and 100 or 50) + (cfg.Help and 16 or 0)
            title.Size = UDim2.new(1, -reserve, 0, title.Size.Y.Offset)
            if desc then desc.Size = UDim2.new(1, -reserve, 0, 14) end
        end
    end
    element.BindMode = cfg.BindMode == "Hold" and "Hold" or "Toggle"
    function element:SetBindMode(mode) self.BindMode = mode == "Hold" and "Hold" or "Toggle" end
    function element:_onBind()
        if self.Locked then return end
        if self.BindMode == "Hold" then self._held = true self:Set(true) else self:Set(not self.Value) end
    end
    function element:_onRelease()
        if self.BindMode == "Hold" and self._held then self._held = false self:Set(false) end
    end
    if bindable then
        -- the bound key: a small key cap left of the switch (same look as the Keybind element, smaller)
        tag = Util.label(row, "", 9, {
            Name = "Bind", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, cfg.Help and -64 or -44, 0.5, 0), Size = UDim2.fromOffset(0, 16),
            AutomaticSize = Enum.AutomaticSize.X, TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamMedium, Visible = false,
        })
        Util.corner(tag, 4)
        Util.create("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), Parent = tag })
        local tagEdge = Util.stroke(tag)
        Theme.bind(tagEdge, "Color", "buttonEdge")
        Theme.bind(tag, "TextColor3", "muted")
        element._keyLabel, element._keyStroke = tag, tagEdge
        row.MouseButton2Click:Connect(function()
            if element.Locked then return end
            tag.Text, tag.Visible = "...", true
            title.Size = UDim2.new(1, -(100 + (cfg.Help and 16 or 0)), 0, title.Size.Y.Offset)
            window._capture = function(key)
                if key == Enum.KeyCode.Escape or key == window.key then element:SetBind(element.BindKey) -- (the menu key stays the menu key)
                elseif key == Enum.KeyCode.Backspace then element:SetBind(nil)
                else element:SetBind(key) end
            end
        end)
        element:SetBind(cfg.Bind)
        function element:_save() return { Value = self.Value, Bind = self.BindKey and self.BindKey.Name or nil } end
        function element:_load(data)
            if type(data) == "table" then self:SetBind(data.Bind) self:Set(data.Value) else self:Set(data) end
        end
    end

    local function flip() if not element.Locked then element:Set(not element.Value) end end
    row.Activated:Connect(flip)
    switch.Activated:Connect(flip)
    row.MouseEnter:Connect(function() Theme.tweenTo(title, "TextColor3", cfg.Risky and "danger" or "heading", 0.12) end)
    row.MouseLeave:Connect(function() Theme.tweenTo(title, "TextColor3", cfg.Risky and "danger" or "text", 0.12) end)

    render(false)
    element:_fire(element.Value, true)
    return Base.finish(element, cfg)
end
