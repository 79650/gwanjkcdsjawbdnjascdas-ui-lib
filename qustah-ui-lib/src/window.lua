-- Window shell (Qustah layout): header (title, version badge, "Tab › Page" location, minimize / close), sub-page
-- strip, scrolling pages with two card columns, key hint bar, footer (status, centre text, resize grip) and the
-- dock to the right (drag handle, tab icons, group dividers).
local Util = require("util")
local Theme = require("theme")
local Card = require("card")
local Config = require("config")

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
    -- Margins come from the content frame's position / size, not from a UIPadding on the ScrollingFrame:
    -- Roblox sizes scale children of a padded ScrollingFrame from the unpadded width, which pushed the right
    -- column past the window edge.
    local content = create("Frame", {
        Name = "Content", BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 2), Size = UDim2.new(1, -30, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, Parent = frame,
    })
    Util.list(content, 10)
    Util.padding(content, 0, 0, 0, 14)
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
    self.frame, self.wide, self.left, self.right = frame, wide, column("Left", 1), column("Right", 2)

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
-- left / right; Wide cards span both columns and sit above them.
function Page:Card(cfg)
    cfg = cfg or {}
    self.cards = self.cards + 1
    local side = cfg.Side
    if self.cfg.Columns == 1 then side = "Left" end
    if side ~= "Left" and side ~= "Right" then side = (self.cards % 2 == 1) and "Left" or "Right" end
    self.order = self.order + 1
    if cfg.Wide then
        self.cards = self.cards - 1 -- a wide card does not take a turn in the left / right alternation
        return Card.new(self, self.wide, cfg, self.order)
    end
    return Card.new(self, side == "Right" and self.right or self.left, cfg, self.order)
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

    self.Divider = cfg.Divider == true or window._dividerNext == true -- a short line above this tab in the dock
    window._dividerNext = nil
    local button = create("TextButton", {
        Name = self.Title .. "Tab", BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0,
        Position = UDim2.fromOffset(5, DOCK_TOP), Size = UDim2.fromOffset(DOCK_BUTTON, DOCK_BUTTON), ZIndex = 42, Parent = window.dock,
    })
    Theme.bind(button, "BackgroundColor3", "accentDeep")
    corner(button, 15)
    local icon
    local image = cfg.Icon
    if type(image) == "number" or (type(image) == "string" and image:match("^%d+$")) then image = "rbxassetid://" .. tostring(image) end
    if type(image) == "string" and image ~= "" then
        icon = create("ImageLabel", {
            Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 18),
            BackgroundTransparency = 1, Image = image, ScaleType = Enum.ScaleType.Fit, ZIndex = 43, Parent = button,
        })
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
    button.Activated:Connect(function() window:_hideTip() self:Select() end)
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

