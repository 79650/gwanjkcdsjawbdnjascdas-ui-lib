-- Pages and tabs of the window: a tab is a dock icon with one or more pages (a strip switches them when there are
-- two or more); a page scrolls and lays its cards out in two columns (one below NARROW px). Used by window.lua.
local Util = require("util")
local Theme = require("theme")
local Card = require("card")
local Icons = require("icons")

local create, corner, stroke, label, tween = Util.create, Util.corner, Util.stroke, Util.label, Util.tween

local DOCK_BUTTON, DOCK_TOP = 30, 42
local NARROW = 470 -- below this width the two card columns stack

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
    local icon = Icons.themed(banner, opts.Icon or (level == "info" and "info" or "triangle-alert"), 14, role, { Name = "BannerIcon", Position = UDim2.fromOffset(0, 1) })
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

-- page:MatchHeights(cardA, cardB, ...): side-by-side cards grow to the tallest one (an empty spacer goes under the
-- shorter ones' last element), and follow when any of them changes height.
function Page:MatchHeights(...)
    local cards = { ... }
    local spacers = {}
    for index, card in ipairs(cards) do
        spacers[index] = create("Frame", { Name = "MatchSpacer", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 1e6, Visible = false, Parent = card.frame })
    end
    local busy = false
    -- the card's own height without the spacer (its list's content height; summed from the children if the
    -- engine has not measured it yet)
    local function natural(card, spacer)
        local scale = self.window.scale and self.window.scale.Scale or 1
        local layout = card.frame:FindFirstChildOfClass("UIListLayout")
        local gap = layout and layout.Padding.Offset or 4
        local content = layout and layout.AbsoluteContentSize.Y / scale or 0
        if content > 0 then
            if spacer.Visible then content = content - spacer.Size.Y.Offset - gap end
        else
            local count = 0
            for _, child in ipairs(card.frame:GetChildren()) do
                if child:IsA("GuiObject") and child.Visible and child ~= spacer then
                    content = content + child.AbsoluteSize.Y / scale
                    count = count + 1
                end
            end
            content = content + math.max(0, count - 1) * gap
        end
        return content
    end
    local function apply()
        if busy then return end
        busy = true
        local heights, tallest = {}, 0
        for index, card in ipairs(cards) do
            heights[index] = (card.frame.Visible and not card.Collapsed) and natural(card, spacers[index]) or 0
            tallest = math.max(tallest, heights[index])
        end
        for index, card in ipairs(cards) do
            local extra = math.floor(tallest - heights[index] - 4) -- (the spacer brings one list gap with it)
            local show = card.frame.Visible and not card.Collapsed and extra > 0
            spacers[index].Visible = show
            spacers[index].Size = UDim2.new(1, 0, 0, show and extra or 0)
        end
        busy = false
    end
    for _, card in ipairs(cards) do
        local layout = card.frame:FindFirstChildOfClass("UIListLayout")
        if layout then layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() task.defer(apply) end) end
        card.frame:GetPropertyChangedSignal("Visible"):Connect(function() task.defer(apply) end)
        card.frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() task.defer(apply) end)
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
    self.Hidden = cfg.Hidden == true -- not in the dock (Tab:SetHidden)
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

-- Takes the tab's icon out of the dock (and back); the tab still works from code (Select, SelectTab, Tour).
function Tab:SetHidden(hidden)
    self.Hidden = hidden == true
    self.window:_layoutDock()
    self.window:_layout()
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

return { Tab = Tab, Page = Page, DOCK_BUTTON = DOCK_BUTTON, DOCK_TOP = DOCK_TOP, NARROW = NARROW }
