-- Window shell (Qustah layout): header (title, version badge, "Tab › Page" location, minimize / close), sub-page
-- strip, scrolling pages with two card columns, key hint bar, footer (status, centre text, resize grip) and the
-- dock to the right (drag handle, tab icons, group dividers).
local Util = require("util")
local Theme = require("theme")
local Card = require("card")
local Config = require("config")
local Glow = require("glow")
local UIFont = require("font")
local Icons = require("icons")

local Services = Util.Services
local create, corner, stroke, label, tween = Util.create, Util.corner, Util.stroke, Util.label, Util.tween

local HEADER, FOOTER = 44, 26
local DOCK_WIDTH, DOCK_GAP, DOCK_BUTTON, DOCK_STEP, DOCK_TOP = 40, 12, 30, 37, 42
local HINTS = 34 -- height taken by the key hint bar
local NARROW = 470 -- below this width the two card columns stack

local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Page = {}
Page.__index = Page

-------------------------------------------------------------------------------- Page
function Page.new(tab, name, cfg)
    local window = tab.window
    local self = setmetatable({ tab = tab, window = window, Name = name, cfg = cfg or {}, cards = 0, order = 0 }, Page)
    local frame = create("ScrollingFrame", {
        Name = name, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 2, ScrollBarImageTransparency = 0.4, ElasticBehavior = Enum.ElasticBehavior.Never,
        VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar, Visible = false, Parent = window.pages,
    })
    Theme.bind(frame, "ScrollBarImageColor3", "muted")
    Util.fadeScrollbar(frame, 0.4)
    -- Margins come from the content frame's position / size, not from a UIPadding on the ScrollingFrame:
    -- Roblox sizes scale children of a padded ScrollingFrame from the unpadded width, which pushed the right
    -- column past the window edge.
    local content = create("Frame", {
        Name = "Content", BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 2), Size = UDim2.new(1, -30, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, Parent = frame,
    })
    Util.list(content, 10)
    Util.padding(content, 0, 0, 0, 14)
    Util.fitCanvas(frame, content)
    -- full-width cards (Card({ Wide = true })) above the two columns
    local wide = create("Frame", { Name = "Wide", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = content })
    Util.list(wide, 10)
    local holder = create("Frame", {
        Name = "Columns", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2, Parent = content,
    })
    self.layout = Util.list(holder, 10, Enum.FillDirection.Horizontal)
    local function column(name, order)
        local object = create("Frame", {
            Name = name, BackgroundTransparency = 1, Size = UDim2.new(0.5, -5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = order, Parent = holder,
        })
        Util.list(object, 10)
        return object
    end
    -- Wide = "Bottom": full-width cards under the two columns
    local wideBottom = create("Frame", { Name = "WideBottom", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, Parent = content })
    Util.list(wideBottom, 10)
    self.frame, self.wide, self.left, self.right = frame, wide, column("Left", 1), column("Right", 2)
    self.wideBottom = wideBottom
    self.content = content
    if self.cfg.Warning then task.defer(function() self:Warning(self.cfg.Warning) end) end

    -- soft fades at the top / bottom edge while there is more to scroll that way
    local function fade(top)
        local object = create("Frame", {
            Name = top and "FadeTop" or "FadeBottom", AnchorPoint = Vector2.new(0, top and 0 or 1),
            Position = UDim2.new(0, 0, top and 0 or 1, 0), Size = UDim2.new(1, -4, 0, 18), BorderSizePixel = 0,
            Visible = false, ZIndex = 20, Active = false, Parent = window.pages,
        })
        Theme.bind(object, "BackgroundColor3", "base")
        create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(top and 0 or 1, top and 1 or 0), Parent = object })
        return object
    end
    local fadeTop, fadeBottom = fade(true), fade(false)
    local function refreshFades()
        local shown = frame.Visible
        local scrolled = frame.CanvasPosition.Y
        local hidden = frame.AbsoluteCanvasSize.Y - frame.AbsoluteWindowSize.Y - scrolled
        fadeTop.Visible = shown and scrolled > 2
        fadeBottom.Visible = shown and hidden > 2
    end
    for _, property in ipairs({ "CanvasPosition", "AbsoluteCanvasSize", "AbsoluteWindowSize", "Visible" }) do
        frame:GetPropertyChangedSignal(property):Connect(refreshFades)
    end

    -- strip button (shown when the tab has more than one page)
    local button = create("TextButton", {
        Name = name, BackgroundTransparency = 1, Text = name, TextSize = 10, Font = Enum.Font.GothamMedium,
        AutoButtonColor = false, Parent = tab.strip,
    })
    Theme.bind(button, "TextColor3", "text")
    local underline = create("Frame", {
        Name = "Underline", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.fromOffset(math.max(12, Util.textWidth(name, 10, Enum.Font.GothamMedium)), 1),
        BorderSizePixel = 0, Visible = false, Parent = button,
    })
    Theme.bind(underline, "BackgroundColor3", "accent")
    self.button, self.underline = button, underline
    button.MouseEnter:Connect(function() if tab.current ~= self then Theme.tweenTo(button, "TextColor3", "heading", 0.12) end end)
    button.MouseLeave:Connect(function() if tab.current ~= self then Theme.tweenTo(button, "TextColor3", "text", 0.12) end end)
    button.Activated:Connect(function() self:Select() end)
    self:_columns(window.width)
    return self
end

-- Two columns side by side, or stacked when the window is narrow / the page asked for one column.
function Page:_columns(width)
    local single = self.cfg.Columns == 1 or width < NARROW
    self.layout.FillDirection = single and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
    local size = single and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -5, 0, 0)
    self.left.Size, self.right.Size = size, size
end

