-- Window looks and greetings:
--   Window:AddTag("BETA", { Color = "warning" | Color3, Style = "Solid" | "Soft" }) -> { SetText, SetColor, Remove }
--   CreateWindow({ Tags = { "BETA", { Text = "PRO", Color = Color3.fromRGB(240, 190, 80) } } })
--     Solid tags pick black or white text from the fill, so any colour stays readable.
--   Window:SetLiveBackground(on)  a slow drifting accent gradient behind the content (LiveBackground = true)
--   Window:SetAccentGlow(on)      the window edge breathes in the accent colour (AccentGlow = true)
--   Welcome toast: "Signed in as <name>" the first time an account opens this UI (Welcome = false turns it off).
--   Window:SetBlur(on, size)      blurs the game behind while the menu is open (Blur = true / Settings)
--   Changelog = { Version = "1.2", Title = "What's new", Items = { "Added ...", "Fixed ..." } }: shown once per
--     version, in a dialog; Window:ShowChangelog() opens it again (Settings › Info has a button).
local Util = require("util")
local Theme = require("theme")

local create, corner, stroke, label, tween = Util.create, Util.corner, Util.stroke, Util.label, Util.tween

-- relative luminance (WCAG) -> black or white text
local function readableOn(color)
    local function channel(c) return c <= 0.03928 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4 end
    local luminance = 0.2126 * channel(color.R) + 0.7152 * channel(color.G) + 0.0722 * channel(color.B)
    return luminance > 0.36 and Color3.fromRGB(18, 18, 22) or Color3.new(1, 1, 1)
end

