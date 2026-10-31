-- Window extras:
--   Window:HeaderButton({ Icon = "refresh-cw", Tooltip = "Rejoin", Callback })   your own buttons in the header
--   Window:SetFullscreen(bool) / :ToggleFullscreen()   also the maximize button and a double click on the header
--   Window:SetBackgroundImage(image, transparency)      rbxassetid / url / nil; :SetBackgroundTransparency(0-0.9)
--   Window:SetAnonymous(bool)                           hides your name / avatar everywhere (dock profile button)
-- CreateWindow({ FullscreenButton = true, Profile = false, Anonymous = true, Background = "...", BackgroundTransparency })
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")

local create, corner, stroke = Util.create, Util.corner, Util.stroke
local SLOT = 34

return function(Window)
    -- Next free spot left of the header buttons; the location / header tabs move along.
    function Window:_headerSlot()
        self._slotX = (self._slotX or -74) - SLOT
        self.headerRight = -self._slotX + 16
        if self.locationLabel then self.locationLabel.Position = UDim2.new(1, -self.headerRight, 0, 12) end
        if self.headerTabs then self.headerTabs.Position = UDim2.new(1, -self.headerRight, 0, 0) end
        return self._slotX
    end

    function Window:HeaderButton(cfg)
        cfg = cfg or {}
        local button = self._windowButton(tostring(cfg.Name or cfg.Tooltip or cfg.Icon or "Button"), self:_headerSlot(), false, true)
        local icon = Icons.themed(button, cfg.Icon or "circle", 15, "muted", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
        button.MouseEnter:Connect(function()
            if icon then Theme.tweenTo(icon, "ImageColor3", "heading", 0.12) end
            if cfg.Tooltip then self:_tip(cfg.Tooltip) end
        end)
        button.MouseLeave:Connect(function()
            if icon then Theme.tweenTo(icon, "ImageColor3", "muted", 0.12) end
            self:_hideTip()
        end)
        button.Activated:Connect(function() self:_safe(cfg.Tooltip or "Header button", cfg.Callback) end)
        local handle = { Button = button, Icon = icon }
        function handle:SetIcon(name) if icon then Icons.Apply(icon, name) end end
        function handle:SetVisible(visible) button.Visible = visible ~= false end
        return handle
    end

    ------------------------------------------------------------------ fullscreen
    function Window:SetFullscreen(on)
        on = on == true
        if on == (self.fullscreen == true) then return end
        if on then
            self._restore = { width = self.width, height = self.height, topLeft = self.topLeft }
            local viewport = Util.viewport()
            self.width = math.max(self.minSize.X, math.floor(viewport.X - 24 - 12 - 40 - 24))
            self.height = math.max(self.minSize.Y, math.floor(viewport.Y - 24))
            self.topLeft = Vector2.new(12, 12)
        elseif self._restore then
            self.width, self.height, self.topLeft = self._restore.width, self._restore.height, self._restore.topLeft
            self._restore = nil
        end
        self.fullscreen = on
        if self._fullscreenButton then self._fullscreenButton:SetIcon(on and "minimize-2" or "maximize-2") end
        self:_layout()
    end
    function Window:ToggleFullscreen() self:SetFullscreen(not self.fullscreen) end

    ------------------------------------------------------------------ background
    function Window:SetBackgroundImage(image, transparency)
        if not self._background then
            self._background = create("ImageLabel", {
                Name = "Background", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Crop,
                ImageTransparency = 0.85, ZIndex = 0, Parent = self.main,
            })
            corner(self._background, 12)
        end
        local picture = self._background
        picture.Image = ""
        if image == nil or image == "" then picture.Visible = false return end
        picture.Visible = true
        if tonumber(transparency) then picture.ImageTransparency = math.clamp(tonumber(transparency), 0, 1) end
        if not Icons.Apply(picture, image) then picture.Image = tostring(image) end
        picture.ImageColor3 = Color3.new(1, 1, 1)
    end
    function Window:SetBackgroundTransparency(value)
        value = math.clamp(tonumber(value) or 0, 0, 0.9)
        self.main.BackgroundTransparency = value
        self.dock.BackgroundTransparency = math.max(0.03, value)
    end

    ------------------------------------------------------------------ profile button in the dock + anonymous mode
    function Window:SetAnonymous(on)
        self.anonymous = on == true
        for _, listener in ipairs(self._anonListeners or {}) do Util.safe(listener, self.anonymous) end
    end
    function Window:OnAnonymousChanged(callback)
        self._anonListeners = self._anonListeners or {}
        table.insert(self._anonListeners, callback)
        callback(self.anonymous == true)
    end

    local layoutDock = Window._layoutDock
    function Window:_layoutDock()
        layoutDock(self)
        if self._profile and self._profile.Visible then
            local y = self.dockHeight - 2
            self._profileLine.Position = UDim2.fromOffset(9, y)
            self._profile.Position = UDim2.fromOffset(5, y + 7)
            self.dockHeight = y + 7 + 30 + 8
        end
    end

    ------------------------------------------------------------------ mouse unlock
    -- While the menu is open the mouse is free (shift lock / first person would keep it locked in the centre):
    -- a Modal button releases it and the cursor is shown. UnlockMouse = false turns it off; Window:SetMouseUnlock(bool).
    function Window:SetMouseUnlock(on)
        self.unlockMouse = on ~= false
        self:_applyMouse()
    end
    function Window:_applyMouse()
        local UserInputService = Util.Services.UserInputService
        local free = self.alive and self.visible and self.unlockMouse
        if self._modal then self._modal.Modal = free == true end
        if free then
            if self._savedMouseIcon == nil then self._savedMouseIcon = UserInputService.MouseIconEnabled end
            UserInputService.MouseIconEnabled = true
        elseif self._savedMouseIcon ~= nil then
            UserInputService.MouseIconEnabled = self._savedMouseIcon
            self._savedMouseIcon = nil
        end
    end
    local setVisible = Window.SetVisible
    function Window:SetVisible(visible)
        setVisible(self, visible)
        self:_applyMouse()
    end

    function Window:_buildExtras()
        local cfg = self.cfg
        self._modal = create("TextButton", { Name = "MouseUnlock", Text = "", BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0), Modal = false, Parent = self.main })
        self.unlockMouse = cfg.UnlockMouse ~= false
        self.maid:give(function() self.visible = false self:_applyMouse() end)
        self:_applyMouse()
        if cfg.FullscreenButton == true then
            self._fullscreenButton = self:HeaderButton({ Name = "Fullscreen", Icon = "maximize-2", Tooltip = "Fullscreen", Callback = function() self:ToggleFullscreen() end })
        end
        -- double click on the header toggles fullscreen too
        local header = self.main:FindFirstChild("Header")
        local lastClick = 0
        if header then
            self.maid:connect(header.InputBegan, function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                local now = os.clock()
                if now - lastClick < 0.3 then lastClick = 0 self:ToggleFullscreen() else lastClick = now end
            end)
        end
        if cfg.Background then self:SetBackgroundImage(cfg.Background, cfg.BackgroundImageTransparency) end
        if cfg.BackgroundTransparency then self:SetBackgroundTransparency(cfg.BackgroundTransparency) end

        if cfg.Profile ~= false then
            local Players = Util.Services.Players
            local player = Players.LocalPlayer
            local line = create("Frame", { Name = "ProfileLine", Size = UDim2.fromOffset(22, 1), BorderSizePixel = 0, ZIndex = 42, Parent = self.dock })
            Theme.bind(line, "BackgroundColor3", "line")
            local button = create("ImageButton", {
                Name = "Profile", AutoButtonColor = false, BorderSizePixel = 0, Size = UDim2.fromOffset(30, 30), ZIndex = 42,
                ScaleType = Enum.ScaleType.Crop, Image = "", Parent = self.dock,
            })
            Theme.bind(button, "BackgroundColor3", "input")
            corner(button, 15)
            local ring = stroke(button, nil, 0.5, 1.5)
            Theme.bind(ring, "Color", "buttonEdge")
            local mask = Icons.themed(button, "hat-glasses", 14, "muted", { Name = "Anon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 43, Visible = false })
            -- rbxthumb content: no web request (also fine in secure mode)
            local avatar = Util.avatar(player.UserId)
            button.Image = avatar
            self._profile, self._profileLine = button, line
            self:OnAnonymousChanged(function(on)
                button.Image = on and "" or avatar
                if mask then mask.Visible = on end
                Theme.tweenTo(ring, "Color", on and "accent" or "buttonEdge", 0.12)
            end)
            button.MouseEnter:Connect(function()
                self:_dockTip(self.anonymous and "Anonymous · click to show" or (player.DisplayName .. " · click to hide"), button.Position.Y.Offset)
            end)
            button.MouseLeave:Connect(function() self:_hideTip() end)
            button.Activated:Connect(function() self:SetAnonymous(not self.anonymous) end)
            self:_layoutDock()
            self:_layout()
        end
        if cfg.Anonymous then self:SetAnonymous(true) end
    end
end