function Tab:Select()
    local window = self.window
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

    -- Running the same script again replaces its old window instead of stacking a second one.
    local env = (getgenv and getgenv()) or _G
    env.__QustahUIWindows = env.__QustahUIWindows or {}
    local previous = env.__QustahUIWindows[self.Title]
    if previous and previous.Destroy then pcall(previous.Destroy, previous) end
    env.__QustahUIWindows[self.Title] = self

    if typeof(cfg.Accent) == "Color3" then Theme.set("accent", cfg.Accent) end
    self:_build()
    self.Config = Config.new(self, cfg.Folder or self.Title:gsub("[^%w_%- ]", ""))
    Lib.Windows[#Lib.Windows + 1] = self
    return self
end

function Window:_build()
    local maid = self.maid
    local gui = Util.screenGui("QustahUI_" .. self.Title:gsub("%W", ""), 50)
    maid:give(gui)
    self.gui = gui

    local main = create("CanvasGroup", {
        Name = "Window", Size = UDim2.fromOffset(self.width, self.height), BorderSizePixel = 0,
        GroupTransparency = 0, ClipsDescendants = true, Parent = gui,
    })
    Theme.bind(main, "BackgroundColor3", "base")
    corner(main, 12)
    Theme.bind(stroke(main), "Color", "edge")
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
    self.titleLabel = title

    local function windowButton(name, offset, cross)
        local button = create("TextButton", {
            Name = name, Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
            Position = UDim2.new(1, offset, 0, 8), Size = UDim2.fromOffset(30, 28), Parent = main,
        })
        corner(button, 6)
        Theme.bind(button, "BackgroundColor3", "input")
        local bars = {}
        for _, rotation in ipairs(cross and { 45, -45 } or { 0 }) do
            local bar = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 2),
                Rotation = rotation, BorderSizePixel = 0, Parent = button,
            })
            corner(bar, 1)
            Theme.bind(bar, "BackgroundColor3", "muted")
            bars[#bars + 1] = bar
        end
        button.MouseEnter:Connect(function()
            tween(button, 0.12, { BackgroundTransparency = 0, BackgroundColor3 = cross and Color3.fromRGB(60, 24, 26) or Theme.get("input") })
            for _, bar in ipairs(bars) do Theme.tweenTo(bar, "BackgroundColor3", cross and Color3.fromRGB(235, 90, 90) or "heading", 0.12) end
        end)
        button.MouseLeave:Connect(function()
            tween(button, 0.12, { BackgroundTransparency = 1 })
            for _, bar in ipairs(bars) do Theme.tweenTo(bar, "BackgroundColor3", "muted", 0.12) end
        end)
        return button
    end
    local minimize = windowButton("Minimize", -74, false)
    local close = windowButton("Close", -40, true)
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
        Name = "Location", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -90, 0, 12), Size = UDim2.new(0.45, 0, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    Theme.bind(location, "TextColor3", "muted")
    self.locationLabel = location

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
    local dot = create("Frame", { Name = "StatusDot", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 22, 0.5, 0), Size = UDim2.fromOffset(5, 5), BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(82, 207, 132), Parent = footer })
    corner(dot, 3)
    local status = label(footer, "Connected", 9, { Name = "Status", Position = UDim2.fromOffset(32, 0), Size = UDim2.new(0, 150, 1, 0) })
    Theme.bind(status, "TextColor3", "muted")
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
        end)
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
        end)
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
        self:Notify({ Title = self.Title .. " hidden", Content = "Press " .. Util.keyName(self.key) .. " to open it again" })
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
    maid:connect(UserInputService.InputBegan, function(input, processed)
        -- 1. a keybind waiting for a key takes the next key
        if self._capture then
            local key = Util.inputKey(input)
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
                local p, s = object.AbsolutePosition, object.AbsoluteSize
                return point.X >= p.X and point.X <= p.X + s.X and point.Y >= p.Y and point.Y <= p.Y + s.Y
            end
            if not inside(self._popup.frame) and not inside(self._popup.owner) then self:_closePopup() end
        end
        if processed or UserInputService:GetFocusedTextBox() then return end
        local key = Util.inputKey(input)
        if not key then return end
        -- 3. menu key, then toggle / keybind binds
        if key == self.key then self:Toggle() return end
        for element, bound in pairs(self.binds) do
            if bound == key and element.Row and element.Row.Parent then Util.safe(element._onBind, element) end
        end
    end)

    if self.cfg.KeyHints ~= false then
        self.menuHint = self:KeyHint({ Title = "MENU", Side = "Right", Key = self.key, Menu = true, Callback = function(key) self:SetToggleKey(key) end })
    end

    local function watchCamera()
        local camera = workspace.CurrentCamera
        if camera then maid:connect(camera:GetPropertyChangedSignal("ViewportSize"), function() self:_layout() end) end
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
    local s = math.clamp(math.min(1, (viewport.X - 24) / total, (viewport.Y - 24) / self.height), 0.4, 1)
    self.scale.Scale, self.dockScale.Scale = s, s
    local height = self.folded and HEADER or self.height
    self.main.Size = UDim2.fromOffset(self.width, height)
    if not self.topLeft then
        self.topLeft = Vector2.new((viewport.X - total * s) / 2, (viewport.Y - self.height * s) / 2)
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
    self.locationLabel.Visible = self.width >= 440
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