-- Page:Card({ Title = "General", Side = "Left" | "Right", Wide = true }) - without Side the cards alternate
-- left / right; Wide cards span both columns and sit above them (Wide = "Bottom": under them).
-- page:Warning("These features can get you banned", { Title = "Risky", Icon = "triangle-alert", Level = "warning" | "danger" | "info" })
-- A banner at the top of the page. Returns { SetText, SetVisible, Frame }. Tab:Page(name, { Warning = "..." }) too.
function Page:Warning(text, opts)
    opts = opts or {}
    local level = opts.Level or "warning"
    local role = level == "info" and "accent" or level
    local banner = create("Frame", { Name = "Warning", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, LayoutOrder = 0, Parent = self.content })
    Theme.bind(banner, "BackgroundColor3", role)
    banner.BackgroundTransparency = 0.88
    corner(banner, 8)
    local edge = stroke(banner)
    Theme.bind(edge, "Color", role)
    edge.Transparency = 0.55
    Util.padding(banner, 12, 12, 9, 9)
    local Icons = require("icons")
    local icon = Icons.themed(banner, opts.Icon or (level == "info" and "info" or "triangle-alert"), 15, role, { Position = UDim2.fromOffset(0, 1) })
    -- text column right of the icon
    local column = create("Frame", { Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(icon and 26 or 0, 0), Size = UDim2.new(1, icon and -26 or 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = banner })
    Util.list(column, 2)
    local title
    if opts.Title then
        title = label(column, tostring(opts.Title), 11, { Name = "Title", Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.GothamMedium, LayoutOrder = 1 })
        Theme.bind(title, "TextColor3", role)
    end
    local body = label(column, tostring(text or ""), 10, {
        Name = "Text", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None, RichText = true, LayoutOrder = 2,
    })
    Theme.bind(body, "TextColor3", "heading")
    local handle = { Frame = banner, Icon = icon }
    function handle:SetText(value) body.Text = tostring(value) end
    function handle:SetVisible(visible) banner.Visible = visible ~= false end
    return handle
end

function Page:Card(cfg)
    cfg = cfg or {}
    self.cards = self.cards + 1
    local side = cfg.Side
    if self.cfg.Columns == 1 then side = "Left" end
    if side ~= "Left" and side ~= "Right" then side = (self.cards % 2 == 1) and "Left" or "Right" end
    self.order = self.order + 1
    if cfg.Wide then
        self.cards = self.cards - 1 -- a wide card does not take a turn in the left / right alternation
        return Card.new(self, cfg.Wide == "Bottom" and self.wideBottom or self.wide, cfg, self.order)
    end
    return Card.new(self, side == "Right" and self.right or self.left, cfg, self.order)
end

-- page:MatchHeights(cardA, cardB, ...): side-by-side cards grow to the tallest one (the extra room goes under
-- their last element), and follow when any of them changes height.
function Page:MatchHeights(...)
    local cards = { ... }
    local constraints = {}
    for index, card in ipairs(cards) do
        constraints[index] = create("UISizeConstraint", { Name = "MatchHeight", Parent = card.frame })
    end
    local busy = false
    local function natural(card)
        local layout = card.frame:FindFirstChildOfClass("UIListLayout")
        local scale = self.window.scale and self.window.scale.Scale or 1
        local content = layout and layout.AbsoluteContentSize.Y or 0
        if content <= 0 then return 0 end
        return content / scale + 18 -- (the card's padding: 8 above, 10 below)
    end
    local function apply()
        if busy then return end
        busy = true
        local tallest = 0
        for _, card in ipairs(cards) do
            if card.frame.Visible and not card.Collapsed then tallest = math.max(tallest, natural(card)) end
        end
        for index, card in ipairs(cards) do
            local want = (card.frame.Visible and not card.Collapsed) and tallest or 0
            constraints[index].MinSize = Vector2.new(0, math.floor(want))
        end
        busy = false
    end
    for _, card in ipairs(cards) do
        local layout = card.frame:FindFirstChildOfClass("UIListLayout")
        if layout then layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() task.defer(apply) end) end
        card.frame:GetPropertyChangedSignal("Visible"):Connect(function() task.defer(apply) end)
    end
    task.defer(apply)
    return apply
end

function Page:Select()
    local tab = self.tab
    tab.current = self
    for _, page in ipairs(tab.Pages) do
        local selected = page == self
        page.frame.Visible = selected and tab.window.current == tab
        page.underline.Visible = selected
        Theme.tweenTo(page.button, "TextColor3", selected and "accent" or "text", 0.12)
    end
    tab.window:_updateLocation()
end

-------------------------------------------------------------------------------- Tab
function Tab.new(window, cfg)
    local index = #window.Tabs + 1
    local self = setmetatable({ window = window, Title = cfg.Title or ("Tab " .. index), Pages = {}, index = index }, Tab)
    self.strip = create("Frame", { Name = self.Title, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = window.stripHolder })

    self.Header = cfg.Header == true -- also shown as a text tab in the header (Overview / Settings)
    -- Build = function(tab) ... end: the tab's content is made the first time it opens (faster start for big scripts)
    -- (it also builds itself a moment after start, so its key binds work without opening it; BuildDelay = false: only on open)
    self._build = type(cfg.Build) == "function" and cfg.Build or nil
    if self._build and cfg.BuildDelay ~= false then
        task.delay(tonumber(cfg.BuildDelay) or 1.5, function()
            if self._build and window.alive then self:Build() end
        end)
    end
    self.Divider = cfg.Divider == true or window._dividerNext == true -- a short line above this tab in the dock
    window._dividerNext = nil
    local button = create("TextButton", {
        Name = self.Title .. "Tab", BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0,
        Position = UDim2.fromOffset(5, DOCK_TOP), Size = UDim2.fromOffset(DOCK_BUTTON, DOCK_BUTTON), ZIndex = 42, Parent = window.dock,
    })
    Theme.bind(button, "BackgroundColor3", "accentDeep")
    corner(button, 15)
    local icon
    -- Icon: a name ("eye", "solar:eye-bold"), an asset id or nothing (first letter of the title)
    if cfg.Icon ~= nil and Icons.Get(cfg.Icon) then
        icon = create("ImageLabel", {
            Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 18),
            BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 43, Parent = button,
        })
        Icons.Apply(icon, cfg.Icon)
        self.iconProperty = "ImageColor3"
    else
        icon = label(button, self.Title:sub(1, 1):upper(), 13, {
            Name = "Icon", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, ZIndex = 43,
        })
        self.iconProperty = "TextColor3"
    end
    self.button, self.icon, self.hovered = button, icon, false
    self:_render(false)
    button.MouseEnter:Connect(function()
        self.hovered = true
        self:_render(true)
        window:_dockTip(self.Title, self.y or DOCK_TOP)
    end)
    button.MouseLeave:Connect(function()
        self.hovered = false
        self:_render(true)
        window:_hideTip()
    end)
    button.Activated:Connect(function()
        window:_hideTip()
        if window.current ~= self then require("sounds").Play("tab") end
        self:Select()
    end)
    return self
end

-- Dock button look: selected = filled + accent icon, hover = half fill + bright icon.
function Tab:_render(animate)
    local selected = self.window.current == self
    local duration = animate and 0.14 or nil
    local transparency = selected and 0 or (self.hovered and 0.6 or 1)
    if duration then tween(self.button, duration, { BackgroundTransparency = transparency }) else self.button.BackgroundTransparency = transparency end
    Theme.tweenTo(self.icon, self.iconProperty, selected and "accent" or (self.hovered and "heading" or "icon"), duration)
end

-- Tab:Page("Overview") adds a sub-page; with two or more pages the strip of page names appears.
-- tab:SetBadge(3) / ("NEW") / (true) a dot / (nil, 0, false) hides it; color: a theme role or Color3 (default "accent").
-- A small tag on the tab's dock button (new messages, an error, an update...).
-- tab:SetActive(true): a small green dot at the bottom-right of the dock button (something in this tab is
-- running); SetActive(false) hides it. Color: a theme role or Color3 (default "success"). Kept apart from SetBadge.
function Tab:SetActive(on, color)
    self.Active = on == true
    local dot = self._activeDot
    if not dot then
        if not self.Active then return end
        dot = create("Frame", { Name = "ActiveDot", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -1, 1, -1), Size = UDim2.fromOffset(7, 7), BorderSizePixel = 0, ZIndex = 45, Parent = self.button })
        corner(dot, 4)
        Theme.bind(Util.stroke(dot, nil, 0, 1.5), "Color", "dock")
        self._activeDot = dot
    end
    Theme.bind(dot, "BackgroundColor3", color or "success")
    dot.Visible = self.Active
end

