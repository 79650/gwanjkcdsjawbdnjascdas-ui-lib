-- Mobile reopen button: while the menu is hidden a small pill (logo + title) stays on screen; tap it to open the
-- menu again, drag it anywhere (the spot is remembered). Phones have no RightShift.
--   CreateWindow({ MobileButton = "Auto" | true | false })   "Auto" (default): touch screens without a keyboard
--   Window:SetMobileButton(on)
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")

local create, corner, stroke, label, tween = Util.create, Util.corner, Util.stroke, Util.label, Util.tween

return function(Window)
    function Window:SetMobileButton(on, remember)
        self.mobileButton = on == true
        if remember and self.memory then self.memory.mobileButton = self.mobileButton self:_saveMemory() end
        if self.mobileButton and not self._pill then self:_makePill() end
        self:_showPill()
    end

    function Window:_showPill()
        local pill = self._pill
        if not pill then return end
        local show = self.mobileButton and self.alive and not self.visible
        if show then
            pill.Visible = true
            Util.fade(pill, 0.18, 0)
        else
            Util.fade(pill, 0.12, 1)
            task.delay(0.13, function()
                if pill.Parent and not (self.mobileButton and self.alive and not self.visible) then pill.Visible = false end
            end)
        end
    end

    function Window:_makePill()
        local pill = create("CanvasGroup", {
            Name = "MobileButton", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 40), BorderSizePixel = 0,
            GroupTransparency = 1, Visible = false, ZIndex = 80, Parent = self.gui,
        })
        Theme.bind(pill, "BackgroundColor3", "base")
        corner(pill, 20)
        local edge = stroke(pill, nil, 0.3)
        Theme.bind(edge, "Color", "accentEdge")
        local row = create("Frame", { Name = "Row", BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), Parent = pill })
        Util.list(row, 8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
        Util.padding(row, 12, 16, 0, 0)
        Icons.themed(row, self.cfg.Icon or self.cfg.MobileIcon or "menu", 16, "accent", { Name = "Icon", LayoutOrder = 1 })
        local text = label(row, self.Title, 12, { Name = "Text", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 40), Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2 })
        Theme.bind(text, "TextColor3", "heading")
        create("UISizeConstraint", { MaxSize = Vector2.new(150, 40), Parent = text })
        local hit = create("TextButton", { Name = "Hit", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 81, Parent = pill })
        self._pill = pill

        -- position: a fraction of the free screen space (default: top, a little left of centre - clear of the Roblox top bar)
        local saved = self.memory and self.memory.mobilePill
        local fraction = type(saved) == "table" and Vector2.new(tonumber(saved[1]) or 0.5, tonumber(saved[2]) or 0.1) or Vector2.new(0.5, 0.1)
        local function place()
            local viewport = Util.viewport()
            local room = Vector2.new(math.max(0, viewport.X - pill.AbsoluteSize.X), math.max(0, viewport.Y - pill.AbsoluteSize.Y))
            pill.Position = UDim2.fromOffset(math.floor(fraction.X * room.X), math.floor(fraction.Y * room.Y))
        end
        self.maid:connect(pill:GetPropertyChangedSignal("AbsoluteSize"), place)
        self._placers = self._placers or {}
        table.insert(self._placers, place)
        place()

        -- a tap opens the menu; moving more than a few pixels drags instead
        hit.InputBegan:Connect(function(input)
            if not Util.isPress(input) then return end
            local start = Util.pointer(input)
            local origin = Vector2.new(pill.Position.X.Offset, pill.Position.Y.Offset)
            local dragged = false
            self:_beginDrag(input, function(point)
                local delta = point - start
                if not dragged and delta.Magnitude < 6 then return end
                dragged = true
                local viewport = Util.viewport()
                local room = Vector2.new(math.max(1, viewport.X - pill.AbsoluteSize.X), math.max(1, viewport.Y - pill.AbsoluteSize.Y))
                local target = origin + delta
                fraction = Vector2.new(math.clamp(target.X / room.X, 0, 1), math.clamp(target.Y / room.Y, 0, 1))
                place()
            end, function()
                if dragged then
                    self.memory.mobilePill = { fraction.X, fraction.Y }
                    self:_saveMemory()
                else
                    require("haptics").Play("click")
                    self:SetVisible(true)
                end
            end)
        end)
    end

    local setVisible = Window.SetVisible
    function Window:SetVisible(visible)
        setVisible(self, visible)
        if self._pill then self:_showPill() end
    end

    function Window:_buildMobile()
        local mode = self.cfg.MobileButton
        if mode == nil then mode = "Auto" end
        local saved = self.memory and self.memory.mobileButton -- (the Settings switch on this device wins)
        if saved ~= nil then mode = saved end
        local on = mode == true or (mode == "Auto" and Util.isTouch())
        if on then self:SetMobileButton(true) end
        self.maid:give(function() if self._pill then self._pill:Destroy() end end)
    end
end