function Window:_updateLocation()
    local tab = self.current
    if not tab then self.locationLabel.Text = "" return end
    local page = tab.current
    self.locationLabel.Text = (page and #tab.Pages > 1) and (tab.Title .. " › " .. page.Name) or tab.Title
    self.locationLabel.Visible = self.width >= 440
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
end
function Window:_hideTip() self.tip.Visible = false end

function Window:_register(flag, element)
    if self.flags[flag] then warn("[qustah-ui-lib] duplicate flag: " .. tostring(flag)) end
    self.flags[flag] = element
end
function Window:_bind(element, key)
    self.binds[element] = key
end

-------------------------------------------------------------------------------- public API
function Window:Tab(cfg)
    if type(cfg) == "string" then cfg = { Title = cfg } end
    local tab = Tab.new(self, cfg or {})
    self.Tabs[#self.Tabs + 1] = tab
    self:_layoutDock()
    self:_layout()
    if not self.current then tab:Select() end
    return tab
end

function Window:SetVisible(visible)
    self.visible = visible
    self:_closePopup()
    self:_hideTip()
    self._token = (self._token or 0) + 1
    local token = self._token
    if visible then
        self.main.Visible = true
        tween(self.main, 0.14, { GroupTransparency = 0 })
        tween(self.dock, 0.14, { GroupTransparency = 0 })
        self:_layout()
    else
        self._drag = nil
        tween(self.main, 0.12, { GroupTransparency = 1 })
        tween(self.dock, 0.12, { GroupTransparency = 1 })
        task.delay(0.13, function()
            if self.alive and token == self._token and not self.visible then
                self.main.Visible = false
                self.dock.Visible = false
            end
        end)
    end
end
function Window:Toggle() self:SetVisible(not self.visible) end

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
    local hint = { Type = "KeyHint", Row = group, Flag = cfg.Flag }
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
        if self.Flag then window.Lib.Flags[self.Flag] = key end
        if not silent then Util.safe(cfg.Callback, key) end
    end
    function hint:Get() return self.Value end
    function hint:SetTitle(text) caption.Text = tostring(text) end
    function hint:_onBind() Util.safe(cfg.Pressed, self.Value) end
    function hint:_save() return self.Value and self.Value.Name or "None" end
    function hint:_load(value) self:Set(value) end
    badge.MouseEnter:Connect(function() Util.tween(outline, 0.12, { Transparency = 0.1 }) end)
    badge.MouseLeave:Connect(function() Util.tween(outline, 0.12, { Transparency = 0.25 }) end)
    badge.Activated:Connect(function()
        show("...")
        window._capture = function(key)
            if key == Enum.KeyCode.Escape then hint:Set(hint.Value, true)
            elseif key == Enum.KeyCode.Backspace and not cfg.Menu then hint:Set(nil)
            elseif not cfg.Menu and key == window.key then hint:Set(hint.Value, true)
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
function Window:SetToggleKey(key)
    key = Util.toKey(key)
    if not key then -- the menu always needs a key: put the current one back on every display
        if self.menuHint then self.menuHint:Set(self.key, true) end
        for _, listener in ipairs(self._menuListeners or {}) do Util.safe(listener, self.key) end
        return
    end
    self.key = key
    if self.menuHint and self.menuHint.Value ~= key then self.menuHint:Set(key, true) end
    for _, listener in ipairs(self._menuListeners or {}) do Util.safe(listener, key) end
end
function Window:SetStatus(text, color)
    self.statusLabel.Text = tostring(text)
    if typeof(color) == "Color3" then self.statusDot.BackgroundColor3 = color end
end
function Window:SetFooter(text) self.footerText.Text = tostring(text or "") end
function Window:Notify(cfg) return self.Lib:Notify(cfg) end
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