function Tab:SetBadge(value, color)
    local shown = value ~= nil and value ~= false and value ~= 0 and tostring(value) ~= "" and tostring(value) ~= "0"
    self.Badge = shown and value or nil
    if not shown then
        if self._badge then self._badge.Visible = false end
        return
    end
    local badge = self._badge
    if not badge then
        badge = create("Frame", { Name = "Badge", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 2, 0, -1), BorderSizePixel = 0, ZIndex = 45, Parent = self.button })
        corner(badge, 7)
        local text = label(badge, "", 8, { Name = "Text", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, ZIndex = 46 })
        local ring = Util.stroke(badge, nil, 0, 1.5)
        Theme.bind(ring, "Color", "dock")
        self._badge, self._badgeText = badge, text
    end
    local role = color or "accent"
    Theme.bind(badge, "BackgroundColor3", role)
    Theme.bind(self._badgeText, "TextColor3", role == "accent" and "onAccent" or "heading")
    if value == true then
        -- a dot
        self._badgeText.Text = ""
        badge.Size = UDim2.fromOffset(8, 8)
        badge.Position = UDim2.new(1, 0, 0, 1)
    else
        local text = tostring(value)
        if tonumber(value) and tonumber(value) > 99 then text = "99+" end
        self._badgeText.Text = text
        badge.Size = UDim2.fromOffset(math.max(14, Util.textWidth(text, 8, Enum.Font.GothamBold) + 8), 14)
        badge.Position = UDim2.new(1, 3, 0, -2)
    end
    badge.Visible = true
end

