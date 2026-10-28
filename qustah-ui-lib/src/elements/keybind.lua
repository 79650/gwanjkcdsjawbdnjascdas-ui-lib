-- card:Keybind({ Title, Desc, Flag, Default = Enum.KeyCode.X, Callback = function(key) end, Pressed = function() end })
-- Click the badge, then press a key (Backspace clears, Escape cancels). Callback runs when the key changes,
-- Pressed runs every time the key is pressed (outside text boxes).
-- Chord = true: a modifier plus a key or mouse button, e.g. CTRL + M1 (press the modifier first, then the key);
-- Default = { Enum.KeyCode.LeftControl, Enum.UserInputType.MouseButton1 }. Value is then { modifier, key }.
-- Mode = "Hold": Pressed(true) when the key goes down and Pressed(false) when it is let go; element.Held.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local window = card.window
    local chordMode = cfg.Chord == true
    local row, title, desc = Base.row(card, cfg, cfg.Desc and 40 or 30, { right = chordMode and 130 or 100 })
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
    element._keyLabel, element._keyStroke = badge, outline -- (yellow on a key conflict)
    local function show(text)
        badge.Text = text
        local width = math.max(48, Util.textWidth(text, 10, Enum.Font.GothamMedium) + 18)
        badge.Size = UDim2.fromOffset(width, 22)
        -- title / description use the room the badge leaves
        local reserve = math.max(width, 60) + 12
        if cfg.Help then reserve = (chordMode and 130 or 100) + 16 end
        title.Size = UDim2.new(1, -reserve, 0, title.Size.Y.Offset)
        if desc then desc.Size = UDim2.new(1, -reserve, 0, desc.Size.Y.Offset) end
    end
    local function chordName(chord)
        if not chord or not chord[2] then return "None" end
        return (chord[1] and (Util.keyName(chord[1]) .. " + ") or "") .. Util.keyName(chord[2])
    end

    function element:Set(key, silent)
        if chordMode then
            -- accepts { modifier, key }, a single key, or a saved "LeftControl+MouseButton1"
            if type(key) == "string" then
                local first, second = key:match("^([^+]+)%+(.+)$")
                key = first and { Util.toKey(first), Util.toKey(second) } or { nil, Util.toKey(key) }
            elseif typeof(key) == "EnumItem" then
                key = { nil, key }
            elseif type(key) == "table" then
                key = { Util.toKey(key[1]), Util.toKey(key[2]) }
                if not key[2] and key[1] then key = { nil, key[1] } end
            else
                key = nil
            end
            if key and not key[2] then key = nil end
            local changed = chordName(key) ~= chordName(self.Value)
            self.Value, self.Chord = key, key
            window:_bind(self, key and key[2] or nil)
            show(chordName(key))
            Theme.tweenTo(outline, "Color", "buttonEdge", 0.1)
            self._failed = false
            self:_fire(key, silent or not changed)
            if changed and not silent then self:_accepted("accent") end
            return
        end
        key = Util.toKey(key)
        local changed = key ~= self.Value
        self.Value = key
        window:_bind(self, key)
        show(Util.keyName(key))
        Theme.tweenTo(outline, "Color", "buttonEdge", 0.1)
        self._failed = false
        if changed then self:_fire(key, silent) else self:_fire(key, true) end
        if changed and not silent then self:_accepted("accent") end
    end
    function element:Get() return self.Value end
    element.Mode = cfg.Mode == "Hold" and "Hold" or "Press"
    element.Held = false
    function element:_onBind()
        if self.Locked then return end
        if self.Mode == "Hold" then
            if self.Held then return end
            self.Held = true
            self:_call(cfg.Pressed, true)
        else
            self:_call(cfg.Pressed, self.Value)
        end
    end
    function element:_onRelease()
        if self.Mode == "Hold" and self.Held then
            self.Held = false
            self:_call(cfg.Pressed, false)
        end
    end
    function element:_save()
        if chordMode then
            local chord = self.Value
            if not chord then return "None" end
            return (chord[1] and (chord[1].Name .. "+") or "") .. chord[2].Name
        end
        return self.Value and self.Value.Name or "None"
    end

    badge.Activated:Connect(function()
        if element.Locked then return end
        show("...")
        Theme.tweenTo(outline, "Color", "accent", 0.1)
        local modifier
        local function capture(key)
            window._captureMouse = nil
            if key == Enum.KeyCode.Escape then element:Set(element.Value, true) return end
            if key == Enum.KeyCode.Backspace then element:Set(nil) return end
            if chordMode then
                if not modifier and Util.isModifier(key) then
                    -- wait for the main key / mouse button
                    modifier = key
                    show(Util.keyName(key) .. " + ...")
                    window._captureMouse = true
                    window._capture = capture
                    return
                end
                element:Set({ modifier, key })
                return
            end
            if key == window.key then element:Set(element.Value, true) return end -- the menu key stays the menu key
            element:Set(key)
        end
        window._capture = capture
    end)

    element:Set(cfg.Default, true)
    return Base.finish(element, cfg)
end
