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
        if self._placePageTabs then self:_placePageTabs() end
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
            -- (room for the dock beside the window; a sidebar is inside it, an under-the-window dock takes height)
            local dockRoom = self.dockSide == "Right" and (12 + 40) or (self.dockSide == "Side" and 132 or 0)
            self.width = math.max(self.minSize.X, math.floor(viewport.X - 24 - dockRoom - 24))
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
        if not self._profile then return end
        local side = self.dockSide == "Side"
        -- sidebar: the profile card pinned to the bottom (it sits on the panel, so the tab list doesn't grow);
        -- dock: the round avatar under a short line, after the last tab
        self._profile.Visible, self._profileLine.Visible = not side, not side
        if self._profileCard then self._profileCard.Visible = side end
        if not side then
            local at = self.dockHeight - 2
            self._profileLine.Size = UDim2.fromOffset(22, 1)
            self:_dockLine(self._profileLine, at)
            self:_dockSpot(self._profile, at + 7, 5)
            self.dockHeight = at + 7 + 30 + 8
        end
    end

    -- Sidebar profile card: avatar with an online dot, the display name, the session time under it and an eye that
    -- switches anonymous mode (the name becomes "Anonymous", the avatar a mask).
    function Window:_profileCardMake(player, avatar)
        local width = self._sideWidth - 16
        local card = create("Frame", {
            Name = "ProfileCard", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.fromOffset(width, 40),
            BorderSizePixel = 0, ZIndex = 42, Visible = false, Parent = self.dock,
        })
        Theme.bind(card, "BackgroundColor3", "input")
        corner(card, 9)
        Theme.bind(stroke(card, nil, 0, 1), "Color", "line")
        local picture = create("ImageLabel", {
            Name = "Avatar", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 7, 0.5, 0), Size = UDim2.fromOffset(26, 26),
            ScaleType = Enum.ScaleType.Crop, Image = avatar, BorderSizePixel = 0, ZIndex = 43, Parent = card,
        })
        Theme.bind(picture, "BackgroundColor3", "hover")
        corner(picture, 13)
        Theme.bind(stroke(picture, nil, 0.5, 1.5), "Color", "buttonEdge")
        local mask = Icons.themed(picture, "hat-glasses", 13, "muted", { Name = "Anon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 44, Visible = false })
        local dot = create("Frame", {
            Name = "Online", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 1, 1, 1), Size = UDim2.fromOffset(8, 8),
            BorderSizePixel = 0, ZIndex = 45, Parent = picture,
        })
        corner(dot, 4)
        Theme.bind(dot, "BackgroundColor3", "success")
        Theme.bind(stroke(dot, nil, 0, 1.5), "Color", "input")
        -- the pulse behind the dot while something runs (Window:SetProfileStatus("live"))
        local pulse = create("Frame", {
            Name = "Pulse", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(8, 8),
            BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 44, Parent = dot,
        })
        corner(pulse, 8)
        Theme.bind(pulse, "BackgroundColor3", "success")
        self._profileDot, self._profilePulse = dot, pulse
        local name = Util.label(card, player.DisplayName, 11, {
            Name = "Name", Position = UDim2.fromOffset(40, 6), Size = UDim2.new(1, -66, 0, 15), Font = Enum.Font.GothamBold, ZIndex = 43,
        })
        Theme.bind(name, "TextColor3", "heading")
        local time = Util.label(card, "00:00:00", 9, {
            Name = "Session", Position = UDim2.fromOffset(40, 21), Size = UDim2.new(1, -66, 0, 13), ZIndex = 43,
        })
        Theme.bind(time, "TextColor3", "muted")
        local eye = create("ImageButton", {
            Name = "Anonymous", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -5, 0.5, 0), Size = UDim2.fromOffset(22, 22),
            BackgroundTransparency = 1, AutoButtonColor = false, Image = "", ZIndex = 43, Parent = card,
        })
        -- incognito glasses: muted while you are shown, bright while anonymous
        local function rest() return self.anonymous and "heading" or "muted" end
        local eyeIcon = Icons.themed(eye, "hat-glasses", 14, rest(), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 44 })
        local function tip()
            self:_dockTip(self.anonymous and "Anonymous · click to show" or (player.DisplayName .. " · click to hide"),
                self.dock.Size.Y.Offset - 46)
        end
        eye.MouseEnter:Connect(function()
            if eyeIcon then Theme.tweenTo(eyeIcon, "ImageColor3", "heading", 0.1) end
            tip()
        end)
        eye.MouseLeave:Connect(function()
            if eyeIcon then Theme.tweenTo(eyeIcon, "ImageColor3", rest(), 0.1) end
            self:_hideTip()
        end)
        eye.Activated:Connect(function()
            self:SetAnonymous(not self.anonymous)
            tip()
        end)
        self:OnAnonymousChanged(function(on)
            picture.Image = on and "" or avatar
            if mask then mask.Visible = on end
            name.Text = on and "Anonymous" or player.DisplayName
            if eyeIcon then Theme.tweenTo(eyeIcon, "ImageColor3", rest(), 0.1) end
        end)
        -- session time, once a second while the card is on screen
        local started = os.clock()
        task.spawn(function()
            while self.alive do
                if card.Visible and self.visible then time.Text = Util.clock(os.clock() - started) end
                task.wait(1)
            end
        end)
        self._profileCard = card
    end

    ------------------------------------------------------------------ profile status
    -- The avatar dot can say what the script is doing: "live" (green and pulsing), "waiting" (yellow: about to start),
    -- "idle" (grey). Never called, it stays the plain green online dot.
    function Window:SetProfileStatus(state)
        local dot, pulse = self._profileDot, self._profilePulse
        if not dot or state == self._profileStatus then return end
        self._profileStatus = state
        Theme.tweenTo(dot, "BackgroundColor3", state == "waiting" and "warning" or state == "idle" and "muted" or "success", 0.2)
        if self._profilePulseTween then self._profilePulseTween:Cancel() self._profilePulseTween = nil end
        pulse.Size, pulse.BackgroundTransparency = UDim2.fromOffset(8, 8), 1
        if state == "live" then
            pulse.BackgroundTransparency = 0.35
            local tween = Util.Services.TweenService:Create(pulse, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1),
                { Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1 })
            tween:Play()
            self._profilePulseTween = tween
        end
    end

    ------------------------------------------------------------------ mouse unlock
    -- While the menu is open the mouse is free (shift lock / first person would keep it locked in the centre):
    -- a Modal button releases it and the cursor is shown. UnlockMouse = false turns it off; Window:SetMouseUnlock(bool).
    function Window:SetMouseUnlock(on)
        self.unlockMouse = on ~= false
        self:_applyMouse()
    end
    -- Games with their own cursor (Shindo's MOUSE gui) switch the system cursor off again and again: while the
    -- menu frees the mouse it is switched back on right away and once per frame after the game's own scripts
    -- (render step bound last), and handed back to the game when the menu closes.
    local ICON_STEP = "QustahUIMouseIcon"
    function Window:_applyMouse()
        local UserInputService = Util.Services.UserInputService
        local free = self.alive and self.visible and self.unlockMouse
        if self._modal then self._modal.Modal = free == true end
        if free then
            if self._savedMouseIcon == nil then self._savedMouseIcon = UserInputService.MouseIconEnabled end
            UserInputService.MouseIconEnabled = true
            if not self._iconGuard then
                self._iconGuard = UserInputService:GetPropertyChangedSignal("MouseIconEnabled"):Connect(function()
                    if not UserInputService.MouseIconEnabled then UserInputService.MouseIconEnabled = true end
                end)
                pcall(function()
                    Util.Services.RunService:BindToRenderStep(ICON_STEP, Enum.RenderPriority.Last.Value + 1, function()
                        if not UserInputService.MouseIconEnabled then UserInputService.MouseIconEnabled = true end
                    end)
                end)
            end
        else
            if self._iconGuard then
                self._iconGuard:Disconnect()
                self._iconGuard = nil
                pcall(function() Util.Services.RunService:UnbindFromRenderStep(ICON_STEP) end)
            end
            if self._savedMouseIcon ~= nil then
                UserInputService.MouseIconEnabled = self._savedMouseIcon
                self._savedMouseIcon = nil
            end
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
        -- (unload) a download strip still on screen goes with the window
        self.maid:give(function() pcall(function() require("loader").clear() end) end)
        self:_applyMouse()
        if cfg.FullscreenButton == true then
            self._fullscreenButton = self:HeaderButton({ Name = "Fullscreen", Icon = "maximize-2", Tooltip = "Fullscreen", Callback = function() self:ToggleFullscreen() end })
        end
        -- double click on the header toggles fullscreen too - only a real double click: two presses on the same spot
        -- with no window move in between (grabbing the header twice quickly while dragging it around is not one)
        local header = self.main:FindFirstChild("Header")
        local lastClick, lastPoint, lastTopLeft = 0, nil, nil
        if header then
            self.maid:connect(header.InputBegan, function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                local now, point = os.clock(), Util.pointer(input)
                local still = lastPoint and (point - lastPoint).Magnitude < 6 and lastTopLeft == self.topLeft
                if now - lastClick < 0.3 and still then
                    lastClick, lastPoint, lastTopLeft = 0, nil, nil
                    self:ToggleFullscreen()
                else
                    lastClick, lastPoint, lastTopLeft = now, point, self.topLeft
                end
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
            local avatar = Util.avatar(player.UserId, 60) -- (shown at 30 px: a clean 2x)
            button.Image = avatar
            self._profile, self._profileLine = button, line
            self:_profileCardMake(player, avatar)
            self:OnAnonymousChanged(function(on)
                button.Image = on and "" or avatar
                if mask then mask.Visible = on end
                Theme.tweenTo(ring, "Color", on and "accent" or "buttonEdge", 0.12)
            end)
            button.MouseEnter:Connect(function()
                self:_dockTip(self.anonymous and "Anonymous · click to show" or (player.DisplayName .. " · click to hide"),
                    self.dockSide == "Bottom" and button.Position.X.Offset or button.Position.Y.Offset)
            end)
            button.MouseLeave:Connect(function() self:_hideTip() end)
            button.Activated:Connect(function() self:SetAnonymous(not self.anonymous) end)
            self:_layoutDock()
            self:_layout()
        end
        if cfg.Anonymous then self:SetAnonymous(true) end
    end
end