function Tab:Page(name, cfg)
    local page = Page.new(self, tostring(name or ("Page " .. (#self.Pages + 1))), cfg)
    self.Pages[#self.Pages + 1] = page
    local count = #self.Pages
    for index, item in ipairs(self.Pages) do
        item.button.Position = UDim2.new((index - 1) / count, 0, 0, 0)
        item.button.Size = UDim2.new(1 / count, 0, 1, 0)
    end
    if not self.current then self.current = page end
    if self.window.current == self then self:Select() end
    return page
end

-- Cards straight on a tab go to its first page.
function Tab:Card(cfg)
    if #self.Pages == 0 then self:Page(self.Title) end
    return self.Pages[1]:Card(cfg)
end

-- Makes a lazy tab's content now (Tab({ Build = fn })); later calls do nothing.
function Tab:Build()
    local build = self._build
    if not build then return end
    self._build = nil
    self.window:_safe("Build " .. self.Title, build, self)
end

function Tab:Select()
    local window = self.window
    if self._build then self:Build() end
    window.current = self
    for _, tab in ipairs(window.Tabs) do
        tab.strip.Visible = tab == self and #tab.Pages > 1
        for _, page in ipairs(tab.Pages) do page.frame.Visible = false end
        tab:_render(true)
    end
    window:_layoutBody()
    local page = self.current or self.Pages[1]
    if page then page:Select() else window:_updateLocation() end
end

-------------------------------------------------------------------------------- Window
function Window.new(Lib, cfg)
    cfg = cfg or {}
    local size = cfg.Size or Vector2.new(540, 390)
    local self = setmetatable({
        Lib = Lib, cfg = cfg, Title = tostring(cfg.Title or "Qustah UI"), Version = tostring(cfg.Version or ""),
        Tabs = {}, flags = {}, binds = {}, maid = Util.maid(),
        width = size.X, height = size.Y,
        minSize = cfg.MinSize or Vector2.new(400, 300), maxSize = cfg.MaxSize or Vector2.new(920, 660),
        key = cfg.ToggleKey or Enum.KeyCode.RightShift, visible = true, folded = false, alive = true,
    }, Window)
    -- key conflicts the script starts with are only marked; later ones also get a notification
    task.delay(3, function() self._keysSettled = true end)

    -- Running the same script again replaces its old window instead of stacking a second one.
    local env = (getgenv and getgenv()) or _G
    env.__QustahUIWindows = env.__QustahUIWindows or {}
    local previous = env.__QustahUIWindows[self.Title]
    if previous and previous.Destroy then
        pcall(previous.Destroy, previous)
        -- a re-run loads a new copy of the library: the old copy's loops and toast guis go too
        local oldLib = previous.Lib
        if oldLib and oldLib ~= Lib and type(oldLib.Windows) == "table" and #oldLib.Windows == 0 and oldLib.Destroy then pcall(oldLib.Destroy, oldLib) end
    end
    env.__QustahUIWindows[self.Title] = self

    if typeof(cfg.Accent) == "Color3" then Theme.set("accent", cfg.Accent) end
    if cfg.Secure then Util.secure = true end
    if cfg.Sounds ~= nil then require("sounds").Enabled = cfg.Sounds == true end
    self:_makeFlags()
    self.Config = Config.new(self, cfg.Folder or self.Title:gsub("[^%w_%- ]", ""))
    -- a file that was being written when the game closed came back from its .tmp copy
    self.Config:OnRecovered(function(name)
        task.defer(function()
            if self.alive then self:Notify({ Title = "Restored " .. tostring(name), Content = "It was saved when the game closed - nothing was lost", Icon = "history", Color = "warning" }) end
        end)
    end)
    -- window memory: last position / size (SaveWindow = false turns it off)
    self.memory = cfg.SaveWindow ~= false and self.Config:ReadMemory() or {}
    -- per-game profiles: the choice made in Settings (remembered with the window) wins over CreateWindow's PerGame
    local perGame = self.memory.perGame
    if perGame == nil then perGame = cfg.PerGame end
    if perGame then self.Config:SetPerGame(perGame) end
    local saved = self.memory.window
    if type(saved) == "table" and tonumber(saved.w) and tonumber(saved.h) then
        self.width = math.clamp(tonumber(saved.w), self.minSize.X, self.maxSize.X)
        self.height = math.clamp(tonumber(saved.h), self.minSize.Y, self.maxSize.Y)
    end
    self.uiScale = math.clamp(tonumber(self.memory.uiScale or cfg.Scale) or 1, 0.6, 1.5)
    Glow.start(Lib.maid)
    self:_build()
    if self._buildExtras then self:_buildExtras() end
    if self._buildInbox then self:_buildInbox() end
    if self._buildFx then self:_buildFx() end
    if self._watchKicks then self:_watchKicks() end
    if self._buildMobile then self:_buildMobile() end
    self:_refreshStatus()
    Lib.Windows[#Lib.Windows + 1] = self
    return self
end

function Window:_build()
    local maid = self.maid
    local gui = Util.screenGui("QustahUI_" .. self.Title:gsub("%W", ""), 50)
    maid:give(gui)
    self.gui = gui
    UIFont.register(gui, maid)

    local main = create("CanvasGroup", {
        Name = "Window", Size = UDim2.fromOffset(self.width, self.height), BorderSizePixel = 0,
        GroupTransparency = 0, ClipsDescendants = true, Parent = gui,
    })
    Theme.bind(main, "BackgroundColor3", "base")
    corner(main, 12)
    self.mainStroke = stroke(main)
    Theme.bind(self.mainStroke, "Color", "edge")
    self.main = main
    self.scale = create("UIScale", { Scale = 1, Parent = main })

    ---------------------------------------------------------------- header
    local header = create("Frame", { Name = "Header", BackgroundTransparency = 1, Size = UDim2.new(1, -90, 0, HEADER), Active = true, Parent = main })
    local titleRow = create("Frame", { Name = "TitleRow", BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -16, 1, 0), Parent = header })
    Util.list(titleRow, 6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    local title = label(titleRow, self.Title, 16, {
        Name = "Title", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 24),
        TextTruncate = Enum.TextTruncate.None, LayoutOrder = 1,
    })
    pcall(function() title.FontFace = Font.new(Font.fromEnum(Enum.Font.Gotham).Family, Enum.FontWeight.SemiBold) end)
    Theme.bind(title, "TextColor3", "accent")
    Glow.add(title, { Base = "accent", Period = 3.6, GlowTransparency = 0.8 })
    -- CreateWindow({ Icon = "swords" }): a logo before the title
    if self.cfg.Icon then
        local logo = Icons.themed(titleRow, self.cfg.Icon, 18, "accent", { Name = "Logo", LayoutOrder = 0 })
        if logo then self.logo = logo end
    end
    if self.Version ~= "" then
        local badge = create("Frame", { Name = "Version", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 16), LayoutOrder = 2, Parent = titleRow })
        Theme.bind(badge, "BackgroundColor3", "card")
        corner(badge, 6)
        Theme.bind(stroke(badge, nil, 0.5), "Color", "accent")
        Util.padding(badge, 6, 6, 0, 0)
        local text = label(badge, self.Version, 9, {
            AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.None,
        })
        Theme.bind(text, "TextColor3", "accent")
    end
    self.titleLabel, self.titleRow = title, titleRow

    local function windowButton(name, offset, cross, bare)
        local button = create("TextButton", {
            Name = name, Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
            Position = UDim2.new(1, offset, 0, 8), Size = UDim2.fromOffset(30, 28), Parent = main,
        })
        corner(button, 6)
        Theme.bind(button, "BackgroundColor3", "input")
        local bars = {}
        for _, rotation in ipairs(bare and {} or (cross and { 45, -45 } or { 0 })) do
            local bar = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 2),
                Rotation = rotation, BorderSizePixel = 0, Parent = button,
            })
            corner(bar, 1)
            Theme.bind(bar, "BackgroundColor3", "muted")
            bars[#bars + 1] = bar
        end
        button.MouseEnter:Connect(function()
            tween(button, 0.12, { BackgroundTransparency = 0, BackgroundColor3 = Theme.get(cross and "dangerDeep" or "input") })
            for _, bar in ipairs(bars) do Theme.tweenTo(bar, "BackgroundColor3", cross and "danger" or "heading", 0.12) end
        end)
        button.MouseLeave:Connect(function()
            tween(button, 0.12, { BackgroundTransparency = 1 })
            for _, bar in ipairs(bars) do Theme.tweenTo(bar, "BackgroundColor3", "muted", 0.12) end
        end)
        return button
    end
    local minimize = windowButton("Minimize", -74, false)
    local close = windowButton("Close", -40, true)
    self._windowButton = windowButton
    -- room taken by the header buttons (the bell adds one more)
    self.headerRight = 90 -- grows with each extra header button (Window:_headerSlot)
    -- fading accent line under the header
    local headerLine = create("Frame", { Name = "HeaderLine", Position = UDim2.fromOffset(18, HEADER), Size = UDim2.new(1, -36, 0, 1), BorderSizePixel = 0, Parent = main })
    Theme.bind(headerLine, "BackgroundColor3", "accent")
    create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 1),
        }), Parent = headerLine,
    })
    -- "Visuals › Overview" on the right of the header
    local location = label(main, "", 10, {
        Name = "Location", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -self.headerRight, 0, 12), Size = UDim2.new(0.45, 0, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    Theme.bind(location, "TextColor3", "muted")
    self.locationLabel = location
    -- text tabs in the header for tabs created with Header = true (shown while one of them is open)
    self.headerTabs = create("Frame", {
        Name = "HeaderTabs", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -self.headerRight, 0, 0),
        Size = UDim2.new(0, 0, 0, HEADER), AutomaticSize = Enum.AutomaticSize.X, Visible = false, Parent = main,
    })
    Util.list(self.headerTabs, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right)

    ---------------------------------------------------------------- body
    local body = create("Frame", {
        Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, HEADER + 1),
        Size = UDim2.new(1, 0, 1, -(HEADER + 1 + FOOTER)), ClipsDescendants = true, Parent = main,
    })
    self.body = body
    self.stripHolder = create("Frame", { Name = "Strip", BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 6), Size = UDim2.new(1, -32, 0, 26), Parent = body })
    self.pages = create("Frame", { Name = "Pages", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 1, -6), Parent = body })
    -- key hints: [NUM 8] • ESP / SILENT AIM ............ MENU • [RSHIFT]
    self.hintBar = create("Frame", { Name = "KeyHints", BackgroundTransparency = 1, Position = UDim2.new(0, 20, 1, -30), Size = UDim2.new(1, -40, 0, 26), Visible = false, Parent = body })
    self.hintLeft = create("Frame", { Name = "Left", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = self.hintBar })
    Util.list(self.hintLeft, 8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    self.hintRight = create("Frame", { Name = "Right", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = self.hintBar })
    Util.list(self.hintRight, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
    self.hints = {}

    ---------------------------------------------------------------- footer
    local footer = create("Frame", { Name = "Footer", Position = UDim2.new(0, 0, 1, -FOOTER), Size = UDim2.new(1, 0, 0, FOOTER), BorderSizePixel = 0, Parent = main })
    Theme.bind(footer, "BackgroundColor3", "footer")
    local footerLine = create("Frame", { Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, BackgroundTransparency = 0.45, Parent = footer })
    Theme.bind(footerLine, "BackgroundColor3", "line")
    -- status mark: solar "record-bold" (a filled dot) in the status colour; asset id inlined so the solar set is not downloaded
    local dot = create("ImageLabel", {
        Name = "StatusDot", Image = "rbxassetid://122485335253573", BackgroundTransparency = 1, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 19, 0.5, 0), Size = UDim2.fromOffset(10, 10), Parent = footer,
    })
    Theme.bind(dot, "ImageColor3", "success")
    local status = label(footer, "Connected", 9, { Name = "Status", Position = UDim2.fromOffset(34, 0), Size = UDim2.new(0, 160, 1, 0) })
    Theme.bind(status, "TextColor3", "muted")
    Glow.add(status, { Base = "muted", Shine = "heading", GlowTransparency = 0.92 })
    local centre = label(footer, tostring(self.cfg.Footer or ""), 9, {
        Name = "Centre", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(1, -240, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    Theme.bind(centre, "TextColor3", "muted")
    self.footer, self.statusDot, self.statusLabel, self.footerText = footer, dot, status, centre
    if self.cfg.Footer == nil then
        task.spawn(function()
            local ok, info = pcall(function() return Services.MarketplaceService:GetProductInfo(game.PlaceId) end)
            if ok and type(info) == "table" and info.Name and centre.Parent and centre.Text == "" then centre.Text = tostring(info.Name) end
        end)
    end
    local grip = create("TextButton", {
        Name = "ResizeGrip", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -4, 1, -4), Size = UDim2.fromOffset(18, 18), ZIndex = 10, Parent = main,
    })
    for _, line in ipairs({ { 10, 10, 9 }, { 13, 13, 4 } }) do
        local mark = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(line[1], line[2]), Size = UDim2.fromOffset(line[3], 1),
            Rotation = -45, BorderSizePixel = 0, ZIndex = 11, Parent = grip,
        })
        Theme.bind(mark, "BackgroundColor3", "muted")
    end
    self.grip = grip

    ---------------------------------------------------------------- dock
    local dock = create("CanvasGroup", { Name = "Dock", Size = UDim2.fromOffset(DOCK_WIDTH, DOCK_TOP), BorderSizePixel = 0, BackgroundTransparency = 0.03, ZIndex = 40, ClipsDescendants = true, Parent = gui })
    Theme.bind(dock, "BackgroundColor3", "dock")
    corner(dock, 20)
    Theme.bind(stroke(dock), "Color", "line")
    self.dock = dock
    self.dockScale = create("UIScale", { Scale = 1, Parent = dock })
    -- drag handle (three lines) at the top of the dock moves the window like the header
    local dockGrip = create("TextButton", { Name = "DragHandle", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromOffset(5, 6), Size = UDim2.fromOffset(30, 28), ZIndex = 42, Parent = dock })
    for _, lineY in ipairs({ 9, 13, 17 }) do
        local bar = create("Frame", { Position = UDim2.fromOffset(9, lineY), Size = UDim2.fromOffset(12, 1), BorderSizePixel = 0, ZIndex = 43, Parent = dockGrip })
        Theme.bind(bar, "BackgroundColor3", "muted")
    end
    self.dockGrip, self.dockDividers = dockGrip, {}

    ---------------------------------------------------------------- tooltip
    local tip = create("Frame", { Name = "Tooltip", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 22), BorderSizePixel = 0, Visible = false, ZIndex = 300, Parent = gui })
    Theme.bind(tip, "BackgroundColor3", "card")
    corner(tip, 6)
    Theme.bind(stroke(tip), "Color", "line")
    Util.padding(tip, 8, 8, 0, 0)
    local tipText = label(tip, "", 10, { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), ZIndex = 301, TextTruncate = Enum.TextTruncate.None })
    Theme.bind(tipText, "TextColor3", "heading")
    self.tip, self.tipText = tip, tipText

    ---------------------------------------------------------------- behaviour
    local function moveWindow(input)
        if not Util.isPress(input) then return end
        local start, origin = Util.pointer(input), self.topLeft
        self:_hideTip()
        self:_beginDrag(input, function(point)
            self.topLeft = origin + (point - start)
            self:_layout()
        end, function() self:_saveMemory() end)
    end
    maid:connect(header.InputBegan, moveWindow)
    maid:connect(dockGrip.InputBegan, moveWindow)
    maid:connect(dockGrip.MouseEnter, function() self:_dockTip("Drag", 6) end)
    maid:connect(dockGrip.MouseLeave, function() self:_hideTip() end)
    maid:connect(grip.InputBegan, function(input)
        if not Util.isPress(input) or self.folded then return end
        local start, width, height = Util.pointer(input), self.width, self.height
        self:_beginDrag(input, function(point)
            local s = self.scale.Scale
            self.width = math.clamp(math.floor(width + (point.X - start.X) / s), self.minSize.X, self.maxSize.X)
            self.height = math.clamp(math.floor(height + (point.Y - start.Y) / s), self.minSize.Y, self.maxSize.Y)
            self:_layout()
        end, function() self:_saveMemory() end)
    end)
    maid:connect(minimize.Activated, function() self:Minimize() end)
    -- X closes straight away (no extra popup) and says how to get the menu back.
    -- CloseAction = "Destroy" unloads the whole UI instead of hiding it.
    maid:connect(close.Activated, function()
        if self.cfg.CloseAction == "Destroy" then
            self:Notify({ Title = self.Title, Content = "Unloaded" })
            self:Destroy()
            return
        end
        self:SetVisible(false)
        local how = self.mobileButton and "Tap the " .. self.Title .. " button to open it again" or ("Press " .. Util.keyName(self.key) .. " to open it again")
        self:Notify({ Title = self.Title .. " hidden", Content = how })
    end)

    local UserInputService = Services.UserInputService
    maid:connect(UserInputService.InputChanged, function(input)
        local drag = self._drag
        if not drag then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or (input.UserInputType == Enum.UserInputType.Touch and input == drag.input) then
            Util.safe(drag.move, Util.pointer(input))
        end
    end)
    maid:connect(UserInputService.InputEnded, function(input)
        local drag = self._drag
        if drag and (input.UserInputType == Enum.UserInputType.MouseButton1 or input == drag.input) then
            self._drag = nil
            Util.safe(drag.finish)
        end
    end)
    -- key let go: hold-mode binds (Keybind Mode = "Hold", Toggle BindMode = "Hold")
    maid:connect(UserInputService.InputEnded, function(input)
        local key = Util.inputKey(input, true)
        if not key then return end
        for element, bound in pairs(self.binds) do
            if element._onRelease and element.Row and element.Row.Parent then
                local target = element.Chord and element.Chord[2] or bound
                if target == key then self:_safe(element.Title or "Keybind", element._onRelease, element) end
            end
        end
    end)
    maid:connect(UserInputService.InputBegan, function(input, processed)
        -- 1. a keybind waiting for a key takes the next key
        if self._capture then
            local key = Util.inputKey(input, self._captureMouse)
            if key then
                local capture = self._capture
                self._capture = nil
                Util.safe(capture, key)
                return
            end
        end
        -- 2. clicks outside an open popup close it
        if self._popup and Util.isPress(input) then
            local point = Util.pointer(input)
            local function inside(object)
                if not object or not object.Parent then return false end
                local p, s = Util.screenPos(object), object.AbsoluteSize
                return point.X >= p.X and point.X <= p.X + s.X and point.Y >= p.Y and point.Y <= p.Y + s.Y
            end
            if not inside(self._popup.frame) and not inside(self._popup.owner) then self:_closePopup() end
        end
        -- 3. Escape closes an open dialog, else an open popup (dropdown list, colour panel...)
        if self._dialog and input.KeyCode == Enum.KeyCode.Escape then self._dialog:Close() return end
        if self._popup and input.KeyCode == Enum.KeyCode.Escape then self:_closePopup() return end
        if processed or UserInputService:GetFocusedTextBox() then return end
        local key = Util.inputKey(input, true)
        if not key then return end
        -- 4. menu key, then toggle / keybind binds (chords like CTRL + M1 fire when their modifier is held)
        if key == self.key then self:Toggle() return end
        for element, bound in pairs(self.binds) do
            if element.Row and element.Row.Parent then
                local chord = element.Chord
                if chord then
                    if chord[2] == key and (chord[1] == nil or Util.isDown(chord[1])) then self:_safe(element.Title or "Keybind", element._onBind, element) end
                elseif bound == key and key ~= Enum.UserInputType.MouseButton1 then
                    self:_safe(element.Title or "Keybind", element._onBind, element)
                end
            end
        end
    end)

    if self.cfg.KeyHints ~= false then
        self.menuHint = self:KeyHint({ Title = "MENU", Side = "Right", Key = self.key, Menu = true, Callback = function(key) self:SetToggleKey(key) end })
    end

    local function watchCamera()
        local camera = workspace.CurrentCamera
        if camera then
            maid:connect(camera:GetPropertyChangedSignal("ViewportSize"), function()
                self:_layout()
                for _, place in ipairs(self._placers or {}) do Util.safe(place) end
            end)
        end
        self:_layout()
    end
    maid:connect(workspace:GetPropertyChangedSignal("CurrentCamera"), watchCamera)
    watchCamera()