return function(Window)
    ------------------------------------------------------------------ tags
    function Window:AddTag(text, opts)
        if type(text) == "table" then opts, text = text, text.Text end
        opts = opts or {}
        self._tagCount = (self._tagCount or 0) + 1
        local tag = create("Frame", {
            Name = "Tag", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 16), BorderSizePixel = 0,
            LayoutOrder = 10 + self._tagCount, Parent = self.titleRow,
        })
        corner(tag, 5)
        Util.padding(tag, 6, 6, 0, 0)
        local caption = label(tag, tostring(text or ""), 8, {
            Name = "Text", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.None,
        })
        local edge = stroke(tag, nil, 0.6)
        local color, style = opts.Color or "accent", opts.Style == "Soft" and "Soft" or "Solid"
        local function paint()
            local fill = typeof(color) == "Color3" and color or Theme.get(color)
            if style == "Soft" then
                tag.BackgroundColor3, tag.BackgroundTransparency = fill, 0.84
                caption.TextColor3, edge.Color, edge.Transparency = fill, fill, 0.55
            else
                tag.BackgroundColor3, tag.BackgroundTransparency = fill, 0
                caption.TextColor3, edge.Color, edge.Transparency = readableOn(fill), fill, 1
            end
        end
        paint()
        local alive = true
        Theme.onChange(function() if alive and tag.Parent then paint() end end)
        local handle = { Frame = tag }
        function handle:SetText(value) caption.Text = tostring(value) end
        function handle:SetColor(value) color = value or "accent" paint() end
        function handle:SetVisible(visible) tag.Visible = visible ~= false end
        -- the header text on the right makes room for the tags
        local window = self
        function handle:Remove()
            alive = false
            tag:Destroy()
            if window.alive then window:_updateLocation() end
        end
        task.defer(function() if window.alive then window:_updateLocation() end end)
        return handle
    end

    ------------------------------------------------------------------ live background
    function Window:SetLiveBackground(on)
        self.liveBackground = on == true
        if self._live then self._live.connection:Disconnect() self._live.frame:Destroy() self._live = nil end
        if not self.liveBackground then return end
        local frame = create("Frame", { Name = "LiveBackground", Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ZIndex = 0, Active = false, Parent = self.main })
        corner(frame, 12)
        Theme.bind(frame, "BackgroundColor3", "accent")
        local gradient = create("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.35, 0.985),
                NumberSequenceKeypoint.new(0.7, 0.95), NumberSequenceKeypoint.new(1, 0.995),
            }),
            Parent = frame,
        })
        local started, last = os.clock(), 0
        local connection = Util.Services.RunService.Heartbeat:Connect(function()
            local now = os.clock()
            if now - last < 1 / 24 or not self.main.Visible then return end -- 24 updates a second is plenty for a slow drift
            last = now
            local t = now - started
            gradient.Rotation = (t * 9) % 360
            gradient.Offset = Vector2.new(math.sin(t * 0.21) * 0.25, math.cos(t * 0.17) * 0.25)
        end)
        self.maid:give(connection)
        self._live = { frame = frame, gradient = gradient, connection = connection }
    end

    ------------------------------------------------------------------ accent glow on the window edge
    function Window:SetAccentGlow(on)
        self.accentGlow = on == true
        if self._glowConnection then self._glowConnection:Disconnect() self._glowConnection = nil end
        local edge = self.mainStroke
        if not edge then return end
        if not self.accentGlow then
            Theme.bind(edge, "Color", "edge")
            edge.Transparency, edge.Thickness = 0, 1
            return
        end
        Theme.bind(edge, "Color", "accent")
        edge.Thickness = 1.5
        local last = 0
        self._glowConnection = Util.Services.RunService.Heartbeat:Connect(function()
            local now = os.clock()
            if now - last < 1 / 30 then return end
            last = now
            edge.Transparency = 0.55 + math.sin(now * 2.1) * 0.25 -- breathes between 0.3 and 0.8
        end)
        self.maid:give(self._glowConnection)
    end

    ------------------------------------------------------------------ background blur
    function Window:SetBlur(on, size)
        self.blur = on == true
        if size then self.blurSize = math.clamp(tonumber(size) or 12, 2, 40) end
        self:_applyBlur()
    end
    function Window:_applyBlur()
        local want = self.blur and self.alive and self.visible
        local effect = self._blurEffect
        if effect and not effect.Parent then effect = nil self._blurEffect = nil end -- the game cleared Lighting: make a new one
        if want and not effect then
            pcall(function()
                effect = Instance.new("BlurEffect")
                effect.Name = Util.secure and Util.Services.HttpService:GenerateGUID(false) or "QustahUIBlur"
                effect.Size = 0
                effect.Parent = Util.Services.Lighting
            end)
            self._blurEffect = effect
        end
        if not effect then return end
        local target = want and (self.blurSize or 12) or 0
        tween(effect, 0.2, { Size = target })
        if not want then
            local token = {}
            self._blurToken = token
            task.delay(0.22, function()
                if self._blurToken == token and self._blurEffect == effect and not (self.blur and self.alive and self.visible) then
                    effect:Destroy()
                    self._blurEffect = nil
                end
            end)
        else
            self._blurToken = nil
        end
    end
    local setVisible = Window.SetVisible
    function Window:SetVisible(visible)
        setVisible(self, visible)
        if self.blur or self._blurEffect then self:_applyBlur() end
    end

    ------------------------------------------------------------------ small state kept on this PC
    -- (in <Folder>/state.json, so it works with SaveWindow = false too): welcome / changelog seen, welcome toast on
    function Window:_state(key, value)
        self._stateData = self._stateData or self.Config:ReadJSON("state")
        if value ~= nil then
            self._stateData[key] = value
            self.Config:WriteJSON("state", self._stateData)
        end
        return self._stateData[key]
    end

    ------------------------------------------------------------------ changelog
    function Window:ShowChangelog()
        local log = self.cfg.Changelog
        if type(log) ~= "table" then return nil end
        local lines = {}
        for _, item in ipairs(log.Items or {}) do lines[#lines + 1] = "•  " .. tostring(item) end
        if log.Content then table.insert(lines, 1, tostring(log.Content) .. (#lines > 0 and "\n" or "")) end
        return self:Dialog({
            Title = tostring(log.Title or ("What's new" .. (log.Version and (" in " .. tostring(log.Version)) or ""))),
            Icon = log.Icon or "sparkles", Content = table.concat(lines, "\n"),
            Buttons = { { Title = log.Button or "Got it", Style = "Primary" } },
        })
    end
    function Window:_changelog()
        local log = self.cfg.Changelog
        if type(log) ~= "table" then return end
        local version = tostring(log.Version or self.Version or "")
        if self:_state("changelogSeen") == version then return end
        self:_state("changelogSeen", version)
        task.delay(tonumber(log.Delay) or 1, function()
            if self.alive and not self._dialog then self:ShowChangelog() end
        end)
    end

    ------------------------------------------------------------------ welcome
    function Window:_welcome()
        if self.cfg.Welcome == false or self.anonymous then return end
        if self:_state("welcomeToast") == false then return end
        local player = Util.Services.Players.LocalPlayer
        if not player then return end
        local id = tostring(player.UserId)
        if self:_state("welcomed") == id then return end
        self:_state("welcomed", id)
        task.delay(0.6, function()
            if not self.alive or self.anonymous then return end
            self:Toast({ Text = "Signed in as <b>" .. tostring(player.DisplayName or player.Name) .. "</b>", Image = Util.avatar(player.UserId), Duration = 3.5 })
        end)
    end

    function Window:_buildFx()
        local cfg = self.cfg
        for _, item in ipairs(type(cfg.Tags) == "table" and cfg.Tags or {}) do self:AddTag(item) end
        local memory = self.memory or {}
        local live = memory.liveBackground
        if live == nil then live = cfg.LiveBackground == true end
        if live then self:SetLiveBackground(true) end
        local glow = memory.accentGlow
        if glow == nil then glow = cfg.AccentGlow == true end
        if glow then self:SetAccentGlow(true) end
        local blur = memory.blur
        if blur == nil then blur = cfg.Blur == true end
        if blur then self:SetBlur(true, tonumber(cfg.BlurSize)) end
        self.maid:give(function() self.blur = false self:_applyBlur() end)
        self:_welcome()
        self:_changelog()
        if self._autoTour then self:_autoTour() end
    end
end