end

-- Positions everything from width / height / topLeft and fits the window on small screens.
function Window:_layout()
    if not self.alive then return end
    local viewport = Util.viewport()
    local total = self.width + DOCK_GAP + DOCK_WIDTH
    -- the chosen UI scale (Settings / Window:SetUIScale), made smaller when the screen can't fit it
    local s = math.clamp(math.min(self.uiScale or 1, (viewport.X - 24) / total, (viewport.Y - 24) / self.height), 0.4, 1.5)
    self.scale.Scale, self.dockScale.Scale = s, s
    local height = self.folded and HEADER or self.height
    self.main.Size = UDim2.fromOffset(self.width, height)
    if not self.topLeft then
        local saved = self.memory and self.memory.window
        if type(saved) == "table" and tonumber(saved.x) and tonumber(saved.y) then
            local room = Vector2.new(viewport.X - total * s, viewport.Y - self.height * s)
            self.topLeft = Vector2.new(tonumber(saved.x) * room.X, tonumber(saved.y) * room.Y)
        else
            self.topLeft = Vector2.new((viewport.X - total * s) / 2, (viewport.Y - self.height * s) / 2)
        end
    end
    local x = math.clamp(self.topLeft.X, 8, math.max(8, viewport.X - total * s - 8))
    local y = math.clamp(self.topLeft.Y, 8, math.max(8, viewport.Y - height * s - 8))
    self.topLeft = Vector2.new(x, y)
    self.main.Position = UDim2.fromOffset(x, y)
    self.dock.Size = UDim2.fromOffset(DOCK_WIDTH, self.dockHeight or DOCK_TOP)
    self.dock.Position = UDim2.fromOffset(x + (self.width + DOCK_GAP) * s, y)
    self.dock.Visible = self.main.Visible and not self.folded and #self.Tabs > 0
    self.grip.Visible = not self.folded
    for _, tab in ipairs(self.Tabs) do for _, page in ipairs(tab.Pages) do page:_columns(self.width) end end
    self:_updateLocation()
end

-- Saves position (as a 0-1 fraction of the free screen space) and size; written at most twice a second.
function Window:_saveMemory()
    if self.cfg.SaveWindow == false or not self.alive then return end
    local viewport = Util.viewport()
    local s = self.scale.Scale
    local room = Vector2.new(math.max(1, viewport.X - (self.width + DOCK_GAP + DOCK_WIDTH) * s), math.max(1, viewport.Y - self.height * s))
    self.memory.window = {
        x = math.clamp(self.topLeft.X / room.X, 0, 1), y = math.clamp(self.topLeft.Y / room.Y, 0, 1), w = self.width, h = self.height,
    }
    if self._memoryQueued then return end
    self._memoryQueued = true
    task.delay(0.5, function()
        self._memoryQueued = false
        if self.alive then self.Config:WriteMemory(self.memory) end
    end)
end

function Window:_beginDrag(input, move, finish)
    self._drag = { input = input, move = move, finish = finish }
end

function Window:_openPopup(frame, owner, onClose)
    if self._popup and self._popup.frame ~= frame then self:_closePopup() end
    self._popup = { frame = frame, owner = owner, close = onClose }
end
function Window:_closePopup()
    local popup = self._popup
    self._popup = nil
    if popup then Util.safe(popup.close) end
end

-- Dock slots: drag handle, then one button per tab (37 px apart) with a divider above tabs marked Divider.
function Window:_layoutDock()
    for _, divider in ipairs(self.dockDividers) do divider:Destroy() end
    self.dockDividers = {}
    local cursor = DOCK_TOP
    for _, tab in ipairs(self.Tabs) do
        if tab.Divider then
            local divider = create("Frame", { Name = "Divider", Position = UDim2.fromOffset(9, cursor + 1), Size = UDim2.fromOffset(22, 1), BorderSizePixel = 0, ZIndex = 42, Parent = self.dock })
            Theme.bind(divider, "BackgroundColor3", "line")
            self.dockDividers[#self.dockDividers + 1] = divider
            cursor = cursor + 8
        end
        tab.y = cursor
        tab.button.Position = UDim2.fromOffset(5, cursor)
        cursor = cursor + DOCK_STEP
    end
    self.dockHeight = cursor + 8
end

-- Page area: below the strip (if the open tab has pages) and above the key hint bar (if there are hints).
function Window:_layoutBody()
    local tab = self.current
    local top = (tab and #tab.Pages > 1) and 38 or 6
    local bottom = self.hintBar.Visible and HINTS or 0
    self.pages.Position = UDim2.fromOffset(0, top)
    self.pages.Size = UDim2.new(1, 0, 1, -(top + bottom))
end

-- Header right side: the header tabs while one of them is open, otherwise "Tab › Page".
-- Width of the title row (logo, title, version badge, tags).
function Window:_titleWidth()
    local layout = self.titleRow and self.titleRow:FindFirstChildOfClass("UIListLayout")
    local ok, measured = pcall(function() return layout.AbsoluteContentSize.X end)
    if ok and type(measured) == "number" and measured > 0 then return measured / (self.scale and self.scale.Scale or 1) end
    -- (before the first layout pass: an estimate from the texts)
    local width = Util.textWidth(self.Title, 16, Enum.Font.GothamMedium) * 1.05
    if self.logo then width = width + 24 end
    if self.Version ~= "" then width = width + Util.textWidth(self.Version, 9) + 18 end
    for _, child in ipairs(self.titleRow and self.titleRow:GetChildren() or {}) do
        if child.Name == "Tag" and child.Visible then
            local text = child:FindFirstChild("Text")
            width = width + (text and Util.textWidth(text.Text, 8, Enum.Font.GothamBold) or 20) + 18
        end
    end
    return width
end

function Window:_updateLocation()
    local tab = self.current
    -- room between the title row and the header buttons
    local room = self.width - (self.headerRight or 90) - 16 - self:_titleWidth() - 16
    local tabsWidth = 0
    for _, item in ipairs(self._headerButtons or {}) do tabsWidth = tabsWidth + item.button.Size.X.Offset + 6 end
    local onHeaderTab = tab ~= nil and tab.Header and self.cfg.HeaderTabs ~= false
    self.headerTabs.Visible = onHeaderTab and room >= tabsWidth
    for _, item in ipairs(self._headerButtons or {}) do
        local selected = item.tab == tab
        Theme.tweenTo(item.button, "TextColor3", selected and "heading" or "muted", 0.12)
        item.line.Visible = selected
    end
    if not tab then self.locationLabel.Text = "" return end
    local page = tab.current
    self.locationLabel.Text = (page and #tab.Pages > 1) and (tab.Title .. " › " .. page.Name) or tab.Title
    self.locationLabel.Visible = room >= 60 and not self.headerTabs.Visible
    -- never wider than the free room (tags / long titles), and leave the middle to the header stats
    local share = math.floor(self.width * (self.monitorMode == "Header" and 0.25 or 0.45))
    self.locationLabel.Size = UDim2.fromOffset(math.max(0, math.min(share, room)), 20)
end

function Window:_addHeaderTab(tab)
    local width = math.max(56, Util.textWidth(tab.Title, 11, Enum.Font.GothamMedium) + 14)
    local button = create("TextButton", {
        Name = tab.Title, Text = tab.Title, TextSize = 11, Font = Enum.Font.GothamMedium, AutoButtonColor = false,
        BackgroundTransparency = 1, Size = UDim2.fromOffset(width, HEADER), LayoutOrder = #(self._headerButtons or {}) + 1,
        Parent = self.headerTabs,
    })
    Theme.bind(button, "TextColor3", "muted")
    local line = create("Frame", { Name = "SelectionLine", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(1, -14, 0, 2), BorderSizePixel = 0, Visible = false, Parent = button })
    Theme.bind(line, "BackgroundColor3", "accent")
    button.Activated:Connect(function() tab:Select() end)
    self._headerButtons = self._headerButtons or {}
    table.insert(self._headerButtons, { tab = tab, button = button, line = line })
end

function Window:_dockTip(text, y)
    local s = self.scale.Scale
    local dockX = self.dock.Position.X.Offset
    local top = self.dock.Position.Y.Offset + (y + 5) * s
    self.tipText.Text = text
    if dockX + (DOCK_WIDTH + 8) * s + 150 > Util.viewport().X then
        self.tip.AnchorPoint = Vector2.new(1, 0)
        self.tip.Position = UDim2.fromOffset(dockX - 8, top)
    else
        self.tip.AnchorPoint = Vector2.new(0, 0)
        self.tip.Position = UDim2.fromOffset(dockX + (DOCK_WIDTH + 8) * s, top)
    end
    self.tip.Visible = true
end
-- Tooltip next to the mouse (locked elements show why they are locked).
function Window:_tip(text)
    local mouse = Services.UserInputService:GetMouseLocation()
    local viewport = Util.viewport()
    self.tipText.Text = tostring(text)
    self.tip.AnchorPoint = Vector2.new(mouse.X > viewport.X - 220 and 1 or 0, 0)
    self.tip.Position = UDim2.fromOffset(mouse.X + (mouse.X > viewport.X - 220 and -12 or 14), math.min(mouse.Y + 14, viewport.Y - 30))
    self.tip.Visible = true
    -- touch screens never send MouseLeave: the tip goes away by itself
    local token = {}
    self._tipToken = token
    task.delay(4, function() if self._tipToken == token and self.alive then self.tip.Visible = false end end)
end
function Window:_hideTip() self.tip.Visible = false end

function Window:_register(flag, element)
    if self.flags[flag] then Util.log("[qustah-ui-lib] duplicate flag: " .. tostring(flag)) end
    self.flags[flag] = element
    -- after the element finished building: record its default, apply a value loaded before it existed
    task.defer(function()
        if self.alive and self.flags[flag] == element then self.Config:_elementReady(flag, element) end
    end)
end
-- AutoFlags = true: elements without a Flag get "Tab.Card.Title" (a second one with the same name gets " 2").
function Window:_autoFlag(card, title)
    local parts = {}
    local tab = card.page and card.page.tab
    if tab and tab.Title then parts[#parts + 1] = tab.Title end
    if card.title then parts[#parts + 1] = card.title end
    parts[#parts + 1] = tostring(title)
    local flag = table.concat(parts, "."):gsub("[^%w_%.%- ]", "")
    local name, index = flag, 2
    while self.flags[name] or (self._autoNames and self._autoNames[name]) do name = flag .. " " .. index index = index + 1 end
    self._autoNames = self._autoNames or {}
    self._autoNames[name] = true
    return name
end

-- Window.Flags.Speed = 50 sets the element (UI and callback); Window.Flags.Speed reads the value; pairs() works.
-- Window:SetFlag(flag, value), :GetFlag(flag), :GetElement(flag)
function Window:_makeFlags()
    local window = self
    local function snapshot()
        local values = {}
        for flag in pairs(window.flags) do values[flag] = window.Lib.Flags[flag] end
        return values
    end
    self.Flags = setmetatable({}, {
        __index = function(_, flag) return window.Lib.Flags[flag] end,
        __newindex = function(_, flag, value) window:SetFlag(flag, value) end,
        __iter = function() return next, snapshot() end,
        __pairs = function() return next, snapshot() end,
    })
end
function Window:SetFlag(flag, value)
    if flag == nil then return false end
    local element = self.flags[flag]
    if element and element.Set then
        element:Set(value)
        return true
    end
    -- not built yet (or no element): applied when it is created, like a loaded profile
    self.Config.pending[flag] = value
    self.Lib.Flags[flag] = value
    self:_flagChanged(flag)
    return false
end
function Window:GetFlag(flag) return self.Lib.Flags[flag] end
function Window:GetElement(flag) return self.flags[flag] end

-- A flag changed: elements / cards with DependsOn re-check (watchers whose object is gone drop out).
function Window:_flagChanged()
    local list = self._dependents
    if not list or self._checkingDependents then return end
    self._checkingDependents = true -- (a dependent locking an element must not re-enter)
    for index = #list, 1, -1 do
        local ok, keep = pcall(list[index])
        if ok and keep == false then table.remove(list, index) end
    end
    self._checkingDependents = false
end

function Window:_bind(element, key)
    self.binds[element] = key
    -- one check for all bind changes in this frame
    if not self._keyCheckQueued then
        self._keyCheckQueued = true
        task.defer(function()
            self._keyCheckQueued = false
            if self.alive ~= false then self:_checkKeys() end
        end)
    end
end

-- Key conflicts: two binds (toggles, buttons, keybinds, key hints) on the same key - or one on the menu key - are
-- marked on each element (yellow key tag, "Key also used by ..." on hover). A conflict made after the start also
-- gets a notification. Window:GetKeyConflicts() -> { [keyName] = { titles } }.
function Window:_checkKeys()
    local groups = {}
    for element, key in pairs(self.binds) do
        if element.Row and not element.Row.Parent then
            self.binds[element] = nil
        elseif key ~= nil and not (element.Chord and element.Chord[1] ~= nil)
            and not (type(element.Flag) == "string" and element.Flag:sub(1, 2) == "__") then -- (Settings' own "Menu key" is the menu key)
            groups[key] = groups[key] or {}
            table.insert(groups[key], element)
        end
    end
    local conflicts, seen = {}, {}
    for key, list in pairs(groups) do
        local menu = key == self.key
        if #list > 1 or menu then
            local names = {}
            for _, element in ipairs(list) do names[#names + 1] = tostring(element.Title or element.Type or "Key") end
            if menu then names[#names + 1] = "Menu" end
            table.sort(names)
            conflicts[Util.keyName(key)] = names
            for _, element in ipairs(list) do
                local others = {}
                local own = tostring(element.Title or element.Type or "Key")
                local skipped = false
                for _, name in ipairs(names) do
                    if name == own and not skipped then skipped = true else others[#others + 1] = name end
                end
                seen[element] = true
                if element._setConflict then pcall(element._setConflict, element, others) end
            end
        end
    end
    for element in pairs(self.binds) do
        if not seen[element] and element.KeyConflict and element._setConflict then pcall(element._setConflict, element, nil) end
    end
    -- tell about new conflicts (not the ones the script starts with)
    local before = self._keyConflicts or {}
    if self._keysSettled then
        for keyName, names in pairs(conflicts) do
            if not before[keyName] or #before[keyName] < #names then
                self:Notify({ Title = "Key conflict", Content = keyName .. " is used by " .. table.concat(names, " and "), Icon = "triangle-alert", Color = "warning", History = false })
            end
        end
    end
    self._keyConflicts = conflicts
end
function Window:GetKeyConflicts() return self._keyConflicts or {} end

-------------------------------------------------------------------------------- public API
function Window:Tab(cfg)
    if type(cfg) == "string" then cfg = { Title = cfg } end
    local tab = Tab.new(self, cfg or {})
    self.Tabs[#self.Tabs + 1] = tab
    if tab.Header then self:_addHeaderTab(tab) end
    self:_layoutDock()
    self:_layout()
    if not self.current then tab:Select() end
    return tab
end

function Window:SetVisible(visible)
    self.visible = visible
    self:_closePopup()
    if not visible and self._dialog then self._dialog:Close() end
    self:_hideTip()
    self._token = (self._token or 0) + 1
    local token = self._token
    if visible then
        self.main.Visible = true
        Util.fade(self.main, 0.14, 0)
        Util.fade(self.dock, 0.14, 0)
        self:_layout()
    else
        self._drag = nil
        Util.fade(self.main, 0.12, 1)
        Util.fade(self.dock, 0.12, 1)
        task.delay(0.13, function()
            if self.alive and token == self._token and not self.visible then
                self.main.Visible = false
                self.dock.Visible = false
            end
        end)
    end
end
function Window:Toggle() self:SetVisible(not self.visible) end

-- Window:SetUIScale(1.1): the whole menu bigger / smaller (0.6 - 1.5); remembered on this PC.
function Window:SetUIScale(value)
    value = math.clamp(tonumber(value) or 1, 0.6, 1.5)
    self.uiScale = value
    self:_closePopup()
    self:_layout()
    if self.memory then
        self.memory.uiScale = value ~= 1 and value or nil
        self:_saveMemory()
    end
end
function Window:GetUIScale() return self.uiScale or 1 end

function Window:Minimize()
    self.folded = not self.folded
    self:_closePopup()
    self.body.Visible = not self.folded
    self.footer.Visible = not self.folded
    self:_layout()
end

-- Window:KeyHint({ Title = "ESP / SILENT AIM", Key = Enum.KeyCode.KeypadEight, Side = "Left" | "Right",
--                  Pressed = function(key) end, Callback = function(newKey) end, Flag })
-- A key badge with a caption above the footer; click the badge to rebind (Backspace clears, Escape cancels).
function Window:KeyHint(cfg)
    cfg = cfg or {}
    local right = cfg.Side == "Right"
    local group = create("Frame", {
        Name = tostring(cfg.Title or "Hint"), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 26), LayoutOrder = #self.hints + 1, Parent = right and self.hintRight or self.hintLeft,
    })
    Util.list(group, 8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    local badge = create("TextButton", {
        Name = "Key", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", TextSize = 10,
        Font = Enum.Font.GothamMedium, Size = UDim2.fromOffset(48, 22), LayoutOrder = right and 3 or 1, Parent = group,
    })
    Theme.bind(badge, "TextColor3", "text")
    corner(badge, 6)
    local outline = stroke(badge, nil, 0.25)
    Theme.bind(outline, "Color", "line")
    local dot = label(group, "•", 10, { Name = "Dot", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 20), LayoutOrder = 2, TextTruncate = Enum.TextTruncate.None })
    Theme.bind(dot, "TextColor3", "muted")
    local caption = label(group, tostring(cfg.Title or ""), 9, { Name = "Caption", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 20), LayoutOrder = right and 1 or 3, TextTruncate = Enum.TextTruncate.None })
    Theme.bind(caption, "TextColor3", "muted")

    local window = self
    local hint = { Type = "KeyHint", Title = cfg.Title, Row = group, Flag = cfg.Flag }
    local function show(text)
        badge.Text = text
        badge.Size = UDim2.fromOffset(math.max(48, Util.textWidth(text, 10, Enum.Font.GothamMedium) + 18), 22)
    end
    function hint:Set(key, silent)
        key = Util.toKey(key)
        if cfg.Menu and not key then key = window.key end
        self.Value = key
        show(Util.keyName(key))
        if not cfg.Menu then window:_bind(self, key) end
        if self.Flag then window.Lib.Flags[self.Flag] = key window:_flagChanged(self.Flag) end
        if not silent then window:_safe(tostring(cfg.Title or "Key"), cfg.Callback, key) end
    end
    function hint:Get() return self.Value end
    function hint:SetTitle(text) caption.Text = tostring(text) end
    function hint:_onBind() window:_safe(tostring(cfg.Title or "Key"), cfg.Pressed, self.Value) end
    function hint:_setConflict(others)
        local on = others ~= nil and #others > 0
        self.KeyConflict = on and others or nil
        Theme.bind(badge, "TextColor3", on and "warning" or "text")
        Theme.bind(outline, "Color", on and "warning" or "line")
    end
    function hint:_save() return self.Value and self.Value.Name or "None" end
    function hint:_load(value) self:Set(value) end
    badge.MouseEnter:Connect(function() Util.tween(outline, 0.12, { Transparency = 0.1 }) end)
    badge.MouseLeave:Connect(function() Util.tween(outline, 0.12, { Transparency = 0.25 }) end)
    badge.Activated:Connect(function()
        show("...")
        window._capture = function(key)
            -- Escape cancels; another hint can't take the menu key
            if key == Enum.KeyCode.Escape or (not cfg.Menu and key == window.key) then hint:Set(hint.Value, true)
            elseif key == Enum.KeyCode.Backspace and not cfg.Menu then hint:Set(nil)
            else hint:Set(key) end
        end
    end)
    if cfg.Flag then self:_register(cfg.Flag, hint) end
    self.hints[#self.hints + 1] = hint
    self.hintBar.Visible = true
    self:_layoutBody()
    hint:Set(cfg.Key, true)
    return hint
end

-- Changes the menu key everywhere (menu key hint, Settings tab).
-- Builds every lazy tab now (before a full profile export, for example).
function Window:BuildAll()
    for _, tab in ipairs(self.Tabs) do if tab._build then tab:Build() end end
end

function Window:SetToggleKey(key)
    key = Util.toKey(key)
    if not key then -- the menu always needs a key: put the current one back on every display
        if self.menuHint then self.menuHint:Set(self.key, true) end
        for _, listener in ipairs(self._menuListeners or {}) do Util.safe(listener, self.key) end
        return
    end
    self.key = key
    task.defer(function() if self.alive then self:_checkKeys() end end)
    if self.menuHint and self.menuHint.Value ~= key then self.menuHint:Set(key, true) end
    for _, listener in ipairs(self._menuListeners or {}) do Util.safe(listener, key) end
end
function Window:SetFooter(text) self.footerText.Text = tostring(text or "") end
function Window:Notify(cfg) return self.Lib:Notify(cfg) end
function Window:Toast(cfg) return self.Lib:Toast(cfg) end
function Window:SelectTab(target)
    for _, tab in ipairs(self.Tabs) do
        if tab == target or tab.Title == target then tab:Select() return tab end
    end
end

function Window:Destroy()
    if not self.alive then return end
    self.alive = false
    self._drag, self._capture = nil, nil
    self.maid:clean()
    local env = (getgenv and getgenv()) or _G
    if env.__QustahUIWindows and env.__QustahUIWindows[self.Title] == self then env.__QustahUIWindows[self.Title] = nil end
    for index, window in ipairs(self.Lib.Windows) do
        if window == self then table.remove(self.Lib.Windows, index) break end
    end
    Util.safe(self.cfg.OnClose)
end

return Window
