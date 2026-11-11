-- qustah-ui-lib v1.15.0 | bundled from src/ by build.py - edit the source files, not this one.
-- local Lib = loadstring(game:HttpGet("<raw url>/dist/qustah-ui-lib.lua"))()
local __modules, __loaded = {}, {}
local function require(name)
    local loaded = __loaded[name]
    if loaded == nil then
        local module = __modules[name]
        if not module then error("[qustah-ui-lib] missing module: " .. tostring(name), 2) end
        loaded = module()
        __loaded[name] = loaded
    end
    return loaded
end

__modules["card"] = function()
-- A card: rounded panel with an optional title (accent dot + bold heading) that stacks its elements.
-- Every element constructor (Toggle, Slider, ...) is available as a method: card:Toggle({ ... }).
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

local Card = {}
Card.Elements = {
    Toggle      = require("elements/toggle"),
    Slider      = require("elements/slider"),
    Dropdown    = require("elements/dropdown"),
    Keybind     = require("elements/keybind"),
    ColorPicker = require("elements/colorpicker"),
    Input       = require("elements/input"),
    Button      = require("elements/button"),
    Label       = require("elements/label"),
    Paragraph   = require("elements/paragraph"),
    Divider     = require("elements/divider"),
    Segment     = require("elements/segment"),
    Info        = require("elements/info"),
    Range       = require("elements/range"),
    PlayerList  = require("elements/playerlist"),
    ImagePicker = require("elements/imagepicker"),
    Swatches    = require("elements/swatches"),
    Graph       = require("elements/graph"),
    Gradient    = require("elements/gradient"),
    Progress    = require("elements/progress"),
    Code        = require("elements/code"),
    Image       = require("elements/image"),
    Viewport    = require("elements/viewport"),
    ActionInput = require("elements/actioninput"),
    Stat        = require("elements/stat"),
    Console     = require("elements/console"),
    Checkbox    = require("elements/checkbox"),
    Radio       = require("elements/radio"),
    Table       = require("elements/table"),
    Stepper     = require("elements/stepper"),
    TextArea    = require("elements/textarea"),
    CrosshairPreview = require("elements/crosshairpreview"),
    FovPreview  = require("elements/fovpreview"),
    StatTiles   = require("elements/stattiles"),
    Gauges      = require("elements/gauges"),
    SwitchGrid  = require("elements/switchgrid"),
    Tiles       = require("elements/tiles"),
    Chips       = require("elements/chips"),
    Timeline    = require("elements/timeline"),
    Hero        = require("elements/hero"),
    Gallery     = require("elements/gallery"),
    ListItem    = require("elements/listitem"),
    Search      = require("elements/search"),
    SideNav     = require("elements/sidenav"),
    ItemCards   = require("elements/itemcards"),
    DiffList    = require("elements/difflist"),
    StatusBars  = require("elements/statusbars"),
    Checklist   = require("elements/checklist"),
    Notice      = require("elements/notice"),
    Changelog   = require("elements/changelog"),
    ThemePreview = require("elements/themepreview"),
}
Card.__index = function(_, key)
    local method = rawget(Card, key)
    if method ~= nil then return method end
    local constructor = Card.Elements[key]
    if constructor then
        return function(self, cfg)
            if type(cfg) == "string" then cfg = { Title = cfg } end
            return constructor(self, cfg or {})
        end
    end
    return nil
end

function Card.new(page, column, cfg, order)
    local self = setmetatable({ page = page, window = page.window, order = 0, title = cfg.Title }, Card)
    local frame = create("Frame", {
        Name = cfg.Title or "Card", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0, LayoutOrder = order or 0, Parent = column,
    })
    Theme.bind(frame, "BackgroundColor3", "card")
    corner(frame, 8)
    Theme.bind(stroke(frame), "Color", "line")
    Util.padding(frame, 14, 14, 8, 10)
    Util.list(frame, 4)
    if cfg.Title then
        -- accent dot with a soft glow + medium heading (Qustah card title); Icon = "name" replaces the dot
        local head = create("Frame", { Name = "Heading", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 0, Parent = frame })
        local icon = cfg.Icon and Icons.themed(head, cfg.Icon, 14, "accent", { Name = "CardIcon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -1, 0.5, 0) })
        -- Dot = false (or CreateWindow({ CardDots = false }) for every card): plain title when there is no icon
        local dotted = cfg.Dot
        if dotted == nil then dotted = not (page.window and page.window.cfg and page.window.cfg.CardDots == false) end
        local lead = icon and 18 or (dotted and 13 or 0)
        for ring = 3, ((icon or not dotted) and 4 or 0), -1 do
            local dot = create("Frame", {
                Name = ring == 0 and "Dot" or "Glow", Position = UDim2.fromOffset(-ring, 7 - ring), Size = UDim2.fromOffset(6 + ring * 2, 6 + ring * 2),
                BorderSizePixel = 0, BackgroundTransparency = ring == 0 and 0 or 0.91, Parent = head,
            })
            Theme.bind(dot, "BackgroundColor3", "accent")
            corner(dot, ring == 0 and 3 or 6)
        end
        local collapsible = cfg.Collapsible ~= false
        local title = label(head, tostring(cfg.Title), 10, { Position = UDim2.fromOffset(lead, 0), Size = UDim2.new(1, -lead - (collapsible and 22 or 0), 1, 0), Font = Enum.Font.GothamMedium })
        Theme.bind(title, "TextColor3", "heading")
        self.titleLabel = title
        -- Desc = "...": a muted line under the title
        if cfg.Desc then
            local desc = label(frame, tostring(cfg.Desc), 9, { Name = "CardDesc", Size = UDim2.new(1, 0, 0, 12), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextTruncate = Enum.TextTruncate.None, LayoutOrder = 1 })
            Theme.bind(desc, "TextColor3", "muted")
            self.descLabel = desc
        end
        -- collapse arrow (Collapsible = false removes it); the folded state is remembered per PC
        if collapsible then
            local arrow = create("TextButton", { Name = "Collapse", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 4, 0, 0), Size = UDim2.fromOffset(20, 20), Parent = head })
            local chevron = create("Frame", { Name = "Chevron", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 10), Parent = arrow })
            local bars = {}
            for index, rotation in ipairs({ 45, -45 }) do
                local bar = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(index == 1 and 3 or 7, 5), Size = UDim2.fromOffset(6, 1.5), Rotation = rotation, BorderSizePixel = 0, Parent = chevron })
                Theme.bind(bar, "BackgroundColor3", "muted")
                bars[#bars + 1] = bar
            end
            arrow.MouseEnter:Connect(function() for _, bar in ipairs(bars) do Theme.tweenTo(bar, "BackgroundColor3", "heading", 0.1) end end)
            arrow.MouseLeave:Connect(function() for _, bar in ipairs(bars) do Theme.tweenTo(bar, "BackgroundColor3", "muted", 0.1) end end)
            self._chevron = chevron
            arrow.Activated:Connect(function() self:SetCollapsed(not self.Collapsed) end)
        end
        self._key = tostring(page.tab and page.tab.Title or "") .. "/" .. tostring(page.Name or "") .. "/" .. tostring(cfg.Title)
    end
    self.frame, self.body = frame, frame
    -- an empty card (nothing added yet, or everything hidden by DependsOn / SetVisible) says so; Empty = false turns it off
    if cfg.Empty ~= false then
        local empty = label(frame, tostring(cfg.Empty or "Nothing here"), 10, {
            Name = "Empty", Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Center, Visible = false, LayoutOrder = 1,
        })
        Theme.bind(empty, "TextColor3", "muted")
        local queued = false
        local function check()
            queued = false
            if not frame.Parent then return end
            local any = false
            for _, child in ipairs(frame:GetChildren()) do
                if child:IsA("GuiObject") and child ~= empty and child.Name ~= "Heading" and child.Name ~= "CardDesc" and (child.Visible or (self._hidden and self._hidden[child])) then
                    any = true
                    break
                end
            end
            empty.Visible = not any and not self.Collapsed
        end
        local function queue()
            if queued then return end
            queued = true
            task.defer(check)
        end
        frame.ChildAdded:Connect(function(child)
            if child:IsA("GuiObject") and child ~= empty then child:GetPropertyChangedSignal("Visible"):Connect(queue) end
            queue()
        end)
        frame.ChildRemoved:Connect(queue)
        self._checkEmpty = queue
        queue()
    end
    -- DependsOn: the whole card shows only while the condition holds (see elements/base)
    if cfg.DependsOn then require("elements/base").depend(self.window, cfg.DependsOn, function(ok) frame.Visible = ok return frame.Parent ~= nil end) end
    -- restore the folded state from the window memory
    local memory = self.window.memory and self.window.memory.collapsed
    if self._chevron and ((memory and memory[self._key]) or cfg.Collapsed) then
        task.defer(function() self:SetCollapsed(true, true) end)
    end
    return self
end

-- card:SetCollapsed(true) folds the card to its heading (elements keep working); card.Collapsed
function Card:SetCollapsed(collapsed, quiet)
    collapsed = collapsed == true
    if collapsed == (self.Collapsed == true) then return end
    self.Collapsed = collapsed
    self._hidden = self._hidden or {}
    for _, child in ipairs(self.frame:GetChildren()) do
        if child:IsA("GuiObject") and child.Name ~= "Heading" and child.Name ~= "CardDesc" and child.Name ~= "Empty" then
            if collapsed then
                if child.Visible then self._hidden[child] = true child.Visible = false end
            elseif self._hidden[child] then
                child.Visible = true
            end
        end
    end
    if not collapsed then self._hidden = {} end
    if self._checkEmpty then self._checkEmpty() end
    if self._chevron then Util.tween(self._chevron, 0.15, { Rotation = collapsed and -90 or 0 }) end
    local window = self.window
    if self._key and window.memory and not quiet then
        window.memory.collapsed = window.memory.collapsed or {}
        window.memory.collapsed[self._key] = collapsed or nil
        window:_saveMemory()
    end
end
function Card:SetDesc(text) if self.descLabel then self.descLabel.Text = tostring(text) end end

-- Layout order for the next row (steps of 2 so a colour picker can open its panel right under its row).
function Card:_order()
    self.order = self.order + 2
    return self.order
end

-- card:Tabs({ "Main", "Extra" }) -> { Main = section, Extra = section }, selector
-- Sub-sections inside one card, switched with a capsule selector in the card header (or a row when the card
-- has no title). Each section works like a card: section:Toggle({...}).
function Card:Tabs(names, cfg)
    cfg = cfg or {}
    local holder
    if self.titleLabel then
        holder = create("Frame", { Name = "Tabs", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, self._chevron and -20 or 0, 0, 1), Size = UDim2.new(0.6, self._chevron and -20 or 0, 0, 18), Parent = self.titleLabel.Parent })
        self.titleLabel.Size = UDim2.new(0.4, -13, 1, 0)
    else
        holder = create("Frame", { Name = "Tabs", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = self:_order(), Parent = self.body })
    end
    local layout = Util.list(holder, 4, Enum.FillDirection.Horizontal)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    local self_card = self
    local sections, buttons, current = {}, {}, nil
    local selector = {}
    local function render()
        for name, button in pairs(buttons) do
            local on = name == current
            Theme.tweenTo(button, "BackgroundColor3", on and "selected" or "input", 0.1)
            Theme.tweenTo(button, "TextColor3", on and "heading" or "muted", 0.1)
            sections[name].body.Visible = on
        end
    end
    function selector:Select(name)
        if not sections[name] then return end
        current = name
        render()
        if cfg.Callback then self_card.window:_safe("Tabs", cfg.Callback, name) end
    end
    function selector:Get() return current end
    for index, name in ipairs(names) do
        name = tostring(name)
        local button = create("TextButton", {
            Name = name, AutoButtonColor = false, BorderSizePixel = 0, Text = name, TextSize = 9, Font = Enum.Font.GothamMedium,
            Size = UDim2.fromOffset(Util.textWidth(name, 9, Enum.Font.GothamMedium) + 16, 18), LayoutOrder = index, Parent = holder,
        })
        corner(button, 9)
        buttons[name] = button
        local body = create("Frame", { Name = "Section_" .. name, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = self:_order(), Visible = false, Parent = self.body })
        Util.list(body, 4)
        sections[name] = setmetatable({ page = self.page, window = self.window, order = 0, body = body, frame = self.frame, title = self.title }, Card)
        button.Activated:Connect(function() selector:Select(name) end)
    end
    current = tostring(cfg.Default or names[1])
    render()
    return sections, selector
end

-- card:Presets({ { "Legit", { fov = 80, smooth = 0.4 } }, { "Rage", { fov = 400, smooth = 0 } } }, { Custom = true, Callback })
-- Chips in the card header (or at the top of the card when the header is taken): a click sets every flag of that
-- preset. The chip that matches the current values lights up by itself; when nothing matches, "Custom" does.
-- Going from Custom to a preset remembers your values: clicking Custom brings them back.
-- Also takes a name -> values table (sorted by name). Returns { Select(name), Get() -> name or "Custom", Add(name, values) }.
local function same(a, b)
    if type(a) == "number" and type(b) == "number" then return math.abs(a - b) < 1e-6 end
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    for key, value in pairs(a) do if not same(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end
function Card:Presets(list, cfg)
    cfg = cfg or {}
    local window = self.window
    local presets = {}
    if type(list) == "table" and list[1] ~= nil then
        for _, entry in ipairs(list) do
            local name = entry.Name or entry[1]
            local values = entry.Values or entry[2]
            if name ~= nil and type(values) == "table" then presets[#presets + 1] = { name = tostring(name), values = values } end
        end
    elseif type(list) == "table" then
        for name, values in pairs(list) do
            if type(values) == "table" then presets[#presets + 1] = { name = tostring(name), values = values } end
        end
        table.sort(presets, function(a, b) return a.name < b.name end)
    end
    local holder
    local inHeader = self.titleLabel and not self.titleLabel.Parent:FindFirstChild("Tabs") and not self.titleLabel.Parent:FindFirstChild("Presets")
    if inHeader then
        holder = create("Frame", { Name = "Presets", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, self._chevron and -20 or 0, 0, 1), Size = UDim2.new(0.65, self._chevron and -20 or 0, 0, 18), Parent = self.titleLabel.Parent })
        self.titleLabel.Size = UDim2.new(0.35, -13, 1, 0)
    else
        holder = create("Frame", { Name = "Presets", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = self:_order(), Parent = self.body })
    end
    local layout = Util.list(holder, 4, Enum.FillDirection.Horizontal)
    layout.HorizontalAlignment = inHeader and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
    local chips = {}
    local selector = { Presets = presets }
    local current, applying, custom = nil, false, nil
    local showCustom = cfg.Custom ~= false

    local function flags(values)
        local out = {}
        for flag in pairs(values) do out[#out + 1] = flag end
        return out
    end
    -- the preset whose every value matches the flags now
    local function match()
        for _, preset in ipairs(presets) do
            local all = true
            for flag, value in pairs(preset.values) do
                if not same(window.Lib.Flags[flag], value) then all = false break end
            end
            if all then return preset.name end
        end
        return "Custom"
    end
    local function render()
        for name, chip in pairs(chips) do
            local on = name == current
            Theme.tweenTo(chip, "BackgroundColor3", on and "selected" or "input", 0.1)
            Theme.tweenTo(chip, "TextColor3", on and "heading" or "muted", 0.1)
            local stroke_ = chip:FindFirstChildWhichIsA("UIStroke")
            if stroke_ then Theme.bind(stroke_, "Color", on and "accent" or "buttonEdge") stroke_.Transparency = on and 0.4 or 0.6 end
        end
    end
    local function refresh()
        if applying then return end
        local now = match()
        if now ~= current then
            local before = current
            current = now
            render()
            if before ~= nil and cfg.Callback then window:_safe("Presets", cfg.Callback, now) end
        end
    end
    local function chip(name, order)
        local button = create("TextButton", {
            Name = name, AutoButtonColor = false, BorderSizePixel = 0, Text = name, TextSize = 9, Font = Enum.Font.GothamMedium,
            Size = UDim2.fromOffset(Util.textWidth(name, 9, Enum.Font.GothamMedium) + 16, 18), LayoutOrder = order, Parent = holder,
        })
        corner(button, 9)
        stroke(button, nil, 0.6)
        chips[name] = button
        button.Activated:Connect(function() require("sounds").Play("click") selector:Select(name) end)
        return button
    end

    function selector:Select(name)
        name = tostring(name)
        if name == "Custom" then
            if custom then
                applying = true
                for flag, value in pairs(custom) do window:SetFlag(flag, value) end
                applying = false
            end
            refresh()
            return
        end
        for _, preset in ipairs(presets) do
            if preset.name == name then
                -- leaving your own values: keep them for the Custom chip
                if current == "Custom" then
                    custom = {}
                    for _, other in ipairs(presets) do
                        for _, flag in ipairs(flags(other.values)) do custom[flag] = window.Lib.Flags[flag] end
                    end
                end
                applying = true
                for flag, value in pairs(preset.values) do window:SetFlag(flag, value) end
                applying = false
                refresh()
                return
            end
        end
    end
    function selector:Get() return current end
    function selector:Add(name, values)
        if type(values) ~= "table" then return end
        presets[#presets + 1] = { name = tostring(name), values = values }
        chip(tostring(name), #presets)
        if chips.Custom then chips.Custom.LayoutOrder = #presets + 1 end
        current = nil
        refresh()
    end

    for index, preset in ipairs(presets) do chip(preset.name, index) end
    if showCustom then chip("Custom", #presets + 1) end
    -- follow the flags: any change re-checks which preset matches (drops out when the card is gone)
    window._dependents = window._dependents or {}
    table.insert(window._dependents, function()
        if not holder.Parent then return false end
        refresh()
        return true
    end)
    task.defer(refresh)
    return selector
end

-- A pseudo-card: elements go into `body`, ordering is its own.
local function sub(card, body)
    return setmetatable({ page = card.page, window = card.window, order = 0, body = body, frame = card.frame, title = card.title }, Card)
end

-- card:Section({ Title, Icon, Desc, Opened = true }) -> a collapsible part of the card (click its header).
-- section:SetOpen(bool), section:ToggleOpen(), section.Opened
function Card:Section(cfg)
    if type(cfg) == "string" then cfg = { Title = cfg } end
    cfg = cfg or {}
    local holder = create("Frame", { Name = "Section_" .. tostring(cfg.Title or ""), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = self:_order(), Parent = self.body })
    Util.list(holder, 4)
    local head = create("TextButton", { Name = "Header", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, cfg.Desc and 34 or 24), LayoutOrder = 1, Parent = holder })
    local line = create("Frame", { Name = "Line", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = head })
    Theme.bind(line, "BackgroundColor3", "line")
    local x = 0
    local icon = cfg.Icon and Icons.themed(head, cfg.Icon, 14, "accent", { Name = "SectionIcon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0, 11) })
    if icon then x = 20 end
    local title = label(head, tostring(cfg.Title or ""), 11, { Name = "Title", Position = UDim2.fromOffset(x, 1), Size = UDim2.new(1, -x - 24, 0, 20), Font = Enum.Font.GothamMedium })
    Theme.bind(title, "TextColor3", "heading")
    if cfg.Desc then
        local desc = label(head, tostring(cfg.Desc), 9, { Name = "Desc", Position = UDim2.fromOffset(x, 18), Size = UDim2.new(1, -x - 24, 0, 12) })
        Theme.bind(desc, "TextColor3", "muted")
    end
    -- chevron (two bars) that turns when the section closes
    local chevron = create("Frame", { Name = "Chevron", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0, 11), Size = UDim2.fromOffset(10, 10), Parent = head })
    for index, rotation in ipairs({ 45, -45 }) do
        local bar = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(index == 1 and 3 or 7, 5), Size = UDim2.fromOffset(6, 1.5), Rotation = rotation, BorderSizePixel = 0, Parent = chevron })
        Theme.bind(bar, "BackgroundColor3", "muted")
    end
    local body = create("Frame", { Name = "Body", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = holder })
    Util.list(body, 4)
    Util.padding(body, 0, 0, 2, 4)
    local section = sub(self, body)
    if cfg.DependsOn then require("elements/base").depend(self.window, cfg.DependsOn, function(ok) holder.Visible = ok return holder.Parent ~= nil end) end
    function section:SetOpen(open)
        self.Opened = open ~= false
        body.Visible = self.Opened
        Util.tween(chevron, 0.15, { Rotation = self.Opened and 0 or -90 })
    end
    -- (not :Toggle - that name makes a Toggle element)
    function section:ToggleOpen() self:SetOpen(not self.Opened) end
    section.Header = head
    head.Activated:Connect(function() section:SetOpen(not section.Opened) end)
    section:SetOpen(cfg.Opened ~= false)
    return section
end

-- card:Row({ Gap = 6, Widths = { 2, 1 } }) -> elements put in it sit side by side (buttons, small toggles...).
-- Equal widths by default; Widths gives each one a share in order (here the first is twice the second).
function Card:Row(cfg)
    cfg = cfg or {}
    local gap = tonumber(cfg.Gap) or 6
    local weights = type(cfg.Widths) == "table" and cfg.Widths or nil
    local holder = create("Frame", { Name = "Row", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = self:_order(), Parent = self.body })
    Util.list(holder, gap, Enum.FillDirection.Horizontal)
    local function share()
        local children = {}
        for _, child in ipairs(holder:GetChildren()) do if child:IsA("GuiObject") and child.Visible then children[#children + 1] = child end end
        table.sort(children, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
        local n = #children
        local total = 0
        for index = 1, n do total = total + math.max(tonumber(weights and weights[index]) or 1, 0.05) end
        for index, child in ipairs(children) do
            local share = math.max(tonumber(weights and weights[index]) or 1, 0.05) / total
            child.Size = UDim2.new(share, -gap * (n - 1) * share, child.Size.Y.Scale, child.Size.Y.Offset)
        end
    end
    -- widths are shared again when a child comes, goes, or is shown / hidden (DependsOn Mode = "Hide")
    holder.ChildAdded:Connect(function(child)
        if child:IsA("GuiObject") then child:GetPropertyChangedSignal("Visible"):Connect(function() task.defer(share) end) end
        task.defer(share)
    end)
    holder.ChildRemoved:Connect(function() task.defer(share) end)
    return sub(self, holder)
end

-- card:Group({ Title }) -> a boxed group inside the card (elements stacked, its own background).
function Card:Group(cfg)
    if type(cfg) == "string" then cfg = { Title = cfg } end
    cfg = cfg or {}
    local box = create("Frame", { Name = "Group_" .. tostring(cfg.Title or ""), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, LayoutOrder = self:_order(), Parent = self.body })
    Theme.bind(box, "BackgroundColor3", "base")
    box.BackgroundTransparency = 0.35
    corner(box, 7)
    Theme.bind(stroke(box), "Color", "line")
    Util.padding(box, 10, 10, 6, 8)
    Util.list(box, 4)
    if cfg.Title then
        local title = label(box, tostring(cfg.Title):upper(), 8, { Name = "Title", Size = UDim2.new(1, 0, 0, 14), Font = Enum.Font.GothamMedium, LayoutOrder = 0 })
        Theme.bind(title, "TextColor3", "muted")
    end
    return sub(self, box)
end

-- card:HeaderSwitch({ Title = "Debug", Flag, Default, Tooltip, Callback = function(on) end }) -> a small switch with a
-- muted caption in the card's title row (left of the fold arrow). :Set(on), :Get(); saved with the profile via Flag.
function Card:HeaderSwitch(cfg)
    cfg = cfg or {}
    local head = self.titleLabel and self.titleLabel.Parent
    if not head then return nil end
    local right = self._chevron and 22 or 0
    local holder = create("TextButton", { Name = "HeaderSwitch", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -right, 0.5, 0), Size = UDim2.fromOffset(28, 16), Parent = head })
    local track = create("Frame", { Name = "Track", Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Parent = holder })
    corner(track, 8)
    local knob = create("Frame", { Name = "Knob", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(12, 12), BorderSizePixel = 0, Parent = track })
    corner(knob, 6)
    Theme.bind(knob, "BackgroundColor3", "knob")
    local caption
    if cfg.Title then
        caption = label(head, tostring(cfg.Title), 9, { Name = "HeaderSwitchTitle", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(right + 34), 0.5, 0), Size = UDim2.fromOffset(Util.textWidth(cfg.Title, 9, Enum.Font.Gotham) + 8, 16), TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.None })
        Theme.bind(caption, "TextColor3", "muted")
    end
    local used = right + 34 + (caption and caption.Size.X.Offset + 6 or 0)
    self.titleLabel.Size = UDim2.new(1, self.titleLabel.Size.X.Offset - (used - right), 1, 0)
    local element = { Type = "HeaderSwitch", Flag = cfg.Flag, Value = cfg.Default == true, Row = holder, _changed = {} }
    local function paint(animate)
        local t = animate and 0.12 or 0
        Theme.tweenTo(track, "BackgroundColor3", element.Value and "toggleOn" or "input", t)
        Util.tween(knob, t, { Position = UDim2.new(0, element.Value and 14 or 2, 0.5, 0) })
    end
    local window = self.window
    function element:Set(on, silent)
        on = on == true
        local changed = on ~= self.Value
        self.Value = on
        paint(true)
        if self.Flag then window.Lib.Flags[self.Flag] = on window:_flagChanged(self.Flag) end
        if changed and not silent then Util.safe(cfg.Callback, on) end
    end
    function element:Get() return self.Value end
    function element:_save() return self.Value end
    function element:_load(value) self:Set(value == true) end
    holder.Activated:Connect(function() require("sounds").Play("click") element:Set(not element.Value) end)
    holder.MouseEnter:Connect(function() if cfg.Tooltip then window:_tip(cfg.Tooltip) end end)
    holder.MouseLeave:Connect(function() window:_hideTip() end)
    if cfg.Flag then
        window.Lib.Flags[cfg.Flag] = element.Value
        window:_register(cfg.Flag, element) -- (profiles save / load it, its default is remembered)
    end
    paint(false)
    return element
end

function Card:SetTitle(text) if self.titleLabel then self.titleLabel.Text = tostring(text) end end
function Card:SetVisible(visible) self.frame.Visible = visible ~= false end

return Card
end

__modules["config"] = function()
-- Configs: every element with a Flag is saved to <Folder>/configs/<name>.json.
-- Writes are crash-safe (Util.writeAtomic): an interrupted save never leaves a broken profile, and a profile caught
-- half way is restored from its .tmp on the next read (Config.Recovered lists those, the window shows a toast).
-- Window.Config:Save(name), :Load(name), :Delete(name), :List(), :SetAutoLoad(name), :LoadAutoLoad()
local Util = require("util")

local HttpService = Util.Services.HttpService

local Config = {}
Config.__index = Config

-- True when the executor has every named file function.
local function can(...)
    local available = {
        isfolder = isfolder, makefolder = makefolder, writefile = writefile, readfile = readfile,
        isfile = isfile, delfile = delfile, listfiles = listfiles,
    }
    for _, name in ipairs({ ... }) do
        if type(available[name]) ~= "function" then return false end
    end
    return true
end
-- Windows can't create files named con / prn / aux / nul / com1-9 / lpt1-9, and paths must stay short
local RESERVED = { con = true, prn = true, aux = true, nul = true }
for i = 1, 9 do RESERVED["com" .. i] = true RESERVED["lpt" .. i] = true end
local function cleanName(name)
    name = tostring(name or ""):gsub("[^%w_%- ]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    name = name:sub(1, 60):gsub("%s+$", "")
    if RESERVED[name:lower()] then name = name .. "_" end
    return name
end

function Config.new(window, folder)
    local self = setmetatable({ window = window, folder = cleanName(folder) ~= "" and cleanName(folder) or "QustahUI" }, Config)
    self.path = self.folder .. "/configs"
    self.pending = {}  -- values for flags whose element does not exist yet (applied when it is created)
    self.Defaults = {} -- each flag's starting value (recorded when its element is created)
    self.Custom = {}   -- script data saved with the profile: Config:SetData(key, value)
    return self
end

-- Called by Window:_register once the element is fully built: remembers its default and applies a pending value.
function Config:_elementReady(flag, element)
    if self.Defaults[flag] == nil then
        local ok, value = pcall(element._save, element)
        if ok and value ~= nil then self.Defaults[flag] = value end
    end
    -- the reset button compares against this default
    if element._initReset then pcall(element._initReset, element, self.Defaults[flag]) end
    local value = self.pending[flag]
    if value ~= nil then
        self.pending[flag] = nil
        pcall(element._load, element, value)
    end
end

-- Custom data: anything JSON can hold (tables of numbers / strings / booleans), saved and loaded with profiles.
--   Window.Config:SetData("waypoints", { ... }), :GetData("waypoints"), :OnDataLoaded(function(custom) end)
function Config:SetData(key, value) self.Custom[tostring(key)] = value end
function Config:GetData(key) return self.Custom[tostring(key)] end
function Config:OnDataLoaded(callback)
    self._dataListeners = self._dataListeners or {}
    table.insert(self._dataListeners, callback)
end
function Config:_setCustom(custom)
    self.Custom = type(custom) == "table" and custom or {}
    for _, listener in ipairs(self._dataListeners or {}) do Util.safe(listener, self.Custom) end
end

-- Per-game profiles: Config:SetPerGame("Game" | "Place" | false) keeps profiles, their notes and the autoload in
-- <Folder>/configs/<GameId or PlaceId>/ (CreateWindow({ PerGame = "Game" }) or Settings › Profiles).
function Config:SetPerGame(mode)
    if mode == true then mode = "Game" end
    self.perGame = (mode == "Game" or mode == "Place") and mode or nil
    local id = self.perGame == "Place" and game.PlaceId or (self.perGame == "Game" and game.GameId) or nil
    self.path = self.folder .. "/configs" .. (id and ("/" .. tostring(id)) or "")
    self:_setActive(nil, nil)
end
-- files that belong to the current profile scope (shared folder or the game's folder)
function Config:_scopeFile(name)
    return (self.perGame and self.path or self.folder) .. "/" .. name
end

function Config:_ensure()
    if not can("isfolder", "makefolder") then return false end
    if not isfolder(self.folder) then makefolder(self.folder) end
    if not isfolder(self.folder .. "/configs") then makefolder(self.folder .. "/configs") end
    if not isfolder(self.path) then makefolder(self.path) end
    return true
end

-- Returns true, or false and the reason.
function Config:Save(name)
    name = cleanName(name)
    if name == "" then return false, "Empty config name" end
    if not can("writefile") then return false, "writefile is not available" end
    self:_ensure()
    local data = { version = 1, flags = self:Snapshot(), custom = self.Custom }
    local ok, err = Util.writeAtomic(self.path .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    if not ok then return false, err end
    self:_setActive(name, data.flags)
    return true
end

-- Writes a profile from a flag table (Snapshot format) without touching the current values.
function Config:SaveFlags(name, flags, custom)
    name = cleanName(name)
    if name == "" then return false, "Empty config name" end
    if not can("writefile") then return false, "writefile is not available" end
    self:_ensure()
    local ok, err = Util.writeAtomic(self.path .. "/" .. name .. ".json", HttpService:JSONEncode({ version = 1, flags = flags or {}, custom = custom }))
    if not ok then return false, err end
    return true
end

-- Reads <file>; notes a recovery from an interrupted save.
function Config:_readFile(file, label)
    local data, info = Util.readJSON(file)
    if data and info == true then
        self.Recovered = self.Recovered or {}
        table.insert(self.Recovered, label or file)
        for _, listener in ipairs(self._recoverListeners or {}) do Util.safe(listener, label or file) end
    end
    return data, info
end
-- Config:OnRecovered(function(name) end): a file was restored from an interrupted save
function Config:OnRecovered(callback)
    self._recoverListeners = self._recoverListeners or {}
    table.insert(self._recoverListeners, callback)
end
function Config:_readProfile(name)
    if not can("readfile", "isfile") then return nil, "readfile is not available" end
    local data, problem = self:_readFile(self.path .. "/" .. name .. ".json", name)
    if not data then return nil, problem == "missing" and "Config not found" or "Config file is damaged" end
    if type(data.flags) ~= "table" then return nil, "Config file is damaged" end
    return data
end

function Config:Load(name)
    name = cleanName(name)
    local data, err = self:_readProfile(name)
    if not data then return false, err end
    local failed = self:Apply(data.flags)
    self:_setCustom(data.custom)
    self:_setActive(name, data.flags)
    if failed > 0 then return true, failed .. " setting(s) could not be applied" end
    return true
end

-- Reads a profile's flags without applying them.
function Config:Read(name)
    local data, err = self:_readProfile(cleanName(name))
    if not data then return nil, err end
    return data.flags, data.custom
end

-- The profile the current settings came from (nil = the script's defaults) and what it held.
-- Config.Active, Config:OnActiveChanged(fn), Config:Changes() -> number of settings that differ from it.
function Config:_setActive(name, flags)
    self.Active, self.ActiveFlags = name, flags
    for _, listener in ipairs(self._activeListeners or {}) do Util.safe(listener, name) end
end
function Config:OnActiveChanged(callback)
    self._activeListeners = self._activeListeners or {}
    table.insert(self._activeListeners, callback)
end
local function same(a, b)
    if type(a) == "number" and type(b) == "number" then return math.abs(a - b) < 1e-6 end
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    for key, value in pairs(a) do if not same(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end
Config.same = same
-- Settings that differ between the current values and a flag table (default: the active profile's).
function Config:Changes(flags)
    flags = flags or self.ActiveFlags or self.DefaultFlags or {}
    local count, names = 0, {}
    for flag, value in pairs(self:Snapshot()) do
        if flags[flag] ~= nil and not same(value, flags[flag]) then
            count = count + 1
            names[#names + 1] = flag
        end
    end
    return count, names
end

-- Share codes: "QUSTAH1:" .. base64(JSON { n = name, f = flags }).
function Config:Export(name)
    local flags, custom
    if name then flags, custom = self:Read(name) else flags, custom = self:Snapshot(), self.Custom end
    if not flags then return nil, "Config not found" end
    local data = { n = name or "Shared", f = flags }
    if type(custom) == "table" and next(custom) ~= nil then data.c = custom end
    return "QUSTAH1:" .. Util.base64encode(HttpService:JSONEncode(data))
end
-- Returns name, flags (nothing is saved or applied).
function Config:Decode(code)
    code = tostring(code or ""):gsub("%s", "")
    local body = code:match("^QUSTAH1:(.+)$")
    if not body then return nil, "Not a profile code" end
    local json = Util.base64decode(body)
    local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
    if not ok or type(data) ~= "table" or type(data.f) ~= "table" then return nil, "The code is damaged or cut off" end
    return cleanName(data.n) ~= "" and cleanName(data.n) or "Imported", data.f, data.c
end
-- A free name: "pvp", "pvp 2", "pvp 3"...
function Config:FreeName(name)
    name = cleanName(name)
    if name == "" or name:lower() == "default" then name = "Profile" end
    if not self:Exists(name) then return name end
    local index = 2
    while self:Exists(name .. " " .. index) do index = index + 1 end
    return name .. " " .. index
end

function Config:Delete(name)
    name = cleanName(name)
    if self.Active == name then self:_setActive(nil, nil) end
    if not can("delfile", "isfile") then return false, "delfile is not available" end
    local file = self.path .. "/" .. name .. ".json"
    if not isfile(file) then return false, "Config not found" end
    local ok, err = pcall(delfile, file)
    for _, tmp in ipairs(Util.tmpFiles(file)) do if isfile(tmp) then pcall(delfile, tmp) end end
    return ok, not ok and tostring(err) or nil
end

function Config:List()
    local names = {}
    if not can("listfiles", "isfolder") or not isfolder(self.path) then return names end
    local ok, files = pcall(listfiles, self.path)
    if not ok or type(files) ~= "table" then return names end
    local seen = {}
    for _, file in ipairs(files) do
        -- (a profile whose first save was cut off only has its .tmp: listed, restored when read)
        local path = tostring(file):gsub("\\", "/")
        local name = path:match("([^/]+)%.json$") or path:match("([^/]+)%.json%.tmp%.txt$")
        local parent = path:match("^(.*)/[^/]+$") or ""
        if name and not seen[name] and (parent == "" or parent:sub(-#self.path) == self.path) then
            seen[name] = true
            names[#names + 1] = name
        end
    end
    table.sort(names)
    return names
end

function Config:SetAutoLoad(name)
    if not can("writefile") then return false end
    self:_ensure()
    return Util.writeAtomic(self:_scopeFile("autoload.txt"), cleanName(name))
end
function Config:GetAutoLoad()
    if not can("readfile", "isfile") or not isfile(self:_scopeFile("autoload.txt")) then return nil end
    local ok, name = pcall(readfile, self:_scopeFile("autoload.txt"))
    name = ok and cleanName(name) or ""
    return name ~= "" and name or nil
end
-- Call once after the whole UI is built.
function Config:LoadAutoLoad()
    local name = self:GetAutoLoad()
    if name and self:Exists(name) then return self:Load(name) end
    return false, "No autoload config"
end

-- Window memory: position / size of the window and the floating panels, in <Folder>/window.json.
function Config:ReadMemory()
    return self:_readFile(self.folder .. "/window.json", "window") or {}
end
function Config:WriteMemory(data)
    if not can("writefile") then return false end
    self:_ensure()
    return Util.writeAtomic(self.folder .. "/window.json", HttpService:JSONEncode(data))
end

-- Any small JSON file in the folder (custom themes...): Config:ReadJSON("themes"), :WriteJSON("themes", data)
function Config:ReadJSON(name)
    return self:_readFile(self.folder .. "/" .. cleanName(name) .. ".json", cleanName(name)) or {}
end
function Config:WriteJSON(name, data)
    if not can("writefile") then return false end
    self:_ensure()
    return Util.writeAtomic(self.folder .. "/" .. cleanName(name) .. ".json", HttpService:JSONEncode(data))
end

-- Profiles keep extra info (when saved) in <Folder>/profiles.json.
function Config:ReadMeta()
    return self:_readFile(self:_scopeFile("profiles.json"), "profiles") or {}
end
function Config:WriteMeta(data)
    if not can("writefile") then return false end
    self:_ensure()
    return Util.writeAtomic(self:_scopeFile("profiles.json"), HttpService:JSONEncode(data))
end

-- Snapshot of every flag right now (used as the locked "Default" profile).
function Config:Snapshot()
    local data = {}
    for flag, value in pairs(self.pending) do data[flag] = value end -- not created yet: keep what was loaded
    for flag, element in pairs(self.window.flags) do
        local ok, value = pcall(element._save, element)
        if ok and value ~= nil then data[flag] = value end
    end
    return data
end
function Config:Apply(flags)
    local failed = 0
    for flag, value in pairs(flags or {}) do
        local element = self.window.flags[flag]
        if element and self.Defaults[flag] == nil then -- (a load right after building: remember the start value first)
            local ok, current = pcall(element._save, element)
            if ok and current ~= nil then self.Defaults[flag] = current end
        end
        if not element then
            self.pending[flag] = value -- applied when the element is created
        elseif not pcall(element._load, element, value) then
            failed = failed + 1
        end
    end
    return failed
end
function Config:Exists(name)
    name = cleanName(name)
    if not can("isfile") or name == "" then return false end
    local file = self.path .. "/" .. name .. ".json"
    for _, tmp in ipairs(Util.tmpFiles(file)) do if isfile(tmp) then return true end end
    return isfile(file)
end
function Config:Rename(old, new)
    old, new = cleanName(old), cleanName(new)
    if new == "" then return false, "Empty name" end
    if self:Exists(new) then return false, "A profile with that name exists" end
    if not can("readfile", "writefile", "delfile", "isfile") then return false, "File functions are not available" end
    local ok, text = pcall(readfile, self.path .. "/" .. old .. ".json")
    if not ok then return false, "Profile not found" end
    local written, err = Util.writeAtomic(self.path .. "/" .. new .. ".json", text)
    if not written then return false, err end
    pcall(delfile, self.path .. "/" .. old .. ".json")
    if self:GetAutoLoad() == old then self:SetAutoLoad(new) end
    if self.Active == old then self:_setActive(new, self.ActiveFlags) end
    return true
end
function Config:Copy(name, new)
    name, new = cleanName(name), cleanName(new)
    if self:Exists(new) then return false, "A profile with that name exists" end
    if not can("readfile", "writefile") then return false, "File functions are not available" end
    local ok, text = pcall(readfile, self.path .. "/" .. name .. ".json")
    if not ok then return false, "Profile not found" end
    return Util.writeAtomic(self.path .. "/" .. new .. ".json", text)
end
function Config:ClearAutoLoad()
    if can("delfile", "isfile") and isfile(self:_scopeFile("autoload.txt")) then pcall(delfile, self:_scopeFile("autoload.txt")) end
end

return Config
end

__modules["crosshair"] = function()
-- Crosshair drawn from frames: Plus, Plus + Dot, X, Dot, Circle, Circle + Dot.
--   local xh = Lib.Crosshair.Overlay({ Enabled = true, Style = "X" })   -- on screen, follows the mouse
--   xh:Update({ Color = Color3.fromRGB(255, 80, 80), Spin = true })     -- only the given keys change
--   xh:Destroy()
-- card:CrosshairPreview({ Height = 110 }) draws the same settings at 2x in a card (element:Update(settings)).
-- Settings: Enabled, Style, Color, Opacity (0 - 100), Outline (a thin black edge), Length, Thickness, Gap (px),
-- Spin, SpinSpeed (degrees a second).
local Util = require("util")

local create, corner, stroke = Util.create, Util.corner, Util.stroke
local Crosshair = { Styles = { "Plus", "Plus + Dot", "X", "Dot", "Circle", "Circle + Dot" } }

local DEFAULTS = {
    Enabled = true, Style = "Plus", Color = Color3.new(1, 1, 1), Opacity = 100, Outline = true,
    Length = 8, Thickness = 2, Gap = 4, Spin = false, SpinSpeed = 120,
}
-- a full settings table: the defaults, then `settings`
function Crosshair.settings(settings)
    local out = {}
    for key, value in pairs(DEFAULTS) do out[key] = value end
    for key, value in pairs(settings or {}) do out[key] = value end
    return out
end

-- The frames of one crosshair under `parent` (arms, a dot, a ring around a zero-size root):
-- { root, layout(settings, scale), baseRotation } - the X style is the Plus turned by 45 degrees.
function Crosshair.build(parent, zindex)
    local root = create("Frame", { Name = "Crosshair", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(0, 0), ZIndex = zindex, Parent = parent })
    local arms = {}
    for index = 1, 4 do
        local arm = create("Frame", { Name = "Arm" .. index, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = zindex, Parent = root })
        arms[index] = { frame = arm, edge = stroke(arm, Color3.new(), 0, 1) }
    end
    local dot = create("Frame", { Name = "Dot", BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = zindex, Parent = root })
    corner(dot, 999)
    local dotEdge = stroke(dot, Color3.new(), 0, 1)
    local ring = create("Frame", { Name = "Ring", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = zindex, Parent = root })
    corner(ring, 999)
    local ringLine = stroke(ring, nil, 0, 1)
    local self = { root = root, baseRotation = 0 }
    function self.layout(settings, scale)
        scale = scale or 1
        local style = settings.Style or "Plus"
        local color = typeof(settings.Color) == "Color3" and settings.Color or Color3.new(1, 1, 1)
        local alpha = 1 - math.clamp((tonumber(settings.Opacity) or 100) / 100, 0, 1)
        local length = (tonumber(settings.Length) or 8) * scale
        local thick = math.max(1, (tonumber(settings.Thickness) or 2) * scale)
        local gap = (tonumber(settings.Gap) or 4) * scale
        local outline = settings.Outline ~= false
        local hasArms = style == "Plus" or style == "Plus + Dot" or style == "X"
        local hasDot = style == "Dot" or style == "Plus + Dot" or style == "Circle + Dot"
        local hasRing = style == "Circle" or style == "Circle + Dot"
        for index, arm in ipairs(arms) do
            local horizontal = index <= 2
            local offset = ((index % 2 == 1) and -1 or 1) * (gap + length / 2)
            arm.frame.Visible = hasArms
            arm.frame.Size = horizontal and UDim2.fromOffset(length, thick) or UDim2.fromOffset(thick, length)
            arm.frame.Position = horizontal and UDim2.fromOffset(offset, 0) or UDim2.fromOffset(0, offset)
            arm.frame.BackgroundColor3, arm.frame.BackgroundTransparency = color, alpha
            arm.edge.Enabled, arm.edge.Transparency = outline, alpha
        end
        local dotSize = math.max(2, thick * 1.6)
        dot.Visible, dot.Size = hasDot, UDim2.fromOffset(dotSize, dotSize)
        dot.BackgroundColor3, dot.BackgroundTransparency = color, alpha
        dotEdge.Enabled, dotEdge.Transparency = outline, alpha
        local radius = gap + length
        ring.Visible, ring.Size = hasRing, UDim2.fromOffset(radius * 2, radius * 2)
        ringLine.Color, ringLine.Thickness, ringLine.Transparency = color, thick, alpha
        self.baseRotation = style == "X" and 45 or 0
    end
    return self
end

-- A crosshair on screen at the mouse (its own ScreenGui; the per-frame follow only runs while it is enabled).
function Crosshair.Overlay(settings)
    local gui = Util.screenGui("QustahUI_Crosshair", 50)
    local drawn = Crosshair.build(gui, 1)
    local UserInputService, RunService = Util.Services.UserInputService, Util.Services.RunService
    local self = { settings = Crosshair.settings({ Enabled = false }), gui = gui, root = drawn.root }
    local connection, angle = nil, 0
    local function follow(dt)
        local mouse = UserInputService:GetMouseLocation()
        drawn.root.Position = UDim2.fromOffset(mouse.X, mouse.Y)
        if self.settings.Spin then angle = (angle + (tonumber(self.settings.SpinSpeed) or 120) * dt) % 360 else angle = 0 end
        drawn.root.Rotation = drawn.baseRotation + angle
    end
    function self:Update(changes)
        for key, value in pairs(changes or {}) do self.settings[key] = value end
        local on = self.settings.Enabled == true and gui.Parent ~= nil
        gui.Enabled = on
        drawn.layout(self.settings, 1)
        if on and not connection then
            connection = RunService.RenderStepped:Connect(follow)
            follow(0)
        elseif not on and connection then
            connection:Disconnect()
            connection = nil
        end
    end
    function self:SetEnabled(on) self:Update({ Enabled = on == true }) end
    function self:Destroy()
        if connection then connection:Disconnect() connection = nil end
        gui:Destroy()
    end
    self:Update(settings)
    return self
end

return Crosshair
end

__modules["dashboard"] = function()
-- Window:DashboardTab({ Title, Icon, Info = { { "Code revision", "571" }, ... }, Server = true, Modules = true })
-- Qustah's overview: profile card (Hero: avatar, names, session timer, live FPS / ping / players chips), live tiles
-- (StatTiles: FPS, ping, players, Lua memory with their history; Stats = false hides them), Session (with the
-- ids, each with a copy button), Server and Modules (a grid of tiles: Window:SetModule(name, state, detail,
-- { Icon = "eye", Tab = "ESP" }) - a click on a tile opens its tab).
-- Call it before the other tabs; a divider goes between it and the next tab in the dock.
local Util = require("util")
local Theme = require("theme")
local Glow = require("glow")
local Icons = require("icons")
local Stats = require("stats")

local Services = Util.Services
local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

return function(window, cfg)
    cfg = cfg or {}
    local Players = Services.Players
    local player = Players.LocalPlayer
    local tab = window:Tab({ Title = cfg.Title or "Dashboard", Icon = cfg.Icon or "layout-dashboard", Header = cfg.Header ~= false })
    window._dividerNext = true
    local page = tab:Page(tab.Title)
    local started = os.clock()

    ------------------------------------------------------------ profile (Hero) and live numbers (StatTiles)
    local profile = page:Card({ Wide = true })
    local function names(on)
        return on and "Anonymous" or player.DisplayName, on and "hidden" or ("@" .. player.Name .. " · #" .. player.UserId)
    end
    local displayName, userLine = names(window.anonymous)
    local hero = profile:Hero({ Name = "Profile", Title = displayName, Desc = userLine, Label = "SESSION", Value = "00:00:00", AvatarSize = 56,
        Chips = { { "-- FPS", "gauge" }, { "-- ms", "wifi" }, { "--", "users" } } })
    Theme.bind(hero.Value, "TextColor3", "accent")
    Glow.add(hero.Value, { Base = "accent", Phase = 0.45 })
    Stats.start(window.Lib.maid)
    -- rbxthumb content: shows at once, no web request (fine in secure mode)
    local avatarImage = Util.avatar(player.UserId, 60) -- (shown at 56 px: about 1:1, 150 shrunk 2.7x looked jagged)
    if not window.anonymous then hero:SetImage(avatarImage) end
    -- anonymous mode (dock profile button): no name, no id, no avatar
    if window.OnAnonymousChanged then
        window:OnAnonymousChanged(function(on)
            local title, desc = names(on)
            hero:SetTitle(title) hero:SetDesc(desc)
            hero:SetImage(on and "" or avatarImage)
        end)
    end
    -- FPS, ping, players and Lua memory as tiles with a line of their history (Stats = false: none)
    if cfg.Stats ~= false then
        local function memory()
            local ok, kb = pcall(collectgarbage, "count")
            if not ok or type(kb) ~= "number" then ok, kb = pcall(function() return gcinfo() end) end
            return ok and type(kb) == "number" and kb / 1024 or nil
        end
        page:Card({ Wide = true }):StatTiles({ Interval = 2, Items = {
            { Title = "FPS", Source = "FPS" },
            { Title = "Ping", Source = "Ping", Suffix = " ms", Color = "warning" },
            { Title = "Players", Source = function() return #Players:GetPlayers() end, Sub = "this server",
                Format = function(v) return math.floor(v + 0.5) .. " / " .. Players.MaxPlayers end, Color = Color3.fromRGB(127, 180, 232) },
            { Title = "Memory", Source = memory, Sub = "Lua", Format = function(v) return string.format("%.1f MB", v) end, Color = Color3.fromRGB(180, 139, 232) },
        } })
    end

    ------------------------------------------------------------ session / info / server
    local session = page:Card({ Title = "Session", Side = "Left", Icon = "id-card" })
    session:Info({ Title = "Account created", Value = os.date("%d %b %Y", os.time() - player.AccountAge * 86400) })
    local executor = "Unknown"
    pcall(function()
        if type(identifyexecutor) == "function" then executor = table.concat({ identifyexecutor() }, " ")
        elseif type(getexecutorname) == "function" then executor = tostring(getexecutorname()) end
    end)
    session:Info({ Title = "Executor", Value = executor })
    if window.Version ~= "" then session:Info({ Title = "GUI version", Value = window.Version }) end
    for _, entry in ipairs(cfg.Info or {}) do session:Info({ Title = entry[1], Value = entry[2], Copy = entry.Copy }) end
    -- the ids, each with a copy button
    local details = session
    local userId = details:Info({ Title = "User ID", Value = "#" .. player.UserId, Copy = function() return tostring(player.UserId) end })
    if window.OnAnonymousChanged then window:OnAnonymousChanged(function(on) userId:Set(on and "hidden" or ("#" .. player.UserId)) end) end
    details:Info({ Title = "Game ID", Value = "#" .. game.GameId, Copy = function() return tostring(game.GameId) end })
    details:Info({ Title = "Place ID", Value = "#" .. game.PlaceId, Copy = function() return tostring(game.PlaceId) end })

    if cfg.Server ~= false then
        local server = page:Card({ Title = "Server", Side = "Right", Icon = "server" })
        local busy = false
        local function teleport(hop)
            if busy then window:Notify({ Title = "Server", Content = "Teleport already pending" }) return end
            local TeleportService = Services.TeleportService
            busy = true
            task.delay(12, function() busy = false end)
            window:Notify({ Title = hop and "Server hop" or "Rejoin", Content = hop and "Finding a server..." or "Rejoining..." })
            task.spawn(function()
                local ok, err = pcall(function()
                    if not hop then
                        if game.JobId ~= "" and #Players:GetPlayers() > 1 then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
                        else
                            TeleportService:Teleport(game.PlaceId, player)
                        end
                        return
                    end
                    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
                    local data = Services.HttpService:JSONDecode(game:HttpGet(url))
                    local list = {}
                    for _, item in ipairs(data.data or {}) do
                        if item.id ~= game.JobId and item.playing and item.maxPlayers and item.playing < item.maxPlayers then list[#list + 1] = item end
                    end
                    assert(#list > 0, "No other public server found")
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, list[math.random(1, #list)].id, player)
                end)
                if not ok then busy = false window:Notify({ Title = "Teleport failed", Content = tostring(err), Color = "danger" }) end
            end)
        end
        local actions = server:Row()
        actions:Button({ Title = "Rejoin", Icon = "refresh-cw", Callback = function() teleport(false) end })
        actions:Button({ Title = "Server hop", Icon = "shuffle", Confirm = true, Callback = function() teleport(true) end })
        server:Info({ Title = "Job ID", Value = game.JobId ~= "" and (game.JobId:sub(1, 8) .. "...") or "studio", Copy = function() return game.JobId end })
    end

    ------------------------------------------------------------ modules (Window:SetModule)
    if cfg.Modules ~= false then
        local modulesCard = page:Card({ Title = "Modules", Side = "Right", Icon = "boxes" })
        local empty = modulesCard:Label("Modules report here with Window:SetModule(name, state)")
        -- a grid of tiles: icon, name and a coloured state pill; a click opens the module's tab
        local grid = create("Frame", { Name = "ModuleGrid", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = modulesCard:_order(), Parent = modulesCard.body })
        Util.list(grid, 6)
        local tiles, gridRows = {}, {}
        -- two tiles per row; past six modules three smaller ones (name and a state dot, the state on hover)
        -- (plain rows: they size with the card at any width / UI scale). ModuleColumns = 2 | 3 fixes it.
        local columns, tileHeight = 2, 38
        local function rowFor(index)
            local number = math.ceil(index / columns)
            local holder = gridRows[number]
            if not holder then
                holder = create("Frame", { Name = "Row" .. number, BackgroundTransparency = 1, LayoutOrder = number, Parent = grid })
                Util.list(holder, 6, Enum.FillDirection.Horizontal)
                gridRows[number] = holder
            end
            return holder
        end
        local COLORS = { On = "success", Limited = "warning", Error = "danger" }
        local function tabNamed(name)
            for _, t in ipairs(window.Tabs) do if t.Title == name then return t end end
        end
        local function tile(name, index)
            local button = create("TextButton", { Name = "Tile_" .. name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Size = UDim2.new(0.5, -3, 1, 0), LayoutOrder = index, Parent = grid })
            Theme.bind(button, "BackgroundColor3", "input")
            corner(button, 7)
            local edge = stroke(button)
            Theme.bind(edge, "Color", "line")
            local icon = create("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(14, 14), Visible = false, Parent = button })
            local title = label(button, name, 10, { Name = "Title", Position = UDim2.fromOffset(10, 5), Size = UDim2.new(1, -18, 0, 15), Font = Enum.Font.GothamMedium })
            Theme.bind(title, "TextColor3", "text")
            -- the state under the name: a small dot and the word, in the state's colour
            local pill = label(button, "", 8, { Name = "State", Position = UDim2.fromOffset(20, 20), Size = UDim2.new(1, -28, 0, 12), Font = Enum.Font.GothamBold })
            local stateDot = create("Frame", { Name = "StateDot", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(10, 26), Size = UDim2.fromOffset(5, 5), BorderSizePixel = 0, Parent = button })
            corner(stateDot, 3)
            button.MouseEnter:Connect(function()
                Theme.tweenTo(edge, "Color", "accentEdge", 0.1)
                -- (small tiles show no state word: it comes up here)
                if columns == 3 and tileHeight < 42 then
                    local _, modules = window:GetModules()
                    local module = modules[name]
                    if module then window:_tip(name .. " · " .. module.state .. (module.detail and module.detail ~= "" and (" · " .. tostring(module.detail)) or "")) end
                end
            end)
            button.MouseLeave:Connect(function() Theme.tweenTo(edge, "Color", "line", 0.1) window:_hideTip() end)
            button.Activated:Connect(function()
                local meta = window.moduleMeta and window.moduleMeta[name]
                local target = meta and meta.Tab and tabNamed(meta.Tab)
                if target then require("sounds").Play("click") target:Select() end
            end)
            tiles[name] = { button = button, icon = icon, title = title, pill = pill, dot = stateDot }
            return tiles[name]
        end
        local exactGrid, lastExtra = nil, 0
        local function update()
            exactGrid = nil
            local order, modules = window:GetModules()
            empty:SetVisible(#order == 0)
            columns = tonumber(cfg.ModuleColumns) or (#order > 6 and 3 or 2)
            tileHeight = 38
            if columns == 3 then
                -- three a row: as tall as fills the card beside them (Session), so no empty space is left under them
                local rowsWanted = math.max(1, math.ceil(#order / 3))
                tileHeight = 46 -- (until it can be measured)
                -- a card's own height: its children (not the spacer MatchHeights adds) and the gaps between them
                local scale = window.scale and window.scale.Scale or 1
                local function natural(card, skip)
                    local layout = card.frame:FindFirstChildOfClass("UIListLayout")
                    local gap = layout and layout.Padding.Offset or 4
                    local total, count = 0, 0
                    for _, child in ipairs(card.frame:GetChildren()) do
                        if child:IsA("GuiObject") and child.Visible and child.Name ~= "MatchSpacer" and child ~= skip then
                            total = total + child.AbsoluteSize.Y / scale
                            count = count + 1
                        end
                    end
                    return total + math.max(0, count - 1) * gap
                end
                local sessionHeight = natural(session)
                -- (the modules card without its grid)
                local withoutGrid = natural(modulesCard)
                local gridHeight = grid.AbsoluteSize.Y / scale
                if sessionHeight > 0 and gridHeight > 0 then
                    -- the grid exactly as tall as the room (the last row takes the pixels left over), so the two
                    -- cards end on the same line
                    local free = math.floor(sessionHeight - (withoutGrid - gridHeight) + 0.5)
                    local fit = math.floor((free - (rowsWanted - 1) * 6) / rowsWanted)
                    tileHeight = math.clamp(fit, 30, 58)
                    if fit == tileHeight then exactGrid = free end
                end
            end
            -- (the grid's height set from its rows, not AutomaticSize: Session next to it matches it at once)
            local rows = math.ceil(#order / columns)
            local natural = rows > 0 and rows * tileHeight + (rows - 1) * 6 or 0
            local height = exactGrid or natural
            lastExtra = height - natural
            local gridSize = UDim2.new(1, 0, 0, height)
            if grid.Size ~= gridSize then grid.Size = gridSize end
            for index = 1, #order do rowFor(index) end
            for number, holder in pairs(gridRows) do
                holder.Visible = number <= rows
                local size = UDim2.new(1, 0, 0, tileHeight + (number == rows and lastExtra or 0))
                if holder.Size ~= size then holder.Size = size end
            end
            for index, name in ipairs(order) do
                local t = tiles[name] or tile(name, index)
                t.button.Parent = rowFor(index)
                t.button.LayoutOrder = index
                t.button.Size = UDim2.new(1 / columns, columns == 3 and -4 or -3, 1, 0)
                local module = modules[name]
                local meta = window.moduleMeta and window.moduleMeta[name]
                local hasIcon = meta and meta.Icon and Icons.Apply(t.icon, meta.Icon) or false
                t.icon.Visible = hasIcon
                if hasIcon then Theme.bind(t.icon, "ImageColor3", module.state == "Off" and "muted" or "heading") end
                local role = COLORS[module.state] or "muted"
                t.pill.Text = string.upper(module.state)
                if columns == 3 and tileHeight >= 42 then
                    -- name, the state under it (a dot and the word), centred in the tile's height
                    t.icon.Visible = false
                    t.pill.Visible = true
                    t.title.TextSize = 10
                    t.title.TextTruncate = Enum.TextTruncate.AtEnd
                    t.title.Position = UDim2.new(0, 9, 0.5, -15)
                    t.title.Size = UDim2.new(1, -14, 0, 15)
                    t.dot.Position = UDim2.new(0, 9, 0.5, 6)
                    t.pill.Position = UDim2.new(0, 18, 0.5, 0)
                    t.pill.Size = UDim2.new(1, -22, 0, 12)
                elseif columns == 3 then
                    -- one line: [dot] name, centred in the tile's height (no icon, no state word)
                    t.icon.Visible = false
                    t.pill.Visible = false
                    t.dot.Position = UDim2.new(0, 7, 0.5, 0)
                    t.title.Position = UDim2.new(0, 16, 0.5, -8)
                    t.title.Size = UDim2.new(1, -19, 0, 16)
                    t.title.TextSize = 9
                    t.title.TextTruncate = Enum.TextTruncate.AtEnd
                else
                    local lead = hasIcon and 31 or 10
                    t.pill.Visible = true
                    t.title.TextSize = 10
                    t.title.Position = UDim2.fromOffset(lead, 5)
                    t.title.Size = UDim2.new(1, -lead - 8, 0, 15)
                    t.dot.Position = UDim2.fromOffset(lead, 26)
                    t.pill.Position = UDim2.fromOffset(lead + 9, 20)
                    t.pill.Size = UDim2.new(1, -lead - 17, 0, 12)
                end
                Theme.bind(t.pill, "TextColor3", role)
                Theme.bind(t.dot, "BackgroundColor3", role)
                Theme.bind(t.title, "TextColor3", module.state == "Off" and "muted" or "text")
                t.button:SetAttribute("Detail", module.detail)
            end
        end
        window:OnStatusChanged(update)
        update()
        page:MatchHeights(session, modulesCard) -- (side by side, the same height)
        -- (three a row fill the height of Session: measured again when it changes size)
        local queued = false
        local function remeasure()
            if queued or columns ~= 3 then return end
            queued = true
            task.defer(function() queued = false update() end)
        end
        -- (in game the first measure can come before the cards have a size: measured again whenever one of them,
        -- the grid or the page changes size or shows; the same result changes nothing, so this settles at once)
        local sessionLayout = session.frame:FindFirstChildOfClass("UIListLayout")
        if sessionLayout then sessionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(remeasure) end
        for _, object in ipairs({ session.frame, modulesCard.frame, grid, page.frame }) do
            object:GetPropertyChangedSignal("AbsoluteSize"):Connect(remeasure)
            object:GetPropertyChangedSignal("Visible"):Connect(remeasure)
        end
        task.delay(1, remeasure)
    end

    ------------------------------------------------------------ live values (only while the dashboard is open)
    task.spawn(function()
        while window.alive do
            if window.visible and window.current == tab then
                local seconds = math.floor(os.clock() - started)
                hero:SetValue(string.format("%02d:%02d:%02d", seconds // 3600, (seconds // 60) % 60, seconds % 60))
                hero:SetChipText(1, (Stats.fps or 0) .. " FPS")
                local ok, value = pcall(function() return player:GetNetworkPing() end)
                hero:SetChipText(2, ok and (math.floor(value * 1000 + 0.5) .. " ms") or "--")
                hero:SetChipText(3, #Players:GetPlayers() .. " / " .. Players.MaxPlayers)
            end
            task.wait(1)
        end
    end)
    return tab
end
end

__modules["dialog"] = function()
-- In-window dialogs.
--   Window:Dialog({ Title, Content, Buttons = { { Title = "Cancel" }, { Title = "Enable", Style = "Danger", Callback = fn } } })
--   Window:Confirm(title, content, onConfirm, confirmText, danger)
-- The menu behind is dimmed and blocked; Escape or a click on the dim area closes it (as "cancel").
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")

local create, corner, stroke, label, tween = Util.create, Util.corner, Util.stroke, Util.label, Util.tween

return function(Window)
    function Window:Dialog(cfg)
        cfg = cfg or {}
        if self._dialog then self._dialog:Close() end
        local window = self
        local overlay = create("TextButton", {
            Name = "Dialog", Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 200, Parent = self.main,
        })
        local panel = create("Frame", {
            Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 330, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, ZIndex = 201, Active = true, Parent = overlay,
        })
        create("UISizeConstraint", { MaxSize = Vector2.new(330, 400), MinSize = Vector2.new(200, 0), Parent = panel })
        Theme.bind(panel, "BackgroundColor3", "card")
        corner(panel, 8)
        Theme.bind(stroke(panel), "Color", "line")
        Util.padding(panel, 16, 16, 12, 12)
        Util.list(panel, 8)
        -- long titles wrap onto more lines instead of being cut
        local title = label(panel, tostring(cfg.Title or ""), 13, {
            Name = "Title", Size = UDim2.new(1, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None, Font = Enum.Font.GothamMedium, ZIndex = 202, LayoutOrder = 1,
        })
        Theme.bind(title, "TextColor3", "heading")
        -- Icon = "name" before the title (red when IconColor / a Danger button says so)
        if cfg.Icon and Icons.Get(cfg.Icon) then
            Util.padding(title, 24, 0, 0, 0)
            local icon = Icons.themed(title, cfg.Icon, 16, "accent", { Name = "DialogIcon", Position = UDim2.fromOffset(-24, 2), ZIndex = 203 })
            if typeof(cfg.IconColor) == "Color3" then Theme.bind(icon, "ImageColor3", cfg.IconColor) end
        end
        if cfg.Content then
            local content = label(panel, tostring(cfg.Content), 10, {
                Name = "Content", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
                TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top, RichText = true, ZIndex = 202, LayoutOrder = 2,
            })
            Theme.bind(content, "TextColor3", "muted")
        end
        -- (a little more room above the buttons than between the texts)
        local row = create("Frame", { Name = "Buttons", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 3, ZIndex = 202, Parent = panel })
        Util.list(row, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)

        local dialog = { Frame = overlay }
        function dialog:Close(result)
            if not overlay.Parent then return end
            if window._dialog == dialog then window._dialog = nil end
            overlay:Destroy()
            if result == nil then window:_safe("Dialog", cfg.OnCancel) end
        end
        local buttons = cfg.Buttons or { { Title = "OK" } }
        for index, spec in ipairs(buttons) do
            local style = spec.Style
            local button = create("TextButton", {
                Name = tostring(spec.Title or "OK"), Text = tostring(spec.Title or "OK"), TextSize = 10, Font = Enum.Font.GothamMedium,
                AutoButtonColor = false, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(70, 28),
                LayoutOrder = index, ZIndex = 203, Parent = row,
            })
            Util.padding(button, 14, 14, 0, 0)
            corner(button, 6)
            local outline = stroke(button)
            if style == "Danger" then
                Theme.bind(button, "BackgroundColor3", "dangerDeep")
                Theme.bind(button, "TextColor3", "dangerText")
                Theme.bind(outline, "Color", "dangerEdge")
            elseif style == "Primary" then
                Theme.bind(button, "BackgroundColor3", "accentDeep")
                Theme.bind(button, "TextColor3", "accent")
                Theme.bind(outline, "Color", "accent")
                outline.Transparency = 0.45
            else
                Theme.bind(button, "BackgroundColor3", "input")
                Theme.bind(button, "TextColor3", "text")
                Theme.bind(outline, "Color", "buttonEdge")
            end
            button.Activated:Connect(function()
                dialog:Close(true)
                window:_safe("Dialog", spec.Callback)
            end)
        end
        overlay.Activated:Connect(function() dialog:Close() end)
        tween(overlay, 0.15, { BackgroundTransparency = 0.35 })
        self._dialog = dialog
        return dialog
    end

    function Window:Confirm(title, content, onConfirm, confirmText, danger)
        return self:Dialog({
            Title = title, Content = content, Icon = danger and "triangle-alert" or nil, IconColor = danger and Theme.get("danger") or nil,
            Buttons = { { Title = "Cancel" }, { Title = confirmText or "Confirm", Style = danger and "Danger" or "Primary", Callback = onConfirm } },
        })
    end
end
end

__modules["elements/actioninput"] = function()
-- card:ActionInput({ Icon = "plus", Placeholder, Button = "Create", Hint, Validate, Callback = function(text) end, ClearOnAction = true })
-- One field with an icon, the text and an action button inside it (Enter also runs it). Under it a hint line
-- that Validate(text) can turn into live feedback: return ok, message ("ok" green, false red, nil = plain hint).
-- :SetHint(text, state) shows a message ("ok" / "error" / nil); :Focus(); :Set(text).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label
local GREEN, RED = "success", "danger" -- theme roles

return function(card, cfg)
    local holder = create("Frame", { Name = tostring(cfg.Name or cfg.Button or "ActionInput"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = card:_order(), Parent = card.body })
    Util.list(holder, 5)
    local field = create("Frame", { Name = "Field", Size = UDim2.new(1, 0, 0, 34), BorderSizePixel = 0, LayoutOrder = 1, Parent = holder })
    Theme.bind(field, "BackgroundColor3", "input")
    corner(field, 8)
    local outline = stroke(field)
    Theme.bind(outline, "Color", "buttonEdge")

    local left = 12
    local icon = cfg.Icon and Icons.themed(field, cfg.Icon, 14, "muted", { Name = "FieldIcon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 11, 0.5, 0) })
    if icon then left = 33 end

    local buttonText = tostring(cfg.Button or "OK")
    local buttonWidth = Util.textWidth(buttonText, 10, Enum.Font.GothamMedium) + 26
    local button = create("TextButton", {
        Name = "Action", Text = buttonText, TextSize = 10, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -5, 0.5, 0), Size = UDim2.fromOffset(buttonWidth, 24), Parent = field,
    })
    corner(button, 6)
    local buttonEdge = stroke(button)

    local box = create("TextBox", {
        Name = "Box", Text = "", PlaceholderText = tostring(cfg.Placeholder or ""), TextSize = 10, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, BackgroundTransparency = 1, ClipsDescendants = true,
        Position = UDim2.fromOffset(left, 0), Size = UDim2.new(1, -(left + buttonWidth + 14), 1, 0), Parent = field,
    })
    Theme.bind(box, "TextColor3", "heading")
    Theme.bind(box, "PlaceholderColor3", "muted")

    local hintRow = create("Frame", { Name = "HintRow", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 2, Parent = holder })
    local hintDot = create("Frame", { Name = "Dot", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, Visible = false, Parent = hintRow })
    corner(hintDot, 3)
    local hint = label(hintRow, tostring(cfg.Hint or ""), 9, { Name = "Hint", Position = UDim2.fromOffset(2, 0), Size = UDim2.new(1, -2, 1, 0) })
    Theme.bind(hint, "TextColor3", "muted")
    hintRow.Visible = cfg.Hint ~= nil and tostring(cfg.Hint) ~= "" -- (no empty line under the field: it shows when there is something to say)

    local element = Base.element(card, "ActionInput", cfg, holder, nil, nil)
    element.Value = ""
    local ready = false
    local function style()
        Theme.tweenTo(button, "BackgroundColor3", ready and "accentDeep" or "base", 0.1)
        Theme.tweenTo(button, "TextColor3", ready and "accent" or "muted", 0.1)
        Theme.tweenTo(buttonEdge, "Color", ready and "accent" or "line", 0.1)
        buttonEdge.Transparency = ready and 0.45 or 0
    end
    function element:SetHint(text, state)
        hint.Text = tostring(text or cfg.Hint or "")
        hintRow.Visible = hint.Text ~= ""
        local color = state == "ok" and GREEN or (state == "error" and RED or nil)
        hintDot.Visible = color ~= nil
        hint.Position = UDim2.fromOffset(color and 13 or 2, 0)
        if color then Theme.bind(hint, "TextColor3", color) Theme.bind(hintDot, "BackgroundColor3", color) else Theme.bind(hint, "TextColor3", "muted") end
    end
    local function validate()
        local text = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
        element.Value = text
        if text == "" then
            ready = false
            element:SetHint(cfg.Hint)
        elseif type(cfg.Validate) == "function" then
            local okCall, ok, message = pcall(cfg.Validate, text)
            if not okCall then ok, message = false, tostring(ok) end
            ready = ok ~= false
            if message then element:SetHint(message, ok == true and "ok" or (ok == false and "error" or nil)) else element:SetHint(cfg.Hint) end
        else
            ready = true
        end
        style()
    end
    local function run()
        validate()
        if not ready or element.Locked then return end
        element:_call(cfg.Callback, element.Value)
        if cfg.ClearOnAction ~= false then box.Text = "" end
        validate()
    end
    box:GetPropertyChangedSignal("Text"):Connect(validate)
    box.Focused:Connect(function() Theme.tweenTo(outline, "Color", "accent", 0.12) outline.Transparency = 0.4 end)
    box.FocusLost:Connect(function(enter)
        Theme.tweenTo(outline, "Color", "buttonEdge", 0.12)
        outline.Transparency = 0
        if enter then run() end
    end)
    button.Activated:Connect(run)
    button.MouseEnter:Connect(function() if ready then Theme.tweenTo(button, "TextColor3", "heading", 0.1) end end)
    button.MouseLeave:Connect(style)

    function element:Set(text) box.Text = tostring(text or "") validate() end
    function element:Get() return self.Value end
    function element:Focus() pcall(function() box:CaptureFocus() end) end
    function element:Run() run() end
    validate()
    return Base.finish(element, cfg)
end
end

__modules["elements/base"] = function()
-- Shared parts of every element: the row (title + optional description), callbacks / OnChanged, flags,
-- Lock / Unlock with a reason, Flash, MoveUp / MoveDown / MoveTo / Remove, and the default save / load used by configs.
-- A callback that errors makes its element flash red and say so for a moment (the error goes to Settings › Info).
-- DependsOn: the element follows another flag -
--   DependsOn = "silentAim"                                   locked while silentAim is off
--   DependsOn = { Flag = "aimPart", Value = "Head" }          ... unless aimPart is "Head" (in a list for multi dropdowns)
--   DependsOn = { Flag = "esp", Not = true, Mode = "Hide", Reason = "..." }   Mode "Hide" hides instead of locking
--   (Reason = "": only dimmed and not usable, no lock icon or text)
--   DependsOn = function(flags) return flags.esp and flags.range > 500 end
-- Tooltip = "text": shown next to the mouse after a short hover (:SetTooltip(text)).
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")
local Sounds = require("sounds")

local create, corner, label = Util.create, Util.corner, Util.label

local Base = {}

-- elements that hold a value: they get a flag from their name when the window has AutoFlags = true
local VALUE = {
    Toggle = true, Slider = true, Dropdown = true, Keybind = true, ColorPicker = true, Input = true, Segment = true,
    Range = true, Swatches = true, Gradient = true, ImagePicker = true, PlayerList = true, Checkbox = true, Radio = true, Stepper = true, TextArea = true,
}

-- Is a flag value "on"? (false, nil, "", empty lists and "None" keys are off)
local function truthy(value)
    if value == nil or value == false or value == "" then return false end
    if type(value) == "table" then return next(value) ~= nil end
    if typeof(value) == "EnumItem" then return value.Name ~= "None" and value.Name ~= "Unknown" end
    return true
end
Base.truthy = truthy

-- Runs apply(ok) now (deferred, so the flags it reads exist) and whenever any flag changes.
-- apply returns false once its object is gone, which drops the watcher.
function Base.depend(window, spec, apply)
    local check
    if type(spec) == "function" then
        check = function() return spec(window.Lib.Flags) end
    else
        if type(spec) ~= "table" then spec = { Flag = spec } end
        check = function()
            local value = window.Lib.Flags[spec.Flag]
            local ok
            if type(spec.Value) == "function" then ok = spec.Value(value)
            elseif spec.Value ~= nil then
                if type(value) == "table" then ok = table.find(value, spec.Value) ~= nil else ok = value == spec.Value end
            else ok = truthy(value) end
            if spec.Not then ok = not ok end
            return ok
        end
    end
    local function run()
        local ok, result = pcall(check)
        return apply(ok and result and true or false) ~= false
    end
    window._dependents = window._dependents or {}
    table.insert(window._dependents, run)
    task.defer(run)
    return run
end

-- Rows of a list in display order (rows use even LayoutOrders; an odd one right after a row is its panel).
local function rowsOf(parent)
    local list = {}
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("GuiObject") and child.LayoutOrder >= 2 and child.LayoutOrder % 2 == 0 then list[#list + 1] = child end
    end
    table.sort(list, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
    return list
end
local function panelOf(row)
    local parent = row.Parent
    if not parent then return nil end
    for _, child in ipairs(parent:GetChildren()) do
        if child ~= row and child:IsA("GuiObject") and child.LayoutOrder == row.LayoutOrder + 1 then return child end
    end
end

-- opts.right: pixels kept free on the right for the control; opts.button: the whole row is clickable.
function Base.row(card, cfg, height, opts)
    opts = opts or {}
    local row = create(opts.button and "TextButton" or "Frame", {
        Name = tostring(cfg.Title or "Row"), BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height), LayoutOrder = card:_order(), Parent = card.body,
    })
    if opts.button then row.Text = "" row.AutoButtonColor = false end
    local right = opts.right or 0
    local title = label(row, tostring(cfg.Title or ""), 11, {
        Name = "Title", Position = UDim2.fromOffset(0, cfg.Desc and 3 or 0),
        Size = UDim2.new(1, -right, 0, cfg.Desc and 18 or (opts.titleHeight or height)),
    })
    -- Risky = true: the title is red (a feature that can get you flagged); Risky = "text" also explains it on hover
    Theme.bind(title, "TextColor3", cfg.Risky and "danger" or "text")
    if type(cfg.Risky) == "string" and not cfg.Help then cfg.Help = cfg.Risky end
    local desc
    if cfg.Desc then
        desc = label(row, tostring(cfg.Desc), 9, { Name = "Desc", Position = UDim2.fromOffset(0, 23), Size = UDim2.new(1, -right, 0, 14) })
        Theme.bind(desc, "TextColor3", "muted")
    end
    -- Icon = "name": a small icon before the title (title / description move right)
    if cfg.Icon and not opts.noIcon then
        local icon = Icons.themed(row, cfg.Icon, 14, "muted", { Name = "RowIcon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0, cfg.Desc and 12 or (opts.titleHeight or height) / 2) })
        if icon then
            title.Position = UDim2.new(0, 22, 0, title.Position.Y.Offset)
            title.Size = UDim2.new(1, title.Size.X.Offset - 22, 0, title.Size.Y.Offset)
            if desc then desc.Position = UDim2.fromOffset(22, 23) desc.Size = UDim2.new(1, desc.Size.X.Offset - 22, 0, 14) end
        end
    end
    -- Help = "text": a small (i) icon left of the control; hover (or tap) shows the text next to the pointer.
    if cfg.Help then
        local help = create("TextButton", {
            Name = "Help", Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(opts.helpRight or right), 0, opts.helpY or height / 2),
            Size = UDim2.fromOffset(16, 16), ZIndex = 5, Parent = row,
        })
        local glyph = Icons.themed(help, "info", 12, "muted", { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 5 })
        if not glyph then help.Text = "i" help.TextSize = 10 help.Font = Enum.Font.GothamMedium Theme.bind(help, "TextColor3", "muted") end
        local function show() if glyph then Theme.tweenTo(glyph, "ImageColor3", "heading", 0.1) end card.window:_tip(cfg.Help) end
        help.Activated:Connect(show)
        help.MouseEnter:Connect(show)
        help.MouseLeave:Connect(function() if glyph then Theme.tweenTo(glyph, "ImageColor3", "muted", 0.1) end card.window:_hideTip() end)
        title.Size = UDim2.new(1, -(opts.helpRight or right) - 16, 0, title.Size.Y.Offset)
    end
    return row, title, desc
end

-- value helpers for the reset button: deep compare / copy of saved values (numbers, strings, tables...)
local function same(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for key, value in pairs(a) do if not same(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end
local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, item in pairs(value) do out[key] = copy(item) end
    return out
end

function Base.element(card, kind, cfg, row, title, desc)
    local window = card.window
    if cfg.Flag == nil and VALUE[kind] and cfg.Title and window.cfg and window.cfg.AutoFlags and not window._noAutoFlags then
        cfg.Flag = window:_autoFlag(card, cfg.Title)
    end
    local element = { Type = kind, Title = cfg.Title, Flag = cfg.Flag, Row = row, Card = card, Locked = false, _changed = {} }

    function element:OnChanged(callback)
        self._changed[#self._changed + 1] = callback
        return self
    end
    -- Runs a user callback; when it errors the element flashes red and its title says so (Base.failed).
    -- Returns true / false (nil when there was nothing to run).
    function element:_call(callback, ...)
        local ok = window:_safe(tostring(self.Title or kind), callback, ...)
        if ok == false then
            self._failed = true
            Base.failed(self, title)
        end
        return ok
    end
    -- Flash = false turns the green / accent "accepted" flash of inputs and keybinds off
    function element:_accepted(kind)
        if cfg.Flash ~= false and not self._failed then self:Flash(kind or "success") end
    end
    -- Stores the flag value; unless silent, runs Callback and the OnChanged listeners (extra values go along:
    -- the slider sends (value, dragging)).
    function element:_fire(value, silent, ...)
        if self.Flag then
            window.Lib.Flags[self.Flag] = value
            window:_flagChanged(self.Flag)
        end
        if self._resetButton then self:_updateReset() end
        if silent then return end
        -- UI sound (a dragged slider only clicks when it is let go)
        local dragging = ...
        if not (kind == "Slider" and dragging == true) then Sounds.Play((kind == "Toggle" or kind == "Checkbox") and "toggle" or "click") end
        -- errors in user callbacks are reported to the window (footer "Errors: N", Settings › Info)
        self:_call(cfg.Callback, value, ...)
        for _, callback in ipairs(self._changed) do self:_call(callback, value, ...) end
    end
    function element:SetTitle(text)
        self.Title = text
        if self._errorShown then self._titleBefore = tostring(text) elseif title then title.Text = tostring(text) end
    end
    function element:SetDesc(text)
        self._descText = tostring(text)
        if desc and not self.Locked then desc.Text = self._descText end
    end
    function element:SetVisible(visible) row.Visible = visible ~= false end

    -- Reset button: a small "rotate" icon after the title while the value differs from its default
    -- (the default Config recorded when the element was made). Reset = false on the element, or
    -- ResetButtons = false on the window, turns it off. element:ResetToDefault() does the same in code.
    function element:_initReset(default)
        if self._resetButton or default == nil or kind == "Button" then return end
        if not title or not title:IsA("TextLabel") or title.Text == "" then return end
        if cfg.Reset == false or (window.cfg and window.cfg.ResetButtons == false) then return end
        if type(self.Flag) == "string" and self.Flag:sub(1, 2) == "__" then return end -- (the built-in settings)
        self._default = copy(default)
        local button = create("ImageButton", {
            Name = "Reset", BackgroundTransparency = 1, AutoButtonColor = false, Image = "", AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.fromOffset(16, 16), ZIndex = 6, Visible = false, Parent = row,
        })
        local icon = Icons.themed(button, "rotate-ccw", 11, "muted", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 6 })
        button.MouseEnter:Connect(function()
            if icon then Theme.tweenTo(icon, "ImageColor3", "heading", 0.1) end
            window:_tip("Reset to default")
        end)
        button.MouseLeave:Connect(function()
            if icon then Theme.tweenTo(icon, "ImageColor3", "muted", 0.1) end
            window:_hideTip()
        end)
        button.Activated:Connect(function()
            Sounds.Play("click")
            window:_hideTip()
            self:ResetToDefault()
        end)
        self._resetButton = button
        title:GetPropertyChangedSignal("Text"):Connect(function() self:_updateReset() end)
        self:_updateReset()
    end
    function element:_updateReset()
        local button = self._resetButton
        if not button then return end
        local ok, current = pcall(self._save, self)
        button.Visible = ok and not same(current, self._default) and not self._errorShown
        if not button.Visible then return end
        -- right after the title text (or after a Badge tag)
        local width = Util.textWidth(title.Text, title.TextSize, title.Font)
        local room = title.AbsoluteSize.X
        if room and room > 20 then width = math.min(width, room - 18) end
        local x = title.Position.X.Offset + width + 5
        local badge = row:FindFirstChild("Badge")
        if badge then x = badge.Position.X.Offset + badge.Size.X.Offset + 3 end
        button.Position = UDim2.new(0, x, 0, title.Position.Y.Offset + title.Size.Y.Offset / 2)
    end
    function element:ResetToDefault()
        if self.Locked or self._default == nil then return end
        pcall(self._load, self, copy(self._default))
        self:_updateReset()
        self:Flash("accent")
    end
    -- element:Flash("success" | "danger" | "accent" | any role / Color3): a short tint behind the row
    function element:Flash(kind) Base.flash(row, kind) end

    -- Lock("Needs premium"): the row dims and the reason takes the place of the description
    -- (without a description it sits over the control, with a lock icon). Unlock() brings everything back.
    function element:Lock(reason)
        self.Locked = true
        self._lockReason = reason
        -- an open colour panel / dropdown list of this element closes
        if self.SetOpen then pcall(self.SetOpen, self, false) end
        local popup = window._popup
        if popup and popup.owner and (popup.owner == row or popup.owner:IsDescendantOf(row)) then window:_closePopup() end
        if not self._lock then
            local cover = create("TextButton", {
                Name = "Lock", Text = "", AutoButtonColor = false, BackgroundTransparency = 0.45, BorderSizePixel = 0,
                Position = UDim2.fromOffset(-4, -2), Size = UDim2.new(1, 8, 1, 4), ZIndex = 20, Parent = row,
            })
            Theme.bind(cover, "BackgroundColor3", "card")
            corner(cover, 6)
            cover.MouseEnter:Connect(function() if self._lockReason and self._lockReason ~= "" then window:_tip(self._lockReason) end end)
            cover.MouseLeave:Connect(function() window:_hideTip() end)
            self._lock = cover
            -- reason pill over the control (rows without a description)
            local pill = create("Frame", {
                Name = "Reason", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0),
                Size = UDim2.new(0.7, 0, 0, 16), ZIndex = 21, Visible = false, Parent = cover,
            })
            local icon = Icons.themed(pill, "lock", 11, "warning", { Name = "LockIcon", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), ZIndex = 22 })
            local text = label(pill, "", 9, { Name = "Text", Size = UDim2.new(1, icon and -16 or 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium, ZIndex = 22 })
            Theme.bind(text, "TextColor3", "warning")
            self._lockPill, self._lockText = pill, text
        end
        local hasReason = reason ~= nil and reason ~= ""
        if desc then
            if self._descText == nil then self._descText = desc.Text end
            if hasReason then
                desc.Text = tostring(reason)
                desc.ZIndex = 21
                Theme.bind(desc, "TextColor3", "warning")
            end
            self._lockPill.Visible = false
        else
            self._lockText.Text = hasReason and tostring(reason) or ""
            self._lockPill.Visible = hasReason
        end
        self._lock.Visible = true
    end
    function element:Unlock()
        self.Locked = false
        if self._lock then self._lock.Visible = false end
        if desc and self._descText ~= nil then
            desc.Text = self._descText
            desc.ZIndex = 1
            Theme.bind(desc, "TextColor3", "muted")
        end
        window:_hideTip()
    end

    -- Order inside its card / section: MoveUp(), MoveDown(), MoveTo(index), GetIndex()
    function element:GetIndex()
        if not row.Parent then return nil end
        for index, item in ipairs(rowsOf(row.Parent)) do if item == row then return index end end
    end
    function element:MoveTo(index)
        local parent = row.Parent
        if not parent then return end
        local list = rowsOf(parent)
        local orders, panels = {}, {}
        for i, item in ipairs(list) do orders[i] = item.LayoutOrder panels[item] = panelOf(item) end
        for i, item in ipairs(list) do if item == row then table.remove(list, i) break end end
        index = math.clamp(math.floor(tonumber(index) or 1), 1, #list + 1)
        table.insert(list, index, row)
        for i, item in ipairs(list) do
            item.LayoutOrder = orders[i]
            if panels[item] then panels[item].LayoutOrder = orders[i] + 1 end
        end
    end
    function element:MoveUp() local index = self:GetIndex() if index then self:MoveTo(index - 1) end end
    function element:MoveDown() local index = self:GetIndex() if index then self:MoveTo(index + 1) end end

    function element:Destroy()
        if self.Flag and window.flags[self.Flag] == self then window.flags[self.Flag] = nil end
        window.binds[self] = nil
        local panel = panelOf(row) -- (the colour picker's panel lives next to its row)
        if panel then panel:Destroy() end
        row:Destroy()
        window:_hideTip()
    end
    function element:Remove() self:Destroy() end
    function element:_save() return self.Value end
    function element:_load(value) self:Set(value) end

    element._risky = cfg.Risky and true or false
    if cfg.Flag then window:_register(cfg.Flag, element) end

    -- tooltip after a short hover
    element._tooltip = cfg.Tooltip
    function element:SetTooltip(text) self._tooltip = text end
    -- key conflict (Window:_checkKeys): the key tag turns yellow and hovering says what else uses the key.
    -- Elements point _keyLabel at their key text (and _keyStroke at its outline) and may add _onConflict.
    function element:_setConflict(others)
        local on = others ~= nil and #others > 0
        self.KeyConflict = on and others or nil
        self._conflictTip = on and ("Key also used by: " .. table.concat(others, ", ")) or nil
        if self._keyLabel then
            if self._keyRole == nil then self._keyRole = (Theme._binding(self._keyLabel) or {}).TextColor3 or "muted" end
            Theme.bind(self._keyLabel, "TextColor3", on and "warning" or self._keyRole)
        end
        if self._keyStroke then
            if self._keyStrokeRole == nil then self._keyStrokeRole = (Theme._binding(self._keyStroke) or {}).Color or "buttonEdge" end
            Theme.bind(self._keyStroke, "Color", on and "warning" or self._keyStrokeRole)
        end
        if self._onConflict then self:_onConflict(on) end
    end
    local hoverToken = 0
    -- text cut with "..." (a long title, description or value in a narrow window) shows in full on hover
    local function cutText()
        local parts = {}
        for _, object in ipairs({ title, desc, row:FindFirstChild("Value") }) do
            if object and object:IsA("GuiObject") and object.Visible and object.Text ~= "" then
                local ok, fits = pcall(function() return object.TextFits end)
                if ok and fits == false then parts[#parts + 1] = object.Text end
            end
        end
        return #parts > 0 and table.concat(parts, " · ") or nil
    end
    local tipShown = false
    row.MouseEnter:Connect(function()
        hoverToken = hoverToken + 1
        local token = hoverToken
        task.delay(0.35, function()
            if token ~= hoverToken or element.Locked or not row.Parent then return end
            local text = element._conflictTip or element._tooltip or cutText()
            if text then tipShown = true window:_tip(text) end
        end)
    end)
    row.MouseLeave:Connect(function()
        hoverToken = hoverToken + 1
        if tipShown then tipShown = false window:_hideTip() end
    end)

    -- dependency on other flags
    if cfg.DependsOn then
        local spec = cfg.DependsOn
        local mode = type(spec) == "table" and spec.Mode or "Lock"
        local function reason()
            if type(spec) == "table" and spec.Reason then return spec.Reason end
            local flag = type(spec) == "table" and spec.Flag or (type(spec) == "string" and spec)
            local source = flag and window.flags[flag]
            local name = tostring(source and source.Title or flag or "another setting")
            if type(spec) == "table" and spec.Value ~= nil and type(spec.Value) ~= "function" then return "Needs " .. name .. ": " .. tostring(spec.Value) end
            if type(spec) == "table" and spec.Not then return "Turn off " .. name .. " first" end
            return flag and ("Turn on " .. name .. " first") or "Not available right now"
        end
        Base.depend(window, spec, function(ok)
            if not row.Parent then return false end
            if mode == "Hide" then
                -- inside a folded card the row stays hidden; unfolding shows it only if the condition holds
                if card.Collapsed and row.Parent == card.frame then
                    card._hidden = card._hidden or {}
                    card._hidden[row] = ok or nil
                    row.Visible = false
                else
                    row.Visible = ok
                end
            elseif ok then
                if element._depLocked then element._depLocked = false element:Unlock() end
            elseif not element.Locked or element._depLocked then
                element._depLocked = true
                element:Lock(reason())
            end
        end)
    end
    return element
end

-- A soft tint behind a row that fades out (success / error feedback). A new flash restarts it.
function Base.flash(row, kind)
    if not row or not row.Parent then return end
    local flash = row:FindFirstChild("Flash")
    if not flash then
        flash = create("Frame", {
            Name = "Flash", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(-6, -2),
            Size = UDim2.new(1, 12, 1, 4), ZIndex = 0, Parent = row,
        })
        corner(flash, 6)
    end
    Theme.bind(flash, "BackgroundColor3", kind or "accent")
    local token = (flash:GetAttribute("Token") or 0) + 1
    flash:SetAttribute("Token", token)
    flash.BackgroundTransparency = 0.78
    task.delay(0.12, function()
        if flash.Parent and flash:GetAttribute("Token") == token then Util.tween(flash, 0.5, { BackgroundTransparency = 1 }) end
    end)
end

-- After a callback error: red flash, and the title reads "Error · see Settings › Info" for a moment.
function Base.failed(element, title)
    Base.flash(element.Row, "danger")
    Sounds.Play("error")
    if not title or not title.Parent then return end
    element._errorToken = (element._errorToken or 0) + 1
    local token = element._errorToken
    if not element._errorShown then
        element._errorShown = true
        element._titleBefore = tostring(element.Text or element.Title or title.Text)
        Theme.bind(title, "TextColor3", "danger")
    end
    title.Text = "Error · see Settings › Info"
    task.delay(2.2, function()
        if element._errorToken ~= token or not title.Parent then return end
        element._errorShown = false
        title.Text = element._titleBefore or tostring(element.Title or "")
        Theme.bind(title, "TextColor3", element._risky and "danger" or "text")
    end)
end

-- Applied by every element after its first Set: initial lock state.
-- One colour panel open at a time (CreateWindow({ OnePickerOpen = false }) turns this off): opening a colour picker
-- or gradient closes the other open ones, except the one it sits inside (a gradient's own Start / End pickers).
function Base.trackPanel(window, element, open)
    if not window then return end
    local list = window._openPanels or {}
    window._openPanels = list
    local index = table.find(list, element)
    if not open then
        if index then table.remove(list, index) end
        return
    end
    if not index then list[#list + 1] = element end
    if window.cfg and window.cfg.OnePickerOpen == false then return end
    local row = element.Row
    for i = #list, 1, -1 do
        local other = list[i]
        local holder = other._panel
        if other ~= element and not (row and holder and row:IsDescendantOf(holder)) then
            table.remove(list, i)
            other:SetOpen(false)
        end
    end
end

function Base.finish(element, cfg)
    if cfg.Locked then element:Lock(cfg.LockedTitle or cfg.LockedReason) end
    return element
end

return Base
end

__modules["elements/button"] = function()
-- card:Button({ Title, Desc, Icon, Callback, Confirm, Locked, Risky, Flag,
--               Style = "Default" | "Primary" | "Soft" | "Outline" | "Ghost" | "Danger" | "Link",
--               Size = "Small" | "Default" | "Large", IconSide = "Left" | "Right", Align = "Center" | "Left",
--               Cooldown = 5, Hold = 1.5, Loading = true, LoadingText, Done = true,
--               Bind = Enum.KeyCode.R, Bindable = true, Toggle = true, Default, OnStyle, OnTitle, OnIcon,
--               Menu = { "Spawn", { Title = "Shop", Icon = "store" } }, Selected, ShowSelected = true, Badge = "NEW" })
--
-- Confirm = true (or a text): asks for a second click within 2 seconds before running the callback.
-- Hold = seconds: hold the button (or its key) until it fills up; letting go early cancels.
-- Cooldown = seconds: after a run the button counts down and ignores clicks until it is ready again.
-- Loading: a callback that waits (task.wait, HttpGet...) shows a spinner and blocks clicks until it returns,
--   then a short tick (Done = false turns the tick off). element:SetLoading(true / false, text) by hand.
-- Bind = key: the key presses the button (shown as a small key cap); with Bindable right-click sets the key.
-- Toggle = true: an on / off button (Callback(value), Flag keeps it); on it uses OnStyle (Primary) / OnTitle / OnIcon.
-- Menu = { ... }: a split button. The arrow opens the list; a pick runs Callback(option) and the main part
--   runs Callback(selected) again later.
-- Badge = "3" / "NEW": a small tag on the corner; element:SetBadge(text or nil).
-- Icon without a Title gives an icon-only button. Put buttons in card:Row() to line them up side by side.
-- element:SetStyle(style), :SetTitle(text), :SetIcon(name), :SetLoading(on, text), :SetBadge(text), :SetBind(key),
--   :SetCooldown(seconds), :ResetCooldown(), :Set(value) / :Get() (Toggle), :SetMenu(list), :Select(option), :Fire()
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

-- each style: background role + transparency, text role, outline role + transparency; "hover" is the same set on hover
local STYLES = {
    Default = { bg = "input", bgT = 0, text = "text", edge = "buttonEdge", edgeT = 0,
        hover = { bg = "hover", bgT = 0, text = "heading" } },
    Primary = { bg = "accent", bgT = 0, text = "onAccent", edge = "accent", edgeT = 0,
        hover = { bg = "accent", bgT = 0.15, text = "onAccent" } },
    Soft = { bg = "accent", bgT = 0.86, text = "accent", edge = "accent", edgeT = 0.72,
        hover = { bg = "accent", bgT = 0.76, text = "accent" } },
    Outline = { bg = "hover", bgT = 1, text = "text", edge = "buttonEdge", edgeT = 0,
        hover = { bg = "hover", bgT = 0.4, text = "heading" } },
    Ghost = { bg = "hover", bgT = 1, text = "muted", edge = "buttonEdge", edgeT = 1,
        hover = { bg = "hover", bgT = 0, text = "heading" } },
    Danger = { bg = "danger", bgT = 0.86, text = "danger", edge = "danger", edgeT = 0.65,
        hover = { bg = "danger", bgT = 0.74, text = "danger" } },
    Link = { bg = "hover", bgT = 1, text = "accent", edge = "accent", edgeT = 1,
        hover = { bg = "hover", bgT = 1, text = "heading" } },
}
local SIZES = { Small = { 22, 9, 12 }, Default = { 28, 10, 14 }, Large = { 34, 11, 16 } } -- height, text, icon (icon and height both even: no half pixel)
local ARROW = 26 -- width of the split button's arrow part
local ITEM = 26  -- menu row height

local function styleName(value)
    value = tostring(value or "Default")
    for name in pairs(STYLES) do if name:lower() == value:lower() then return name end end
    return "Default"
end

-- menu entries: "Text" or { Title, Icon }
local function entries(list)
    local out = {}
    for _, option in ipairs(type(list) == "table" and list or {}) do
        if type(option) == "table" then
            out[#out + 1] = { Title = tostring(option.Title or option[1] or ""), Icon = option.Icon }
        else
            out[#out + 1] = { Title = tostring(option) }
        end
    end
    return out
end

return function(card, cfg)
    local window = card.window
    local sizeName = tostring(cfg.Size or "Default")
    local size = SIZES[sizeName:sub(1, 1):upper() .. sizeName:sub(2):lower()] or SIZES.Default
    local buttonHeight, textSize, iconSize = size[1], size[2], size[3]
    local height = cfg.Desc and buttonHeight + 16 or buttonHeight
    local title = cfg.Title ~= nil and tostring(cfg.Title) or (cfg.Icon and "" or "Button")
    local row = create("Frame", { Name = title ~= "" and title or tostring(cfg.Icon), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height), LayoutOrder = card:_order(), Parent = card.body })
    local button = create("TextButton", {
        Name = "Button", Size = UDim2.new(1, 0, 0, buttonHeight), BorderSizePixel = 0, Text = "",
        TextSize = textSize, Font = Enum.Font.Gotham, AutoButtonColor = false, Parent = row,
    })
    corner(button, 6)
    local outline = stroke(button)
    local desc
    if cfg.Desc then
        desc = Util.label(row, tostring(cfg.Desc), 9, { Position = UDim2.fromOffset(2, buttonHeight + 2), Size = UDim2.new(1, -4, 0, 14) })
        Theme.bind(desc, "TextColor3", "muted")
    end

    -- fill: grows while a Hold button is held, empties during a Cooldown
    local fill = create("Frame", { Name = "Fill", BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), BackgroundTransparency = 1, ZIndex = 1, Parent = button })
    corner(fill, 6)

    -- content: [spinner][icon][text][selected option] - centred, or on the left with Align = "Left"; IconSide = "Right" swaps
    local left = tostring(cfg.Align or ""):lower() == "left"
    local content = create("Frame", {
        Name = "Content", BackgroundTransparency = 1, AnchorPoint = Vector2.new(left and 0 or 0.5, 0.5), ZIndex = 2,
        Position = left and UDim2.new(0, 10, 0.5, 0) or UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, Parent = button,
    })
    Util.list(content, 6, Enum.FillDirection.Horizontal, left and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
    local iconRight = tostring(cfg.IconSide or ""):lower() == "right"
    local icon = cfg.Icon and Icons.Get(cfg.Icon) and Icons.themed(content, cfg.Icon, iconSize, "text", { Name = "ButtonIcon", LayoutOrder = iconRight and 3 or 1 }) or nil
    local spinner = Icons.themed(content, "loader-circle", iconSize, "text", { Name = "Spinner", LayoutOrder = 0, Visible = false })
    local textLabel = Util.label(content, title, textSize, {
        Name = "Text", Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2, Visible = title ~= "",
    })
    local selectedLabel -- (Menu) the chosen option, muted, after the text

    -- right side, from the edge inwards: [menu arrow][key cap][timer]
    local rightUsed = 0
    local menu = cfg.Menu ~= nil and entries(cfg.Menu) or nil
    local arrow
    if menu then
        arrow = create("TextButton", {
            Name = "MenuArrow", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3,
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, ARROW, 1, 0), Parent = button,
        })
        local split = create("Frame", { Name = "Split", BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 6), Size = UDim2.new(0, 1, 1, -12), BackgroundTransparency = 0.4, Parent = arrow })
        Theme.bind(split, "BackgroundColor3", "buttonEdge")
        Icons.themed(arrow, "chevron-down", 12, "text", { Name = "Chevron", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 1, 0.5, 0) })
        rightUsed = ARROW
        -- the main part is centred in the space left of the arrow
        if not left then content.Position = UDim2.new(0.5, -ARROW / 2, 0.5, 0) end
        if cfg.ShowSelected ~= false then
            selectedLabel = Util.label(content, "", textSize, { Name = "Selected", Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, TextTruncate = Enum.TextTruncate.None, LayoutOrder = 4, Visible = false })
        end
    end
    local keyCap = create("Frame", { Name = "Key", AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(20, math.min(16, buttonHeight - 8)), BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = 3, Visible = false, Parent = button })
    corner(keyCap, 4)
    local keyStroke = stroke(keyCap, nil, 0.3)
    Theme.bind(keyStroke, "Color", "buttonEdge")
    local keyText = Util.label(keyCap, "", 8, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamMedium, ZIndex = 3 })
    local timer = Util.label(button, "", math.max(8, textSize - 1), { Name = "Timer", AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(40, buttonHeight), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 3, Visible = false })

    local badge = create("Frame", { Name = "Badge", AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(16, 13), BorderSizePixel = 0, ZIndex = 4, Visible = false, Parent = button })
    corner(badge, 6)
    Theme.bind(badge, "BackgroundColor3", "accent")
    local badgeText = Util.label(badge, "", 8, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, ZIndex = 4 })
    Theme.bind(badgeText, "TextColor3", "onAccent")

    local element = Base.element(card, "Button", cfg, row, button, desc)
    -- the error note of a failed callback (Base.failed writes to the button) shows in the text label instead
    local paint
    button:GetPropertyChangedSignal("Text"):Connect(function()
        if button.Text == "" then return end
        textLabel.Text = button.Text
        textLabel.Visible = true
        button.Text = ""
        -- (an icon-only button has no text to restore: put its own state back once the note is gone)
        if element._errorShown then
            task.delay(2.4, function()
                if not element._errorShown and button.Parent then element:SetTitle(element.Text) if paint then paint(0) end end
            end)
        end
    end)
    button:GetPropertyChangedSignal("TextColor3"):Connect(function()
        if element._errorShown then textLabel.TextColor3 = button.TextColor3 elseif paint then paint(0) end
    end)
    element.Text = title
    element.Style = styleName(cfg.Style)
    local baseStyle = STYLES[element.Style]
    local isToggle = cfg.Toggle == true
    if isToggle then element.Value = cfg.Default == true end
    local hovered, loading, cooling, holding = false, false, false, false
    local busy = false

    local function style()
        if isToggle and element.Value then return STYLES[styleName(cfg.OnStyle or "Primary")] end
        return baseStyle
    end
    local function textRole(set)
        -- Risky keeps the red text on the plain styles
        local current = style()
        if cfg.Risky and (current == STYLES.Default or current == STYLES.Outline or current == STYLES.Ghost) then return "danger" end
        return set.text
    end
    -- the fill tint suits the style: a light veil on Primary, red on Danger / Risky, the accent otherwise
    local function fillRole()
        local current = style()
        if current == STYLES.Primary then return "onAccent", 0.75 end
        if current == STYLES.Danger or cfg.Risky then return "danger", 0.7 end
        return "accent", 0.78
    end
    function paint(duration)
        local current = style()
        local set = hovered and not (loading or cooling) and current.hover or current
        local role = textRole(set)
        Theme.tweenTo(button, "BackgroundColor3", set.bg, duration)
        if duration > 0 then Util.tween(button, duration, { BackgroundTransparency = set.bgT }) else button.BackgroundTransparency = set.bgT end
        Theme.tweenTo(outline, "Color", current.edge, duration)
        outline.Transparency = current.edgeT
        -- the icon and labels follow the same role (so a theme change repaints them right too)
        Theme.tweenTo(textLabel, "TextColor3", role, duration)
        if icon then Theme.tweenTo(icon, "ImageColor3", role, duration) end
        if spinner then Theme.tweenTo(spinner, "ImageColor3", role, duration) end
        if selectedLabel then Theme.tweenTo(selectedLabel, "TextColor3", role, duration) selectedLabel.TextTransparency = 0.45 end
        if arrow then
            local chevron = arrow:FindFirstChild("Chevron")
            if chevron then Theme.tweenTo(chevron, "ImageColor3", role, duration) end
        end
        Theme.tweenTo(keyText, "TextColor3", element.KeyConflict and "warning" or role, duration)
        keyText.TextTransparency = element.KeyConflict and 0 or 0.35
        Theme.bind(keyStroke, "Color", element.KeyConflict and "warning" or "buttonEdge")
        Theme.tweenTo(timer, "TextColor3", role, duration)
        local dim = (loading or cooling) and 0.45 or 0
        textLabel.TextTransparency = dim
        if icon then icon.ImageTransparency = dim end
        local tint, transparency = fillRole()
        Theme.bind(fill, "BackgroundColor3", tint)
        if fill.BackgroundTransparency < 1 then fill.BackgroundTransparency = transparency end
    end

    -- right side layout (arrow, key cap, timer, badge)
    -- the text is cut with "..." when the button is too narrow for it (the full text shows on hover)
    local function fit()
        local width = button.AbsoluteSize.X / (window.scale and window.scale.Scale or 1)
        if width <= 0 then return end
        local reserved = 20 + (content.Position.X.Offset < 0 and -content.Position.X.Offset * 2 or 0)
        for _, object in ipairs({ icon, spinner }) do
            if object and object.Visible then reserved = reserved + iconSize + 6 end
        end
        local need = Util.textWidth(textLabel.Text, textSize, Enum.Font.Gotham)
        -- the chosen option (split button) goes first when space is short: the button's own text matters more
        local squeezed = false
        if selectedLabel and element.Selected ~= nil then
            local extra = Util.textWidth(selectedLabel.Text, textSize, Enum.Font.Gotham) + 6
            squeezed = need + extra > width - reserved
            selectedLabel.Visible = not squeezed
            if not squeezed then reserved = reserved + extra end
        end
        local room = math.max(0, math.floor(width - reserved))
        if textLabel.Text ~= "" and need > room then
            textLabel.AutomaticSize = Enum.AutomaticSize.None
            textLabel.Size = UDim2.new(0, room, 1, 0)
            textLabel.TextTruncate = Enum.TextTruncate.AtEnd
            if cfg.Tooltip == nil then element._tooltip = textLabel.Text end
        else
            textLabel.AutomaticSize = Enum.AutomaticSize.X
            textLabel.Size = UDim2.fromScale(0, 1)
            textLabel.TextTruncate = Enum.TextTruncate.None
            if cfg.Tooltip == nil then element._tooltip = squeezed and (textLabel.Text .. " · " .. selectedLabel.Text) or nil end
        end
    end
    -- right side layout (arrow, key cap, timer, badge); centred content moves left to stay clear of it
    local function layoutRight()
        local x = rightUsed
        if keyCap.Visible then
            keyCap.Position = UDim2.new(1, -(x + 6), 0.5, 0)
            x = x + 6 + keyCap.Size.X.Offset
        end
        timer.Position = UDim2.new(1, -(x + 8), 0.5, 0)
        if timer.Visible then x = x + 8 + math.max(26, Util.textWidth(timer.Text, timer.TextSize, Enum.Font.Gotham)) end
        badge.Position = UDim2.new(1, -(rightUsed + 3), 0, 3)
        if not left then content.Position = UDim2.new(0.5, -x / 2, 0.5, 0) end
        fit()
    end
    layoutRight()
    button:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
    row:GetPropertyChangedSignal("Size"):Connect(function() task.defer(fit) end) -- (a Row shares out the widths)
    textLabel:GetPropertyChangedSignal("Text"):Connect(function() task.defer(fit) end)

    function element:SetTitle(text)
        self.Text = tostring(text)
        textLabel.Text = self.Text
        textLabel.Visible = self.Text ~= ""
    end
    function element:SetIcon(name) if icon then Icons.Apply(icon, name) end end
    function element:SetStyle(name)
        self.Style = styleName(name)
        baseStyle = STYLES[self.Style]
        paint(0.12)
    end
    function element:SetBadge(text)
        local shown = text ~= nil and text ~= false and tostring(text) ~= "" and tostring(text) ~= "0"
        badge.Visible = shown
        if shown then
            badgeText.Text = tostring(text)
            badge.Size = UDim2.fromOffset(math.max(13, Util.textWidth(badgeText.Text, 8, Enum.Font.GothamBold) + 8), 13)
        end
        self.Badge = shown and tostring(text) or nil
    end
    element:SetBadge(cfg.Badge)

    ------------------------------------------------------------ loading
    local spinConnection, doneToken = nil, 0
    function element:SetLoading(on, text)
        loading = on == true
        self.Loading = loading
        if spinConnection then spinConnection:Disconnect() spinConnection = nil end
        if spinner then
            spinner.Rotation = 0
            Icons.Apply(spinner, "loader-circle")
            spinner.Visible = loading
            if loading then
                spinConnection = window.maid:connect(Util.Services.RunService.Heartbeat, function(dt)
                    if not spinner.Parent then
                        if spinConnection then spinConnection:Disconnect() spinConnection = nil end
                        return
                    end
                    spinner.Rotation = (spinner.Rotation + (dt or 1 / 60) * 360) % 360
                end)
            end
        end
        if icon and not iconRight then icon.Visible = not loading end
        textLabel.Text = loading and text and tostring(text) or (loading and cfg.LoadingText and tostring(cfg.LoadingText)) or self.Text
        textLabel.Visible = textLabel.Text ~= ""
        paint(0.1)
    end
    -- a short tick after a callback that took a while
    local function showDone()
        if cfg.Done == false or not spinner then return end
        doneToken = doneToken + 1
        local token = doneToken
        Icons.Apply(spinner, "check")
        spinner.Rotation = 0
        spinner.Visible = true
        if icon and not iconRight then icon.Visible = false end
        task.delay(1.2, function()
            if token ~= doneToken or loading or not spinner.Parent then return end
            spinner.Visible = false
            Icons.Apply(spinner, "loader-circle")
            if icon then icon.Visible = true end
        end)
    end

    ------------------------------------------------------------ cooldown
    local coolToken = 0
    local cooldown = tonumber(cfg.Cooldown) or 0
    local function endCooldown()
        coolToken = coolToken + 1
        cooling = false
        element.CoolingDown = false
        timer.Visible = false
        layoutRight()
        fill.BackgroundTransparency = 1
        fill.Size = UDim2.fromScale(0, 1)
        paint(0.1)
    end
    local function startCooldown()
        if cooldown <= 0 then return end
        coolToken = coolToken + 1
        local token = coolToken
        cooling = true
        element.CoolingDown = true
        local _, transparency = fillRole()
        fill.Size = UDim2.fromScale(1, 1)
        fill.BackgroundTransparency = transparency
        Util.tween(fill, cooldown, { Size = UDim2.fromScale(0, 1) }, Enum.EasingStyle.Linear)
        timer.Visible = true
        timer.Text = string.format("%.1fs", cooldown)
        layoutRight()
        paint(0.1)
        local finish = os.clock() + cooldown
        task.spawn(function()
            while token == coolToken and button.Parent do
                local left = finish - os.clock()
                if left <= 0 then break end
                timer.Text = left >= 10 and string.format("%ds", math.ceil(left)) or string.format("%.1fs", left)
                task.wait(0.1)
            end
            if token == coolToken then endCooldown() end
        end)
    end
    function element:SetCooldown(seconds) cooldown = tonumber(seconds) or 0 end
    function element:ResetCooldown() if cooling then endCooldown() end end

    ------------------------------------------------------------ running the callback
    local function run(...)
        if busy or element.Locked then return end
        busy = true
        local args = table.pack(...)
        local finished, ok = false, nil
        task.spawn(function()
            ok = element:_call(cfg.Callback, table.unpack(args, 1, args.n))
            finished = true
            busy = false
            if loading then
                element:SetLoading(false)
                if ok ~= false then showDone() end
            end
            if ok ~= false then startCooldown() end
        end)
        -- still running after the first yield: show the spinner (Loading = false keeps the button as it is)
        if not finished and cfg.Loading ~= false then element:SetLoading(true) end
    end

    local function activate()
        if element.Locked or loading or cooling or busy then return end
        if isToggle then
            element:Set(not element.Value)
        elseif menu then
            run(element.Selected)
        else
            run()
        end
    end

    ------------------------------------------------------------ toggle mode
    function element:Set(value, silent)
        if not isToggle then return end
        value = value == true
        local changed = value ~= self.Value
        self.Value = value
        if cfg.OnTitle then self:SetTitle(value and cfg.OnTitle or (cfg.Title or "")) end
        if cfg.OnIcon and icon then Icons.Apply(icon, value and cfg.OnIcon or cfg.Icon) end
        paint(0.12)
        if silent or not changed then
            self:_fire(value, true)
        else
            -- (the callback runs through _fire so Flag / OnChanged / errors work like any toggle)
            self:_fire(value, false)
            startCooldown()
        end
    end
    function element:Get() return self.Value end

    ------------------------------------------------------------ hold to confirm
    local holdTime = tonumber(cfg.Hold) or 0
    local holdToken = 0
    local function cancelHold()
        if not holding then return end
        holding = false
        holdToken = holdToken + 1
        Util.tween(fill, 0.15, { Size = UDim2.fromScale(0, 1) })
        task.delay(0.16, function() if not holding and not cooling then fill.BackgroundTransparency = 1 end end)
    end
    local function startHold()
        if element.Locked or loading or cooling or busy or holding then return end
        holding = true
        holdToken = holdToken + 1
        local token = holdToken
        local _, transparency = fillRole()
        fill.Size = UDim2.fromScale(0, 1)
        fill.BackgroundTransparency = transparency
        Util.tween(fill, holdTime, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Linear)
        task.delay(holdTime, function()
            if token ~= holdToken or not holding or not button.Parent then return end
            holding = false
            fill.BackgroundTransparency = 1
            fill.Size = UDim2.fromScale(0, 1)
            require("sounds").Play("click")
            activate()
        end)
    end
    element.Hold = holdTime > 0 and holdTime or nil

    ------------------------------------------------------------ key bind
    local bindable = cfg.Bindable == true or cfg.Bind ~= nil
    function element:SetBind(key)
        key = Util.toKey(key)
        self.BindKey = key
        window:_bind(self, key)
        keyCap.Visible = key ~= nil
        if key then
            keyText.Text = Util.keyName(key)
            keyCap.Size = UDim2.fromOffset(math.max(16, Util.textWidth(keyText.Text, 8, Enum.Font.GothamMedium) + 10), keyCap.Size.Y.Offset)
        end
        layoutRight()
    end
    function element:_onBind()
        if holdTime > 0 then startHold() else activate() end
    end
    function element:_onRelease() if holdTime > 0 then cancelHold() end end
    function element:_onConflict() paint(0) end
    if bindable then
        element:SetBind(cfg.Bind)
        button.MouseButton2Click:Connect(function()
            if element.Locked then return end
            keyCap.Visible, keyText.Text = true, "..."
            keyCap.Size = UDim2.fromOffset(24, keyCap.Size.Y.Offset)
            layoutRight()
            window._capture = function(key)
                if key == Enum.KeyCode.Escape or key == window.key then element:SetBind(element.BindKey)
                elseif key == Enum.KeyCode.Backspace then element:SetBind(nil)
                else element:SetBind(key) end
            end
        end)
    end

    ------------------------------------------------------------ split button menu
    local popup
    function element:Select(option, silent)
        option = option ~= nil and tostring(option) or nil
        local known = false
        for _, entry in ipairs(menu or {}) do if entry.Title == option then known = true end end
        if not known then return end
        self.Selected = option
        if selectedLabel then
            selectedLabel.Text = option
            selectedLabel.Visible = true
            task.defer(fit)
        end
        if not silent then run(option) end
    end
    function element:SetMenu(list)
        if not menu then return end
        menu = entries(list)
        local still = false
        for _, entry in ipairs(menu) do if entry.Title == self.Selected then still = true end end
        if not still then
            self.Selected = nil
            if menu[1] then self:Select(menu[1].Title, true) elseif selectedLabel then selectedLabel.Visible = false end
        end
    end
    local function closeMenu()
        if popup then popup:Destroy() popup = nil end
    end
    local function openMenu()
        closeMenu()
        local position, buttonSize = Util.screenPos(button), button.AbsoluteSize
        local viewport = Util.viewport()
        local scale = window.scale and window.scale.Scale or 1
        local width = math.max(buttonSize.X / scale, 140)
        local total = #menu * ITEM + 8
        local roomBelow = viewport.Y - 8 - (position.Y + buttonSize.Y + 4)
        local below = roomBelow >= total * scale or roomBelow >= position.Y
        popup = create("Frame", {
            Name = "ButtonMenu", BorderSizePixel = 0, ZIndex = 260, Size = UDim2.fromOffset(width, total),
            Position = UDim2.fromOffset(math.clamp(position.X + buttonSize.X - width * scale, 8, math.max(8, viewport.X - width * scale - 8)),
                below and position.Y + buttonSize.Y + 4 or position.Y - 4 - total * scale),
            Parent = window.gui,
        })
        create("UIScale", { Scale = scale, Parent = popup })
        Theme.bind(popup, "BackgroundColor3", "input")
        corner(popup, 6)
        Theme.bind(stroke(popup), "Color", "buttonEdge")
        Util.padding(popup, 4, 4, 4, 4)
        Util.list(popup, 0)
        for index, entry in ipairs(menu) do
            local item = create("TextButton", {
                Name = entry.Title, Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, ITEM), LayoutOrder = index, ZIndex = 261, Parent = popup,
            })
            Theme.bind(item, "BackgroundColor3", "hover")
            corner(item, 5)
            local x = 8
            if entry.Icon and Icons.Get(entry.Icon) then
                Icons.themed(item, entry.Icon, 12, "muted", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0), ZIndex = 262 })
                x = 26
            end
            local text = Util.label(item, entry.Title, 10, { Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -x - 20, 1, 0), ZIndex = 262 })
            local chosen = entry.Title == element.Selected
            Theme.bind(text, "TextColor3", chosen and "heading" or "text")
            if chosen then
                local dot = create("Frame", { Name = "Check", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, ZIndex = 262, Parent = item })
                Theme.bind(dot, "BackgroundColor3", "accent")
                corner(dot, 3)
            end
            item.MouseEnter:Connect(function() Util.tween(item, 0.08, { BackgroundTransparency = 0 }) end)
            item.MouseLeave:Connect(function() Util.tween(item, 0.08, { BackgroundTransparency = 1 }) end)
            item.Activated:Connect(function()
                window:_closePopup()
                require("sounds").Play("click")
                if element.Locked or loading or cooling or busy then return end
                element:Select(entry.Title)
            end)
        end
        window:_openPopup(popup, arrow, closeMenu)
    end
    if menu then
        local first = cfg.Selected ~= nil and tostring(cfg.Selected) or (menu[1] and menu[1].Title)
        element:Select(first, true)
        arrow.Activated:Connect(function()
            if element.Locked then return end
            if popup then window:_closePopup() else openMenu() end
        end)
    end

    ------------------------------------------------------------ saving (Flag): toggle value, menu choice, key
    if cfg.Flag then
        function element:_save()
            return { Value = isToggle and self.Value or nil, Selected = self.Selected, Bind = self.BindKey and Util.keyName(self.BindKey) or nil }
        end
        function element:_load(data)
            if type(data) ~= "table" then data = { Value = data } end
            if bindable and data.Bind ~= nil then self:SetBind(data.Bind) end
            if menu and data.Selected ~= nil then self:Select(data.Selected, true) end
            if isToggle and data.Value ~= nil then self:Set(data.Value == true) end
        end
    end

    paint(0)
    if isToggle then element:_fire(element.Value, true) end

    function element:Fire() activate() end

    button.MouseEnter:Connect(function() hovered = true paint(0.12) end)
    button.MouseLeave:Connect(function()
        hovered = false
        paint(0.12)
        cancelHold()
    end)
    if holdTime > 0 then
        button.InputBegan:Connect(function(input) if Util.isPress(input) then startHold() end end)
        button.InputEnded:Connect(function(input) if Util.isPress(input) then cancelHold() end end)
    end
    local armed = 0
    button.Activated:Connect(function()
        if holdTime > 0 then return end -- (a Hold button runs when the fill completes)
        require("sounds").Play("click")
        if element.Locked or loading or cooling or busy then return end
        if cfg.Confirm then
            if armed == 0 then
                armed = armed + 1
                local token = armed
                local ask = type(cfg.Confirm) == "string" and cfg.Confirm or nil
                if not ask then
                    -- the longest wording that fits the button (half-width buttons in a Row get the short one)
                    local room = button.AbsoluteSize.X / (window.scale and window.scale.Scale or 1) - 20 - ((icon and icon.Visible) and (iconSize + 6) or 0)
                    ask = "Sure?"
                    for _, wording in ipairs({ "Click again to confirm", "Click again" }) do
                        if Util.textWidth(wording, textSize, Enum.Font.Gotham) <= room then ask = wording break end
                    end
                end
                textLabel.Text = ask
                textLabel.Visible = true
                Theme.tweenTo(outline, "Color", "accent", 0.1)
                outline.Transparency = 0
                task.delay(2, function()
                    if armed == token and button.Parent then
                        armed = 0
                        element:SetTitle(element.Text)
                        paint(0.1)
                    end
                end)
                return
            end
            armed = 0
            element:SetTitle(element.Text)
            paint(0.1)
        end
        activate()
    end)
    return Base.finish(element, cfg)
end
end

__modules["elements/changelog"] = function()
-- card:Changelog({ Items = {
--     { Version = "V1.00 · rev 571", Time = "now", Items = { "Click TP: the game's own teleport", "ESP: bars under the feet" } },
--     { Version = "rev 560", Time = "3 days ago", Items = { "Crosshair from the library" } },
-- }, Open = 1 })
-- Release notes: one row per version (bold version, muted time, a chevron); click a row to open its bullet list.
-- The Open-th entry starts open (0 = none). :SetItems(entries), :Open(index). No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, label = Util.create, Util.label
local BULLET = 12 -- (the text starts this far right of the bullet)

return function(card, cfg)
    local holder = create("Frame", { Name = tostring(cfg.Title or "Changelog"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = card:_order(), Parent = card.body })
    Util.list(holder, 0)
    local element = Base.element(card, "Changelog", { Title = cfg.Title }, holder, nil, nil)
    local entries = {}
    function element:Open(index)
        for i, entry in ipairs(entries) do
            local open = i == index and not entry.body.Visible
            entry.body.Visible = open
            if entry.chevron then Util.tween(entry.chevron, 0.15, { Rotation = open and 180 or 0 }) end
        end
    end
    function element:SetItems(list)
        for _, entry in ipairs(entries) do entry.frame:Destroy() end
        table.clear(entries)
        for index, data in ipairs(list or {}) do
            local frame = create("Frame", { Name = tostring(data.Version or index), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = index, Parent = holder })
            Util.list(frame, 0)
            local head = create("TextButton", { Name = "Head", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 1, Parent = frame })
            local version = label(head, tostring(data.Version or ""), 10, { Name = "Version", Size = UDim2.new(0, Util.textWidth(tostring(data.Version or ""), 10, Enum.Font.GothamBold) + 4, 1, 0), Font = Enum.Font.GothamBold })
            Theme.bind(version, "TextColor3", "heading")
            local time = label(head, tostring(data.Time or ""), 9, { Name = "Time", Position = UDim2.fromOffset(version.Size.X.Offset + 6, 0), Size = UDim2.new(1, -version.Size.X.Offset - 30, 1, 0) })
            Theme.bind(time, "TextColor3", "muted")
            local chevron = Icons.themed(head, "chevron-down", 12, "muted", { Name = "Chevron", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0) })
            local body = create("Frame", { Name = "Items", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Visible = false, Parent = frame })
            Util.list(body, 1)
            Util.padding(body, 8, 0, 0, 6)
            local lines = {}
            for order, text in ipairs(data.Items or {}) do
                -- the bullet on its own, the text beside it (a wrapped line starts under the text, not the bullet)
                local item = create("Frame", { Name = "Item", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = order, Parent = body })
                local dot = label(item, "•", 10, { Name = "Bullet", Size = UDim2.fromOffset(10, 13), TextYAlignment = Enum.TextYAlignment.Top })
                Theme.bind(dot, "TextColor3", "muted")
                local words = label(item, tostring(text), 10, { Name = "Text", Position = UDim2.fromOffset(BULLET, 0), Size = UDim2.new(1, -BULLET, 1, 0), TextWrapped = true, TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top })
                Theme.bind(words, "TextColor3", "text")
                lines[#lines + 1] = { frame = item, text = words }
            end
            -- each note as tall as its wrapped lines (measured from the text width, not left to AutomaticSize)
            local function wrap()
                local scale = card.window.scale and card.window.scale.Scale or 1
                local width = body.AbsoluteSize.X / scale - 8 - BULLET
                if width < 40 then return end
                for _, item in ipairs(lines) do
                    local count = math.max(1, math.ceil((Util.textWidth(item.text.Text, 10, Enum.Font.Gotham) * 1.08 + 6) / width))
                    item.frame.Size = UDim2.new(1, 0, 0, count * 13 + 1)
                end
            end
            body:GetPropertyChangedSignal("AbsoluteSize"):Connect(wrap)
            body:GetPropertyChangedSignal("Visible"):Connect(function() task.defer(wrap) end)
            task.defer(wrap)
            local line = create("Frame", { Name = "Line", Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, LayoutOrder = 3, Parent = frame })
            Theme.bind(line, "BackgroundColor3", "line")
            local entry = { frame = frame, body = body, chevron = chevron }
            entries[index] = entry
            head.Activated:Connect(function() element:Open(index) end)
        end
        local open = tonumber(cfg.Open) or 1
        if entries[open] then entries[open].body.Visible = true if entries[open].chevron then entries[open].chevron.Rotation = 180 end end
    end
    element:SetItems(cfg.Items)
    return Base.finish(element, cfg)
end
end

__modules["elements/checkbox"] = function()
-- card:Checkbox({ Title, Desc, Flag, Default = false, Callback = function(on) end, Locked })
-- A plain tick box before the title: lighter than a Toggle for lists of options. Click the row or the box.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local row, title, desc = Base.row(card, cfg, cfg.Desc and 40 or 28, { button = true, noIcon = true })
    -- the box sits where an icon would; title / description move right of it
    local box = create("Frame", { Name = "Box", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0, cfg.Desc and 12 or 14), Size = UDim2.fromOffset(16, 16), BorderSizePixel = 0, Parent = row })
    corner(box, 4)
    local edge = stroke(box)
    local tick = Icons.themed(box, "check", 12, "onAccent", { Name = "Tick", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
    title.Position = UDim2.new(0, 26, 0, title.Position.Y.Offset)
    title.Size = UDim2.new(1, -26 - (cfg.Help and 16 or 0), 0, title.Size.Y.Offset)
    if desc then desc.Position = UDim2.fromOffset(26, 23) desc.Size = UDim2.new(1, -26, 0, 14) end

    local element = Base.element(card, "Checkbox", cfg, row, title, desc)
    element.Value = cfg.Default == true
    local hovered = false
    local function render(animate)
        local on = element.Value
        local duration = animate and 0.12 or nil
        Theme.tweenTo(box, "BackgroundColor3", on and "accent" or (hovered and "hover" or "input"), duration)
        Theme.tweenTo(edge, "Color", on and "accent" or "buttonEdge", duration)
        if tick then tick.Visible = on end
    end
    function element:Set(value, silent)
        value = value == true
        local changed = value ~= self.Value
        self.Value = value
        render(true)
        self:_fire(value, silent or not changed)
    end
    function element:Get() return self.Value end

    row.Activated:Connect(function() if not element.Locked then element:Set(not element.Value) end end)
    row.MouseEnter:Connect(function() hovered = true render(true) Theme.tweenTo(title, "TextColor3", cfg.Risky and "danger" or "heading", 0.12) end)
    row.MouseLeave:Connect(function() hovered = false render(true) Theme.tweenTo(title, "TextColor3", cfg.Risky and "danger" or "text", 0.12) end)
    render(false)
    element:_fire(element.Value, true)
    return Base.finish(element, cfg)
end
end

__modules["elements/checklist"] = function()
-- card:Checklist({ Items = { { Title = "File access", Ok = true, Note = "profiles, icons" }, { Title = "getconnections", Ok = false, Note = "Anti-AFK" } } })
-- A list of checks: a green tick or a red cross, the name, a muted note on the right. Ok = nil shows a grey dash
-- (unknown / not checked). :Set(title, ok, note), :Count() -> passed, total. No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, label = Util.create, Util.label

return function(card, cfg)
    local holder = create("Frame", { Name = tostring(cfg.Title or "Checklist"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = card:_order(), Parent = card.body })
    Util.list(holder, 0)
    local element = Base.element(card, "Checklist", { Title = cfg.Title }, holder, nil, nil)
    local rows, order = {}, {}
    local function paint(row)
        local icon = row.ok == true and "check" or row.ok == false and "x" or "minus"
        local role = row.ok == true and "success" or row.ok == false and "danger" or "muted"
        if row.icon then row.icon:Destroy() end
        row.icon = Icons.themed(row.frame, icon, 12, role, { Name = "Mark", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) })
        row.note.Text = tostring(row.noteText or "")
    end
    for index, item in ipairs(cfg.Items or {}) do
        local frame = create("Frame", { Name = tostring(item.Title or index), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = index, Parent = holder })
        local title = label(frame, tostring(item.Title or ""), 10, { Name = "Title", Position = UDim2.fromOffset(20, 0), Size = UDim2.new(0.6, -20, 1, 0) })
        Theme.bind(title, "TextColor3", "text")
        local note = label(frame, "", 9, { Name = "Note", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.4, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Right })
        Theme.bind(note, "TextColor3", "muted")
        local row = { frame = frame, note = note, ok = item.Ok, noteText = item.Note }
        rows[tostring(item.Title)] = row
        order[#order + 1] = row
        paint(row)
    end
    function element:Set(titleText, ok, note)
        local row = rows[tostring(titleText)]
        if not row then return end
        row.ok = ok
        if note ~= nil then row.noteText = note end
        paint(row)
    end
    function element:Count()
        local passed = 0
        for _, row in ipairs(order) do if row.ok == true then passed = passed + 1 end end
        return passed, #order
    end
    return Base.finish(element, cfg)
end
end

__modules["elements/chips"] = function()
-- card:Chips({ Title, Flag, Items = { "ESP", { Title = "Silent Aim", Icon = "crosshair" }, ... }, Multi = true,
--              Default = { "ESP" }, Callback = function(value) end })
-- A wrapping row of rounded chips. Multi = true: each chip turns on / off (value = list of names);
-- Multi = false: one chosen at a time (value = the name). Lit chips get the accent outline.
-- :Set(value), :Get(), :SetItems(items).
-- Static = true: chips that only show something (values, tags): no clicking, no flag; :SetItems to change them.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local multi = cfg.Multi ~= false
    local top = cfg.Title and 22 or 0
    local holder = create("Frame", { Name = tostring(cfg.Title or "Chips"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, top + 24), LayoutOrder = card:_order(), Parent = card.body })
    local title
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Size = UDim2.new(1, 0, 0, 20) })
        Theme.bind(title, "TextColor3", "text")
    end
    local area = create("Frame", { Name = "Chips", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 1, -top), Parent = holder })
    local element = Base.element(card, "Chips", cfg, holder, title, nil)
    local chips = {}
    local function chosen(name)
        if multi then return type(element.Value) == "table" and table.find(element.Value, name) ~= nil end
        return element.Value == name
    end
    local function render()
        for _, chip in ipairs(chips) do
            local on = chosen(chip.name)
            Theme.tweenTo(chip.button, "BackgroundColor3", on and "selected" or "input", 0.1)
            Theme.tweenTo(chip.edge, "Color", on and "accent" or "buttonEdge", 0.1)
            chip.edge.Transparency = on and 0.35 or 0.3
            Theme.tweenTo(chip.text, "TextColor3", on and "heading" or "muted", 0.1)
            if chip.icon then Theme.tweenTo(chip.icon, "ImageColor3", on and "heading" or "muted", 0.1) end
        end
    end
    -- lays the chips out left to right, wrapping (sizes from the text)
    local function layout()
        local width = area.AbsoluteSize.X / (card.window.scale and card.window.scale.Scale or 1)
        if width <= 0 then width = 400 end
        local x, y = 0, 0
        for _, chip in ipairs(chips) do
            local w = chip.width
            if x > 0 and x + w > width then x, y = 0, y + 28 end
            chip.button.Position = UDim2.fromOffset(x, y)
            x = x + w + 6
        end
        holder.Size = UDim2.new(1, 0, 0, top + y + 24)
    end
    function element:SetItems(items)
        for _, chip in ipairs(chips) do chip.button:Destroy() end
        table.clear(chips)
        for index, item in ipairs(items or {}) do
            if type(item) ~= "table" then item = { Title = item } end
            local name = tostring(item.Title)
            local iconW = item.Icon and 16 or 0
            local width = Util.textWidth(name, 10, Enum.Font.GothamMedium) + 22 + iconW
            local button = create("TextButton", { Name = name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Size = UDim2.fromOffset(width, 24), LayoutOrder = index, Parent = area })
            corner(button, 12)
            local edge = Util.stroke(button, nil, 0.3)
            local icon = item.Icon and Icons.themed(button, item.Icon, 11, "muted", { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0) })
            local text = label(button, name, 10, { Name = "Text", Position = UDim2.fromOffset(11 + (icon and 15 or 0), 0), Size = UDim2.new(1, -16, 1, 0), Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.None })
            local chip = { name = name, button = button, edge = edge, text = text, icon = icon, width = width }
            chips[#chips + 1] = chip
            button.Activated:Connect(function()
                if element.Locked or cfg.Static then return end
                if multi then
                    local value = table.clone(type(element.Value) == "table" and element.Value or {})
                    local at = table.find(value, name)
                    if at then table.remove(value, at) else value[#value + 1] = name end
                    element:Set(value)
                else
                    element:Set(name)
                end
            end)
        end
        layout()
        render()
    end
    function element:Set(value, silent)
        if multi and type(value) ~= "table" then value = value ~= nil and { value } or {} end
        self.Value = value
        render()
        self:_fire(value, silent)
    end
    function element:Get() return self.Value end
    area:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
    element:SetItems(cfg.Items)
    element.Value = cfg.Default ~= nil and cfg.Default or (multi and {} or nil)
    if multi and type(element.Value) ~= "table" then element.Value = { element.Value } end
    render()
    element:_fire(element.Value, true)
    return Base.finish(element, cfg)
end
end

__modules["elements/code"] = function()
-- card:Code({ Title = "loader.lua", Code = "print('hi')", Copy = true, MaxHeight = 200 })
-- A code block: monospace, Lua colouring (keywords, strings, numbers, comments, functions), scrolls sideways for long
-- lines and down past MaxHeight. Copy button in the header. :Set(code).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

local KEYWORDS = {}
for word in ("and break do else elseif end false for function if in local nil not or repeat return then true until while continue"):gmatch("%a+") do KEYWORDS[word] = true end
local GLOBALS = {}
for word in ("game workspace script task math string table print warn pcall require loadstring getgenv Instance Vector3 Vector2 CFrame UDim2 Color3 Enum"):gmatch("%a+") do GLOBALS[word] = true end
-- colours come from the theme (codeKeyword...), so light packs get darker ones
local ROLES = { keyword = "codeKeyword", string = "codeString", number = "codeNumber", comment = "codeComment", global = "codeGlobal", call = "codeCall" }

local function escape(text) return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
local function paint(kind, text) return '<font color="#' .. Util.toHex(Theme.get(ROLES[kind])) .. '">' .. escape(text) .. "</font>" end

-- Small Lua tokenizer -> RichText (one pass, no nesting issues).
local function highlight(source)
    local out, i, n = {}, 1, #source
    while i <= n do
        local c = source:sub(i, i)
        if source:sub(i, i + 1) == "--" then
            local long = source:match("^%-%-%[(=*)%[", i)
            local stop
            if long then stop = select(2, source:find("%]" .. long .. "%]", i)) end
            stop = stop or (source:find("\n", i) or n + 1) - 1
            out[#out + 1] = paint("comment", source:sub(i, stop))
            i = stop + 1
        elseif c == '"' or c == "'" then
            local j = i + 1
            while j <= n do
                local d = source:sub(j, j)
                if d == "\\" then j = j + 2 elseif d == c or d == "\n" then break else j = j + 1 end
            end
            out[#out + 1] = paint("string", source:sub(i, j))
            i = j + 1
        elseif source:match("^%[=*%[", i) then
            local eq = source:match("^%[(=*)%[", i)
            local stop = select(2, source:find("%]" .. eq .. "%]", i)) or n
            out[#out + 1] = paint("string", source:sub(i, stop))
            i = stop + 1
        elseif c:match("%d") then
            local number = source:match("^0[xX]%x+", i) or source:match("^%d+%.?%d*[eE][%-+]?%d+", i) or source:match("^%d+%.?%d*", i)
            out[#out + 1] = paint("number", number)
            i = i + #number
        elseif c:match("[%a_]") then
            local word = source:match("^[%w_]+", i)
            local after = source:match("^%s*(.)", i + #word)
            if KEYWORDS[word] then out[#out + 1] = paint("keyword", word)
            elseif GLOBALS[word] then out[#out + 1] = paint("global", word)
            elseif after == "(" then out[#out + 1] = paint("call", word)
            else out[#out + 1] = escape(word) end
            i = i + #word
        else
            out[#out + 1] = escape(c)
            i = i + 1
        end
    end
    return table.concat(out)
end

return function(card, cfg)
    local window = card.window
    local maxHeight = tonumber(cfg.MaxHeight) or 200
    local holder = create("Frame", { Name = tostring(cfg.Title or "Code"), Size = UDim2.new(1, 0, 0, 60), BorderSizePixel = 0, LayoutOrder = card:_order(), Parent = card.body })
    Theme.bind(holder, "BackgroundColor3", "base")
    corner(holder, 7)
    Theme.bind(stroke(holder), "Color", "line")
    local head = create("Frame", { Name = "Head", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), Parent = holder })
    Icons.themed(head, "code", 12, "muted", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0) })
    local title = label(head, tostring(cfg.Title or "Code"), 10, { Name = "Title", Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -90, 1, 0), Font = Enum.Font.GothamMedium })
    Theme.bind(title, "TextColor3", "text")
    local line = create("Frame", { Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = holder })
    Theme.bind(line, "BackgroundColor3", "line")
    local scroller = create("ScrollingFrame", {
        Name = "Body", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 27), Size = UDim2.new(1, 0, 1, -27),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.XY, ScrollBarThickness = 3, Parent = holder,
    })
    Theme.bind(scroller, "ScrollBarImageColor3", "muted")
    Util.fadeScrollbar(scroller)
    local text = create("TextLabel", {
        Name = "Code", BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY,
        Font = Enum.Font.Code, TextSize = 11, RichText = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = false, Text = "", Parent = scroller,
    })
    text:SetAttribute("QCode", true) -- the code font (Sono Mono / CreateWindow CodeFont)
    Theme.bind(text, "TextColor3", "heading")
    create("UIPadding", { PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 10), Parent = text })

    local element = Base.element(card, "Code", {}, holder, title, nil)
    local function fit()
        local lines = select(2, (element.Value or ""):gsub("\n", "\n")) + 1
        holder.Size = UDim2.new(1, 0, 0, math.min(maxHeight, 27 + 18 + lines * 14))
    end
    function element:Set(code)
        self.Value = tostring(code or "")
        text.Text = cfg.Highlight == false and self.Value:gsub("<", "&lt;") or highlight(self.Value)
        fit()
    end
    function element:Get() return self.Value end

    if cfg.Copy ~= false then
        local copy = create("TextButton", {
            Name = "Copy", Text = "", AutoButtonColor = false, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(52, 18), Parent = head,
        })
        Theme.bind(copy, "BackgroundColor3", "input")
        corner(copy, 5)
        Theme.bind(stroke(copy), "Color", "buttonEdge")
        local copyText = label(copy, "Copy", 9, { Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -22, 1, 0), Font = Enum.Font.GothamMedium })
        Theme.bind(copyText, "TextColor3", "text")
        local copyIcon = Icons.themed(copy, "copy", 10, "text", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 7, 0.5, 0) })
        copy.Activated:Connect(function()
            local clipboard = setclipboard or toclipboard
            local ok = type(clipboard) == "function" and pcall(clipboard, element.Value)
            copyText.Text = ok and "Copied" or "Failed"
            if copyIcon then Icons.Apply(copyIcon, ok and "check" or "x") end
            if ok and cfg.OnCopy then window:_safe("Code", cfg.OnCopy) end
            task.delay(1.4, function()
                if copy.Parent then copyText.Text = "Copy" if copyIcon then Icons.Apply(copyIcon, "copy") end end
            end)
        end)
    end
    element:Set(cfg.Code or "")
    Theme.onChange(function() if holder.Parent then element:Set(element.Value) end end)
    return element
end
end

__modules["elements/colorpicker"] = function()
-- card:ColorPicker({ Title, Desc, Flag, Default = Color3, Callback = function(color) end, Locked })
-- Click the swatch to open the picker under the row: saturation / brightness square, hue bar, HEX box, Random, Rainbow.
-- Apply = true: edits only preview until Apply is pressed (closing without Apply reverts).
-- Rainbow = true / :SetRainbow(on): cycles the hue (RainbowSpeed = seconds per cycle, default 5); saved with the config.
-- Alpha = true (or Transparency = 0.3): a transparency bar under the hue; Callback(color, transparency),
-- element.Transparency, :SetTransparency(0-1). Saved with the colour.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

local HUE = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)), ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
    ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)), ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
    ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)), ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
    ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
})

return function(card, cfg)
    local window = card.window
    local row, title, desc = Base.row(card, cfg, cfg.Desc and 40 or 30, { right = 60, button = true })
    local swatch = create("TextButton", {
        Name = "Swatch", Text = "", AutoButtonColor = false, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(34, 18), Parent = row,
    })
    corner(swatch, 5)
    Theme.bind(stroke(swatch, nil, 0.2), "Color", "buttonEdge")

    -- panel (opens under the row)
    local panel = create("Frame", {
        Name = "Picker", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 158), LayoutOrder = row.LayoutOrder + 1,
        Visible = false, Parent = card.body,
    })
    local square = create("TextButton", {
        Name = "Square", Text = "", AutoButtonColor = false, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 4),
        Size = UDim2.new(1, -104, 0, 104), Parent = panel,
    })
    corner(square, 6)
    local white = create("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), Parent = square })
    corner(white, 6)
    create("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
    local black = create("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0), Parent = square })
    corner(black, 6)
    create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = black })
    local cursor = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(8, 8), BackgroundTransparency = 1, ZIndex = 3, Parent = square })
    corner(cursor, 4)
    stroke(cursor, Color3.new(1, 1, 1), 0, 1.5)
    local hueBar = create("TextButton", {
        Name = "Hue", Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
        Position = UDim2.fromOffset(0, 116), Size = UDim2.new(1, -104, 0, 10), Parent = panel,
    })
    corner(hueBar, 5)
    create("UIGradient", { Color = HUE, Parent = hueBar })
    local hueCursor = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(4, 14), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3, Parent = hueBar })
    corner(hueCursor, 2)
    -- transparency bar: the colour fading out to the right, over a dark / light split so the fade shows
    local alphaMode = cfg.Alpha == true or tonumber(cfg.Transparency) ~= nil
    local alphaBar, alphaCursor
    if alphaMode then
        local backing = create("Frame", { Name = "AlphaBacking", BorderSizePixel = 0, Position = UDim2.fromOffset(0, 134), Size = UDim2.new(1, -104, 0, 10), Parent = panel })
        Theme.bind(backing, "BackgroundColor3", "input")
        corner(backing, 5)
        local light = create("Frame", { BorderSizePixel = 0, Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(1, 0.5), BackgroundColor3 = Color3.fromRGB(205, 205, 210), BackgroundTransparency = 0.55, Parent = backing })
        corner(light, 5)
        alphaBar = create("TextButton", { Name = "Alpha", Text = "", AutoButtonColor = false, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Parent = backing })
        corner(alphaBar, 5)
        create("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = alphaBar })
        Theme.bind(stroke(backing, nil, 0.3), "Color", "buttonEdge")
        alphaCursor = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(4, 14), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3, Parent = backing })
        corner(alphaCursor, 2)
        Theme.bind(stroke(alphaCursor, nil, 0.2), "Color", "base")
    end

    local side = create("Frame", { Name = "Side", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 4), Size = UDim2.fromOffset(92, 150), Parent = panel })
    local preview = create("Frame", { Name = "Preview", Size = UDim2.new(1, 0, 0, 26), BorderSizePixel = 0, Parent = side })
    corner(preview, 6)
    Theme.bind(stroke(preview, nil, 0.2), "Color", "buttonEdge")
    local hex = create("TextBox", {
        Name = "Hex", Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 24), BorderSizePixel = 0, Text = "",
        TextSize = 10, Font = Enum.Font.GothamMedium, ClearTextOnFocus = false, Parent = side,
    })
    Theme.bind(hex, "BackgroundColor3", "input")
    Theme.bind(hex, "TextColor3", "text")
    corner(hex, 6)
    Theme.bind(stroke(hex), "Color", "buttonEdge")
    local random = create("TextButton", {
        Name = "Random", Position = UDim2.fromOffset(0, 62), Size = UDim2.new(1, 0, 0, 24), BorderSizePixel = 0,
        Text = "Random", TextSize = 10, Font = Enum.Font.Gotham, AutoButtonColor = false, Parent = side,
    })
    Theme.bind(random, "BackgroundColor3", "input")
    Theme.bind(random, "TextColor3", "text")
    corner(random, 6)
    Theme.bind(stroke(random), "Color", "buttonEdge")
    local rainbow = create("TextButton", {
        Name = "Rainbow", Position = UDim2.fromOffset(0, 92), Size = UDim2.new(1, 0, 0, 24), BorderSizePixel = 0,
        Text = "Rainbow", TextSize = 10, Font = Enum.Font.Gotham, AutoButtonColor = false, Parent = side,
    })
    Theme.bind(rainbow, "BackgroundColor3", "input")
    Theme.bind(rainbow, "TextColor3", "text")
    corner(rainbow, 6)
    local rainbowEdge = stroke(rainbow)
    Theme.bind(rainbowEdge, "Color", "buttonEdge")
    local done = create("TextButton", {
        Name = "Done", Position = UDim2.fromOffset(0, 122), Size = UDim2.new(1, 0, 0, 24), BorderSizePixel = 0,
        Text = cfg.Apply and "Apply" or "Done", TextSize = 10, Font = Enum.Font.GothamMedium, AutoButtonColor = false, Parent = side,
    })
    Theme.bind(done, "BackgroundColor3", "accentDeep")
    Theme.bind(done, "TextColor3", "accent")
    corner(done, 6)
    Theme.bind(stroke(done, nil, 0.45), "Color", "accent")

    local element = Base.element(card, "ColorPicker", cfg, row, title, desc)
    local h, s, v = 0, 0, 1
    local alpha = math.clamp(tonumber(cfg.Transparency) or 0, 0, 1)
    element.Transparency = alpha

    local function render()
        local color = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3, preview.BackgroundColor3 = color, color
        square.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        cursor.Position = UDim2.fromScale(s, 1 - v)
        hueCursor.Position = UDim2.fromScale(h, 0.5)
        hex.Text = "#" .. Util.toHex(color)
        if alphaMode then
            alphaBar.BackgroundColor3 = color
            alphaCursor.Position = UDim2.fromScale(alpha, 0.5)
            preview.BackgroundTransparency = alpha
            swatch.BackgroundTransparency = alpha * 0.85
        end
    end
    local applyMode = cfg.Apply == true
    local function commit(silent, force)
        local color = Color3.fromHSV(h, s, v)
        if applyMode and not force and panel.Visible and not silent then render() swatch.BackgroundColor3 = element.Value or color return end
        local changed = color ~= element.Value or alpha ~= element.Transparency
        element.Value = color
        element.Transparency = alpha
        render()
        if alphaMode then element:_fire(color, silent or not changed, alpha) else element:_fire(color, silent or not changed) end
    end
    function element:Set(color, silent)
        if type(color) == "string" then color = Util.fromHex(color) end
        if typeof(color) ~= "Color3" then return end
        h, s, v = color:ToHSV()
        commit(silent, true)
    end
    function element:Get() return self.Value, self.Transparency end
    function element:SetTransparency(value, silent)
        alpha = math.clamp(tonumber(value) or 0, 0, 1)
        commit(silent, true)
    end
    function element:_save()
        if self.Rainbow or (alphaMode and self.Transparency > 0) then
            return { Color = Util.toHex(self.Value), Rainbow = self.Rainbow or nil, Alpha = alphaMode and self.Transparency or nil }
        end
        return Util.toHex(self.Value)
    end
    function element:_load(data)
        if type(data) == "table" then
            if alphaMode then alpha = math.clamp(tonumber(data.Alpha) or 0, 0, 1) end
            self:Set(data.Color)
            self:SetRainbow(data.Rainbow == true)
        else
            if alphaMode then alpha = 0 end
            self:SetRainbow(false)
            self:Set(data)
        end
    end
    local function revert()
        if applyMode and element.Value then h, s, v = element.Value:ToHSV() render() end
    end
    element._panel = panel
    function element:SetOpen(open)
        if not open then revert() end
        panel.Visible = open == true
        Base.trackPanel(window, self, open == true)
    end

    -- rainbow: hue walks around the wheel; callbacks are throttled to ~20 per second
    element.Rainbow = false
    local rainbowConnection
    local function renderRainbow()
        Theme.tweenTo(rainbow, "BackgroundColor3", element.Rainbow and "accentDeep" or "input", 0.1)
        Theme.tweenTo(rainbow, "TextColor3", element.Rainbow and "accent" or "text", 0.1)
        Theme.tweenTo(rainbowEdge, "Color", element.Rainbow and "accent" or "buttonEdge", 0.1)
    end
    function element:SetRainbow(on)
        on = on == true
        if on == self.Rainbow then return end
        self.Rainbow = on
        if rainbowConnection then rainbowConnection:Disconnect() rainbowConnection = nil end
        if on then
            local period = math.max(0.5, tonumber(cfg.RainbowSpeed) or 5)
            local last = 0
            rainbowConnection = window.maid:connect(Util.Services.RunService.Heartbeat, function()
                local now = os.clock()
                if now - last < 0.05 then return end
                last = now
                h = (now / period) % 1
                if s < 0.05 then s = 0.75 end
                commit(false, true)
            end)
        end
        renderRainbow()
    end

    local function drag(target, apply)
        target.InputBegan:Connect(function(input)
            if not Util.isPress(input) or element.Locked then return end
            local function move(point)
                local p, size = Util.screenPos(target), target.AbsoluteSize
                if size.X <= 0 or size.Y <= 0 then return end
                apply(math.clamp((point.X - p.X) / size.X, 0, 1), math.clamp((point.Y - p.Y) / size.Y, 0, 1))
                commit()
            end
            move(Util.pointer(input))
            window:_beginDrag(input, move)
        end)
    end
    drag(square, function(x, y) s, v = x, 1 - y end)
    drag(hueBar, function(x) h = math.min(x, 0.999) end)
    if alphaBar then drag(alphaBar, function(x) alpha = math.floor(x * 100 + 0.5) / 100 end) end
    hex.FocusLost:Connect(function()
        local color = Util.fromHex(hex.Text)
        if color then h, s, v = color:ToHSV() commit() else render() end
    end)
    random.Activated:Connect(function() if not element.Locked then h, s, v = math.random(), 0.45 + math.random() * 0.5, 0.6 + math.random() * 0.4 commit() end end)
    rainbow.Activated:Connect(function() if not element.Locked then element:SetRainbow(not element.Rainbow) end end)
    done.Activated:Connect(function()
        if applyMode then commit(false, true) end
        panel.Visible = false
    end)
    local function toggleOpen() if not element.Locked then element:SetOpen(not panel.Visible) end end
    row.Activated:Connect(toggleOpen)
    swatch.Activated:Connect(toggleOpen)

    local default = cfg.Default
    if type(default) == "string" then default = Util.fromHex(default) end
    element:Set(typeof(default) == "Color3" and default or Color3.new(1, 1, 1), true)
    renderRainbow()
    if cfg.Rainbow then element:SetRainbow(true) end
    return Base.finish(element, cfg)
end
end

__modules["elements/console"] = function()
-- card:Console({ Title = "Log", Height = 150, MaxLines = 200, Follow = true, Time = true, Copy = true })
-- A small log: console:Append("text", "info" | "success" | "warning" | "error"), :Print(...) (like print),
-- :Clear(), :SetFollow(on), :GetText(). Follow keeps the newest line in view, until you scroll up to read
-- (scrolling back to the bottom turns it on again). Old lines drop off past MaxLines.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

local LEVELS = { info = "text", success = "success", warning = "warning", warn = "warning", error = "danger", danger = "danger", debug = "muted" }

local function escape(text) return (tostring(text):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end

return function(card, cfg)
    local maxLines = math.max(1, math.floor(tonumber(cfg.MaxLines) or 200))
    local height = tonumber(cfg.Height) or 150
    local holder = create("Frame", { Name = tostring(cfg.Title or "Console"), Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, LayoutOrder = card:_order(), Parent = card.body })
    Theme.bind(holder, "BackgroundColor3", "base")
    corner(holder, 7)
    Theme.bind(stroke(holder), "Color", "line")
    local head = create("Frame", { Name = "Head", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), Parent = holder })
    Icons.themed(head, cfg.Icon or "terminal", 12, "muted", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0) })
    local title = label(head, tostring(cfg.Title or "Console"), 10, { Name = "Title", Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -150, 1, 0), Font = Enum.Font.GothamMedium })
    Theme.bind(title, "TextColor3", "text")
    local line = create("Frame", { Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = holder })
    Theme.bind(line, "BackgroundColor3", "line")
    local scroller = create("ScrollingFrame", {
        Name = "Lines", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 27), Size = UDim2.new(1, 0, 1, -27),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = holder,
    })
    Theme.bind(scroller, "ScrollBarImageColor3", "muted")
    Util.fadeScrollbar(scroller)
    local list = create("Frame", { Name = "List", BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = scroller })
    Util.list(list, 1)
    Util.padding(list, 0, 0, 0, 8)
    Util.fitCanvas(scroller, list)
    local empty = label(scroller, cfg.Empty or "Nothing logged yet", 10, { Name = "Empty", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })
    Theme.bind(empty, "TextColor3", "muted")

    local element = Base.element(card, "Console", {}, holder, title, nil)
    element.Lines = {}
    element.Follow = cfg.Follow ~= false
    local order = 0

    -- small header buttons: follow, clear, copy (right to left)
    local buttons = {}
    local function headButton(name, icon, tip, index, callback)
        local button = create("TextButton", {
            Name = name, Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -6 - (index - 1) * 24, 0.5, 0), Size = UDim2.fromOffset(20, 20), Parent = head,
        })
        corner(button, 5)
        Theme.bind(button, "BackgroundColor3", "input")
        local image = Icons.themed(button, icon, 12, "muted", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
        button.MouseEnter:Connect(function()
            Util.tween(button, 0.1, { BackgroundTransparency = 0 })
            card.window:_tip(tip)
        end)
        button.MouseLeave:Connect(function()
            Util.tween(button, 0.1, { BackgroundTransparency = 1 })
            card.window:_hideTip()
        end)
        button.Activated:Connect(callback)
        buttons[name] = { button = button, icon = image }
        return button
    end

    -- (the canvas grows after the layout pass, so following also listens to the canvas size)
    local autoScrolling = false
    local function scrollToEnd()
        if not scroller.Parent then return end
        autoScrolling = true
        -- the list's own height (6 px top offset) is known right after the layout, the canvas size may lag
        local content = math.max(scroller.AbsoluteCanvasSize.Y, list.AbsoluteSize.Y + 6)
        scroller.CanvasPosition = Vector2.new(0, math.max(0, content - scroller.AbsoluteWindowSize.Y))
        autoScrolling = false
    end
    scroller:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function() if element.Follow then scrollToEnd() end end)
    list:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() if element.Follow then scrollToEnd() end end)
    local function renderFollow()
        local entry = buttons.Follow
        if entry and entry.icon then Theme.bind(entry.icon, "ImageColor3", element.Follow and "accent" or "muted") end
    end
    function element:SetFollow(on)
        self.Follow = on ~= false
        renderFollow()
        if self.Follow then scrollToEnd() end
    end

    -- the user scrolling up stops follow; reaching the bottom again starts it
    scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if autoScrolling then return end
        local bottom = scroller.AbsoluteCanvasSize.Y - scroller.AbsoluteWindowSize.Y
        if bottom <= 0 then return end
        local atEnd = scroller.CanvasPosition.Y >= bottom - 4
        if atEnd ~= element.Follow then element.Follow = atEnd renderFollow() end
    end)

    function element:Append(text, level)
        level = LEVELS[tostring(level or "info"):lower()] and tostring(level or "info"):lower() or "info"
        text = tostring(text == nil and "" or text)
        local stamp = cfg.Time ~= false and os.date("%H:%M:%S") or nil
        order = order + 1
        local entry = { text = text, level = level, time = stamp }
        table.insert(self.Lines, entry)
        local row = label(list, "", 10, {
            Name = "Line", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None, RichText = true, Font = Enum.Font.Code, LayoutOrder = order,
            TextYAlignment = Enum.TextYAlignment.Top,
        })
        row:SetAttribute("QCode", true) -- the code font (Sono Mono / CreateWindow CodeFont)
        local function paint()
            local prefix = stamp and ('<font color="#' .. Util.toHex(Theme.get("muted")) .. '">' .. stamp .. "</font>  ") or ""
            row.Text = prefix .. escape(text)
        end
        paint()
        entry.label, entry.paint = row, paint
        Theme.bind(row, "TextColor3", LEVELS[level])
        empty.Visible = false
        while #self.Lines > maxLines do
            local old = table.remove(self.Lines, 1)
            if old.label then old.label:Destroy() end
        end
        if self.Follow then task.defer(scrollToEnd) end
        return entry
    end
    -- console:Print("a", 1, true) joins its values like print
    function element:Print(...)
        local parts = table.pack(...)
        for index = 1, parts.n do parts[index] = tostring(parts[index]) end
        return self:Append(table.concat(parts, " ", 1, parts.n))
    end
    function element:Log(text, level) return self:Append(text, level) end
    function element:Clear()
        for _, entry in ipairs(self.Lines) do if entry.label then entry.label:Destroy() end end
        self.Lines = {}
        empty.Visible = true
    end
    function element:GetText()
        local out = {}
        for _, entry in ipairs(self.Lines) do
            out[#out + 1] = (entry.time and ("[" .. entry.time .. "] ") or "") .. (entry.level ~= "info" and (entry.level:upper() .. ": ") or "") .. entry.text
        end
        return table.concat(out, "\n")
    end
    function element:SetTitle(text) title.Text = tostring(text) end
    function element:Get() return self:GetText() end

    if cfg.Copy ~= false then
        headButton("Copy", "copy", "Copy log", 1, function()
            local clipboard = setclipboard or toclipboard
            local ok = type(clipboard) == "function" and pcall(clipboard, element:GetText())
            local entry = buttons.Copy
            if entry.icon then
                Icons.Apply(entry.icon, ok and "check" or "x")
                task.delay(1.2, function() if entry.icon.Parent then Icons.Apply(entry.icon, "copy") end end)
            end
        end)
    end
    headButton("Clear", "trash-2", "Clear", cfg.Copy ~= false and 2 or 1, function() element:Clear() end)
    headButton("Follow", "arrow-down-to-line", "Follow new lines", cfg.Copy ~= false and 3 or 2, function() element:SetFollow(not element.Follow) end)
    renderFollow()
    -- timestamps keep the theme's muted colour
    Theme.onChange(function()
        if not holder.Parent then return end
        for _, entry in ipairs(element.Lines) do if entry.paint then entry.paint() end end
    end)
    for _, item in ipairs(cfg.Lines or {}) do
        if type(item) == "table" then element:Append(item[1] or item.Text, item[2] or item.Level) else element:Append(item) end
    end
    return element
end
end

__modules["elements/crosshairpreview"] = function()
-- card:CrosshairPreview({ Height = 110, Scale = 2 }) - a dark box with the crosshair drawn the way the settings
-- would draw it (2x by default) and its style in the corner. element:Update(settings) takes the settings of
-- Lib.Crosshair (Style, Color, Opacity, Outline, Length, Thickness, Gap, Spin, SpinSpeed, Enabled); a spinning
-- crosshair turns at the same speed as on screen while the preview is in view.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Crosshair = require("crosshair")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local window = card.window
    local box = create("Frame", {
        Name = "CrosshairPreview", Size = UDim2.new(1, 0, 0, cfg.Height or 110), BorderSizePixel = 0, ClipsDescendants = true,
        LayoutOrder = card:_order(), Parent = card.body,
    })
    Theme.bind(box, "BackgroundColor3", "base")
    corner(box, 6)
    Theme.bind(stroke(box), "Color", "line")
    local drawn = Crosshair.build(box, 2)
    drawn.root.Position = UDim2.fromScale(0.5, 0.5)
    local caption = Util.label(box, "", 8, { Name = "Caption", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -5), Size = UDim2.fromOffset(140, 12), TextXAlignment = Enum.TextXAlignment.Right })
    Theme.bind(caption, "TextColor3", "muted")

    local element = Base.element(card, "CrosshairPreview", {}, box, nil, nil)
    element.Settings = Crosshair.settings()
    local spinConnection, angle = nil, 0
    local function stopSpin()
        if spinConnection then spinConnection:Disconnect() spinConnection = nil end
    end
    if window and window.maid then window.maid:give(stopSpin) end
    function element:Update(changes)
        for key, value in pairs(changes or {}) do self.Settings[key] = value end
        local settings = self.Settings
        drawn.layout(settings, cfg.Scale or 2)
        caption.Text = (settings.Enabled == false and "Off · " or "") .. "Style: " .. tostring(settings.Style)
        if settings.Spin and not spinConnection then
            spinConnection = Util.Services.RunService.RenderStepped:Connect(function(dt)
                if not box.Parent then stopSpin() return end
                if not Util.shown(box) then return end
                angle = (angle + (tonumber(self.Settings.SpinSpeed) or 120) * dt) % 360
                drawn.root.Rotation = drawn.baseRotation + angle
            end)
        elseif not settings.Spin then
            stopSpin()
            angle = 0
        end
        if not settings.Spin then drawn.root.Rotation = drawn.baseRotation end
    end
    element:Update(cfg.Settings)
    return Base.finish(element, cfg)
end
end

__modules["elements/difflist"] = function()
-- card:DiffList({ Empty = "No changes", OnRevert = function(row, index) end, Items = {
--     { Tag = "ESP", Title = "Max distance", Old = "1000", New = "1500" },
-- } })
-- What changed: per row a small tag, the setting, the old value struck through in red, an arrow and the new value
-- in green, and (with OnRevert) a small undo button. :SetItems(rows), :GetItems(), :Count(). No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")
local Parts = require("elements/parts")

local create, label = Util.create, Util.label

return function(card, cfg)
    local holder = create("Frame", { Name = tostring(cfg.Title or "DiffList"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = card:_order(), Parent = card.body })
    Util.list(holder, 0)
    local element = Base.element(card, "DiffList", { Title = cfg.Title }, holder, nil, nil)
    local rows, frames = {}, {}
    function element:SetItems(list)
        for _, frame in ipairs(frames) do frame:Destroy() end
        table.clear(frames)
        rows = list or {}
        if #rows == 0 then
            local empty = label(holder, tostring(cfg.Empty or "No changes"), 10, { Name = "Empty", Size = UDim2.new(1, 0, 0, 24) })
            Theme.bind(empty, "TextColor3", "muted")
            frames[1] = empty
            return
        end
        for index, row in ipairs(rows) do
            local frame = create("Frame", { Name = tostring(row.Title or index), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = index, Parent = holder })
            local line = create("Frame", { Name = "Line", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = frame })
            Theme.bind(line, "BackgroundColor3", "line")
            local x = 0
            if row.Tag then
                local chip = Parts.chip(frame, tostring(row.Tag), "muted", nil, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) })
                chip.Size = UDim2.fromOffset(math.max(chip.Size.X.Offset, 66), 18)
                x = chip.Size.X.Offset + 8
            end
            local right = cfg.OnRevert and 22 or 0
            local new = label(frame, tostring(row.New or ""), 9, { Name = "New", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -right, 0.5, 0), Size = UDim2.fromOffset(78, 16), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.Code })
            Theme.bind(new, "TextColor3", "success")
            Icons.themed(frame, "arrow-right", 10, "muted", { Name = "Arrow", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -right - 82, 0.5, 0) })
            local old = label(frame, tostring(row.Old or ""), 9, { Name = "Old", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -right - 96, 0.5, 0), Size = UDim2.fromOffset(78, 16), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.Code, RichText = true })
            old.Text = "<s>" .. tostring(row.Old or ""):gsub("[<>&]", "") .. "</s>"
            Theme.bind(old, "TextColor3", "danger")
            local title = label(frame, tostring(row.Title or ""), 10, { Name = "Title", Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -x - right - 180, 1, 0) })
            Theme.bind(title, "TextColor3", "text")
            if cfg.OnRevert then
                local undo = create("ImageButton", { Name = "Revert", BackgroundTransparency = 1, Image = "", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(18, 18), Parent = frame })
                local icon = Icons.themed(undo, "undo-2", 12, "muted", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
                undo.MouseEnter:Connect(function() if icon then Theme.tweenTo(icon, "ImageColor3", "heading", 0.1) end card.window:_tip("Undo this change") end)
                undo.MouseLeave:Connect(function() if icon then Theme.tweenTo(icon, "ImageColor3", "muted", 0.1) end card.window:_hideTip() end)
                undo.Activated:Connect(function() card.window:_safe("DiffList", cfg.OnRevert, row, index) end)
            end
            frames[#frames + 1] = frame
        end
    end
    function element:GetItems() return rows end
    function element:Count() return #rows end
    element:SetItems(cfg.Items)
    return Base.finish(element, cfg)
end
end

__modules["elements/divider"] = function()
-- card:Divider() - a thin line between groups of rows.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create = Util.create

return function(card)
    local holder = create("Frame", { Name = "Divider", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 7), LayoutOrder = card:_order(), Parent = card.body })
    local line = create("Frame", { Position = UDim2.fromOffset(0, 3), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, BackgroundTransparency = 0.3, Parent = holder })
    Theme.bind(line, "BackgroundColor3", "line")
    return Base.element(card, "Divider", {}, holder, nil, nil)
end
end

__modules["elements/dropdown"] = function()
-- card:Dropdown({ Title, Desc, Flag, Items = {...}, Default, Multi, AllowNone, Search, DragSelect, Callback, Locked })
-- Single: Value is the chosen option. Multi: Value is a list of chosen options.
-- Options can be:
--   strings                                   { "Head", "Body" }
--   tables                                    { { Title = "Head", Icon = "user", Image = "rbxassetid://..", Desc = "...", Locked = true, Font = family } }
--   key / label pairs (Value = the key)       { pvp = "PvP mode", farm = "Auto farm" } or { { Value = "pvp", Title = "PvP mode" } }
-- Search = true (automatic above 8 options) puts a filter box at the top; long lists are drawn in chunks while
-- scrolling, so thousands of options stay fast. Multi lists can be ticked by dragging over them (DragSelect = false
-- turns it off). AllowNone = true lets a single dropdown be cleared by clicking the chosen option again.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label
local ITEM, ITEM_DESC, MAX_HEIGHT, SEARCH, CHUNK = 24, 34, 176, 28, 60

return function(card, cfg)
    local window = card.window
    local multi = cfg.Multi == true
    local options, info = {}, {} -- options: keys in order; info[key] = { Title, Icon, Image, Desc, Locked }
    local function setOptions(list)
        options, info = {}, {}
        list = list or {}
        local isArray = #list > 0 or next(list) == nil
        if isArray then
            for _, option in ipairs(list) do
                local entry = type(option) == "table" and option or { Title = option }
                local key = tostring(entry.Value or entry.Title or entry.Name or entry[1] or "")
                entry.Title = tostring(entry.Title or entry.Name or entry[1] or key)
                if not info[key] then options[#options + 1] = key end
                info[key] = entry
            end
        else
            -- dictionary: key = identity, value = label (or an entry table)
            for key, value in pairs(list) do
                local entry = type(value) == "table" and value or { Title = tostring(value) }
                entry.Title = tostring(entry.Title or key)
                key = tostring(key)
                options[#options + 1] = key
                info[key] = entry
            end
            table.sort(options, function(a, b) return info[a].Title:lower() < info[b].Title:lower() end)
        end
    end
    setOptions(cfg.Items)
    local function titleOf(key) return info[key] and info[key].Title or tostring(key) end

    local row, title, desc = Base.row(card, cfg, cfg.Desc and 40 or 30, { right = 160 })
    -- the title takes the left half, the box the right half (up to 170 px)
    title.Size = UDim2.new(0.55, -8 - title.Position.X.Offset, 0, title.Size.Y.Offset)
    if desc then desc.Size = UDim2.new(0.55, -8 - desc.Position.X.Offset, 0, 14) end
    local button = create("TextButton", {
        Name = "Select", Text = "", AutoButtonColor = false, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0.45, 0, 0, 24), Parent = row,
    })
    Theme.bind(button, "BackgroundColor3", "input")
    corner(button, 6)
    Theme.bind(stroke(button), "Color", "buttonEdge")
    create("UISizeConstraint", { MaxSize = Vector2.new(170, 24), Parent = button })
    local valueIcon = create("ImageLabel", { Name = "ValueIcon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.fromOffset(12, 12), Visible = false, Parent = button })
    local valueLabel = label(button, "", 10, { Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -28, 1, 0) })
    Theme.bind(valueLabel, "TextColor3", "text")
    -- chevron drawn with two bars (fonts may not have an arrow glyph)
    local arrow = create("Frame", { Name = "Chevron", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 1), Size = UDim2.fromOffset(10, 6), Parent = button })
    local arrowBars = {}
    for index, rotation in ipairs({ 45, -45 }) do
        local bar = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(index == 1 and 3 or 7, 3), Size = UDim2.fromOffset(6, 1.5),
            Rotation = rotation, BorderSizePixel = 0, Parent = arrow,
        })
        Theme.bind(bar, "BackgroundColor3", "muted")
        arrowBars[index] = bar
    end
    local function tintArrow(role) for _, bar in ipairs(arrowBars) do Theme.tweenTo(bar, "BackgroundColor3", role, 0.1) end end

    local element = Base.element(card, "Dropdown", cfg, row, title, desc)
    element.Items = options

    local function chosen(option)
        if multi then return table.find(element.Value, option) ~= nil end
        return element.Value == option
    end
    -- the small picture / icon of an option (pictures keep their colours, icons follow the theme)
    local function applyVisual(image, entry, role)
        if entry.Image then
            if not Icons.Apply(image, entry.Image) then image.Image = tostring(entry.Image) end
            Theme.bind(image, "ImageColor3", Color3.new(1, 1, 1))
            return true
        elseif entry.Icon and Icons.Apply(image, entry.Icon) then
            Theme.bind(image, "ImageColor3", role)
            return true
        end
        return false
    end
    local function render()
        local text
        if multi then
            -- as many names as fit the box, then "+N" for the rest ("Name, Health +2")
            local scale = window.scale and window.scale.Scale or 1
            local room = button.AbsoluteSize.X > 0 and (button.AbsoluteSize.X / scale - 30) or 140
            local titles = {}
            for _, key in ipairs(element.Value) do titles[#titles + 1] = titleOf(key) end
            text = #titles > 0 and table.concat(titles, ", ") or "None"
            if #titles > 1 and Util.textWidth(text, 10, Enum.Font.Gotham) > room then
                local shown = titles[1]
                for count = 2, #titles do
                    local try = shown .. ", " .. titles[count]
                    local rest = " +" .. (#titles - count)
                    if Util.textWidth(try .. (count < #titles and rest or ""), 10, Enum.Font.Gotham) > room then
                        text = shown .. " +" .. (#titles - count + 1)
                        break
                    end
                    shown = try
                end
            end
        else
            text = element.Value and titleOf(element.Value) or "None"
        end
        valueLabel.Text = text
        -- single value with an icon / picture: show it in the box
        local entry = not multi and element.Value and info[element.Value]
        local hasVisual = entry and applyVisual(valueIcon, entry, "text") or false
        valueIcon.Visible = hasVisual
        valueLabel.Position = UDim2.fromOffset(hasVisual and 26 or 9, 0)
        valueLabel.Size = UDim2.new(1, hasVisual and -45 or -28, 1, 0)
    end

    if multi then button:GetPropertyChangedSignal("AbsoluteSize"):Connect(render) end

    ------------------------------------------------------------ list popup
    local popup
    local dragging -- multi drag-select: the state being painted (true / false)
    local function closeList()
        if popup then popup:Destroy() popup = nil end
        dragging = nil
        tintArrow("muted")
    end
    local function itemHeight(option) return info[option] and info[option].Desc and ITEM_DESC or ITEM end
    local function openList()
        closeList()
        -- The list opens over the button: header (value + upturned chevron), divider, [search], options.
        -- It opens upwards when there is more room above. It lives outside the scaled window, so it takes the scale itself.
        local position, size = Util.screenPos(button), button.AbsoluteSize
        local viewport = Util.viewport()
        local searchable = cfg.Search == true or (cfg.Search ~= false and #options > 8)
        local fullHeight = 8
        for index, option in ipairs(options) do
            fullHeight = fullHeight + itemHeight(option)
            if index > 200 then fullHeight = MAX_HEIGHT break end
        end
        local listHeight = math.min(fullHeight, MAX_HEIGHT)
        local top = 25 + (searchable and SEARCH + 4 or 0)
        local total = top + listHeight
        local scale = window.scale and window.scale.Scale or 1
        local hasDesc = false
        for index, option in ipairs(options) do
            if info[option] and info[option].Desc then hasDesc = true break end
            if index > 200 then break end
        end
        local width = math.max(size.X / scale, cfg.ListWidth or (hasDesc and 190 or 140))
        local roomBelow, roomAbove = viewport.Y - 8 - position.Y, position.Y + size.Y - 8
        local below = roomBelow >= total * scale or roomBelow >= roomAbove
        popup = create("Frame", {
            Name = "DropdownList", BorderSizePixel = 0, ZIndex = 260,
            Position = UDim2.fromOffset(math.clamp(position.X + size.X - width * scale, 8, math.max(8, viewport.X - width * scale - 8)), below and position.Y or position.Y + size.Y - total * scale),
            Size = UDim2.fromOffset(width, total), Parent = window.gui,
        })
        create("UIScale", { Scale = scale, Parent = popup })
        Theme.bind(popup, "BackgroundColor3", "input")
        corner(popup, 6)
        Theme.bind(stroke(popup), "Color", "buttonEdge")
        local header = create("TextButton", {
            Name = "Header", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, ZIndex = 261,
            Position = UDim2.fromOffset(0, below and 0 or total - 24), Size = UDim2.new(1, 0, 0, 24), Parent = popup,
        })
        local headerText = label(header, valueLabel.Text, 10, { Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -28, 1, 0), ZIndex = 262 })
        Theme.bind(headerText, "TextColor3", "text")
        for index, rotation in ipairs({ -40, 40 }) do
            local bar = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, index == 1 and -16 or -12, 0.5, 0), Size = UDim2.fromOffset(6, 1.5),
                Rotation = rotation, BorderSizePixel = 0, ZIndex = 262, Parent = header,
            })
            Theme.bind(bar, "BackgroundColor3", "accent")
        end
        header.Activated:Connect(function() window:_closePopup() end)
        local separator = create("Frame", {
            Position = UDim2.new(0, 6, 0, below and 24 or total - 25), Size = UDim2.new(1, -12, 0, 1), BorderSizePixel = 0, ZIndex = 261, Parent = popup,
        })
        Theme.bind(separator, "BackgroundColor3", "line")
        local bodyTop = below and 25 or 0
        local searchBox
        if searchable then
            searchBox = create("TextBox", {
                Name = "Search", Text = "", PlaceholderText = "Search...", TextSize = 10, Font = Enum.Font.Gotham, ClearTextOnFocus = false,
                TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 262,
                Position = UDim2.fromOffset(6, bodyTop + 4), Size = UDim2.new(1, -12, 0, SEARCH - 2), Parent = popup,
            })
            Theme.bind(searchBox, "BackgroundColor3", "base")
            Theme.bind(searchBox, "TextColor3", "text")
            Theme.bind(searchBox, "PlaceholderColor3", "muted")
            corner(searchBox, 5)
            Util.padding(searchBox, 24, 6, 0, 0)
            Icons.themed(searchBox, "search", 11, "muted", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -17, 0.5, 0), ZIndex = 263 })
            bodyTop = bodyTop + SEARCH + 4
        end
        local scroller = create("ScrollingFrame", {
            Name = "Options", BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 261, ScrollBarThickness = 2,
            Position = UDim2.fromOffset(0, bodyTop), Size = UDim2.new(1, 0, 0, listHeight),
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = popup,
        })
        Theme.bind(scroller, "ScrollBarImageColor3", "muted")
        Util.fadeScrollbar(scroller)
        Util.padding(scroller, 4, 4, 4, 4)
        Util.fitCanvas(scroller, Util.list(scroller, 0))
        local empty = label(scroller, "No matches", 10, { Name = "Empty", Size = UDim2.new(1, 0, 0, ITEM), TextXAlignment = Enum.TextXAlignment.Center, Visible = false, ZIndex = 262, LayoutOrder = 1e6 })
        Theme.bind(empty, "TextColor3", "muted")
        local more = label(scroller, "", 9, { Name = "More", Size = UDim2.new(1, 0, 0, ITEM), TextXAlignment = Enum.TextXAlignment.Center, Visible = false, ZIndex = 262, LayoutOrder = 1e6 + 1 })
        Theme.bind(more, "TextColor3", "muted")
        local function refreshHeader() headerText.Text = valueLabel.Text end

        local items = {}
        local function paint(option, entry, text, icon, check)
            local on = chosen(option)
            Theme.tweenTo(text, "TextColor3", on and "accent" or "text", 0.1)
            if icon and not entry.Image then Theme.tweenTo(icon, "ImageColor3", on and "accent" or "muted", 0.1) end
            check.Visible = on
        end
        local function setChosen(option, on)
            local list = table.clone(element.Value)
            local at = table.find(list, option)
            if on and not at then list[#list + 1] = option elseif not on and at then table.remove(list, at) end
            element:Set(list)
            refreshHeader()
        end
        local function buildItem(option, order)
            local entry = info[option] or { Title = option }
            local height = itemHeight(option)
            local locked = entry.Locked == true
            local item = create("TextButton", {
                Name = option, Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, height), LayoutOrder = order, ZIndex = 262, Parent = scroller,
            })
            Theme.bind(item, "BackgroundColor3", "hover")
            corner(item, 5)
            local textX = 8
            local icon = create("ImageLabel", {
                Name = "Icon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0, entry.Desc and 12 or height / 2),
                Size = UDim2.fromOffset(entry.Image and 16 or 12, entry.Image and 16 or 12), ZIndex = 263, Parent = item,
            })
            if entry.Image then corner(icon, 4) end
            if applyVisual(icon, entry, chosen(option) and "accent" or "muted") then textX = entry.Image and 30 or 26 else icon:Destroy() icon = nil end
            local text = label(item, entry.Title, 10, { Position = UDim2.fromOffset(textX, entry.Desc and 3 or 0), Size = UDim2.new(1, -textX - 20, 0, entry.Desc and 17 or height), ZIndex = 263 })
            -- Font = family: the option is drawn in that font (the font list shows each font in its own face)
            if entry.Font then
                text:SetAttribute("QFixedFont", true)
                pcall(function() text.FontFace = Font.new(entry.Font, Enum.FontWeight.Medium) end)
            end
            Theme.bind(text, "TextColor3", chosen(option) and "accent" or "text")
            if entry.Desc then
                local sub = label(item, tostring(entry.Desc), 9, { Position = UDim2.fromOffset(textX, 18), Size = UDim2.new(1, -textX - 20, 0, 13), ZIndex = 263 })
                Theme.bind(sub, "TextColor3", "muted")
            end
            if locked then
                text.TextTransparency = 0.55
                if icon then icon.ImageTransparency = 0.55 end
                Icons.themed(item, "lock", 10, "muted", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), ZIndex = 263, ImageTransparency = 0.3 })
            end
            local check = create("Frame", { Name = "Check", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, ZIndex = 263, Visible = chosen(option), Parent = item })
            corner(check, 3)
            Theme.bind(check, "BackgroundColor3", "accent")
            items[option] = item
            item.MouseEnter:Connect(function()
                if not locked then item.BackgroundTransparency = 0 end
                -- drag-select: moving over items with the button held paints them
                if dragging ~= nil and not locked and chosen(option) ~= dragging then
                    setChosen(option, dragging)
                    paint(option, entry, text, icon, check)
                end
            end)
            item.MouseLeave:Connect(function() item.BackgroundTransparency = 1 end)
            if multi then
                item.InputBegan:Connect(function(input)
                    if locked or not Util.isPress(input) then return end
                    local target = not chosen(option)
                    setChosen(option, target)
                    paint(option, entry, text, icon, check)
                    if cfg.DragSelect ~= false and input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = target end
                end)
            else
                item.Activated:Connect(function()
                    if locked then return end
                    if element.Value == option and cfg.AllowNone then element:Set(nil) else element:Set(option) end
                    window:_closePopup()
                end)
            end
            return item
        end

        -- shown = the options matching the search; only the first `drawn` of them exist as instances
        local shown, drawn = {}, 0
        local function drawMore()
            local limit = math.min(#shown, drawn + CHUNK)
            for index = drawn + 1, limit do
                local option = shown[index]
                local item = items[option] or buildItem(option, index)
                item.LayoutOrder = index
                item.Visible = true
            end
            drawn = limit
            more.Visible = drawn < #shown
            more.Text = (#shown - drawn) .. " more - scroll or search"
        end
        local function filter(query)
            query = (query or ""):lower()
            for _, item in pairs(items) do item.Visible = false end
            shown, drawn = {}, 0
            for _, option in ipairs(options) do
                local entry = info[option] or {}
                if query == "" or entry.Title:lower():find(query, 1, true) or option:lower():find(query, 1, true)
                    or (entry.Desc ~= nil and tostring(entry.Desc):lower():find(query, 1, true)) then
                    shown[#shown + 1] = option
                end
            end
            empty.Visible = #shown == 0
            drawMore()
        end
        scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            if drawn < #shown and scroller.CanvasPosition.Y + scroller.AbsoluteSize.Y >= scroller.AbsoluteCanvasSize.Y - 60 then drawMore() end
        end)
        filter("")
        if searchBox then
            searchBox:GetPropertyChangedSignal("Text"):Connect(function() filter(searchBox.Text) end)
            task.defer(function() pcall(function() searchBox:CaptureFocus() end) end)
        end
        tintArrow("accent")
        window:_openPopup(popup, button, closeList)
    end
    button.Activated:Connect(function()
        if element.Locked then return end
        if popup then window:_closePopup() else openList() end
    end)
    -- the drag ends with the mouse button
    window.maid:connect(Util.Services.UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = nil end
    end)

    -- accepts keys or labels
    local function resolve(value)
        value = tostring(value)
        if info[value] then return value end
        for _, key in ipairs(options) do if info[key].Title == value then return key end end
        return nil
    end
    function element:Set(value, silent)
        if multi then
            local list = {}
            for _, option in ipairs(type(value) == "table" and value or { value }) do
                local key = resolve(option)
                if key and not table.find(list, key) then list[#list + 1] = key end
            end
            self.Value = list
        else
            self.Value = value ~= nil and resolve(value) or nil
        end
        render()
        self:_fire(self.Value, silent)
    end
    function element:Get() return self.Value end
    function element:GetLabel(key) return titleOf(key or self.Value) end
    -- SetItems accepts the same forms as Options; chosen values that no longer exist are dropped
    function element:SetItems(list, keep)
        setOptions(list)
        self.Items = options
        if popup then window:_closePopup() end
        self:Set(keep and self.Value or (multi and {} or nil), true)
    end
    function element:Refresh(list) self:SetItems(list, true) end

    if multi then
        element.Value = {}
        element:Set(cfg.Default or {}, true)
    else
        element:Set(cfg.Default, true)
    end
    return Base.finish(element, cfg)
end
end

__modules["elements/fovpreview"] = function()
-- card:FovPreview({ Height = 140 }) - the aim FOV circle round the cursor exactly as big as on screen (real pixels,
-- whatever the UI scale); one too big for the box is shrunk to fit and the corner says so ("300 px · shown at 40 %").
-- element:Update(settings):
--   Radius (px on the real screen), Sides (under 16: drawn as the polygon it is), Thickness, Color,
--   Transparency (0 - 1, the outline), Filled, FillColor, FillTransparency (0 - 1), Visible (false: shown faint), HiddenReason (the note then, default "hidden").
-- Drawn again on its own when the UI scale changes.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

local DEFAULTS = {
    Radius = 60, Sides = 100, Thickness = 1, Color = Color3.new(1, 1, 1), Transparency = 0,
    Filled = false, FillColor = Color3.new(1, 1, 1), FillTransparency = 0.85, Visible = true,
}

return function(card, cfg)
    local window = card.window
    local box = create("Frame", {
        Name = "FovPreview", Size = UDim2.new(1, 0, 0, cfg.Height or 140), BorderSizePixel = 0, ClipsDescendants = true,
        LayoutOrder = card:_order(), Parent = card.body,
    })
    Theme.bind(box, "BackgroundColor3", "base")
    corner(box, 6)
    Theme.bind(stroke(box), "Color", "line")
    local cursor = create("Frame", { Name = "Cursor", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(4, 4), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = box })
    corner(cursor, 2)
    local circle = create("Frame", { Name = "Circle", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0, Parent = box })
    corner(circle, 999)
    local ring = stroke(circle, nil, 0, 1)
    local lines, fills = {}, {}
    local note = Util.label(box, "", 8, { Name = "Note", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -5), Size = UDim2.fromOffset(160, 12), TextXAlignment = Enum.TextXAlignment.Right })
    Theme.bind(note, "TextColor3", "muted")

    local element = Base.element(card, "FovPreview", {}, box, nil, nil)
    element.Settings = {}
    for key, value in pairs(DEFAULTS) do element.Settings[key] = value end

    local function draw()
        local s = element.Settings
        -- real screen pixels: the window's UI scale is undone (k = 1 / scale), unless the circle would not fit
        local scaleUI = window and window.scale and window.scale.Scale or 1
        local height = cfg.Height or 140
        local realRadius = math.max(tonumber(s.Radius) or 60, 1)
        local k = math.min(1 / scaleUI, (height - 14) / (2 * realRadius))
        local fit = k * scaleUI
        local radius = realRadius * k
        local sides = math.floor(tonumber(s.Sides) or 100)
        local color = typeof(s.Color) == "Color3" and s.Color or Color3.new(1, 1, 1)
        local thickness = math.max(1, (tonumber(s.Thickness) or 1) * k)
        local shown = s.Visible ~= false
        local outline = shown and math.clamp(tonumber(s.Transparency) or 0, 0, 1) or 0.85
        circle.Size = UDim2.fromOffset(radius * 2, radius * 2)
        circle.BackgroundColor3 = typeof(s.FillColor) == "Color3" and s.FillColor or Color3.new(1, 1, 1)
        -- a round circle from 16 sides up; fewer sides are drawn as the polygon they are (outline and fill)
        local polygon = sides < 16
        local fillAlpha = (s.Filled and shown) and math.clamp(tonumber(s.FillTransparency) or 0.85, 0, 1) or 1
        circle.BackgroundTransparency = polygon and 1 or fillAlpha
        -- the polygon's fill: 2 px rows, each as wide as the polygon is at that height
        local rows = (polygon and fillAlpha < 1) and math.max(1, math.ceil(radius)) or 0
        for index = 1, math.max(#fills, rows) do
            local row = fills[index]
            if not row then
                row = create("Frame", { Name = "Fill", AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Parent = box })
                fills[index] = row
            end
            local y = -radius + (index - 0.5) * 2
            local left, right = math.huge, -math.huge
            if index <= rows then
                for side = 1, sides do
                    local a1, a2 = (side - 1) / sides * math.pi * 2, side / sides * math.pi * 2
                    local x1, y1 = math.cos(a1) * radius, math.sin(a1) * radius
                    local x2, y2 = math.cos(a2) * radius, math.sin(a2) * radius
                    if (y1 - y) * (y2 - y) <= 0 and y1 ~= y2 then
                        local x = x1 + (x2 - x1) * (y - y1) / (y2 - y1)
                        left, right = math.min(left, x), math.max(right, x)
                    end
                end
            end
            if right > left then
                row.Position = UDim2.new(0.5, (left + right) / 2, 0.5, y)
                row.Size = UDim2.fromOffset(right - left, 2)
                row.BackgroundColor3, row.BackgroundTransparency, row.Visible = circle.BackgroundColor3, fillAlpha, true
            else
                row.Visible = false
            end
        end
        ring.Color, ring.Thickness, ring.Transparency = color, thickness, polygon and 1 or outline
        for index = 1, math.max(#lines, polygon and sides or 0) do
            local line = lines[index]
            if not line then
                line = create("Frame", { Name = "Side", AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, ZIndex = 2, Parent = box })
                lines[index] = line
            end
            if polygon and index <= sides then
                local a1, a2 = (index - 1) / sides * math.pi * 2, index / sides * math.pi * 2
                -- from the centre of the box (like the circle), so the UI scale cannot move it off
                local x1, y1 = math.cos(a1) * radius, math.sin(a1) * radius
                local x2, y2 = math.cos(a2) * radius, math.sin(a2) * radius
                local dx, dy = x2 - x1, y2 - y1
                line.Position = UDim2.new(0.5, (x1 + x2) / 2, 0.5, (y1 + y2) / 2)
                line.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + 1, thickness)
                line.Rotation = math.deg(math.atan2(dy, dx))
                line.BackgroundColor3, line.BackgroundTransparency, line.Visible = color, outline, true
            else
                line.Visible = false
            end
        end
        note.Text = (shown and "" or (tostring(s.HiddenReason or "hidden") .. " · ")) .. math.floor(realRadius) .. " px"
            .. (fit < 0.995 and " · shown at " .. math.floor(fit * 100 + 0.5) .. " %" or " · real size")
    end
    function element:Update(changes)
        for key, value in pairs(changes or {}) do self.Settings[key] = value end
        draw()
    end

    -- the UI scale changed (the box's on-screen size with it): drawn again, so the circle stays real size
    local lastSize
    local sizeConnection = box:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if box.AbsoluteSize ~= lastSize then lastSize = box.AbsoluteSize draw() end
    end)
    if window and window.maid then window.maid:give(sizeConnection) end
    element:Update(cfg.Settings)
    return Base.finish(element, cfg)
end
end

__modules["elements/gallery"] = function()
-- card:Gallery({ Title, Flag, Columns = 4, Default = "Dark", Callback = function(name) end, Items = {
--     { Name = "Dark", Colors = { Color3.fromRGB(18, 18, 19), Color3.fromRGB(27, 27, 29), Color3.fromRGB(92, 92, 98) } },
--     { Name = "Gotham", Font = Enum.Font.Gotham },                       -- a font sample ("Aa")
--     { Name = "Logo", Image = "rbxassetid://..." },
-- } })
-- Pick one of several cards by how it looks: a theme thumbnail (Colors = { background, card, accent }), a font sample
-- (Font = Enum.Font or Font.new(...), Sample = "Aa"), or an image. The chosen one gets a bright outline.
-- Value is the item's Name. :Set(name), :Get(), :SetItems(items).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Parts = require("elements/parts")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local columns = math.max(1, tonumber(cfg.Columns) or 4)
    local cellH, gap = tonumber(cfg.Height) or 58, 6
    local top = (cfg.Title and 22 or 0)
    local holder = create("Frame", { Name = tostring(cfg.Title or "Gallery"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, top), LayoutOrder = card:_order(), Parent = card.body })
    local title
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Size = UDim2.new(1, 0, 0, 20) })
        Theme.bind(title, "TextColor3", "text")
    end
    local element = Base.element(card, "Gallery", cfg, holder, title, nil)
    local cells = {}
    local function render()
        for _, cell in ipairs(cells) do
            local on = cell.name == element.Value
            Theme.tweenTo(cell.edge, "Color", on and "heading" or "line", 0.1)
            cell.edge.Thickness = on and 1.5 or 1
            Theme.tweenTo(cell.caption, "TextColor3", on and "heading" or "muted", 0.1)
        end
    end
    function element:SetItems(items)
        for _, cell in ipairs(cells) do cell.button:Destroy() end
        table.clear(cells)
        items = items or {}
        holder.Size = UDim2.new(1, 0, 0, top + Parts.gridHeight(#items, columns, gap, cellH))
        for index, item in ipairs(items) do
            local name = tostring(item.Name or item.Title or index)
            local position, size = Parts.cell(index, columns, gap, cellH, top)
            local button = create("TextButton", { Name = name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Position = position, Size = size, Parent = holder })
            corner(button, 8)
            local edge = Util.stroke(button, nil, 0)
            local caption = label(button, name, 9, { Name = "Caption", Position = UDim2.new(0, 7, 1, -15), Size = UDim2.new(1, -14, 0, 12) })
            if item.Colors then
                local colors = item.Colors
                button.BackgroundColor3 = colors[1] or Color3.new()
                local preview = create("Frame", { Name = "Preview", Position = UDim2.fromOffset(5, 5), Size = UDim2.new(1, -10, 1, -24), BorderSizePixel = 0, BackgroundColor3 = colors[2] or colors[1], Parent = button })
                corner(preview, 5)
                local bar = create("Frame", { Name = "Bar", Position = UDim2.fromOffset(5, 5), Size = UDim2.new(1, -24, 0, 6), BorderSizePixel = 0, BackgroundColor3 = (colors[2] or Color3.new()):Lerp(Color3.new(1, 1, 1), 0.12), Parent = preview })
                corner(bar, 3)
                local knob = create("Frame", { Name = "Accent", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -5, 0, 5), Size = UDim2.fromOffset(10, 6), BorderSizePixel = 0, BackgroundColor3 = colors[3] or Color3.new(1, 1, 1), Parent = preview })
                corner(knob, 3)
                local bright = (colors[1].R + colors[1].G + colors[1].B) / 3 > 0.6
                caption.TextColor3 = bright and Color3.fromRGB(40, 40, 45) or Color3.fromRGB(225, 225, 230)
            else
                Theme.bind(button, "BackgroundColor3", "input")
                if item.Image then
                    create("ImageLabel", { Name = "Image", BackgroundTransparency = 1, Position = UDim2.fromOffset(5, 5), Size = UDim2.new(1, -10, 1, -24), Image = tostring(item.Image), ScaleType = Enum.ScaleType.Fit, Parent = button })
                else
                    local sample = label(button, tostring(item.Sample or cfg.Sample or "Aa"), 17, { Name = "Sample", Position = UDim2.fromOffset(8, 5), Size = UDim2.new(1, -16, 1, -22) })
                    sample:SetAttribute("QFixedFont", true)
                    if typeof(item.Font) == "EnumItem" then sample.Font = item.Font
                    elseif typeof(item.Font) == "Font" then sample.FontFace = item.Font end
                    Theme.bind(sample, "TextColor3", "heading")
                end
            end
            local cell = { name = name, button = button, edge = edge, caption = caption }
            if not item.Colors then Theme.bind(caption, "TextColor3", "muted") end
            cells[#cells + 1] = cell
            button.Activated:Connect(function() if not element.Locked then element:Set(name) end end)
            Util.hoverPop(button, 1.03)
        end
        render()
    end
    function element:Set(name, silent)
        self.Value = name ~= nil and tostring(name) or nil
        render()
        self:_fire(self.Value, silent)
    end
    function element:Get() return self.Value end
    element:SetItems(cfg.Items)
    element.Value = cfg.Default ~= nil and tostring(cfg.Default) or nil
    render()
    element:_fire(element.Value, true)
    return Base.finish(element, cfg)
end
end

__modules["elements/gauges"] = function()
-- card:Gauges({ Size = 62, Items = {
--     { Title = "FPS", Value = 60, Max = 60, Color = "heading" },
--     { Title = "Ping", Value = 40, Max = 150, Sub = "ms", Color = "warning" },
--     { Title = "Players", Value = 2, Max = 50, Sub = "of 50" },
-- } })
-- Round gauges side by side: a ring of dots that fills up to Value / Max, the value in the middle, a small line
-- under it and the title below. Source = "FPS" | "Ping" | function() return number end keeps one live.
-- :Set(gauge, value, max?, sub?) (gauge = index or title). No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Stats = require("stats")
local Parts = require("elements/parts")

local create, label = Util.create, Util.label

return function(card, cfg)
    local window = card.window
    local list = cfg.Items or {}
    local size = tonumber(cfg.Size) or 62
    local holder = create("Frame", { Name = tostring(cfg.Title or "Gauges"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, size + 20), LayoutOrder = card:_order(), Parent = card.body })
    local element = Base.element(card, "Gauges", cfg, holder, nil, nil)
    local gauges = {}
    local count = math.max(#list, 1)
    for index, spec in ipairs(list) do
        local slot = create("Frame", { Name = tostring(spec.Title or index), BackgroundTransparency = 1, Position = UDim2.new((index - 1) / count, 0, 0, 0), Size = UDim2.new(1 / count, 0, 1, 0), Parent = holder })
        local ring = create("Frame", { Name = "Ring", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(size, size), Parent = slot })
        local set = Parts.dotRing(ring, size, math.floor(size * 0.7), 3)
        local value = label(ring, "", 13, { Name = "Value", Position = UDim2.new(0, 0, 0.5, -11), Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold })
        Theme.bind(value, "TextColor3", "heading")
        local sub = label(ring, tostring(spec.Sub or ""), 8, { Name = "Sub", Position = UDim2.new(0, 0, 0.5, 5), Size = UDim2.new(1, 0, 0, 10), TextXAlignment = Enum.TextXAlignment.Center })
        Theme.bind(sub, "TextColor3", "muted")
        local title = label(slot, string.upper(tostring(spec.Title or "")), 8, { Name = "Title", Position = UDim2.fromOffset(0, size + 5), Size = UDim2.new(1, 0, 0, 12), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamMedium })
        Theme.bind(title, "TextColor3", "muted")
        local gauge = { spec = spec, set = set, value = value, sub = sub, max = tonumber(spec.Max) or 100 }
        gauges[index] = gauge
        gauges[tostring(spec.Title)] = gauge
    end
    local function find(which) return type(which) == "number" and gauges[which] or gauges[tostring(which)] end
    function element:Set(which, number, max, subText)
        local gauge = find(which)
        if not gauge then return end
        if max then gauge.max = tonumber(max) or gauge.max end
        number = tonumber(number) or 0
        gauge.current = number
        local spec = gauge.spec
        gauge.value.Text = spec.Format and spec.Format(number) or tostring(math.floor(number * 10 + 0.5) / 10)
        if subText ~= nil then gauge.sub.Text = tostring(subText) end
        local fraction = number / math.max(gauge.max, 1e-6)
        if spec.Invert then fraction = 1 - fraction end
        gauge.set(fraction, Parts.color(spec.Color, "heading"))
    end
    function element:Get(which) local gauge = find(which) return gauge and gauge.current end
    for index, gauge in ipairs(gauges) do element:Set(index, gauge.spec.Value or 0) end

    local live = {}
    for index, gauge in ipairs(gauges) do if gauge.spec.Source then live[#live + 1] = index end end
    if #live > 0 then
        Stats.start(window.Lib.maid)
        window.maid:give(Stats.listen(function()
            if not holder.Parent or not Util.shown(holder) then return end
            for _, index in ipairs(live) do
                local source = gauges[index].spec.Source
                local number
                if source == "FPS" then number = Stats.fps elseif source == "Ping" then number = Stats.ping
                elseif type(source) == "function" then local ok, v = pcall(source) number = ok and tonumber(v) or nil end
                if number then element:Set(index, number) end
            end
        end))
    end
    return Base.finish(element, cfg)
end
end

__modules["elements/gradient"] = function()
-- card:Gradient({ Title, Desc, Flag, Default = { Color3 start, Color3 end }, Rotation = 0, Callback = function(sequence, a, b) end })
-- Two-colour gradient (ESP fill, chams...). The row shows a preview bar; clicking it opens two colour pickers
-- (Start / End) with a Swap button. Value is { start, end }; :GetSequence() gives a ColorSequence.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local window = card.window
    local row, title, desc = Base.row(card, cfg, cfg.Desc and 40 or 30, { right = 100, button = true })
    local preview = create("TextButton", {
        Name = "Preview", Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(88, 18), Parent = row,
    })
    corner(preview, 5)
    Theme.bind(stroke(preview, nil, 0.2), "Color", "buttonEdge")
    local gradient = create("UIGradient", { Rotation = tonumber(cfg.Rotation) or 0, Parent = preview })

    -- the editor: a section of this card holding two colour pickers (no flags of their own)
    local section = create("Frame", {
        Name = "GradientEditor", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = row.LayoutOrder + 1, Visible = false, Parent = card.body,
    })
    Util.list(section, 4)
    local sub = setmetatable({ page = card.page, window = window, order = 0, body = section, frame = card.frame }, getmetatable(card))

    local element = Base.element(card, "Gradient", cfg, row, title, desc)
    local a, b = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
    local pickers = {}
    local applying = false
    local function render()
        gradient.Color = ColorSequence.new(a, b)
    end
    local function commit(silent)
        render()
        element.Value = { a, b }
        element:_fire(element.Value, true)
        if silent then return end
        element:_call(cfg.Callback, ColorSequence.new(a, b), a, b)
        for _, callback in ipairs(element._changed) do element:_call(callback, ColorSequence.new(a, b), a, b) end
    end
    pickers[1] = sub:ColorPicker({ Title = "Start", Flag = false, Default = a, Callback = function(color) if not applying then a = color commit() end end })
    pickers[2] = sub:ColorPicker({ Title = "End", Flag = false, Default = b, Callback = function(color) if not applying then b = color commit() end end })
    sub:Button({ Title = "Swap colours", Callback = function() element:Set({ b, a }) end })

    function element:Set(value, silent)
        if type(value) ~= "table" then return end
        local first, second = value[1], value[2]
        if type(first) == "string" then first = Util.fromHex(first) end
        if type(second) == "string" then second = Util.fromHex(second) end
        if typeof(first) ~= "Color3" or typeof(second) ~= "Color3" then return end
        local changed = first ~= a or second ~= b
        a, b = first, second
        applying = true
        pickers[1]:Set(a, true)
        pickers[2]:Set(b, true)
        applying = false
        commit(silent or not changed)
    end
    function element:Get() return a, b end
    function element:GetSequence() return ColorSequence.new(a, b) end
    function element:_save() return { Util.toHex(a), Util.toHex(b) } end
    element._panel = section
    function element:SetOpen(open)
        section.Visible = open == true
        Base.trackPanel(window, self, open == true)
    end

    local function toggleOpen() if not element.Locked then element:SetOpen(not section.Visible) end end
    row.Activated:Connect(toggleOpen)
    preview.Activated:Connect(toggleOpen)

    local default = type(cfg.Default) == "table" and cfg.Default or { Color3.fromRGB(215, 120, 120), Color3.fromRGB(120, 140, 230) }
    element:Set(default, true)
    return Base.finish(element, cfg)
end
end

__modules["elements/graph"] = function()
-- card:Graph({ Title, Source = "FPS" | "Ping" | function() return number end, Max, Suffix, Height = 70, Points = 40, Interval = 0.5,
--              Compact = true (stat tile: small title, big value, the graph under it - two fit side by side in a Row),
--              Style = "Bars" | "Line" })
-- A small live chart. "FPS" / "Ping" use the library's shared sampler; a function is sampled every Interval
-- seconds while the graph is on screen. :Push(value) adds a sample by hand.
-- Several lines in one chart: Style = "Line", Series = { { Name = "FPS", Source = "FPS" }, { Name = "Ping", Source = "Ping", Color = "warning" } }
-- (Color: a theme role or Color3). A legend shows each line's last value; :Push(value, "Ping") feeds one series.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Stats = require("stats")

local create, corner, label = Util.create, Util.corner, Util.label

local PALETTE = { "accent", "warning", "success", "danger", "codeGlobal", "codeKeyword" }

return function(card, cfg)
    local window = card.window
    local points = math.clamp(tonumber(cfg.Points) or 40, 5, 120)
    local height = tonumber(cfg.Height) or 70
    local function suffixFor(source, given)
        return given or (source == "Ping" and " ms" or (source == "FPS" and " FPS" or ""))
    end
    -- one series unless Series is given
    local series = {}
    if type(cfg.Series) == "table" and #cfg.Series > 0 then
        for index, spec in ipairs(cfg.Series) do
            series[index] = {
                name = tostring(spec.Name or spec.Source or ("Series " .. index)), source = spec.Source,
                color = spec.Color or PALETTE[(index - 1) % #PALETTE + 1], suffix = suffixFor(spec.Source, spec.Suffix), samples = {},
            }
        end
    else
        series[1] = { name = tostring(cfg.Title or cfg.Source or "Graph"), source = cfg.Source, color = cfg.Color or "accent", suffix = suffixFor(cfg.Source, cfg.Suffix), samples = {} }
    end
    local line = cfg.Style == "Line" or #series > 1

    local holder = create("Frame", { Name = tostring(cfg.Title or "Graph"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height + 24), LayoutOrder = card:_order(), Parent = card.body })
    local title = label(holder, tostring(cfg.Title or cfg.Source or "Graph"), 11, { Name = "Title", Size = UDim2.new(1, -90, 0, 20) })
    Theme.bind(title, "TextColor3", "text")
    -- one series: its value on the right; several: a legend (dot, name, value) instead
    local value, legend
    if #series == 1 then
        value = label(holder, "--", 10, { Name = "Value", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(90, 20), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium })
        Theme.bind(value, "TextColor3", "heading")
    else
        title.Size = UDim2.new(0.35, 0, 0, 20)
        legend = create("Frame", { Name = "Legend", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.65, 0, 0, 20), Parent = holder })
        Util.list(legend, 10, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
        for index, entry in ipairs(series) do
            local item = create("Frame", { Name = entry.name, BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 20), LayoutOrder = index, Parent = legend })
            Util.list(item, 4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
            local dot = create("Frame", { Name = "Dot", Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, Parent = item })
            corner(dot, 3)
            Theme.bind(dot, "BackgroundColor3", entry.color)
            entry.legend = label(item, entry.name .. " --", 9, { Name = "Text", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 20), TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2 })
            Theme.bind(entry.legend, "TextColor3", "muted")
        end
    end
    -- Compact = true (one series): small muted title, the value big under it, then the graph (a stat tile)
    local top = 24
    if cfg.Compact and value then
        top = 40
        holder.Size = UDim2.new(1, 0, 0, height + top)
        title.TextSize, title.Size = 9, UDim2.new(1, 0, 0, 14)
        Theme.bind(title, "TextColor3", "muted")
        value.AnchorPoint, value.Position, value.Size = Vector2.new(0, 0), UDim2.fromOffset(0, 14), UDim2.new(1, 0, 0, 22)
        value.TextXAlignment, value.TextSize, value.Font = Enum.TextXAlignment.Left, 17, Enum.Font.GothamBold
    end
    local area = create("Frame", { Name = "Area", Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, BackgroundTransparency = 0.4, ClipsDescendants = true, Parent = holder })
    Theme.bind(area, "BackgroundColor3", "base")
    corner(area, 6)

    local bars = {}
    if line then
        -- faint guide lines at 25 / 50 / 75 %
        for _, y in ipairs({ 0.25, 0.5, 0.75 }) do
            local guide = create("Frame", { Name = "Guide", Position = UDim2.fromScale(0, y), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, BackgroundTransparency = 0.6, Parent = area })
            Theme.bind(guide, "BackgroundColor3", "line")
        end
        for _, entry in ipairs(series) do
            entry.segments = {}
            for index = 1, points - 1 do
                local segment = create("Frame", { Name = "Segment", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(0, 2), BorderSizePixel = 0, Visible = false, ZIndex = 2, Parent = area })
                corner(segment, 1)
                Theme.bind(segment, "BackgroundColor3", entry.color)
                entry.segments[index] = segment
            end
            entry.head = create("Frame", { Name = "Head", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(5, 5), BorderSizePixel = 0, Visible = false, ZIndex = 3, Parent = area })
            corner(entry.head, 3)
            Theme.bind(entry.head, "BackgroundColor3", entry.color)
        end
    else
        for index = 1, points do
            local bar = create("Frame", {
                AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((index - 1) / points, 1, 1, 0), Size = UDim2.new(1 / points, -2, 0, 0),
                BorderSizePixel = 0, BackgroundTransparency = 0.3, Parent = area,
            })
            Theme.bind(bar, "BackgroundColor3", series[1].color)
            bars[index] = bar
        end
    end

    local element = Base.element(card, "Graph", {}, holder, title, nil)
    local function top()
        local highest = tonumber(cfg.Max) or 1
        for _, entry in ipairs(series) do for _, sample in ipairs(entry.samples) do highest = math.max(highest, sample) end end
        -- without a Max a line gets some room above it (a steady value would otherwise run along the top edge)
        if line and not tonumber(cfg.Max) then highest = highest * 1.25 end
        return highest
    end
    local function text(entry)
        local last = entry.samples[#entry.samples]
        return last and (tostring(math.floor(last + 0.5)) .. entry.suffix) or "--"
    end
    local function render()
        local highest = top()
        if line then
            local size = area.AbsoluteSize
            local width, tall = size.X, size.Y
            for _, entry in ipairs(series) do
                local samples = entry.samples
                local count = #samples
                -- newest sample on the right edge, one step per point
                local function point(i)
                    local sample = samples[i]
                    local x = width * ((points - (count - i) - 1) / (points - 1))
                    local y = tall - 3 - math.clamp(sample / highest, 0, 1) * (tall - 6)
                    return x, y
                end
                for index, segment in ipairs(entry.segments) do
                    local i = count - (points - 1) + index -- the segment ends at sample i
                    if i >= 2 and width > 0 then
                        local x1, y1 = point(i - 1)
                        local x2, y2 = point(i)
                        local dx, dy = x2 - x1, y2 - y1
                        segment.Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
                        segment.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + 1, 2)
                        segment.Rotation = math.deg(math.atan2(dy, dx))
                        segment.Visible = true
                    else
                        segment.Visible = false
                    end
                end
                if count > 0 and width > 0 then
                    local x, y = point(count)
                    entry.head.Position = UDim2.fromOffset(x - 2, y)
                    entry.head.Visible = true
                end
                if entry.legend then entry.legend.Text = entry.name .. " " .. text(entry) end
            end
        else
            local samples = series[1].samples
            for index = 1, points do
                local sample = samples[#samples - points + index]
                bars[index].Size = UDim2.new(1 / points, -2, sample and math.clamp(sample / highest, 0.02, 1) or 0, 0)
            end
        end
        if value then value.Text = text(series[1]) end
    end
    local dirty = false
    local function find(name)
        if name == nil then return series[1] end
        for _, entry in ipairs(series) do if entry.name == name then return entry end end
    end
    function element:Push(sample, name)
        sample = tonumber(sample)
        local entry = find(name)
        if not sample or not entry then return end
        entry.samples[#entry.samples + 1] = sample
        if #entry.samples > points then table.remove(entry.samples, 1) end
        -- (off screen - another page, the menu hidden - only the samples are kept; drawn when it can be seen)
        if Util.shown(holder) then
            dirty = false render()
        else
            dirty = true -- (the numbers are cheap: kept current)
            for _, item in ipairs(series) do if item.legend then item.legend.Text = item.name .. " " .. text(item) end end
            if value then value.Text = text(series[1]) end
        end
    end
    function element:Set(list, name)
        local entry = find(name)
        if not entry then return end
        entry.samples = {}
        for _, sample in ipairs(list or {}) do
            sample = tonumber(sample)
            if sample then
                entry.samples[#entry.samples + 1] = sample
                if #entry.samples > points then table.remove(entry.samples, 1) end
            end
        end
        render()
    end
    function element:Get(name) local entry = find(name) return entry and entry.samples end
    area:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
    -- catch up as soon as the page shows again
    task.spawn(function()
        while window.alive and holder.Parent do
            if dirty and Util.shown(holder) then dirty = false render() end
            task.wait(0.25)
        end
    end)

    local function onScreen()
        local object = holder
        while object and object ~= window.gui do
            if object:IsA("GuiObject") and not object.Visible then return false end
            object = object.Parent
        end
        return window.visible
    end
    local polled = {}
    for _, entry in ipairs(series) do
        if entry.source == "FPS" or entry.source == "Ping" then
            Stats.start(window.Lib.maid)
            local key = entry.source == "FPS" and "fps" or "ping"
            window.maid:give(Stats.listen(function(stats) if holder.Parent then element:Push(stats[key], entry.name) end end))
        elseif type(entry.source) == "function" then
            polled[#polled + 1] = entry
        end
    end
    if #polled > 0 then
        task.spawn(function()
            while window.alive and holder.Parent do
                if onScreen() then
                    for _, entry in ipairs(polled) do
                        local ok, sample = pcall(entry.source)
                        if ok then element:Push(sample, entry.name) end
                    end
                end
                task.wait(tonumber(cfg.Interval) or 0.5)
            end
        end)
    end
    render()
    return element
end
end

__modules["elements/hero"] = function()
-- card:Hero({ Title = "Tester", Desc = "@Tester · #101", UserId = 1 | Image = "rbxassetid://...", Online = true,
--             Chips = { { "60 FPS", "activity" }, { "40 ms", "wifi" } }, Label = "SESSION", Value = "00:12:44" })
-- A profile header: round avatar (UserId: the player's headshot) with an online dot, a big name, a muted line, a row
-- of chips, and a small-caps label over a big value on the right (a timer, a score...).
-- :SetTitle, :SetDesc, :SetValue(text), :SetLabel(text), :SetChips(list), :SetChipText(index, text), :SetOnline(on),
-- :SetImage(image). hero.Value / hero.Avatar are the value label and the avatar image.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Parts = require("elements/parts")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local size = tonumber(cfg.AvatarSize) or 46
    local holder = create("Frame", { Name = tostring(cfg.Name or cfg.Title or "Hero"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, size + 8), LayoutOrder = card:_order(), Parent = card.body })
    local avatar = create("ImageLabel", { Name = "Avatar", Size = UDim2.fromOffset(size, size), Position = UDim2.fromOffset(0, 4), BorderSizePixel = 0, Image = "", Parent = holder })
    Theme.bind(avatar, "BackgroundColor3", "input")
    corner(avatar, size)
    Theme.bind(Util.stroke(avatar, nil, 0.1, 2), "Color", "buttonEdge")
    local online = create("Frame", { Name = "Online", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0), Size = UDim2.fromOffset(math.floor(size * 0.24), math.floor(size * 0.24)), BorderSizePixel = 0, ZIndex = 2, Parent = avatar })
    corner(online, size)
    Theme.bind(online, "BackgroundColor3", "success")
    Theme.bind(Util.stroke(online, nil, 0, 2), "Color", "card")
    local x = size + 12
    local title = label(holder, tostring(cfg.Title or ""), 15, { Name = "Title", Position = UDim2.fromOffset(x, 2), Size = UDim2.new(1, -x - 110, 0, 20), Font = Enum.Font.GothamBold })
    Theme.bind(title, "TextColor3", "heading")
    local desc = label(holder, tostring(cfg.Desc or ""), 9, { Name = "Desc", Position = UDim2.fromOffset(x, 21), Size = UDim2.new(1, -x - 110, 0, 12) })
    Theme.bind(desc, "TextColor3", "muted")
    local chipRow = create("Frame", { Name = "Chips", BackgroundTransparency = 1, Position = UDim2.fromOffset(x, 36), Size = UDim2.new(1, -x - 110, 0, 18), Parent = holder })
    Util.list(chipRow, 4, Enum.FillDirection.Horizontal)
    local small = label(holder, tostring(cfg.Label or ""), 8, { Name = "Label", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 8), Size = UDim2.fromOffset(120, 12), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium })
    Theme.bind(small, "TextColor3", "muted")
    local value = label(holder, tostring(cfg.Value or ""), 20, { Name = "Value", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 20), Size = UDim2.fromOffset(140, 24), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium })
    Theme.bind(value, "TextColor3", "heading")

    local element = Base.element(card, "Hero", { Title = cfg.Title }, holder, title, desc)
    local chipFrames, chipSetters = {}, {}
    function element:SetChips(list)
        for _, chip in ipairs(chipFrames) do chip:Destroy() end
        table.clear(chipFrames)
        table.clear(chipSetters)
        for index, item in ipairs(list or {}) do
            if type(item) ~= "table" then item = { item } end
            local chip, _, resize = Parts.chip(chipRow, tostring(item[1] or item.Text), item.Role or "text", item[2] or item.Icon, { LayoutOrder = index })
            chipFrames[#chipFrames + 1] = chip
            chipSetters[index] = resize
        end
    end
    -- one chip's text (live numbers), without rebuilding the row
    function element:SetChipText(index, text) if chipSetters[index] then chipSetters[index](text) end end
    function element:SetValue(text) value.Text = tostring(text) end
    function element:SetLabel(text) small.Text = tostring(text) end
    function element:SetOnline(on) online.Visible = on ~= false end
    function element:SetImage(image) avatar.Image = tostring(image or "") end
    element.Value, element.Avatar = value, avatar
    if cfg.UserId then element:SetImage(Util.avatar(cfg.UserId, 150)) elseif cfg.Image then element:SetImage(cfg.Image) end
    element:SetOnline(cfg.Online)
    element:SetChips(cfg.Chips)
    return Base.finish(element, cfg)
end
end

__modules["elements/image"] = function()
-- card:Image({ Image = "rbxassetid://..." | "https://.../logo.png" | "icon-name", Height = 120, Radius = 8, Fit = "Crop" | "Fit", Caption })
-- A picture inside a card. Web images download once (getcustomasset). :Set(image).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local height = tonumber(cfg.Height) or 120
    local holder = create("Frame", { Name = tostring(cfg.Name or "Image"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height + (cfg.Caption and 18 or 0)), LayoutOrder = card:_order(), Parent = card.body })
    local frame = create("ImageLabel", {
        Name = "Picture", Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, ScaleType = cfg.Fit == "Fit" and Enum.ScaleType.Fit or Enum.ScaleType.Crop,
        Parent = holder,
    })
    Theme.bind(frame, "BackgroundColor3", "input")
    corner(frame, tonumber(cfg.Radius) or 8)
    if typeof(cfg.AspectRatio) == "number" then
        create("UIAspectRatioConstraint", { AspectRatio = cfg.AspectRatio, Parent = frame })
    end
    local caption
    if cfg.Caption then
        caption = label(holder, tostring(cfg.Caption), 9, { Name = "Caption", Position = UDim2.fromOffset(0, height + 4), Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Center })
        Theme.bind(caption, "TextColor3", "muted")
    end
    local element = Base.element(card, "Image", {}, holder, caption, nil)
    function element:Set(image)
        self.Value = image
        frame.Image = ""
        if image == nil then return end
        local icon = Icons.Get(image)
        if icon then Icons.Apply(frame, image) else frame.Image = tostring(image) end
        -- icon names are tinted like text; pictures keep their colours
        local isPicture = tostring(image):match("^rbxasset") or tostring(image):match("^%d+$") or tostring(image):match("^https?://")
        if isPicture then frame.ImageColor3 = Color3.new(1, 1, 1) else Theme.bind(frame, "ImageColor3", "heading") end
    end
    element:Set(cfg.Image)
    return element
end
end

__modules["elements/imagepicker"] = function()
-- card:ImagePicker({ Title, Flag, Items = { "251497633", "rbxassetid://12140499119", ... }, Default, Columns = 5, Callback })
-- A grid of images (crosshairs, icons...); the chosen one is outlined. Value is the image exactly as given.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

return function(card, cfg)
    local images = cfg.Items or {}
    local columns = math.max(1, tonumber(cfg.Columns) or 5)
    local cell = tonumber(cfg.CellSize) or 40
    local rowsCount = math.ceil(#images / columns)
    local top = cfg.Title and 24 or 0
    local holder = create("Frame", { Name = tostring(cfg.Title or "Images"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, top + rowsCount * (cell + 6)), LayoutOrder = card:_order(), Parent = card.body })
    local title
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Size = UDim2.new(1, 0, 0, 20) })
        Theme.bind(title, "TextColor3", "text")
    end
    local grid = create("Frame", { Name = "Grid", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 1, -top), Parent = holder })

    local element = Base.element(card, "ImagePicker", cfg, holder, title, nil)
    local buttons = {}
    local function asset(image)
        image = tostring(image)
        return image:match("^%d+$") and ("rbxassetid://" .. image) or image
    end
    local function render()
        for image, entry in pairs(buttons) do
            local on = image == element.Value
            Theme.tweenTo(entry.button, "BackgroundColor3", on and "selected" or "input", 0.1)
            Theme.tweenTo(entry.outline, "Color", on and "accent" or "line", 0.1)
            entry.outline.Transparency = on and 0.2 or 0.6
        end
    end
    for index, image in ipairs(images) do
        local key = tostring(image)
        local button = create("ImageButton", {
            Name = "Image" .. index, AutoButtonColor = false, BorderSizePixel = 0, Image = "", LayoutOrder = index, Parent = grid,
            Position = UDim2.new(((index - 1) % columns) / columns, 3, 0, ((index - 1) // columns) * (cell + 6)), Size = UDim2.new(1 / columns, -6, 0, cell),
        })
        corner(button, 6)
        local outline = stroke(button)
        local preview = create("ImageLabel", {
            Name = "Preview", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.62, 0.62),
            BackgroundTransparency = 1, Image = asset(image), ScaleType = Enum.ScaleType.Fit, Parent = button,
        })
        -- icon names work too ("crosshair", "solar:target-bold")
        if not tostring(image):match("^%d+$") and not tostring(image):match("^rbxasset") then Icons.Apply(preview, image) end
        buttons[key] = { button = button, outline = outline }
        -- hover: a slight grow and a brighter edge
        Util.hoverPop(button, 1.05)
        button.MouseEnter:Connect(function()
            if key ~= element.Value then Theme.tweenTo(outline, "Color", "buttonEdge", 0.1) outline.Transparency = 0.1 end
        end)
        button.MouseLeave:Connect(render)
        button.Activated:Connect(function() if not element.Locked then element:Set(key) end end)
    end

    function element:Set(image, silent)
        image = image ~= nil and tostring(image) or nil
        if image and not buttons[image] then return end
        local changed = image ~= self.Value
        self.Value = image
        render()
        self:_fire(image, silent or not changed)
    end
    function element:Get() return self.Value end

    element:Set(cfg.Default ~= nil and cfg.Default or images[1], true)
    return Base.finish(element, cfg)
end
end

__modules["elements/info"] = function()
-- card:Info({ Title = "User ID", Value = "#123", Copy = true | "text to copy" | function() return ... end })
-- A read-only "name ........ value" row; :Set(value) updates it. With Copy a small Copy button right after the
-- value copies it.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

return function(card, cfg)
    local row = create("Frame", { Name = tostring(cfg.Title or "Info"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = card:_order(), Parent = card.body })
    local title = label(row, tostring(cfg.Title or ""), 10, { Name = "Title", Size = UDim2.new(0.42, -6, 1, 0) })
    Theme.bind(title, "TextColor3", "muted")
    local copyWidth = cfg.Copy and 40 or 0
    local value = label(row, "", 10, {
        Name = "Value", Position = UDim2.new(0.42, 0, 0, 0), Size = UDim2.new(0.58, -copyWidth, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium,
    })
    Theme.bind(value, "TextColor3", "text")

    local element = Base.element(card, "Info", {}, row, title, nil)
    -- without a Copy button a long value borrows room from the name (down to what the name needs),
    -- so a long value ("Limited · client-side only") isn't cut next to a short name
    local function share()
        if cfg.Copy then return end
        local scale = card.window.scale and card.window.scale.Scale or 1
        local width = row.AbsoluteSize.X / scale
        if width <= 0 then return end
        local need = Util.textWidth(title.Text, 10, Enum.Font.Gotham) + 10
        local valueNeed = Util.textWidth(value.Text, 10, Enum.Font.GothamMedium)
        -- 42% for the name; less when the value needs it (never less than the name needs), more when a long name fits
        local titleWidth = width * 0.42
        if need > titleWidth then
            titleWidth = math.max(titleWidth, math.min(need, width - valueNeed - 8)) -- a long name takes what a short value leaves
        elseif valueNeed + 10 > width - titleWidth then
            titleWidth = math.max(need, width - valueNeed - 10) -- (a little slack: fonts measure a few px wider on some screens)
        end
        title.Size = UDim2.new(0, titleWidth - 6, 1, 0)
        value.Position = UDim2.new(0, titleWidth, 0, 0)
        value.Size = UDim2.new(1, -titleWidth, 1, 0)
    end
    row:GetPropertyChangedSignal("AbsoluteSize"):Connect(share)
    function element:Set(text) self.Value = text value.Text = tostring(text) share() end
    function element:Get() return self.Value end
    -- a theme role ("success") or a Color3
    function element:SetColor(color) Theme.bind(value, "TextColor3", color or "text") end

    if cfg.Copy then
        local copy = create("TextButton", {
            Name = "Copy", Text = "Copy", TextSize = 8, Font = Enum.Font.Gotham, AutoButtonColor = false, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(34, 16), Parent = row,
        })
        Theme.bind(copy, "BackgroundColor3", "input")
        Theme.bind(copy, "TextColor3", "text")
        corner(copy, 5)
        Theme.bind(stroke(copy), "Color", "buttonEdge")
        copy.Activated:Connect(function()
            local text = cfg.Copy
            if type(text) == "function" then local ok, result = pcall(text) text = ok and result or nil end
            if text == true or text == nil then text = tostring(element.Value):gsub("^#", "") end
            local clipboard = setclipboard or toclipboard
            local ok = type(clipboard) == "function" and pcall(clipboard, tostring(text))
            copy.Text = ok and "OK" or "!"
            task.delay(1.2, function() if copy.Parent then copy.Text = "Copy" end end)
            if ok then card.window:Notify({ Title = "Copied", Content = tostring(cfg.Title or "Value") .. " copied to clipboard" }) end
        end)
    end
    element:Set(cfg.Value ~= nil and cfg.Value or "--")
    return element
end
end

__modules["elements/input"] = function()
-- card:Input({ Title, Desc, Flag, Default, Placeholder, Numeric, ClearOnFocus, Finished, Validate, Callback, Locked })
-- Callback runs when the box loses focus (with Finished = false it runs on every change).
-- Validate = function(text) return ok, message end: checked while typing. ok = true: green edge, false: red edge and
-- the value is not taken (the flag keeps the last good one), nil: no judgement. The message shows under the box.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local baseHeight = cfg.Desc and 40 or 30
    local row, title, desc = Base.row(card, cfg, baseHeight, { right = 160 })
    -- the title takes the left half, the box the right half (up to 170 px)
    title.Size = UDim2.new(0.55, -8, 0, title.Size.Y.Offset)
    if desc then desc.Size = UDim2.new(0.55, -8, 0, 14) end
    local box = create("TextBox", {
        Name = "Box", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0, baseHeight / 2), Size = UDim2.new(0.45, 0, 0, 24),
        BorderSizePixel = 0, Text = "", PlaceholderText = tostring(cfg.Placeholder or ""), TextSize = 10, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = cfg.ClearOnFocus == true, ClipsDescendants = true,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
    })
    Theme.bind(box, "BackgroundColor3", "input")
    Theme.bind(box, "TextColor3", "text")
    Theme.bind(box, "PlaceholderColor3", "muted")
    corner(box, 6)
    local outline = stroke(box)
    Theme.bind(outline, "Color", "buttonEdge")
    local PAD = 9
    Util.padding(box, PAD, PAD, 0, 0)
    -- the box hugs its text (or the placeholder): the same gap left and right, up to 170 px / 45% of the row
    -- measured with a hidden label in the box's own font (the UI font can be changed in Settings)
    local measure = create("TextLabel", { Name = "Measure", BackgroundTransparency = 1, TextTransparency = 1, Size = UDim2.fromOffset(0, 0), TextSize = 10, Font = box.Font, Text = "", Parent = row })
    local function textWidth(text)
        local ok, width = pcall(function()
            measure.FontFace = box.FontFace
            measure.Text = text
            return measure.TextBounds.X
        end)
        if ok and type(width) == "number" and width > 0 then return width end
        return Util.textWidth(text, 10, box.Font)
    end
    local function fit()
        local text = box.Text ~= "" and box.Text or box.PlaceholderText
        local most = 170
        local rowWidth = row.AbsoluteSize.X
        if rowWidth > 0 then most = math.min(most, math.floor(rowWidth * 0.45)) end
        local width = math.clamp(math.ceil(textWidth(text)) + PAD * 2 + 4, 56, math.max(56, most))
        box.Size = UDim2.fromOffset(width, 24)
    end
    box:GetPropertyChangedSignal("Text"):Connect(fit)
    box:GetPropertyChangedSignal("FontFace"):Connect(fit)
    row:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
    fit()

    local element = Base.element(card, "Input", cfg, row, title, desc)
    local function clean(text)
        text = tostring(text or "")
        if cfg.Numeric then text = text:gsub("[^%d%.%-]", "") end
        return text
    end
    function element:Set(text, silent)
        text = clean(text)
        local changed = text ~= self.Value
        self.Value = text
        if box.Text ~= text then box.Text = text end
        self._failed = false
        self:_fire(text, silent or not changed)
        if changed and not silent then self:_accepted("success") end
    end
    function element:Get() return self.Value end
    function element:SetPlaceholder(text) box.PlaceholderText = tostring(text or "") fit() end

    ------------------------------------------------------------ Validate
    local focused = false
    local hint
    local state -- true / false / nil (last Validate result)
    local function edgeRole()
        if state == false then return "danger" end -- (a red edge stays until the text is fixed)
        if not focused then return "buttonEdge" end
        return state == true and "success" or "accent"
    end
    -- returns ok (true / false / nil) and shows it: edge colour + the message under the box
    local function validate(text)
        if type(cfg.Validate) ~= "function" then return nil end
        local ok, result, message = pcall(cfg.Validate, clean(text))
        if not ok then result, message = nil, nil end
        if clean(text) == "" and result == nil then message = nil end
        state = result
        element.Valid = result
        Theme.tweenTo(outline, "Color", edgeRole(), 0.1)
        local show = message ~= nil and tostring(message) ~= ""
        if show and not hint then
            hint = Util.label(row, "", 9, { Name = "Hint", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, baseHeight - 1), Size = UDim2.new(1, -4, 0, 13), TextXAlignment = Enum.TextXAlignment.Right })
        end
        if hint then
            hint.Visible = show
            hint.Text = show and tostring(message) or ""
            Theme.bind(hint, "TextColor3", result == true and "success" or (result == false and "danger" or "muted"))
        end
        row.Size = UDim2.new(1, 0, 0, baseHeight + (show and 13 or 0))
        return result
    end
    element.Validate = function(_, text) return validate(text == nil and box.Text or text) end

    box.Focused:Connect(function() focused = true Theme.tweenTo(outline, "Color", edgeRole(), 0.1) end)
    box.FocusLost:Connect(function()
        focused = false
        if validate(box.Text) == false then
            -- not taken: the value stays the last good one, the box keeps the text and the red hint
            Theme.tweenTo(outline, "Color", edgeRole(), 0.1)
            return
        end
        Theme.tweenTo(outline, "Color", edgeRole(), 0.1)
        -- a good value: its message goes away with the focus
        if hint and state ~= false then hint.Visible = false row.Size = UDim2.new(1, 0, 0, baseHeight) end
        element:Set(box.Text)
    end)
    if cfg.Validate then
        box:GetPropertyChangedSignal("Text"):Connect(function() if focused then validate(box.Text) end end)
    end
    if cfg.Finished == false then
        box:GetPropertyChangedSignal("Text"):Connect(function()
            if validate(box.Text) ~= false then element:Set(box.Text) end
        end)
    end
    element:Set(cfg.Default or "", true)
    if cfg.Validate and element.Value ~= "" then validate(element.Value) end
    if cfg.Locked then box.TextEditable = false end
    return Base.finish(element, cfg)
end
end

__modules["elements/itemcards"] = function()
-- card:ItemCards({ Columns = 2, AddNew = "New profile", OnAdd = function() end, OnAction = function(item, index) end,
--     OnMenu = function(item, index) end, Items = {
--         { Title = "Default", Sub = "now · 46 settings", Desc = "Active · autoload", Color = Color3.fromRGB(232, 232, 236),
--           Badges = { "ACTIVE", "AUTO" }, Action = "Save", Highlight = true },
--     } })
-- A grid of small cards (profiles, saved setups, servers...): a coloured letter badge, a title and a muted line, a
-- "..." menu button, a description, badge tags and one action button. AddNew adds a dashed "+" card at the end.
-- Badges may be { Text = "ACTIVE", Role = "success" }. :SetItems(items), :GetItems(). No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")
local Parts = require("elements/parts")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local columns = math.max(1, tonumber(cfg.Columns) or 2)
    local cellH, gap = tonumber(cfg.Height) or 96, 6
    local holder = create("Frame", { Name = tostring(cfg.Title or "ItemCards"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = card:_order(), Parent = card.body })
    local element = Base.element(card, "ItemCards", { Title = cfg.Title }, holder, nil, nil)
    local items, frames = {}, {}
    local function button(parent, text, props)
        local width = Util.textWidth(text, 10, Enum.Font.GothamMedium) + 20
        local b = create("TextButton", { Name = text, Text = text, AutoButtonColor = false, BorderSizePixel = 0, Size = UDim2.fromOffset(width, 22), TextSize = 10, Font = Enum.Font.GothamMedium, Parent = parent })
        for key, value in pairs(props or {}) do b[key] = value end
        corner(b, 6)
        Theme.bind(b, "BackgroundColor3", "card")
        Theme.bind(b, "TextColor3", "text")
        Theme.bind(Util.stroke(b, nil, 0.2), "Color", "buttonEdge")
        b.MouseEnter:Connect(function() Theme.tweenTo(b, "BackgroundColor3", "hover", 0.1) end)
        b.MouseLeave:Connect(function() Theme.tweenTo(b, "BackgroundColor3", "card", 0.1) end)
        return b
    end
    function element:SetItems(list)
        for _, frame in ipairs(frames) do frame:Destroy() end
        table.clear(frames)
        items = list or {}
        local total = #items + (cfg.AddNew and 1 or 0)
        holder.Size = UDim2.new(1, 0, 0, Parts.gridHeight(total, columns, gap, cellH))
        for index, item in ipairs(items) do
            local position, size = Parts.cell(index, columns, gap, cellH)
            local box, edge = Parts.box(holder, { Name = tostring(item.Title or index), Position = position, Size = size })
            if item.Highlight then Theme.bind(edge, "Color", "buttonEdge") edge.Transparency = 0 end
            frames[#frames + 1] = box
            local color = typeof(item.Color) == "Color3" and item.Color or Theme.get("accent")
            local badge = create("Frame", { Name = "Letter", Position = UDim2.fromOffset(9, 9), Size = UDim2.fromOffset(26, 26), BorderSizePixel = 0, BackgroundColor3 = color, BackgroundTransparency = 0.82, Parent = box })
            corner(badge, 7)
            Util.stroke(badge, color, 0.55)
            local letter = label(badge, string.upper(string.sub(tostring(item.Letter or item.Title or "?"), 1, 1)), 12, { Name = "Text", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold })
            -- (the item's colour, made readable on the card for the current theme: a white profile on Light)
            local function paintLetter() letter.TextColor3 = Theme.readable(color, "card", 3.8) end
            letter.Destroying:Connect(Theme.onChange(paintLetter))
            paintLetter()
            local title = label(box, tostring(item.Title or ""), 11, { Name = "Title", Position = UDim2.fromOffset(42, 8), Size = UDim2.new(1, -70, 0, 15), Font = Enum.Font.GothamMedium })
            Theme.bind(title, "TextColor3", "heading")
            local sub = label(box, tostring(item.Sub or ""), 8, { Name = "Sub", Position = UDim2.fromOffset(42, 23), Size = UDim2.new(1, -70, 0, 11) })
            Theme.bind(sub, "TextColor3", "muted")
            if cfg.OnMenu then
                local menu = create("ImageButton", { Name = "Menu", BackgroundTransparency = 1, Image = "", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 9), Size = UDim2.fromOffset(18, 18), Parent = box })
                Icons.themed(menu, "ellipsis", 14, "muted", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
                menu.Activated:Connect(function() card.window:_safe("ItemCards menu", cfg.OnMenu, item, index) end)
            end
            local desc = label(box, tostring(item.Desc or ""), 9, { Name = "Desc", Position = UDim2.fromOffset(9, 40), Size = UDim2.new(1, -18, 0, 24), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })
            Theme.bind(desc, "TextColor3", "muted")
            local tags = create("Frame", { Name = "Badges", BackgroundTransparency = 1, Position = UDim2.new(0, 9, 1, -28), Size = UDim2.new(1, -90, 0, 20), Parent = box })
            Util.list(tags, 4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
            for order, tag in ipairs(item.Badges or {}) do
                if type(tag) ~= "table" then tag = { Text = tag } end
                local chip = Parts.chip(tags, tostring(tag.Text), tag.Role or "muted", nil, { LayoutOrder = order })
                chip.Size = UDim2.fromOffset(chip.Size.X.Offset, 16)
                chip:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 4)
            end
            if item.Action ~= false then
                local action = button(box, tostring(item.Action or "Open"), { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -9, 1, -8) })
                action.Activated:Connect(function() if cfg.OnAction then card.window:_safe("ItemCards", cfg.OnAction, item, index) end end)
            end
        end
        if cfg.AddNew then
            local position, size = Parts.cell(#items + 1, columns, gap, cellH)
            local add = create("TextButton", { Name = "AddNew", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = position, Size = size, Parent = holder })
            corner(add, 7)
            Theme.bind(Util.stroke(add, nil, 0.1), "Color", "buttonEdge")
            Icons.themed(add, "plus", 16, "muted", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -8) })
            local text = label(add, tostring(cfg.AddNew), 10, { Position = UDim2.new(0, 0, 0.5, 4), Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Center })
            Theme.bind(text, "TextColor3", "muted")
            add.Activated:Connect(function() if cfg.OnAdd then card.window:_safe("ItemCards add", cfg.OnAdd) end end)
            frames[#frames + 1] = add
        end
    end
    function element:GetItems() return items end
    element:SetItems(cfg.Items)
    return Base.finish(element, cfg)
end
end

__modules["elements/keybind"] = function()
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
end

__modules["elements/label"] = function()
-- card:Label("text") or card:Label({ Title = "text", Color = Color3 }) - a wrapped line of muted text.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

return function(card, cfg)
    local text = Util.label(card.body, tostring(cfg.Title or cfg.Text or ""), 10, {
        Name = "Label", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None, RichText = true, LayoutOrder = card:_order(),
    })
    if typeof(cfg.Color) == "Color3" then text.TextColor3 = cfg.Color else Theme.bind(text, "TextColor3", "muted") end
    local element = Base.element(card, "Label", {}, text, text, nil)
    function element:Set(value) text.Text = tostring(value) end
    function element:SetColor(color) Theme.bind(text, "TextColor3", color or "muted") end
    return element
end
end

__modules["elements/listitem"] = function()
-- card:ListItem({ Title = "Theme", Icon = "palette", Value = "Dark", Callback = function() end })      -- a link row
-- card:ListItem({ Title = "Free mouse", Icon = "mouse-pointer", Toggle = true, Flag = "freeMouse", Default = true })
-- A settings-list row: the icon in a small rounded box, the title, then on the right a muted value with a chevron
-- (the row is a button: Callback) or, with Toggle = true, a switch (a normal saved toggle). Badge = "RISKY": a small
-- tag after the title; Risky = true: the title (and tag) red. Rows put one after the
-- other read as a grouped list (a thin line between them). :SetValue(text); toggles also :Set / :Get.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")
local Parts = require("elements/parts")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local row = create("TextButton", { Name = tostring(cfg.Title or "ListItem"), Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, cfg.Desc and 42 or 36), LayoutOrder = card:_order(), Parent = card.body })
    local line = create("Frame", { Name = "Line", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, cfg.Icon and 32 or 0, 1, 0), Size = UDim2.new(1, cfg.Icon and -32 or 0, 0, 1), BorderSizePixel = 0, Parent = row })
    Theme.bind(line, "BackgroundColor3", "line")
    local x = 0
    if cfg.Icon then
        local box = create("Frame", { Name = "IconBox", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(22, 22), BorderSizePixel = 0, Parent = row })
        Theme.bind(box, "BackgroundColor3", "input")
        corner(box, 6)
        Icons.themed(box, cfg.Icon, 12, cfg.IconColor or "icon", { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
        x = 32
    end
    -- room on the right: a switch needs less than a value + chevron (so a row half a card wide keeps its title)
    local reserve = cfg.Toggle and 44 or 130
    local title = label(row, tostring(cfg.Title or ""), 11, { Name = "Title", Position = UDim2.fromOffset(x, cfg.Desc and 5 or 0), Size = UDim2.new(1, -x - reserve, 0, cfg.Desc and 18 or 36) })
    Theme.bind(title, "TextColor3", cfg.Risky and "danger" or "text")
    if cfg.Badge then
        local tag = Parts.chip(row, tostring(cfg.Badge), cfg.Risky and "danger" or "muted", nil, { Name = "Badge", AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, x + Util.textWidth(tostring(cfg.Title or ""), 11, Enum.Font.Gotham) + 6, 0, cfg.Desc and 14 or 18) })
        tag.Size = UDim2.fromOffset(tag.Size.X.Offset, 15)
        tag:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 4)
    end
    local desc
    if cfg.Desc then
        desc = label(row, tostring(cfg.Desc), 9, { Name = "Desc", Position = UDim2.fromOffset(x, 22), Size = UDim2.new(1, -x - reserve, 0, 13) })
        Theme.bind(desc, "TextColor3", "muted")
    end
    local kind = cfg.Toggle and "Toggle" or "ListItem"
    local element = Base.element(card, kind, cfg, row, title, desc)
    if cfg.Toggle then
        local switch = create("Frame", { Name = "Switch", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(30, 16), BorderSizePixel = 0, Parent = row })
        corner(switch, 8)
        local knob = create("Frame", { Name = "Knob", Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(12, 12), BorderSizePixel = 0, Parent = switch })
        corner(knob, 6)
        Theme.bind(knob, "BackgroundColor3", "knob")
        element.Value = cfg.Default == true
        local function render(animate)
            Theme.tweenTo(switch, "BackgroundColor3", element.Value and "toggleOn" or "buttonEdge", animate and 0.15 or nil)
            Util.tween(knob, animate and 0.15 or 0, { Position = UDim2.fromOffset(element.Value and 16 or 2, 2) })
        end
        function element:Set(on, silent)
            on = on == true
            local changed = on ~= self.Value
            self.Value = on
            render(true)
            self:_fire(on, silent or not changed)
        end
        function element:Get() return self.Value end
        row.Activated:Connect(function() if not element.Locked then element:Set(not element.Value) end end)
        render(false)
        element:_fire(element.Value, true)
    else
        local chevron = Icons.themed(row, "chevron-right", 12, "muted", { Name = "Chevron", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0) })
        local value = label(row, tostring(cfg.Value or ""), 10, { Name = "Value", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, chevron and cfg.Chevron ~= false and -18 or 0, 0.5, 0), Size = UDim2.fromOffset(120, 16), TextXAlignment = Enum.TextXAlignment.Right })
        Theme.bind(value, "TextColor3", "muted")
        if chevron and cfg.Chevron == false then chevron.Visible = false end
        function element:SetValue(text) value.Text = tostring(text) end
        row.Activated:Connect(function() if not element.Locked and cfg.Callback then element:_call(cfg.Callback) end end)
    end
    row.MouseEnter:Connect(function() if not cfg.Risky then Theme.tweenTo(title, "TextColor3", "heading", 0.1) end end)
    row.MouseLeave:Connect(function() if not cfg.Risky then Theme.tweenTo(title, "TextColor3", "text", 0.1) end end)
    return Base.finish(element, cfg)
end
end

__modules["elements/notice"] = function()
-- card:Notice({ Kind = "success" | "warning" | "danger" | "info", Title = "Everything is running", Desc = "1 module limited",
--              Icon = "circle-check", Button = { Title = "Debug info", Icon = "copy", Callback = function() end } })
-- A tinted strip with an icon, a bold line, a smaller line and an optional button on the right (status banners,
-- "5 unsaved changes - Save"). :Set({ Kind, Title, Desc, Icon }) changes any of them. No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, label = Util.create, Util.corner, Util.label

local ICONS = { success = "circle-check", warning = "circle-alert", danger = "circle-x", info = "info" }

return function(card, cfg)
    local holder = create("Frame", { Name = tostring(cfg.Title or "Notice"), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, cfg.Desc and 44 or 34), LayoutOrder = card:_order(), Parent = card.body })
    corner(holder, 8)
    Theme.bind(holder, "BackgroundColor3", "card")
    -- a tint of the kind's colour over the card
    local tint = create("Frame", { Name = "Tint", BorderSizePixel = 0, BackgroundTransparency = 0.88, Size = UDim2.fromScale(1, 1), Parent = holder })
    corner(tint, 8)
    local edge = Util.stroke(holder, nil, 0.55)
    -- (the text takes the width left of the button, or all of it without one)
    local buttonWidth = cfg.Button and (Util.textWidth(tostring(cfg.Button.Title or "OK"), 10, Enum.Font.GothamMedium) + (cfg.Button.Icon and 34 or 20)) or nil
    local reserve = 34 + (buttonWidth and buttonWidth + 16 or 10)
    local title = label(holder, "", 11, { Name = "Title", Position = UDim2.fromOffset(34, cfg.Desc and 7 or 0), Size = UDim2.new(1, -reserve, 0, cfg.Desc and 16 or 34), Font = Enum.Font.GothamMedium })
    local desc = label(holder, "", 9, { Name = "Desc", Position = UDim2.fromOffset(34, 23), Size = UDim2.new(1, -reserve, 0, 13) })
    local element = Base.element(card, "Notice", { Title = cfg.Title }, holder, title, desc)
    local icon
    local state = { Kind = cfg.Kind or "info", Title = cfg.Title, Desc = cfg.Desc, Icon = cfg.Icon }
    if cfg.Button then
        local b = cfg.Button
        local text = tostring(b.Title or "OK")
        local width = buttonWidth
        local button = create("TextButton", { Name = "Button", Text = "", AutoButtonColor = false, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(width, 24), Parent = holder })
        corner(button, 6)
        Theme.bind(button, "BackgroundColor3", "card")
        Theme.bind(Util.stroke(button, nil, 0.2), "Color", "buttonEdge")
        if b.Icon then Icons.themed(button, b.Icon, 11, "text", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0) }) end
        local bt = label(button, text, 10, { Position = UDim2.fromOffset(b.Icon and 24 or 10, 0), Size = UDim2.new(1, -(b.Icon and 30 or 20), 1, 0), Font = Enum.Font.GothamMedium })
        Theme.bind(bt, "TextColor3", "text")
        button.Activated:Connect(function() if b.Callback then element:_call(b.Callback) end end)
    end
    function element:Set(changes)
        for key, value in pairs(changes or {}) do state[key] = value end
        local role = state.Kind == "info" and "accent" or state.Kind
        Theme.bind(tint, "BackgroundColor3", role)
        Theme.bind(edge, "Color", role)
        title.Text = tostring(state.Title or "")
        Theme.bind(title, "TextColor3", role == "accent" and "heading" or role)
        desc.Text = tostring(state.Desc or "")
        desc.Visible = state.Desc ~= nil
        Theme.bind(desc, "TextColor3", "muted")
        if icon then icon:Destroy() end
        icon = Icons.themed(holder, state.Icon or ICONS[state.Kind] or "info", 16, role, { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0) })
    end
    element:Set({})
    return Base.finish(element, cfg)
end
end

__modules["elements/paragraph"] = function()
-- card:Paragraph({ Title = "Heading", Content = "Longer text, wraps to any number of lines." })
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create = Util.create

return function(card, cfg)
    local holder = create("Frame", {
        Name = "Paragraph", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = card:_order(), Parent = card.body,
    })
    Util.list(holder, 2)
    local title = Util.label(holder, tostring(cfg.Title or ""), 11, { Name = "Title", Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamMedium, LayoutOrder = 1 })
    Theme.bind(title, "TextColor3", "heading")
    title.Visible = cfg.Title ~= nil
    local content = Util.label(holder, tostring(cfg.Content or ""), 10, {
        Name = "Content", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top, RichText = true, LayoutOrder = 2,
    })
    Theme.bind(content, "TextColor3", "muted")
    local element = Base.element(card, "Paragraph", {}, holder, title, content)
    function element:Set(text) content.Text = tostring(text) end
    function element:SetContent(text) content.Text = tostring(text) end
    return element
end
end

__modules["elements/parts"] = function()
-- Small pieces shared by the dashboard-style elements (StatTiles, Gauges, Tiles, Timeline, ...):
-- grid cells, chips, sparklines, dotted rings, state colours. Not an element itself.
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

local Parts = {}

-- a state name -> theme role: "on" / "ok" green, "limited" / "warn" amber, "error" red, anything else muted
Parts.STATE = {
    on = "success", ok = "success", running = "success", success = "success", good = "success",
    limited = "warning", warn = "warning", warning = "warning", pending = "warning",
    error = "danger", danger = "danger", failed = "danger", off = "muted", idle = "muted", none = "muted",
}
function Parts.stateRole(state)
    if state == true then return "success" elseif state == false or state == nil then return "muted" end
    return Parts.STATE[string.lower(tostring(state))] or "muted"
end

-- Color = "warning" (a theme role) or a Color3: what Theme.bind takes
function Parts.color(value, fallback)
    if typeof(value) == "Color3" or type(value) == "string" then return value end
    return fallback or "heading"
end

-- position / size of cell `index` (1-based) in a grid of `columns` with `gap` px between cells
function Parts.cell(index, columns, gap, height, top)
    local col, row = (index - 1) % columns, math.floor((index - 1) / columns)
    return UDim2.new(col / columns, col * gap / columns, 0, (top or 0) + row * (height + gap)),
        UDim2.new(1 / columns, -gap * (columns - 1) / columns, 0, height)
end
function Parts.gridHeight(count, columns, gap, height)
    local rows = math.ceil(count / columns)
    return rows > 0 and rows * height + (rows - 1) * gap or 0
end

-- a box like the library's inputs (tile background)
function Parts.box(parent, props)
    local frame = create("Frame", { BorderSizePixel = 0, Parent = parent })
    for key, value in pairs(props or {}) do frame[key] = value end
    Theme.bind(frame, "BackgroundColor3", "input")
    corner(frame, 7)
    local edge = stroke(frame, nil, 0.2)
    Theme.bind(edge, "Color", "line")
    return frame, edge
end

-- a small rounded chip: [icon] text. Returns the frame and its label; chip:SetText via the label.
function Parts.chip(parent, text, role, iconName, props)
    local width = Util.textWidth(text, 9, Enum.Font.GothamMedium) + (iconName and 38 or 24)
    local frame = create("Frame", { Name = "Chip", Size = UDim2.fromOffset(width, 18), BorderSizePixel = 0, Parent = parent })
    for key, value in pairs(props or {}) do frame[key] = value end
    Theme.bind(frame, "BackgroundColor3", "input")
    corner(frame, 9)
    Theme.bind(stroke(frame, nil, 0.3), "Color", "buttonEdge")
    local x = 8
    if iconName then
        local icon = Icons.themed(frame, iconName, 10, role or "muted", { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 7, 0.5, 0) })
        if icon then x = 21 end
    end
    local text_ = label(frame, text, 9, { Name = "Text", Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -x - 6, 1, 0), Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.None })
    Theme.bind(text_, "TextColor3", role or "text")
    local function resize(value)
        text_.Text = tostring(value)
        frame.Size = UDim2.fromOffset(Util.textWidth(text_.Text, 9, Enum.Font.GothamMedium) + x + 16, 18)
    end
    return frame, text_, resize
end

-- a small status dot
function Parts.dot(parent, role, size, props)
    local dot = create("Frame", { Name = "Dot", Size = UDim2.fromOffset(size or 6, size or 6), BorderSizePixel = 0, Parent = parent })
    for key, value in pairs(props or {}) do dot[key] = value end
    corner(dot, (size or 6))
    Theme.bind(dot, "BackgroundColor3", role or "muted")
    return dot
end

-- A sparkline (line of frames) inside `parent` (fills it). Returns draw(values): redraws with these values.
-- Lines are drawn from the frame's own size (AbsoluteSize, without the window's UI scale).
function Parts.sparkline(parent, role, scaleOf)
    local holder = create("Frame", { Name = "Spark", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ClipsDescendants = true, Parent = parent })
    local segments, last = {}, nil
    local function draw(values)
        last = values or last
        values = last or {}
        local scale = scaleOf and scaleOf() or 1
        local w, h = holder.AbsoluteSize.X / scale, holder.AbsoluteSize.Y / scale
        local count = #values
        if w <= 0 or h <= 0 or count < 2 then for _, s in ipairs(segments) do s.Visible = false end return end
        local low, high = math.huge, -math.huge
        for _, v in ipairs(values) do low, high = math.min(low, v), math.max(high, v) end
        if high - low < 1e-6 then low, high = low - 1, high + 1 end
        local function point(i) return (i - 1) / (count - 1) * w, h - 2 - (values[i] - low) / (high - low) * (h - 4) end
        for i = 1, math.max(#segments, count - 1) do
            local seg = segments[i]
            if not seg then
                seg = create("Frame", { Name = "Seg", AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Parent = holder })
                Theme.bind(seg, "BackgroundColor3", role or "heading")
                segments[i] = seg
            end
            if i < count then
                local x1, y1 = point(i)
                local x2, y2 = point(i + 1)
                local dx, dy = x2 - x1, y2 - y1
                seg.Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
                seg.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + 1, 1.5)
                seg.Rotation = math.deg(math.atan2(dy, dx))
                seg.Visible = true
            else
                seg.Visible = false
            end
        end
    end
    holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() draw() end)
    return draw, holder
end

-- A ring of `count` dots round the centre of `parent` (size px); set(fraction, role) lights the first part.
function Parts.dotRing(parent, size, count, dotSize)
    count, dotSize = count or 40, dotSize or 3
    local dots = {}
    local radius = size / 2 - dotSize
    for i = 1, count do
        local angle = (i - 1) / count * math.pi * 2 - math.pi / 2
        local dot = create("Frame", {
            Name = "Seg", AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Size = UDim2.fromOffset(dotSize, dotSize),
            Position = UDim2.new(0.5, math.cos(angle) * radius, 0.5, math.sin(angle) * radius), Parent = parent,
        })
        corner(dot, dotSize)
        Theme.bind(dot, "BackgroundColor3", "line")
        dots[i] = dot
    end
    return function(fraction, role)
        local lit = math.floor(math.clamp(tonumber(fraction) or 0, 0, 1) * count + 0.5)
        for i, dot in ipairs(dots) do Theme.bind(dot, "BackgroundColor3", i <= lit and (role or "heading") or "line") end
    end
end

-- the window's UI scale (for drawing in px)
function Parts.scaleOf(window)
    return function() return window and window.scale and window.scale.Scale or 1 end
end

-- a header line for an element: title (left) and an optional right-hand text; returns title, right labels
function Parts.header(holder, cfg, y)
    local title, right
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Position = UDim2.fromOffset(0, y or 0), Size = UDim2.new(1, -90, 0, 20) })
        Theme.bind(title, "TextColor3", "text")
        right = label(holder, "", 9, { Name = "Right", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, y or 0), Size = UDim2.fromOffset(90, 20), TextXAlignment = Enum.TextXAlignment.Right })
        Theme.bind(right, "TextColor3", "muted")
    end
    return title, right
end

return Parts
end

__modules["elements/playerlist"] = function()
-- card:PlayerList({ Title, Flag, Multi = true, Height = 150, IncludeSelf = false, Callback = function(ids) end })
-- Searchable list of the players in the server (avatar, display name, @name); updates when players join / leave.
-- Value is a list of UserIds (Multi) or one UserId; :GetPlayers() returns the chosen Player objects in the server.
-- Chosen players who leave stay chosen and come back selected.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local Services = Util.Services
local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label
local ROW = 30

return function(card, cfg)
    local window = card.window
    local Players = Services.Players
    local multi = cfg.Multi ~= false
    local height = tonumber(cfg.Height) or 150
    local holder = create("Frame", { Name = tostring(cfg.Title or "Players"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height + (cfg.Title and 56 or 34)), LayoutOrder = card:_order(), Parent = card.body })
    local top = 0
    local title
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Size = UDim2.new(1, -90, 0, 20) })
        Theme.bind(title, "TextColor3", "text")
        top = 22
    end
    local count = label(holder, "", 9, { Name = "Count", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(90, 20), TextXAlignment = Enum.TextXAlignment.Right })
    Theme.bind(count, "TextColor3", "muted")
    local search = create("TextBox", {
        Name = "Search", Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, 26), BorderSizePixel = 0, Text = "",
        PlaceholderText = "Search players...", TextSize = 10, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false, Parent = holder,
    })
    Theme.bind(search, "BackgroundColor3", "input")
    Theme.bind(search, "TextColor3", "text")
    Theme.bind(search, "PlaceholderColor3", "muted")
    corner(search, 6)
    Theme.bind(stroke(search), "Color", "buttonEdge")
    Util.padding(search, 9, 9, 0, 0)
    local list = create("ScrollingFrame", {
        Name = "List", Position = UDim2.fromOffset(0, top + 32), Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = holder,
    })
    Theme.bind(list, "BackgroundColor3", "base")
    Theme.bind(list, "ScrollBarImageColor3", "muted")
    Util.fadeScrollbar(list)
    list.BackgroundTransparency = 0.4
    corner(list, 6)
    Theme.bind(stroke(list), "Color", "line")
    local inner = create("Frame", { Name = "Rows", BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = list })
    Util.list(inner, 2)
    Util.padding(inner, 0, 0, 0, 6)
    Util.fitCanvas(list, inner)
    local empty = label(list, "No players", 10, { Name = "Empty", Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Center, Visible = false })
    Theme.bind(empty, "TextColor3", "muted")

    local element = Base.element(card, "PlayerList", cfg, holder, title, nil)
    local chosen = {} -- [userId] = true
    local rows = {}
    local function valueList()
        local ids = {}
        for id in pairs(chosen) do ids[#ids + 1] = id end
        table.sort(ids)
        return ids
    end
    local function renderRow(entry)
        local on = chosen[entry.player.UserId] == true
        entry.button.BackgroundTransparency = on and 0 or 1
        Theme.bind(entry.name, "TextColor3", on and "accent" or "text")
        entry.check.Visible = on
    end
    local function filter()
        local query = search.Text:lower()
        local shown = 0
        for _, entry in pairs(rows) do
            local player = entry.player
            local match = query == "" or player.Name:lower():find(query, 1, true) or player.DisplayName:lower():find(query, 1, true)
            entry.button.Visible = match ~= nil and match ~= false
            if entry.button.Visible then shown = shown + 1 end
        end
        empty.Visible = shown == 0
        local selected = 0
        for _ in pairs(chosen) do selected = selected + 1 end
        local total = 0
        for _ in pairs(rows) do total = total + 1 end
        count.Text = selected > 0 and (selected .. " selected") or (total .. (total == 1 and " player" or " players"))
    end
    local function commit()
        element.Value = multi and valueList() or valueList()[1]
        for _, entry in pairs(rows) do renderRow(entry) end
        filter()
        element:_fire(element.Value)
    end
    local function addRow(player)
        if rows[player] or not holder.Parent or (player == Players.LocalPlayer and not cfg.IncludeSelf) then return end
        local button = create("TextButton", {
            Name = player.Name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, ROW), Parent = inner,
        })
        Theme.bind(button, "BackgroundColor3", "selected")
        corner(button, 5)
        local avatar = create("ImageLabel", { Position = UDim2.fromOffset(4, 3), Size = UDim2.fromOffset(24, 24), BorderSizePixel = 0, Parent = button })
        Theme.bind(avatar, "BackgroundColor3", "input")
        corner(avatar, 12)
        local name = label(button, player.DisplayName, 10, { Position = UDim2.fromOffset(36, 2), Size = UDim2.new(1, -60, 0, 14), Font = Enum.Font.GothamMedium })
        local user = label(button, "@" .. player.Name, 9, { Position = UDim2.fromOffset(36, 15), Size = UDim2.new(1, -60, 0, 12) })
        Theme.bind(user, "TextColor3", "muted")
        local check = create("Frame", { Name = "Check", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, Visible = false, Parent = button })
        Theme.bind(check, "BackgroundColor3", "accent")
        corner(check, 3)
        local entry = { player = player, button = button, name = name, check = check }
        rows[player] = entry
        button.MouseEnter:Connect(function() if not chosen[player.UserId] then button.BackgroundTransparency = 0.5 end end)
        button.MouseLeave:Connect(function() renderRow(entry) end)
        button.Activated:Connect(function()
            if element.Locked then return end
            local id = player.UserId
            if multi then
                chosen[id] = not chosen[id] or nil
            else
                local was = chosen[id]
                chosen = {}
                if not was then chosen[id] = true end
            end
            commit()
        end)
        avatar.Image = Util.avatar(player.UserId) -- rbxthumb: no web request
        renderRow(entry)
        filter()
    end
    local function removeRow(player)
        local entry = rows[player]
        if entry then entry.button:Destroy() rows[player] = nil filter() end
    end
    for _, player in ipairs(Players:GetPlayers()) do addRow(player) end
    window.maid:connect(Players.PlayerAdded, addRow)
    window.maid:connect(Players.PlayerRemoving, removeRow)
    search:GetPropertyChangedSignal("Text"):Connect(filter)

    function element:Set(ids, silent)
        chosen = {}
        for _, id in ipairs(type(ids) == "table" and ids or { ids }) do
            id = tonumber(id)
            if id then chosen[id] = true end
            if not multi then break end
        end
        self.Value = multi and valueList() or valueList()[1]
        for _, entry in pairs(rows) do renderRow(entry) end
        filter()
        self:_fire(self.Value, silent)
    end
    function element:Get() return self.Value end
    function element:GetPlayers()
        local out = {}
        for _, player in ipairs(Players:GetPlayers()) do if chosen[player.UserId] then out[#out + 1] = player end end
        return out
    end
    function element:Clear() self:Set({}) end

    element:Set(cfg.Default or {}, true)
    return Base.finish(element, cfg)
end
end

__modules["elements/progress"] = function()
-- card:Progress({ Title, Desc, Value = 0, Max = 100, Suffix = "%", Format = function(value, max) return "3 / 10" end, Indeterminate })
-- A progress bar (farm, download, cooldown...). :Set(value), :SetMax(max), :SetIndeterminate(true) shows a moving
-- stripe for "working, no number yet". No flag (it reports, it does not configure).
-- Steps = 5: the track is split into 5 segments that fill one by one (Max defaults to Steps: Set(3) = "3 / 5").
-- :SetSteps(n) (0 = a plain bar again).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local window = card.window
    local top = cfg.Desc and 38 or 22
    local row, title, desc = Base.row(card, cfg, top + 12, { right = 90, titleHeight = 22 })
    local value = label(row, "", 10, { Name = "Value", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 1), Size = UDim2.fromOffset(86, 20), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium })
    Theme.bind(value, "TextColor3", "text")
    if desc then desc.Size = UDim2.new(1, desc.Size.X.Offset, 0, 14) end
    local track = create("Frame", { Name = "Track", Position = UDim2.new(0, 0, 0, top + 4), Size = UDim2.new(1, 0, 0, 6), BorderSizePixel = 0, ClipsDescendants = true, Parent = row })
    Theme.bind(track, "BackgroundColor3", "input")
    corner(track, 3)
    local fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = track })
    Theme.bind(fill, "BackgroundColor3", "accent")
    corner(fill, 3)
    create("UIGradient", { Transparency = NumberSequence.new(0.25, 0), Parent = fill })

    local element = Base.element(card, "Progress", {}, row, title, desc)
    local max = math.max(tonumber(cfg.Max) or tonumber(cfg.Steps) or 100, 1e-9)
    local segments, segmentHolder = {}, nil
    local suffix = cfg.Suffix
    local indeterminate = false
    local function text()
        if indeterminate then return cfg.IndeterminateText or "Working..." end
        if type(cfg.Format) == "function" then
            local ok, result = pcall(cfg.Format, element.Value, max)
            if ok then return tostring(result) end
        end
        if suffix == nil and max == 100 then return math.floor(element.Value + 0.5) .. "%" end
        return math.floor(element.Value + 0.5) .. " / " .. math.floor(max + 0.5) .. (suffix and (" " .. suffix) or "")
    end
    local function render(animate)
        value.Text = text()
        if segmentHolder then segmentHolder.Visible = not indeterminate end
        track.BackgroundTransparency = (#segments > 0 and not indeterminate) and 1 or 0
        if indeterminate then fill.Visible = true return end
        local ratio = math.clamp(element.Value / max, 0, 1)
        fill.Visible = #segments == 0
        for index, segment in ipairs(segments) do
            local part = math.clamp(ratio * #segments - (index - 1), 0, 1)
            if animate then Util.tween(segment, 0.25, { Size = UDim2.fromScale(part, 1) }) else segment.Size = UDim2.fromScale(part, 1) end
        end
        fill.Position = UDim2.fromScale(0, 0)
        if animate then Util.tween(fill, 0.25, { Size = UDim2.fromScale(ratio, 1) }) else fill.Size = UDim2.fromScale(ratio, 1) end
    end
    function element:Set(v) self.Value = math.max(0, tonumber(v) or 0) render(true) end
    function element:SetMax(m) max = math.max(tonumber(m) or max, 1e-9) render(true) end
    function element:Get() return self.Value, max end
    local spinner
    function element:SetIndeterminate(on)
        indeterminate = on == true
        if spinner then spinner:Disconnect() spinner = nil end
        if indeterminate then
            fill.Size = UDim2.fromScale(0.3, 1)
            local started = os.clock()
            spinner = window.maid:connect(Util.Services.RunService.Heartbeat, function()
                -- (gone: stop for good; out of sight: nothing to move)
                if not row.Parent then if spinner then spinner:Disconnect() spinner = nil end return end
                if not Util.shown(row) then return end
                local t = ((os.clock() - started) / 1.2) % 1
                fill.Position = UDim2.fromScale(-0.3 + t * 1.3, 0)
            end)
        end
        render(false)
    end
    function element:SetSteps(count)
        count = math.clamp(math.floor(tonumber(count) or 0), 0, 40)
        if segmentHolder then segmentHolder:Destroy() segmentHolder = nil end
        segments = {}
        if count > 0 then
            -- the track's own frame clips, so the segments sit in a holder over it
            segmentHolder = create("Frame", { Name = "Segments", BackgroundTransparency = 1, Position = track.Position, Size = track.Size, Parent = row })
            local gap = count > 12 and 2 or 3
            Util.list(segmentHolder, gap, Enum.FillDirection.Horizontal)
            for index = 1, count do
                local cell = create("Frame", { Name = "Segment" .. index, Size = UDim2.new(1 / count, -gap * (count - 1) / count, 1, 0), BorderSizePixel = 0, LayoutOrder = index, ClipsDescendants = true, Parent = segmentHolder })
                Theme.bind(cell, "BackgroundColor3", "input")
                corner(cell, 3)
                local part = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = cell })
                Theme.bind(part, "BackgroundColor3", "accent")
                corner(part, 3)
                segments[index] = part
            end
        end
        render(false)
    end
    element.Value = math.max(0, tonumber(cfg.Value or cfg.Default) or 0)
    if tonumber(cfg.Steps) then element:SetSteps(cfg.Steps) end
    render(false)
    if cfg.Indeterminate then element:SetIndeterminate(true) end
    return element
end
end

__modules["elements/radio"] = function()
-- card:Radio({ Title, Flag, Items = { "Closest", "Lowest HP", { Title = "Random", Desc = "Any target" } }, Default, Callback, Locked })
-- One choice from a short list, every option visible with a round marker. Value is the chosen option's text
-- (or its Value, when an option is { Value = "hp", Title = "Lowest HP" }). :SetItems(list).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

local function normalize(list)
    local out = {}
    for _, option in ipairs(list or {}) do
        if type(option) == "table" then
            local text = tostring(option.Title or option.Value or "")
            out[#out + 1] = { value = option.Value ~= nil and option.Value or text, title = text, desc = option.Desc, locked = option.Locked == true }
        else
            out[#out + 1] = { value = option, title = tostring(option) }
        end
    end
    return out
end

return function(card, cfg)
    local holder = create("Frame", { Name = tostring(cfg.Title or "Radio"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = card:_order(), Parent = card.body })
    Util.list(holder, 2)
    local title
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 0 })
        Theme.bind(title, "TextColor3", cfg.Risky and "danger" or "text")
    end
    local list = create("Frame", { Name = "Options", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = holder })
    Util.list(list, 2)

    local element = Base.element(card, "Radio", cfg, holder, title, nil)
    local options, rows = {}, {}
    local function render(animate)
        local duration = animate and 0.12 or nil
        for _, entry in ipairs(rows) do
            local on = entry.option.value == element.Value
            Theme.tweenTo(entry.ring, "Color", on and "accent" or "buttonEdge", duration)
            entry.dot.Visible = on
            Theme.tweenTo(entry.text, "TextColor3", entry.option.locked and "muted" or (on and "heading" or "text"), duration)
        end
    end
    local function build()
        for _, entry in ipairs(rows) do entry.button:Destroy() end
        rows = {}
        for index, option in ipairs(options) do
            local height = option.desc and 36 or 26
            local button = create("TextButton", { Name = tostring(option.title), Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height), LayoutOrder = index, Parent = list })
            local circle = create("Frame", { Name = "Circle", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 1, 0, option.desc and 12 or height / 2), Size = UDim2.fromOffset(14, 14), BorderSizePixel = 0, Parent = button })
            corner(circle, 7)
            Theme.bind(circle, "BackgroundColor3", "input")
            local ring = stroke(circle)
            local dot = create("Frame", { Name = "Dot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, Visible = false, Parent = circle })
            corner(dot, 3)
            Theme.bind(dot, "BackgroundColor3", "accent")
            local text = label(button, option.title, 10, { Name = "Text", Position = UDim2.fromOffset(24, option.desc and 3 or 0), Size = UDim2.new(1, -24, 0, option.desc and 18 or height) })
            if option.desc then
                local sub = label(button, tostring(option.desc), 9, { Name = "Desc", Position = UDim2.fromOffset(24, 20), Size = UDim2.new(1, -24, 0, 13) })
                Theme.bind(sub, "TextColor3", "muted")
            end
            button.Activated:Connect(function()
                if element.Locked or option.locked then return end
                element:Set(option.value)
            end)
            button.MouseEnter:Connect(function() if option.value ~= element.Value and not option.locked then Theme.tweenTo(text, "TextColor3", "heading", 0.1) end end)
            button.MouseLeave:Connect(function() render(true) end)
            rows[index] = { option = option, button = button, ring = ring, dot = dot, text = text }
        end
        render(false)
    end
    local function has(value)
        for _, option in ipairs(options) do if option.value == value then return true end end
        return false
    end
    function element:Set(value, silent)
        if not has(value) then -- also accept an option's title
            for _, option in ipairs(options) do if option.title == value then value = option.value break end end
        end
        if not has(value) then return end
        local changed = value ~= self.Value
        self.Value = value
        render(true)
        self:_fire(value, silent or not changed)
    end
    function element:Get() return self.Value end
    function element:SetItems(list)
        options = normalize(list)
        build()
        if not has(self.Value) then self.Value = options[1] and options[1].value or nil self:_fire(self.Value, true) end
    end

    options = normalize(cfg.Items)
    build()
    element.Value = has(cfg.Default) and cfg.Default or (options[1] and options[1].value)
    render(false)
    element:_fire(element.Value, true)
    return Base.finish(element, cfg)
end
end

__modules["elements/range"] = function()
-- card:Range({ Title, Desc, Flag, Min, Max, Default = { 20, 80 }, Step, Suffix, MinGap, Callback = function(range) end })
-- A slider with two handles; Value is { low, high }. Dragging moves the nearer handle; the values can be typed.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner = Util.create, Util.corner

return function(card, cfg)
    local window = card.window
    local min, max = tonumber(cfg.Min) or 0, tonumber(cfg.Max) or 100
    if max < min then min, max = max, min end
    local step = tonumber(cfg.Step) or 1
    local gap = math.max(0, tonumber(cfg.MinGap) or 0)
    local suffix = cfg.Suffix and (" " .. tostring(cfg.Suffix)) or ""
    local decimals = Util.decimals(step)
    local top = cfg.Desc and 38 or 22
    local row, title, desc = Base.row(card, cfg, top + 18, { right = 150, titleHeight = 22, helpRight = 146, helpY = 11 })

    -- "low – high suffix": two small boxes
    local boxes = create("Frame", { Name = "Values", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 1), Size = UDim2.fromOffset(150, 20), Parent = row })
    local function box(name, x, align)
        local object = create("TextBox", {
            Name = name, Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(52, 20), BackgroundTransparency = 1, BorderSizePixel = 0,
            Text = "", TextSize = 10, Font = Enum.Font.GothamMedium, ClearTextOnFocus = false, TextXAlignment = align, Parent = boxes,
        })

        Theme.bind(object, "BackgroundColor3", "base")
        Theme.bind(object, "TextColor3", "text")
        corner(object, 6)
        object:SetAttribute("QNoScale", true) -- (its width follows the value at this size)
        return object
    end
    local lowBox, highBox = box("Low", 0, Enum.TextXAlignment.Right), box("High", 64, Enum.TextXAlignment.Right)
    local dash = Util.label(boxes, "–", 10, { Name = "Dash", Position = UDim2.fromOffset(52, 0), Size = UDim2.fromOffset(14, 20), TextXAlignment = Enum.TextXAlignment.Center })
    Theme.bind(dash, "TextColor3", "muted")

    if desc then desc.Size = UDim2.new(1, 0, 0, 14) end -- the values sit on the title line only
    local track = create("Frame", { Name = "Track", Position = UDim2.new(0, 0, 0, top + 8), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, Parent = row })
    Theme.bind(track, "BackgroundColor3", "buttonEdge")
    corner(track, 1)
    local fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = track })
    Theme.bind(fill, "BackgroundColor3", "accent")
    local function knob(name)
        local object = create("Frame", { Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(10, 10), BorderSizePixel = 0, ZIndex = 2, Parent = track })
        Theme.bind(object, "BackgroundColor3", "accent")
        corner(object, 5)
        return object
    end
    local lowKnob, highKnob = knob("LowKnob"), knob("HighKnob")
    local reach = Util.isTouch() and 8 or 0 -- (taller on touch screens)
    local hit = create("TextButton", { Name = "Hit", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.new(0, -6, 0, top - reach), Size = UDim2.new(1, 12, 0, 18 + reach * 2), ZIndex = 3, Parent = row })

    local element = Base.element(card, "Range", cfg, row, title, desc)
    local focused = {}
    local function format(value)
        return decimals > 0 and string.format("%." .. decimals .. "f", value) or tostring(math.floor(value + 0.5))
    end
    local function snap(value)
        value = math.clamp(Util.round(value - min, step) + min, min, max)
        if decimals > 0 then value = tonumber(string.format("%." .. decimals .. "f", value)) end
        return value
    end
    local function ratio(value) return max > min and (value - min) / (max - min) or 0 end
    local function render()
        local low, high = element.Value[1], element.Value[2]
        local a, b = ratio(low), ratio(high)
        lowKnob.Position = UDim2.new(a, 5 - 10 * a, 0.5, 0)
        highKnob.Position = UDim2.new(b, 5 - 10 * b, 0.5, 0)
        fill.Position = UDim2.new(a, 5 - 10 * a, 0, 0)
        fill.Size = UDim2.new(b - a, -10 * (b - a), 1, 0)
        if not focused.low then lowBox.Text = format(low) end -- (the unit once, after the high value: "0 – 100 %")
        if not focused.high then highBox.Text = format(high) .. suffix end
        -- "low – high" packed against the right edge (boxes as wide as their text)
        local function width(object) return math.max(18, Util.textWidth(object.Text, 10, Enum.Font.GothamMedium) + (focused[object == lowBox and "low" or "high"] and 14 or 4)) end
        local highWidth, lowWidth = width(highBox), width(lowBox)
        highBox.Position, highBox.Size = UDim2.new(1, -highWidth, 0, 0), UDim2.fromOffset(highWidth, 20)
        dash.Position = UDim2.new(1, -highWidth - 14, 0, 0)
        lowBox.Position, lowBox.Size = UDim2.new(1, -highWidth - 14 - lowWidth, 0, 0), UDim2.fromOffset(lowWidth, 20)
        if not cfg.Help then title.Size = UDim2.new(1, -(highWidth + 14 + lowWidth + 10), 0, title.Size.Y.Offset) end
    end
    function element:Set(value, silent)
        if type(value) ~= "table" then return end
        local low, high = tonumber(value[1]) or min, tonumber(value[2]) or max
        if low > high then low, high = high, low end
        low, high = snap(low), snap(high)
        if high - low < gap then
            if low + gap <= max then high = snap(low + gap) else low = snap(high - gap) end
        end
        local old = self.Value
        self.Value = { low, high }
        render()
        self:_fire(self.Value, silent or (old and old[1] == low and old[2] == high))
    end
    function element:Get() return self.Value[1], self.Value[2] end

    local dragging
    local function fromPoint(point)
        local width = track.AbsoluteSize.X
        if width <= 0 then return end
        local inset = 5 * (window.scale and window.scale.Scale or 1)
        local value = min + math.clamp((point.X - Util.screenPos(track).X - inset) / math.max(1, width - inset * 2), 0, 1) * (max - min)
        if not dragging then
            -- grab the nearer handle (the high one when both sit on the same spot at the top end)
            local low, high = element.Value[1], element.Value[2]
            dragging = (math.abs(value - low) < math.abs(value - high) or (low == high and value < low)) and 1 or 2
        end
        local next = { element.Value[1], element.Value[2] }
        next[dragging] = value
        if dragging == 1 then next[1] = math.min(value, element.Value[2] - gap) else next[2] = math.max(value, element.Value[1] + gap) end
        element:Set(next)
    end
    hit.InputBegan:Connect(function(input)
        if not Util.isPress(input) or element.Locked then return end
        dragging = nil
        fromPoint(Util.pointer(input))
        window:_beginDrag(input, fromPoint, function() dragging = nil end)
    end)
    for key, object in pairs({ low = lowBox, high = highBox }) do
        object.Focused:Connect(function() focused[key] = true object.BackgroundTransparency = 0.2 render() end)
        object.FocusLost:Connect(function()
            focused[key] = false
            object.BackgroundTransparency = 1
            local number = tonumber((object.Text:gsub("[^%d%.%-]", "")))
            if number then
                local next = { element.Value[1], element.Value[2] }
                next[key == "low" and 1 or 2] = number
                element:Set(next)
            end
            render()
        end)
    end

    local default = type(cfg.Default) == "table" and cfg.Default or { min, max }
    element.Value = { min, max }
    element:Set(default, true)
    return Base.finish(element, cfg)
end
end

__modules["elements/search"] = function()
-- card:Search({ Placeholder = "Search settings…" })
-- A search box that filters the page it is on: rows whose title (or description, also of what is inside them) does
-- not contain the text hide,
-- and so do cards with nothing left; an empty box shows everything again. Put it in a card of its own at the top
-- (page:Card({ Wide = true })). :Set(text), :Get(), :Clear(). No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local holder = create("Frame", { Name = "Search", Size = UDim2.new(1, 0, 0, 30), BorderSizePixel = 0, LayoutOrder = card:_order(), Parent = card.body })
    Theme.bind(holder, "BackgroundColor3", "input")
    corner(holder, 7)
    Theme.bind(Util.stroke(holder, nil, 0.2), "Color", "buttonEdge")
    Icons.themed(holder, "search", 13, "muted", { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0) })
    local box = create("TextBox", {
        Name = "Box", BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -60, 1, 0), Text = "", ClearTextOnFocus = false,
        PlaceholderText = tostring(cfg.Placeholder or "Search…"), TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
    })
    Theme.bind(box, "TextColor3", "heading")
    local count = label(holder, "", 9, { Name = "Count", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(60, 14), TextXAlignment = Enum.TextXAlignment.Right })
    Theme.bind(count, "TextColor3", "muted")
    local element = Base.element(card, "Search", { Title = cfg.Title }, holder, nil, nil)
    local own = card.frame
    local page = card.page

    -- every card frame on the page (columns and wide areas), not the one holding the box
    local function cards()
        local out = {}
        for _, area in ipairs({ page.wide, page.left, page.right, page.wideBottom }) do
            if area then
                for _, child in ipairs(area:GetChildren()) do
                    if child:IsA("Frame") and child ~= own and child:FindFirstChildOfClass("UIListLayout") then out[#out + 1] = child end
                end
            end
        end
        return out
    end
    -- the text a row can be found by: its name, its Title / Desc labels
    -- (titles further in count too: a SideNav part, a Row of toggles, a grid of tiles)
    local function words(row)
        local parts = { row.Name }
        for _, item in ipairs(row:GetDescendants()) do
            if item:IsA("TextLabel") and (item.Name == "Title" or item.Name == "Desc") then parts[#parts + 1] = item.Text end
        end
        return string.lower(table.concat(parts, " "))
    end
    local hidden = {}
    local function apply(query)
        query = string.lower(query or "")
        for object, was in pairs(hidden) do if object.Parent then object.Visible = was end end
        table.clear(hidden)
        if query == "" then count.Text = "" return end
        local found = 0
        for _, frame in ipairs(cards()) do
            local any = false
            local heading = frame:FindFirstChild("Heading")
            local cardMatch = heading and string.find(string.lower(heading:FindFirstChildWhichIsA("TextLabel") and heading:FindFirstChildWhichIsA("TextLabel").Text or ""), query, 1, true)
            for _, row in ipairs(frame:GetChildren()) do
                if row:IsA("GuiObject") and row ~= heading and row.Name ~= "CardDesc" and row.Visible then
                    if cardMatch or string.find(words(row), query, 1, true) then
                        any = true found = found + 1
                    else
                        hidden[row] = row.Visible row.Visible = false
                    end
                end
            end
            if not any then hidden[frame] = frame.Visible frame.Visible = false end
        end
        count.Text = found == 1 and "1 match" or (found .. " matches")
    end
    box:GetPropertyChangedSignal("Text"):Connect(function() apply(box.Text) end)
    function element:Set(text) box.Text = tostring(text or "") apply(box.Text) end
    function element:Get() return box.Text end
    function element:Clear() self:Set("") end
    return Base.finish(element, cfg)
end
end

__modules["elements/segment"] = function()
-- card:Segment({ Title, Desc, Flag, Items = { "Head", "Body", "Closest" }, Default, Callback, Locked, Style })
-- One choice shown as a row of buttons (Qustah's Aim Part / Priority rows). On a narrow card the buttons move
-- under the title. Style (or CreateWindow({ SegmentStyle })): "Boxed" (a framed button each, the default),
-- "Track" (one rounded track, a thumb slides under the chosen one), "Underline" (plain words, a line under the
-- chosen one), "Line" (a short line under the chosen word only), "Dot" (a dot under it), "Divided" (words split
-- by thin bars, the chosen one bright), "Ghost" (a thin outline round the chosen word) or "Pills" (small pills as
-- wide as their word, the chosen one filled). "Tab" is Underline with a fainter base line and a word-wide
-- line; "Capsule" is Pills inside one rounded track, the filled part sliding to the chosen word.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local options = {}
    for _, option in ipairs(cfg.Items or {}) do options[#options + 1] = tostring(option) end
    local row, title, desc = Base.row(card, cfg, 40, {})
    title.Size = UDim2.new(0, 110, 0, cfg.Desc and 18 or 40)
    if desc then desc.Size = UDim2.new(0, 110, 0, 14) end
    local strip = create("Frame", {
        Name = "Segments", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 120, 0.5, 0),
        Size = UDim2.new(1, -120, 0, 28), Parent = row,
    })

    local window = card.window
    local style = tostring(cfg.Style or (window and window.cfg and window.cfg.SegmentStyle) or "Boxed")
    local STYLES = { Boxed = true, Track = true, Underline = true, Line = true, Dot = true, Divided = true, Ghost = true, Pills = true, Tab = true, Capsule = true }
    if not STYLES[style] then style = "Boxed" end
    local element = Base.element(card, "Segment", cfg, row, title, desc)
    element.Style = style
    element.Items = options
    local buttons, outlines = {}, {}
    local count = math.max(1, #options)
    -- the moving part of Track (a thumb behind the chosen word) and Underline (a bar under it)
    local thumb, bar
    if style == "Track" then
        Theme.bind(strip, "BackgroundColor3", "input")
        strip.BackgroundTransparency = 0
        corner(strip, 8)
        Theme.bind(stroke(strip, nil, 0.6), "Color", "line")
        thumb = create("Frame", { Name = "Thumb", BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1 / count, -6, 1, -6), Parent = strip })
        Theme.bind(thumb, "BackgroundColor3", "selected")
        corner(thumb, 6)
        Theme.bind(stroke(thumb, nil, 0.55), "Color", "buttonEdge")
    elseif style == "Underline" then
        local base = create("Frame", { Name = "Line", BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), Parent = strip })
        Theme.bind(base, "BackgroundColor3", "line")
        bar = create("Frame", { Name = "Bar", BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.new(1 / count, -16, 0, 2), ZIndex = 2, Parent = strip })
        Theme.bind(bar, "BackgroundColor3", "accent")
        corner(bar, 1)
    elseif style == "Tab" then
        local base = create("Frame", { Name = "Line", BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0.5, Parent = strip })
        Theme.bind(base, "BackgroundColor3", "line")
        bar = create("Frame", { Name = "Bar", BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(20, 2), ZIndex = 2, Parent = strip })
        Theme.bind(bar, "BackgroundColor3", "accent")
        corner(bar, 1)
    elseif style == "Capsule" then
        -- a track as wide as its words (left), the filled thumb slides / resizes to the chosen one
        strip.BackgroundTransparency = 0
        Theme.bind(strip, "BackgroundColor3", "input")
        corner(strip, 13)
        Theme.bind(stroke(strip, nil, 0.6), "Color", "line")
        thumb = create("Frame", { Name = "Thumb", BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(40, 20), Parent = strip })
        Theme.bind(thumb, "BackgroundColor3", "accent")
        corner(thumb, 10)
    elseif style == "Line" then
        bar = create("Frame", { Name = "Bar", BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(20, 2), ZIndex = 2, Parent = strip })
        Theme.bind(bar, "BackgroundColor3", "accent")
        corner(bar, 1)
    elseif style == "Dot" then
        bar = create("Frame", { Name = "Dot", BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(4, 4), ZIndex = 2, Parent = strip })
        Theme.bind(bar, "BackgroundColor3", "accent")
        corner(bar, 2)
    elseif style == "Divided" then
        for index = 1, count - 1 do
            local divider = create("Frame", { Name = "Divider", BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(index / count, 0, 0.5, 0), Size = UDim2.fromOffset(1, 12), Parent = strip })
            Theme.bind(divider, "BackgroundColor3", "line")
        end
    elseif style == "Pills" then
        Util.list(strip, 6, Enum.FillDirection.Horizontal).VerticalAlignment = Enum.VerticalAlignment.Center
    end
    local function render(animate)
        local duration = animate and 0.12 or nil
        local chosen = table.find(options, element.Value) or 1
        for index, option in ipairs(options) do
            local selected = option == element.Value
            local button = buttons[index]
            if style == "Boxed" then
                Theme.tweenTo(button, "BackgroundColor3", selected and "selected" or "input", duration)
                Theme.tweenTo(button, "TextColor3", selected and "accent" or "muted", duration)
                Theme.tweenTo(outlines[index], "Color", selected and "accent" or "line", duration)
                outlines[index].Transparency = selected and 0.25 or 0.65
            elseif style == "Pills" then
                Theme.tweenTo(button, "BackgroundColor3", selected and "accent" or "input", duration)
                Theme.tweenTo(button, "TextColor3", selected and "base" or "muted", duration)
            elseif style == "Ghost" then
                Theme.tweenTo(button, "TextColor3", selected and "heading" or "muted", duration)
                outlines[index].Transparency = selected and 0.35 or 1
            elseif style == "Capsule" then
                Theme.tweenTo(button, "TextColor3", selected and "base" or "muted", duration)
            elseif style == "Line" or style == "Dot" or style == "Divided" or style == "Tab" then
                Theme.tweenTo(button, "TextColor3", selected and "heading" or "muted", duration)
            else
                Theme.tweenTo(button, "TextColor3", selected and (style == "Track" and "heading" or "accent") or "muted", duration)
            end
        end
        local target = UDim2.new((chosen - 0.5) / count, 0, thumb and 0.5 or 1, style == "Dot" and -1 or 0)
        if style == "Capsule" and buttons[chosen] then
            local button = buttons[chosen]
            target = UDim2.new(0, button.Position.X.Offset, 0.5, 0)
            if animate then Util.tween(thumb, 0.16, { Size = UDim2.fromOffset(button.Size.X.Offset, 20) }) else thumb.Size = UDim2.fromOffset(button.Size.X.Offset, 20) end
        end
        if (style == "Line" or style == "Tab") and options[chosen] then
            local width = Util.textWidth(options[chosen], 10, Enum.Font.GothamMedium) + (style == "Tab" and 16 or 6)
            if animate then Util.tween(bar, 0.16, { Size = UDim2.fromOffset(width, 2) }) else bar.Size = UDim2.fromOffset(width, 2) end
        end
        local moving = thumb or bar
        if moving then
            if animate then Util.tween(moving, 0.16, { Position = target }) else moving.Position = target end
        end
    end
    for index, option in ipairs(options) do
        local button = create("TextButton", {
            Name = option, Text = option, TextSize = 10, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((index - 0.5) / count, 0, 0.5, 0),
            Size = UDim2.new(1 / count, -4, 0, 24), TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = index, ZIndex = 3, Parent = strip,
        })
        if style == "Boxed" then
            corner(button, 6)
            outlines[index] = stroke(button)
        elseif style == "Pills" then
            corner(button, 12)
            button.Size = UDim2.fromOffset(Util.textWidth(option, 10, Enum.Font.GothamMedium) + 26, 24)
        else
            button.BackgroundTransparency = 1
            if style == "Capsule" then
                button.AnchorPoint = Vector2.new(0, 0.5)
                button.ZIndex = 3
            end
            if style == "Ghost" then
                corner(button, 12)
                button.Size = UDim2.new(1 / count, -10, 0, 22)
                outlines[index] = stroke(button)
                Theme.bind(outlines[index], "Color", "accent")
            end
        end
        buttons[index] = button
        button.Activated:Connect(function() if not element.Locked then element:Set(option) end end)
        -- plain words: a word under the mouse brightens a little
        if style == "Tab" or style == "Capsule" then
            button.MouseEnter:Connect(function() if option ~= element.Value and not element.Locked then Theme.tweenTo(button, "TextColor3", "text", 0.08) end end)
            button.MouseLeave:Connect(function() if option ~= element.Value then Theme.tweenTo(button, "TextColor3", "muted", 0.08) end end)
        end
    end
    -- Capsule: each word as wide as itself, side by side from the left; the track fits around them
    if style == "Capsule" then
        local x = 3
        for _, button in ipairs(buttons) do
            local width = Util.textWidth(button.Text, 10, Enum.Font.GothamMedium) + 24
            button.Size = UDim2.fromOffset(width, 20)
            button.Position = UDim2.new(0, x, 0.5, 0)
            x = x + width + 2
        end
        strip.Size = UDim2.fromOffset(x + 1, 26)
    end

    -- narrow card: title on top, buttons underneath
    local function fit()
        local stacked = row.AbsoluteSize.X > 0 and row.AbsoluteSize.X < 300
        row.Size = UDim2.new(1, 0, 0, stacked and 70 or (cfg.Desc and 46 or 40))
        strip.AnchorPoint = stacked and Vector2.new(0, 0) or Vector2.new(0, 0.5)
        strip.Position = stacked and UDim2.fromOffset(0, cfg.Desc and 40 or 30) or UDim2.new(0, 120, 0.5, 0)
        if style == "Capsule" then
            strip.Size = UDim2.fromOffset(strip.Size.X.Offset, 26) -- (as wide as its words)
        else
            strip.Size = stacked and UDim2.new(1, 0, 0, 28) or UDim2.new(1, -120, 0, 28)
        end
        title.Size = UDim2.new(stacked and 1 or 0, stacked and 0 or 110, 0, cfg.Desc and 18 or (stacked and 28 or 40))
    end
    row:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)

    function element:Set(value, silent)
        value = value ~= nil and tostring(value) or nil
        if value and not table.find(options, value) then return end
        local changed = value ~= self.Value
        self.Value = value
        render(true)
        self:_fire(value, silent or not changed)
    end
    function element:Get() return self.Value end

    element.Value = cfg.Default ~= nil and table.find(options, tostring(cfg.Default)) and tostring(cfg.Default) or options[1]
    render(false)
    fit()
    element:_fire(element.Value, true)
    return Base.finish(element, cfg)
end
end

__modules["elements/sidenav"] = function()
-- local nav = card:SideNav({ Width = 140, Height = 320, Items = { { "Appearance", "palette" }, { "Behaviour", "sliders-horizontal" } } })
-- local look = nav:Section("Appearance")       -- a card-like part: look:Toggle({ ... }), look:Slider({ ... }), ...
-- A menu down the left of the card and the chosen part on the right (one part shows at a time). nav:Select(name),
-- nav.Selected, nav:OnSelect(function(name) end). Footer = function(part) end builds something under the menu
-- (an Unload button...). No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local width = tonumber(cfg.Width) or 140
    local holder = create("Frame", { Name = tostring(cfg.Title or "SideNav"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, tonumber(cfg.Height) or 0), AutomaticSize = cfg.Height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y, LayoutOrder = card:_order(), Parent = card.body })
    local menu = create("Frame", { Name = "Menu", BackgroundTransparency = 1, Size = UDim2.new(0, width, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = holder })
    local list = create("Frame", { Name = "Items", BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = menu })
    Util.list(list, 2)
    local divider = create("Frame", { Name = "Divider", Position = UDim2.new(0, width, 0, 0), Size = UDim2.new(0, 1, 1, 0), BorderSizePixel = 0, Parent = holder })
    Theme.bind(divider, "BackgroundColor3", "line")
    local content = create("Frame", { Name = "Content", BackgroundTransparency = 1, Position = UDim2.fromOffset(width + 12, 0), Size = UDim2.new(1, -width - 12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = holder })
    local element = Base.element(card, "SideNav", { Title = cfg.Title }, holder, nil, nil)
    local parts, buttons, listeners = {}, {}, {}

    local function paint()
        for name, button in pairs(buttons) do
            local on = name == element.Selected
            Theme.tweenTo(button.frame, "BackgroundColor3", on and "selected" or "card", 0.1)
            button.frame.BackgroundTransparency = on and 0 or 1
            Theme.tweenTo(button.text, "TextColor3", on and "heading" or "muted", 0.1)
            if button.icon then Theme.tweenTo(button.icon, "ImageColor3", on and "heading" or "muted", 0.1) end
        end
    end
    function element:Section(name)
        name = tostring(name)
        if parts[name] then return parts[name] end
        local body = create("Frame", { Name = name, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, Parent = content })
        Util.list(body, 4)
        local part = setmetatable({ page = card.page, window = card.window, order = 0, body = body, frame = card.frame, title = name }, getmetatable(card))
        parts[name] = part
        if not self.Selected then self:Select(name) end
        return part
    end
    function element:Select(name)
        name = tostring(name)
        self.Selected = name
        for other, part in pairs(parts) do part.body.Visible = other == name end
        paint()
        for _, callback in ipairs(listeners) do card.window:_safe("SideNav", callback, name) end
    end
    function element:OnSelect(callback) listeners[#listeners + 1] = callback return self end
    for index, item in ipairs(cfg.Items or {}) do
        if type(item) ~= "table" then item = { item } end
        local name, iconName = tostring(item[1] or item.Title), item[2] or item.Icon
        local frame = create("TextButton", { Name = name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = index, Parent = list })
        corner(frame, 7)
        local icon = iconName and Icons.themed(frame, iconName, 13, "muted", { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0) })
        local text = label(frame, name, 10, { Name = "Title", Position = UDim2.fromOffset(icon and 29 or 10, 0), Size = UDim2.new(1, -36, 1, 0) })
        buttons[name] = { frame = frame, text = text, icon = icon }
        frame.Activated:Connect(function() element:Select(name) end)
        element:Section(name)
    end
    if cfg.Footer then
        -- under the menu items (an Unload button...)
        local foot = create("Frame", { Name = "Footer", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1e6, Parent = list })
        Util.list(foot, 4)
        Util.padding(foot, 0, 0, 10, 0)
        local part = setmetatable({ page = card.page, window = card.window, order = 0, body = foot, frame = card.frame, title = "Footer" }, getmetatable(card))
        card.window:_safe("SideNav footer", cfg.Footer, part)
    end
    -- (the card grows with the taller of the menu and the shown part: AutomaticSize, nothing to measure)
    paint()
    return Base.finish(element, cfg)
end
end

__modules["elements/slider"] = function()
-- card:Slider({ Title, Desc, Flag, Min, Max, Default, Step, Suffix, Callback, Locked, Icons = { From = "volume", To = "volume-2" }, Bubble = true })
-- Drag the track, or click the value and type a number. Icons puts an icon at each end of the track (clicking one
-- steps the value); while dragging a bubble over the knob shows the value (Bubble = false turns it off).
-- Callback(value, dragging): dragging is true while the knob is held, and one last call with false comes on
-- release - do heavy work only when `dragging` is false.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner = Util.create, Util.corner

return function(card, cfg)
    local window = card.window
    local min, max = tonumber(cfg.Min) or 0, tonumber(cfg.Max) or 100
    if max < min then min, max = max, min end
    local step = tonumber(cfg.Step) or 1
    local suffix = cfg.Suffix and (" " .. tostring(cfg.Suffix)) or ""
    local decimals = Util.decimals(step)
    local top = cfg.Desc and 38 or 22
    local row, title, desc = Base.row(card, cfg, top + 18, { right = 90, titleHeight = 22, helpRight = 84, helpY = 11 })

    if desc then desc.Size = UDim2.new(1, 0, 0, 14) end -- the value sits on the title line only
    local box = create("TextBox", {
        Name = "Value", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 1), Size = UDim2.fromOffset(78, 20),
        BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", TextSize = 10, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Right, ClearTextOnFocus = false, Parent = row,
    })
    -- value sits flush right like the other controls; while typing it gets a small field
    local boxPad = Util.padding(box, 0, 0, 0, 0)
    box.Focused:Connect(function() box.BackgroundTransparency = 0.2 boxPad.PaddingRight = UDim.new(0, 6) boxPad.PaddingLeft = UDim.new(0, 6) end)
    box.FocusLost:Connect(function() box.BackgroundTransparency = 1 boxPad.PaddingRight = UDim.new(0, 0) boxPad.PaddingLeft = UDim.new(0, 0) end)
    Theme.bind(box, "TextColor3", "text")
    Theme.bind(box, "BackgroundColor3", "base")
    corner(box, 6)
    local sideIcons = type(cfg.Icons) == "table" and cfg.Icons or nil
    local inset = sideIcons and 20 or 0
    local track = create("Frame", { Name = "Track", Position = UDim2.new(0, inset, 0, top + 8), Size = UDim2.new(1, -inset * 2, 0, 2), BorderSizePixel = 0, Parent = row })
    Theme.bind(track, "BackgroundColor3", "buttonEdge")
    corner(track, 1)
    local fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = track })
    Theme.bind(fill, "BackgroundColor3", "accent")
    corner(fill, 1)
    local knob = create("Frame", { Name = "Knob", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(10, 10), BorderSizePixel = 0, ZIndex = 2, Parent = track })
    Theme.bind(knob, "BackgroundColor3", "accent")
    corner(knob, 5)
    -- (taller on touch screens: easier to catch with a finger)
    local reach = Util.isTouch() and 8 or 0
    local hit = create("TextButton", { Name = "Hit", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.new(0, inset - 6, 0, top - reach), Size = UDim2.new(1, 12 - inset * 2, 0, 18 + reach * 2), ZIndex = 3, Parent = row })
    -- value bubble over the knob while dragging
    local bubble = create("TextLabel", {
        Name = "Bubble", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -6), Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X,
        BorderSizePixel = 0, Text = "", TextSize = 9, Font = Enum.Font.GothamMedium, Visible = false, ZIndex = 6, Parent = knob,
    })
    Theme.bind(bubble, "BackgroundColor3", "selected")
    Theme.bind(bubble, "TextColor3", "heading")
    corner(bubble, 5)
    Util.padding(bubble, 7, 7, 0, 0)
    Theme.bind(Util.stroke(bubble), "Color", "buttonEdge")

    local element = Base.element(card, "Slider", cfg, row, title, desc)
    local focused = false
    local dragging, movedWhileDragging = false, false
    element.Dragging = false

    local function format(value)
        return (decimals > 0 and string.format("%." .. decimals .. "f", value) or tostring(math.floor(value + 0.5))) .. suffix
    end
    local function render()
        local ratio = max > min and (element.Value - min) / (max - min) or 0
        fill.Size = UDim2.new(ratio, 5 - 10 * ratio, 1, 0)
        knob.Position = UDim2.new(ratio, 5 - 10 * ratio, 0.5, 0)
        if not focused then box.Text = format(element.Value) end
        bubble.Text = format(element.Value)
    end
    function element:Set(value, silent)
        value = tonumber(value)
        if not value then render() return end
        value = math.clamp(Util.round(value - min, step) + min, min, max)
        if decimals > 0 then value = tonumber(string.format("%." .. decimals .. "f", value)) end
        local changed = value ~= self.Value
        self.Value = value
        render()
        if changed and dragging then movedWhileDragging = true end
        self:_fire(value, silent or not changed, dragging)
    end
    function element:Get() return self.Value end
    function element:SetRange(newMin, newMax)
        min, max = tonumber(newMin) or min, tonumber(newMax) or max
        self:Set(self.Value)
    end

    local function fromPoint(point)
        local width = track.AbsoluteSize.X
        if width <= 0 then return end
        local inset = 5 * (window.scale and window.scale.Scale or 1)
        element:Set(min + math.clamp((point.X - Util.screenPos(track).X - inset) / math.max(1, width - inset * 2), 0, 1) * (max - min))
    end
    hit.InputBegan:Connect(function(input)
        if not Util.isPress(input) or element.Locked then return end
        bubble.Visible = cfg.Bubble ~= false
        dragging, movedWhileDragging = true, false
        element.Dragging = true
        fromPoint(Util.pointer(input))
        window:_beginDrag(input, fromPoint, function()
            bubble.Visible = false
            dragging = false
            element.Dragging = false
            if movedWhileDragging then element:_fire(element.Value, false, false) end -- released: the final value
        end)
    end)
    if sideIcons then
        -- icons at both ends; a click moves one step (or a tenth of the range) that way
        local stride = step > 0 and math.max(step, (max - min) / 10) or (max - min) / 10
        for index, key in ipairs({ "From", "To" }) do
            local name = sideIcons[key] or sideIcons[index]
            local icon = name and Icons.themed(row, name, 14, "muted", {
                Name = key .. "Icon", AnchorPoint = Vector2.new(index == 1 and 0 or 1, 0.5), Position = UDim2.new(index == 1 and 0 or 1, 0, 0, top + 9),
            })
            if icon then
                local click = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 6, 1, 6), Position = UDim2.fromOffset(-3, -3), ZIndex = 4, Parent = icon })
                click.Activated:Connect(function()
                    if element.Locked then return end
                    element:Set(element.Value + (index == 1 and -stride or stride))
                end)
                click.MouseEnter:Connect(function() Theme.tweenTo(icon, "ImageColor3", "heading", 0.1) end)
                click.MouseLeave:Connect(function() Theme.tweenTo(icon, "ImageColor3", "muted", 0.1) end)
            end
        end
    end
    box.Focused:Connect(function() focused = true end)
    box.FocusLost:Connect(function()
        focused = false
        local number = tonumber((box.Text:gsub("[^%d%.%-]", "")))
        if number then element:Set(number) else render() end
        render()
    end)

    element.Value = math.clamp(tonumber(cfg.Default) or min, min, max)
    render()
    element:_fire(element.Value, true)
    return Base.finish(element, cfg)
end
end

__modules["elements/stat"] = function()
-- card:Stat({ Title = "Coins", Value = 0, Icon = "coins", Prefix = "$", Suffix = " /h", Decimals = 0, Separator = ",",
--             Delta = "percent" | "absolute" | false, Invert = false, Format = function(value) return "..." end })
-- A big number whose digits roll like an odometer when it changes, with a chip showing the last change
-- (+12.5% green, -3 red; Invert = true when lower is better, e.g. ping). :Set(value), :Add(amount), :Get().
-- No flag (it shows something, it does not configure).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

local SIZE, HEIGHT = 18, 22
local FONT = Enum.Font.GothamBold

local function group(text, separator)
    if separator == "" then return text end
    local sign, whole, rest = text:match("^([%-]?)(%d+)(.*)$")
    if not whole then return text end
    whole = whole:reverse():gsub("(%d%d%d)", "%1" .. separator:reverse()):reverse()
    if whole:sub(1, #separator) == separator then whole = whole:sub(#separator + 1) end
    return sign .. whole .. rest
end

return function(card, cfg)
    local hasIcon = cfg.Icon and Icons.Get(cfg.Icon)
    local x = hasIcon and 44 or 0
    local holder = create("Frame", { Name = tostring(cfg.Title or "Stat"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = card:_order(), Parent = card.body })
    if hasIcon then
        local tile = create("Frame", { Name = "IconTile", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(34, 34), BorderSizePixel = 0, Parent = holder })
        Theme.bind(tile, "BackgroundColor3", "accentDeep")
        corner(tile, 9)
        local edge = stroke(tile, nil, 0.6)
        Theme.bind(edge, "Color", "accent")
        Icons.themed(tile, cfg.Icon, 16, "accent", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
    end
    local title = label(holder, tostring(cfg.Title or ""), 9, { Name = "Title", Position = UDim2.fromOffset(x, 2), Size = UDim2.new(1, -x - 80, 0, 14), Font = Enum.Font.GothamMedium })
    Theme.bind(title, "TextColor3", "muted")
    local digits = create("Frame", { Name = "Digits", BackgroundTransparency = 1, Position = UDim2.fromOffset(x, 17), Size = UDim2.new(1, -x - 80, 0, HEIGHT), ClipsDescendants = true, Parent = holder })
    Util.list(digits, 0, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)

    -- change chip on the right
    local chip = create("Frame", { Name = "Delta", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, BorderSizePixel = 0, Visible = false, Parent = holder })
    corner(chip, 10)
    Util.list(chip, 4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    Util.padding(chip, 7, 8, 0, 0)
    local chipIcon = Icons.themed(chip, "trending-up", 12, "success", { Name = "Arrow", LayoutOrder = 1 })
    local chipText = label(chip, "", 9, { Name = "Text", Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2 })

    local element = Base.element(card, "Stat", {}, holder, title, nil)
    local decimals = math.max(0, math.floor(tonumber(cfg.Decimals) or 0))
    local separator = cfg.Separator == nil and "," or tostring(cfg.Separator)
    local digitWidth = math.max(8, Util.textWidth("0", SIZE, FONT) + 2)

    local function format(value)
        if type(cfg.Format) == "function" then
            local ok, result = pcall(cfg.Format, value)
            if ok then return tostring(result) end
        end
        local text = decimals > 0 and string.format("%." .. decimals .. "f", value) or tostring(math.floor(value + 0.5))
        return tostring(cfg.Prefix or "") .. group(text, separator) .. tostring(cfg.Suffix or "")
    end

    -- one column per character: digits are a 0-9 strip that slides, everything else a plain label
    local columns, shape = {}, nil
    local function build(text)
        for _, column in ipairs(columns) do column.frame:Destroy() end
        columns = {}
        for index = 1, #text do
            local char = text:sub(index, index)
            local digit = tonumber(char)
            if digit then
                local frame = create("Frame", { Name = "Digit", BackgroundTransparency = 1, Size = UDim2.fromOffset(digitWidth, HEIGHT), ClipsDescendants = true, LayoutOrder = index, Parent = digits })
                local strip = create("Frame", { Name = "Strip", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, -digit * HEIGHT), Size = UDim2.fromOffset(digitWidth, HEIGHT * 10), Parent = frame })
                for n = 0, 9 do
                    local glyph = label(strip, tostring(n), SIZE, { Name = tostring(n), Position = UDim2.fromOffset(0, n * HEIGHT), Size = UDim2.fromOffset(digitWidth, HEIGHT), Font = FONT, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.None })
                    glyph:SetAttribute("QNoScale", true) -- (sized to its digit column)
                    Theme.bind(glyph, "TextColor3", "heading")
                end
                columns[index] = { frame = frame, strip = strip, digit = digit }
            else
                local frame = label(digits, char, SIZE, { Name = "Char", Size = UDim2.fromOffset(char == " " and 4 or 0, HEIGHT), AutomaticSize = char == " " and Enum.AutomaticSize.None or Enum.AutomaticSize.X, Font = FONT, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.None, LayoutOrder = index })
                frame:SetAttribute("QNoScale", true)
                Theme.bind(frame, "TextColor3", "heading")
                columns[index] = { frame = frame, char = char }
            end
        end
    end
    -- the layout of digits / other characters, e.g. "$9,999": a change here rebuilds, otherwise digits roll
    local function shapeOf(text) return (text:gsub("%d", "#")) end

    local function show(text, animate)
        local newShape = shapeOf(text)
        if newShape ~= shape then
            shape = newShape
            build(text)
            return
        end
        for index = 1, #text do
            local column, digit = columns[index], tonumber(text:sub(index, index))
            if column and column.strip and digit and digit ~= column.digit then
                column.digit = digit
                local target = UDim2.fromOffset(0, -digit * HEIGHT)
                if animate then
                    -- the further right, the quicker (like a real counter)
                    Util.tween(column.strip, 0.35 + (#text - index) * 0.04, { Position = target }, Enum.EasingStyle.Quint)
                else
                    column.strip.Position = target
                end
            end
        end
    end

    local mode = cfg.Delta == nil and "percent" or cfg.Delta
    local function renderDelta(old, new)
        if not mode or old == nil or old == new then return end
        local change = new - old
        local good = (change > 0) ~= (cfg.Invert == true)
        local role = good and "success" or "danger"
        local text
        if mode == "absolute" then
            text = (change > 0 and "+" or "") .. format(change):gsub("^" .. tostring(cfg.Prefix or ""):gsub("%p", "%%%0"), "")
        else
            if old == 0 then text = change > 0 and "+new" or "-" else text = string.format("%+.1f%%", change / math.abs(old) * 100) end
        end
        chipText.Text = text
        Theme.bind(chip, "BackgroundColor3", role)
        chip.BackgroundTransparency = 0.86
        Theme.bind(chipText, "TextColor3", role)
        if chipIcon then
            Icons.Apply(chipIcon, change > 0 and "trending-up" or "trending-down")
            Theme.bind(chipIcon, "ImageColor3", role)
        end
        chip.Visible = true
    end

    function element:Set(value, silent)
        value = tonumber(value)
        if not value then return end
        local old = self.Value
        self.Value = value
        show(format(value), old ~= nil and not silent)
        renderDelta(old, value)
    end
    function element:Add(amount) self:Set((self.Value or 0) + (tonumber(amount) or 0)) end
    function element:Get() return self.Value end
    function element:SetTitle(text) title.Text = tostring(text) end
    element:Set(tonumber(cfg.Value or cfg.Default) or 0, true)
    return element
end
end

__modules["elements/stattiles"] = function()
-- card:StatTiles({ Columns = 4, Items = {
--     { Title = "FPS", Source = "FPS" },                                   -- live (the library's sampler)
--     { Title = "Ping", Source = "Ping", Suffix = " ms", Color = "warning" },
--     { Title = "Memory", Value = "26 MB", Sub = "Lua", History = { 20, 22, 26 }, Color = Color3.fromRGB(180, 140, 232) },
-- } })
-- KPI tiles: a small caps title, a big value, a muted line under it and a sparkline of its history.
-- Source = "FPS" | "Ping" | function() return number end (sampled every Interval = 0.5 s while in view; Sub shows
-- "avg ..." on its own). :Set(tile, { Value, Sub }) (tile = index or title), :Push(tile, number) adds to the line.
-- No flag (it shows numbers).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Stats = require("stats")
local Parts = require("elements/parts")

local create, label = Util.create, Util.label

return function(card, cfg)
    local window = card.window
    local list = cfg.Items or {}
    local columns = math.max(1, tonumber(cfg.Columns) or math.min(#list, 4))
    local height, gap = tonumber(cfg.Height) or 74, 6
    local holder = create("Frame", { Name = tostring(cfg.Title or "StatTiles"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Parts.gridHeight(#list, columns, gap, height)), LayoutOrder = card:_order(), Parent = card.body })
    local element = Base.element(card, "StatTiles", cfg, holder, nil, nil)
    local tiles = {}
    for index, spec in ipairs(list) do
        local position, size = Parts.cell(index, columns, gap, height)
        local box = Parts.box(holder, { Name = tostring(spec.Title or index), Position = position, Size = size })
        local title = label(box, string.upper(tostring(spec.Title or "")), 8, { Name = "Title", Position = UDim2.fromOffset(9, 6), Size = UDim2.new(1, -18, 0, 12), Font = Enum.Font.GothamMedium })
        Theme.bind(title, "TextColor3", "muted")
        local value = label(box, tostring(spec.Value or "-"), 15, { Name = "Value", Position = UDim2.fromOffset(9, 18), Size = UDim2.new(1, -18, 0, 20), Font = Enum.Font.GothamBold })
        Theme.bind(value, "TextColor3", "heading")
        local sub = label(box, tostring(spec.Sub or ""), 8, { Name = "Sub", Position = UDim2.fromOffset(9, 37), Size = UDim2.new(1, -18, 0, 11) })
        Theme.bind(sub, "TextColor3", "muted")
        local spark = create("Frame", { Name = "Line", BackgroundTransparency = 1, Position = UDim2.new(0, 8, 1, -24), Size = UDim2.new(1, -16, 0, 18), Parent = box })
        local draw = Parts.sparkline(spark, Parts.color(spec.Color, "heading"), Parts.scaleOf(window))
        local tile = { spec = spec, box = box, value = value, sub = sub, draw = draw, history = table.clone(spec.History or {}) }
        tiles[index] = tile
        tiles[tostring(spec.Title)] = tile
        task.defer(draw, tile.history)
    end
    local function find(which) return type(which) == "number" and tiles[which] or tiles[tostring(which)] end
    function element:Set(which, data)
        local tile = find(which)
        if not tile then return end
        if type(data) ~= "table" then data = { Value = data } end
        if data.Value ~= nil then tile.value.Text = tostring(data.Value) end
        if data.Sub ~= nil then tile.sub.Text = tostring(data.Sub) end
    end
    function element:Push(which, number, keep)
        local tile = find(which)
        if not tile or type(number) ~= "number" then return end
        table.insert(tile.history, number)
        while #tile.history > (keep or 30) do table.remove(tile.history, 1) end
        if Util.shown(holder) then tile.draw(tile.history) end
    end
    function element:Get(which) local tile = find(which) return tile and tile.value.Text end

    -- live tiles
    local live = {}
    for index, tile in ipairs(tiles) do if tile.spec.Source then live[#live + 1] = index end end
    if #live > 0 then
        local function sample(index)
            local spec = tiles[index].spec
            local number
            if spec.Source == "FPS" then number = Stats.fps elseif spec.Source == "Ping" then number = Stats.ping
            elseif type(spec.Source) == "function" then local ok, v = pcall(spec.Source) number = ok and tonumber(v) or nil end
            if not number then return end
            element:Push(index, number)
            local sum = 0
            for _, v in ipairs(tiles[index].history) do sum = sum + v end
            local average = sum / math.max(#tiles[index].history, 1)
            local fmt = spec.Format or function(v) return tostring(math.floor(v + 0.5)) .. (spec.Suffix or "") end
            element:Set(index, { Value = fmt(number), Sub = spec.Sub or ("avg " .. fmt(average)) })
        end
        Stats.start(window.Lib.maid)
        -- (only while the tiles are on screen: nothing runs for a closed menu or another page)
        window.maid:give(Stats.listen(function()
            if not holder.Parent or not Util.shown(holder) then return end
            for _, index in ipairs(live) do if tiles[index].spec.Source == "FPS" or tiles[index].spec.Source == "Ping" then sample(index) end end
        end))
        task.spawn(function()
            while holder.Parent and window.alive ~= false do
                for _, index in ipairs(live) do if type(tiles[index].spec.Source) == "function" and Util.shown(holder) then sample(index) end end
                task.wait(tonumber(cfg.Interval) or 0.5)
            end
        end)
    end
    return Base.finish(element, cfg)
end
end

__modules["elements/statusbars"] = function()
-- card:StatusBars({ Slots = 30, Items = {
--     { Title = "ESP", State = "on", History = { "on", "on", "off", ... } },
--     { Title = "Misc", State = "limited" },
-- } })
-- A status-page row per item: its name, its state on the right ("Running" / "Limited" / "Off" / "Error", coloured),
-- and a strip of Slots small bars, one per sample (oldest left): green on, amber limited, red error, grey off.
-- :Push(title, state) adds a sample (and sets the state), :SetState(title, state, text), :AddItem(item). No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Parts = require("elements/parts")

local create, corner, label = Util.create, Util.corner, Util.label

local WORDS = { success = "Running", warning = "Limited", danger = "Error", muted = "Off" }

return function(card, cfg)
    local slots = math.max(5, tonumber(cfg.Slots) or 30)
    local holder = create("Frame", { Name = tostring(cfg.Title or "StatusBars"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = card:_order(), Parent = card.body })
    Util.list(holder, 2)
    local element = Base.element(card, "StatusBars", { Title = cfg.Title }, holder, nil, nil)
    local rows = {}
    local function paint(row)
        local count = #row.history
        for i, bar in ipairs(row.bars) do
            local state = row.history[count - slots + i]
            local role = state ~= nil and Parts.stateRole(state) or "line"
            Theme.bind(bar, "BackgroundColor3", role == "muted" and "buttonEdge" or role)
            bar.BackgroundTransparency = state == nil and 0.4 or (i > slots - 6 and 0 or 0.3)
        end
    end
    function element:SetState(titleText, stateName, text)
        local row = rows[tostring(titleText)]
        if not row then return end
        local role = Parts.stateRole(stateName)
        row.state.Text = text and tostring(text) or WORDS[role] or tostring(stateName)
        Theme.bind(row.state, "TextColor3", role)
        row.current = stateName
    end
    function element:Push(titleText, stateName)
        local row = rows[tostring(titleText)]
        if not row then return end
        row.history[#row.history + 1] = stateName
        while #row.history > slots do table.remove(row.history, 1) end
        self:SetState(titleText, stateName)
        paint(row)
    end
    -- :AddItem({ Title, State, History }) adds a row (a module that reports later); nothing when it exists
    function element:AddItem(item)
        if rows[tostring(item.Title)] then return end
        local index = #rows + 1
        local frame = create("Frame", { Name = tostring(item.Title or index), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), LayoutOrder = index, Parent = holder })
        local title = label(frame, tostring(item.Title or ""), 10, { Name = "Title", Size = UDim2.new(1, -90, 0, 18) })
        Theme.bind(title, "TextColor3", "text")
        local state = label(frame, "", 9, { Name = "State", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(90, 18), TextXAlignment = Enum.TextXAlignment.Right })
        local strip = create("Frame", { Name = "Strip", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 12), Parent = frame })
        local bars = {}
        for i = 1, slots do
            local bar = create("Frame", { Name = "Bar", BorderSizePixel = 0, Position = UDim2.new((i - 1) / slots, (i - 1) * 2 / slots, 0, 0), Size = UDim2.new(1 / slots, -2 * (slots - 1) / slots, 1, 0), Parent = strip })
            corner(bar, 2)
            bars[i] = bar
        end
        local row = { title = title, state = state, bars = bars, history = table.clone(item.History or {}) }
        rows[tostring(item.Title)] = row
        rows[index] = row
        element:SetState(item.Title, item.State)
        paint(row)
    end
    for _, item in ipairs(cfg.Items or {}) do element:AddItem(item) end
    return Base.finish(element, cfg)
end
end

__modules["elements/stepper"] = function()
-- card:Stepper({ Title, Desc, Flag, Min = 0, Max = 10, Step = 1, Default, Suffix, Callback, Locked })
-- [-] value [+]: exact numbers without a slider. Hold a button to repeat (it speeds up); click the value to type.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local min, max = tonumber(cfg.Min) or 0, tonumber(cfg.Max) or 10
    if max < min then min, max = max, min end
    local step = tonumber(cfg.Step) or 1
    if step <= 0 then step = 1 end
    local decimals = Util.decimals(step)
    local suffix = cfg.Suffix and (" " .. tostring(cfg.Suffix)) or ""
    local row, title, desc = Base.row(card, cfg, cfg.Desc and 40 or 30, { right = 106, helpRight = 100 })
    local box = create("Frame", { Name = "Stepper", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(96, 24), BorderSizePixel = 0, Parent = row })
    Theme.bind(box, "BackgroundColor3", "input")
    corner(box, 6)
    Theme.bind(stroke(box), "Color", "buttonEdge")
    local function sideButton(name, icon, side)
        local button = create("TextButton", {
            Name = name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(side, 0.5), Position = UDim2.new(side, 0, 0.5, 0), Size = UDim2.fromOffset(24, 24), Parent = box,
        })
        Theme.bind(button, "BackgroundColor3", "hover")
        corner(button, 6)
        local image = Icons.themed(button, icon, 12, "text", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
        button.MouseEnter:Connect(function() Util.tween(button, 0.1, { BackgroundTransparency = 0 }) if image then Theme.tweenTo(image, "ImageColor3", "heading", 0.1) end end)
        button.MouseLeave:Connect(function() Util.tween(button, 0.1, { BackgroundTransparency = 1 }) if image then Theme.tweenTo(image, "ImageColor3", "text", 0.1) end end)
        return button, image
    end
    local minus = sideButton("Minus", "minus", 0)
    local plus = sideButton("Plus", "plus", 1)
    local value = create("TextBox", {
        Name = "Value", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -48, 1, 0), Text = "", TextSize = 10, Font = Enum.Font.GothamMedium, ClearTextOnFocus = false,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = box,
    })
    Theme.bind(value, "TextColor3", "heading")
    Theme.bind(value, "PlaceholderColor3", "muted")

    local element = Base.element(card, "Stepper", cfg, row, title, desc)
    local focused = false
    local function format(number)
        return (decimals > 0 and string.format("%." .. decimals .. "f", number) or tostring(math.floor(number + 0.5))) .. suffix
    end
    local function render()
        if not focused then value.Text = format(element.Value) end
        -- the ends dim their button
        minus.Active, plus.Active = element.Value > min, element.Value < max
        for _, button in ipairs({ minus, plus }) do
            local icon = button:FindFirstChildWhichIsA("ImageLabel")
            if icon then icon.ImageTransparency = button.Active and 0 or 0.6 end
        end
    end
    function element:Set(number, silent)
        number = tonumber(number)
        if not number or number ~= number then render() return end
        number = math.clamp(Util.round(number - min, step) + min, min, max)
        if decimals > 0 then number = tonumber(string.format("%." .. decimals .. "f", number)) end
        local changed = number ~= self.Value
        self.Value = number
        render()
        self:_fire(number, silent or not changed)
    end
    function element:Get() return self.Value end
    function element:SetRange(newMin, newMax)
        min, max = tonumber(newMin) or min, tonumber(newMax) or max
        self:Set(self.Value)
    end

    -- press and hold: one step, then repeats that get quicker
    local function hold(button, direction)
        local holding = 0
        button.InputBegan:Connect(function(input)
            if not Util.isPress(input) or element.Locked then return end
            holding = holding + 1
            local mine = holding
            element:Set(element.Value + step * direction)
            task.spawn(function()
                task.wait(0.4)
                local delay = 0.12
                while holding == mine and button.Parent and not element.Locked do
                    local before = element.Value
                    element:Set(element.Value + step * direction)
                    if element.Value == before then break end
                    task.wait(delay)
                    delay = math.max(0.03, delay * 0.85)
                end
            end)
        end)
        button.InputEnded:Connect(function(input) if Util.isPress(input) then holding = holding + 1 end end)
        button.MouseLeave:Connect(function() holding = holding + 1 end)
    end
    hold(minus, -1)
    hold(plus, 1)
    value.Focused:Connect(function() focused = true value.Text = format(element.Value):gsub(suffix:gsub("%p", "%%%0") .. "$", "") end)
    value.FocusLost:Connect(function()
        focused = false
        local number = tonumber((value.Text:gsub("[^%d%.%-]", "")))
        if number then element:Set(number) else render() end
        render()
    end)

    element.Value = math.clamp(tonumber(cfg.Default) or min, min, max)
    render()
    element:_fire(element.Value, true)
    return Base.finish(element, cfg)
end
end

__modules["elements/swatches"] = function()
-- card:Swatches({ Title, Desc, Flag, Items = { { "Neutral", Color3 }, { "Blue", Color3 }, ... }, Default = "Blue", Columns = 4, Callback = function(color, name) end })
-- Named colour presets as a grid (Qustah's accent picker). Value is the chosen name; Callback gets the Color3 and the name.
-- Without Colors it uses Qustah's eight accent presets.
-- Style = "Dots": one row of small round colour dots (the name shows on hover). Custom = function(open) end adds a
-- last dot for "any colour" (a script opens its own picker there); it lights up while a custom colour is chosen.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

local PRESETS = {
    { "Neutral", Color3.fromRGB(177, 178, 183) }, { "Blue", Color3.fromRGB(124, 156, 255) },
    { "Crimson", Color3.fromRGB(240, 36, 90) }, { "Violet", Color3.fromRGB(180, 140, 242) },
    { "Mint", Color3.fromRGB(61, 180, 136) }, { "Gold", Color3.fromRGB(242, 179, 61) },
}
return function(card, cfg)
    local colors = cfg.Items or PRESETS
    local dots = cfg.Style == "Dots"
    local maxColumns = math.max(1, tonumber(cfg.Columns) or 4)
    local columns = maxColumns
    local rowsCount = math.ceil(#colors / columns)
    local top = (cfg.Title and 20 or 0) + (cfg.Desc and 16 or 0) + (cfg.Title and 4 or 0)
    local holder = create("Frame", { Name = tostring(cfg.Title or "Swatches"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, top + (dots and 28 or rowsCount * 34)), LayoutOrder = card:_order(), Parent = card.body })
    local title, desc
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Size = UDim2.new(1, 0, 0, 20) })
        Theme.bind(title, "TextColor3", "text")
    end
    if cfg.Desc then
        desc = label(holder, tostring(cfg.Desc), 9, { Name = "Desc", Position = UDim2.fromOffset(0, cfg.Title and 20 or 0), Size = UDim2.new(1, 0, 0, 14) })
        Theme.bind(desc, "TextColor3", "muted")
    end
    local grid = create("Frame", { Name = "Grid", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 1, -top), Parent = holder })

    local element = Base.element(card, "Swatches", cfg, holder, title, desc)
    local entries, byName = {}, {}
    local customEntry
    local function render()
        for _, entry in ipairs(entries) do
            local on = entry.name == element.Value
            if dots then
                entry.outline.Transparency = on and 0 or 1
            else
                Theme.tweenTo(entry.button, "BackgroundColor3", on and "selected" or "card", 0.1)
                Theme.tweenTo(entry.text, "TextColor3", on and "heading" or "muted", 0.1)
                entry.outline.Transparency = on and 0.3 or 1
            end
        end
        if customEntry then
            local custom = element.Value == nil and element.Color ~= nil
            customEntry.outline.Transparency = custom and 0 or 1
            customEntry.fill.BackgroundColor3 = custom and element.Color or Color3.new(1, 1, 1)
            customEntry.fill.BackgroundTransparency = custom and 0 or 1
            if customEntry.icon then customEntry.icon.Visible = not custom end
        end
    end
    -- Dots: a round dot with a ring around the chosen one (the name as a tooltip)
    local function dot(name, color)
        local button = create("TextButton", { Name = name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundTransparency = 1, Size = UDim2.fromOffset(22, 22), Parent = grid })
        local fill = create("Frame", { Name = "Dot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(16, 16), BorderSizePixel = 0, BackgroundColor3 = color or Color3.new(1, 1, 1), Parent = button })
        corner(fill, 8)
        local ringFrame = create("Frame", { Name = "Ring", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = button })
        corner(ringFrame, 11)
        local outline = stroke(ringFrame, nil, 1, 1.5)
        Theme.bind(outline, "Color", "heading")
        Util.hoverPop(button, 1.08)
        button.MouseEnter:Connect(function() card.window:_tip(name) end)
        button.MouseLeave:Connect(function() card.window:_hideTip() end)
        return button, fill, outline
    end
    for index, item in ipairs(colors) do
        local name, color = tostring(item[1] or item.Name), item[2] or item.Color
        if dots then
            local button, fill, outline = dot(name, color)
            button.LayoutOrder = index
            local entry = { name = name, color = color, button = button, outline = outline, fill = fill }
            entries[#entries + 1] = entry
            byName[name] = entry
            button.Activated:Connect(function() if not element.Locked then element:Set(name) end end)
            continue
        end
        local button = create("TextButton", { Name = name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = index, Parent = grid })
        corner(button, 6)
        local outline = stroke(button, Color3.new(1, 1, 1), 1)
        Theme.bind(outline, "Color", "accent")
        local dot = create("Frame", { Name = "Dot", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.fromOffset(14, 14), BorderSizePixel = 0, BackgroundColor3 = color, Parent = button })
        corner(dot, 4)
        local text = label(button, name, 10, { Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -32, 1, 0) })
        local entry = { name = name, color = color, button = button, text = text, outline = outline }
        entries[#entries + 1] = entry
        byName[name] = entry
        Util.hoverPop(button, 1.04)
        button.MouseEnter:Connect(function()
            if element.Value ~= name then
                Theme.tweenTo(button, "BackgroundColor3", "input", 0.1)
                Theme.tweenTo(text, "TextColor3", "heading", 0.1)
            end
        end)
        button.MouseLeave:Connect(render)
        button.Activated:Connect(function() if not element.Locked then element:Set(name) end end)
    end

    if dots and type(cfg.Custom) == "function" then
        local button, fill, outline = dot("Custom colour", Color3.new(1, 1, 1))
        button.LayoutOrder = #entries + 1
        fill.BackgroundTransparency = 1
        local edge = stroke(fill, nil, 0, 1)
        Theme.bind(edge, "Color", "muted")
        local icon = require("icons").themed(fill, "plus", 11, "muted", { Name = "Plus", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
        customEntry = { button = button, fill = fill, outline = outline, icon = icon }
        local open = false
        button.Activated:Connect(function()
            if element.Locked then return end
            open = not open
            element:_call(cfg.Custom, open)
        end)
    end
    if dots then
        -- one row, the dots spread evenly over the width (by scale: right at any width or UI scale), gaps at most 30 px
        local all = {}
        for _, entry in ipairs(entries) do all[#all + 1] = entry.button end
        if customEntry then all[#all + 1] = customEntry.button end
        local count = #all
        create("UISizeConstraint", { MaxSize = Vector2.new(count * 22 + (count - 1) * 30, math.huge), Parent = grid })
        for index, button in ipairs(all) do
            local t = count > 1 and (index - 1) / (count - 1) or 0
            button.AnchorPoint = Vector2.new(0, 0.5)
            button.Position = UDim2.new(t, -t * 22, 0.5, 0)
        end
    end
    -- columns follow the width (about 90 px per chip, at most Columns)
    local function place()
        if dots then return end
        local width = holder.AbsoluteSize.X
        columns = width > 0 and math.clamp(math.floor((width + 6) / 90), 2, maxColumns) or maxColumns
        columns = math.min(columns, math.max(1, #entries))
        for index, entry in ipairs(entries) do
            local column, line = (index - 1) % columns, (index - 1) // columns
            entry.button.Position = UDim2.new(column / columns, column == 0 and 0 or 3, 0, line * 34)
            entry.button.Size = UDim2.new(1 / columns, -6 + (column == 0 and 3 or 0) + (column == columns - 1 and 3 or 0), 0, 28)
        end
        holder.Size = UDim2.new(1, 0, 0, top + math.ceil(#entries / columns) * 34)
    end
    holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if dots then return end
        local before = columns
        local width = holder.AbsoluteSize.X
        local want = width > 0 and math.min(math.clamp(math.floor((width + 6) / 90), 2, maxColumns), #entries) or maxColumns
        if want ~= before then place() end
    end)
    place()

    function element:Set(name, silent)
        if typeof(name) == "Color3" then -- pick the preset with this colour
            for _, entry in ipairs(entries) do if entry.color == name then name = entry.name break end end
        end
        if typeof(name) == "Color3" then -- a custom colour: no preset is selected
            self.Value, self.Color = nil, name
            render()
            return
        end
        local entry = byName[tostring(name)]
        if not entry then return end
        local changed = entry.name ~= self.Value
        self.Value = entry.name
        self.Color = entry.color
        render()
        if self.Flag then card.window.Lib.Flags[self.Flag] = entry.name card.window:_flagChanged(self.Flag) end
        if not silent and changed then
            self:_call(cfg.Callback, entry.color, entry.name)
            for _, callback in ipairs(self._changed) do self:_call(callback, entry.color, entry.name) end
        end
    end
    function element:Get() return self.Value, self.Color end
    -- recolour one preset (e.g. "Neutral" per theme pack)
    function element:SetColor(name, color)
        for _, entry in ipairs(entries) do
            if entry.name == name and typeof(color) == "Color3" then
                entry.color = color
                local dot = entry.button:FindFirstChild("Dot")
                if dot then dot.BackgroundColor3 = color end
                if self.Value == name then self.Color = color end
            end
        end
    end

    element:Set(cfg.Default or (entries[1] and entries[1].name), true)
    return Base.finish(element, cfg)
end
end

__modules["elements/switchgrid"] = function()
-- card:SwitchGrid({ Columns = 2, Items = {
--     { Title = "ESP", Icon = "eye", Flag = "esp", Default = true, Callback = function(on) end },
--     { Title = "Misc", Icon = "box", Status = "Limited" },          -- no switch: a status chip instead
-- } })
-- Boxed rows two (Columns) to a line, each with an icon, a name and its own switch. Every item with a Flag is a
-- normal toggle (saved with the profile, Lib.Flags[flag], window.flags[flag]:Set(on)). Status = "text" shows a chip
-- (coloured by StatusRole = "warning" | "success" | "danger" ...) instead of a switch. Badge = "RISKY", Risky = true,
-- Tooltip = "text" work as on a Toggle.
-- Returns the grid; grid.Items[i] / grid.Items[title] are the toggles (:Set, :Get, :Lock), grid:SetStatus(title, text, role).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")
local Parts = require("elements/parts")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local list = cfg.Items or {}
    local columns = math.max(1, tonumber(cfg.Columns) or 2)
    local height, gap = 34, 6
    local holder = create("Frame", { Name = tostring(cfg.Title or "SwitchGrid"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Parts.gridHeight(#list, columns, gap, height)), LayoutOrder = card:_order(), Parent = card.body })
    local grid = Base.element(card, "SwitchGrid", { Title = cfg.Title }, holder, nil, nil)
    grid.Items = {}
    local chips = {}
    for index, spec in ipairs(list) do
        local position, size = Parts.cell(index, columns, gap, height)
        local box = create("TextButton", { Name = tostring(spec.Title or index), Text = "", AutoButtonColor = false, BorderSizePixel = 0, Position = position, Size = size, Parent = holder })
        Theme.bind(box, "BackgroundColor3", "input")
        corner(box, 7)
        Theme.bind(Util.stroke(box, nil, 0.2), "Color", "line")
        local x = 10
        if spec.Icon then
            local icon = Icons.themed(box, spec.Icon, 13, "icon", { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0) })
            if icon then x = 30 end
        end
        local title = label(box, tostring(spec.Title or ""), 10, { Name = "Title", Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -x - 52, 1, 0) })
        Theme.bind(title, "TextColor3", spec.Risky and "danger" or "text")
        -- Badge = "RISKY": a small tag after the name (Risky = true: the name is red too)
        if spec.Badge then
            local tag = Parts.chip(box, tostring(spec.Badge), spec.Risky and "danger" or "muted", nil, { Name = "Badge", AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, x + Util.textWidth(tostring(spec.Title or ""), 10, Enum.Font.Gotham) + 6, 0.5, 0) })
            tag.Size = UDim2.fromOffset(tag.Size.X.Offset, 15)
            tag:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 4)
        end
        if spec.Tooltip then
            box.MouseEnter:Connect(function() card.window:_tip(tostring(spec.Tooltip)) end)
            box.MouseLeave:Connect(function() card.window:_hideTip() end)
        end
        if spec.Status ~= nil then
            local chip, _, resize = Parts.chip(box, tostring(spec.Status), spec.StatusRole or "warning", nil, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0) })
            chips[tostring(spec.Title)] = { chip = chip, resize = resize }
            title.Size = UDim2.new(1, -x - chip.Size.X.Offset - 14, 1, 0)
        else
            local switch = create("Frame", { Name = "Switch", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(30, 16), BorderSizePixel = 0, Parent = box })
            corner(switch, 8)
            local knob = create("Frame", { Name = "Knob", Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(12, 12), BorderSizePixel = 0, Parent = switch })
            corner(knob, 6)
            Theme.bind(knob, "BackgroundColor3", "knob")
            local item = Base.element(card, "Toggle", { Title = spec.Title, Flag = spec.Flag, Callback = spec.Callback, Reset = false }, box, title, nil)
            item.Value = spec.Default == true
            local function render(animate)
                Theme.tweenTo(switch, "BackgroundColor3", item.Value and (spec.OnRole or "success") or "buttonEdge", animate and 0.15 or nil)
                Util.tween(knob, animate and 0.15 or 0, { Position = UDim2.fromOffset(item.Value and 16 or 2, 2) })
            end
            function item:Set(on, silent)
                on = on == true
                local changed = on ~= self.Value
                self.Value = on
                render(true)
                self:_fire(on, silent or not changed)
            end
            function item:Get() return self.Value end
            box.Activated:Connect(function() if not item.Locked then item:Set(not item.Value) end end)
            render(false)
            item:_fire(item.Value, true)
            grid.Items[index] = item
            grid.Items[tostring(spec.Title)] = item
        end
        box.MouseEnter:Connect(function() Theme.tweenTo(box, "BackgroundColor3", "hover", 0.1) end)
        box.MouseLeave:Connect(function() Theme.tweenTo(box, "BackgroundColor3", "input", 0.1) end)
    end
    function grid:SetStatus(titleText, text, role)
        local entry = chips[tostring(titleText)]
        if not entry then return end
        entry.resize(text)
        local textLabel = entry.chip:FindFirstChild("Text")
        if textLabel and role then Theme.bind(textLabel, "TextColor3", role) end
    end
    function grid:Get(titleText) local item = self.Items[titleText] return item and item.Value end
    function grid:Set(titleText, on) local item = self.Items[titleText] if item then item:Set(on) end end
    return Base.finish(grid, cfg)
end
end

__modules["elements/table"] = function()
-- card:Table({
--     Title = "Players", Height = 160, Search = false, Sortable = true,
--     Columns = { "Name", { Title = "Kills", Width = 0.2, Align = "Right" }, { Title = "Team", Width = 0.25 } },
--     Items = { { "Player1", 12, "Red" }, ... },
--     RowColor = function(row, index) return row[2] > 10 and "success" or nil end, -- the first cell's theme role
--     OnRowClick = function(row, index) end,
-- })
-- A scrolling table. Click a column header to sort by it (again for the other direction); numbers sort as
-- numbers. Search = true adds a filter box. :SetItems(rows), :AddRow(row), :RemoveRow(index), :UpdateRow(index, row),
-- :Clear(), :Sort(column, descending), :GetItems(). No flag (it shows data).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

local ROW = 24

return function(card, cfg)
    -- columns: widths default to an equal share of what the sized ones leave
    local columns, fixed, open = {}, 0, 0
    for index, spec in ipairs(cfg.Columns or { "Value" }) do
        if type(spec) ~= "table" then spec = { Title = spec } end
        local width = tonumber(spec.Width)
        columns[index] = { title = tostring(spec.Title or ("Column " .. index)), width = width, align = spec.Align == "Right" and Enum.TextXAlignment.Right or (spec.Align == "Center" and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left) }
        if width then fixed = fixed + width else open = open + 1 end
    end
    for _, column in ipairs(columns) do
        if not column.width then column.width = open > 0 and math.max(0.05, (1 - fixed) / open) or 0.1 end
    end
    local height = tonumber(cfg.Height) or 160
    local top = (cfg.Title and 22 or 0) + (cfg.Search and 30 or 0)
    local holder = create("Frame", { Name = tostring(cfg.Title or "Table"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, top + height), LayoutOrder = card:_order(), Parent = card.body })
    local title
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Size = UDim2.new(1, -80, 0, 20) })
        Theme.bind(title, "TextColor3", "text")
    end
    -- the row count: right of the title; with no title inside the search box's right end; with neither, not shown
    -- (it would sit on the header row)
    local count = label(holder, "", 9, { Name = "Count", AnchorPoint = Vector2.new(1, 0), Position = cfg.Title and UDim2.new(1, 0, 0, 0) or UDim2.new(1, -8, 0, 2),
        Size = UDim2.fromOffset(80, 20), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 2, Visible = cfg.Title ~= nil or cfg.Search == true })
    Theme.bind(count, "TextColor3", "muted")
    local search
    if cfg.Search then
        search = create("TextBox", {
            Name = "Search", Position = UDim2.fromOffset(0, cfg.Title and 22 or 0), Size = UDim2.new(1, 0, 0, 24), BorderSizePixel = 0,
            Text = "", PlaceholderText = "Search...", TextSize = 10, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false, Parent = holder,
        })
        Theme.bind(search, "BackgroundColor3", "input")
        Theme.bind(search, "TextColor3", "text")
        Theme.bind(search, "PlaceholderColor3", "muted")
        corner(search, 6)
        Theme.bind(stroke(search), "Color", "buttonEdge")
        Util.padding(search, 8, cfg.Title and 8 or 70, 0, 0)
    end
    local box = create("Frame", { Name = "Box", Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, ClipsDescendants = true, Parent = holder })
    Theme.bind(box, "BackgroundColor3", "base")
    corner(box, 7)
    Theme.bind(stroke(box), "Color", "line")
    local head = create("Frame", { Name = "Head", Size = UDim2.new(1, 0, 0, ROW), BorderSizePixel = 0, Parent = box })
    Theme.bind(head, "BackgroundColor3", "input")
    local headLine = create("Frame", { Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = head })
    Theme.bind(headLine, "BackgroundColor3", "line")
    local body = create("ScrollingFrame", {
        Name = "Rows", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, ROW), Size = UDim2.new(1, 0, 1, -ROW),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = box,
    })
    Theme.bind(body, "ScrollBarImageColor3", "muted")
    Util.fadeScrollbar(body)
    Util.fitCanvas(body, Util.list(body, 0))
    local empty = label(box, cfg.Empty or "No rows", 10, { Name = "Empty", Position = UDim2.fromOffset(0, ROW), Size = UDim2.new(1, 0, 1, -ROW), TextXAlignment = Enum.TextXAlignment.Center })
    Theme.bind(empty, "TextColor3", "muted")

    local element = Base.element(card, "Table", {}, holder, title, nil)
    local rows = {}
    local sortColumn, descending = nil, false
    local headers = {}

    -- x position (scale) where each column starts
    local function starts()
        local out, x = {}, 0
        for index, column in ipairs(columns) do out[index] = x x = x + column.width end
        return out
    end
    local function cell(parent, index, text, x, bold)
        local column = columns[index]
        local object = label(parent, tostring(text == nil and "" or text), 10, {
            Name = "Cell" .. index, Position = UDim2.new(x, 8, 0, 0), Size = UDim2.new(column.width, -16, 1, 0),
            TextXAlignment = column.align, Font = bold and Enum.Font.GothamMedium or Enum.Font.Gotham,
        })
        return object
    end

    local sortable = cfg.Sortable ~= false
    for index, column in ipairs(columns) do
        local x = starts()[index]
        local button = create("TextButton", { Name = column.title, Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromScale(x, 0), Size = UDim2.new(column.width, 0, 1, 0), Parent = head })
        local text = label(button, column.title, 9, { Name = "Text", Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), TextXAlignment = column.align, Font = Enum.Font.GothamMedium })
        Theme.bind(text, "TextColor3", "muted")
        -- the sort arrow sits right next to the column name (before it in right-aligned columns)
        local nameWidth = Util.textWidth(column.title, 9, Enum.Font.GothamMedium)
        local arrowPos
        if column.align == Enum.TextXAlignment.Right then arrowPos = UDim2.new(1, -(8 + nameWidth + 2), 0.5, 0)
        elseif column.align == Enum.TextXAlignment.Center then arrowPos = UDim2.new(0.5, nameWidth / 2 + 2, 0.5, 0)
        else arrowPos = UDim2.new(0, 8 + nameWidth + 2, 0.5, 0) end
        local arrow = Icons.themed(button, "chevron-down", 10, "accent", { Name = "Arrow", AnchorPoint = Vector2.new(column.align == Enum.TextXAlignment.Right and 1 or 0, 0.5), Position = arrowPos, Visible = false })
        headers[index] = { text = text, arrow = arrow }
        if sortable then
            button.MouseEnter:Connect(function() Theme.tweenTo(text, "TextColor3", "heading", 0.1) end)
            button.MouseLeave:Connect(function() Theme.tweenTo(text, "TextColor3", sortColumn == index and "accent" or "muted", 0.1) end)
            button.Activated:Connect(function() element:Sort(index, sortColumn == index and not descending) end)
        end
    end

    local function matches(row)
        local query = search and search.Text:lower() or ""
        if query == "" then return true end
        for index = 1, #columns do
            local value = row[index]
            if value ~= nil and tostring(value):lower():find(query, 1, true) then return true end
        end
        return false
    end
    local function ordered()
        local list = {}
        for index, row in ipairs(rows) do list[#list + 1] = { row = row, index = index } end
        if sortColumn then
            table.sort(list, function(a, b)
                local x, y = a.row[sortColumn], b.row[sortColumn]
                -- empty cells always go last, whichever direction
                local emptyX, emptyY = x == nil or x == "", y == nil or y == ""
                if emptyX or emptyY then
                    if emptyX and emptyY then return a.index < b.index end
                    return emptyY
                end
                if tostring(x) == tostring(y) then return a.index < b.index end -- stable
                local nx, ny = tonumber(x), tonumber(y)
                local less
                if nx and ny then less = nx < ny
                elseif nx or ny then less = nx ~= nil -- numbers before text
                else less = tostring(x):lower() < tostring(y):lower() end
                if descending then return not less end
                return less
            end)
        end
        return list
    end
    local drawn = {}
    local function render()
        for _, object in ipairs(drawn) do object:Destroy() end
        drawn = {}
        local x = starts()
        local shown = 0
        for position, item in ipairs(ordered()) do
            if matches(item.row) then
                shown = shown + 1
                local line = create("TextButton", { Name = "Row" .. item.index, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, ROW), LayoutOrder = position, Parent = body })
                Theme.bind(line, "BackgroundColor3", "card")
                local stripe = shown % 2 == 0 and 0.4 or 1 -- every other row slightly lighter
                line.BackgroundTransparency = stripe
                for index = 1, #columns do
                    local object = cell(line, index, item.row[index], x[index], index == 1)
                    -- RowColor(row, index) -> a theme role ("danger"...) for the row's first cell
                    local role = index == 1 and cfg.RowColor and cfg.RowColor(item.row, item.index) or nil
                    Theme.bind(object, "TextColor3", role or (index == 1 and "heading" or "text"))
                end
                line.MouseEnter:Connect(function() Theme.tweenTo(line, "BackgroundColor3", "hover", 0.08) line.BackgroundTransparency = 0 end)
                line.MouseLeave:Connect(function() Theme.tweenTo(line, "BackgroundColor3", "card", 0.08) line.BackgroundTransparency = stripe end)
                if cfg.OnRowClick then
                    local rowData, rowIndex = item.row, item.index
                    line.Activated:Connect(function() element:_call(cfg.OnRowClick, rowData, rowIndex) end)
                end
                drawn[#drawn + 1] = line
            end
        end
        empty.Visible = shown == 0
        empty.Text = #rows > 0 and "No matches" or (cfg.Empty or "No rows")
        count.Text = (shown == #rows) and (#rows .. (#rows == 1 and " row" or " rows")) or (shown .. " / " .. #rows)
        for index, header in ipairs(headers) do
            local on = sortColumn == index
            Theme.bind(header.text, "TextColor3", on and "accent" or "muted")
            if header.arrow then
                header.arrow.Visible = on
                header.arrow.Rotation = descending and 0 or 180
            end
        end
    end

    -- (by column count, so a nil in the middle of a row doesn't cut it short; named fields such as row.key are
    -- kept too, for RowColor / OnRowClick)
    local function copy(row)
        local out = {}
        row = row or {}
        for index = 1, math.max(#columns, #row) do out[index] = row[index] end
        for key, value in pairs(row) do
            if type(key) ~= "number" then out[key] = value end
        end
        return out
    end
    function element:SetItems(list)
        rows = {}
        for _, row in ipairs(list or {}) do rows[#rows + 1] = copy(row) end
        render()
    end
    function element:AddRow(row) rows[#rows + 1] = copy(row) render() return #rows end
    function element:RemoveRow(index) if rows[index] then table.remove(rows, index) render() end end
    function element:UpdateRow(index, row) if rows[index] then rows[index] = copy(row) render() end end
    function element:Clear() rows = {} render() end
    function element:GetItems() return rows end
    function element:Sort(column, desc)
        if column ~= nil and not columns[column] then
            for index, item in ipairs(columns) do if item.title == column then column = index break end end
        end
        sortColumn = columns[column] and column or nil
        descending = desc == true
        render()
    end
    function element:Get() return rows end
    function element:Set(list) self:SetItems(list) end
    if search then search:GetPropertyChangedSignal("Text"):Connect(render) end

    element:SetItems(cfg.Items)
    if cfg.SortBy then element:Sort(cfg.SortBy, cfg.Descending) end
    return element
end
end

__modules["elements/textarea"] = function()
-- card:TextArea({ Title, Desc, Flag, Placeholder, Default, Height = 80, MaxLength, Callback, Locked })
-- A multi-line text box (notes, a script, a message). Callback runs when it loses focus (Finished = false: on
-- every change). With MaxLength a counter shows "12 / 200".
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

return function(card, cfg)
    local height = math.max(40, tonumber(cfg.Height) or 80)
    local maxLength = tonumber(cfg.MaxLength)
    local top = (cfg.Title and 20 or 0) + (cfg.Desc and 16 or 0) + (cfg.Title and 4 or 0)
    local holder = create("Frame", { Name = tostring(cfg.Title or "TextArea"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, top + height), LayoutOrder = card:_order(), Parent = card.body })
    local title, desc
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Size = UDim2.new(1, maxLength and -70 or 0, 0, 20) })
        Theme.bind(title, "TextColor3", cfg.Risky and "danger" or "text")
    end
    if cfg.Desc then
        desc = label(holder, tostring(cfg.Desc), 9, { Name = "Desc", Position = UDim2.fromOffset(0, cfg.Title and 20 or 0), Size = UDim2.new(1, 0, 0, 14) })
        Theme.bind(desc, "TextColor3", "muted")
    end
    local counter
    if maxLength then
        counter = label(holder, "", 9, { Name = "Counter", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(70, 20), TextXAlignment = Enum.TextXAlignment.Right })
        Theme.bind(counter, "TextColor3", "muted")
    end
    local box = create("TextBox", {
        Name = "Box", Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, Text = "",
        PlaceholderText = tostring(cfg.Placeholder or ""), TextSize = 10, Font = Enum.Font.Gotham, MultiLine = true, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ClearTextOnFocus = false, ClipsDescendants = true,
        Parent = holder,
    })
    Theme.bind(box, "BackgroundColor3", "input")
    Theme.bind(box, "TextColor3", "text")
    Theme.bind(box, "PlaceholderColor3", "muted")
    corner(box, 7)
    local outline = stroke(box)
    Theme.bind(outline, "Color", "buttonEdge")
    Util.padding(box, 10, 10, 8, 8)

    local element = Base.element(card, "TextArea", cfg, holder, title, desc)
    local function count()
        if counter then
            counter.Text = #box.Text .. " / " .. maxLength
            Theme.bind(counter, "TextColor3", #box.Text >= maxLength and "warning" or "muted")
        end
    end
    function element:Set(text, silent)
        text = tostring(text == nil and "" or text)
        if maxLength and #text > maxLength then text = text:sub(1, maxLength) end
        local changed = text ~= self.Value
        self.Value = text
        if box.Text ~= text then box.Text = text end
        count()
        self._failed = false
        self:_fire(text, silent or not changed)
        if changed and not silent then self:_accepted("success") end
    end
    function element:Get() return self.Value end
    box:GetPropertyChangedSignal("Text"):Connect(function()
        if maxLength and #box.Text > maxLength then box.Text = box.Text:sub(1, maxLength) return end
        count()
        if cfg.Finished == false then element:Set(box.Text) end
    end)
    box.Focused:Connect(function() Theme.tweenTo(outline, "Color", "accent", 0.1) end)
    box.FocusLost:Connect(function()
        Theme.tweenTo(outline, "Color", "buttonEdge", 0.1)
        element:Set(box.Text)
    end)
    element:Set(cfg.Default or "", true)
    if cfg.Locked then box.TextEditable = false end
    return Base.finish(element, cfg)
end
end

__modules["elements/themepreview"] = function()
-- card:ThemePreview({ Height = 150, Caption = function() return "Gotham · Normal · 100%" end })
-- A tiny live copy of a window: title, two little cards with a switch and a slider, drawn with the theme's own
-- colours - change the theme, accent or font and it follows at once (next to the look settings).
-- :Refresh() updates the caption. No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local holder = create("Frame", { Name = "ThemePreview", BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, tonumber(cfg.Height) or 150), LayoutOrder = card:_order(), ClipsDescendants = true, Parent = card.body })
    Theme.bind(holder, "BackgroundColor3", "base")
    corner(holder, 9)
    Theme.bind(Util.stroke(holder), "Color", "edge")
    local title = label(holder, tostring(cfg.Name or card.window.Title or "Window"), 11, { Name = "WindowTitle", Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -60, 0, 18), Font = Enum.Font.GothamBold })
    Theme.bind(title, "TextColor3", "heading")
    local tab = create("Frame", { Name = "Tab", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 22), Size = UDim2.fromOffset(34, 2), BorderSizePixel = 0, Parent = holder })
    Theme.bind(tab, "BackgroundColor3", "accent")
    local function mini(x, name, on, withSlider)
        local box = create("Frame", { Name = name, Position = UDim2.new(x, x == 0 and 10 or 4, 0, 32), Size = UDim2.new(0.5, -14, 0, 74), BorderSizePixel = 0, Parent = holder })
        Theme.bind(box, "BackgroundColor3", "card")
        corner(box, 6)
        Theme.bind(Util.stroke(box), "Color", "line")
        local heading = label(box, name, 9, { Position = UDim2.fromOffset(8, 5), Size = UDim2.new(1, -16, 0, 12), Font = Enum.Font.GothamMedium })
        Theme.bind(heading, "TextColor3", "heading")
        local row = label(box, on and "Highlight" or "Silent Aim", 8, { Position = UDim2.fromOffset(8, 24), Size = UDim2.new(1, -40, 0, 12) })
        Theme.bind(row, "TextColor3", "text")
        local switch = create("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 24), Size = UDim2.fromOffset(20, 11), BorderSizePixel = 0, Parent = box })
        corner(switch, 6)
        Theme.bind(switch, "BackgroundColor3", on and "toggleOn" or "buttonEdge")
        local knob = create("Frame", { Position = UDim2.fromOffset(on and 10 or 1, 1), Size = UDim2.fromOffset(9, 9), BorderSizePixel = 0, Parent = switch })
        corner(knob, 5)
        Theme.bind(knob, "BackgroundColor3", "knob")
        if withSlider then
            local track = create("Frame", { Position = UDim2.fromOffset(8, 52), Size = UDim2.new(1, -16, 0, 3), BorderSizePixel = 0, Parent = box })
            corner(track, 2)
            Theme.bind(track, "BackgroundColor3", "buttonEdge")
            local fill = create("Frame", { Size = UDim2.fromScale(0.6, 1), BorderSizePixel = 0, Parent = track })
            corner(fill, 2)
            Theme.bind(fill, "BackgroundColor3", "accent")
        end
    end
    mini(0, "ESP", true, true)
    mini(0.5, "Aim", false, false)
    local caption = label(holder, "", 8, { Name = "Caption", Position = UDim2.new(0, 10, 1, -18), Size = UDim2.new(1, -20, 0, 12) })
    Theme.bind(caption, "TextColor3", "muted")
    local element = Base.element(card, "ThemePreview", { Title = cfg.Title }, holder, nil, nil)
    function element:Refresh()
        local ok, text = true, cfg.Caption
        if type(cfg.Caption) == "function" then ok, text = pcall(cfg.Caption) end
        caption.Text = ok and tostring(text or "") or ""
    end
    element:Refresh()
    return Base.finish(element, cfg)
end
end

__modules["elements/tiles"] = function()
-- card:Tiles({ Columns = 4, Items = {
--     { Title = "Free mouse", Icon = "mouse-pointer", Flag = "freeMouse", Default = true },   -- a toggle tile
--     { Title = "ESP", Icon = "eye", State = "on" },                                          -- a status tile
--     { Title = "Rejoin", Icon = "rotate-ccw", Callback = function() end },                   -- a button tile
-- } })
-- Square-ish tiles: an icon, a name and a small line under it. A tile with a Flag flips on click (On / Off under the
-- name, lit while on; saved like any toggle). A tile with State is tinted by it ("on" green, "limited" amber,
-- "error" red, "off" plain) - :SetState(title, state, sub). A tile with only a Callback is a button.
-- tiles.Items[i] / [title] are the toggle tiles (:Set, :Get).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")
local Parts = require("elements/parts")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local list = cfg.Items or {}
    local columns = math.max(1, tonumber(cfg.Columns) or 4)
    local height, gap = tonumber(cfg.Height) or 58, 6
    local holder = create("Frame", { Name = tostring(cfg.Title or "Tiles"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Parts.gridHeight(#list, columns, gap, height)), LayoutOrder = card:_order(), Parent = card.body })
    local element = Base.element(card, "Tiles", { Title = cfg.Title }, holder, nil, nil)
    element.Items = {}
    local states = {}
    local centered = cfg.Align == "Center"
    for index, spec in ipairs(list) do
        local position, size = Parts.cell(index, columns, gap, height)
        local box = create("TextButton", { Name = tostring(spec.Title or index), Text = "", AutoButtonColor = false, BorderSizePixel = 0, Position = position, Size = size, Parent = holder })
        corner(box, 9)
        local edge = Util.stroke(box, nil, 0.1)
        local icon = spec.Icon and Icons.themed(box, spec.Icon, 15, "muted", { Name = "Icon", AnchorPoint = Vector2.new(centered and 0.5 or 0, 0), Position = centered and UDim2.new(0.5, 0, 0, 10) or UDim2.fromOffset(9, 9) })
        local title = label(box, tostring(spec.Title or ""), 10, { Name = "Title", Position = UDim2.new(0, 9, 1, -28), Size = UDim2.new(1, -18, 0, 13), TextXAlignment = centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left })
        local sub = label(box, tostring(spec.Sub or ""), 8, { Name = "Sub", Position = UDim2.new(0, 9, 1, -15), Size = UDim2.new(1, -18, 0, 11), TextXAlignment = centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left })
        Theme.bind(sub, "TextColor3", "muted")
        local function paint(lit, role)
            -- lit: a light tile; role: a state colour for the icon / outline
            Theme.tweenTo(box, "BackgroundColor3", lit and "selected" or "input", 0.12)
            Theme.tweenTo(edge, "Color", role and role ~= "muted" and role or (lit and "buttonEdge" or "line"), 0.12)
            edge.Transparency = role and role ~= "muted" and 0.45 or 0.1
            if icon then Theme.tweenTo(icon, "ImageColor3", role and role ~= "muted" and role or (lit and "heading" or "muted"), 0.12) end
            Theme.tweenTo(title, "TextColor3", lit and "heading" or "text", 0.12)
        end
        if spec.Flag ~= nil or spec.Default ~= nil and spec.State == nil then
            local item = Base.element(card, "Toggle", { Title = spec.Title, Flag = spec.Flag, Callback = spec.Callback, Reset = false }, box, title, nil)
            item.Value = spec.Default == true
            local function render()
                paint(item.Value, nil)
                if spec.Sub == nil then sub.Text = item.Value and "On" or "Off" end
            end
            function item:Set(on, silent)
                on = on == true
                local changed = on ~= self.Value
                self.Value = on
                render()
                self:_fire(on, silent or not changed)
            end
            function item:Get() return self.Value end
            box.Activated:Connect(function() if not item.Locked then item:Set(not item.Value) end end)
            render()
            item:_fire(item.Value, true)
            element.Items[index] = item
            element.Items[tostring(spec.Title)] = item
        elseif spec.State ~= nil then
            local function set(state, subText)
                local role = Parts.stateRole(state)
                paint(role ~= "muted", role)
                if subText ~= nil then sub.Text = tostring(subText) end
            end
            states[tostring(spec.Title)] = set
            set(spec.State, spec.Sub)
            if spec.Callback then box.Activated:Connect(function() card.window:_safe(tostring(spec.Title), spec.Callback) end) end
        else
            paint(false, nil)
            box.Activated:Connect(function() if spec.Callback then card.window:_safe(tostring(spec.Title), spec.Callback) end end)
            box.MouseEnter:Connect(function() Theme.tweenTo(box, "BackgroundColor3", "hover", 0.1) end)
            box.MouseLeave:Connect(function() Theme.tweenTo(box, "BackgroundColor3", "input", 0.1) end)
        end
        Util.hoverPop(box, 1.02)
    end
    function element:SetState(titleText, state, subText)
        local set = states[tostring(titleText)]
        if set then set(state, subText) end
    end
    return Base.finish(element, cfg)
end
end

__modules["elements/timeline"] = function()
-- card:Timeline({ Max = 50, Height = 220, Compact = false, Filters = { "All", "Modules", "Combat" } })
-- An activity feed, newest on top. timeline:Add({ Title = "Click TP", Desc = "212 studs", Icon = "navigation",
-- Kind = "success" | "warning" | "danger" | nil, Tag = "Combat", Time = "19:21" (now when left out) }).
-- Full: a round icon per event joined by a line, the description under the title, the time on the right.
-- Compact = true: one line per event - time, a coloured dot, the text. Filters: a row of chips that show only events
-- with that Tag ("All" shows everything). :Clear(), :GetEvents(). No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")
local Parts = require("elements/parts")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local compact = cfg.Compact == true
    local max = math.max(1, tonumber(cfg.Max) or 50)
    local height = tonumber(cfg.Height) or (compact and 130 or 220)
    local top = cfg.Filters and 28 or 0
    local holder = create("Frame", { Name = tostring(cfg.Title or "Timeline"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height + top), LayoutOrder = card:_order(), Parent = card.body })
    local scroller = create("ScrollingFrame", {
        Name = "Events", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 1, -top),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, Parent = holder,
    })
    Theme.bind(scroller, "ScrollBarImageColor3", "buttonEdge")
    Util.list(scroller, compact and 0 or 2)
    local element = Base.element(card, "Timeline", { Title = cfg.Title }, holder, nil, nil)
    local events, filter, order = {}, "All", 0
    local empty = label(scroller, tostring(cfg.Empty or "Nothing yet"), 10, { Name = "Empty", Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 1e9 })
    Theme.bind(empty, "TextColor3", "muted")

    local function refresh()
        local shown = 0
        for index, event in ipairs(events) do
            local visible = filter == "All" or event.data.Tag == filter
            event.row.Visible = visible
            if visible then shown = shown + 1 end
            if event.line then event.line.Visible = index < #events end
        end
        empty.Visible = shown == 0
    end
    if cfg.Filters then
        local chips = {}
        local x = 0
        for _, name in ipairs(cfg.Filters) do
            local width = Util.textWidth(name, 9, Enum.Font.GothamMedium) + 18
            local button = create("TextButton", { Name = name, Text = name, AutoButtonColor = false, BorderSizePixel = 0, Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(width, 20), TextSize = 9, Font = Enum.Font.GothamMedium, Parent = holder })
            corner(button, 10)
            chips[name] = button
            x = x + width + 4
            button.Activated:Connect(function()
                filter = name
                for other, chip in pairs(chips) do
                    Theme.tweenTo(chip, "BackgroundColor3", other == filter and "selected" or "input", 0.1)
                    Theme.tweenTo(chip, "TextColor3", other == filter and "heading" or "muted", 0.1)
                end
                refresh()
            end)
            Theme.bind(button, "BackgroundColor3", name == filter and "selected" or "input")
            Theme.bind(button, "TextColor3", name == filter and "heading" or "muted")
        end
    end

    function element:Add(data)
        if type(data) ~= "table" then data = { Title = tostring(data) } end
        data.Time = data.Time or os.date("%H:%M")
        order = order - 1
        local role = data.Kind and Parts.stateRole(data.Kind) or nil
        local row
        if compact then
            row = create("Frame", { Name = "Event", BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, 18), LayoutOrder = order, Parent = scroller })
            local time = label(row, tostring(data.Time), 9, { Name = "Time", Size = UDim2.fromOffset(40, 18), Font = Enum.Font.Code })
            Theme.bind(time, "TextColor3", "muted")
            Parts.dot(row, role or "muted", 6, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 44, 0.5, 0) })
            local text = label(row, tostring(data.Title) .. (data.Desc and (" · " .. tostring(data.Desc)) or ""), 10, { Name = "Text", Position = UDim2.fromOffset(56, 0), Size = UDim2.new(1, -56, 1, 0) })
            Theme.bind(text, "TextColor3", "text")
        else
            local h = data.Desc and 38 or 30
            row = create("Frame", { Name = "Event", BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, h), LayoutOrder = order, Parent = scroller })
            local bubble = create("Frame", { Name = "Bubble", Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(0, 3), BorderSizePixel = 0, ZIndex = 2, Parent = row })
            corner(bubble, 12)
            Theme.bind(bubble, "BackgroundColor3", "input")
            Theme.bind(Util.stroke(bubble, nil, 0.2), "Color", "buttonEdge")
            local icon = Icons.themed(bubble, data.Icon or "circle", 11, role or "icon", { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 2 })
            if not icon then Parts.dot(bubble, role or "muted", 6, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 2 }) end
            local line = create("Frame", { Name = "Line", Position = UDim2.fromOffset(12, 27), Size = UDim2.new(0, 1, 1, -22), BorderSizePixel = 0, Parent = row })
            Theme.bind(line, "BackgroundColor3", "line")
            local title = label(row, tostring(data.Title), 11, { Name = "Title", Position = UDim2.fromOffset(34, 4), Size = UDim2.new(1, -90, 0, 14) })
            Theme.bind(title, "TextColor3", "heading")
            if data.Desc then
                local desc = label(row, tostring(data.Desc), 9, { Name = "Desc", Position = UDim2.fromOffset(34, 19), Size = UDim2.new(1, -90, 0, 12) })
                Theme.bind(desc, "TextColor3", "muted")
            end
            local time = label(row, tostring(data.Time), 9, { Name = "Time", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, 4), Size = UDim2.fromOffset(52, 14), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.Code })
            Theme.bind(time, "TextColor3", "muted")
            -- (the line joins this event to the older one below it)
            table.insert(events, 1, { data = data, row = row, line = line })
        end
        if compact then table.insert(events, 1, { data = data, row = row }) end
        while #events > max do local old = table.remove(events) old.row:Destroy() end
        refresh()
        return row
    end
    function element:Clear()
        for _, event in ipairs(events) do event.row:Destroy() end
        table.clear(events)
        refresh()
    end
    function element:GetEvents()
        local out = {}
        for _, event in ipairs(events) do out[#out + 1] = event.data end
        return out
    end
    for _, data in ipairs(cfg.Events or {}) do element:Add(data) end
    refresh()
    return Base.finish(element, cfg)
end
end

__modules["elements/toggle"] = function()
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
end

__modules["elements/viewport"] = function()
-- card:Viewport({ Object = workspace.Model | BasePart, Height = 170, Interactive = true, Spin = false, Distance, Lower = 0 })
-- A 3D preview of a clone of the object (an avatar, a weapon...). Drag to turn it, wheel to zoom (the page doesn't
-- scroll while the pointer is over it). The clone has no scripts and no Animator (nothing plays on it).
-- :SetObject(obj) swaps the model; :SetSpin(true) turns it slowly. element.Model is the clone on show,
-- element.Camera / element.View its camera and ViewportFrame.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

return function(card, cfg)
    local window = card.window
    local height = tonumber(cfg.Height) or 170
    local holder = create("Frame", { Name = tostring(cfg.Name or "Viewport"), Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, LayoutOrder = card:_order(), Parent = card.body })
    Theme.bind(holder, "BackgroundColor3", "base")
    corner(holder, 8)
    Theme.bind(stroke(holder), "Color", "line")
    local view = create("ViewportFrame", {
        Name = "View", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(150, 150, 155),
        LightColor = Color3.fromRGB(255, 255, 255), LightDirection = Vector3.new(-1, -1, -0.6), Parent = holder,
    })
    corner(view, 8)
    local camera = Instance.new("Camera")
    camera.FieldOfView = 40
    camera.Parent = view
    view.CurrentCamera = camera
    local world = Instance.new("WorldModel")
    world.Parent = view
    local empty = label(holder, "No object", 10, { Name = "Empty", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })
    Theme.bind(empty, "TextColor3", "muted")

    local element = Base.element(card, "Viewport", {}, holder, nil, nil)
    element.Camera, element.View = camera, view -- (to project points of the model onto the frame)
    local center, radius = Vector3.zero, 5
    local yaw, pitch, zoom = math.rad(25), math.rad(-12), 1
    local spin = cfg.Spin == true
    local function place()
        local distance = (tonumber(cfg.Distance) or radius / math.tan(math.rad(camera.FieldOfView / 2)) * 1.15) * zoom
        local rotation = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
        -- (Lower: the model sits that share of its size under the middle, room for what is drawn over it)
        local aim = center + (rotation * Vector3.new(0, 1, 0)) * radius * (tonumber(cfg.Lower) or 0)
        camera.CFrame = CFrame.new(aim) * rotation * CFrame.new(0, 0, distance)
        camera.Focus = CFrame.new(aim)
    end
    function element:SetObject(object)
        world:ClearAllChildren()
        self.Value, self.Model = object, nil
        empty.Visible = object == nil
        if not object then return end
        local ok, copy = pcall(function()
            local archivable = object.Archivable
            object.Archivable = true
            local clone = object:Clone()
            object.Archivable = archivable
            return clone
        end)
        if not ok or not copy then empty.Text = "Cannot preview" empty.Visible = true return end
        -- scripts out, physics off
        for _, d in ipairs(copy:GetDescendants()) do
            -- (an Animator left in the clone can play the character's animations on it: a dash pose stuck in the preview)
            if d:IsA("LuaSourceContainer") or d:IsA("Animator") then d:Destroy() elseif d:IsA("BasePart") then d.Anchored = true end
        end
        if copy:IsA("BasePart") then copy.Anchored = true end
        copy.Parent = world
        self.Model = copy -- (the clone being shown: a script can recolour it)
        local okBox, cf, size = pcall(function()
            if copy:IsA("Model") then return copy:GetBoundingBox() end
            return copy.CFrame, copy.Size
        end)
        if okBox then center, radius = cf.Position, math.max(size.Magnitude / 2, 0.5) end
        place()
    end
    -- turning: a per-frame step only while Spin is on (and nothing done while the preview is out of sight)
    local spinConnection
    function element:SetSpin(on)
        spin = on == true
        if spin and not spinConnection then
            spinConnection = window.maid:connect(Util.Services.RunService.Heartbeat, function(dt)
                if not holder.Parent then spinConnection:Disconnect() spinConnection = nil return end
                if holder.AbsoluteSize.X > 0 and Util.shown(holder) then yaw = yaw + (dt or 0.016) * 0.6 place() end
            end)
        elseif not spin and spinConnection then
            spinConnection:Disconnect() spinConnection = nil
        end
    end

    if cfg.Interactive ~= false then
        local hit = create("TextButton", { Name = "Drag", Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = holder })
        hit.InputBegan:Connect(function(input)
            if not Util.isPress(input) then return end
            local last = Util.pointer(input)
            window:_beginDrag(input, function(point)
                local delta = point - last
                last = point
                yaw = yaw - delta.X * 0.012
                pitch = math.clamp(pitch - delta.Y * 0.01, -1.3, 1.3)
                place()
            end)
        end)
        -- (the wheel zooms here: the page's own scrolling waits while the pointer is over the preview)
        local scroller
        hit.MouseEnter:Connect(function()
            local node = holder.Parent
            while node and not node:IsA("ScrollingFrame") do node = node.Parent end
            if node and node.ScrollingEnabled ~= false then scroller = node node.ScrollingEnabled = false end
        end)
        hit.MouseLeave:Connect(function()
            if scroller then scroller.ScrollingEnabled = true scroller = nil end
        end)
        hit.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseWheel then
                zoom = math.clamp(zoom * (input.Position.Z > 0 and 0.9 or 1.1), 0.4, 3)
                place()
            end
        end)
    end
    element:SetSpin(spin)
    element:SetObject(cfg.Object)
    return element
end
end

__modules["font"] = function()
-- UI font. Every text object in a registered ScreenGui gets the chosen family; its weight (regular / medium /
-- semibold / bold) is kept. UIFont.set("Quicksand"), UIFont.register(gui, maid).
-- Gotham is Roblox's built-in default; every other font comes from Roblox's own font library (Creator Marketplace)
-- by asset id, like WindUI does: nothing to download, they work in every executor.
local UIFont = { current = "Gotham", guis = {} }

UIFont.order = {
    "Gotham", "Montserrat", "Ubuntu", "Work Sans", "Josefin Sans", "Builder Mono", "Arcade", "Michroma",
    "Quicksand", "Fuzzy Bubbles", "Silkscreen", "Sono Mono",
}
-- Roblox's own fonts by their Enum.Font name, and families that are only a file in Roblox's font folder
UIFont.Enums = { ["Josefin Sans"] = "JosefinSans", Montserrat = "Montserrat", Ubuntu = "Ubuntu", Arcade = "Arcade", Michroma = "Michroma" }
UIFont.Files = { ["Builder Mono"] = "rbxasset://fonts/families/BuilderMono.json" }
-- How big a font draws next to Gotham at the same size: its text is sized by 1 / this, so a wide font (Michroma)
-- doesn't push labels out of their rows and a small one (Arcade's pixels) stays readable. Code text has its own font.
UIFont.Fit = { Michroma = 1.12, ["Builder Mono"] = 1.08, Arcade = 0.9, ["Josefin Sans"] = 0.96 }
-- The code fonts the settings offer (Code, Console, Log)
UIFont.codeFonts = { "Sono Mono", "Builder Mono" }
UIFont.Library = {
    ["Work Sans"] = 12187373327, Quicksand = 12187371324, ["Fuzzy Bubbles"] = 11322590111, Silkscreen = 12187371840,
    ["Sono Mono"] = 12187362578,
}
-- Code text (Code, Console, Log; marked with the QCode attribute) has its own monospace font, Sono Mono unless
-- CreateWindow({ CodeFont = "Silkscreen" }) asks for another. Text marked QFixedFont keeps whatever font it has
-- (the font list draws each name in its own font).
UIFont.code = "Sono Mono"
-- Text size (Settings > Interface > Text size): every text's own size times this, rounded.
UIFont.textScale = 1

-- the fonts this executor can show (all of them: nothing is downloaded)
function UIFont.available() return table.clone(UIFont.order) end

local function isText(object)
    return object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")
end

local function familyOf(name)
    name = tostring(name)
    if UIFont.Library[name] then return "rbxassetid://" .. UIFont.Library[name] end
    if UIFont.Files[name] then return UIFont.Files[name] end
    local enumName = UIFont.Enums[name] or name
    local ok, face = pcall(function() return Font.fromEnum(Enum.Font[enumName]) end)
    return ok and face and face.Family or nil
end

-- the family an icon name's text should use: the font list's own faces stay, code text gets the code font
local function targetFor(object, uiTarget)
    if object:GetAttribute("QFixedFont") then return nil end
    if object:GetAttribute("QCode") then return familyOf(UIFont.code) end
    return uiTarget
end

-- Small print (9 px and under: badges, tags, captions) and text sized to a fixed box (QNoScale: rolling digits,
-- range values) keep their size; everything else grows or shrinks with the setting.
local function scaleText(object)
    if object:GetAttribute("QNoScale") then return end
    local fit = object:GetAttribute("QCode") and 1 or (UIFont.Fit[UIFont.current] or 1)
    if object:GetAttribute("QFixedFont") then fit = 1 end
    local base = object:GetAttribute("QBaseSize")
    if base == nil then
        if (UIFont.textScale == 1 and fit == 1) or object.TextSize <= 9 then return end
        base = object.TextSize
        object:SetAttribute("QBaseSize", base)
    end
    local size = math.max(6, math.floor(base * UIFont.textScale / fit + 0.5))
    if object.TextSize ~= size then object.TextSize = size end
end

local function apply(object, uiTarget)
    if not isText(object) then return end
    pcall(scaleText, object)
    local target = targetFor(object, uiTarget)
    if not target then return end
    pcall(function()
        local face = object.FontFace
        if not face then object.FontFace = Font.new(target) return end
        if face.Family ~= target then object.FontFace = Font.new(target, face.Weight, face.Style) end
    end)
end

-- the family behind a font name (a library id or a built-in Enum.Font)
function UIFont.family(name) return familyOf(name) end

-- Re-applies the current font to every registered gui (Gotham puts the library's own font back).
function UIFont.refresh()
    local target = familyOf(UIFont.current)
    for gui in pairs(UIFont.guis) do
        if gui.Parent then
            for _, object in ipairs(gui:GetDescendants()) do apply(object, target) end
        else
            UIFont.guis[gui] = nil
        end
    end
end

function UIFont.set(name)
    name = tostring(name or "Gotham")
    if not table.find(UIFont.order, name) or not familyOf(name) then return false end
    UIFont.current = name
    UIFont.refresh()
    return true
end

-- The code font (a library font; Sono Mono unless CreateWindow({ CodeFont = "..." }) picks another).
function UIFont.setCode(name)
    name = tostring(name or "Sono Mono")
    if not table.find(UIFont.order, name) or not familyOf(name) then return false end
    UIFont.code = name
    UIFont.refresh()
    return true
end

-- Text size: 0.9 small, 1 normal, 1.1 large (every text's own size times this).
function UIFont.setTextScale(scale)
    UIFont.textScale = math.clamp(tonumber(scale) or 1, 0.7, 1.4)
    UIFont.refresh()
end

function UIFont.register(gui, maid)
    if UIFont.guis[gui] then return end
    UIFont.guis[gui] = true
    local connection = gui.DescendantAdded:Connect(function(object)
        if not isText(object) then return end
        -- deferred: creators may still set FontFace (e.g. SemiBold) or the QCode / QFixedFont marks right after parenting
        task.defer(function()
            if not object.Parent then return end
            if UIFont.current == "Gotham" and UIFont.textScale == 1 and not object:GetAttribute("QCode") then return end
            apply(object, UIFont.current ~= "Gotham" and familyOf(UIFont.current) or nil)
        end)
    end)
    if maid then maid:give(connection) end
    task.defer(UIFont.refresh)
end

return UIFont
end

__modules["gate"] = function()
-- Key system: a key screen before the window opens.
--   Lib:CreateWindow({ ..., KeySystem = {
--       Keys = { "QUSTAH-1234" },                      -- accepted keys, or:
--       Check = function(key) return ok, message end,  -- your own check (may call a web API)
--       Url = "https://discord.gg/yourserver",         -- "Get key" copies this
--       Title = "Qustāh", Subtitle = "Enter your key to continue", Note = "Keys reset every 24 hours",
--       Remember = true,                               -- save the key in <Folder>/key.txt (checked again next time)
--   } })
-- CreateWindow waits until a key is accepted. Closing the key screen stops the script (OnCancel runs first).
-- Lib:ForgetKey(folder) deletes the saved key.
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")
local UIFont = require("font")

local create, corner, stroke, label, tween = Util.create, Util.corner, Util.stroke, Util.label, Util.tween

local Gate = {}

local function trim(text) return (tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

-- ok, message
local function check(spec, key)
    key = trim(key)
    if key == "" then return false, "Enter a key" end
    if type(spec.Check) == "function" then
        local ran, ok, message = pcall(spec.Check, key)
        if not ran then return false, "The key could not be checked" end
        return ok == true, message
    end
    for _, valid in ipairs(spec.Keys or {}) do
        if key == trim(valid) then return true end
    end
    return false, "Wrong key"
end
Gate.check = check

function Gate.file(folder) return folder .. "/key.txt" end

-- Blocks until a key is accepted (true) or the screen is closed (false).
function Gate.run(Lib, cfg)
    local spec = cfg.KeySystem
    -- (the same folder name Config uses)
    local folder = trim((tostring(cfg.Folder or cfg.Title or "QustahUI"):gsub("[^%w_%- ]", "")))
    if folder == "" then folder = "QustahUI" end
    local file = Gate.file(folder)
    -- a remembered key that still passes skips the screen
    if spec.Remember ~= false and type(isfile) == "function" and type(readfile) == "function" and isfile(file) then
        local ok, saved = pcall(readfile, file)
        if ok and check(spec, saved) then return true end
    end

    -- a re-run while the key screen is open replaces it (the old one counts as closed)
    local genv = (getgenv and getgenv()) or _G
    if genv.__QustahKeyGate then pcall(genv.__QustahKeyGate) end
    local gui = Util.screenGui("QustahUI_Key", 70)
    UIFont.register(gui, Lib.maid)
    local shade = create("Frame", { Name = "Shade", Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Parent = gui })
    local panel = create("Frame", {
        Name = "KeySystem", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(340, 232),
        BorderSizePixel = 0, Parent = gui,
    })
    Theme.bind(panel, "BackgroundColor3", "base")
    corner(panel, 12)
    Theme.bind(stroke(panel), "Color", "edge")
    local scale = create("UIScale", { Scale = 0.96, Parent = panel })

    -- header: icon tile, title, subtitle, close
    local tile = create("Frame", { Name = "IconTile", Position = UDim2.fromOffset(20, 20), Size = UDim2.fromOffset(36, 36), BorderSizePixel = 0, Parent = panel })
    Theme.bind(tile, "BackgroundColor3", "accentDeep")
    corner(tile, 10)
    Theme.bind(stroke(tile, nil, 0.6), "Color", "accent")
    Icons.themed(tile, spec.Icon or "key-round", 17, "accent", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
    local title = label(panel, tostring(spec.Title or cfg.Title or "Key system"), 15, { Name = "Title", Position = UDim2.fromOffset(68, 19), Size = UDim2.new(1, -110, 0, 20), Font = Enum.Font.GothamBold })
    Theme.bind(title, "TextColor3", "heading")
    local subtitle = label(panel, tostring(spec.Subtitle or "Enter your key to continue"), 10, { Name = "Subtitle", Position = UDim2.fromOffset(68, 39), Size = UDim2.new(1, -110, 0, 16) })
    Theme.bind(subtitle, "TextColor3", "muted")
    local close = create("TextButton", { Name = "Close", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14), Size = UDim2.fromOffset(26, 26), Parent = panel })
    corner(close, 6)
    Theme.bind(close, "BackgroundColor3", "input")
    Icons.themed(close, "x", 14, "muted", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })

    -- key box + check button
    local field = create("Frame", { Name = "Field", Position = UDim2.fromOffset(20, 74), Size = UDim2.new(1, -40, 0, 34), BorderSizePixel = 0, Parent = panel })
    Theme.bind(field, "BackgroundColor3", "input")
    corner(field, 8)
    local fieldEdge = stroke(field)
    Theme.bind(fieldEdge, "Color", "buttonEdge")
    local box = create("TextBox", {
        Name = "Box", BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -96, 1, 0), Text = "",
        PlaceholderText = "Paste your key", TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false, Parent = field,
    })
    Theme.bind(box, "TextColor3", "heading")
    Theme.bind(box, "PlaceholderColor3", "muted")
    local submit = create("TextButton", {
        Name = "Check", Text = "Check", TextSize = 10, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(76, 26), Parent = field,
    })
    corner(submit, 6)
    Theme.bind(submit, "BackgroundColor3", "accentDeep")
    Theme.bind(submit, "TextColor3", "accent")
    local submitEdge = stroke(submit, nil, 0.45)
    Theme.bind(submitEdge, "Color", "accent")
    local status = label(panel, "", 10, { Name = "Status", Position = UDim2.fromOffset(20, 112), Size = UDim2.new(1, -40, 0, 16) })
    Theme.bind(status, "TextColor3", "muted")
    local note = label(panel, tostring(spec.Note or ""), 9, {
        Name = "Note", Position = UDim2.fromOffset(20, 132), Size = UDim2.new(1, -40, 0, 30), TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top,
    })
    Theme.bind(note, "TextColor3", "muted")

    -- footer: get key
    local line = create("Frame", { Position = UDim2.new(0, 0, 1, -54), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = panel })
    Theme.bind(line, "BackgroundColor3", "line")
    local getKey = create("TextButton", {
        Name = "GetKey", Text = "", AutoButtonColor = false, BorderSizePixel = 0, Position = UDim2.new(0, 20, 1, -42), Size = UDim2.new(1, -40, 0, 30),
        Visible = spec.Url ~= nil, Parent = panel,
    })
    corner(getKey, 7)
    Theme.bind(getKey, "BackgroundColor3", "input")
    Theme.bind(stroke(getKey), "Color", "buttonEdge")
    local getRow = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = getKey })
    Util.list(getRow, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
    Icons.themed(getRow, "link", 12, "text", { LayoutOrder = 1 })
    local getText = label(getRow, "Get key", 10, { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30), Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2 })
    Theme.bind(getText, "TextColor3", "text")
    if not spec.Url then panel.Size = UDim2.fromOffset(340, 178) line.Visible = false end

    tween(shade, 0.2, { BackgroundTransparency = 0.45 })
    Util.fadeTree(panel, 0.2, 0, true)
    tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)

    local result, busy = nil, false
    local function say(text, role)
        status.Text = tostring(text or "")
        Theme.bind(status, "TextColor3", role or "muted")
    end
    local function attempt()
        if busy or result ~= nil then return end
        busy = true
        submit.Text = "..."
        local key = trim(box.Text)
        local ok, message = check(spec, key)
        busy = false
        submit.Text = "Check"
        if ok then
            say(message or "Key accepted", "success")
            Theme.bind(fieldEdge, "Color", "success")
            if spec.Remember ~= false and type(writefile) == "function" then
                pcall(function() if type(isfolder) == "function" and not isfolder(folder) then makefolder(folder) end end)
                Util.writeAtomic(file, key)
            end
            result = true
        else
            say(message or "Wrong key", "danger")
            Theme.bind(fieldEdge, "Color", "danger")
            -- small shake
            local x = panel.Position
            task.spawn(function()
                for _, dx in ipairs({ -6, 6, -4, 4, 0 }) do
                    panel.Position = x + UDim2.fromOffset(dx, 0)
                    task.wait(0.03)
                end
            end)
        end
    end
    submit.Activated:Connect(attempt)
    box.FocusLost:Connect(function(enter) if enter then attempt() end end)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        if result == nil and status.Text ~= "" then say("") Theme.bind(fieldEdge, "Color", "buttonEdge") end
    end)
    getKey.Activated:Connect(function()
        local clipboard = setclipboard or toclipboard
        local ok = type(clipboard) == "function" and pcall(clipboard, tostring(spec.Url))
        say(ok and "Link copied - open it in your browser" or tostring(spec.Url), ok and "accent" or "muted")
    end)
    close.Activated:Connect(function() result = false end)
    local function replaced() if result == nil then result = false end end
    genv.__QustahKeyGate = replaced

    while result == nil and gui.Parent do task.wait(0.05) end
    if result == nil then result = false end
    if genv.__QustahKeyGate == replaced then genv.__QustahKeyGate = nil end
    tween(shade, 0.18, { BackgroundTransparency = 1 })
    Util.fadeTree(panel, 0.18, 1)
    task.delay(0.2, function() gui:Destroy() end)
    if result == false then Util.safe(spec.OnCancel) end
    return result
end

function Gate.forget(folder)
    local file = Gate.file(tostring(folder or "QustahUI"):gsub("[^%w_%- ]", ""))
    if type(isfile) == "function" and type(delfile) == "function" and isfile(file) then pcall(delfile, file) end
end

return Gate
end

__modules["glow"] = function()
-- Text glow: a light band slides across a label every few seconds, with a soft outline (Qustah's text glow).
-- Glow.add(label, { Base = "accent", Shine = "heading", Period = 3.2, Phase = 0 }) - colours are theme roles.
-- Glow.setEnabled(false) turns every glow off (plain text colour again).
local Util = require("util")
local Theme = require("theme")

local Glow = { enabled = true, items = {}, started = false }

local WHITE = Color3.new(1, 1, 1)

local function colors(fx)
    local base = Theme.get(fx.base)
    local shine = fx.shine and Theme.get(fx.shine) or base:Lerp(WHITE, 0.6)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, base), ColorSequenceKeypoint.new(0.36, base), ColorSequenceKeypoint.new(0.5, shine),
        ColorSequenceKeypoint.new(0.64, base), ColorSequenceKeypoint.new(1, base),
    }), base
end

local function apply(fx)
    local sequence, base = colors(fx)
    fx.gradient.Color = sequence
    fx.outline.Color = base
    fx.gradient.Enabled, fx.outline.Enabled = Glow.enabled, Glow.enabled
    -- with the glow on, the label is white and the gradient carries the colour
    Theme.bind(fx.label, "TextColor3", Glow.enabled and WHITE or fx.base)
end

-- The label must already be parented; it keeps its own theme role as Base.
function Glow.add(label, opts)
    opts = opts or {}
    local fx = {
        label = label, base = opts.Base or "text", shine = opts.Shine, period = opts.Period or 3.2, phase = opts.Phase or 0,
        gradient = Util.create("UIGradient", { Name = "Shine", Offset = Vector2.new(-1.2, 0), Parent = label }),
        outline = Util.create("UIStroke", {
            Name = "Glow", ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Round,
            Thickness = 1, Transparency = opts.GlowTransparency or 0.88, Parent = label,
        }),
    }
    Glow.items[#Glow.items + 1] = fx
    apply(fx)
    return fx
end

function Glow.setEnabled(enabled)
    Glow.enabled = enabled ~= false
    for _, fx in ipairs(Glow.items) do if fx.label.Parent then apply(fx) end end
end

local visible = Util.shown

-- One RenderStepped loop for all glows, connected only while a glowing label is on screen and glow is on: a slow
-- check (twice a second) connects / disconnects it, so a closed menu (and no overlay title showing) costs nothing.
function Glow.start(maid)
    if Glow.started then return end
    Glow.started = true
    local connection
    local function step()
        local now = os.clock()
        for _, fx in ipairs(Glow.items) do
            if fx.label.Parent and visible(fx.label) then
                local p = ((now / fx.period) + fx.phase) % 1
                fx.gradient.Offset = Vector2.new(p < 0.6 and (-1.2 + (p / 0.6) * 2.4) or 1.2, 0)
            end
        end
    end
    local function anyShown()
        local shown = false
        for index = #Glow.items, 1, -1 do
            local fx = Glow.items[index]
            if not fx.label.Parent then table.remove(Glow.items, index)
            elseif not shown and visible(fx.label) then shown = true end
        end
        return shown
    end
    task.spawn(function()
        while Glow.started do
            local want = Glow.enabled and anyShown()
            if want and not connection then
                connection = Util.Services.RunService.RenderStepped:Connect(step)
            elseif not want and connection then
                connection:Disconnect()
                connection = nil
            end
            Glow.running = connection ~= nil
            task.wait(0.5)
        end
    end)
    maid:give(function()
        Glow.started = false
        if connection then connection:Disconnect() connection = nil end
        Glow.running = false
    end)
end
Theme.onChange(function() for _, fx in ipairs(Glow.items) do if fx.label.Parent then apply(fx) end end end)

return Glow
end

__modules["haptics"] = function()
-- Haptics: a short buzz on phones / controllers for presses and notifications (Roblox HapticEffect).
--   Lib.Haptics.Enabled (default: on for touch screens), Lib.Haptics.Play("click" | "notify")
-- Silent on devices / clients without HapticEffect.
local Util = require("util")

local Haptics = { Enabled = Util.isTouch() }

local TYPES
local function types()
    if TYPES ~= nil then return TYPES end
    TYPES = false
    pcall(function()
        Instance.new("HapticEffect"):Destroy() -- (older clients don't have the class)
        TYPES = { click = Enum.HapticEffectType.UIHover, notify = Enum.HapticEffectType.UIClick }
    end)
    return TYPES
end

local pool = {}
local last = 0
function Haptics.Play(kind)
    if not Haptics.Enabled then return end
    local list = types()
    local hapticType = list and list[kind or "click"]
    if not hapticType then return end
    local now = os.clock()
    if now - last < 0.04 then return end -- a dragged slider would buzz non-stop
    last = now
    pcall(function()
        local effect = pool[kind]
        if not (effect and effect.Parent) then
            effect = Instance.new("HapticEffect")
            effect.Type = hapticType
            effect.Parent = Util.guiParent()
            pool[kind] = effect
        end
        effect:Play()
    end)
end

function Haptics.Clear()
    for kind, effect in pairs(pool) do pcall(effect.Destroy, effect) pool[kind] = nil end
end

return Haptics
end

__modules["hud"] = function()
-- On-screen overlays outside the menu (they stay while the menu is hidden):
--   Window:KeybindList(true / false)   draggable list of bound keys; toggles that are on are bright
--   Window:SessionBar(true / false)    "60 FPS · 40 ms · 2/50 · 00:12:03" at the top of the screen
--   Window:StatsMonitor("Header" | "Floating" | "Off")   FPS / ping in the header or in a small draggable graph
-- Positions of the draggable panels are remembered with the window (see Window memory).
local Util = require("util")
local Theme = require("theme")
local Stats = require("stats")
local Glow = require("glow")
local Icons = require("icons")

local Services = Util.Services
local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

return function(Window)
    -- A small draggable panel in the window's ScreenGui, kept on screen; position saved as a 0-1 fraction.
    function Window:_floating(name, width, height, default)
        local panel = create("Frame", {
            Name = name, Size = UDim2.fromOffset(width, height), BorderSizePixel = 0, BackgroundTransparency = 0.04,
            Visible = false, ZIndex = 70, Parent = self.gui,
        })
        Theme.bind(panel, "BackgroundColor3", "base")
        corner(panel, 8)
        Theme.bind(stroke(panel, nil, 0.4), "Color", "line")
        local handle = create("TextButton", { Name = "Handle", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), ZIndex = 71, Parent = panel })
        local saved = self.memory and self.memory.hud and self.memory.hud[name]
        local fraction = saved and Vector2.new(tonumber(saved[1]) or default.X, tonumber(saved[2]) or default.Y) or default
        local function place()
            local viewport = Util.viewport()
            local room = Vector2.new(math.max(0, viewport.X - panel.AbsoluteSize.X), math.max(0, viewport.Y - panel.AbsoluteSize.Y))
            panel.Position = UDim2.fromOffset(math.floor(fraction.X * room.X), math.floor(fraction.Y * room.Y))
        end
        handle.InputBegan:Connect(function(input)
            if not Util.isPress(input) then return end
            local start, origin = Util.pointer(input), Vector2.new(panel.Position.X.Offset, panel.Position.Y.Offset)
            self:_beginDrag(input, function(point)
                local viewport = Util.viewport()
                local room = Vector2.new(math.max(1, viewport.X - panel.AbsoluteSize.X), math.max(1, viewport.Y - panel.AbsoluteSize.Y))
                local target = origin + (point - start)
                fraction = Vector2.new(math.clamp(target.X / room.X, 0, 1), math.clamp(target.Y / room.Y, 0, 1))
                place()
            end, function()
                self.memory.hud = self.memory.hud or {}
                self.memory.hud[name] = { fraction.X, fraction.Y }
                self:_saveMemory()
            end)
        end)
        self.maid:connect(panel:GetPropertyChangedSignal("AbsoluteSize"), place)
        self._placers = self._placers or {}
        table.insert(self._placers, place)
        place()
        return panel, handle
    end

    ------------------------------------------------------------------ keybind list
    local function chordText(element)
        if element.Chord then
            local mod, key = element.Chord[1], element.Chord[2]
            return (mod and (Util.keyName(mod) .. " + ") or "") .. Util.keyName(key)
        end
        if element.Type == "Toggle" then return Util.keyName(element.BindKey) end
        return Util.keyName(element.Value or element.BindKey)
    end
    -- Window:KeybindList(true)  click a row = press it (toggles flip, keybinds fire); "-" folds the list;
    -- the eye button switches to edit mode where rows can be hidden (remembered with the window).
    function Window:KeybindList(visible)
        visible = visible ~= false
        if not self._keybindHud then
            local panel, handle = self:_floating("Keybinds", 210, 60, Vector2.new(0.02, 0.18))
            local caption = label(handle, "Keybinds", 10, { Position = UDim2.fromOffset(12, 3), Size = UDim2.new(1, -70, 1, -3), ZIndex = 72 })
            Theme.bind(caption, "TextColor3", "muted")
            self.memory.hud = self.memory.hud or {}
            local hidden = self.memory.hud.keybindsHidden or {}
            local folded = self.memory.hud.keybindsFolded == true
            local editing = false
            local refresh
            local function headerButton(name, x, icon)
                local button = create("TextButton", { Name = name, Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, x, 0, 5), Size = UDim2.fromOffset(20, 20), ZIndex = 74, Parent = handle })
                local image = Icons.themed(button, icon, 12, "muted", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 75 })
                button.MouseEnter:Connect(function() if image then Theme.tweenTo(image, "ImageColor3", "heading", 0.1) end end)
                button.MouseLeave:Connect(function() if image then Theme.tweenTo(image, "ImageColor3", editing and name == "Edit" and "accent" or "muted", 0.1) end end)
                return button, image
            end
            local foldButton, foldIcon = headerButton("Fold", -8, folded and "chevron-down" or "chevron-up")
            local editButton, editIcon = headerButton("Edit", -30, "eye")
            local function remember()
                self.memory.hud.keybindsHidden, self.memory.hud.keybindsFolded = hidden, folded
                self:_saveMemory()
            end
            foldButton.Activated:Connect(function()
                folded = not folded
                if foldIcon then Icons.Apply(foldIcon, folded and "chevron-down" or "chevron-up") end
                remember()
                refresh()
            end)
            editButton.Activated:Connect(function()
                editing = not editing
                if editIcon then Theme.tweenTo(editIcon, "ImageColor3", editing and "accent" or "muted", 0.1) end
                caption.Text = editing and "Click to hide / show" or "Keybinds"
                refresh()
            end)

            local list = create("Frame", { Name = "List", BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 30), Size = UDim2.new(1, -16, 1, -36), ZIndex = 71, Parent = panel })
            Util.list(list, 2)
            local rows = {}
            local function row(index)
                if rows[index] then return rows[index] end
                local holder = create("TextButton", { Name = "Row", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = index, ZIndex = 72, Parent = list })
                Theme.bind(holder, "BackgroundColor3", "hover")
                corner(holder, 5)
                local name = label(holder, "", 10, { Position = UDim2.fromOffset(4, 0), Size = UDim2.new(1, -80, 1, 0), ZIndex = 73 })
                local key = label(holder, "", 9, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 0), Size = UDim2.new(0, 72, 1, 0), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium, ZIndex = 73 })
                Theme.bind(key, "TextColor3", "muted")
                local r = { holder = holder, name = name, key = key }
                holder.MouseEnter:Connect(function() holder.BackgroundTransparency = 0.4 end)
                holder.MouseLeave:Connect(function() holder.BackgroundTransparency = 1 end)
                holder.Activated:Connect(function()
                    local entry = r.entry
                    if not entry then return end
                    if editing then
                        if not entry.menu then hidden[entry.title] = not hidden[entry.title] or nil remember() end
                    elseif entry.element and entry.element._onBind then
                        local element = entry.element
                        -- a hold bind clicked here works like a switch (there is no key to let go of)
                        if element.BindMode == "Hold" and element.Set then
                            element:Set(not element.Value)
                        else
                            self:_safe(entry.title, element._onBind, element)
                            if element.Mode == "Hold" and element._onRelease then task.delay(0.15, function() self:_safe(entry.title, element._onRelease, element) end) end
                        end
                    end
                    refresh()
                end)
                rows[index] = r
                return r
            end
            function refresh()
                local entries = { { title = "Menu", key = Util.keyName(self.key), on = true, menu = true } }
                for element, bound in pairs(self.binds) do
                    -- the settings menu-key row is the "Menu" entry already
                    if bound and element.Row and element.Row.Parent and element.Title and element.Flag ~= "__ui_menu_key" then
                        local title = tostring(element.Title)
                        if editing or not hidden[title] then
                            local on = element.Type == "Toggle" and element.Value == true or element.Type ~= "Toggle"
                            entries[#entries + 1] = { title = title, key = chordText(element), on = on, element = element, hidden = hidden[title] }
                        end
                    end
                end
                table.sort(entries, function(a, b)
                    if a.menu ~= b.menu then return a.menu == true end
                    if a.on ~= b.on then return a.on end
                    return a.title < b.title
                end)
                local shown = folded and 0 or #entries
                for index = 1, shown do
                    local entry = entries[index]
                    local r = row(index)
                    r.entry = entry
                    r.holder.Visible = true
                    r.name.Text, r.key.Text = (entry.hidden and "· " or "") .. entry.title, "[" .. entry.key .. "]"
                    Theme.bind(r.name, "TextColor3", entry.hidden and "muted" or (entry.on and "heading" or "muted"))
                    r.name.TextTransparency = entry.hidden and 0.4 or 0
                end
                for index = shown + 1, #rows do rows[index].holder.Visible = false rows[index].entry = nil end
                list.Visible = not folded
                panel.Size = UDim2.fromOffset(210, folded and 30 or (36 + shown * 22))
            end
            self._keybindHud = { panel = panel, refresh = refresh }
            task.spawn(function()
                while self.alive do
                    if panel.Visible then refresh() end
                    task.wait(0.5)
                end
            end)
        end
        self._keybindHud.panel.Visible = visible
        if visible then self._keybindHud.refresh() end
    end

    ------------------------------------------------------------------ session bar
    function Window:SessionBar(visible)
        visible = visible ~= false
        if not self._sessionBar then
            Stats.start(self.Lib.maid)
            local started = os.clock()
            local bar = create("Frame", {
                Name = "SessionBar", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 20), Size = UDim2.fromOffset(300, 30),
                BorderSizePixel = 0, BackgroundTransparency = 0.04, Visible = false, ZIndex = 70, Parent = self.gui,
            })
            Theme.bind(bar, "BackgroundColor3", "base")
            corner(bar, 8)
            Theme.bind(stroke(bar, nil, 0.4), "Color", "line")
            local text = label(bar, "", 10, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 71 })
            Theme.bind(text, "TextColor3", "text")
            local Players = Services.Players
            local function refresh()
                text.Text = string.format("%d FPS  ·  %d ms  ·  %d/%d  ·  %s", Stats.fps, Stats.ping, #Players:GetPlayers(), Players.MaxPlayers, Util.clock(os.clock() - started))
            end
            self.maid:give(Stats.listen(function() if bar.Visible then refresh() end end))
            self._sessionBar = { bar = bar, refresh = refresh }
            -- top centre; on a narrow screen where the watermark / keybind list sit there too, bottom centre instead
            local function place()
                local viewport = Util.viewport()
                local barLeft, barRight = viewport.X / 2 - 150, viewport.X / 2 + 150
                local crowded = false
                for _, name in ipairs({ "Watermark", "Keybinds", "Performance" }) do
                    local panel = self.gui:FindFirstChild(name)
                    if panel and panel:IsA("GuiObject") and panel.Visible then
                        local at = Util.screenPos(panel)
                        local left, right = at.X, at.X + panel.AbsoluteSize.X
                        if right > barLeft and left < barRight and at.Y < 20 + 30 + 8 then crowded = true end
                    end
                end
                if crowded then
                    bar.AnchorPoint, bar.Position = Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -14)
                else
                    bar.AnchorPoint, bar.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 20)
                end
            end
            self._sessionBar.place = place
            self._placers = self._placers or {}
            table.insert(self._placers, place)
        end
        self._sessionBar.bar.Visible = visible
        if visible then self._sessionBar.refresh() self._sessionBar.place() end
    end

    ------------------------------------------------------------------ stats monitor
    function Window:StatsMonitor(mode)
        mode = mode == true and "Header" or (mode == false and "Off" or tostring(mode or "Header"))
        Stats.start(self.Lib.maid)
        if not self._monitor then
            local header = label(self.main, "", 10, {
                Name = "HeaderStats", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(170, 20),
                TextXAlignment = Enum.TextXAlignment.Center, RichText = true, Visible = false,
            })
            Theme.bind(header, "TextColor3", "muted")
            local panel, handle = self:_floating("Performance", 190, 96, Vector2.new(0.98, 0.04))
            local caption = label(handle, "Performance", 10, { Position = UDim2.fromOffset(12, 3), Size = UDim2.new(0.5, 0, 1, -3), ZIndex = 72 })
            Theme.bind(caption, "TextColor3", "muted")
            local values = label(handle, "", 10, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 3), Size = UDim2.new(0.6, 0, 1, -3), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium, ZIndex = 72 })
            Theme.bind(values, "TextColor3", "text")
            local graph = create("Frame", { Name = "Graph", BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 32), Size = UDim2.new(1, -24, 1, -42), ZIndex = 71, Parent = panel })
            local bars = {}
            for index = 1, 30 do
                local bar = create("Frame", {
                    AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((index - 1) / 30, 0, 1, 0), Size = UDim2.new(1 / 30, -1, 0, 1),
                    BorderSizePixel = 0, BackgroundTransparency = 0.25, ZIndex = 72, Parent = graph,
                })
                Theme.bind(bar, "BackgroundColor3", "accent")
                bars[index] = bar
            end
            local function refresh()
                local text = string.format("FPS %d  ·  PING %d ms", Stats.fps, Stats.ping)
                header.Text, values.Text = text, string.format("%d FPS · %d ms", Stats.fps, Stats.ping)
                if panel.Visible then
                    local history = Stats.history.fps
                    local top = 60
                    for _, value in ipairs(history) do top = math.max(top, value) end
                    for index = 1, 30 do
                        local value = history[#history - 30 + index]
                        bars[index].Size = UDim2.new(1 / 30, -1, value and math.clamp(value / top, 0.03, 1) or 0, value and 0 or 1)
                    end
                end
            end
            self.maid:give(Stats.listen(function() if header.Visible or panel.Visible then refresh() end end))
            self._monitor = { header = header, panel = panel, refresh = refresh }
        end
        self.monitorMode = mode
        self._monitor.header.Visible = mode == "Header"
        self._monitor.panel.Visible = mode == "Floating"
        self._monitor.refresh()
        self:_updateLocation()
    end

    ------------------------------------------------------------------ watermark
    -- Window:Watermark(true, { Text = "custom" })  "Qustāh  V1.00 | 60 FPS | 40 ms | 21:03", draggable
    function Window:Watermark(visible, cfg)
        visible = visible ~= false
        cfg = cfg or {}
        if not self._watermark then
            Stats.start(self.Lib.maid)
            local panel, handle = self:_floating("Watermark", 240, 28, Vector2.new(0.01, 0.01))
            local accent = create("Frame", { Name = "Bar", Position = UDim2.fromOffset(0, 6), Size = UDim2.new(0, 2, 1, -12), BorderSizePixel = 0, ZIndex = 72, Parent = panel })
            Theme.bind(accent, "BackgroundColor3", "accent")
            corner(accent, 1)
            local title = label(handle, self.Title, 11, { Name = "Title", Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, TextTruncate = Enum.TextTruncate.None, ZIndex = 72 })
            pcall(function() title.FontFace = Font.new(Font.fromEnum(Enum.Font.Gotham).Family, Enum.FontWeight.SemiBold) end)
            Theme.bind(title, "TextColor3", "accent")
            Glow.add(title, { Base = "accent", Period = 3.6, Phase = 0.3, GlowTransparency = 0.82 })
            local info = label(handle, "", 10, { Name = "Info", Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0, 200, 1, 0), TextTruncate = Enum.TextTruncate.None, ZIndex = 72 })
            Theme.bind(info, "TextColor3", "text")
            local extra = nil
            local function refresh()
                local parts = {}
                if self.Version ~= "" then parts[#parts + 1] = self.Version end
                if extra and extra ~= "" then parts[#parts + 1] = extra end
                parts[#parts + 1] = Stats.fps .. " FPS"
                parts[#parts + 1] = Stats.ping .. " ms"
                parts[#parts + 1] = os.date("%H:%M")
                info.Text = table.concat(parts, "  |  ")
                local titleWidth = Util.textWidth(self.Title, 11, Enum.Font.GothamMedium) + 4
                local infoWidth = Util.textWidth(info.Text, 10, Enum.Font.Gotham) + 6
                info.Position = UDim2.fromOffset(12 + titleWidth + 10, 0)
                info.Size = UDim2.new(0, infoWidth, 1, 0)
                panel.Size = UDim2.fromOffset(12 + titleWidth + 10 + infoWidth + 12, 28)
            end
            self.maid:give(Stats.listen(function() if panel.Visible then refresh() end end))
            self._watermark = { panel = panel, refresh = refresh, setExtra = function(text) extra = text end }
        end
        if cfg.Text ~= nil then self._watermark.setExtra(tostring(cfg.Text)) end
        self._watermark.panel.Visible = visible
        if visible then self._watermark.refresh() end
        if not self._watermark.watched then
            self._watermark.watched = true
            self.maid:connect(self._watermark.panel:GetPropertyChangedSignal("Position"), function() if self._sessionBar then self._sessionBar.place() end end)
        end
        if self._sessionBar then self._sessionBar.place() end
    end
end
end

__modules["icons"] = function()
-- Icons: names instead of asset ids, anywhere the library takes an Icon.
--   Icon = "house"                  default set (lucide, built in - 1700+ icons)
--   Icon = "solar:home-bold"        another set: lucide, solar, sfsymbols, gravity, geist, craft
--   Icon = "rbxassetid://123" / 123 a plain image
-- Sets other than lucide download once on first use (from this repo's icons/ folder; Footagesus/Icons, MIT).
--   Lib.Icons.Get(name)             -> { Image, RectSize, RectOffset, Parts } or nil
--   Lib.Icons.Apply(imageLabel, name) -> true when the icon was found
--   Lib.Icons.Image(name, { Size, Color }) -> ImageLabel
--   Lib.Icons.SetDefault("solar"), Lib.Icons.Add("mine", { ["skull"] = "rbxassetid://..." }), Lib.Icons.List(set)
local Icons = {
    Default = "lucide",
    Source = "https://raw.githubusercontent.com/79650/gwanjkcdsjawbdnjascdas-ui-lib/refs/heads/main/qustah-ui-lib/icons/",
    Remote = { solar = true, sfsymbols = true, gravity = true, geist = true, craft = true },
    Sets = {},
    _failed = {},
}

local Theme = require("theme")
local Util = require("util")

-- lucide is embedded as name, asset number pairs (in the order the sharp sheets use)
local lucideOrder = {}
do
    local list, set = require("icons_lucide"), {}
    for i = 1, #list, 2 do
        set[list[i]] = list[i + 1]
        lucideOrder[#lucideOrder + 1] = list[i]
    end
    Icons.Sets.lucide = set
end

local ZERO = Vector2.new(0, 0)

-- Downloads a set (once). Returns true or false, reason.
function Icons.Load(set)
    if Icons.Sets[set] then return true end
    if not Icons.Remote[set] then return false, "unknown icon set " .. tostring(set) end
    if Icons._failed[set] then return false, Icons._failed[set] end
    local ok, data = pcall(function()
        local source = game:HttpGet(Icons.Source .. set .. ".lua")
        return loadstring(source)()
    end)
    if not ok or type(data) ~= "table" then
        Icons._failed[set] = tostring(data)
        require("util").log("[qustah-ui-lib] icon set " .. set .. " could not be loaded: " .. tostring(data))
        return false, Icons._failed[set]
    end
    Icons.Sets[set] = data
    return true
end

local function asset(value)
    if type(value) == "number" then return "rbxassetid://" .. value end
    return tostring(value)
end

local function lookup(set, name)
    local data = Icons.Sets[set]
    if not data then return nil end
    -- spritesheet sets: { Spritesheets = { ["1"] = id }, Icons = { name = { Image = 1, ImageRectPosition, ImageRectSize, Parts } } }
    if type(data.Icons) == "table" and type(data.Spritesheets) == "table" then
        local icon = data.Icons[name]
        if not icon then return nil end
        local parts
        for _, part in ipairs(icon.Parts or {}) do
            parts = parts or {}
            parts[#parts + 1] = lookup(set, part)
        end
        return {
            Image = asset(data.Spritesheets[tostring(icon.Image)] or icon.Image),
            RectSize = icon.ImageRectSize or ZERO, RectOffset = icon.ImageRectPosition or ZERO, Parts = parts,
        }
    end
    local value = data[name]
    if value == nil then return nil end
    return { Image = asset(value), RectSize = ZERO, RectOffset = ZERO }
end

function Icons.Get(name)
    if name == nil or name == "" then return nil end
    if type(name) == "number" or (type(name) == "string" and name:match("^%d+$")) then
        return { Image = "rbxassetid://" .. tostring(name), RectSize = ZERO, RectOffset = ZERO }
    end
    name = tostring(name)
    if name:match("^https?://") and not name:find("roblox%.com") then
        -- a picture on the web (logo...): downloaded once, shown through getcustomasset; not tinted
        return { Image = Icons._urls[name] or "", RectSize = ZERO, RectOffset = ZERO, Url = name }
    end
    if name:match("^rbxasset") or name:match("^https?://") then
        return { Image = name, RectSize = ZERO, RectOffset = ZERO }
    end
    local set, icon = name:match("^([%w_%-]+):(.+)$")
    if not set then set, icon = Icons.Default, name end
    set = set:lower()
    if not Icons.Sets[set] then Icons.Load(set) end
    return lookup(set, icon) or (set ~= "lucide" and not name:find(":") and lookup("lucide", icon)) or nil
end

-- Web images: request + writefile + getcustomasset (cached per url for the session and on disk).
Icons._urls = {}
Icons.Folder = "QustahUI/assets"
local function fetch(url, done)
    if Icons._urls[url] then return done(Icons._urls[url]) end
    local name = (url:match("([^/?#]+)[?#]?[^/]*$") or "image"):gsub("%.[^%.]+$", ""):gsub("[^%w%-_]", "_"):sub(1, 32)
    local path = Icons.Folder .. "/" .. name .. "-" .. Util.hash(url) .. ".png"
    Util.cacheFiles({ { path = path, url = url } }, function(ids)
        Icons._urls[url] = ids[path]
        done(ids[path])
    end, function(reason)
        Util.log("[qustah-ui-lib] image " .. url .. " could not be loaded: " .. tostring(reason))
    end)
end

-- Sharp lucide icons. Roblox shrinks a big image badly (it skips pixels, so a 256 px icon drawn at 14 px looks
-- jagged), so lucide icons come from small sheets drawn at 16 and 32 px (icons/atlas, tools/gen_atlas.py): the
-- 16 px sheet for icons up to 16 px on screen, the 32 px sheet above. The sheets are downloaded once into
-- QustahUI/icons and shown through getcustomasset; without it (or before they are ready) the asset ids are used.
-- Lib.Icons.Sharp = false before the first window turns this off.
Icons.Sharp = true
Icons.AtlasFolder = "QustahUI/icons"
local Atlas = require("icons_atlas")
local atlas = { started = false, ready = false, index = nil, pages = {} }
local sharpImages = setmetatable({}, { __mode = "k" }) -- image -> lucide name, so they switch sheets / get re-drawn
local applySharp
local queueSnap

-- name -> place in the sheets: lucide's order without the names lucide no longer has
local function atlasIndex()
    if not atlas.index then
        local missing = {}
        for name in string.gmatch(Atlas.Missing or "", "[^,]+") do missing[name] = true end
        atlas.index = {}
        local i = 0
        for _, name in ipairs(lucideOrder) do
            if not missing[name] then i = i + 1 atlas.index[name] = i end
        end
    end
    return atlas.index
end

-- the place of icon number `index` for an icon `pixels` tall on screen: image, offset, size
local function atlasRect(index, pixels)
    local size = pixels <= 16 and 16 or 32
    local sheet = Atlas.Sheets[size]
    local page = math.floor((index - 1) / sheet.PerPage) + 1
    local k = (index - 1) % sheet.PerPage
    local pitch = size + 2
    local image = atlas.pages[Atlas.Pages[size][page]]
    if not image then return nil end
    return image, Vector2.new((k % sheet.Columns) * pitch + 1, math.floor(k / sheet.Columns) * pitch + 1), Vector2.new(size, size)
end

-- The sheets' files in AtlasFolder (as <prefix><file>), downloaded once; done(ids by file name).
local function isPng(body) return body:sub(2, 4) == "PNG" end
local function loadFiles(prefix, source, files, done)
    local list = {}
    for _, file in ipairs(files) do
        list[#list + 1] = { path = Icons.AtlasFolder .. "/" .. prefix .. file, url = source .. file, check = isPng, name = file }
    end
    Util.cacheFiles(list, function(ids)
        local byName = {}
        for _, file in ipairs(list) do byName[file.name] = ids[file.path] end
        done(byName)
    end, function(reason)
        if Util.canCustomAsset() then Util.log("[qustah-ui-lib] sharp icons could not be loaded (" .. tostring(reason) .. "); using the plain ones") end
    end, "icons")
end

local function redrawSharp()
    for image, name in pairs(sharpImages) do if name and image.Parent then pcall(applySharp, image, name) end end
end

local function startAtlas()
    if atlas.started then return end
    atlas.started = true
    if Icons.Sharp == false then return end
    local files = {}
    for _, list in pairs(Atlas.Pages) do for _, file in ipairs(list) do files[#files + 1] = file end end
    loadFiles("v" .. Atlas.Version .. "-", Icons.Source .. "atlas/", files, function(ids)
        atlas.pages = ids
        atlas.ready = true
        redrawSharp()
    end)
end

-- A script's own sheet (tools/gen_sheet.py): its icons drawn at every on-screen size, used before the lucide
-- sheets whenever an icon's size is in it. Lib.Icons.UseSheet(manifest, "https://.../folder/") before the window.
local customSheets = {}
function Icons.UseSheet(manifest, source)
    if type(manifest) ~= "table" or type(source) ~= "string" then return end
    local sheet = { manifest = manifest, index = {}, ready = false, ids = {} }
    local i = 0
    for name in string.gmatch(manifest.Names or "", "[^,]+") do i = i + 1 sheet.index[name] = i end
    customSheets[#customSheets + 1] = sheet
    if Icons.Sharp == false then return end
    loadFiles(tostring(manifest.Id) .. "-v" .. tostring(manifest.Version) .. "-", source, manifest.Files or {}, function(ids)
        sheet.ids = ids
        sheet.ready = true
        redrawSharp()
    end)
end

-- Starts the download of the sharp lucide sheets now (they otherwise start with the first icon drawn), so a
-- script can wait for them with Lib.Loader.Wait before its window opens.
function Icons.Preload() startAtlas() end

-- the exact cell for an icon `pixels` tall, from a script sheet: image, offset, size
local function sheetRect(name, pixels)
    local size = math.floor(pixels + 0.5)
    for _, sheet in ipairs(customSheets) do
        local index = sheet.ready and sheet.index[name]
        local place = index and sheet.manifest.Sizes[size]
        if place then
            local page, y0, cols = place[1], place[2], place[3]
            local pitch = size + 2
            local image = sheet.ids[sheet.manifest.Files[page]]
            if image then
                return image, Vector2.new(((index - 1) % cols) * pitch + 1, y0 + math.floor((index - 1) / cols) * pitch + 1), Vector2.new(size, size)
            end
        end
    end
end

-- (tests) start over: forget the loaded sheets
function Icons._resetAtlas() atlas.started, atlas.ready, atlas.pages = false, false, {} table.clear(customSheets) end
Icons._atlas = atlas

-- the lucide name behind an icon name ("eye", "lucide:eye"), when the sheets have it
local function lucideName(name)
    if type(name) ~= "string" then return nil end
    local set, icon = name:match("^([%w_%-]+):(.+)$")
    if set then if set:lower() ~= "lucide" then return nil end name = icon
    elseif Icons.Default ~= "lucide" then return nil end
    if atlasIndex()[name] then return name end
    for _, sheet in ipairs(customSheets) do if sheet.index[name] then return name end end
    return nil
end

local function pixelsOf(image)
    local size = image.AbsoluteSize
    if size and size.Y > 0 then return math.max(size.X, size.Y) end
    return math.max(image.Size.X.Offset, image.Size.Y.Offset)
end

-- A square icon sized in pixels lands on whole screen pixels: at a UI scale like 110 % a 14 px icon would be 15.4
-- px and Roblox would stretch the 15 px cell over it (a slight blur). Its size becomes round(14 * 1.1) / 1.1 (the
-- original size is kept in the QIconSize attribute, so a later scale starts from it again).
local function snapToPixels(image)
    local size = image.Size
    if size.X.Scale ~= 0 or size.Y.Scale ~= 0 then return end
    local base = image:GetAttribute("QIconSize") or size.X.Offset
    if base <= 0 or size.X.Offset ~= size.Y.Offset then return end
    local absolute = image.AbsoluteSize
    if not absolute or absolute.X <= 0 then return end
    local scale = absolute.X / size.X.Offset
    if scale <= 0 or math.abs(scale - 1) < 0.001 then
        if image:GetAttribute("QIconSize") and size.X.Offset ~= base then image.Size = UDim2.fromOffset(base, base) end
        return
    end
    local snapped = math.max(1, math.floor(base * scale + 0.5)) / scale
    if math.abs(snapped - size.X.Offset) > 0.001 then
        image:SetAttribute("QIconSize", base)
        image.Size = UDim2.fromOffset(snapped, snapped)
    end
end

-- A pixel-exact icon between two pixels is blurred again (an 11 px icon centred in a 16 px box sits at 2.5): it is
-- moved by under half a pixel onto whole pixels. An icon its parent lays out (a list: a button's icon and text)
-- can't move itself, so that parent moves instead, when nothing lays the parent out. The original position stays
-- in QIconX / QIconY; a position someone else sets later becomes the new one.
local function laidOut(object)
    local parent = object.Parent
    return parent == nil or parent:FindFirstChildWhichIsA("UIGridStyleLayout") ~= nil
end
local function snapPosition(image)
    if Icons.SnapPosition == false then return end
    local target = image
    if laidOut(image) then
        target = image.Parent
        if not (target and target:IsA("GuiObject")) or target:IsA("ScrollingFrame") or laidOut(target) then return end
    end
    local position = target.Position
    local mine = target:GetAttribute("QIconSet")
    local baseX, baseY = target:GetAttribute("QIconX"), target:GetAttribute("QIconY")
    if baseX == nil or (mine and (math.abs(position.X.Offset - mine.X) > 0.001 or math.abs(position.Y.Offset - mine.Y) > 0.001)) then
        baseX, baseY = position.X.Offset, position.Y.Offset -- (first time, or moved by someone else)
    end
    local absolute, size = image.AbsolutePosition, image.AbsoluteSize
    if not absolute or not size or size.X <= 0 or image.Size.X.Offset <= 0 then return end
    local scale = size.X / image.Size.X.Offset
    -- (where the icon would be with the target at its own position, then how far that is from whole pixels)
    local atX = absolute.X + (baseX - position.X.Offset) * scale
    local atY = absolute.Y + (baseY - position.Y.Offset) * scale
    local dx, dy = math.floor(atX + 0.5) - atX, math.floor(atY + 0.5) - atY
    local x, y = baseX + dx / scale, baseY + dy / scale
    target:SetAttribute("QIconX", baseX)
    target:SetAttribute("QIconY", baseY)
    target:SetAttribute("QIconSet", Vector2.new(x, y))
    if math.abs(x - position.X.Offset) > 0.001 or math.abs(y - position.Y.Offset) > 0.001 then
        target.Position = UDim2.new(position.X.Scale, x, position.Y.Scale, y)
    end
end

-- (gathered and done once a frame: a card that opens resizes many boxes, each icon is placed once; an icon that
-- will not settle - something keeps resizing its box - is left alone after a few tries a second)
local queued, queueRunning = {}, false
local tries = setmetatable({}, { __mode = "k" })
queueSnap = function(image)
    local now = os.clock()
    local t = tries[image]
    if not t or now - t.since > 1 then t = { since = now, count = 0 } tries[image] = t end
    if t.count >= 6 then return end
    t.count = t.count + 1
    queued[image] = true
    if queueRunning then return end
    queueRunning = true
    task.defer(function()
        queueRunning = false
        local list = queued
        queued = {}
        for icon in pairs(list) do if icon.Parent then pcall(snapPosition, icon) end end
    end)
end

applySharp = function(image, name)
    pcall(snapToPixels, image)
    pcall(snapPosition, image)
    local pixels = pixelsOf(image)
    local picture, offset, size = sheetRect(name, pixels)
    if not picture then
        if not atlas.ready or not atlasIndex()[name] then return false end
        picture, offset, size = atlasRect(atlasIndex()[name], pixels)
    end
    if not picture then return false end
    image.Image, image.ImageRectOffset, image.ImageRectSize = picture, offset, size
    return true
end

-- Puts the icon on an ImageLabel / ImageButton (two-tone icons get their extra parts as children).
function Icons.Apply(image, name)
    for _, child in ipairs(image:GetChildren()) do if child.Name == "IconPart" then child:Destroy() end end
    local icon = Icons.Get(name)
    if not icon then sharpImages[image] = nil return false end
    local sharp = not icon.Url and lucideName(name)
    if sharp then
        startAtlas()
        if sharpImages[image] == nil then
            -- a bigger / smaller menu (UI scale) can move the icon to the other sheet
            image:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                local current = sharpImages[image]
                if current then applySharp(image, current) end
            end)
            -- (its box laid out or resized: onto whole pixels again. Not on every move: the window and the pages
            -- only move by whole pixels, and thousands of icons listening to every move would cost a drag)
            local boxWatch
            local function watchBox()
                if boxWatch then boxWatch:Disconnect() boxWatch = nil end
                local parent = image.Parent
                if parent and parent:IsA("GuiObject") then
                    boxWatch = parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                        if sharpImages[image] then queueSnap(image) end
                    end)
                end
                if sharpImages[image] then queueSnap(image) end
            end
            -- (an icon gets its parent after it is made: Icons.Image, then .Parent)
            if Icons.SnapPosition ~= false then
                image:GetPropertyChangedSignal("Parent"):Connect(watchBox)
                watchBox()
            end
        end
        sharpImages[image] = sharp
        if applySharp(image, sharp) then return true end
    elseif sharpImages[image] then
        sharpImages[image] = false
    end
    if icon.Url then
        image.ImageColor3 = Color3.new(1, 1, 1)
        image.ImageRectSize, image.ImageRectOffset = ZERO, ZERO
        fetch(icon.Url, function(asset) image.Image = asset end)
        return true
    end
    image.Image = icon.Image
    image.ImageRectSize = icon.RectSize
    image.ImageRectOffset = icon.RectOffset
    for _, part in ipairs(icon.Parts or {}) do
        local child = Instance.new("ImageLabel")
        child.Name = "IconPart"
        child.BackgroundTransparency = 1
        child.Size = UDim2.fromScale(1, 1)
        child.Image, child.ImageRectSize, child.ImageRectOffset = part.Image, part.RectSize, part.RectOffset
        child.ImageTransparency = 0.5 -- second tone
        child.ZIndex = image.ZIndex
        child.Parent = image
        -- the part follows the icon's colour
        child.ImageColor3 = image.ImageColor3
        image:GetPropertyChangedSignal("ImageColor3"):Connect(function() child.ImageColor3 = image.ImageColor3 end)
    end
    return true
end

function Icons.Image(name, props)
    props = props or {}
    local image = Instance.new("ImageLabel")
    image.Name = props.Name or "Icon"
    image.BackgroundTransparency = 1
    image.ScaleType = Enum.ScaleType.Fit
    image.Size = props.Size or UDim2.fromOffset(16, 16)
    if typeof(props.Color) == "Color3" then image.ImageColor3 = props.Color end
    Icons.Apply(image, name)
    image.Parent = props.Parent
    return image
end

-- Library use: an icon whose colour follows a theme role (nil when the name is not an icon).
function Icons.themed(parent, name, size, role, props)
    if not Icons.Get(name) then return nil end
    local image = Icons.Image(name, { Size = UDim2.fromOffset(size, size), Name = props and props.Name or "Icon" })
    for key, value in pairs(props or {}) do if key ~= "Name" then image[key] = value end end
    -- web images keep their own colours
    if not Icons.Get(name).Url then Theme.bind(image, "ImageColor3", role or "text") end
    image.Parent = parent
    return image
end

function Icons.SetDefault(set)
    set = tostring(set):lower()
    if Icons.Sets[set] or Icons.Load(set) then Icons.Default = set return true end
    return false
end

function Icons.Add(set, data)
    set = tostring(set):lower()
    Icons.Sets[set] = Icons.Sets[set] or {}
    for name, value in pairs(data) do Icons.Sets[set][name] = value end
end

function Icons.List(set)
    set = tostring(set or Icons.Default):lower()
    if not Icons.Sets[set] then Icons.Load(set) end
    local data = Icons.Sets[set] or {}
    local names = {}
    for name in pairs(type(data.Icons) == "table" and data.Icons or data) do
        if type(name) == "string" then names[#names + 1] = name end
    end
    table.sort(names)
    return names
end

return Icons
end

__modules["icons_atlas"] = function()
-- Layout of icons/atlas/*.png, generated by tools/gen_atlas.py. Do not edit by hand.
return {
    Version = 1,
    Sheets = { [16] = { Columns = 56, PerPage = 10000 }, [32] = { Columns = 30, PerPage = 900 } },
    Pages = { [16] = { "lucide-16.png" }, [32] = { "lucide-32-1.png", "lucide-32-2.png" } },
    -- every lucide icon in icons_lucide.lua order, except these (no longer in lucide)
    Missing = "chromium,codepen,codesandbox,dribbble,facebook,figma,framer,github,gitlab,instagram,linkedin,pocket,rail-symbol,slack,trello,twitch,twitter,youtube",
}
end

__modules["icons_lucide"] = function()
-- Lucide icons as name, asset id pairs in a fixed order (the sharp sheets in icons/atlas follow the same order),
-- generated by tools/gen_lucide.py from Footagesus/Icons (MIT, see icons/LICENSE). Do not edit by hand.
return {
	"a-arrow-down",92867583610071,"a-arrow-up",132318504999733,"a-large-small",111491496660216,"accessibility",114029945302017,"activity",94212016861936,"air-vent",81517226012329,
	"airplay",115020759309179,"alarm-clock-check",76437352099157,"alarm-clock-minus",77364179863205,"alarm-clock-off",97904885874823,"alarm-clock-plus",80468822979214,"alarm-clock",126259032907535,
	"alarm-smoke",96965448419685,"album",127358331163602,"align-center-horizontal",81570549209434,"align-center-vertical",118470463752466,"align-end-horizontal",139502909745427,"align-end-vertical",96528869059554,
	"align-horizontal-distribute-center",97220086126656,"align-horizontal-distribute-end",106128590702022,"align-horizontal-distribute-start",76074660002997,"align-horizontal-justify-center",75732302772427,"align-horizontal-justify-end",129167626402283,"align-horizontal-justify-start",130161830325281,
	"align-horizontal-space-around",91646106782950,"align-horizontal-space-between",103886093046990,"align-start-horizontal",125674804697729,"align-start-vertical",105020230154823,"align-vertical-distribute-center",93791183635525,"align-vertical-distribute-end",139354223511433,
	"align-vertical-distribute-start",74961997822126,"align-vertical-justify-center",134754696166569,"align-vertical-justify-end",92569381441969,"align-vertical-justify-start",99692844572718,"align-vertical-space-around",96206012459190,"align-vertical-space-between",124998077349706,
	"ambulance",78599995190651,"ampersand",75272915739209,"ampersands",126947193455996,"amphora",137370389604364,"anchor",92181172123618,"angry",74237056000103,
	"annoyed",80064369052011,"antenna",99628923540956,"anvil",100203029845919,"aperture",83396154449972,"app-window-mac",79587216113811,"app-window",93142176757189,
	"apple",104349242902442,"archive-restore",78956681942188,"archive-x",75830115088395,"archive",122180020814574,"armchair",105384358373973,"arrow-big-down-dash",137987229582002,
	"arrow-big-down",81081164158885,"arrow-big-left-dash",97827621354677,"arrow-big-left",85973092492641,"arrow-big-right-dash",117825834972403,"arrow-big-right",82960676755590,"arrow-big-up-dash",99260194327483,
	"arrow-big-up",93136954756149,"arrow-down-0-1",120961896217875,"arrow-down-1-0",93474255891850,"arrow-down-a-z",99554596207900,"arrow-down-from-line",132045845807798,"arrow-down-left",102899325237364,
	"arrow-down-narrow-wide",129105261655061,"arrow-down-right",123109928624974,"arrow-down-to-dot",101675355931221,"arrow-down-to-line",87050478931254,"arrow-down-up",85780258549577,"arrow-down-wide-narrow",88461733425991,
	"arrow-down-z-a",76115279362232,"arrow-down",98764963621439,"arrow-left-from-line",87857914437603,"arrow-left-right",131324733048447,"arrow-left-to-line",118645136026970,"arrow-left",102531941843733,
	"arrow-right-from-line",74073639809355,"arrow-right-left",77015754304300,"arrow-right-to-line",78632510329852,"arrow-right",113692007244654,"arrow-up-0-1",105257823943016,"arrow-up-1-0",134175521693798,
	"arrow-up-a-z",77763416595160,"arrow-up-down",81019887641527,"arrow-up-from-dot",124408496673275,"arrow-up-from-line",95777664626453,"arrow-up-left",123490598231261,"arrow-up-narrow-wide",73006024672636,
	"arrow-up-right",129280608535523,"arrow-up-to-line",108818207813537,"arrow-up-wide-narrow",87437426951568,"arrow-up-z-a",107546173611884,"arrow-up",89282378235317,"arrows-up-from-line",133710016938621,
	"asterisk",88552752106723,"at-sign",79059152889146,"atom",73167696981648,"audio-lines",70930641819242,"audio-waveform",86462036665209,"award",132740088158419,
	"axe",132405197863294,"axis-3d",122438676546804,"baby",93472926933440,"backpack",140420225386018,"badge-alert",101829200081951,"badge-cent",133345018873154,
	"badge-check",76078495178149,"badge-dollar-sign",127139803581141,"badge-euro",120016477674659,"badge-indian-rupee",75659682309981,"badge-info",131995373201472,"badge-japanese-yen",99081574588615,
	"badge-minus",140321561183881,"badge-percent",121359224294885,"badge-plus",100325578561866,"badge-pound-sterling",119688217279444,"badge-question-mark",121464963737502,"badge-russian-ruble",108839463659864,
	"badge-swiss-franc",91447608372740,"badge-turkish-lira",137839965873529,"badge-x",122931434733842,"badge",116620312917084,"baggage-claim",86922213051957,"ban",90767043015246,
	"banana",140713420056179,"bandage",129660129590770,"banknote-arrow-down",139366449345199,"banknote-arrow-up",133758343082529,"banknote-x",95348701438065,"banknote",104840231536668,
	"barcode",118473018143689,"barrel",130647115622774,"baseline",124677132511270,"bath",76031400297942,"battery-charging",80139357470047,"battery-full",70906718268972,
	"battery-low",139659256984314,"battery-medium",105934079398915,"battery-plus",91931341486966,"battery-warning",115230083817257,"battery",70765800346189,"beaker",80902539995520,
	"bean-off",98164436608714,"bean",89491967076869,"bed-double",73820193212911,"bed-single",113423940880634,"bed",97726529032925,"beef",105850162318915,
	"beer-off",120333134736361,"beer",116404978807744,"bell-dot",93161277118810,"bell-electric",100277767266983,"bell-minus",126334890449727,"bell-off",78560046118930,
	"bell-plus",77014333795836,"bell-ring",94612128913941,"bell",97392696311902,"between-horizontal-end",81602774794322,"between-horizontal-start",76112384929846,"between-vertical-end",72817612571631,
	"between-vertical-start",85278312190301,"biceps-flexed",82004462003936,"bike",102930322246035,"binary",91751953950088,"binoculars",101460003267896,"biohazard",95956532900432,
	"bird",132284145117371,"birdhouse",83999157401433,"bitcoin",95459240442938,"blend",111679612185257,"blinds",71164165283925,"blocks",72212693357737,
	"bluetooth-connected",96315134002985,"bluetooth-off",80600044218117,"bluetooth-searching",100673019606426,"bluetooth",90506573139443,"bold",116141470019166,"bolt",102881251417484,
	"bomb",139223800924636,"bone",111242153474115,"book-a",104067275658465,"book-alert",124159928044853,"book-audio",109208148317037,"book-check",115999656081696,
	"book-copy",108543407492005,"book-dashed",127430784795958,"book-down",101011730128222,"book-headphones",108670200799574,"book-heart",112788845135284,"book-image",80808285757226,
	"book-key",116024426170705,"book-lock",118765061220571,"book-marked",73211024251780,"book-minus",112724962046282,"book-open-check",130848362492667,"book-open-text",100629528672195,
	"book-open",129845326810392,"book-plus",140267785051233,"book-text",94011772484232,"book-type",97817304725443,"book-up-2",130161620853665,"book-up",98640174079190,
	"book-user",128489189240523,"book-x",118754548186537,"book",125383279695672,"bookmark-check",93940443347986,"bookmark-minus",96807096039910,"bookmark-plus",121469724491615,
	"bookmark-x",112272342584706,"bookmark",121093149326239,"boom-box",99901322535868,"bot-message-square",96145330292478,"bot-off",140417690560013,"bot",80451686744860,
	"bottle-wine",131675403196921,"bow-arrow",124089655150375,"box",101768155599700,"boxes",136372617578355,"braces",117761094704041,"brackets",74368995728099,
	"brain-circuit",70547962410202,"brain-cog",132039205501538,"brain",92424107303177,"brick-wall-fire",92980588705520,"brick-wall-shield",75954432775071,"brick-wall",112878522258821,
	"briefcase-business",129135125207283,"briefcase-conveyor-belt",108665725653714,"briefcase-medical",119917756334087,"briefcase",96754188164225,"bring-to-front",132975903553748,"brush-cleaning",71728977448805,
	"brush",127035535799640,"bubbles",106183424168227,"bug-off",88020025049245,"bug-play",80107955888092,"bug",83626408925438,"building-2",77873775611951,
	"building",110616258983082,"bus-front",89863432456045,"bus",133798469717463,"cable-car",128643682205596,"cable",128449944504901,"cake-slice",136769828413242,
	"cake",103131590503275,"calculator",74915716529646,"calendar-1",98458364171044,"calendar-arrow-down",108415736543437,"calendar-arrow-up",70574654109118,"calendar-check-2",120231170248276,
	"calendar-check",71551019465748,"calendar-clock",119132152594595,"calendar-cog",122402172360287,"calendar-days",99072017568595,"calendar-fold",117368871270394,"calendar-heart",88839008103676,
	"calendar-minus-2",98846170279891,"calendar-minus",137354318924383,"calendar-off",109726151749217,"calendar-plus-2",112264562093883,"calendar-plus",125266115249843,"calendar-range",103641849247576,
	"calendar-search",92010083223634,"calendar-sync",78082218499697,"calendar-x-2",107518051061147,"calendar-x",106703374806500,"calendar",114792700814035,"camera-off",81057636835256,
	"camera",79950339943067,"candy-cane",71689468772492,"candy-off",110232752314832,"candy",107812129154678,"cannabis",98792006538601,"captions-off",105223545364193,
	"captions",104960225031445,"car-front",87380942739063,"car-taxi-front",122455403384057,"car",121065933462582,"caravan",120070979471783,"card-sim",134490550095771,
	"carrot",119118221444304,"case-lower",129303130603241,"case-sensitive",125410273293056,"case-upper",111633433531325,"cassette-tape",137065788934157,"cast",98202245922071,
	"castle",119275077187784,"cat",124252153404931,"cctv",99979894766624,"chart-area",123446436762366,"chart-bar-big",72336824986044,"chart-bar-decreasing",107217459044963,
	"chart-bar-increasing",88268905998571,"chart-bar-stacked",98478751113024,"chart-bar",105389816384108,"chart-candlestick",125676898615697,"chart-column-big",98598733210787,"chart-column-decreasing",73586137373563,
	"chart-column-increasing",120421615068601,"chart-column-stacked",86031449675105,"chart-column",97915995538580,"chart-gantt",88811660555940,"chart-line",101833156055618,"chart-network",104027882693561,
	"chart-no-axes-column-decreasing",123371717192542,"chart-no-axes-column-increasing",140383830943049,"chart-no-axes-column",94078751170351,"chart-no-axes-combined",121424233161912,"chart-no-axes-gantt",131936541106368,"chart-pie",113412261630136,
	"chart-scatter",108217585014571,"chart-spline",90307460742494,"check-check",95183312173858,"check-line",115122343485290,"check",93898873302694,"chef-hat",121744015002573,
	"cherry",139519182403183,"chess-bishop",121701705580238,"chess-king",90885687223462,"chess-knight",96467707042169,"chess-pawn",111318574652751,"chess-queen",98304702099749,
	"chess-rook",76223925830262,"chevron-down",134243273101015,"chevron-first",105243363790238,"chevron-last",89268452603731,"chevron-left",73780377692148,"chevron-right",92473583511724,
	"chevron-up",122444883127455,"chevrons-down-up",139404716013205,"chevrons-down",100524612205956,"chevrons-left-right-ellipsis",125035817741526,"chevrons-left-right",87910685945204,"chevrons-left",82617201744347,
	"chevrons-right-left",87149546686569,"chevrons-right",139121276490483,"chevrons-up-down",131833120209646,"chevrons-up",100467452364672,"chromium",128165143739006,"church",113714744350666,
	"cigarette-off",77797883078452,"circle-alert",83898160590116,"circle-arrow-down",95901860261344,"circle-arrow-left",102148876968988,"circle-arrow-out-down-left",140598097856694,"circle-arrow-out-down-right",119952801379305,
	"circle-arrow-out-up-left",132858212688303,"circle-arrow-out-up-right",81783743753173,"circle-arrow-right",70786767999559,"circle-arrow-up",84395128546494,"circle-check-big",93202927221730,"circle-check",85262178816537,
	"circle-chevron-down",137069490345718,"circle-chevron-left",130250009740827,"circle-chevron-right",125943696958495,"circle-chevron-up",111223574026321,"circle-dashed",126799443883746,"circle-divide",106398997754208,
	"circle-dollar-sign",91106238890387,"circle-dot-dashed",111451232827180,"circle-dot",82947033619201,"circle-ellipsis",91687150884779,"circle-equal",95133963751438,"circle-fading-arrow-up",104648212910336,
	"circle-fading-plus",91847890443490,"circle-gauge",108157549473765,"circle-minus",133556159576809,"circle-off",97923456918886,"circle-parking-off",128369410981252,"circle-parking",124034962915196,
	"circle-pause",139337739700879,"circle-percent",133311912860256,"circle-play",120408917249739,"circle-plus",113157136350384,"circle-pound-sterling",105476153083828,"circle-power",140676030155098,
	"circle-question-mark",97516698664325,"circle-slash-2",136766902186549,"circle-slash",125206439913049,"circle-small",73685402843600,"circle-star",120318414957104,"circle-stop",87400503942659,
	"circle-user-round",95489465399880,"circle-user",136220511671311,"circle-x",76821953846248,"circle",130359823580534,"circuit-board",107695264369312,"citrus",139018222976433,
	"clapperboard",132660667070200,"clipboard-check",92649798577170,"clipboard-clock",123957515687745,"clipboard-copy",125851897718493,"clipboard-list",96460215958908,"clipboard-minus",107968008485671,
	"clipboard-paste",74382068849983,"clipboard-pen-line",77711589791615,"clipboard-pen",75290966822953,"clipboard-plus",134285318675662,"clipboard-type",89949374318028,"clipboard-x",102222456890103,
	"clipboard",89601995828423,"clock-1",129363225422045,"clock-10",104332695855541,"clock-11",119023205186105,"clock-12",117789618723068,"clock-2",134710777209413,
	"clock-3",136385631189327,"clock-4",121808839832144,"clock-5",85082019959457,"clock-6",71009733505593,"clock-7",103111188546225,"clock-8",110059272125337,
	"clock-9",77610027126437,"clock-alert",97157344465162,"clock-arrow-down",92349314416042,"clock-arrow-up",111484286332629,"clock-check",85231630218857,"clock-fading",93205297285245,
	"clock-plus",93367709263150,"clock",121808839832144,"closed-caption",99832644030788,"cloud-alert",91967273658626,"cloud-check",97318598202432,"cloud-cog",96497764065749,
	"cloud-download",121435581993566,"cloud-drizzle",139525315752605,"cloud-fog",76650233148776,"cloud-hail",72320462748242,"cloud-lightning",133517088924849,"cloud-moon-rain",127667837827018,
	"cloud-moon",71938114737914,"cloud-off",131907154501444,"cloud-rain-wind",107414583736721,"cloud-rain",105547081967408,"cloud-snow",72307126270226,"cloud-sun-rain",99041604425705,
	"cloud-sun",86114208148727,"cloud-upload",93307473217005,"cloud",121226497050352,"cloudy",105360479023346,"clover",74925550436750,"club",108490365816628,
	"code-xml",130150477351734,"code",107380207681249,"codepen",135643965971885,"codesandbox",106911852964823,"coffee",106864403231093,"cog",116544501716299,
	"coins",116510979641930,"columns-2",113004100221850,"columns-3-cog",121589691981064,"columns-3",115223357399375,"columns-4",130807991968419,"combine",79908476334048,
	"command",93648221906330,"compass",115123411028382,"component",110027788875080,"computer",77480056459407,"concierge-bell",140384259310436,"cone",97759550688437,
	"construction",106539489968173,"contact-round",71907624112229,"contact",75868297719012,"container",91507237573499,"contrast",112796643981497,"cookie",73159504540002,
	"cooking-pot",94959783129799,"copy-check",91177247988892,"copy-minus",109524509933035,"copy-plus",113618379616952,"copy-slash",93805787810390,"copy-x",106557557978061,
	"copy",78979572434545,"copyleft",78559055698593,"copyright",129433635747111,"corner-down-left",90473561177832,"corner-down-right",86512767702085,"corner-left-down",139876989150630,
	"corner-left-up",126228268096099,"corner-right-down",89237035551302,"corner-right-up",112851237026705,"corner-up-left",84669279763024,"corner-up-right",115099889693145,"cpu",77549309870247,
	"creative-commons",90408210735312,"credit-card",99163352872346,"croissant",130710485559420,"crop",116344601101413,"cross",101833377863588,"crosshair",134242818164054,
	"crown",127843403295538,"cuboid",75618807946111,"cup-soda",121098640829562,"currency",90551250119972,"cylinder",90569677179169,"dam",76874486231393,
	"database-backup",103403210984699,"database-zap",131199921258418,"database",126791525623846,"decimals-arrow-left",120198500638749,"decimals-arrow-right",118263047146797,"delete",126279426372342,
	"dessert",71508133278830,"diameter",97429051503783,"diamond-minus",128989071438290,"diamond-percent",107717860105959,"diamond-plus",134701163723675,"diamond",105846996304890,
	"dice-1",112650149591038,"dice-2",112278274566793,"dice-3",118526270626312,"dice-4",113365650364004,"dice-5",72768312430593,"dice-6",85376239182543,
	"dices",81268120302865,"diff",135052708609715,"disc-2",91419420404185,"disc-3",135470554736048,"disc-album",74693460404344,"disc",101908120120777,
	"divide",136678191878278,"dna-off",89612426361540,"dna",74007982981741,"dock",121997427160252,"dog",71920105558570,"dollar-sign",127320961224019,
	"donut",72204922742657,"door-closed-locked",74027613267551,"door-closed",136249099949073,"door-open",91306356501736,"dot",137321056643916,"download",134814648082393,
	"drafting-compass",99701976182841,"drama",110297795801577,"dribbble",80231809663849,"drill",108644821412796,"drone",117299095794783,"droplet-off",119365002225172,
	"droplet",100597455015098,"droplets",140111846025180,"drum",136979060344890,"drumstick",104662462521709,"dumbbell",80277236776212,"ear-off",87421916192807,
	"ear",121894949934209,"earth-lock",88814147073745,"earth",76231597751076,"eclipse",114829622118222,"egg-fried",90622538210545,"egg-off",92288321309285,
	"egg",117851493400222,"ellipsis-vertical",117978708573781,"ellipsis",140019550645825,"equal-approximately",105382689698323,"equal-not",76864449458032,"equal",123467780715624,
	"eraser",133957773112410,"ethernet-port",75391715149314,"euro",72229646524456,"ev-charger",97906158859623,"expand",137492887754537,"external-link",129331830773832,
	"eye-closed",111063268625789,"eye-off",135928786788378,"eye",100033680381365,"facebook",72098528632192,"factory",102170024318039,"fan",78391400440696,
	"fast-forward",121615540167909,"feather",91872927606406,"fence",123451565578029,"ferris-wheel",79729205796176,"figma",134182122852301,"file-archive",77018106869967,
	"file-axis-3d",133912328009885,"file-badge",74564895394477,"file-box",119264004071690,"file-braces-corner",77253337986109,"file-braces",95314128621234,"file-chart-column-increasing",134449481172067,
	"file-chart-column",82048481252560,"file-chart-line",71954360551345,"file-chart-pie",81072193564497,"file-check-corner",76295552859171,"file-check",82604001452455,"file-clock",102325208830990,
	"file-code-corner",78293841184371,"file-code",130978036895504,"file-cog",101385347151368,"file-diff",96147216772241,"file-digit",89220220354580,"file-down",120650154178290,
	"file-exclamation-point",102821865889635,"file-headphone",100533735901986,"file-heart",132214916401696,"file-image",123334057511782,"file-input",124728604166044,"file-key",118790255921100,
	"file-lock",72170228691242,"file-minus-corner",119263271735124,"file-minus",111014798459222,"file-music",134948051536671,"file-output",92146832572911,"file-pen-line",104622936345006,
	"file-pen",79556179730240,"file-play",89006821567838,"file-plus-corner",76544604043974,"file-plus",78881710800060,"file-question-mark",127617422859576,"file-scan",129480105228213,
	"file-search-corner",90974165234008,"file-search",97780235974933,"file-signal",122070252538165,"file-sliders",85787771732439,"file-spreadsheet",134501869359270,"file-stack",138929929862605,
	"file-symlink",91865722036510,"file-terminal",116757454755476,"file-text",90496405707281,"file-type-corner",124902230275209,"file-type",115272552799361,"file-up",131173039312748,
	"file-user",99552018455009,"file-video-camera",81719056173960,"file-volume",111264764438958,"file-x-corner",87554136773609,"file-x",107333775515154,"file",74748492079329,
	"files",102806336233202,"film",120978945609706,"fingerprint",112173305232811,"fire-extinguisher",111643493006960,"fish-off",89756724887508,"fish-symbol",118475177681618,
	"fish",124360663785796,"flag-off",112944528856799,"flag-triangle-left",88045221285272,"flag-triangle-right",108292480304566,"flag",78183383236196,"flame-kindling",139728976917928,
	"flame",98218034436456,"flashlight-off",79780362871740,"flashlight",100286985600444,"flask-conical-off",112597970025298,"flask-conical",128406680901165,"flask-round",127508287324940,
	"flip-horizontal-2",103726993598186,"flip-horizontal",122937530107837,"flip-vertical-2",103836358956328,"flip-vertical",108003917346888,"flower-2",72934574245145,"flower",86129438272762,
	"focus",87493973153317,"fold-horizontal",92835712442240,"fold-vertical",108873727253656,"folder-archive",97312009460206,"folder-check",128492920904557,"folder-clock",111964836738545,
	"folder-closed",118286209350843,"folder-code",70624096349370,"folder-cog",85299519462846,"folder-dot",138687772725278,"folder-down",118044108459225,"folder-git-2",101394054141166,
	"folder-git",121885778095158,"folder-heart",79104747211105,"folder-input",90699920697871,"folder-kanban",78313285104072,"folder-key",85270407596791,"folder-lock",119201572260567,
	"folder-minus",85648718999010,"folder-open-dot",74741494767354,"folder-open",76018996254888,"folder-output",101532447937612,"folder-pen",112770491173911,"folder-plus",91865663406119,
	"folder-root",103333751154693,"folder-search-2",71276453442655,"folder-search",110568075123861,"folder-symlink",127485747227189,"folder-sync",91544602659796,"folder-tree",85577554337861,
	"folder-up",72008269765857,"folder-x",91699618247635,"folder",80846616596607,"folders",110351216219061,"footprints",139192589041315,"forklift",72030930983101,
	"forward",97545944739523,"frame",109080612832751,"framer",108384807262391,"frown",124407301067982,"fuel",106447647274511,"fullscreen",77793665526178,
	"funnel-plus",100780233821928,"funnel-x",70984385812555,"funnel",108829540827529,"gallery-horizontal-end",74672430161161,"gallery-horizontal",80004001442122,"gallery-thumbnails",136219289862706,
	"gallery-vertical-end",106461402088317,"gallery-vertical",119299431466725,"gamepad-2",92483947987410,"gamepad-directional",84342305212226,"gamepad",121607283959010,"gauge",110273524101447,
	"gavel",78952298198456,"gem",112904952151156,"georgian-lari",98084432591687,"ghost",113822048130017,"gift",109855212076373,"git-branch-minus",97385010649411,
	"git-branch-plus",125944221134316,"git-branch",90490195516649,"git-commit-horizontal",133646041800147,"git-commit-vertical",122098032990350,"git-compare-arrows",84874426520216,"git-compare",91945124438792,
	"git-fork",89954992404765,"git-graph",86166832019304,"git-merge",131833355158059,"git-pull-request-arrow",94507974577439,"git-pull-request-closed",78070600389091,"git-pull-request-create-arrow",127422677061091,
	"git-pull-request-create",105929577383926,"git-pull-request-draft",76173459869943,"git-pull-request",138463010991471,"github",120349554354380,"gitlab",114054627192933,"glass-water",115526102400988,
	"glasses",87936407455373,"globe-lock",134065526704402,"globe",114238209622913,"goal",120517954878160,"gpu",95577823614219,"graduation-cap",93771896340220,
	"grape",134760640415561,"grid-2x2-check",138468840220821,"grid-2x2-plus",91811610580247,"grid-2x2-x",72407303981388,"grid-2x2",99050491897640,"grid-3x2",95528684210010,
	"grid-3x3",70419024781206,"grip-horizontal",136255899715930,"grip-vertical",137183678565296,"grip",109058783556768,"group",107643418926671,"guitar",75915531867926,
	"ham",74465607934635,"hamburger",93086916815495,"hammer",83545120140895,"hand-coins",126990543175462,"hand-fist",83341608917591,"hand-grab",88867162163985,
	"hand-heart",117507367668412,"hand-helping",89897738419446,"hand-metal",113619498548713,"hand-platter",88594727743168,"hand",130703864968637,"handbag",135675846264061,
	"handshake",78442115255814,"hard-drive-download",73913801230614,"hard-drive-upload",85762133615118,"hard-drive",88183305858463,"hard-hat",128050846767382,"hash",82890331678520,
	"hat-glasses",101165538224815,"haze",108857561768901,"hdmi-port",103693661037020,"heading-1",118129315662110,"heading-2",110209069670094,"heading-3",90267885237062,
	"heading-4",129625620307602,"heading-5",120386663181267,"heading-6",90959079775093,"heading",129254312067735,"headphone-off",85038251615641,"headphones",118833729589183,
	"headset",129269236787694,"heart-crack",110987638564119,"heart-handshake",111483078692002,"heart-minus",96827380163326,"heart-off",89748414415617,"heart-plus",94877796283249,
	"heart-pulse",129352925579546,"heart",116559368303288,"heater",140478466880916,"helicopter",111557171735930,"hexagon",127592089339199,"highlighter",77411555641113,
	"history",123980022019922,"hop-off",103386036934034,"hop",82778923997672,"hospital",105868763850707,"hotel",132283390859718,"hourglass",86160434939203,
	"house-heart",136054771868597,"house-plug",71438263712075,"house-plus",118495165208309,"house-wifi",126495519725698,"house",98755624629571,"ice-cream-bowl",124867218454386,
	"ice-cream-cone",90751397288639,"id-card-lanyard",90761480469224,"id-card",75354294622640,"image-down",78972295741235,"image-minus",101066016918565,"image-off",81934811700938,
	"image-play",129501806784210,"image-plus",70391970623917,"image-up",126610009605241,"image-upscale",106963545024679,"images",79350649395557,"import",116545008906029,
	"inbox",112591360302868,"indian-rupee",113038778381805,"infinity",98083086936965,"info",124560466474914,"inspection-panel",70905313146088,"instagram",119864798614855,
	"italic",96220378864282,"iteration-ccw",140221832794083,"iteration-cw",95534489554662,"japanese-yen",106362863465813,"joystick",99416790224739,"kanban",125934100055431,
	"kayak",136107544609389,"key-round",83619031955390,"key-square",94621420033649,"key",96510194465420,"keyboard-music",121058541758636,"keyboard-off",92466375369772,
	"keyboard",121474456068237,"lamp-ceiling",80032758469141,"lamp-desk",85290686983238,"lamp-floor",104585881375892,"lamp-wall-down",91271394132073,"lamp-wall-up",132141464337445,
	"lamp",110730830653382,"land-plot",96449039620294,"landmark",76885079756393,"languages",90816903776498,"laptop-minimal-check",114352019833865,"laptop-minimal",136705765566068,
	"laptop",111387063244975,"lasso-select",105609719912753,"lasso",121072936884007,"laugh",104491311361166,"layers-2",70536710516357,"layers",81973586053257,
	"layout-dashboard",139929981863901,"layout-grid",81344910161871,"layout-list",87462136296578,"layout-panel-left",125092469751491,"layout-panel-top",91943941515944,"layout-template",115564446417985,
	"leaf",119951075637174,"leafy-green",105146290493154,"lectern",106166425183862,"library-big",106794530191412,"library",114334671982047,"life-buoy",81168450671956,
	"ligature",111397873269411,"lightbulb-off",83795722296178,"lightbulb",103871245626488,"line-squiggle",109555164424447,"link-2-off",76885956296867,"link-2",86072351557466,
	"link",131607023382430,"linkedin",132842789255788,"list-check",72374358471156,"list-checks",99809353635593,"list-chevrons-down-up",137409641500711,"list-chevrons-up-down",81825351389084,
	"list-collapse",124505247702401,"list-end",77650610048119,"list-filter-plus",96385120752336,"list-filter",103321376129527,"list-indent-decrease",137879979228193,"list-indent-increase",79051053161201,
	"list-minus",138507965142671,"list-music",126380635781840,"list-ordered",83212528113913,"list-plus",112384738137814,"list-restart",91703153577421,"list-start",84828348299727,
	"list-todo",132980603752108,"list-tree",97685396239010,"list-video",93648525452489,"list-x",113025303988861,"list",113179976918783,"loader-circle",116535712789945,
	"loader-pinwheel",108513357940900,"loader",78408734580845,"locate-fixed",137367361548433,"locate-off",73729216338137,"locate",84467676590391,"lock-keyhole-open",110863509313073,
	"lock-keyhole",78672912777756,"lock-open",93597915325122,"lock",134724289526879,"log-in",103768533135201,"log-out",84895399304975,"logs",89772091251787,
	"lollipop",84681611583044,"luggage",76619236486400,"magnet",135162361226972,"mail-check",86921536259917,"mail-minus",81989813236553,"mail-open",122785416858638,
	"mail-plus",104886401588341,"mail-question-mark",126540170949819,"mail-search",135616173775287,"mail-warning",81495303676089,"mail-x",74607841705644,"mail",103945161245599,
	"mailbox",82765503320335,"mails",90673453450080,"map-minus",129525760577747,"map-pin-check-inside",107130529843809,"map-pin-check",118110914690154,"map-pin-house",80546885029816,
	"map-pin-minus-inside",79005529692964,"map-pin-minus",74518762643623,"map-pin-off",82474689391020,"map-pin-pen",113515395277504,"map-pin-plus-inside",134639656514430,"map-pin-plus",91875228967029,
	"map-pin-x-inside",126235934252379,"map-pin-x",101085273547316,"map-pin",84279202219901,"map-pinned",103963788475034,"map-plus",129388826743495,"map",95107167260947,
	"mars-stroke",131973193186828,"mars",111287112372511,"martini",82977695401058,"maximize-2",73085922906397,"maximize",76045941763188,"medal",79016002264450,
	"megaphone-off",124280774193935,"megaphone",118759541854879,"meh",132197867028557,"memory-stick",93212591343119,"menu",77021539815611,"merge",126201866476775,
	"message-circle-code",112865244991651,"message-circle-dashed",81525157881897,"message-circle-heart",101990756073677,"message-circle-more",92856823884663,"message-circle-off",134955643890328,"message-circle-plus",106562979649273,
	"message-circle-question-mark",107700302759934,"message-circle-reply",137071749508334,"message-circle-warning",119020096067894,"message-circle-x",126843387725536,"message-circle",127255077587058,"message-square-code",110968863152123,
	"message-square-dashed",107653455516238,"message-square-diff",75472190472625,"message-square-dot",127806382463916,"message-square-heart",75612811742074,"message-square-lock",81268215619563,"message-square-more",120139782405970,
	"message-square-off",99961019005789,"message-square-plus",76934450256199,"message-square-quote",116670768629340,"message-square-reply",130985622754637,"message-square-share",131017005324026,"message-square-text",94899503194205,
	"message-square-warning",138432903962261,"message-square-x",137285463279462,"message-square",83881670383280,"messages-square",97532166733358,"mic-off",82123034444822,"mic-vocal",99082286164362,
	"mic",89640799126523,"microchip",73937907669903,"microscope",116875530102782,"microwave",108411735353008,"milestone",101618292325920,"milk-off",72388480962742,
	"milk",96221903896918,"minimize-2",116269596042539,"minimize",121304296213645,"minus",118026365011536,"monitor-check",86651948439229,"monitor-cloud",85931096038318,
	"monitor-cog",94345128715799,"monitor-dot",130394010063680,"monitor-down",97466933743423,"monitor-off",74395526657953,"monitor-pause",76002184067562,"monitor-play",133018824306217,
	"monitor-smartphone",84335680433378,"monitor-speaker",81744810060380,"monitor-stop",98708958984757,"monitor-up",96035360858377,"monitor-x",126265210441423,"monitor",72664649203050,
	"moon-star",82782200506348,"moon",83380517901735,"motorbike",94580787368233,"mountain-snow",105315495740588,"mountain",73269957566415,"mouse-off",75267871697595,
	"mouse-pointer-2-off",104701076865632,"mouse-pointer-2",117093892862228,"mouse-pointer-ban",106849413057133,"mouse-pointer-click",107150227368485,"mouse-pointer",72322454962935,"mouse",73096068864710,
	"move-3d",103365982054003,"move-diagonal-2",117298577948096,"move-diagonal",101433481954184,"move-down-left",102819433534567,"move-down-right",101479760041877,"move-down",70510115135583,
	"move-horizontal",88513523439149,"move-left",137614740247980,"move-right",132455779472989,"move-up-left",139079815540148,"move-up-right",105885140592646,"move-up",84505444262658,
	"move-vertical",86234730730899,"move",116138709011735,"music-2",134397426600888,"music-3",94466120066498,"music-4",132459323665838,"music",113343203848535,
	"navigation-2-off",116569611780763,"navigation-2",81889066747907,"navigation-off",87003270290777,"navigation",79308213542922,"network",127410729922644,"newspaper",123479530460544,
	"nfc",76822396542242,"non-binary",78442360386235,"notebook-pen",140380614761023,"notebook-tabs",127371085570083,"notebook-text",93061585217270,"notebook",136132108664987,
	"notepad-text-dashed",135793446376219,"notepad-text",93404682958966,"nut-off",78795397311573,"nut",127146410705656,"octagon-alert",140438367956051,"octagon-minus",74720436795421,
	"octagon-pause",103161463909039,"octagon-x",90498161006311,"octagon",120803515514852,"omega",70414080018786,"option",100776883894054,"orbit",108926136860562,
	"origami",136020626667101,"package-2",70394974762575,"package-check",102374216055130,"package-minus",114492858789692,"package-open",132890233237818,"package-plus",129261988138366,
	"package-search",95465120894145,"package-x",70818501607442,"package",97261141732706,"paint-bucket",124275586663284,"paint-roller",115248074358348,"paintbrush-vertical",105151296591292,
	"paintbrush",125572663700289,"palette",86350350950064,"panda",132509022802512,"panel-bottom-close",74287004071159,"panel-bottom-dashed",131084651621603,"panel-bottom-open",107768659586540,
	"panel-bottom",132127145048511,"panel-left-close",126579818823552,"panel-left-dashed",75536606374585,"panel-left-open",111075816195767,"panel-left-right-dashed",110100707973959,"panel-left",97419752870313,
	"panel-right-close",139528655524132,"panel-right-dashed",94959793877311,"panel-right-open",118114419142794,"panel-right",116365035443156,"panel-top-bottom-dashed",134737235653344,"panel-top-close",83578325777808,
	"panel-top-dashed",70522913169237,"panel-top-open",137959875507454,"panel-top",75838479462875,"panels-left-bottom",72996856149149,"panels-right-bottom",90659068960726,"panels-top-left",79858853850600,
	"paperclip",92088291163453,"parentheses",78950955173096,"parking-meter",84652733960568,"party-popper",111626795712193,"pause",74873705394436,"paw-print",112218825427601,
	"pc-case",122978648019101,"pen-line",109108135755303,"pen-off",84807123119438,"pen-tool",106145404953445,"pen",72037878096321,"pencil-line",88392917053533,
	"pencil-off",103330927652832,"pencil-ruler",110120288284597,"pencil",137986121120732,"pentagon",79184802179890,"percent",130155041032013,"person-standing",125020872044147,
	"philippine-peso",91173798254675,"phone-call",70555587592860,"phone-forwarded",113269614319737,"phone-incoming",82863576359288,"phone-missed",130156165198376,"phone-off",133318623553383,
	"phone-outgoing",104576478735825,"phone",128804946640049,"pi",74936036243146,"piano",85008880789520,"pickaxe",105888023317688,"picture-in-picture-2",112803319544468,
	"picture-in-picture",80579597835123,"piggy-bank",79498575790721,"pilcrow-left",103803000849583,"pilcrow-right",104881733911870,"pilcrow",139512780392871,"pill-bottle",118394692404597,
	"pill",73280534813448,"pin-off",127696372451750,"pin",120978111007514,"pipette",133167932934404,"pizza",126964453193501,"plane-landing",122555692211889,
	"plane-takeoff",117179478829575,"plane",126985561580989,"play",135609604299893,"plug-2",97912386476366,"plug-zap",74506269884055,"plug",99782373064495,
	"plus",111774323017047,"pocket-knife",134075428063965,"pocket",136686762542964,"podcast",109577075549215,"pointer-off",95488389312794,"pointer",92615117311099,
	"popcorn",139446511232750,"popsicle",112696318077073,"pound-sterling",127482649469130,"power-off",118768311012214,"power",96479131758775,"presentation",106134583757890,
	"printer-check",130273549443689,"printer",76080649734247,"projector",103281856385283,"proportions",130046855997237,"puzzle",136837798892463,"pyramid",107811442374127,
	"qr-code",105329945723350,"quote",103271711590001,"rabbit",98580518804206,"radar",138528222906635,"radiation",104499586848433,"radical",132758286926047,
	"radio-receiver",129598303378835,"radio-tower",93958663130054,"radio",85611589536956,"radius",89814505307129,"rail-symbol",134295386306962,"rainbow",132488862841895,
	"rat",127400975953159,"ratio",126369423897295,"receipt-cent",91557573925201,"receipt-euro",94015722210295,"receipt-indian-rupee",89718170439990,"receipt-japanese-yen",132472560758851,
	"receipt-pound-sterling",73934967569625,"receipt-russian-ruble",105164576936853,"receipt-swiss-franc",72503668620116,"receipt-text",138483536013737,"receipt-turkish-lira",91950765836342,"receipt",77877895901792,
	"rectangle-circle",100642423153903,"rectangle-ellipsis",112919953980965,"rectangle-goggles",98605436666727,"rectangle-horizontal",90224199814966,"rectangle-vertical",117277050590967,"recycle",140417023381961,
	"redo-2",70451039017914,"redo-dot",94252981719732,"redo",116150342119054,"refresh-ccw-dot",106702246753270,"refresh-ccw",117913330389477,"refresh-cw-off",140179498843054,
	"refresh-cw",138133190015277,"refrigerator",102614042652753,"regex",100727200791841,"remove-formatting",112833162022628,"repeat-1",130144534857095,"repeat-2",85927537182704,
	"repeat",121886242955173,"replace-all",127862728198635,"replace",128404082279430,"reply-all",71723137343562,"reply",109788633497028,"rewind",95205297521988,
	"ribbon",94265331526851,"rocket",87412317685854,"rocking-chair",110420269495360,"roller-coaster",112426178972099,"rose",126336840238769,"rotate-3d",76300551576392,
	"rotate-ccw-key",74976035240976,"rotate-ccw-square",90515853170424,"rotate-ccw",110116685948665,"rotate-cw-square",77095448159303,"rotate-cw",84183336178654,"route-off",106350402024079,
	"route",89968303228953,"router",102130331994471,"rows-2",112556185960101,"rows-3",117215586961375,"rows-4",125646021959055,"rss",131789058984793,
	"ruler-dimension-line",70673861371412,"ruler",81432445547423,"russian-ruble",126357936542156,"sailboat",87110567187540,"salad",128864507821603,"sandwich",104573187458917,
	"satellite-dish",136742443888305,"satellite",134967053164645,"saudi-riyal",102282769104635,"save-all",116946975799440,"save-off",87085435778560,"save",126116963775616,
	"scale-3d",72414199620352,"scale",108203682317477,"scaling",122360365318466,"scan-barcode",96889457154761,"scan-eye",99244790601968,"scan-face",109959345069668,
	"scan-heart",106280819776142,"scan-line",126544908146540,"scan-qr-code",105409149549927,"scan-search",80009010551347,"scan-text",73702396787766,"scan",123104789658180,
	"school",76351530290068,"scissors-line-dashed",122237447974173,"scissors",118665510911274,"screen-share-off",107677572669805,"screen-share",85137895705653,"scroll-text",97321022666868,
	"scroll",74072101474951,"search-check",75442076191356,"search-code",117114794592802,"search-slash",96483932261041,"search-x",137319957522951,"search",121018724060431,
	"section",91732188298948,"send-horizontal",111734392411664,"send-to-back",75340312862253,"send",127751956873796,"separator-horizontal",84864453699927,"separator-vertical",84031801478581,
	"server-cog",138470287250966,"server-crash",132810618000212,"server-off",114048751507723,"server",92188766517878,"settings-2",135684703553372,"settings",80758916183665,
	"shapes",129989433311409,"share-2",71210767962065,"share",87340985053299,"sheet",134902122480171,"shell",140212943563599,"shield-alert",114995877719925,
	"shield-ban",108765041044649,"shield-check",87354736164608,"shield-ellipsis",114794739892123,"shield-half",117842634172647,"shield-minus",89965059528921,"shield-off",133426959132690,
	"shield-plus",100664857995498,"shield-question-mark",135722075265150,"shield-user",124832775645347,"shield-x",73370117343811,"shield",110987169760162,"ship-wheel",130797795829448,
	"ship",83995100553930,"shirt",106579555405966,"shopping-bag",71885477293226,"shopping-basket",138646411956433,"shopping-cart",128420521375441,"shovel",102465000512056,
	"shower-head",75884944024117,"shredder",122125164414463,"shrimp",102625900815307,"shrink",90953687918880,"shrub",127326280714343,"shuffle",132382786975101,
	"sigma",126884244870899,"signal-high",130436670012270,"signal-low",73674683500458,"signal-medium",125003021367019,"signal-zero",130045332414754,"signal",78424889355261,
	"signature",114402748013000,"signpost-big",115780185675001,"signpost",106584743791433,"siren",134210267818039,"skip-back",70466132711334,"skip-forward",124844823753990,
	"skull",137726256442333,"slack",96089719516736,"slash",117792185664263,"slice",95810504278179,"sliders-horizontal",85538382643347,"sliders-vertical",101190569086853,
	"smartphone-charging",102837532613995,"smartphone-nfc",82326425754446,"smartphone",96623008834511,"smile-plus",131981881472144,"smile",105880397565283,"snail",70904536548363,
	"snowflake",101235206534566,"soap-dispenser-droplet",77258480479465,"sofa",114427687218324,"solar-panel",132448188047921,"soup",115092551871618,"space",87072088914178,
	"spade",131444449466462,"sparkle",111044800239623,"sparkles",138635884129147,"speaker",96227183003618,"speech",87013139446349,"spell-check-2",81556731785534,
	"spell-check",91913483031334,"spline-pointer",84842840956804,"spline",129406685807412,"split",105112438805988,"spool",124541981347743,"spotlight",77571742539344,
	"spray-can",128372039366326,"sprout",100091687832508,"square-activity",89496630185293,"square-arrow-down-left",108194680296901,"square-arrow-down-right",99403846801050,"square-arrow-down",135962519626588,
	"square-arrow-left",111671474549238,"square-arrow-out-down-left",125714881756353,"square-arrow-out-down-right",89971003001390,"square-arrow-out-up-left",103759986579087,"square-arrow-out-up-right",91221896066807,"square-arrow-right",113920471701361,
	"square-arrow-up-left",112424670290693,"square-arrow-up-right",76602291406940,"square-arrow-up",106998604646718,"square-asterisk",89186832353625,"square-bottom-dashed-scissors",79076980104803,"square-chart-gantt",104034017316411,
	"square-check-big",115320390907184,"square-check",134682053539509,"square-chevron-down",91032307924592,"square-chevron-left",73143404829510,"square-chevron-right",90612077729930,"square-chevron-up",85565910197337,
	"square-code",81604576616881,"square-dashed-bottom-code",100354801563230,"square-dashed-bottom",101102319625624,"square-dashed-kanban",90388067649847,"square-dashed-mouse-pointer",121016142178467,"square-dashed-top-solid",117157577548540,
	"square-dashed",136905537847606,"square-divide",99894657101970,"square-dot",116613421354866,"square-equal",110283363706707,"square-function",86075219551088,"square-kanban",114537101260131,
	"square-library",73810931222081,"square-m",117662700410577,"square-menu",104067089444415,"square-minus",116764432015770,"square-mouse-pointer",76141850603920,"square-parking-off",100857293535141,
	"square-parking",133116656122387,"square-pause",86608552787615,"square-pen",120239476110475,"square-percent",87111930314567,"square-pi",75383328781618,"square-pilcrow",131854284699367,
	"square-play",108186325238481,"square-plus",114713264461873,"square-power",129240437805187,"square-radical",132645931868292,"square-round-corner",104592745113567,"square-scissors",110601255612411,
	"square-sigma",113231244246816,"square-slash",105477013908757,"square-split-horizontal",76095370148660,"square-split-vertical",88589192032058,"square-square",136555087357875,"square-stack",100463396619394,
	"square-star",94506958703720,"square-stop",80018708472943,"square-terminal",83969264476798,"square-user-round",86484997229302,"square-user",70771214183445,"square-x",125136183850190,
	"square",86304921356806,"squares-exclude",102345385822324,"squares-intersect",120869602570119,"squares-subtract",131484650948795,"squares-unite",96673080107843,"squircle-dashed",129936702532522,
	"squircle",82426632573807,"squirrel",112864252085343,"stamp",92370779813368,"star-half",117449275562979,"star-off",75742832732503,"star",136141469398409,
	"step-back",108672750005121,"step-forward",126131872136145,"stethoscope",122331031702148,"sticker",79938203791608,"sticky-note",111894074643919,"store",90338129673705,
	"stretch-horizontal",87665042192343,"stretch-vertical",95265463417122,"strikethrough",103417324549613,"subscript",74553514785183,"sun-dim",129141645592715,"sun-medium",130278807964710,
	"sun-moon",75752898854559,"sun-snow",112791898014579,"sun",110150589884127,"sunrise",134705665494098,"sunset",75904872203588,"superscript",96887696590118,
	"swatch-book",126786244872453,"swiss-franc",113497920041625,"switch-camera",76841154349737,"sword",124448418211665,"swords",81872698913435,"syringe",123891270479254,
	"table-2",95751552281545,"table-cells-merge",95363715175258,"table-cells-split",114799086088649,"table-columns-split",111011625447949,"table-of-contents",135044763275414,"table-properties",125062886015372,
	"table-rows-split",96443733673997,"table",109109148250737,"tablet-smartphone",133680859813404,"tablet",128403991264386,"tablets",80835787970735,"tag",129104970103940,
	"tags",107179263080798,"tally-1",115301298241643,"tally-2",110363186864027,"tally-3",97655344572540,"tally-4",102633494371890,"tally-5",88031817475886,
	"tangent",123263132981724,"target",87563802520297,"telescope",91755049143647,"tent-tree",76698322463977,"tent",109779587826330,"terminal",106783148545356,
	"test-tube-diagonal",75662704378840,"test-tube",98801015650164,"test-tubes",92555361447433,"text-align-center",84051028246390,"text-align-end",130041738343555,"text-align-justify",80279880143030,
	"text-align-start",134489585487649,"text-cursor-input",107551944047171,"text-cursor",115984654447300,"text-initial",129458097472087,"text-quote",139278366448736,"text-search",92345384671606,
	"text-select",117087320884956,"text-wrap",114804318314018,"theater",108558145549163,"thermometer-snowflake",121876188028425,"thermometer-sun",106693240074310,"thermometer",106546011492311,
	"thumbs-down",87794009914015,"thumbs-up",111137070767020,"ticket-check",105428777212507,"ticket-minus",78966299769328,"ticket-percent",80834774406405,"ticket-plus",110086734392189,
	"ticket-slash",89045681172265,"ticket-x",88674114109926,"ticket",126527071492145,"tickets-plane",100367018248695,"tickets",135268612687833,"timer-off",110916370767271,
	"timer-reset",110052125369932,"timer",85473888890506,"toggle-left",85887872573050,"toggle-right",90411952142550,"toilet",80930782432931,"tool-case",87533537832522,
	"tornado",88358291515768,"torus",70855707283051,"touchpad-off",78784008075456,"touchpad",74882354908014,"tower-control",95937619060532,"toy-brick",86293483924633,
	"tractor",103376704722051,"traffic-cone",74110220470369,"train-front-tunnel",105194827005114,"train-front",125237934215370,"train-track",77451032453723,"tram-front",93315182364998,
	"transgender",135530817673639,"trash-2",109843431391323,"trash",106723740584310,"tree-deciduous",123124389219004,"tree-palm",103846705893963,"tree-pine",124662547202594,
	"trees",121203841375919,"trello",130987241149527,"trending-down",139309232226438,"trending-up-down",85083293981691,"trending-up",81819858538839,"triangle-alert",125920361880643,
	"triangle-dashed",124324079103935,"triangle-right",116930791412791,"triangle",126330486745540,"trophy",131545003268773,"truck-electric",111873446387359,"truck",86662707764771,
	"turkish-lira",114589876174070,"turntable",129870346487856,"turtle",118295081560334,"tv-minimal-play",99201833426972,"tv-minimal",100382201729427,"tv",135687724791776,
	"twitch",71383308134888,"twitter",88791703276842,"type-outline",80108627791690,"type",133543553793564,"umbrella-off",72395143739955,"umbrella",127502210274589,
	"underline",123709229216544,"undo-2",113885292059932,"undo-dot",132055277744844,"undo",111258459077271,"unfold-horizontal",117128358526398,"unfold-vertical",116593025265499,
	"ungroup",106674800451003,"university",84652528263642,"unlink-2",128131898892572,"unlink",139835795227752,"unplug",90171381619874,"upload",138212042425501,
	"usb",117230058949613,"user-check",81775205032725,"user-cog",92795491530865,"user-lock",78892639693821,"user-minus",126976941957511,"user-pen",87445472574836,
	"user-plus",118514469915884,"user-round-check",118794737621941,"user-round-cog",78239503290053,"user-round-minus",98944176636447,"user-round-pen",108155244324878,"user-round-plus",113301899567470,
	"user-round-search",71565774381870,"user-round-x",122367980560930,"user-round",136485052187963,"user-search",101335649828115,"user-star",98777846316000,"user-x",139748155894754,
	"user",81589895647169,"users-round",103005444008339,"users",115398113982385,"utensils-crossed",109520762270383,"utensils",139952569804235,"utility-pole",101965541238242,
	"variable",104743088438151,"vault",108049164599845,"vector-square",86713728565344,"vegan",119489190688082,"venetian-mask",102636443033920,"venus-and-mars",120227752103771,
	"venus",82891342220859,"vibrate-off",113446447326246,"vibrate",108330910738733,"video-off",132239189859305,"video",107587444636945,"videotape",114816894323398,
	"view",118717253976805,"voicemail",134313454010227,"volleyball",83889351124153,"volume-1",98514588731639,"volume-2",89344380902620,"volume-off",103047478058767,
	"volume-x",139252359189540,"volume",103236289817396,"vote",89409762851246,"wallet-cards",129728715308337,"wallet-minimal",137800448816116,"wallet",132331555762628,
	"wallpaper",74682121235494,"wand-sparkles",82546429942392,"wand",114580617777835,"warehouse",78388887451080,"washing-machine",104194127573858,"watch",130544621618405,
	"waves-ladder",101808619355514,"waves",96340135183647,"waypoints",102450133666017,"webcam",104148487911129,"webhook-off",96370548093471,"webhook",112812457747322,
	"weight",103860559844854,"wheat-off",133294844612307,"wheat",85261952080359,"whole-word",90111083954485,"wifi-cog",110500263326209,"wifi-high",81954601342139,
	"wifi-low",138217335635913,"wifi-off",74113634330106,"wifi-pen",91290205064712,"wifi-sync",84043971055177,"wifi-zero",124286465246123,"wifi",104669375183960,
	"wind-arrow-down",127753987414870,"wind",114551690399915,"wine-off",108294164302317,"wine",115743721332829,"workflow",99186544029189,"worm",115752311548091,
	"wrench",112148279212860,"x",110786993356448,"youtube",123663668456341,"zap-off",81385483183652,"zap",130551565616516,"zoom-in",127956924984803,
	"zoom-out",108334162607319,"balloon",97489111621526,"beef-off",99869959725200,"book-search",132585409504950,"calendars",130944763042289,"cannabis-off",101938500363812,
	"cctv-off",75925370187295,"cigarette",137149549886852,"circle-pile",116353155251541,"cloud-backup",111649579696132,"cloud-sync",79393911188593,"database-search",92017137080138,
	"ellipse",71559658267482,"fingerprint-pattern",80934710831288,"fishing-hook",121038780855899,"fishing-rod",71754848048049,"form",72999643971000,"git-merge-conflict",85677801675703,
	"globe-off",77775243585824,"globe-x",109268097029296,"hd",71682790698278,"image",112751259236831,"layers-plus",77587765623057,"lens-concave",94819631937027,
	"lens-convex",74736504195474,"line-dot-right-horizontal",104718593155221,"line-style",90176717785772,"map-pin-search",89065012915078,"message-circle-check",132772297689418,"message-square-check",125789987055668,
	"metronome",101991829345965,"mirror-rectangular",109046769760336,"mirror-round",121534049429097,"mouse-left",99144293708743,"mouse-right",88331710212594,"printer-x",103002721801548,
	"radio-off",80359258046586,"road",120251329173530,"scooter",100035452787934,"search-alert",127597984617505,"shelving-unit",80116568514793,"shield-cog-corner",111694066132698,
	"shield-cog",129235695057857,"sport-shoe",120495992692630,"square-arrow-right-enter",138867831495334,"square-arrow-right-exit",133688575845430,"square-centerline-dashed-horizontal",77780104374341,"square-centerline-dashed-vertical",107878435803525,
	"stone",135161057497830,"toolbox",85341033903792,"towel-rack",125223915620991,"user-key",105403041782190,"user-round-key",124547549008939,"van",122066377022942,
	"waves-arrow-down",129215220911792,"waves-arrow-up",102314705716217,"weight-tilde",112081212176951,"x-line-top",140592656289509,"zodiac-aquarius",74560047770362,"zodiac-aries",73255859670234,
	"zodiac-cancer",131985162532947,"zodiac-capricorn",97859568140652,"zodiac-gemini",80997588122992,"zodiac-leo",75509406718106,"zodiac-libra",113222735060218,"zodiac-ophiuchus",129180108892480,
	"zodiac-pisces",95845819440327,"zodiac-sagittarius",82651026742181,"zodiac-scorpio",113640924054631,"zodiac-taurus",123053219704400,"zodiac-virgo",99462994613661,
}
end

__modules["inbox"] = function()
-- Notification history: a bell in the window header (left of minimize) with an unread dot; it opens a list of
-- the last 50 notifications. CreateWindow({ NotificationHistory = false }) leaves it out.
--   Window:OpenInbox(), Window:ClearInbox()
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label
local HEADER = 44

return function(Window)
    function Window:_buildInbox()
        if self.cfg.NotificationHistory == false then return end
        local Lib = self.Lib
        local button = self._windowButton("Inbox", self:_headerSlot(), false, true)
        -- bell drawn from frames: dome, rim, clapper (no glyphs / images needed)
        local parts = {}
        local function part(props, radius)
            local object = create("Frame", props)
            object.BorderSizePixel = 0
            object.Parent = button
            if radius then corner(object, radius) end
            Theme.bind(object, "BackgroundColor3", "muted")
            parts[#parts + 1] = object
            return object
        end
        part({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(8, 9) }, 4)
        part({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 15), Size = UDim2.fromOffset(12, 2) }, 1)
        part({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 18), Size = UDim2.fromOffset(3, 2) }, 1)
        local dot = create("Frame", { Name = "Unread", Position = UDim2.new(0.5, 3, 0, 6), Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, Visible = false, ZIndex = 3, Parent = button })
        corner(dot, 3)
        Theme.bind(dot, "BackgroundColor3", "accent")
        Theme.bind(stroke(dot, nil, 0, 1.5), "Color", "base")
        button.MouseEnter:Connect(function() for _, p in ipairs(parts) do Theme.tweenTo(p, "BackgroundColor3", "heading", 0.12) end end)
        button.MouseLeave:Connect(function() for _, p in ipairs(parts) do Theme.tweenTo(p, "BackgroundColor3", "muted", 0.12) end end)

        local seen = 0
        local panel
        local function unread()
            local history = Lib.NotifyHistory or {}
            local count = 0
            for _, entry in ipairs(history) do if entry.Time and entry._id and entry._id > seen then count = count + 1 end end
            return count
        end
        -- ids so "unread" survives the list being trimmed
        local nextId = 0
        local function stamp()
            for index = #(Lib.NotifyHistory or {}), 1, -1 do
                local entry = Lib.NotifyHistory[index]
                if not entry._id then nextId = nextId + 1 entry._id = nextId end
            end
        end
        local function close()
            if panel then panel:Destroy() panel = nil end
        end
        local function render()
            if not panel then return end
            local list = panel:FindFirstChild("List")
            for _, child in ipairs(list:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
            local history = Lib.NotifyHistory or {}
            panel:FindFirstChild("Empty").Visible = #history == 0
            for index, entry in ipairs(history) do
                local item = create("Frame", { Name = "Entry", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, entry.Content and 38 or 24), LayoutOrder = index, ZIndex = 232, Parent = list })
                local mark = create("Frame", { Position = UDim2.fromOffset(0, 5), Size = UDim2.new(0, 2, 1, -10), BorderSizePixel = 0, ZIndex = 233, Parent = item })
                corner(mark, 1)
                Theme.bind(mark, "BackgroundColor3", entry.Color or "accent")
                local entryIcon = entry.Icon and Icons.themed(item, entry.Icon, 12, "accent", { Position = UDim2.fromOffset(10, 5), ZIndex = 233 })
                if entryIcon and entry.Color then Theme.bind(entryIcon, "ImageColor3", entry.Color) end
                local title = label(item, entry.Title .. ((entry.Count or 1) > 1 and ("  ×" .. entry.Count) or ""), 10, { Position = UDim2.fromOffset(entryIcon and 28 or 10, 3), Size = UDim2.new(1, entryIcon and -82 or -64, 0, 16), Font = Enum.Font.GothamMedium, ZIndex = 233 })
                Theme.bind(title, "TextColor3", "heading")
                local time = label(item, Util.ago(entry.Time), 9, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 3), Size = UDim2.fromOffset(54, 16), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 233 })
                Theme.bind(time, "TextColor3", "muted")
                if entry.Content then
                    local content = label(item, entry.Content, 9, { Position = UDim2.fromOffset(entryIcon and 28 or 10, 19), Size = UDim2.new(1, entryIcon and -28 or -10, 0, 14), ZIndex = 233 })
                    Theme.bind(content, "TextColor3", "muted")
                end
            end
        end
        function self:OpenInbox()
            close()
            stamp()
            panel = create("Frame", {
                Name = "InboxPanel", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, HEADER - 4), Size = UDim2.fromOffset(270, 260),
                BorderSizePixel = 0, ZIndex = 230, Active = true, Parent = self.main,
            })
            Theme.bind(panel, "BackgroundColor3", "card")
            corner(panel, 8)
            Theme.bind(stroke(panel), "Color", "line")
            local heading = label(panel, "Notifications", 11, { Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -90, 0, 20), Font = Enum.Font.GothamMedium, ZIndex = 231 })
            Theme.bind(heading, "TextColor3", "heading")
            local clear = create("TextButton", {
                Name = "Clear", Text = "Clear", TextSize = 9, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BorderSizePixel = 0,
                AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 9), Size = UDim2.fromOffset(44, 18), ZIndex = 231, Parent = panel,
            })
            Theme.bind(clear, "BackgroundColor3", "input")
            Theme.bind(clear, "TextColor3", "text")
            corner(clear, 5)
            Theme.bind(stroke(clear), "Color", "buttonEdge")
            clear.Activated:Connect(function() self:ClearInbox() end)
            local line = create("Frame", { Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 1), BorderSizePixel = 0, ZIndex = 231, Parent = panel })
            Theme.bind(line, "BackgroundColor3", "line")
            local list = create("ScrollingFrame", {
                Name = "List", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(14, 40), Size = UDim2.new(1, -22, 1, -48),
                CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollingDirection = Enum.ScrollingDirection.Y,
                ZIndex = 231, Parent = panel,
            })
            Theme.bind(list, "ScrollBarImageColor3", "muted")
            Util.fadeScrollbar(list)
            Util.fitCanvas(list, Util.list(list, 2))
            local empty = label(panel, "No notifications yet", 10, { Name = "Empty", Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -48), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 231 })
            Theme.bind(empty, "TextColor3", "muted")
            render()
            seen = nextId
            dot.Visible = false
            self:_openPopup(panel, button, close)
        end
        function self:ClearInbox()
            Lib.NotifyHistory = {}
            render()
            dot.Visible = false
        end
        button.Activated:Connect(function()
            if panel then self:_closePopup() else self:OpenInbox() end
        end)
        Lib._historyListeners = Lib._historyListeners or {}
        local function listener()
            if not self.alive then return end
            stamp()
            if panel then render() seen = nextId else dot.Visible = unread() > 0 end
        end
        table.insert(Lib._historyListeners, listener)
        self.maid:give(function()
            local index = table.find(Lib._historyListeners, listener)
            if index then table.remove(Lib._historyListeners, index) end
        end)
        self.inboxButton = button
    end
end
end

__modules["init"] = function()
-- qustah-ui-lib: entry point. The build script bundles every module into dist/qustah-ui-lib.lua.
local Util = require("util")
local Theme = require("theme")
local Window = require("window")
local Notify = require("notify")
local Settings = require("settings")
local Dashboard = require("dashboard")
local Icons = require("icons")
local Sounds = require("sounds")
local Gate = require("gate")
require("status")(Window)
require("dialog")(Window)
require("hud")(Window)
require("inbox")(Window)
require("windowx")(Window)
require("windowfx")(Window)
require("kick")(Window)
require("mobile")(Window)
require("tour")(Window)

local Lib = {
    Version = "1.15.0",
    Flags = {},   -- Flag -> current value of every flagged element
    Windows = {},
    Theme = Theme,
    Icons = Icons, -- Lib.Icons.Get("house"), "solar:home-bold", Lib.Icons.SetDefault("solar")
    Sounds = Sounds, -- Lib.Sounds.Enabled = true, Lib.Sounds.Set("click", id)
    Haptics = require("haptics"), -- Lib.Haptics.Enabled (on for touch screens)
    Fonts = require("font"), -- Lib.Fonts.set("Quicksand"), Lib.Fonts.available()
    Loader = require("loader"), -- the download strip; Lib.Loader.enabled = false hides it
    Crosshair = require("crosshair"), -- Lib.Crosshair.Overlay({ Style = "X" }) - a crosshair on screen; card:CrosshairPreview()
    _glow = require("glow"), -- (tests)
    Util = Util,
}
Lib.maid = Util.maid()

-- Lib:CreateWindow({ Title, Version, Size = Vector2, ToggleKey = Enum.KeyCode, Accent = Color3, Folder, Footer, OnClose })
-- UIScale = false: no UI scale choice in Settings, always 100 % (sharpest).
-- With KeySystem the call waits until a key is accepted; closing the key screen stops the script.
function Lib:CreateWindow(cfg)
    cfg = cfg or {}
    if cfg.Secure then Util.secure = true end
    if type(cfg.KeySystem) == "table" and not Gate.run(self, cfg) then
        error("[qustah-ui-lib] no key entered - the script was stopped", 0)
    end
    return Window.new(self, cfg)
end
function Lib:ForgetKey(folder) Gate.forget(folder) end
-- Lib:Notify({ Title, Content, Duration, Color })
function Lib:Notify(cfg) return Notify.show(self, cfg) end
-- Lib:Toast("Saved") / Lib:Toast({ Text, Icon, Image, Color, Position = "Top" | "Bottom", Duration })
function Lib:Toast(cfg) return Notify.pill(self, cfg) end
Lib.MaxNotifications = 6
function Lib:SetAccent(color) Theme.set("accent", color) end
-- Any colour role: base, card, input, line, text, muted, heading, accent ...
function Lib:SetColor(role, color) Theme.set(role, color) end
function Lib:GetFlag(flag) return self.Flags[flag] end
-- Secure mode: random gui names, a silent console (also getgenv().QUSTAH_SECURE = true before loading)
function Lib:SetSecure(on) Util.secure = on ~= false end
function Lib:IsSecure() return Util.secure == true end
function Lib:Destroy()
    for index = #self.Windows, 1, -1 do self.Windows[index]:Destroy() end
    self.maid:clean()
end

-- (the built-in tabs keep their own flags: AutoFlags is off while they are built)
local function builtIn(window, build, cfg)
    window._noAutoFlags = true
    local ok, result = pcall(build, window, cfg)
    window._noAutoFlags = nil
    if not ok then error(result, 0) end
    return result
end
function Window:SettingsTab(cfg) return builtIn(self, Settings, cfg) end
function Window:DashboardTab(cfg) return builtIn(self, Dashboard, cfg) end

return Lib
end

__modules["kick"] = function()
-- Kick watcher: notices when the game disconnects you and says why.
--   Window:OnKick(function(info) end)   info = { Reason, Code, Kind, Message, Time }
--   Window:GetKicks()                    the last 20, newest first (saved in <Folder>/kicks.json)
--   Window.LastKick
-- CreateWindow({ KickLog = false }) turns it off; Rejoin = true teleports back to the same place after a kick.
-- It reads Roblox's own error prompt (GuiService), so it works for kicks from the server, anti-cheats and
-- connection drops alike.
local Util = require("util")

-- Roblox error codes that matter here
local KINDS = {
    [267] = "Kicked", [268] = "Unexpected client behaviour", [273] = "Logged in elsewhere", [274] = "Server shut down",
    [277] = "Connection lost", [278] = "Idle (AFK) disconnect", [279] = "Failed to connect", [282] = "Disconnected",
    [292] = "Game removed", [517] = "Server full", [524] = "Not allowed", [529] = "Service error", [600] = "Banned",
}

local function parse(message, code)
    message = tostring(message or "")
    code = tonumber(code) or tonumber(message:match("[Ee]rror [Cc]ode:?%s*(%d+)"))
    -- "You were kicked from this experience: <reason>" / "...game: <reason>"
    local reason = message:match("[Kk]icked from this [%a]+:%s*(.-)%s*%(?[Ee]rror [Cc]ode")
        or message:match("[Kk]icked from this [%a]+:%s*(.+)$")
        or message:match("^(.-)%s*%(?[Ee]rror [Cc]ode") or message
    reason = reason:gsub("%s+$", ""):gsub("^%s+", "")
    if reason == "" then reason = KINDS[code] or "Disconnected" end
    return { Reason = reason, Code = code, Kind = KINDS[code] or (code and ("Error " .. code)) or "Disconnected", Message = message, Time = os.time() }
end

return function(Window)
    Window._parseKick = parse

    function Window:OnKick(callback)
        self._kickListeners = self._kickListeners or {}
        table.insert(self._kickListeners, callback)
    end
    function Window:GetKicks()
        local data = self.Config:ReadJSON("kicks")
        return type(data.list) == "table" and data.list or {}
    end

    function Window:_kicked(message, code)
        local info = parse(message, code)
        -- the prompt and the error signal both report the same kick: keep one
        if self.LastKick and self.LastKick.Message == info.Message and os.time() - self.LastKick.Time < 10 then return end
        self.LastKick = info
        local list = self:GetKicks()
        table.insert(list, 1, { Reason = info.Reason, Code = info.Code, Kind = info.Kind, Time = info.Time, Place = game.PlaceId })
        while #list > 20 do table.remove(list) end
        self.Config:WriteJSON("kicks", { list = list })
        for _, listener in ipairs(self._kickListeners or {}) do self:_safe("OnKick", listener, info) end
        if self.cfg.Rejoin and info.Code ~= 273 and info.Code ~= 600 then
            task.delay(tonumber(self.cfg.RejoinDelay) or 2, function()
                pcall(function() Util.Services.TeleportService:Teleport(game.PlaceId, Util.Services.Players.LocalPlayer) end)
            end)
        end
    end

    function Window:_watchKicks()
        if self.cfg.KickLog == false then return end
        local GuiService = Util.Services.GuiService
        pcall(function()
            self.maid:connect(GuiService.ErrorMessageChanged, function(message)
                if not message or message == "" then return end
                local code
                pcall(function() code = GuiService:GetErrorCode().Value end)
                self:_kicked(message, code)
            end)
        end)
        -- the error prompt itself (some executors see this before the signal)
        task.spawn(function()
            pcall(function()
                local prompt = Util.Services.CoreGui:FindFirstChild("RobloxPromptGui")
                local overlay = prompt and prompt:FindFirstChild("promptOverlay")
                if not overlay then return end
                self.maid:connect(overlay.ChildAdded, function(child)
                    if child.Name ~= "ErrorPrompt" then return end
                    task.wait(0.1)
                    local text = child:FindFirstChild("ErrorMessage", true)
                    if text and text.Text ~= "" then self:_kicked(text.Text) end
                end)
            end)
        end)
    end
end
end

__modules["loader"] = function()
-- Download strip: a thin pill at the top of the screen while the library downloads something (icon sheets, a
-- script's icon sheet) - "Qustāh  Downloading icons  ▬▬▬▭▭  62%". It only appears when a file is
-- really fetched (files already on disk show nothing) and fades out when everything is done.
-- Util.cacheFiles(files, done, fail, "icons") drives it; Loader.title is set by the first window (or setTitle).
local Util = require("util")
local Theme = require("theme")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label
local Loader = { jobs = {}, title = nil, enabled = true }
local ui -- { gui, pill, title, text, fill, percent, spinner }
local spin

local genv = (getgenv and getgenv()) or _G
-- a strip an earlier run left on screen (it was unloaded or broke mid-download) goes at once, not only when this
-- run downloads something: with every file already on disk this run never builds one and the old one stayed
if genv.__QustahLoaderGui then
    pcall(function() genv.__QustahLoaderGui:Destroy() end)
    genv.__QustahLoaderGui = nil
end
-- a job never ends later than this (a download that hangs past Util.downloadTimeout, a callback that broke)
local JOB_LIMIT = 45
local function build()
    -- a strip left by an earlier run of the script (a download that never finished there) goes first
    if genv.__QustahLoaderGui then pcall(function() genv.__QustahLoaderGui:Destroy() end) end
    local gui = Util.screenGui("QustahUI_Loading", 65)
    genv.__QustahLoaderGui = gui
    pcall(function() require("font").register(gui) end)
    local pill = create("Frame", {
        Name = "Loading", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 26), Size = UDim2.fromOffset(0, 34),
        AutomaticSize = Enum.AutomaticSize.X, BorderSizePixel = 0, Parent = gui,
    })
    pill:SetAttribute("QFadedOut", true)
    Theme.bind(pill, "BackgroundColor3", "base")
    corner(pill, 17)
    Theme.bind(stroke(pill), "Color", "line")
    local row = create("Frame", { Name = "Row", BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), Parent = pill })
    Util.list(row, 10, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    Util.padding(row, 12, 16, 0, 0)
    local spinner = require("icons").themed(row, "loader-circle", 14, "muted", { Name = "Spinner", LayoutOrder = 1 })
    local title = label(row, "", 11, { Name = "Title", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 34), TextTruncate = Enum.TextTruncate.None, Font = Enum.Font.GothamBold, LayoutOrder = 2 })
    Theme.bind(title, "TextColor3", "heading")
    local text = label(row, "", 10, { Name = "Text", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 34), TextTruncate = Enum.TextTruncate.None, LayoutOrder = 3 })
    Theme.bind(text, "TextColor3", "muted")
    local track = create("Frame", { Name = "Track", Size = UDim2.fromOffset(110, 3), BorderSizePixel = 0, LayoutOrder = 4, Parent = row })
    Theme.bind(track, "BackgroundColor3", "input")
    corner(track, 2)
    local fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = track })
    Theme.bind(fill, "BackgroundColor3", "accent")
    corner(fill, 2)
    local percent = label(row, "", 10, { Name = "Percent", Size = UDim2.fromOffset(30, 34), TextXAlignment = Enum.TextXAlignment.Right, LayoutOrder = 5 })
    Theme.bind(percent, "TextColor3", "muted")
    pill.Visible = false
    ui = { gui = gui, pill = pill, title = title, text = text, fill = fill, percent = percent, spinner = spinner }
end

local building = false
local function render()
    if not Loader.enabled then return end
    local active = #Loader.jobs > 0
    -- (building the strip draws its spinner icon, which can start the lucide sheets' download: a second job that
    -- renders again. Built twice, the first strip was destroyed but kept as `ui`, and the second one sat on screen
    -- at 0 % forever. The inner render now waits for the build; the outer one shows both jobs.)
    if active and not ui then
        if building then return end
        building = true
        local ok, err = pcall(build)
        building = false
        if not ok then Util.log("[qustah-ui-lib] download strip: " .. tostring(err)) return end
    end
    if not ui then return end
    if active then
        local share = Loader.share()
        local newest = Loader.jobs[#Loader.jobs]
        ui.title.Text = Loader.title or "Loading"
        ui.text.Text = "Downloading " .. newest.label
        ui.percent.Text = math.floor(share * 100 + 0.5) .. "%"
        Util.tween(ui.fill, 0.2, { Size = UDim2.fromScale(math.max(share, 0.04), 1) })
        if not ui.pill.Visible or ui.pill:GetAttribute("QFadedOut") then
            ui.pill.Visible = true
            Util.fadeTree(ui.pill, 0.18, 0)
        end
        -- (a connection something else cut - a reused library whose earlier window took its connections along - is
        -- made again, or the bar would sit frozen at 0 %)
        if spin and not spin.Connected then spin = nil end
        if not spin then
            spin = Util.Services.RunService.Heartbeat:Connect(function(dt)
                if not ui then return end
                if ui.spinner then ui.spinner.Rotation = (ui.spinner.Rotation + dt * 360) % 360 end
                -- jobs past their limit are dropped; with none left the strip goes (even if a finish was missed)
                for index = #Loader.jobs, 1, -1 do
                    if os.clock() - Loader.jobs[index].began > JOB_LIMIT then table.remove(Loader.jobs, index) end
                end
                if #Loader.jobs == 0 then
                    task.defer(render)
                    return
                end
                -- (the bar keeps moving while a file is still coming)
                if #Loader.jobs > 0 then
                    local now = Loader.share()
                    ui.percent.Text = math.floor(now * 100 + 0.5) .. "%"
                    ui.fill.Size = UDim2.fromScale(math.max(now, 0.04), 1)
                end
            end)
        end
    else
        Loader.visible = false
        if spin then spin:Disconnect() spin = nil end
        if ui.pill.Visible and not ui.pill:GetAttribute("QFadedOut") then
            ui.fill.Size = UDim2.fromScale(1, 1)
            ui.percent.Text = "100%"
            Util.fadeTree(ui.pill, 0.25, 1)
            task.delay(0.26, function() if ui and #Loader.jobs == 0 then ui.pill.Visible = false end end)
        end
        return
    end
    Loader.visible = true
end

-- How far the downloads are (0-1): the files done, plus a guess for the ones still coming that grows with time
-- (up to 90% of a file) - one big file no longer sits at 0% until it is all there.
function Loader.share()
    local done, total = 0, 0
    local now = os.clock()
    for _, job in ipairs(Loader.jobs) do
        local coming = job.total - job.done
        local guess = coming > 0 and coming * 0.9 * (1 - math.exp(-(now - job.began) / 4)) or 0
        done, total = done + job.done + guess, total + job.total
    end
    return total > 0 and math.min(done / total, 1) or 0
end

-- A download of `total` files: job:step() after each one, job:finish() at the end (done or failed).
function Loader.start(what, total)
    local job = { label = tostring(what), total = math.max(1, total or 1), done = 0, began = os.clock() }
    function job.step() job.done = math.min(job.total, job.done + 1) render() end
    function job.finish()
        local index = table.find(Loader.jobs, job)
        if index then table.remove(Loader.jobs, index) end
        render()
    end
    Loader.jobs[#Loader.jobs + 1] = job
    render()
    return job
end

-- Yields until every download is done (or `seconds` have passed): a script can keep its window back until its
-- icons are there - Lib.Loader.Wait(30) before CreateWindow. Returns true when nothing is downloading any more.
function Loader.Wait(seconds)
    local started = os.clock()
    while #Loader.jobs > 0 and os.clock() - started < (tonumber(seconds) or 30) do task.wait(0.1) end
    return #Loader.jobs == 0
end
-- drops every job and hides the strip (the script unloads)
function Loader.clear()
    table.clear(Loader.jobs)
    render()
end

-- the first window's title (shown in the strip)
function Loader.setTitle(text)
    Loader.title = text
    if ui and #Loader.jobs > 0 then ui.title.Text = text end
end

return Loader
end

__modules["mobile"] = function()
-- Mobile reopen button: while the menu is hidden a small pill (logo + title) stays on screen; tap it to open the
-- menu again, drag it anywhere (the spot is remembered). Phones have no RightShift.
--   CreateWindow({ MobileButton = "Auto" | true | false })   "Auto" (default): touch screens without a keyboard
--   Window:SetMobileButton(on)
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

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
            Util.fadeTree(pill, 0.18, 0)
        else
            Util.fadeTree(pill, 0.12, 1)
            task.delay(0.13, function()
                if pill.Parent and not (self.mobileButton and self.alive and not self.visible) then pill.Visible = false end
            end)
        end
    end

    function Window:_makePill()
        local pill = create("Frame", {
            Name = "MobileButton", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 40), BorderSizePixel = 0,
            Visible = false, ZIndex = 80, Parent = self.gui,
        })
        pill:SetAttribute("QFadedOut", true)
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
end

__modules["notify"] = function()
-- Toast notifications, bottom-right: Lib:Notify({ Title, Content, Duration }).
-- Without Duration the time follows the text length (3-10 s). Hovering a toast pauses its timer
-- (PauseOnHover = false turns that off). At most Lib.MaxNotifications (6) are shown; the oldest makes room.
-- Lib:Toast("Saved") / Lib:Toast({ Text, Icon, Image, Color, Position = "Top" | "Bottom", Duration }): a small pill
-- at the top (or bottom) centre for quick confirmations.
local Util = require("util")
local Theme = require("theme")
local UIFont = require("font")
local Icons = require("icons")

local create, corner, stroke, label, tween = Util.create, Util.corner, Util.stroke, Util.label, Util.tween

local Notify = {}

function Notify.holder(Lib)
    if Lib._notifyHolder and Lib._notifyHolder.Parent then return Lib._notifyHolder end
    local gui = Util.screenGui("QustahUI_Notifications", 60)
    Lib.maid:give(gui)
    UIFont.register(gui, Lib.maid)
    local holder = create("Frame", {
        Name = "Toasts", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 250, 1, -32), Parent = gui,
    })
    Util.list(holder, 6, nil, nil, Enum.VerticalAlignment.Bottom)
    Lib._notifyHolder = holder
    return holder
end

function Notify.show(Lib, cfg)
    if type(cfg) == "string" then cfg = { Title = cfg } end
    cfg = cfg or {}
    local holder = Notify.holder(Lib)
    -- the same simple notification again while it is still open: it counts up ("×3") instead of stacking
    -- (Merge = false turns this off; toasts with buttons / progress never merge)
    local simple = cfg.Merge ~= false and not (type(cfg.Buttons) == "table" and #cfg.Buttons > 0) and cfg.Progress == nil and cfg.Steps == nil and cfg.Persist ~= true
    local mergeKey = simple and (tostring(cfg.Title or "") .. "\0" .. tostring(cfg.Content or "")) or nil
    if mergeKey then
        for _, item in ipairs(Lib._openToasts or {}) do
            if item.key == mergeKey and item.handle and item.handle:IsOpen() then
                item.bump()
                local last = Lib.NotifyHistory and Lib.NotifyHistory[1]
                if last and last.Title == tostring(cfg.Title or "") and last.Content == (cfg.Content and tostring(cfg.Content) or nil) then
                    last.Count = (last.Count or 1) + 1
                    last.Time = os.time()
                    for _, listener in ipairs(Lib._historyListeners or {}) do Util.safe(listener) end
                end
                return item.handle
            end
        end
    end
    require("haptics").Play("notify")
    -- history (the bell in the window header); History = false keeps a toast out of it
    if cfg.History ~= false then
        Lib.NotifyHistory = Lib.NotifyHistory or {}
        table.insert(Lib.NotifyHistory, 1, { Title = tostring(cfg.Title or ""), Content = cfg.Content and tostring(cfg.Content) or nil, Color = cfg.Color, Icon = cfg.Icon, Time = os.time() })
        while #Lib.NotifyHistory > 50 do table.remove(Lib.NotifyHistory) end
        for _, listener in ipairs(Lib._historyListeners or {}) do Util.safe(listener) end
    end
    Lib._toastOrder = (Lib._toastOrder or 0) + 1
    -- reading time: about 22 characters a second on top of a short base
    local length = #tostring(cfg.Title or "") + #tostring(cfg.Content or "")
    local duration = tonumber(cfg.Duration) or math.clamp(2.5 + length * 0.045, 3, 10)
    -- Progress = 0..1 / Steps = 5 (+ Step) / Persist = true: the toast stays until :Close() or the progress reaches the end
    local tracked = cfg.Progress ~= nil or cfg.Steps ~= nil or cfg.Persist == true
    local hasContent = (cfg.Content ~= nil and cfg.Content ~= "") or cfg.Steps ~= nil
    local buttons = type(cfg.Buttons) == "table" and #cfg.Buttons > 0 and cfg.Buttons or nil
    if buttons and not cfg.Duration then duration = math.max(duration, 6) end
    local textHeight = hasContent and 50 or 34
    local height = textHeight + (buttons and 32 or 0)
    -- a plain Frame (a CanvasGroup would draw it through a softer texture); Util.fadeTree fades its parts
    local toast = create("Frame", {
        Name = "Toast", Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, ClipsDescendants = true,
        LayoutOrder = Lib._toastOrder, Parent = holder,
    })
    Theme.bind(toast, "BackgroundColor3", "card")
    corner(toast, 8)
    Theme.bind(stroke(toast), "Color", "line")
    local marker = create("Frame", { Position = UDim2.fromOffset(12, 10), Size = UDim2.new(0, 3, 0, textHeight - 20), BorderSizePixel = 0, Parent = toast })
    corner(marker, 2)
    -- (inset from the rounded corners: a plain Frame clips square)
    local progress = create("Frame", { Position = UDim2.new(0, 8, 1, -2), Size = UDim2.new(1, -16, 0, 2), BorderSizePixel = 0, Parent = toast })
    corner(progress, 1)
    -- Color: a Color3 or a theme role ("danger", "success", "warning"); default the accent
    local tint = (typeof(cfg.Color) == "Color3" or type(cfg.Color) == "string") and cfg.Color or "accent"
    Theme.bind(marker, "BackgroundColor3", tint)
    Theme.bind(progress, "BackgroundColor3", tint)
    -- Icon = "name": icon in place of the bar (tinted with Color / the accent)
    local textX = 23
    local icon = cfg.Icon and Icons.Get(cfg.Icon) and Icons.Image(cfg.Icon, { Name = "ToastIcon", Size = UDim2.fromOffset(16, 16) })
    if icon then
        marker.Visible = false
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.Position = UDim2.new(0, 12, 0, textHeight / 2)
        Theme.bind(icon, "ImageColor3", tint)
        icon.Parent = toast
        textX = 36
    end
    local closeRoom = cfg.CanClose ~= false and 22 or 0
    local contentLabel
    local title = label(toast, tostring(cfg.Title or ""), 11, { Position = UDim2.fromOffset(textX, hasContent and 8 or 0), Size = UDim2.new(1, -textX - 9 - closeRoom, 0, hasContent and 17 or textHeight), Font = Enum.Font.GothamBold })
    Theme.bind(title, "TextColor3", "heading")
    if hasContent then
        contentLabel = label(toast, tostring(cfg.Content or ""), 10, { Name = "Content", Position = UDim2.fromOffset(textX, 25), Size = UDim2.new(1, -textX - 9 - closeRoom, 0, 16) })
        Theme.bind(contentLabel, "TextColor3", "muted")
    end
    local closed = false
    local timer
    local entry = { toast = toast, key = mergeKey, count = 1 }
    local function dismiss()
        if closed or not toast.Parent then return end
        closed = true
        if timer then timer:Disconnect() timer = nil end
        for index, item in ipairs(Lib._openToasts or {}) do if item == entry then table.remove(Lib._openToasts, index) break end end
        Util.fadeTree(toast, 0.25, 1)
        task.delay(0.27, function() if toast.Parent then toast:Destroy() end end)
    end
    entry.dismiss = dismiss
    -- too many on screen: the oldest one goes
    Lib._openToasts = Lib._openToasts or {}
    table.insert(Lib._openToasts, entry)
    local limit = math.max(1, tonumber(Lib.MaxNotifications) or 6)
    while #Lib._openToasts > limit do table.remove(Lib._openToasts, 1).dismiss() end -- (removed first: a toast whose gui is gone can't remove itself)
    -- small screens: as many as fit in the height (6 toasts don't fit on a phone)
    local room = Util.viewport().Y - 32
    local used = height
    for index = #Lib._openToasts - 1, 1, -1 do
        local item = Lib._openToasts[index]
        local h = item.toast.Parent and item.toast.Size.Y.Offset or 0
        if used + h + 6 > room then
            for _ = 1, index do table.remove(Lib._openToasts, 1).dismiss() end
            break
        end
        used = used + h + 6
    end
    local hovered = false
    toast.MouseEnter:Connect(function() hovered = true end)
    toast.MouseLeave:Connect(function() hovered = false end)
    -- CanClose (default true): a small x in the corner
    if cfg.CanClose ~= false then
        local close = create("TextButton", {
            Name = "Close", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(18, 18), Parent = toast,
        })
        for _, rotation in ipairs({ 45, -45 }) do
            local bar = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(9, 1.5), Rotation = rotation, BorderSizePixel = 0, Parent = close })
            Theme.bind(bar, "BackgroundColor3", "muted")
        end
        close.Activated:Connect(dismiss)
    end
    -- Buttons = { { Title = "Undo", Callback = fn, Style = "Primary" } }: a row under the text; a click closes the toast
    if buttons then
        local row = create("Frame", { Name = "Buttons", BackgroundTransparency = 1, Position = UDim2.new(0, textX, 0, textHeight - 4), Size = UDim2.new(1, -textX - 10, 0, 24), Parent = toast })
        Util.list(row, 6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
        for index, spec in ipairs(buttons) do
            local text = tostring(spec.Title or "OK")
            local button = create("TextButton", {
                Name = text, Text = text, TextSize = 9, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BorderSizePixel = 0,
                Size = UDim2.fromOffset(Util.textWidth(text, 9, Enum.Font.GothamMedium) + 20, 22), LayoutOrder = index, Parent = row,
            })
            corner(button, 6)
            local outline = stroke(button)
            if spec.Style == "Primary" or index == 1 then
                Theme.bind(button, "BackgroundColor3", "accentDeep")
                Theme.bind(button, "TextColor3", "accent")
                Theme.bind(outline, "Color", "accent")
                outline.Transparency = 0.5
            else
                Theme.bind(button, "BackgroundColor3", "input")
                Theme.bind(button, "TextColor3", "text")
                Theme.bind(outline, "Color", "buttonEdge")
            end
            button.Activated:Connect(function()
                Util.safe(spec.Callback)
                if spec.Close ~= false then dismiss() end
            end)
        end
    end
    Util.fadeTree(toast, 0.2, 0, true)

    -- Sound = true (a short built-in ping) or an asset id; Volume 0-1
    if cfg.Sound then
        pcall(function()
            local sound = Instance.new("Sound")
            sound.SoundId = cfg.Sound == true and "rbxasset://sounds/electronicpingshort.wav" or (tostring(cfg.Sound):match("^%d+$") and ("rbxassetid://" .. cfg.Sound) or tostring(cfg.Sound))
            sound.Volume = tonumber(cfg.Volume) or 0.4
            sound.Parent = Util.Services.SoundService
            sound:Play()
            task.delay(4, function() sound:Destroy() end)
        end)
    end

    -- the handle: a toast you can update (Progress / Steps) - it also answers like the Frame (toast.Parent, :FindFirstChild)
    local handle = { Frame = toast }
    local steps = tonumber(cfg.Steps)
    function handle:SetTitle(text) title.Text = tostring(text) end
    function handle:SetContent(text) if contentLabel then contentLabel.Text = tostring(text) end end
    function handle:SetProgress(value)
        value = math.clamp(tonumber(value) or 0, 0, 1)
        self.Progress = value
        tween(progress, 0.2, { Size = UDim2.new(value, -16 * value, 0, 2) })
        if value >= 1 then task.delay(1.2, dismiss) end
    end
    function handle:SetStep(step, text)
        step = tonumber(step) or 0
        self.Step = step
        if contentLabel then contentLabel.Text = string.format("%d/%d%s", math.min(step, steps or step), steps or step, text and ("  ·  " .. tostring(text)) or "") end
        if steps and steps > 0 then self:SetProgress(step / steps) end
    end
    function handle:Close() dismiss() end
    function handle:IsOpen() return not closed and toast.Parent ~= nil end

    if tracked then
        progress.Size = UDim2.new(0, 0, 0, 2)
        if steps then handle:SetStep(tonumber(cfg.Step) or 0, cfg.Content) elseif cfg.Progress then handle:SetProgress(cfg.Progress) end
    end
    -- countdown (paused while the mouse is over the toast); the bar shows the time left
    local remaining = duration
    -- a merged repeat: "×N" after the title and the time starts again
    function entry.bump()
        entry.count = entry.count + 1
        remaining = duration
        local muted = Util.toHex(Theme.get("muted"))
        local plain = tostring(cfg.Title or ""):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
        title.RichText = true
        title.Text = plain .. '  <font color="#' .. muted .. '">×' .. entry.count .. "</font>"
        local scale = toast:FindFirstChildOfClass("UIScale") or create("UIScale", { Parent = toast })
        scale.Scale = 1.03
        tween(scale, 0.18, { Scale = 1 })
    end
    if not tracked or cfg.Duration then
        timer = Util.Services.RunService.Heartbeat:Connect(function(dt)
            if closed then return end
            if hovered and cfg.PauseOnHover ~= false then return end
            remaining = remaining - (tonumber(dt) or 0)
            if not tracked then local f = math.clamp(remaining / duration, 0, 1) progress.Size = UDim2.new(f, -16 * f, 0, 2) end
            if remaining <= 0 then dismiss() end
        end)
    end
    function handle:GetCount() return entry.count end
    entry.handle = setmetatable(handle, {
        __index = function(_, key)
            local value = toast[key]
            if type(value) == "function" then return function(_, ...) return value(toast, ...) end end
            return value
        end,
    })
    return entry.handle
end

-------------------------------------------------------------------------------- pill toasts
function Notify.pillHolder(Lib, bottom)
    Lib._pillHolders = Lib._pillHolders or {}
    local key = bottom and "Bottom" or "Top"
    local existing = Lib._pillHolders[key]
    if existing and existing.Parent then return existing end
    local gui = Lib._pillGui
    if not gui or not gui.Parent then
        gui = Util.screenGui("QustahUI_Toasts", 61)
        Lib.maid:give(gui)
        UIFont.register(gui, Lib.maid)
        Lib._pillGui = gui
    end
    local holder = create("Frame", {
        Name = key, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, bottom and 1 or 0),
        Position = UDim2.new(0.5, 0, bottom and 1 or 0, bottom and -70 or 58), Size = UDim2.new(0, 420, 0, 120), Parent = gui,
    })
    Util.list(holder, 6, nil, Enum.HorizontalAlignment.Center, bottom and Enum.VerticalAlignment.Bottom or Enum.VerticalAlignment.Top)
    Lib._pillHolders[key] = holder
    return holder
end

function Notify.pill(Lib, cfg)
    if type(cfg) ~= "table" then cfg = { Text = tostring(cfg) } end
    local bottom = cfg.Position == "Bottom"
    local holder = Notify.pillHolder(Lib, bottom)
    Lib._pillOrder = (Lib._pillOrder or 0) + 1
    -- three at most: the oldest goes
    local open = {}
    for _, child in ipairs(holder:GetChildren()) do if child.Name == "Pill" and child:GetAttribute("Closing") ~= true then open[#open + 1] = child end end
    table.sort(open, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
    while #open >= 3 do
        local old = table.remove(open, 1)
        old:SetAttribute("Closing", true)
        Util.fadeTree(old, 0.15, 1)
        task.delay(0.16, function() if old.Parent then old:Destroy() end end)
    end
    local text = tostring(cfg.Text or cfg.Title or "")
    local pill = create("Frame", {
        Name = "Pill", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30), BorderSizePixel = 0,
        LayoutOrder = bottom and Lib._pillOrder or -Lib._pillOrder, Parent = holder, -- newest next to the edge
    })
    Theme.bind(pill, "BackgroundColor3", "card")
    corner(pill, 15)
    local tint = (typeof(cfg.Color) == "Color3" or type(cfg.Color) == "string") and cfg.Color or "accent"
    local edge = stroke(pill, nil, 0.35)
    Theme.bind(edge, "Color", cfg.Color and tint or "line")
    local row = create("Frame", { Name = "Row", BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), Parent = pill })
    Util.list(row, 7, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    Util.padding(row, cfg.Image and 4 or 12, 14, 0, 0)
    if cfg.Image then
        -- a picture in a circle (avatar: Image = Util.avatar(userId))
        local image = create("ImageLabel", { Name = "Image", BorderSizePixel = 0, Size = UDim2.fromOffset(22, 22), ScaleType = Enum.ScaleType.Crop, LayoutOrder = 1, Image = tostring(cfg.Image), Parent = row })
        Theme.bind(image, "BackgroundColor3", "input")
        corner(image, 11)
    elseif cfg.Icon and Icons.Get(cfg.Icon) then
        Icons.themed(row, cfg.Icon, 14, tint, { Name = "Icon", LayoutOrder = 1 })
    end
    local caption = label(row, text, 10, { Name = "Text", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30), Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2, RichText = true })
    Theme.bind(caption, "TextColor3", "heading")
    create("UISizeConstraint", { MaxSize = Vector2.new(320, 30), Parent = caption })

    local scale = create("UIScale", { Scale = 0.92, Parent = pill })
    Util.fadeTree(pill, 0.18, 0, true)
    tween(scale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
    local closed = false
    local function close()
        if closed or not pill.Parent then return end
        closed = true
        pill:SetAttribute("Closing", true)
        Util.fadeTree(pill, 0.2, 1)
        tween(scale, 0.2, { Scale = 0.94 })
        task.delay(0.22, function() if pill.Parent then pill:Destroy() end end)
    end
    task.delay(tonumber(cfg.Duration) or math.clamp(1.6 + #text * 0.04, 2, 6), close)
    local handle = { Frame = pill }
    function handle:SetText(value) caption.Text = tostring(value) end
    function handle:Close() close() end
    return handle
end

return Notify
end

__modules["profiles"] = function()
-- Settings › Profiles page (used by settings.lua).
--   Current   which profile is active, how many settings changed since it was loaded / saved, Save / Revert / Share
--   New       create from the current settings, or import a share code (QUSTAH1:...)
--   Saved     search, profile cards sorted by last use (Load on each); a card's "..." opens its tools under the
--             cards: note, rename / duplicate, Load, Overwrite, Autoload, Share, Delete. "Default" is locked and holds the values the script started with.
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label
local RED, GREEN, YELLOW = "danger", "success", "warning" -- theme roles

return function(window, page, defaults)
    local store = window.Config
    store.DefaultFlags = defaults
    local refresh, updateCurrent
    local open -- expanded row
    local query = ""

    local function meta() return store:ReadMeta() end
    local function touch(name, fields)
        local data = meta()
        data[name] = data[name] or {}
        for key, value in pairs(fields) do data[name][key] = value end
        store:WriteMeta(data)
    end
    local function copy(text, what)
        local clipboard = setclipboard or toclipboard
        if type(clipboard) == "function" and pcall(clipboard, text) then
            window:Notify({ Title = "Copied", Content = what .. " copied to clipboard" })
            return true
        end
        window:Notify({ Title = "Clipboard", Content = "setclipboard is not available", Color = RED })
        return false
    end

    ------------------------------------------------------------ feedback (toast)
    local function say(text, bad)
        window:Notify({
            Title = bad == true and "Profiles · error" or "Profiles", Content = tostring(text), Duration = 3,
            Icon = bad == true and "triangle-alert" or (bad == "warn" and "info" or "circle-check"),
            Color = bad == true and RED or (bad == "warn" and YELLOW or nil),
        })
    end

    ------------------------------------------------------------ actions
    local function loadProfile(name, locked)
        local function go()
            if locked then
                local failed = store:Apply(defaults)
                store:_setActive(nil, nil)
                say(failed > 0 and (failed .. " setting(s) could not be reset") or "Default settings restored", failed > 0)
            else
                local ok, err = store:Load(name)
                if ok then touch(name, { used = os.time() }) end
                say(ok and (err or ("Loaded \"" .. name .. "\"")) or err, not ok)
            end
            refresh()
        end
        local changes = store:Changes()
        if changes > 0 then
            window:Confirm("Load \"" .. name .. "\"?", string.format("%d unsaved change%s in \"%s\" will be lost.", changes, changes == 1 and "" or "s", store.Active or "Default"), go, "Load")
        else
            go()
        end
    end
    local function saveProfile(name)
        local ok, err = store:Save(name)
        if ok then touch(name, { saved = os.time(), used = os.time() }) end
        say(ok and ("Saved \"" .. name .. "\"") or err, not ok)
        refresh()
        return ok
    end

    ------------------------------------------------------------ current
    local current = page:Card({ Title = "Current", Icon = "bookmark" })
    local activeInfo = current:Info({ Title = "Profile", Value = "Default" })
    local changesInfo = current:Info({ Title = "Changes", Value = "--" })
    local bar = create("Frame", { Name = "CurrentActions", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = current:_order(), Parent = current.body })
    Util.list(bar, 6, Enum.FillDirection.Horizontal)

    local ICONS = {
        Save = "save", Revert = "rotate-ccw", ["Share current"] = "share-2", ["What changed?"] = "list-checks",
        Load = "download", Overwrite = "upload", Autoload = "star", ["Autoload off"] = "star-off", Share = "share-2",
        Delete = "trash-2", Rename = "pencil", Duplicate = "copy",
    }
    local function smallButton(parent, text, order, style)
        local iconName = ICONS[text]
        local button = create("TextButton", {
            Name = text, Text = text, TextSize = 9, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BorderSizePixel = 0,
            Size = UDim2.fromOffset(Util.textWidth(text, 9, Enum.Font.GothamMedium) + (iconName and 34 or 20), 22), LayoutOrder = order, Parent = parent,
        })
        -- icon + text centred together; both follow the button's TextColor3 (the button's own text is hidden)
        local icon = iconName and Icons.Image(iconName, { Name = "ButtonIcon", Size = UDim2.fromOffset(11, 11) })
        if icon then
            local content = create("Frame", { Name = "Content", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, Parent = button })
            Util.list(content, 5, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
            icon.LayoutOrder = 1
            icon.Parent = content
            local text_ = label(content, text, 9, { Name = "Label", Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, TextTruncate = Enum.TextTruncate.None, Font = Enum.Font.GothamMedium, LayoutOrder = 2 })
            button.TextTransparency = 1
            local function tint() icon.ImageColor3 = button.TextColor3 text_.TextColor3 = button.TextColor3 end
            button:GetPropertyChangedSignal("TextColor3"):Connect(tint)
            task.defer(tint)
        end
        corner(button, 6)
        local outline = stroke(button)
        if style == "Danger" then
            Theme.bind(button, "BackgroundColor3", "dangerDeep")
            Theme.bind(button, "TextColor3", "dangerText")
            Theme.bind(outline, "Color", "dangerEdge")
            outline.Transparency = 0.3
        elseif style == "Primary" then
            Theme.bind(button, "BackgroundColor3", "accentDeep")
            Theme.bind(button, "TextColor3", "accent")
            Theme.bind(outline, "Color", "accent")
            outline.Transparency = 0.5
        else
            Theme.bind(button, "BackgroundColor3", "input")
            Theme.bind(button, "TextColor3", "text")
            Theme.bind(outline, "Color", "buttonEdge")
        end
        button.MouseEnter:Connect(function() if style == nil then Theme.tweenTo(button, "BackgroundColor3", "hover", 0.1) end end)
        button.MouseLeave:Connect(function() if style == nil then Theme.tweenTo(button, "BackgroundColor3", "input", 0.1) end end)
        return button
    end

    local saveButton = smallButton(bar, "Save", 1, "Primary")
    saveButton.Activated:Connect(function()
        if store.Active then saveProfile(store.Active)
        else say("Default is locked - type a name under New profile and press Create", "warn") end
    end)
    smallButton(bar, "Revert", 2).Activated:Connect(function()
        local changes = store:Changes()
        if changes == 0 then return say("Nothing to revert") end
        window:Confirm("Revert " .. changes .. " change" .. (changes == 1 and "" or "s") .. "?", "Settings go back to \"" .. (store.Active or "Default") .. "\".", function()
            local failed = store:Apply(store.ActiveFlags or defaults)
            say(failed > 0 and (failed .. " setting(s) could not be reverted") or "Reverted", failed > 0)
            updateCurrent()
        end, "Revert")
    end)
    smallButton(bar, "Share current", 3).Activated:Connect(function()
        local code = store:Export(nil)
        if code then copy(code, "Share code") end
    end)
    smallButton(bar, "What changed?", 4).Activated:Connect(function()
        local count, names = store:Changes()
        if count == 0 then return say("No changes since \"" .. (store.Active or "Default") .. "\"") end
        -- flags -> element titles
        local titles = {}
        for _, flag in ipairs(names) do
            local element = window.flags[flag]
            titles[#titles + 1] = element and element.Title and tostring(element.Title) or flag
        end
        table.sort(titles)
        local shown = {}
        for index = 1, math.min(#titles, 12) do shown[index] = titles[index] end
        window:Dialog({
            Title = count .. " change" .. (count == 1 and "" or "s"),
            Content = table.concat(shown, ", ") .. (#titles > 12 and (" and " .. (#titles - 12) .. " more") or ""),
            Buttons = { { Title = "Close" } },
        })
    end)

    function updateCurrent()
        local name = store.Active
        activeInfo:Set(name or "Default")
        activeInfo:SetColor(name and "accent" or "text")
        local changes = store:Changes()
        if changes > 0 then
            changesInfo:Set(changes .. " unsaved")
            changesInfo:SetColor(YELLOW)
        else
            changesInfo:Set("Saved")
            changesInfo:SetColor(GREEN)
        end
    end

    ------------------------------------------------------------ new / import
    -- one card, two tabs in its header; each tab is a single field with the action inside it
    local newCard = page:Card({ Title = "New profile", Icon = "plus" })
    local sections = newCard:Tabs({ "From current", "From code" })
    local function count(flags) local n = 0 for _ in pairs(flags or {}) do n = n + 1 end return n end
    sections["From current"]:ActionInput({
        Name = "CreateProfile", Icon = "plus", Placeholder = "Profile name", Button = "Create",
        Hint = "Saves your current settings as a new profile",
        Validate = function(name)
            if name:lower() == "default" then return false, "\"Default\" is reserved" end
            if name:gsub("[%w_%- ]", "") ~= "" then return false, "Letters, numbers, spaces, - and _ only" end
            if store:Exists(name) then return false, "\"" .. name .. "\" already exists - open it and press Overwrite" end
            return true, "Saves " .. count(store:Snapshot()) .. " settings as \"" .. name .. "\""
        end,
        Callback = function(name)
            if saveProfile(name) then
                open = name
                say("Created \"" .. name .. "\"")
                refresh()
            end
        end,
    })
    sections["From code"]:ActionInput({
        Name = "ImportProfile", Icon = "import", Placeholder = "Paste a QUSTAH1: code", Button = "Import",
        Hint = "Get a code with Share on any profile",
        Validate = function(code)
            local name, flags = store:Decode(code)
            if not name then return false, flags end
            local target = store:FreeName(name)
            return true, "\"" .. name .. "\" · " .. count(flags) .. " settings" .. (target ~= name and (" → saved as \"" .. target .. "\"") or "")
        end,
        Callback = function(code)
            local name, flags, custom = store:Decode(code)
            if not name then return say(flags, true) end
            name = store:FreeName(name)
            local ok, err = store:SaveFlags(name, flags, custom)
            if not ok then return say(err, true) end
            touch(name, { saved = os.time(), note = "Imported" })
            open = name
            say("Imported as \"" .. name .. "\" - open it and press Load")
            refresh()
        end,
    })

    -- per-game profiles (each game gets its own list + autoload); remembered with the window
    newCard:Toggle({
        Title = "Separate profiles per game", Desc = "Each game keeps its own list and autoload", Icon = "gamepad-2",
        Default = store.perGame ~= nil,
        Callback = function(on)
            store:SetPerGame(on and "Game" or false)
            window.memory.perGame = on and "Game" or false
            window:_saveMemory()
            open = nil
            refresh()
            say(on and ("Profiles for this game (#" .. game.GameId .. ")") or "Shared profiles for all games")
        end,
    })

    ------------------------------------------------------------ saved list
    local listCard = page:Card({ Title = "Saved", Icon = "folder-open" })
    local search = create("TextBox", {
        Name = "Search", Text = "", PlaceholderText = "Search profiles...", TextSize = 10, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 26), LayoutOrder = listCard:_order(), Parent = listCard.body,
    })
    Theme.bind(search, "BackgroundColor3", "input")
    Theme.bind(search, "TextColor3", "text")
    Theme.bind(search, "PlaceholderColor3", "muted")
    corner(search, 6)
    Theme.bind(stroke(search), "Color", "buttonEdge")
    Util.padding(search, 9, 9, 0, 0)
    local holder = create("Frame", { Name = "ProfileList", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = listCard:_order(), Parent = listCard.body })
    Util.list(holder, 4)
    local empty = listCard:Label("")

    -- the profiles as cards (ItemCards): a "..." on a card opens its tools under the grid
    local PALETTE = { Color3.fromRGB(232, 232, 236), Color3.fromRGB(74, 157, 224), Color3.fromRGB(94, 196, 110), Color3.fromRGB(232, 110, 176),
        Color3.fromRGB(226, 177, 90), Color3.fromRGB(160, 125, 232), Color3.fromRGB(79, 200, 216), Color3.fromRGB(224, 106, 106) }
    local function colorOf(name)
        if name == "Default" then return PALETTE[1] end
        local sum = 0
        for i = 1, #name do sum = sum + string.byte(name, i) end
        return PALETTE[2 + sum % (#PALETTE - 1)]
    end
    local cards = listCard:ItemCards({ Columns = 2, Height = 92,
        OnAction = function(item) loadProfile(item.Title, item.Locked) end,
        OnMenu = function(item) open = open ~= item.Title and item.Title or nil refresh() end,
    })
    holder.LayoutOrder = listCard:_order() -- (the tools of the open profile come under the cards)
    if empty.Row then empty.Row.LayoutOrder = listCard:_order() end

    -- the open profile's tools (note, rename / duplicate, Load, Overwrite, Autoload, Share, Delete)
    local function profileRow(name, order, locked, autoload, info)
        if open ~= name then return end
        local frame = create("Frame", { Name = "Profile_" .. name, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, LayoutOrder = order, Parent = holder })
        Theme.bind(frame, "BackgroundColor3", "selected")
        corner(frame, 6)
        Theme.bind(stroke(frame), "Color", "buttonEdge")
        Util.list(frame, 0)
        local note = info and info.note and tostring(info.note) or nil
        local head = create("TextButton", { Name = "Head", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 1, Parent = frame })
        local title = label(head, name, 11, { Name = "Name", Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -40, 1, 0), Font = Enum.Font.GothamMedium })
        Theme.bind(title, "TextColor3", "heading")
        Icons.themed(head, "x", 12, "muted", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0) })
        head.Activated:Connect(function() open = nil refresh() end)

        local actions = create("Frame", { Name = "Actions", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = frame })
        Util.padding(actions, 12, 12, 0, 10)
        Util.list(actions, 6)
        if not locked then
            -- what this profile would change
            local flags = store:Read(name)
            local differs = flags and store:Changes(flags) or 0
            local summary = label(actions, flags and (differs == 0 and "Same as your current settings" or (differs .. (differs == 1 and " setting differs" or " settings differ") .. " from your current settings")) or "File could not be read", 9, {
                Name = "Summary", Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 0,
            })
            Theme.bind(summary, "TextColor3", "muted")
        end

        local function box(name_, placeholder, order_, width)
            local object = create("TextBox", {
                Name = name_, Text = "", PlaceholderText = placeholder, TextSize = 10, Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, BorderSizePixel = 0, Size = width, LayoutOrder = order_,
            })
            Theme.bind(object, "BackgroundColor3", "base")
            Theme.bind(object, "TextColor3", "text")
            Theme.bind(object, "PlaceholderColor3", "muted")
            corner(object, 6)
            Util.padding(object, 8, 8, 0, 0)
            return object
        end
        -- note
        if not locked then
            local noteBox = box("Note", "Add a note (e.g. ranked, low graphics)", 1, UDim2.new(1, 0, 0, 24))
            noteBox.Text = note or ""
            noteBox.Parent = actions
            noteBox.FocusLost:Connect(function()
                local text = noteBox.Text:gsub("^%s+", ""):gsub("%s+$", ""):sub(1, 60)
                touch(name, { note = text ~= "" and text or false })
                refresh()
            end)
        end
        -- name box: Rename / Duplicate
        local nameRow = create("Frame", { Name = "NameRow", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 2, Parent = actions })
        local nameBox = box("NewName", locked and "name for the copy" or "new name", 1, UDim2.new(1, locked and -90 or -176, 1, 0))
        nameBox.Parent = nameRow
        local side = create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, locked and 84 or 170, 1, 0), Parent = nameRow })
        Util.list(side, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right)
        local function typed()
            local text = nameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
            if text == "" then say("Type a name in the box", true) return nil end
            if text:lower() == "default" then say("\"Default\" is reserved", true) return nil end
            return text
        end
        if not locked then
            smallButton(side, "Rename", 1).Activated:Connect(function()
                local new = typed()
                if not new then return end
                local ok, err = store:Rename(name, new)
                if ok then local m = meta() m[new], m[name] = m[name], nil store:WriteMeta(m) open = new end
                say(ok and ("Renamed to \"" .. new .. "\"") or err, not ok)
                refresh()
            end)
        end
        smallButton(side, "Duplicate", 2).Activated:Connect(function()
            local new = typed()
            if not new then return end
            local ok, err
            if store:Exists(new) then ok, err = false, "A profile with that name exists"
            elseif locked then ok, err = store:SaveFlags(new, defaults)
            else ok, err = store:Copy(name, new) end
            if ok then touch(new, { saved = os.time(), note = "Copy of " .. name }) open = new end
            say(ok and ("Copied to \"" .. new .. "\"") or (err or "Copy failed"), not ok)
            refresh()
        end)

        local buttons = create("Frame", { Name = "Buttons", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, Parent = actions })
        local flow = Util.list(buttons, 6, Enum.FillDirection.Horizontal)
        pcall(function() flow.Wraps = true end)
        smallButton(buttons, "Load", 1, "Primary").Activated:Connect(function() loadProfile(name, locked) end)
        if not locked then
            smallButton(buttons, "Overwrite", 2).Activated:Connect(function()
                window:Confirm("Overwrite \"" .. name .. "\"?", "It will hold your current settings.", function() saveProfile(name) end, "Overwrite")
            end)
            smallButton(buttons, autoload and "Autoload off" or "Autoload", 3).Activated:Connect(function()
                if autoload then store:ClearAutoLoad() say("Autoload off")
                else store:SetAutoLoad(name) say("\"" .. name .. "\" loads on start") end
                refresh()
            end)
        end
        smallButton(buttons, "Share", 4).Activated:Connect(function()
            local code = locked and ("QUSTAH1:" .. Util.base64encode(Util.Services.HttpService:JSONEncode({ n = "Default", f = defaults }))) or store:Export(name)
            if code then copy(code, "Share code for \"" .. name .. "\"") end
        end)
        if not locked then
            smallButton(buttons, "Delete", 6, "Danger").Activated:Connect(function()
                window:Confirm("Delete \"" .. name .. "\"?", "This cannot be undone.", function()
                    local ok, err = store:Delete(name)
                    if ok then
                        local m = meta() m[name] = nil store:WriteMeta(m)
                        if store:GetAutoLoad() == name then store:ClearAutoLoad() end
                        open = nil
                    end
                    say(ok and ("Deleted \"" .. name .. "\"") or err, not ok)
                    refresh()
                end, "Delete", true)
            end)
        end
    end

    function refresh()
        for _, child in ipairs(holder:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
        local auto = store:GetAutoLoad()
        local data = meta()
        local names = {}
        for _, name in ipairs(store:List()) do if name:lower() ~= "default" then names[#names + 1] = name end end
        -- most recently used / saved first
        table.sort(names, function(a, b)
            local ta = data[a] and (data[a].used or data[a].saved) or 0
            local tb = data[b] and (data[b].used or data[b].saved) or 0
            if ta ~= tb then return ta > tb end
            return a:lower() < b:lower()
        end)
        local q = query:lower()
        local shown = 0
        local items = {}
        local function add(name, locked, autoload, info)
            local active = (locked and store.Active == nil) or store.Active == name
            local badges = {}
            if active then badges[#badges + 1] = { Text = "ACTIVE", Role = "success" } end
            if autoload then badges[#badges + 1] = "AUTO" end
            if locked then badges[#badges + 1] = "LOCKED" end
            local when = info and (info.saved or info.used)
            local count = 0
            if not locked then local flags = store:Read(name) for _ in pairs(flags or {}) do count = count + 1 end end
            items[#items + 1] = {
                Title = name, Locked = locked, Color = colorOf(name), Badges = badges, Action = "Load", Highlight = active or open == name,
                Sub = (when and os.date("%d %b", when) or (locked and "starting values" or "")) .. (count > 0 and (" · " .. count .. " settings") or ""),
                Desc = info and info.note and tostring(info.note) or (locked and "The values the script started with" or ""),
            }
            profileRow(name, #items, locked, autoload, info)
            shown = shown + 1
        end
        if q == "" or ("default"):find(q, 1, true) then add("Default", true, auto == nil, nil) end
        for _, name in ipairs(names) do
            local info = data[name]
            local note = info and info.note and tostring(info.note):lower() or ""
            if q == "" or name:lower():find(q, 1, true) or note:find(q, 1, true) then add(name, false, auto == name, info) end
        end
        cards:SetItems(items)
        search.Visible = #names > 3 or q ~= ""
        empty:Set(#names == 0 and "No saved profiles yet - create one above." or (shown == 0 and "No profile matches \"" .. query .. "\"" or ""))
        empty:SetVisible(#names == 0 or shown == 0)
        updateCurrent()
    end
    search:GetPropertyChangedSignal("Text"):Connect(function() query = search.Text refresh() end)
    store:OnActiveChanged(function() if page.frame.Visible then refresh() end end)
    refresh()
    -- files may change outside the menu - re-read when the page is shown; the change counter ticks while it is open
    page.frame:GetPropertyChangedSignal("Visible"):Connect(function() if page.frame.Visible then refresh() end end)
    task.spawn(function()
        while window.alive do
            if window.visible and page.frame.Visible then updateCurrent() end
            task.wait(1)
        end
    end)
    return { refresh = refresh }
end
end

__modules["settings"] = function()
-- Window:SettingsTab({ Title, Icon, Divider }) - ready-made tab (create it LAST, after every other tab):
--   Interface  theme pack, accent presets + custom colour, font, text glow, menu key, overlays (watermark,
--              keybind list, session bar, performance monitor), window reset / unload
--   Profiles   see profiles.lua (active profile + unsaved changes, share codes, notes, search...)
--   Keys       every bound key, the ones used twice in red; a click opens the setting
--   Info       versions, modules, error list with Copy report / Clear
local Util = require("util")
local Theme = require("theme")
local Glow = require("glow")
local UIFont = require("font")
local Profiles = require("profiles")

local RED = "danger" -- theme role

return function(window, cfg)
    cfg = cfg or {}
    local defaultSize = Vector2.new(window.width, window.height)
    local tab = window:Tab({ Title = cfg.Title or "Settings", Icon = cfg.Icon or "settings", Divider = cfg.Divider ~= false, Header = cfg.Header ~= false })
    local interface = tab:Page("Interface")
    local profiles = tab:Page("Profiles", { Columns = 1 })
    local keysPage = tab:Page("Keys", { Columns = 1 })
    local infoPage = tab:Page("Info")

    ------------------------------------------------------------ interface
    local look = interface:Card({ Title = "Appearance", Side = "Left", Icon = "palette" })
    local picker
    local swatches
    local function syncSwatches()
        if not swatches then return end
        -- the Neutral preset shows the pack's own neutral (Light uses a dark one)
        swatches:SetColor("Neutral", Theme.neutral(Theme.pack))
        local accent = Theme.get("accentUser")
        if accent == Theme.neutral(Theme.pack) then swatches:Set("Neutral", true) else swatches:Set(accent, true) end
    end
    -- custom themes saved on this PC (<Folder>/themes.json)
    local customThemes = window.Config:ReadJSON("themes")
    for name, data in pairs(customThemes) do Theme.registerCustom(name, data) end
    local themeDropdown = look:Dropdown({
        Title = "Theme", Items = Theme.packOrder, Default = Theme.pack, Flag = "__ui_theme",
        Callback = function(name)
            Theme.applyPack(name)
            -- the pack may swap the neutral accent: keep the picker / presets in step
            if picker then picker:Set(Theme.get("accentUser"), true) end
            syncSwatches()
        end,
    })
    -- accent: one row of colour dots; the last one opens a picker for any colour (saved with the profile)
    swatches = look:Swatches({
        Title = "Accent", Default = "Neutral", Style = "Dots",
        Custom = function(open) if picker then picker:SetOpen(open) end end,
        Callback = function(color, name)
            if name == "Neutral" then color = Theme.neutral(Theme.pack) end
            if picker then picker:Set(color) end
        end,
    })
    picker = look:ColorPicker({
        Title = "Custom accent", Flag = "__ui_accent", Default = Theme.get("accentUser"),
        Callback = function(color) Theme.set("accent", color) syncSwatches() end,
    })
    picker.Row.Visible = false -- (only its colour panel shows, under the dots)
    syncSwatches()
    -- Gotham and Roblox's font library (nothing downloaded). CreateWindow({ Font = "Quicksand" }) starts with one;
    -- a list ({ "Quicksand", "Work Sans" }) starts with the first known name
    local fonts = UIFont.available()
    local wanted = type(window.cfg.Font) == "table" and window.cfg.Font or { window.cfg.Font }
    local usable = {}
    for _, name in ipairs(wanted) do if table.find(fonts, tostring(name)) then usable[#usable + 1] = tostring(name) end end
    local startFont = usable[1] or "Gotham"
    -- each name drawn in its own font
    local fontOptions = {}
    for _, name in ipairs(fonts) do fontOptions[#fontOptions + 1] = { Title = name, Font = UIFont.family(name) } end
    look:Dropdown({
        Title = "Font", Items = fontOptions, Default = startFont, Flag = "__ui_font",
        Callback = function(name)
            if not UIFont.set(name) then window:Notify({ Title = "Font", Content = name .. " is not available here", Color = RED }) end
        end,
    })
    if startFont ~= "Gotham" then UIFont.set(startFont) end
    -- the font of Code, Console and Log text: Sono Mono, or CreateWindow({ CodeFont = "Builder Mono" }) to start with
    local codeItems = {}
    for _, name in ipairs(UIFont.codeFonts) do codeItems[#codeItems + 1] = name end
    local startCode = table.find(codeItems, tostring(window.cfg.CodeFont)) and tostring(window.cfg.CodeFont) or "Sono Mono"
    look:Segment({
        Title = "Code font", Desc = "Errors and code blocks", Flag = "__ui_codefont", Items = codeItems, Default = startCode,
        Callback = function(name) UIFont.setCode(name) end,
    })
    if startCode ~= "Sono Mono" then UIFont.setCode(startCode) end
    if window.cfg.CodeFont and not table.find(codeItems, tostring(window.cfg.CodeFont)) then UIFont.setCode(window.cfg.CodeFont) end
    -- text size: every text a bit smaller / larger, the menu itself stays the same size
    local TEXT_SIZES = { Small = 0.9, Normal = 1, Large = 1.1 }
    look:Segment({
        Title = "Text size", Flag = "__ui_textsize", Items = { "Small", "Normal", "Large" }, Default = "Normal",
        Callback = function(choice) UIFont.setTextScale(TEXT_SIZES[choice] or 1) end,
    })
    look:Toggle({
        Title = "Text glow", Desc = "Shine on the title and highlights", Flag = "__ui_glow", Default = Glow.enabled,
        Callback = function(on) Glow.setEnabled(on) end,
    })

    local scaleDropdown
    local menu = interface:Card({ Title = "Behaviour", Side = "Right", Icon = "settings-2" })
    local menuKey = menu:Keybind({
        Title = "Menu key", Desc = "Opens and closes the menu", Flag = "__ui_menu_key", Default = window.key,
        Callback = function(key) window:SetToggleKey(key) end,
    })
    window._menuListeners = window._menuListeners or {}
    table.insert(window._menuListeners, function(key) if menuKey.Value ~= key then menuKey:Set(key, true) end end)
    -- UI scale: this PC only (not part of profiles)
    local SCALES = { "80%", "100%", "110%", "120%" }
    -- another scale (CreateWindow({ Scale = 0.9 })) stays as it is; the list shows the nearest
    local percent = math.floor((window:GetUIScale() * 100) + 0.5)
    local nearest = 100
    for _, text in ipairs(SCALES) do
        local value = tonumber(text:match("%d+"))
        if math.abs(value - percent) < math.abs(nearest - percent) then nearest = value end
    end
    if window.cfg.UIScale ~= false then
        scaleDropdown = menu:Dropdown({
            Title = "UI scale", Desc = "Bigger or smaller menu", Items = SCALES, Default = nearest .. "%",
            Callback = function(text) window:SetUIScale((tonumber(text:match("%d+")) or 100) / 100) end,
        })
    end
    window._scaleDropdown = scaleDropdown
    -- where the tab icons and the page names sit
    menu:Segment({ Title = "Dock", Items = { "Right", "Bottom" }, Default = window.dockSide, Flag = "__ui_dock",
        Callback = function(side) window:SetDockSide(side) end })
    menu:Segment({ Title = "Page tabs", Items = { "Header", "Row" }, Default = window.pageTabs, Flag = "__ui_pagetabs",
        Callback = function(mode) window:SetPageTabs(mode) end })
    menu:Toggle({ Title = "Free mouse", Desc = "Free cursor while open", Icon = "hand", Flag = "__ui_mouse",
        Default = window.unlockMouse ~= false, Callback = function(on) window:SetMouseUnlock(on) end })
    menu:Toggle({ Title = "Anonymous mode", Desc = "Hides your name and avatar", Icon = "venetian-mask", Flag = "__ui_anon", Default = window.anonymous == true,
        Callback = function(on) window:SetAnonymous(on) end })
    if window.OnAnonymousChanged then
        window:OnAnonymousChanged(function(on) local t = window.flags.__ui_anon if t and t.Value ~= on then t:Set(on, true) end end)
    end
    local Sounds = require("sounds")
    menu:Toggle({
        Title = "UI sounds", Desc = "Soft clicks on buttons and switches", Flag = "__ui_sounds", Default = Sounds.Enabled,
        Callback = function(on) Sounds.Enabled = on end,
    })
    local Haptics = require("haptics")
    -- (phones / tablets only: nothing to buzz on a PC)
    if Util.Services.UserInputService.TouchEnabled then
        menu:Toggle({ Title = "Haptics", Desc = "Buzz on taps", Default = Haptics.Enabled, Callback = function(on) Haptics.Enabled = on end })
    end
    menu:Toggle({ Title = "Mobile button", Desc = "Reopen button while hidden", Default = window.mobileButton == true,
        Callback = function(on) window:SetMobileButton(on, true) end })
    menu:Toggle({
        Title = "Welcome toast", Desc = "Greets a new account on first open",
        Default = window:_state("welcomeToast") ~= false and window.cfg.Welcome ~= false,
        Callback = function(on) window:_state("welcomeToast", on) end,
    })
    local menuActions = menu:Row({ Widths = { 3, 2 } })
    menuActions:Button({
        Title = "Reset layout", Icon = "rotate-ccw", Tooltip = "Puts the window back to its default size and place",
        Callback = function()
            window.width, window.height, window.topLeft = defaultSize.X, defaultSize.Y, nil
            window.memory.window = nil
            window:_layout()
            window:_saveMemory()
        end,
    })
    menuActions:Button({
        Title = "Unload", Icon = "power", Style = "Danger",
        Callback = function()
            window:Confirm("Unload " .. window.Title .. "?", "The menu and everything it runs will be removed.", function() window:Destroy() end, "Unload", true)
        end,
    })
    -- the look of the menu back to its defaults (theme, accent, font, window, overlays, scale) - nothing else changes
    local LOOK_FLAGS = { "__ui_theme", "__ui_accent", "__ui_font", "__ui_codefont", "__ui_textsize", "__ui_glow", "__ui_transparency", "__ui_bg", "__ui_bg_alpha",
        "__ui_live", "__ui_edge_glow", "__ui_blur", "__ui_hud_watermark", "__ui_hud_keys", "__ui_hud_session", "__ui_hud_stats", "__ui_dock", "__ui_pagetabs" }
    menu:Button({ Title = "Reset interface", Icon = "paintbrush", Style = "Ghost", Callback = function()
        window:Confirm("Reset the interface?", "Theme, accent, font, window look and overlays go back to their defaults. Your script settings stay.", function()
            for _, flag in ipairs(LOOK_FLAGS) do
                local element = window.flags[flag]
                local default = window.Config.Defaults[flag]
                if element and default ~= nil then
                    pcall(element._load or element.Set, element, default)
                    if element._updateReset then pcall(element._updateReset, element) end
                end
            end
            window:SetUIScale(1)
            if scaleDropdown then scaleDropdown:Set("100%", true) end
            window:Notify({ Title = "Interface reset", Content = "The menu looks like the first time", Icon = "paintbrush" })
        end, "Reset")
    end })

    local look2 = interface:Card({ Title = "Window", Side = "Left", Icon = "app-window" })
    look2:Slider({ Title = "Transparency", Flag = "__ui_transparency", Min = 0, Max = 60, Default = 0, Suffix = "%",
        Callback = function(value) window:SetBackgroundTransparency(value / 100) end })
    local bgAlpha
    look2:Input({ Title = "Background", Placeholder = "image id or url", Flag = "__ui_bg",
        Callback = function(text) window:SetBackgroundImage(text ~= "" and text or nil, bgAlpha and (1 - bgAlpha.Value / 100) or 0.85) end })
    bgAlpha = look2:Slider({ Title = "Background visibility", Flag = "__ui_bg_alpha", Min = 0, Max = 60, Default = 15, Suffix = "%",
        DependsOn = { Flag = "__ui_bg", Value = function(text) return type(text) == "string" and text ~= "" end, Mode = "Hide" },
        Callback = function(value) if window._background then window._background.ImageTransparency = 1 - value / 100 end end })
    look2:Toggle({ Title = "Animated background", Desc = "Slow glow behind the menu", Icon = "blend", Flag = "__ui_live",
        Default = window.liveBackground == true, Callback = function(on) window:SetLiveBackground(on) end })
    look2:Toggle({ Title = "Edge glow", Desc = "Pulsing accent border", Flag = "__ui_edge_glow",
        Default = window.accentGlow == true, Callback = function(on) window:SetAccentGlow(on) end })
    look2:Toggle({ Title = "Blur game", Desc = "Blurs the game while open", Flag = "__ui_blur",
        Default = window.blur == true, Callback = function(on) window:SetBlur(on) end })

    local overlays = interface:Card({ Title = "Overlays", Side = "Right", Icon = "layers" })
    overlays:Toggle({ Title = "Watermark", Desc = "Name · FPS · ping · clock", Flag = "__ui_hud_watermark", Callback = function(on) window:Watermark(on) end })
    overlays:Toggle({ Title = "Keybind list", Desc = "Bound keys on screen", Flag = "__ui_hud_keys", Callback = function(on) window:KeybindList(on) end })
    overlays:Toggle({ Title = "Session bar", Desc = "FPS · ping · players · time", Flag = "__ui_hud_session", Callback = function(on) window:SessionBar(on) end })
    overlays:Dropdown({
        Title = "Performance", Items = { "Off", "Header", "Floating" }, Default = "Off", Flag = "__ui_hud_stats",
        Callback = function(mode) window:StatsMonitor(mode) end,
    })

    ------------------------------------------------------------ theme editor
    local editorCard = interface:Card({ Title = "Theme editor", Side = "Left", Icon = "paintbrush" })
    local editor = editorCard:Section({ Title = "Edit colours", Opened = false })
    local ROLE_NAMES = { "Background", "Cards", "Inputs", "Outlines", "Text", "Muted text", "Headings", "Dock", "Icons", "Accent" }
    local ROLE_OF = {}
    for index, name in ipairs(ROLE_NAMES) do ROLE_OF[name] = Theme.EDITABLE[index] end
    local roleColor
    local roleDropdown = editor:Dropdown({ Title = "Colour", Items = ROLE_NAMES, Default = "Background",
        Callback = function(name)
            local role = ROLE_OF[name]
            if roleColor and role then roleColor:Set(Theme.get(role == "accent" and "accentUser" or role), true) end
        end })
    roleColor = editor:ColorPicker({ Title = "Value", Default = Theme.get("base"),
        Callback = function(color)
            local role = ROLE_OF[roleDropdown.Value or "Background"]
            if not role then return end
            if role == "accent" then picker:Set(color) else Theme.set(role, color) end
        end })
    local function saveThemes() window.Config:WriteJSON("themes", customThemes) end
    local function refreshThemeList(select)
        themeDropdown:SetItems(Theme.packOrder, true)
        if select then themeDropdown:Set(select) end
    end
    editor:ActionInput({ Name = "SaveTheme", Icon = "save", Placeholder = "Theme name", Button = "Save",
        Hint = "Saves the colours above as a theme",
        Validate = function(name)
            if Theme.packs[name] and not Theme.packs[name].custom then return false, "\"" .. name .. "\" is a built-in theme" end
            return true, Theme.packs[name] and ("Overwrites \"" .. name .. "\"") or ("Adds \"" .. name .. "\" to the Theme list")
        end,
        Callback = function(name)
            customThemes[name] = Theme.export()
            Theme.registerCustom(name, customThemes[name])
            saveThemes()
            refreshThemeList(name)
            window:Notify({ Title = "Theme saved", Content = name, Icon = "palette" })
        end })
    local codeRow = editor:Row()
    codeRow:Button({ Title = "Copy code", Icon = "copy", Callback = function()
        local code = "QTHEME1:" .. Util.base64encode(Util.Services.HttpService:JSONEncode({ n = themeDropdown.Value or "Theme", t = Theme.export() }))
        local clipboard = setclipboard or toclipboard
        if clipboard and pcall(clipboard, code) then window:Notify({ Title = "Copied", Content = "Theme code copied", Icon = "palette" }) end
    end })
    codeRow:Button({ Title = "Delete", Icon = "trash-2", Risky = true, Callback = function()
        local name = themeDropdown.Value
        if not (name and Theme.packs[name] and Theme.packs[name].custom) then
            return window:Notify({ Title = "Theme", Content = "Only your own themes can be deleted", Color = "warning" })
        end
        window:Confirm("Delete theme \"" .. name .. "\"?", "It is removed from this PC.", function()
            customThemes[name] = nil
            Theme.removeCustom(name)
            saveThemes()
            refreshThemeList(Theme.defaultPack)
        end, "Delete", true)
    end })
    editor:ActionInput({ Name = "ImportTheme", Icon = "import", Placeholder = "Paste a theme code", Button = "Import",
        Validate = function(code)
            local body = code:gsub("%s", ""):match("^QTHEME1:(.+)$")
            if not body then return false, "Not a theme code" end
            local ok, data = pcall(function() return Util.Services.HttpService:JSONDecode(Util.base64decode(body)) end)
            if not ok or type(data) ~= "table" or type(data.t) ~= "table" then return false, "The code is damaged" end
            return true, "Theme \"" .. tostring(data.n) .. "\""
        end,
        Callback = function(code)
            local data = Util.Services.HttpService:JSONDecode(Util.base64decode(code:gsub("%s", ""):match("^QTHEME1:(.+)$")))
            local name = tostring(data.n or "Imported"):gsub("[^%w_%- ]", "")
            if Theme.packs[name] and not Theme.packs[name].custom then name = name .. " (2)" end
            customThemes[name] = data.t
            if Theme.registerCustom(name, data.t) then
                saveThemes()
                refreshThemeList(name)
                window:Notify({ Title = "Theme imported", Content = name, Icon = "palette" })
            end
        end })


    ------------------------------------------------------------ profiles
    -- Default profile = each element's starting value (recorded as elements are created, any order)
    Profiles(window, profiles, window.Config.Defaults)

    ------------------------------------------------------------ info
    ------------------------------------------------------------ keys
    -- every key the menu listens to: switches / buttons with a bind, keybinds, key hints and the menu key. A key
    -- used twice is marked (!); a click on a row opens the setting it belongs to.
    do
        local card = keysPage:Card({ Title = "Keys", Icon = "keyboard", Wide = true, Desc = "Every bound key" })
        local list
        local rows = {}
        local function where(element)
            if element.Type == "KeyHint" then return "Footer" end
            local page = element.Card and element.Card.page
            local owner = page and page.tab
            if not owner then return "" end
            return #owner.Pages > 1 and (owner.Title .. " › " .. page.Name) or owner.Title
        end
        local function refresh()
            local conflicts = window:GetKeyConflicts()
            table.clear(rows)
            rows[#rows + 1] = { key = Util.keyName(window.key), title = "Open / close the menu", place = "Settings › Interface" }
            for element, key in pairs(window.binds) do
                if key ~= nil and element.Row and element.Row.Parent and not (type(element.Flag) == "string" and element.Flag:sub(1, 2) == "__") then
                    local name = Util.keyName(key)
                    if element.Chord and element.Chord[1] ~= nil and element.Chord[2] ~= nil then
                        name = Util.keyName(element.Chord[1]) .. " + " .. Util.keyName(element.Chord[2])
                    end
                    if name ~= "None" then
                        -- (the card's title in front when the element's own one says little: "Click to Teleport › Keys")
                        local title = tostring(element.ListTitle or element.Title or element.Type or "Key")
                        local cardTitle = element.Card and element.Card.title
                        if type(cardTitle) == "string" and cardTitle ~= "" and cardTitle ~= title and #title <= 8 then title = cardTitle .. " › " .. title end
                        rows[#rows + 1] = { key = name, title = title, place = where(element), element = element,
                            clash = conflicts[name] ~= nil }
                    end
                end
            end
            if conflicts[Util.keyName(window.key)] then rows[1].clash = true end
            table.sort(rows, function(a, b) if a.key ~= b.key then return a.key < b.key end return a.title < b.title end)
            local items, clashes = {}, {}
            for _, row in ipairs(rows) do
                items[#items + 1] = { (row.clash and "! " or "") .. row.key, row.title, row.place }
                if row.clash then clashes[row.key] = true end
            end
            local count = 0
            for _ in pairs(clashes) do count = count + 1 end
            card:SetDesc(#rows .. " keys" .. (count > 0 and (" · " .. count .. " used twice (!)") or " · no key used twice"))
            list:SetItems(items)
        end
        list = card:Table({
            Height = 230, Search = true, Columns = { { Title = "Key", Width = 0.26 }, { Title = "Setting", Width = 0.4 }, "Where" },
            Items = {},
            RowColor = function(row) return tostring(row[1]):sub(1, 2) == "! " and "danger" or nil end,
            OnRowClick = function(_, index)
                local row = rows[index]
                local element = row and row.element
                local page = element and element.Card and element.Card.page
                if not page then return end
                page.tab:Select() page:Select()
                task.defer(function() pcall(element.Flash, element) end)
            end,
        })
        -- (filled when the page opens, and again after a key changes while it is open)
        keysPage.frame:GetPropertyChangedSignal("Visible"):Connect(function() if keysPage.frame.Visible then refresh() end end)
        local check = window._checkKeys
        window._checkKeys = function(self, ...)
            check(self, ...)
            if keysPage.frame.Visible then refresh() end
        end
    end

    local about = infoPage:Card({ Title = "About", Side = "Left", Icon = "info" })
    if window.Version ~= "" then about:Info({ Title = window.Title, Value = window.Version }) end
    about:Info({ Title = "qustah-ui-lib", Value = "v" .. tostring(window.Lib.Version) })
    for _, entry in ipairs(cfg.Info or {}) do about:Info({ Title = entry[1], Value = entry[2], Copy = entry.Copy }) end
    local files = type(writefile) == "function" and type(readfile) == "function"
    about:Info({ Title = "File access", Value = files and "Yes" or "No (profiles off)" })
    about:Info({ Title = "Secure mode", Value = Util.secure and "On" or "Off", Help = "Random gui names and a silent console. Turn it on with getgenv().QUSTAH_SECURE = true before loading, or CreateWindow({ Secure = true })" })
    -- the window's size as CreateWindow({ Size = Vector2.new(w, h) }) takes it (drag the corner and read it here),
    -- and the UI scale it is drawn at
    local sizeRow = about:Info({ Title = "Window size", Value = "",
        Copy = function() return ("Vector2.new(%d, %d)"):format(window.width or 0, window.height or 0) end,
        Help = "Drag the bottom-right corner to resize; this is the value for CreateWindow({ Size = Vector2.new(w, h) })" })
    local function showSize()
        local scale = window.scale and window.scale.Scale or 1
        sizeRow:Set(("%d × %d · %d%%"):format(window.width or 0, window.height or 0, math.floor(scale * 100 + 0.5)))
    end
    window.maid:connect(window.main:GetPropertyChangedSignal("Size"), showSize)
    window.maid:connect(window.scale:GetPropertyChangedSignal("Scale"), showSize)
    showSize()
    -- (the release notes are in the "What's new" card)
    local aboutButtons = about
    if window.cfg.Tour then
        aboutButtons:Button({ Title = "Show the tour", Icon = "map", Callback = function()
            local spec = window.cfg.Tour
            window:Tour(type(spec) == "table" and spec or nil, { Id = window.cfg.TourId, Force = true })
        end })
    end

    -- CreateWindow({ Links = { { Title = "Discord", Url = "https://discord.gg/...", Icon = "message-circle" }, ... } }):
    -- buttons that copy the link (a game can't open a browser), two per row
    if type(window.cfg.Links) == "table" and #window.cfg.Links > 0 then
        local linkRow
        for index, link in ipairs(window.cfg.Links) do
            if index % 2 == 1 then linkRow = about:Row() end
            linkRow:Button({ Title = tostring(link.Title or "Link"), Icon = link.Icon or "link", Style = "Soft", Tooltip = tostring(link.Url or ""),
                Callback = function()
                    local clipboard = setclipboard or toclipboard
                    if type(clipboard) == "function" and pcall(clipboard, tostring(link.Url or "")) then
                        window:Notify({ Title = "Link copied", Content = tostring(link.Title or "Link") .. " · paste it in your browser", Icon = link.Icon or "link" })
                    else
                        window:Notify({ Title = tostring(link.Title or "Link"), Content = tostring(link.Url or ""), Duration = 10 })
                    end
                end })
        end
    end

    -- kicks / disconnects seen by the kick watcher (kick.lua)
    if window.GetKicks and window.cfg.KickLog ~= false then
        local kicksCard = infoPage:Card({ Title = "Disconnects", Side = "Left", Icon = "log-out", Desc = "Kicks and drops, with Roblox's reason" })
        local kickText = kicksCard:Paragraph({ Content = "None yet" })
        local kicksClear
        local function showKicks()
            local list = window:GetKicks()
            local lines = {}
            for index, entry in ipairs(list) do
                if index > 5 then break end
                lines[#lines + 1] = string.format("<font color=\"#%s\">%s</font>  %s  <font color=\"#%s\">%s</font>",
                    Util.toHex(Theme.get((entry.Code == 277 or entry.Code == 279) and "warning" or "danger")), tostring(entry.Kind or "Kicked"),
                    (tostring(entry.Reason or ""):gsub("<", "&lt;")), Util.toHex(Theme.get("muted")), Util.ago(entry.Time))
            end
            kickText:Set(#lines > 0 and table.concat(lines, "\n") or "None yet")
            if kicksClear then kicksClear:SetVisible(#lines > 0) end -- (nothing to clear: no button)
        end
        kicksClear = kicksCard:Button({ Title = "Clear", Icon = "trash-2", Callback = function()
            window.Config:WriteJSON("kicks", { list = {} })
            showKicks()
        end })
        window:OnKick(showKicks)
        Theme.onChange(function() if infoPage.frame.Parent then showKicks() end end)
        showKicks()
    end

    -- Copy debug info (the Errors card's button)
    local function copyDebug()
        local clipboard = setclipboard or toclipboard
        if type(clipboard) == "function" and pcall(clipboard, window:GetDebugInfo()) then
            window:Notify({ Title = "Copied", Content = "Debug info copied - paste it into your bug report", Icon = "clipboard-copy" })
        else
            window:Notify({ Title = "Clipboard", Content = "setclipboard is not available", Color = RED })
        end
    end

    -- each module's state over the last 15 minutes (a sample every 30 s)
    local modulesCard = infoPage:Card({ Title = "Modules", Side = "Left", Icon = "boxes", Desc = "Last 15 minutes" })
    local noModules = modulesCard:Label("No modules reported")
    local moduleBars = modulesCard:StatusBars({ Slots = 30, Items = {} })
    task.spawn(function()
        while window.alive do
            task.wait(30)
            local order, modules = window:GetModules()
            for _, name in ipairs(order) do moduleBars:Push(name, modules[name].state) end
        end
    end)

    -- what this executor can do (each line: the feature it is needed for)
    local executorName = "Unknown"
    pcall(function()
        if type(identifyexecutor) == "function" then executorName = table.concat({ identifyexecutor() }, " ")
        elseif type(getexecutorname) == "function" then executorName = tostring(getexecutorname()) end
    end)
    local function has(name) return type(getfenv(0)[name]) == "function" or (getgenv and type(getgenv()[name]) == "function") end
    infoPage:Card({ Title = "Executor", Side = "Right", Icon = "square-terminal", Desc = executorName }):Checklist({ Items = {
        { Title = "File access", Ok = files, Note = "profiles, themes" },
        { Title = "getcustomasset", Ok = has("getcustomasset"), Note = "sharp icons" },
        { Title = "gethui", Ok = has("gethui"), Note = "hidden interface" },
        { Title = "Drawing", Ok = (function() local d = getfenv(0).Drawing return type(d) == "table" and type(d.new) == "function" end)(), Note = "screen drawings" },
        { Title = "getconnections", Ok = has("getconnections"), Note = "connection control" },
        { Title = "hookmetamethod", Ok = has("hookmetamethod"), Note = "game hooks" },
        { Title = "setclipboard", Ok = has("setclipboard") or has("toclipboard"), Note = "copy buttons" },
    } })

    -- release notes (CreateWindow({ Changelog = { Version, Items, History } }))
    if type(window.cfg.Changelog) == "table" then
        local log = window.cfg.Changelog
        local entries = { { Version = tostring(log.Version or window.Version), Time = "this version", Items = log.Items or {} } }
        for _, old in ipairs(log.History or {}) do entries[#entries + 1] = { Version = tostring(old.Version or ""), Time = old.Date or old.Time, Items = old.Items or {} } end
        infoPage:Card({ Title = "What's new", Side = "Right", Icon = "newspaper" }):Changelog({ Items = entries })
    end

    local errorsCard = infoPage:Card({ Title = "Errors", Side = "Right", Icon = "bug" })
    -- debug mode: a small switch in the card's title row (a notification for every new error)
    errorsCard:HeaderSwitch({ Title = "Debug", Flag = "__ui_debug", Default = window.cfg.Debug == true, Tooltip = "A notification for every new error",
        Callback = function(on) window.debug = on end })
    local errorCount = errorsCard:Info({ Title = "Errors", Value = "0" })
    -- the newest errors as a code block (its Copy button copies them all)
    local errorText = errorsCard:Code({ Title = "Last errors", Code = "", MaxHeight = 180 })
    local errorButtons = errorsCard:Row()
    errorButtons:Button({ Title = "Copy debug info", Icon = "clipboard-copy", Tooltip = "Executor, versions, game, modules and errors - paste it into a bug report", Callback = copyDebug })
    local clearErrors = errorButtons:Button({ Title = "Clear", Icon = "trash-2", Callback = function() window:ClearErrors() end })

    local function update()
        local order, modules = window:GetModules()
        noModules:SetVisible(#order == 0)
        for _, name in ipairs(order) do
            local module = modules[name]
            moduleBars:AddItem({ Title = name, State = module.state, History = { module.state } })
            moduleBars:SetState(name, module.state, module.state .. (module.detail and module.state ~= "Error" and (" · " .. tostring(module.detail)) or ""))
        end
        local errors = window:GetErrors()
        local total = 0
        local lines = {}
        for index, entry in ipairs(errors) do
            total = total + entry.count
            if index > #errors - 8 then
                local head = string.format("[%s] %s%s", os.date("%H:%M:%S", entry.last or os.time()), entry.source, entry.count > 1 and (" ×" .. entry.count) or "")
                table.insert(lines, 1, head .. "\n" .. tostring(entry.message))
            end
        end
        if #errors > 8 then lines[#lines + 1] = "-- +" .. (#errors - 8) .. " older (Copy debug info)" end
        errorCount:Set(#errors == 0 and "0" or (#errors .. (total > #errors and (" (" .. total .. "×)") or "")))
        errorCount:SetColor(#errors > 0 and RED or "text")
        errorText:Set(table.concat(lines, "\n\n"))
        errorText:SetVisible(#lines > 0) -- (none: the count above says 0)
        clearErrors:SetVisible(#errors > 0)
    end
    window:OnStatusChanged(update)
    Theme.onChange(function() if infoPage.frame.Parent then update() end end)
    update()
    -- this session: how long, the script's own counters (Window:Count), Lua memory
    window._startedAt = window._startedAt or os.clock()
    local sessionCard = infoPage:Card({ Title = "This session", Side = "Right", Icon = "timer" })
    local uptimeRow = sessionCard:Info({ Title = "Running for", Value = "0s" })
    local countRows = {}
    local memoryRow = sessionCard:Info({ Title = "Lua memory", Value = "--" })
    memoryRow.Row.LayoutOrder = 10000 -- (stays last when counters are added)
    local function memory()
        local ok, kb = pcall(collectgarbage, "count")
        if not ok or type(kb) ~= "number" then ok, kb = pcall(function() return gcinfo() end) end
        return ok and type(kb) == "number" and kb or nil
    end
    local function refreshSession()
        local seconds = math.floor(os.clock() - window._startedAt)
        uptimeRow:Set(seconds >= 3600 and string.format("%dh %02dm", seconds // 3600, (seconds // 60) % 60)
            or (seconds >= 60 and string.format("%dm %02ds", seconds // 60, seconds % 60) or (seconds .. "s")))
        local order, counts = window:GetCounts()
        for _, name in ipairs(order) do
            countRows[name] = countRows[name] or sessionCard:Info({ Title = name })
            countRows[name]:Set(tostring(counts[name]))
        end
        local kb = memory()
        memoryRow:Set(kb and string.format("%.1f MB", kb / 1024) or "unavailable")
    end
    window:OnCount(function() if infoPage.frame.Visible then refreshSession() end end)
    task.spawn(function()
        while window.alive do
            if window.visible and infoPage.frame.Visible then refreshSession() end
            task.wait(1)
        end
    end)
    refreshSession()

    window.settingsTab = tab
    return tab
end
end

__modules["sounds"] = function()
-- UI sounds: soft clicks for buttons, toggles, tabs. Off by default.
--   Lib.Sounds.Enabled = true (or CreateWindow({ Sounds = true }) / Settings › Menu › UI sounds)
--   Lib.Sounds.Volume = 0.35
--   Lib.Sounds.Set("click", "rbxassetid://123")   your own sound for "click" | "toggle" | "tab" | "error"
--   Lib.Sounds.Play("click")
-- The defaults are Roblox's built-in ping played short and high, so nothing has to be downloaded.
local Util = require("util")

local PING = "rbxasset://sounds/electronicpingshort.wav"

local Sounds = {
    Enabled = false,
    Volume = 0.35,
    -- id, playback speed, relative volume
    Map = {
        click = { PING, 2.2, 0.35 },
        toggle = { PING, 1.8, 0.4 },
        tab = { PING, 2.6, 0.25 },
        error = { PING, 0.7, 0.5 },
    },
}

local Haptics = require("haptics")

local last = {}
function Sounds.Play(name)
    -- every UI sound moment is also a haptic tick (phones; Lib.Haptics.Enabled)
    Haptics.Play(name == "error" and "notify" or "click")
    if not Sounds.Enabled then return end
    local entry = Sounds.Map[name]
    if not entry then return end
    -- the same sound at most every 60 ms (a dragged slider would machine-gun otherwise)
    local now = os.clock()
    if last[name] and now - last[name] < 0.06 then return end
    last[name] = now
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = entry[1]
        sound.PlaybackSpeed = entry[2] or 1
        sound.Volume = math.clamp((tonumber(Sounds.Volume) or 0.35) * (entry[3] or 1), 0, 1)
        sound.Parent = Util.Services.SoundService
        sound:Play()
        task.delay(2, function() sound:Destroy() end)
    end)
end

function Sounds.Set(name, id, speed, volume)
    local value = tostring(id or "")
    if value:match("^%d+$") then value = "rbxassetid://" .. value end
    Sounds.Map[name] = { value, tonumber(speed) or 1, tonumber(volume) or 1 }
end

return Sounds
end

__modules["stats"] = function()
-- Shared FPS / ping sampler (one RenderStepped counter for the whole library, started on first use).
-- Stats.fps, Stats.ping (ms), Stats.history.fps / .ping (last 60 samples, one every 0.5 s).
local Util = require("util")

local Services = Util.Services

local Stats = { fps = 0, ping = 0, history = { fps = {}, ping = {} }, running = false }
local listeners = {}
local HISTORY = 60

function Stats.start(maid)
    if Stats.running then return end
    Stats.running = true
    local frames, last = 0, os.clock()
    maid:connect(Services.RunService.RenderStepped, function() frames = frames + 1 end)
    task.spawn(function()
        while Stats.running do
            task.wait(0.5)
            local now = os.clock()
            Stats.fps = math.floor(frames / math.max(now - last, 1e-3) + 0.5)
            frames, last = 0, now
            local ok, ping = pcall(function() return Services.Players.LocalPlayer:GetNetworkPing() * 1000 end)
            Stats.ping = ok and math.floor(ping + 0.5) or Stats.ping
            for key, value in pairs({ fps = Stats.fps, ping = Stats.ping }) do
                local list = Stats.history[key]
                list[#list + 1] = value
                if #list > HISTORY then table.remove(list, 1) end
            end
            for _, listener in ipairs(listeners) do Util.safe(listener, Stats) end
        end
    end)
    maid:give(function() Stats.running = false end)
end

-- Runs callback(Stats) after every sample; returns a function that removes it.
function Stats.listen(callback)
    listeners[#listeners + 1] = callback
    return function()
        local index = table.find(listeners, callback)
        if index then table.remove(listeners, index) end
    end
end

return Stats
end

__modules["status"] = function()
-- Health of the script, shown in the footer, the Dashboard "Modules" card and the Settings "Info" page.
--   Window:SetModule("ESP", "On" | "Off" | "Error" | "Limited", detail)
--   Window:ReportError(source, message)   (callback errors are reported here automatically)
--   Window:SetStatus(text, color)          manual footer text; SetStatus(nil) goes back to automatic
--   Window:GetErrors(), Window:GetErrorReport(), Window:ClearErrors(), Window:OnStatusChanged(fn)
local Util = require("util")

local Theme = require("theme")
-- theme roles, so the colours suit every theme pack
local GREEN, YELLOW, RED = "success", "warning", "danger"

return function(Window)
    local function changed(self)
        self:_refreshStatus()
        for _, listener in ipairs(self._statusListeners or {}) do Util.safe(listener, self) end
    end

    function Window:OnStatusChanged(callback)
        self._statusListeners = self._statusListeners or {}
        table.insert(self._statusListeners, callback)
    end

    -- meta (optional, kept between calls): { Icon = "eye", Tab = "ESP" } for the dashboard tiles
    function Window:SetModule(name, state, detail, meta)
        name = tostring(name)
        if type(meta) == "table" then
            self.moduleMeta = self.moduleMeta or {}
            self.moduleMeta[name] = meta
        end
        self.modules = self.modules or {}
        self.moduleOrder = self.moduleOrder or {}
        if not self.modules[name] then table.insert(self.moduleOrder, name) end
        self.modules[name] = { state = tostring(state or "Off"), detail = detail }
        if state == "Error" then self:ReportError(name, detail or "Module stopped with an error", true) return end
        changed(self)
    end
    function Window:GetModules() return self.moduleOrder or {}, self.modules or {} end

    -- session counters shown in Settings › Info › This session: Window:Count("Teleports"), Count("Server hops", 1)
    function Window:Count(name, amount)
        name = tostring(name)
        self.counts = self.counts or {}
        self.countOrder = self.countOrder or {}
        if self.counts[name] == nil then self.counts[name] = 0 table.insert(self.countOrder, name) end
        self.counts[name] = self.counts[name] + (tonumber(amount) or 1)
        for _, listener in ipairs(self._countListeners or {}) do Util.safe(listener, name, self.counts[name]) end
        return self.counts[name]
    end
    function Window:GetCounts() return self.countOrder or {}, self.counts or {} end
    function Window:OnCount(callback)
        self._countListeners = self._countListeners or {}
        table.insert(self._countListeners, callback)
    end

    -- (the same error is one entry: same source and first line; the longest text is kept, with its trace. quiet: a
    -- status that repeats an error already counted - Window:SetModule "Error" - adds no count)
    function Window:ReportError(source, message, quiet)
        source, message = tostring(source or "Script"), tostring(message or "Unknown error")
        self.errors = self.errors or {}
        self._errorIndex = self._errorIndex or {}
        local key = source .. "\0" .. (message:match("[^\r\n]+") or message)
        local entry = self._errorIndex[key]
        if entry then
            if #message > #entry.message then entry.message = message end
            if entry.fromStatus and not quiet then
                entry.fromStatus = nil -- (the report the status already counted)
            elseif not quiet then
                entry.count = entry.count + 1
                entry.last = os.time()
            end
        else
            entry = { source = source, message = message, count = 1, first = os.time(), last = os.time(), fromStatus = quiet or nil }
            self._errorIndex[key] = entry
            table.insert(self.errors, entry)
            Util.log(string.format("[%s / %s] %s", self.Title, source, message))
            -- Debug mode (CreateWindow{ Debug = true } or Settings › Info): a toast for every new error
            if self.debug == nil then self.debug = self.cfg.Debug == true end
            if self.debug and self.Notify then
                local short = (message:match("[^\r\n]+") or message):gsub("^.-:%d+: ", "")
                self:Notify({
                    Title = "Error · " .. source, Content = short, Icon = "triangle-alert", Color = RED, Duration = 6,
                    Buttons = { { Title = "Copy", Callback = function()
                        local clipboard = setclipboard or toclipboard
                        if clipboard then pcall(clipboard, source .. ": " .. message) end
                    end } },
                })
            end
        end
        changed(self)
    end
    function Window:GetErrors() return self.errors or {} end
    function Window:ClearErrors()
        self.errors, self._errorIndex = {}, {}
        for _, module in pairs(self.modules or {}) do if module.state == "Error" then module.state = "Off" end end
        changed(self)
    end
    function Window:GetErrorReport()
        local lines = { string.format("%s %s - error report (%s)", self.Title, self.Version, os.date("%Y-%m-%d %H:%M")) }
        for _, name in ipairs(self.moduleOrder or {}) do
            local module = self.modules[name]
            lines[#lines + 1] = string.format("module %s: %s%s", name, module.state, module.detail and (" (" .. tostring(module.detail) .. ")") or "")
        end
        for _, entry in ipairs(self.errors or {}) do
            lines[#lines + 1] = string.format("x%d %s: %s", entry.count, entry.source, entry.message)
        end
        if #(self.errors or {}) == 0 then lines[#lines + 1] = "no errors" end
        return table.concat(lines, "\n")
    end

    -- everything a bug report needs, as plain text: script / lib versions, executor, game, screen, theme, modules, errors
    function Window:GetDebugInfo()
        local executor = "Unknown"
        pcall(function()
            if type(identifyexecutor) == "function" then executor = table.concat({ identifyexecutor() }, " ")
            elseif type(getexecutorname) == "function" then executor = tostring(getexecutorname()) end
        end)
        local camera = workspace.CurrentCamera
        local screen = camera and camera.ViewportSize or Vector2.zero
        local lines = {
            string.format("%s %s · qustah-ui-lib v%s", self.Title, self.Version ~= "" and self.Version or "-", tostring(self.Lib and self.Lib.Version or "?")),
            "executor: " .. executor,
            string.format("game: %s · place %s · job %s", tostring(game.GameId), tostring(game.PlaceId), game.JobId ~= "" and game.JobId or "studio"),
            string.format("screen: %dx%d · ui scale %d%% · theme %s", screen.X, screen.Y, math.floor((self.GetUIScale and self:GetUIScale() or 1) * 100 + 0.5), tostring(require("theme").pack or "?")),
            string.format("files: %s · secure: %s", (type(writefile) == "function" and type(readfile) == "function") and "yes" or "no", Util.secure and "on" or "off"),
            "",
        }
        return table.concat(lines, "\n") .. self:GetErrorReport()
    end

    function Window:SetStatus(text, color)
        self._manualStatus = text ~= nil and { text = tostring(text), color = color } or nil
        self:_refreshStatus()
    end

    -- Footer: manual text > "Errors: N" > "Limited" > "Connected" (with a dot in green / yellow / red).
    function Window:_refreshStatus()
        if not self.statusLabel then return end
        local text, color
        local errorCount = #(self.errors or {})
        local limited = false
        for _, module in pairs(self.modules or {}) do if module.state == "Limited" then limited = true end end
        if self._manualStatus then
            text, color = self._manualStatus.text, self._manualStatus.color
        elseif errorCount > 0 then
            text, color = "Errors: " .. errorCount, RED
        elseif limited then
            text, color = "Limited", YELLOW
        else
            text, color = "Connected", GREEN
        end
        self.statusText = text
        self.statusLabel.Text = text
        if color ~= nil and self.statusDot then Theme.bind(self.statusDot, "ImageColor3", color) end
    end

    -- Runs a user callback; an error is reported (footer, Info page) instead of breaking the UI.
    -- Returns true / false (nil when there was nothing to run).
    function Window:_safe(source, callback, ...)
        if type(callback) ~= "function" then return nil end
        local ok, err = pcall(callback, ...)
        if not ok then self:ReportError(source, err) end
        return ok
    end
end
end

__modules["tabs"] = function()
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
    button.MouseLeave:Connect(function()
        if tab.current ~= self then Theme.tweenTo(button, "TextColor3", (window.pagesInHeader and window.current == tab) and "muted" or "text", 0.12) end
    end)
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
    -- the card's own height without the spacer: its other children summed (not the list's content size, which
    -- can still include the spacer's last height for a frame and would make the spacer grow on itself)
    local function natural(card, spacer)
        local scale = self.window.scale and self.window.scale.Scale or 1
        local layout = card.frame:FindFirstChildOfClass("UIListLayout")
        local gap = layout and layout.Padding.Offset or 4
        local content, count = 0, 0
        -- (an AutomaticSize child not measured yet: the tallest of its own children)
        local function tall(object)
            local y = object.AbsoluteSize.Y / scale
            if y > 0 or object.AutomaticSize == Enum.AutomaticSize.None then return y end
            for _, inner in ipairs(object:GetChildren()) do
                if inner:IsA("GuiObject") and inner.Visible then y = math.max(y, tall(inner)) end
            end
            return y
        end
        for _, child in ipairs(card.frame:GetChildren()) do
            if child:IsA("GuiObject") and child.Visible and child ~= spacer then
                content = content + tall(child)
                count = count + 1
            end
        end
        return content + math.max(0, count - 1) * gap
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

-- page:FillColumn(card): the card grows (empty space at its bottom) until its column ends on the same line as the
-- other column, so a Wide = "Bottom" card under them starts right after both. Returns the re-check function.
function Page:FillColumn(card)
    local own = card.frame.Parent
    local other = own == self.left and self.right or self.left
    local spacer = create("Frame", { Name = "FillSpacer", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 1e6, Visible = false, Parent = card.frame })
    local busy = false
    local function height(column)
        local scale = self.window.scale and self.window.scale.Scale or 1
        local layout = column:FindFirstChildOfClass("UIListLayout")
        local content = layout and layout.AbsoluteContentSize.Y / scale or 0
        if content > 0 then return content end
        local count = 0
        for _, child in ipairs(column:GetChildren()) do
            if child:IsA("GuiObject") and child.Visible then
                content = content + child.AbsoluteSize.Y / scale
                count = count + 1
            end
        end
        return content + math.max(0, count - 1) * (layout and layout.Padding.Offset or 10)
    end
    local function apply()
        if busy then return end
        busy = true
        local layout = card.frame:FindFirstChildOfClass("UIListLayout")
        local gap = layout and layout.Padding.Offset or 4
        local mine = height(own) - (spacer.Visible and (spacer.Size.Y.Offset + gap) or 0)
        local extra = math.floor(height(other) - mine - gap)
        local show = card.frame.Visible and not card.Collapsed and extra > 0
        spacer.Visible = show
        spacer.Size = UDim2.new(1, 0, 0, show and extra or 0)
        busy = false
    end
    for _, column in ipairs({ own, other }) do
        local layout = column:FindFirstChildOfClass("UIListLayout")
        if layout then layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() task.defer(apply) end) end
        column.ChildAdded:Connect(function() task.defer(apply) end)
    end
    card.frame:GetPropertyChangedSignal("Visible"):Connect(function() task.defer(apply) end)
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
        -- (in the title row: like the header tabs, heading / muted)
        local header = tab.window.pagesInHeader and tab.window.current == tab
        Theme.tweenTo(page.button, "TextColor3", selected and (header and "heading" or "accent") or (header and "muted" or "text"), 0.12)
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
    if self.window.current == self then self.window:_layoutBody() end
    if not self.current then self.current = page end
    if self.window.current == self then self:Select() end
    return page
end

-- Cards straight on a tab go to its first page.
function Tab:Card(cfg)
    if #self.Pages == 0 then self:Page(self.Title) end
    return self.Pages[1]:Card(cfg)
end
-- (a tab without pages: on its first page, like Tab:Card)
function Tab:FillColumn(card) return (card.page or self.Pages[1]):FillColumn(card) end
function Tab:MatchHeights(...) return self.Pages[1]:MatchHeights(...) end

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
end

__modules["theme"] = function()
-- Colour roles. Objects bind a property to a role; changing a role (e.g. the accent) recolours every bound object.
local Util = require("util")

local Theme = {}
local rgb = Color3.fromRGB

Theme.colors = {
    base       = rgb(15, 15, 16),    -- window background
    footer     = rgb(12, 12, 13),
    dock       = rgb(16, 16, 16),
    selected   = rgb(33, 33, 36),
    icon       = rgb(192, 192, 192),
    card       = rgb(19, 19, 20),
    input      = rgb(25, 25, 27),    -- buttons, boxes
    hover      = rgb(33, 33, 36),
    line       = rgb(36, 36, 39),    -- card outlines, dividers
    edge       = rgb(30, 30, 30),    -- window outline
    buttonEdge = rgb(46, 46, 50),    -- button outline, switch off
    text       = rgb(168, 168, 172),
    muted      = rgb(118, 118, 124),
    heading    = rgb(205, 205, 210),
    knob       = rgb(190, 190, 195),
    accent     = rgb(177, 178, 183), -- Qustah neutral; Lib:SetAccent changes it
    -- states (footer dot, module rows, hints, danger buttons)
    success    = rgb(110, 200, 130),
    warning    = rgb(215, 180, 120),
    danger     = rgb(215, 130, 130),
    dangerDeep = rgb(70, 32, 36),    -- danger button fill
    dangerEdge = rgb(150, 60, 66),
    dangerText = rgb(235, 150, 155),
    -- code blocks
    codeKeyword = rgb(199, 146, 234), codeString = rgb(195, 232, 141), codeNumber = rgb(247, 140, 108),
    codeComment = rgb(107, 112, 128), codeGlobal = rgb(130, 170, 255), codeCall = rgb(255, 203, 107),
}
Theme.colors.accentUser = Theme.colors.accent -- the accent as chosen; "accent" may be darkened for light packs

local function luminance(c)
    local function channel(v) return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
    return 0.2126 * channel(c.R) + 0.7152 * channel(c.G) + 0.0722 * channel(c.B)
end
local function contrast(a, b)
    local la, lb = luminance(a), luminance(b)
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05)
end
Theme.contrast = contrast

-- Roles computed from the accent.
local function derive()
    local colors = Theme.colors
    -- on light backgrounds a pale accent (green, yellow...) is darkened until it reads (contrast 3:1 on cards)
    local accent = colors.accentUser or colors.accent
    local light = luminance(colors.base) > 0.5
    if light then
        -- it must also read on its own tinted fill (primary buttons, selected dock button) and on the dock
        local black = Color3.new(0, 0, 0)
        for _ = 1, 16 do
            local deep = colors.base:Lerp(accent, 0.12)
            if contrast(accent, colors.card) >= 3 and contrast(accent, deep) >= 3 and contrast(accent, colors.dock or colors.base) >= 3
                and contrast(accent, colors.selected or colors.card) >= 3 then break end
            accent = accent:Lerp(black, 0.08)
        end
    end
    colors.accent = accent
    Theme.isLight = light
    colors.accentDeep = colors.base:Lerp(colors.accent, 0.12) -- selected dock button / indicator fill
    -- muted text is also the placeholder colour inside input boxes: keep it readable there (3:1)
    if colors.muted and colors.input and colors.text then
        for _ = 1, 10 do
            if contrast(colors.muted, colors.input) >= 3 then break end
            colors.muted = colors.muted:Lerp(colors.text, 0.12)
        end
    end
    -- switch track when on: light packs need a much stronger fill to read against the white knob
    colors.toggleOn = colors.input:Lerp(colors.accent, Theme.isLight and 0.85 or 0.42)
    colors.accentEdge = colors.base:Lerp(colors.accent, 0.35)
    -- knob / tick / text on an accent fill: whichever of the background and white reads better
    local white = Color3.new(1, 1, 1)
    colors.onAccent = contrast(colors.base, colors.accent) > contrast(white, colors.accent) and colors.base or white
end
derive()

-- object -> { property = role }. A normal (strong) table: Roblox collects the Lua handle of an Instance that no
-- script variable holds, even while the Instance is on screen, so a weak table silently lost bindings (outlines,
-- labels, boxes stayed in the old theme). Entries leave when their object is destroyed.
local bound = {}
local function track(object)
    local entry = {}
    bound[object] = entry
    pcall(function()
        local connection
        connection = object.Destroying:Connect(function()
            bound[object] = nil
            if connection then connection:Disconnect() end
        end)
    end)
    return entry
end
function Theme._binding(object) return bound[object] end

-- A data colour (a profile's colour, a series...) made readable on a theme colour: darkened on light packs,
-- lightened on dark ones until it reaches `ratio` (3:1). Theme.readable(color, "card", 3.5) -> Color3
function Theme.readable(color, role, ratio)
    local back = Theme.get(role or "card")
    local toward = luminance(back) > 0.5 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
    for _ = 1, 14 do
        if contrast(color, back) >= (ratio or 3) then break end
        color = color:Lerp(toward, 0.1)
    end
    return color
end
function Theme._bound() return bound end
function Theme._boundCount()
    local count = 0
    for _ in pairs(bound) do count = count + 1 end
    return count
end
local listeners = {}

function Theme.get(role)
    return Theme.colors[role] or role
end

-- bind(object, "BackgroundColor3", "card")
function Theme.bind(object, property, role)
    local entry = bound[object] or track(object)
    entry[property] = role
    object[property] = Theme.get(role)
    if property == "BackgroundColor3" and (Theme.alpha[role] or entry.__alpha ~= nil) then
        -- (not in its place yet: once it is)
        if object.Parent then Theme._alphaOf(object, entry) else task.defer(function() if object.Parent then pcall(Theme._alphaOf, object, entry) end end) end
    end
    -- a text box's placeholder follows the theme too (muted) unless something else was chosen for it
    if property == "TextColor3" and entry.PlaceholderColor3 == nil and object:IsA("TextBox") then
        entry.PlaceholderColor3 = "muted"
        object.PlaceholderColor3 = Theme.get("muted")
    end
    return object
end

-- Rebinds and animates to the role's colour (state changes such as a toggle turning on).
function Theme.tweenTo(object, property, role, duration)
    local entry = bound[object] or track(object)
    entry[property] = role
    if duration and duration > 0 then
        Util.tween(object, duration, { [property] = Theme.get(role) })
        -- a theme change while this runs must not be undone by it (see recolour)
        entry.__until = entry.__until or {}
        entry.__until[property] = os.clock() + duration
    else
        object[property] = Theme.get(role)
    end
end

-- recolours only what uses a role whose colour really changed (dragging the accent picker touches a handful of
-- roles, not every one of the thousands of bound properties)
local function recolour(before)
    local changed, any = {}, false
    for role, color in pairs(Theme.colors) do
        if before[role] ~= color then changed[role] = true any = true end
    end
    if not any then return end
    for object, properties in pairs(bound) do
        if object.Parent then
            for property, boundRole in pairs(properties) do
                if changed[boundRole] then
                    local running = properties.__until and properties.__until[property]
                    if running and running > os.clock() then
                        -- a tween to the old colour is still running: a new one (ending just after it) replaces it
                        pcall(Util.tween, object, running - os.clock() + 0.02, { [property] = Theme.get(boundRole) })
                    else
                        pcall(function() object[property] = Theme.get(boundRole) end)
                    end
                end
            end
        end
    end
end

function Theme.set(role, color)
    if typeof(color) ~= "Color3" then return end
    if role == "accent" then role = "accentUser" end
    local before = table.clone(Theme.colors)
    Theme.colors[role] = color
    if role == "accentUser" or role == "base" or role == "input" or role == "card" or role == "muted" or role == "text" or role == "dock" then derive() end
    recolour(before)
    for _, listener in ipairs(listeners) do Util.safe(listener, role, color) end
end

-- Several roles at once (one recolour pass).
function Theme.setMany(colors)
    local before = table.clone(Theme.colors)
    for role, color in pairs(colors) do
        if typeof(color) == "Color3" then Theme.colors[role == "accent" and "accentUser" or role] = color end
    end
    derive()
    recolour(before)
    for _, listener in ipairs(listeners) do Util.safe(listener, "*", nil) end
end

-- Theme packs: the background / text roles (the accent stays the user's), and what else the pack brings to the
-- window (Theme.packs[name].extras: see Theme.extras). Five built in:
--   Midnight  deep blue-black, the default        Graphite  neutral grey (Qustah 1.x)
--   Glass     see-through window and cards, light edges, the game blurred behind
--   OLED      true black                          Light     light
Theme.packs = {
    Midnight = {
        base = rgb(13, 14, 17), footer = rgb(11, 12, 15), dock = rgb(13, 14, 17), selected = rgb(30, 32, 39), icon = rgb(150, 155, 168),
        card = rgb(20, 21, 26), input = rgb(25, 26, 32), hover = rgb(30, 32, 39), line = rgb(33, 35, 42), edge = rgb(31, 33, 40),
        buttonEdge = rgb(44, 46, 55), text = rgb(196, 199, 207), muted = rgb(110, 115, 128), heading = rgb(238, 240, 244), knob = rgb(255, 255, 255),
    },
    Graphite = {},
    Glass = {
        base = rgb(14, 15, 19), footer = rgb(14, 15, 19), dock = rgb(14, 15, 19), selected = rgb(52, 55, 66), icon = rgb(170, 175, 188),
        card = rgb(40, 43, 52), input = rgb(48, 51, 61), hover = rgb(55, 58, 69), line = rgb(78, 82, 95), edge = rgb(92, 96, 110),
        buttonEdge = rgb(70, 74, 86), text = rgb(206, 209, 216), muted = rgb(140, 145, 158), heading = rgb(245, 246, 250), knob = rgb(255, 255, 255),
        extras = {
            -- (BackgroundTransparency per role: the window and dock let the game through, cards are lighter panes)
            alpha = { base = 0.3, footer = 1, dock = 0.3, card = 0.55, input = 0.45 },
            blur = true,
        },
    },
    OLED = {
        base = rgb(0, 0, 0), footer = rgb(0, 0, 0), dock = rgb(0, 0, 0), selected = rgb(26, 26, 28), icon = rgb(190, 190, 190),
        card = rgb(9, 9, 10), input = rgb(17, 17, 19), hover = rgb(26, 26, 28), line = rgb(34, 34, 37), edge = rgb(36, 36, 38),
        buttonEdge = rgb(46, 46, 50), text = rgb(176, 176, 180), muted = rgb(118, 118, 124), heading = rgb(225, 225, 230), knob = rgb(255, 255, 255),
    },
    Light = {
        base = rgb(238, 238, 241), footer = rgb(229, 229, 233), dock = rgb(234, 234, 238), selected = rgb(216, 216, 222), icon = rgb(85, 85, 95),
        card = rgb(247, 247, 249), input = rgb(231, 231, 235), hover = rgb(221, 221, 226), line = rgb(214, 214, 220), edge = rgb(200, 200, 206),
        buttonEdge = rgb(190, 190, 198), text = rgb(62, 62, 70), muted = rgb(120, 120, 130), heading = rgb(25, 25, 30), knob = rgb(255, 255, 255),
        success = rgb(30, 135, 70), warning = rgb(165, 105, 15), danger = rgb(190, 55, 55),
        dangerDeep = rgb(252, 230, 230), dangerEdge = rgb(225, 150, 150), dangerText = rgb(170, 40, 40),
        codeKeyword = rgb(135, 55, 195), codeString = rgb(35, 125, 55), codeNumber = rgb(195, 85, 35),
        codeComment = rgb(135, 135, 145), codeGlobal = rgb(35, 95, 200), codeCall = rgb(150, 100, 0),
    },
}
-- Custom themes (Settings › Theme editor): a few colours, the rest derived with the same steps as Graphite (card /
-- input / hover / outline at fixed distances between the background and the text), then checked: text at least
-- 4.5:1 and muted text 3:1 on cards.
local hex = function(text) return Color3.fromRGB(tonumber(text:sub(2, 3), 16), tonumber(text:sub(4, 5), 16), tonumber(text:sub(6, 7), 16)) end
Theme.hex = hex
function Theme.makePack(p)
    local base, text = hex(p.base), hex(p.text)
    local function step(t) return base:Lerp(text, t) end
    local pack = {
        base = base, footer = base:Lerp(Color3.new(0, 0, 0), 0.18), dock = p.dock and hex(p.dock) or base,
        card = p.card and hex(p.card) or step(0.026), input = p.input and hex(p.input) or step(0.065),
        selected = step(0.118), hover = step(0.118), line = step(0.137), edge = step(0.098), buttonEdge = step(0.203),
        text = text, muted = hex(p.muted), heading = hex(p.heading or p.text), icon = text:Lerp(hex(p.heading or p.text), 0.5),
        knob = text:Lerp(Color3.new(1, 1, 1), 0.15), accent = p.accent and hex(p.accent) or nil,
    }
    for _ = 1, 10 do if contrast(pack.text, pack.card) >= 4.5 then break end pack.text = pack.text:Lerp(pack.heading, 0.2) end
    for _ = 1, 10 do if contrast(pack.muted, pack.card) >= 3 then break end pack.muted = pack.muted:Lerp(pack.text, 0.15) end
    -- switch-off track / button outlines must still show on cards
    for _ = 1, 10 do if contrast(pack.buttonEdge, pack.card) >= 1.35 then break end pack.buttonEdge = pack.buttonEdge:Lerp(text, 0.08) end
    return pack
end
Theme.packOrder = { "Midnight", "Graphite", "Glass", "OLED", "Light" }
Theme.defaultPack = "Midnight"
local DEFAULTS = {}
for role, color in pairs(Theme.colors) do DEFAULTS[role] = color end
Theme.defaults = DEFAULTS
-- The accent a pack starts with ("Neutral" preset): Light a dark grey, the others Qustah grey.
function Theme.neutral(pack)
    local data = Theme.packs[pack]
    if data and data.accent then return data.accent end
    return pack == "Light" and rgb(70, 70, 80) or rgb(177, 178, 183)
end

-- Transparency per role (Glass): a surface bound to one of these roles takes its BackgroundTransparency (only
-- surfaces that show a background at all; their own value comes back when the pack has none).
Theme.alpha = {}
-- (only inside the window and the dock - a frame marked with the ThemeGlass attribute: popups, notifications and
-- the HUD over the game stay solid so their text reads on any background)
local function inGlass(object)
    local parent = object
    while parent do
        if parent:GetAttribute("ThemeGlass") then return true end
        parent = parent.Parent
    end
    return false
end
local function alphaOf(object, entry)
    local role = entry.BackgroundColor3
    local wanted = role and Theme.alpha[role]
    if wanted and not inGlass(object) then wanted = nil end
    if wanted then
        if entry.__alpha == nil then
            if object.BackgroundTransparency >= 1 then return end
            entry.__alpha = object.BackgroundTransparency
        end
        if object.BackgroundTransparency ~= wanted then object.BackgroundTransparency = wanted end
    elseif entry.__alpha ~= nil then
        object.BackgroundTransparency = entry.__alpha
        entry.__alpha = nil
    end
end
Theme._alphaOf = alphaOf
local function applyAlpha()
    for object, entry in pairs(Theme._bound()) do
        if object.Parent and entry.BackgroundColor3 then pcall(alphaOf, object, entry) end
    end
end

-- What the pack brings besides colours: { alpha = { role = transparency }, blur = true }. Windows listen with
-- Theme.onExtras(fn(extras)) (the blur).
Theme.extras = {}
local extrasListeners = {}
-- returns a function that removes the listener (a window gives it to its maid)
function Theme.onExtras(callback)
    extrasListeners[#extrasListeners + 1] = callback
    return function()
        local index = table.find(extrasListeners, callback)
        if index then table.remove(extrasListeners, index) end
    end
end

function Theme.applyPack(name)
    local pack = Theme.packs[name]
    if not pack then return false end
    local colors = {}
    for role, color in pairs(DEFAULTS) do if role ~= "accent" and role ~= "accentUser" then colors[role] = color end end
    for role, color in pairs(pack) do if role ~= "accent" and typeof(color) == "Color3" then colors[role] = color end end
    -- the pack's own accent follows the pack; an accent the user picked is kept
    local accent = Theme.colors.accentUser
    if accent == Theme.neutral(Theme.pack) or accent == Theme.neutral("Graphite") or accent == Theme.neutral("Light") then colors.accentUser = Theme.neutral(name) end
    Theme.pack = name
    Theme.extras = pack.extras or {}
    Theme.alpha = Theme.extras.alpha or {}
    Theme.setMany(colors)
    applyAlpha()
    for _, listener in ipairs(extrasListeners) do Util.safe(listener, Theme.extras) end
    return true
end
Theme.pack = "Graphite"

-- Custom themes: { base = "#101010", card = ..., accent = ... } (hex per role) <-> packs
Theme.EDITABLE = { "base", "card", "input", "line", "text", "muted", "heading", "dock", "icon", "accent" }
function Theme.export()
    local data = {}
    for _, role in ipairs(Theme.EDITABLE) do
        local color = Theme.colors[role == "accent" and "accentUser" or role]
        data[role] = "#" .. Util.toHex(color)
    end
    return data
end
function Theme.registerCustom(name, data)
    if type(data) ~= "table" or type(data.base) ~= "string" or type(data.text) ~= "string" then return false end
    local ok, pack = pcall(function()
        local made = Theme.makePack({
            base = data.base, card = data.card, input = data.input, text = data.text, muted = data.muted or data.text,
            heading = data.heading, accent = data.accent, dock = data.dock,
        })
        if data.line then made.line = hex(data.line) end
        if data.icon then made.icon = hex(data.icon) end
        -- light custom themes get the light state / code colours
        if luminance(made.base) > 0.5 then
            for role, color in pairs(Theme.packs.Light) do if made[role] == nil or role:match("^code") or role:match("^danger") or role == "success" or role == "warning" then made[role] = made[role] or color end end
            for _, role in ipairs({ "success", "warning", "danger", "dangerDeep", "dangerEdge", "dangerText", "codeKeyword", "codeString", "codeNumber", "codeComment", "codeGlobal", "codeCall" }) do made[role] = Theme.packs.Light[role] end
        end
        made.custom = true
        return made
    end)
    if not ok then return false end
    Theme.packs[name] = pack
    if not table.find(Theme.packOrder, name) then table.insert(Theme.packOrder, name) end
    return true
end
function Theme.removeCustom(name)
    if not (Theme.packs[name] and Theme.packs[name].custom) then return false end
    Theme.packs[name] = nil
    local index = table.find(Theme.packOrder, name)
    if index then table.remove(Theme.packOrder, index) end
    return true
end

-- returns a function that removes the listener
function Theme.onChange(callback)
    listeners[#listeners + 1] = callback
    return function()
        local index = table.find(listeners, callback)
        if index then table.remove(listeners, index) end
    end
end

return Theme
end

__modules["tour"] = function()
-- First-run guide: the screen dims except one part of the menu, with a small card that explains it.
--   Window:Tour()                                  the built-in steps (tabs, header, menu key, settings, status)
--   Window:Tour({ { Target = esp, Title = "ESP", Text = "Turn it on here" }, ... }, { Id = "v2", Once = true })
--   CreateWindow({ Tour = true })                   the built-in tour once per account, a moment after start
-- Target: an element, a card, a tab, any GuiObject, or a name: "dock", "header", "footer", "menuKey", "settings",
--   "status", "bell", "close". The tab / page of an element or card opens by itself, and a scrolled page scrolls to it.
-- Opts: Id (what "seen" is remembered as, default "default"), Once (skip when seen), OnFinish(completed), Force.
-- Keys: Right / Enter = next, Left = back, Escape = skip. Window:ResetTour(id) forgets that it was seen.
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label
local PANEL = 236 -- card width
local PAD = 6     -- room around the highlighted part
local TIGHT = { status = 3, menukey = 3, footer = 0, header = 2 } -- (targets in the footer: a smaller ring that stays inside the window)

return function(Window)
    local function guiOf(window, target)
        if typeof(target) == "Instance" then return target end
        if type(target) == "string" then
            local name = target:lower()
            if name == "dock" then return window.dock end
            if name == "header" then
                -- the whole top bar (the Header frame stops before the window buttons)
                local main, header = window.main, window.main and window.main:FindFirstChild("Header")
                if not header then return nil end
                local area = main:FindFirstChild("TourHeader")
                    or create("Frame", { Name = "TourHeader", BackgroundTransparency = 1, Parent = main })
                area.Size = UDim2.new(1, 0, 0, header.Size.Y.Offset)
                return area
            end
            if name == "footer" then return window.footer end
            if name == "status" then
                -- the dot and the words only (the label itself is much wider than its text)
                local footer, label_ = window.footer, window.statusLabel
                if not footer or not label_ then return nil end
                local area = footer:FindFirstChild("TourStatus")
                if not area then
                    area = create("Frame", { Name = "TourStatus", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Parent = footer })
                end
                local width = Util.textWidth(label_.Text, label_.TextSize, Enum.Font.Gotham)
                area.Position = UDim2.new(0, 16, 0.5, 0)
                area.Size = UDim2.fromOffset(math.ceil(label_.Position.X.Offset - 16 + width + 4), 16)
                return area
            end
            if name == "menukey" then return window.menuHint and window.menuHint.Row end
            if name == "settings" then return window.settingsTab and window.settingsTab.button end
            if name == "bell" then return window.main and window.main:FindFirstChild("Bell", true) end
            if name == "close" then return window.main and window.main:FindFirstChild("Close", true) end
            return nil
        end
        if type(target) == "table" then
            if target.button and target.Pages then return target.button end -- a tab
            if target.Row then return target.Row end                         -- an element
            if target.frame then return target.frame end                     -- a card / page
        end
        return nil
    end

    -- opens the tab / page that holds the target and scrolls its page to it
    local function reveal(window, target)
        local card = type(target) == "table" and (target.Card or (target.frame and target.page and target)) or nil
        local page = card and card.page
        if page and page.tab then
            if window.current ~= page.tab then pcall(page.tab.Select, page.tab) end
            if page.tab.current ~= page then pcall(page.Select, page) end
        end
        if type(target) == "table" and target.button and target.Pages and window.current ~= target then pcall(target.Select, target) end
        local object = guiOf(window, target)
        if not object then return end
        local scroller = object:FindFirstAncestorWhichIsA("ScrollingFrame")
        if scroller then
            local top = object.AbsolutePosition.Y - scroller.AbsolutePosition.Y
            local bottom = top + object.AbsoluteSize.Y
            if top < 0 or bottom > scroller.AbsoluteSize.Y then
                local y = math.max(0, scroller.CanvasPosition.Y + top - 24)
                scroller.CanvasPosition = Vector2.new(scroller.CanvasPosition.X, y)
            end
        end
    end

    function Window:_defaultTourSteps()
        local key = Util.keyName(self.key):upper()
        local steps = {
            { Target = "dock", Title = "Tabs", Text = "Every part of the script has its own tab here. Hover an icon to see its name." },
            { Target = "header", Title = "Move and resize", Text = "Drag the header to move the window, drag the bottom-right corner to resize it. Double-click the header for fullscreen." },
            { Target = "menuKey", Title = "Menu key", Text = "Press " .. key .. " to hide or show the menu. Click the key to change it." },
            { Target = "settings", Title = "Settings", Text = "Themes, fonts, profiles and overlays live here. Profiles save every setting so you can load them next time." },
            { Target = "status", Title = "Status", Text = "Green: everything works. Yellow: some features are limited on this executor. Red: something failed. Settings > Info says why." },
        }
        local out = {}
        for _, step in ipairs(steps) do if guiOf(self, step.Target) then out[#out + 1] = step end end
        return out
    end

    -- "seen" is kept in <Folder>/state.json (like the welcome toast and the changelog)
    function Window:ResetTour(id) self:_state("tour:" .. tostring(id or "default"), false) end
    function Window:HasSeenTour(id) return self:_state("tour:" .. tostring(id or "default")) == true end

    -- CreateWindow({ Tour = true | { steps }, TourDelay = 2.5 }): once per account, when no dialog / key screen is open
    function Window:_autoTour()
        local spec = self.cfg.Tour
        if not spec or self:HasSeenTour(self.cfg.TourId) then return end
        task.delay(tonumber(self.cfg.TourDelay) or 2.5, function()
            -- waits for the changelog / any dialog to close and the menu to be open (never on top of them)
            while self.alive and (self._dialog or not self.visible or self._tour) do task.wait(0.5) end
            if self.alive then self:Tour(type(spec) == "table" and spec or nil, { Once = true, Id = self.cfg.TourId }) end
        end)
    end

    function Window:Tour(steps, opts)
        opts = opts or {}
        if type(steps) ~= "table" or #steps == 0 then steps = self:_defaultTourSteps() end
        local id = tostring(opts.Id or "default")
        if opts.Once and not opts.Force and self:HasSeenTour(id) then return nil end
        if #steps == 0 or not self.alive then return nil end
        if self._tour then self._tour:Close(false) end
        if not self.visible then self:SetVisible(true) end
        self:_closePopup()

        local window = self
        local tour = { Index = 0, Steps = steps }
        local alive = true
        local scale = self.scale and self.scale.Scale or 1

        local overlay = create("Frame", { Name = "Tour", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 300, Parent = self.gui })
        -- four dim panes around the hole (they also swallow clicks)
        local panes = {}
        for index = 1, 4 do
            local pane = create("TextButton", { Name = "Dim" .. index, Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, ZIndex = 300, Parent = overlay })
            panes[index] = pane
        end
        local ring = create("Frame", { Name = "Ring", BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 301, Parent = overlay })
        corner(ring, 9)
        local ringStroke = stroke(ring, nil, 0, 2)
        Theme.bind(ringStroke, "Color", "accent")
        local glow = create("Frame", { Name = "Glow", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(-4, -4), Size = UDim2.new(1, 8, 1, 8), ZIndex = 301, Parent = ring })
        corner(glow, 12)
        local glowStroke = stroke(glow, nil, 0.7, 4)
        Theme.bind(glowStroke, "Color", "accent")

        -- the card
        local panel = create("Frame", { Name = "Panel", BorderSizePixel = 0, Size = UDim2.fromOffset(PANEL, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 302, Parent = overlay })
        create("UIScale", { Scale = scale, Parent = panel })
        Theme.bind(panel, "BackgroundColor3", "card")
        corner(panel, 10)
        Theme.bind(stroke(panel), "Color", "buttonEdge")
        Util.padding(panel, 14, 14, 12, 12)
        Util.list(panel, 6)
        local head = create("Frame", { Name = "Head", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1, ZIndex = 302, Parent = panel })
        local titleLabel = label(head, "", 11, { Name = "Title", Size = UDim2.new(1, -24, 1, 0), Font = Enum.Font.GothamMedium, ZIndex = 303 })
        Theme.bind(titleLabel, "TextColor3", "heading")
        local skip = create("TextButton", { Name = "Skip", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 4, 0.5, 0), Size = UDim2.fromOffset(20, 20), ZIndex = 303, Parent = head })
        local skipIcon = Icons.themed(skip, "x", 12, "muted", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 304 })
        local text = label(panel, "", 10, { Name = "Text", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2, ZIndex = 303 })
        Theme.bind(text, "TextColor3", "text")
        local foot = create("Frame", { Name = "Foot", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 3, ZIndex = 302, Parent = panel })
        local counter = label(foot, "", 9, { Name = "Counter", Size = UDim2.new(0, 60, 1, 0), ZIndex = 303 })
        Theme.bind(counter, "TextColor3", "muted")
        local function footButton(name, primary, x)
            local button = create("TextButton", {
                Name = name, Text = name, TextSize = 9, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BorderSizePixel = 0,
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(Util.textWidth(name, 9, Enum.Font.GothamMedium) + 20, 22), ZIndex = 303, Parent = foot,
            })
            corner(button, 6)
            local edge = stroke(button)
            Theme.bind(button, "BackgroundColor3", primary and "accent" or "input")
            Theme.bind(button, "TextColor3", primary and "onAccent" or "text")
            Theme.bind(edge, "Color", primary and "accent" or "buttonEdge")
            return button
        end
        local nextButton = footButton("Next", true, 0)
        local backButton = footButton("Back", false, -(nextButton.Size.X.Offset + 6))

        -- wrapped text height, measured word by word (does not rely on AutomaticSize of wrapped text)
        local function wrapHeight(value, size, width)
            local lines, line = 0, ""
            for paragraph in (tostring(value) .. "\n"):gmatch("(.-)\n") do
                line = ""
                lines = lines + 1
                for word in paragraph:gmatch("%S+") do
                    local try = line == "" and word or (line .. " " .. word)
                    if line ~= "" and Util.textWidth(try, size, Enum.Font.Gotham) > width then
                        lines = lines + 1
                        line = word
                    else
                        line = try
                    end
                end
            end
            return math.max(1, lines) * (size + 4)
        end
        -- the box of a part (a frame that sizes itself to its children may report no size: use the children then)
        local function rectOf(object)
            local p, s = Util.screenPos(object), object.AbsoluteSize
            if s.X > 0 and s.Y > 0 then return p, s end
            local x1, y1, x2, y2
            for _, child in ipairs(object:GetChildren()) do
                if child:IsA("GuiObject") and child.Visible and child.AbsoluteSize.X > 0 then
                    local cp, cs = Util.screenPos(child), child.AbsoluteSize
                    x1 = math.min(x1 or cp.X, cp.X)
                    y1 = math.min(y1 or cp.Y, cp.Y)
                    x2 = math.max(x2 or cp.X + cs.X, cp.X + cs.X)
                    y2 = math.max(y2 or cp.Y + cs.Y, cp.Y + cs.Y)
                end
            end
            if not x1 then return p, s end
            return Vector2.new(x1, y1), Vector2.new(x2 - x1, y2 - y1)
        end

        local current
        local function place()
            if not alive then return end
            local viewport = Util.viewport()
            local object = current and guiOf(window, current.Target)
            local x, y, w, h
            local p, s
            if object and object.Parent then p, s = rectOf(object) end
            local pad = type(current.Target) == "string" and TIGHT[current.Target:lower()] or PAD
            pad = pad * scale
            if s and s.X > 0 then
                x, y, w, h = p.X - pad, p.Y - pad, s.X + pad * 2, s.Y + pad * 2
            else
                -- nothing to point at: a centred card on a dimmed screen
                x, y, w, h = viewport.X / 2, viewport.Y / 2, 0, 0
            end
            ring.Visible = w > 0
            ring.Position, ring.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h)
            panes[1].Position, panes[1].Size = UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, math.max(0, y))
            panes[2].Position, panes[2].Size = UDim2.fromOffset(0, y + h), UDim2.new(1, 0, 1, -(y + h))
            panes[3].Position, panes[3].Size = UDim2.fromOffset(0, y), UDim2.fromOffset(math.max(0, x), h)
            panes[4].Position, panes[4].Size = UDim2.fromOffset(x + w, y), UDim2.new(1, -(x + w), 0, h)
            -- the card goes below, above, right or left of the hole - wherever it fits - and stays on screen
            local pw = PANEL * scale
            local ph = math.max(panel.AbsoluteSize.Y, (24 + 18 + 6 + text.Size.Y.Offset + 6 + 24) * scale)
            local px, py
            local rightHalf = x + w / 2 > viewport.X / 2
            local alignX = rightHalf and (x + w - pw) or x -- (lined up with the side of the part nearer the middle)
            if w == 0 then
                px, py = x - pw / 2, y - ph / 2
            elseif h > w * 2 and (rightHalf and x - 10 - pw >= 8 or x + w + 10 + pw <= viewport.X - 8) then
                -- a tall part (the dock): beside it, towards the middle of the screen
                px = rightHalf and x - 10 - pw or x + w + 10
                py = math.clamp(y + h / 2 - ph / 2, y, y + h - ph)
            elseif y + h + 10 + ph <= viewport.Y - 8 then
                px, py = alignX, y + h + 10
            elseif y - 10 - ph >= 8 then
                px, py = alignX, y - 10 - ph
            elseif not rightHalf and x + w + 10 + pw <= viewport.X - 8 then
                px, py = x + w + 10, y
            else
                px, py = x - 10 - pw, y
            end
            px = math.clamp(px, 8, math.max(8, viewport.X - pw - 8))
            py = math.clamp(py, 8, math.max(8, viewport.Y - ph - 8))
            panel.Position = UDim2.fromOffset(px, py)
        end

        local function show(index)
            index = math.clamp(index, 1, #steps)
            tour.Index = index
            current = steps[index]
            if current.Target ~= nil then reveal(window, current.Target) end
            titleLabel.Text = tostring(current.Title or "")
            text.Text = tostring(current.Text or "")
            text.AutomaticSize = Enum.AutomaticSize.None
            text.Size = UDim2.new(1, 0, 0, wrapHeight(text.Text, 10, PANEL - 30))
            counter.Text = string.format("%d / %d", index, #steps)
            nextButton.Text = index == #steps and "Done" or "Next"
            nextButton.Size = UDim2.fromOffset(Util.textWidth(nextButton.Text, 9, Enum.Font.GothamMedium) + 20, 22)
            backButton.Position = UDim2.new(1, -(nextButton.Size.X.Offset + 6), 0.5, 0)
            backButton.Visible = index > 1
            if type(current.OnShow) == "function" then window:_safe("Tour", current.OnShow) end
            place()
            task.defer(place) -- (after the tab / page switch has laid out)
        end

        local connections = {}
        function tour:Close(completed)
            if not alive then return end
            alive = false
            for _, connection in ipairs(connections) do connection:Disconnect() end
            overlay:Destroy()
            window._tour = nil
            if completed ~= nil then pcall(window._state, window, "tour:" .. id, true) end
            if opts.OnFinish then window:_safe("Tour", opts.OnFinish, completed == true) end
        end
        function tour:Next() if tour.Index >= #steps then tour:Close(true) else show(tour.Index + 1) end end
        function tour:Back() if tour.Index > 1 then show(tour.Index - 1) end end
        function tour:Go(index) show(tonumber(index) or 1) end

        nextButton.Activated:Connect(function() require("sounds").Play("click") tour:Next() end)
        backButton.Activated:Connect(function() require("sounds").Play("click") tour:Back() end)
        skip.Activated:Connect(function() tour:Close(false) end)
        skip.MouseEnter:Connect(function() if skipIcon then Theme.tweenTo(skipIcon, "ImageColor3", "heading", 0.1) end end)
        skip.MouseLeave:Connect(function() if skipIcon then Theme.tweenTo(skipIcon, "ImageColor3", "muted", 0.1) end end)
        -- follows the window when it moves or resizes
        connections[#connections + 1] = self.maid:connect(Util.Services.RunService.Heartbeat, place)
        connections[#connections + 1] = self.maid:connect(Util.Services.UserInputService.InputBegan, function(input, processed)
            if not alive or processed then return end
            local key = input.KeyCode
            if key == Enum.KeyCode.Escape then tour:Close(false)
            elseif key == Enum.KeyCode.Right or key == Enum.KeyCode.Return then tour:Next()
            elseif key == Enum.KeyCode.Left then tour:Back() end
        end)

        self._tour = tour
        -- a tour that shows once is marked as seen as soon as it opens, so leaving the game (or re-running the
        -- script) in the middle of it does not bring it back next time
        if opts.Once then pcall(self._state, self, "tour:" .. id, true) end
        show(1)
        return tour
    end
end
end

__modules["util"] = function()
-- Shared helpers: services, instance creation, tweens, cleanup (maid), text / colour / key helpers.
local Util = {}

local cloneref = cloneref or clonereference or function(object) return object end
Util.Services = setmetatable({}, {
    __index = function(cache, name)
        local service = cloneref(game:GetService(name))
        rawset(cache, name, service)
        return service
    end,
})
local Services = Util.Services

-- Secure mode (getgenv().QUSTAH_SECURE = true before loading, CreateWindow({ Secure = true }) or Lib:SetSecure(true)):
-- random ScreenGui names, nothing printed to the console, avatars as rbxthumb content (no web lookup).
local genv = (getgenv and getgenv()) or _G
Util.secure = genv.QUSTAH_SECURE == true
-- Library messages go through here so secure mode (or CreateWindow({ ConsoleLog = false })) keeps the console
-- quiet: the game's own scripts can read the console.
Util.quiet = false
function Util.log(message)
    if not Util.secure and not Util.quiet then warn(message) end
end

-- create("Frame", { Size = ..., Parent = ... }, { children }) - Parent is applied last.
function Util.create(class, props, children)
    local object = Instance.new(class)
    local parent
    for key, value in pairs(props or {}) do
        if key == "Parent" then parent = value else object[key] = value end
    end
    for _, child in ipairs(children or {}) do child.Parent = object end
    if parent then object.Parent = parent end
    return object
end
local create = Util.create

function Util.corner(object, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = object })
end
function Util.stroke(object, color, transparency, thickness)
    return create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = color or Color3.new(1, 1, 1),
        Transparency = transparency or 0, Thickness = thickness or 1, Parent = object,
    })
end
function Util.padding(object, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0), PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or 0), PaddingBottom = UDim.new(0, bottom or top or 0), Parent = object,
    })
end
function Util.list(object, padding, direction, horizontal, vertical)
    return create("UIListLayout", {
        Padding = UDim.new(0, padding or 0), FillDirection = direction or Enum.FillDirection.Vertical,
        HorizontalAlignment = horizontal or Enum.HorizontalAlignment.Left,
        VerticalAlignment = vertical or Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder, Parent = object,
    })
end
-- The UIScale on a gui and its ancestors, multiplied (1 when there is none).
function Util.uiScale(object)
    local scale = 1
    while object and not object:IsA("LayerCollector") do
        local found = object:FindFirstChildWhichIsA("UIScale")
        if found then scale = scale * found.Scale end
        object = object.Parent
    end
    return scale
end
-- A ScrollingFrame's canvas, sized from its content by hand. Roblox's AutomaticCanvasSize gets it wrong under a
-- UIScale (the menu's UI scale / small screens): the canvas comes out too short and the last items can't be
-- scrolled to. source: the content's UIListLayout / UIGridLayout, or the content frame itself. extra: more room (px).
-- (Until the content has a measured size, AutomaticCanvasSize stays on.)
function Util.fitCanvas(scroller, source, extra)
    local function update()
        if not scroller.Parent then return end
        local scale = Util.uiScale(scroller)
        if scale <= 0 then scale = 1 end
        local height
        if source:IsA("UIGridStyleLayout") then
            height = source.AbsoluteContentSize.Y / scale
        else
            height = source.AbsoluteSize.Y / scale + source.Position.Y.Offset
        end
        if height <= 0 then return end
        local padding = scroller:FindFirstChildWhichIsA("UIPadding")
        if padding then height = height + padding.PaddingTop.Offset + padding.PaddingBottom.Offset end
        scroller.AutomaticCanvasSize = Enum.AutomaticSize.None
        scroller.CanvasSize = UDim2.new(0, 0, 0, math.ceil(height + (extra or 0)))
    end
    source:GetPropertyChangedSignal(source:IsA("UIGridStyleLayout") and "AbsoluteContentSize" or "AbsoluteSize"):Connect(update)
    task.defer(update)
    return update
end
function Util.label(parent, text, size, props)
    local object = create("TextLabel", {
        BackgroundTransparency = 1, Text = text or "", TextSize = size or 11, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd, BorderSizePixel = 0, Parent = parent,
    })
    for key, value in pairs(props or {}) do object[key] = value end
    return object
end

function Util.tween(object, duration, props, style, direction)
    local tween = Services.TweenService:Create(object,
        TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end

-- Fades a small piece of UI (toast, pill, key screen) by tweening each part's own transparency, so nothing is
-- drawn through a CanvasGroup texture (sharp text and icons) and it can stay inside a list layout. Each part's
-- resting transparency is remembered the first time. fromHidden: start everything invisible (a new toast).
local FADE_PROPS = {
    { "GuiObject", "BackgroundTransparency" }, { "TextLabel", "TextTransparency" }, { "TextButton", "TextTransparency" },
    { "TextBox", "TextTransparency" }, { "ImageLabel", "ImageTransparency" }, { "ImageButton", "ImageTransparency" },
    { "UIStroke", "Transparency" },
}
function Util.fadeTree(root, duration, target, fromHidden)
    fromHidden = fromHidden or root:GetAttribute("QFadedOut") == true
    root:SetAttribute("QFadedOut", target >= 1)
    local objects = root:GetDescendants()
    table.insert(objects, root)
    for _, object in ipairs(objects) do
        for _, spec in ipairs(FADE_PROPS) do
            if object:IsA(spec[1]) then
                local prop = spec[2]
                local key = "QRest" .. prop
                local rest = object:GetAttribute(key)
                if rest == nil then
                    rest = object[prop]
                    object:SetAttribute(key, rest)
                end
                if rest < 1 then
                    if fromHidden then object[prop] = 1 end
                    Util.tween(object, duration, { [prop] = 1 - (1 - rest) * (1 - target) })
                end
            end
        end
    end
end

-- Sets an outline's normal transparency (respected by Util.fade); applied now unless its group is faded out.
function Util.setRest(strokeObject, value)
    strokeObject:SetAttribute("QRest", value)
    local group = strokeObject.Parent
    if not (group and group:IsA("CanvasGroup") and group.GroupTransparency > 0.01) then strokeObject.Transparency = value end
end

-- Downloaded files shown through getcustomasset (icon sheets, fonts, web images) --------------------------------
function Util.canCustomAsset()
    return type(getcustomasset or getsynasset) == "function" and type(writefile) == "function" and type(isfile) == "function"
end

-- A short stable name for a link (djb2), so two different links never share a file.
function Util.hash(text)
    local h = 5381
    for i = 1, #text do h = (h * 33 + string.byte(text, i)) % 4294967296 end
    return string.format("%08x", h)
end

local function makeFolders(path)
    if type(makefolder) ~= "function" or type(isfolder) ~= "function" then return end
    local built = ""
    for part in string.gmatch(path:match("^(.*)/[^/]*$") or "", "[^/]+") do
        built = built == "" and part or (built .. "/" .. part)
        if not isfolder(built) then makefolder(built) end
    end
end

-- Util.cacheFiles({ { path = "QustahUI/x.png", url = "https://...", check = function(body) return ok end }, ... },
--     done(ids), fail(reason), what)
-- what ("icons"): shown in the download strip at the top of the screen while files are fetched.
-- Every missing file is downloaded once and kept on disk; done gets { [path] = getcustomasset id }. It runs at once
-- when everything is already there (so the first frame can use it), after the download otherwise. fail runs when
-- the executor can't show downloaded files or a download / check fails.
Util.downloadTimeout = 20
function Util.cacheFiles(files, done, fail, what)
    fail = fail or function() end
    if not Util.canCustomAsset() then fail("getcustomasset is not available") return end
    local custom = getcustomasset or getsynasset
    local function finish()
        local ids = {}
        for _, file in ipairs(files) do
            local ok, id = pcall(custom, file.path)
            if not ok or type(id) ~= "string" or id == "" then fail(tostring(id)) return end
            ids[file.path] = id
        end
        done(ids)
    end
    local missing = {}
    for _, file in ipairs(files) do
        local ok, exists = pcall(isfile, file.path)
        if not (ok and exists) then missing[#missing + 1] = file end
    end
    if #missing == 0 then finish() return end
    -- (required here, not at the top: the strip itself is built from util)
    local job = what and require("loader").start(what, #missing)
    -- every missing file at once (one after the other, the strip sat at 0% through the whole first sheet). An http
    -- request reaches any host (raw.githubusercontent.com works with HttpGet too). A request that never answers
    -- would keep the strip (and whoever waits for it) forever: given up after Util.downloadTimeout seconds, the
    -- caller falls back (plain icons).
    local request = (syn and syn.request) or http_request or request
    local left, failed = #missing, nil
    local function settle(reason)
        if reason ~= nil and failed == nil then failed = reason end
        left = left - 1
        if left > 0 then return end
        if job then job.finish() end
        if failed == nil then finish() else fail(tostring(failed)) end
    end
    for _, file in ipairs(missing) do
        task.spawn(function()
            local body, finished, failure = nil, false, nil
            local worker = task.spawn(function()
                local got, value = pcall(function()
                    if request and not file.url:find("githubusercontent", 1, true) then
                        return request({ Url = file.url, Method = "GET" }).Body
                    end
                    return game:HttpGet(file.url)
                end)
                if got then body = value else failure = value end
                finished = true
            end)
            local started = os.clock()
            while not finished and os.clock() - started < Util.downloadTimeout do task.wait(0.1) end
            local ok, reason = pcall(function()
                if not finished then pcall(task.cancel, worker) error("timed out", 0) end
                if failure ~= nil then error(failure, 0) end
                assert(type(body) == "string" and #body > 0, "empty response")
                if file.check then assert(file.check(body), "unexpected file") end
                makeFolders(file.path)
                writefile(file.path, body)
            end)
            if ok and job then job.step() end
            settle(not ok and reason or nil)
        end)
    end
end

-- Runs a user callback; an error is reported but never breaks the UI.
function Util.safe(callback, ...)
    if type(callback) ~= "function" then return end
    local ok, err = pcall(callback, ...)
    if not ok then Util.log("[qustah-ui-lib] callback error: " .. tostring(err)) end
end

-- A maid owns connections, instances and cleanup functions; clean() releases all of them (newest first).
function Util.maid()
    local maid = { items = {} }
    function maid:give(item) self.items[#self.items + 1] = item return item end
    function maid:connect(signal, callback) return self:give(signal:Connect(callback)) end
    function maid:clean()
        for index = #self.items, 1, -1 do
            local item = self.items[index]
            self.items[index] = nil
            if typeof(item) == "Instance" then
                pcall(item.Destroy, item)
            elseif type(item) == "function" then
                pcall(item)
            elseif item and (typeof(item) == "RBXScriptConnection" or type(item) == "table") and item.Disconnect then
                pcall(item.Disconnect, item)
            end
        end
    end
    return maid
end

-- text widths are asked for a lot (buttons fitting their text, the tour, tooltips): remembered, the table starts over at 1000
local widthCache, widthCount = {}, 0
-- (font: an Enum.Font. A label drawn in a font from Roblox's font library or a downloaded one reports
-- Enum.Font.Unknown, which GetTextSize refuses: Gotham stands in, about as wide.)
function Util.textWidth(text, size, font)
    text = tostring(text)
    if typeof(font) ~= "EnumItem" or font == Enum.Font.Unknown then font = Enum.Font.Gotham end
    local key = text .. "\0" .. tostring(size) .. "\0" .. tostring(font)
    local width = widthCache[key]
    if width then return width end
    local ok, bounds = pcall(function() return Services.TextService:GetTextSize(text, size, font, Vector2.new(10000, 100)) end)
    width = ok and bounds.X or #text * (tonumber(size) or 10) * 0.55
    if widthCount >= 1000 then widthCache, widthCount = {}, 0 end
    widthCache[key], widthCount = width, widthCount + 1
    return width
end
-- true while the object can actually be seen: it and every parent Visible, the ScreenGui enabled
function Util.shown(object)
    while object do
        if object:IsA("GuiObject") and not object.Visible then return false end
        if object:IsA("LayerCollector") then return object.Enabled end
        object = object.Parent
    end
    return false
end

function Util.round(value, step)
    step = step or 1
    if step <= 0 then return value end
    return math.floor(value / step + 0.5) * step
end
function Util.decimals(step)
    local text = tostring(step)
    local dot = text:find("%.")
    return dot and #text - dot or 0
end

function Util.toHex(color)
    return string.format("%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end
function Util.fromHex(text)
    text = tostring(text or ""):gsub("#", ""):gsub("%s", "")
    if not text:match("^%x%x%x%x%x%x$") then return nil end
    return Color3.fromRGB(tonumber(text:sub(1, 2), 16), tonumber(text:sub(3, 4), 16), tonumber(text:sub(5, 6), 16))
end

local SHORT_KEYS = {
    LeftShift = "LSHIFT", RightShift = "RSHIFT", LeftControl = "LCTRL", RightControl = "RCTRL",
    LeftAlt = "LALT", RightAlt = "RALT", MouseButton1 = "M1", MouseButton2 = "M2", MouseButton3 = "M3", Return = "ENTER",
    KeypadZero = "NUM 0", KeypadOne = "NUM 1", KeypadTwo = "NUM 2", KeypadThree = "NUM 3", KeypadFour = "NUM 4",
    KeypadFive = "NUM 5", KeypadSix = "NUM 6", KeypadSeven = "NUM 7", KeypadEight = "NUM 8", KeypadNine = "NUM 9",
}
-- KeyCode / UserInputType / name -> short label ("RSHIFT", "NUM 8", "F").
function Util.keyName(key)
    if key == nil then return "None" end
    local name = typeof(key) == "EnumItem" and key.Name or tostring(key)
    if name == "None" or name == "" or name == "Unknown" then return "None" end
    return SHORT_KEYS[name] or name:upper()
end
-- Saved key names back to an Enum (KeyCode first, then mouse buttons).
function Util.toKey(name)
    if typeof(name) == "EnumItem" then return name end
    if type(name) ~= "string" or name == "" or name == "None" then return nil end
    if name:match("^MouseButton%d$") then
        local found, button = pcall(function() return Enum.UserInputType[name] end)
        if found and button then return button end
    end
    local ok, key = pcall(function() return Enum.KeyCode[name] end)
    if ok and key then return key end
    ok, key = pcall(function() return Enum.UserInputType[name] end)
    if ok and key then return key end
    return nil
end
-- The key an input means for binds: the KeyCode for keyboards, the UserInputType for mouse buttons 2/3
-- (and mouse button 1 when allowPrimary is set - only chords like CTRL + M1 use it).
function Util.inputKey(input, allowPrimary)
    if input.UserInputType == Enum.UserInputType.Keyboard then return input.KeyCode end
    if input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
        return input.UserInputType
    end
    if allowPrimary and input.UserInputType == Enum.UserInputType.MouseButton1 then return input.UserInputType end
    return nil
end
local MODIFIERS = {
    LeftShift = true, RightShift = true, LeftControl = true, RightControl = true, LeftAlt = true, RightAlt = true,
}
function Util.isModifier(key) return typeof(key) == "EnumItem" and MODIFIERS[key.Name] == true end
-- Is this key (KeyCode or mouse UserInputType) held down right now?
function Util.isDown(key)
    if typeof(key) ~= "EnumItem" then return false end
    local UserInputService = Services.UserInputService
    local ok, down = pcall(function()
        if tostring(key):match("^Enum%.KeyCode%.") then return UserInputService:IsKeyDown(key) end
        return UserInputService:IsMouseButtonPressed(key)
    end)
    return ok and down == true
end

-- Where a gui object really is on the screen (top-left of the whole screen, the space GetMouseLocation uses and
-- the space a child placed with Position = fromOffset(x, y) in our IgnoreGuiInset ScreenGui ends up in).
-- AbsolutePosition alone is not enough: depending on where the gui lives it can come out shifted by the top bar
-- inset (pop-ups then opened ~58 px above their button). A zero-size probe at (0, 0) in the same ScreenGui
-- measures that shift, so this is right either way.
local probes = setmetatable({}, { __mode = "k" })
function Util.origin(object)
    local gui = object and object:FindFirstAncestorWhichIsA("LayerCollector")
    if not gui then return Vector2.new(0, 0) end
    local probe = probes[gui]
    if not probe or probe.Parent ~= gui then
        probe = Instance.new("Frame")
        probe.Name = "Origin"
        probe.BackgroundTransparency = 1
        probe.Size = UDim2.fromOffset(0, 0)
        probe.Position = UDim2.fromOffset(0, 0)
        probe.Parent = gui
        probes[gui] = probe
    end
    return probe.AbsolutePosition
end
function Util.screenPos(object)
    return object.AbsolutePosition - Util.origin(object)
end

-- Screen position of a pointer input (same space as Util.screenPos).
function Util.pointer(input)
    if input and input.UserInputType == Enum.UserInputType.Touch then
        local inset = Services.GuiService:GetGuiInset()
        return Vector2.new(input.Position.X + inset.X, input.Position.Y + inset.Y)
    end
    return Services.UserInputService:GetMouseLocation()
end
function Util.isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

-- Head shot of a user as rbxthumb content (no web request).
function Util.avatar(userId, size)
    size = size or 48
    return string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=%d&h=%d", tonumber(userId) or 0, size, size)
end

-- Scroll bars that only show while scrolling or hovered (fade out ~1 s after).
function Util.fadeScrollbar(scroller, shown)
    shown = shown or 0.35
    local hovering, token = false, 0
    scroller.ScrollBarImageTransparency = 1
    local function show()
        token = token + 1
        local mine = token
        Util.tween(scroller, 0.12, { ScrollBarImageTransparency = shown })
        task.delay(1.2, function()
            if mine == token and not hovering and scroller.Parent then Util.tween(scroller, 0.35, { ScrollBarImageTransparency = 1 }) end
        end)
    end
    scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(show)
    scroller.MouseEnter:Connect(function() hovering = true show() end)
    scroller.MouseLeave:Connect(function() hovering = false show() end)
    return scroller
end

-- A touch screen without a keyboard (phones / tablets): bigger hit areas, the reopen button.
function Util.isTouch()
    local UserInputService = Services.UserInputService
    local ok, touch = pcall(function() return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled end)
    return ok and touch == true
end

-- Hover "pop": a slight grow (grid cells: images, swatches). Returns the UIScale.
function Util.hoverPop(button, amount)
    local scale = create("UIScale", { Scale = 1, Parent = button })
    button.MouseEnter:Connect(function() Util.tween(scale, 0.12, { Scale = amount or 1.05 }) end)
    button.MouseLeave:Connect(function() Util.tween(scale, 0.15, { Scale = 1 }) end)
    return scale
end

-- HH:MM:SS
function Util.clock(seconds)
    seconds = math.max(0, math.floor(seconds))
    return string.format("%02d:%02d:%02d", seconds // 3600, (seconds // 60) % 60, seconds % 60)
end

function Util.viewport()
    local camera = workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

-- gethui() > CoreGui (if writable) > PlayerGui.
function Util.guiParent()
    local ok, hidden = pcall(function() return gethui and gethui() end)
    if ok and hidden then return hidden end
    local probe = Instance.new("Folder")
    local coreOk = pcall(function() probe.Parent = Services.CoreGui end)
    probe:Destroy()
    if coreOk then return Services.CoreGui end
    return Services.Players.LocalPlayer:WaitForChild("PlayerGui")
end
function Util.screenGui(name, order)
    local gui = create("ScreenGui", {
        Name = Util.secure and Services.HttpService:GenerateGUID(false) or name, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = order or 50,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) elseif protectgui then protectgui(gui) end end)
    gui.Parent = Util.guiParent()
    return gui
end

-- The temporary copy of a file: <file>.tmp.txt (many executors only write known extensions such as .txt / .json and
-- refuse ".tmp" with "Illegal extension").
function Util.tmpOf(path) return path .. ".tmp.txt" end
local function tmpFiles(path) return { path .. ".tmp.txt" } end
Util.tmpFiles = tmpFiles

-- Crash-safe writes: the text goes to <file>.tmp.txt first, is read back, then written over the file and the .tmp removed.
-- If the game closes half way, either the old file or a complete .tmp survives (Util.readJSON picks it up).
function Util.writeAtomic(path, text)
    if type(writefile) ~= "function" then return false, "writefile is not available" end
    local tmp = Util.tmpOf(path)
    local ok, err = pcall(writefile, tmp, text)
    if not ok then
        -- no temporary copy possible here: write the file itself
        ok, err = pcall(writefile, path, text)
        if not ok then return false, tostring(err) end
        return true
    end
    if type(readfile) == "function" then
        local read, back = pcall(readfile, tmp)
        -- (some executors turn \n into \r\n on Windows)
        if not read or (back ~= text and (tostring(back):gsub("\r\n", "\n")) ~= (text:gsub("\r\n", "\n"))) then
            return false, "the file could not be written completely" -- the old file stays
        end
    end
    ok, err = pcall(writefile, path, text)
    if not ok then return false, tostring(err) end
    if type(delfile) == "function" then pcall(delfile, tmp) end
    return true
end
-- Reads a JSON table. A missing / damaged file falls back to the .tmp of an interrupted save (and the file is repaired).
-- Returns data, recovered | nil, "missing" | "damaged".
function Util.readJSON(path)
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return nil, "missing" end
    local function decode(file)
        if not isfile(file) then return nil, "missing" end
        local ok, data = pcall(function() return Services.HttpService:JSONDecode(readfile(file)) end)
        if ok and type(data) == "table" then return data end
        return nil, "damaged"
    end
    -- the temporary copy that is there (new name first), else the new name
    local tmp = Util.tmpOf(path)
    for _, file in ipairs(tmpFiles(path)) do
        if isfile(file) then tmp = file break end
    end
    local data, problem = decode(path)
    if data then
        if isfile(tmp) then
            -- both complete but different: the game closed after the .tmp was checked and before the file was
            -- written, so the .tmp is the newer save
            local newer = decode(tmp)
            local read, saved, current = pcall(function() return readfile(tmp), readfile(path) end)
            if newer and read and saved ~= current then
                pcall(function() writefile(path, readfile(tmp)) end)
                if type(delfile) == "function" then pcall(delfile, tmp) end
                return newer, true
            end
            if type(delfile) == "function" then pcall(delfile, tmp) end -- leftover of a save that finished
        end
        return data, false
    end
    local saved = decode(tmp)
    if saved then
        pcall(function() writefile(path, readfile(tmp)) end)
        if type(delfile) == "function" then pcall(delfile, tmp) end
        return saved, true
    end
    return nil, problem
end

-- Base64 (profile share codes).
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
function Util.base64encode(data)
    local out = {}
    for i = 1, #data, 3 do
        local a, b, c = data:byte(i, i + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        local c1, c2, c3, c4 = n // 262144, (n // 4096) % 64, (n // 64) % 64, n % 64
        out[#out + 1] = B64:sub(c1 + 1, c1 + 1) .. B64:sub(c2 + 1, c2 + 1)
            .. (b and B64:sub(c3 + 1, c3 + 1) or "=") .. (c and B64:sub(c4 + 1, c4 + 1) or "=")
    end
    return table.concat(out)
end
function Util.base64decode(data)
    data = tostring(data):gsub("[^%w%+/=]", "")
    local out, bits, count = {}, 0, 0
    for i = 1, #data do
        local char = data:sub(i, i)
        if char == "=" then break end
        local value = B64:find(char, 1, true)
        if not value then return nil end
        bits = bits * 64 + (value - 1)
        count = count + 6
        if count >= 8 then
            count = count - 8
            out[#out + 1] = string.char((bits // (2 ^ count)) % 256)
            bits = bits % (2 ^ count)
        end
    end
    return table.concat(out)
end

-- "2m ago"
function Util.ago(time)
    local seconds = math.max(0, os.time() - (tonumber(time) or os.time()))
    if seconds < 60 then return "now" end
    if seconds < 3600 then return (seconds // 60) .. "m ago" end
    if seconds < 86400 then return (seconds // 3600) .. "h ago" end
    return (seconds // 86400) .. "d ago"
end

return Util
end

__modules["window"] = function()
-- Window shell (Qustah layout): header (title, version badge, "Tab › Page" location, minimize / close), sub-page
-- strip, scrolling pages with two card columns, key hint bar, footer (status, centre text, resize grip) and the
-- dock to the right (drag handle, tab icons, group dividers).
local Util = require("util")
local Theme = require("theme")
local Config = require("config")
local Glow = require("glow")
local UIFont = require("font")
local Icons = require("icons")

local Services = Util.Services
local create, corner, stroke, label, tween = Util.create, Util.corner, Util.stroke, Util.label, Util.tween

local Tabs = require("tabs") -- Tab and Page
local Tab = Tabs.Tab

local HEADER, FOOTER = 44, 30
local DOCK_WIDTH, DOCK_GAP, DOCK_STEP = 40, 12, 37
local DOCK_TOP = Tabs.DOCK_TOP

local Window = {}
Window.__index = Window

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
        -- DockSide = "Right" (beside the window, default) | "Bottom" (under it, in a row)
        dockSide = cfg.DockSide == "Bottom" and "Bottom" or "Right",
        -- PageTabs = "Row" (a row of page names over the cards, default) | "Header" (in the title row, like the
        -- header tabs; a tab whose page names don't fit there keeps the row)
        pageTabs = cfg.PageTabs == "Header" and "Header" or "Row",
    }, Window)
    require("loader").setTitle(self.Title) -- the download strip says whose files these are
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

    -- CreateWindow({ Theme = "Glass" }): the pack it starts with (Midnight otherwise; Settings › Theme changes it)
    Theme.applyPack(Theme.packs[cfg.Theme] and cfg.Theme or Theme.defaultPack)
    if typeof(cfg.Accent) == "Color3" then Theme.set("accent", cfg.Accent) end
    if cfg.Secure then Util.secure = true end
    if cfg.ConsoleLog == false then Util.quiet = true end
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
    -- UIScale = false: no UI scale choice (Settings) and always 100 % (the sharpest: whole pixels everywhere)
    self.uiScale = cfg.UIScale == false and 1 or math.clamp(tonumber(self.memory.uiScale or cfg.Scale) or 1, 0.6, 1.5)
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

    -- a plain Frame: a CanvasGroup would draw the whole menu into a texture (softer icons and text in game)
    local main = create("Frame", {
        Name = "Window", Size = UDim2.fromOffset(self.width, self.height), BorderSizePixel = 0,
        ClipsDescendants = true, Parent = gui,
    })
    main:SetAttribute("ThemeGlass", true) -- (a see-through theme reaches inside: see Theme alpha)
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

    ---------------------------------------------------------------- footer
    local footer = create("Frame", { Name = "Footer", Position = UDim2.new(0, 0, 1, -FOOTER), Size = UDim2.new(1, 0, 0, FOOTER), BorderSizePixel = 0, Parent = main })
    Theme.bind(footer, "BackgroundColor3", "footer")
    -- rounded bottom corners like the window (its clipping is square now), square top edge
    corner(footer, 12)
    local footerFill = create("Frame", { Name = "TopFill", Size = UDim2.new(1, 0, 0, 13), BorderSizePixel = 0, ZIndex = 0, Parent = footer })
    Theme.bind(footerFill, "BackgroundColor3", "footer")
    local footerLine = create("Frame", { Name = "Line", Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, BackgroundTransparency = 0.35, Parent = footer })
    Theme.bind(footerLine, "BackgroundColor3", "line")
    -- status mark: solar "record-bold" (a filled dot) in the status colour; asset id inlined so the solar set is not downloaded
    local dot = create("ImageLabel", {
        Name = "StatusDot", Image = "rbxassetid://122485335253573", BackgroundTransparency = 1, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0), Size = UDim2.fromOffset(9, 9), Parent = footer,
    })
    Theme.bind(dot, "ImageColor3", "success")
    -- one status bar: [dot] Connected   Mock Place ........ [NUM 8] ESP / SILENT AIM   [RSHIFT] MENU
    local status = label(footer, "Connected", 10, { Name = "Status", Position = UDim2.fromOffset(31, 0), Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, TextTruncate = Enum.TextTruncate.None })
    Theme.bind(status, "TextColor3", "text")
    Glow.add(status, { Base = "text", Shine = "heading", GlowTransparency = 0.92 })
    local centre = label(footer, tostring(self.cfg.Footer or ""), 10, { Name = "Centre", Size = UDim2.new(0, 100, 1, 0) })
    Theme.bind(centre, "TextColor3", "muted")
    -- key hints on the right of the status bar (Left hints first, then Right ones)
    self.hintBar = create("Frame", {
        Name = "KeyHints", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -26, 0, 0),
        Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, Visible = false, Parent = footer,
    })
    local hintLayout = Util.list(self.hintBar, 14, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    for index, name in ipairs({ "Left", "Right" }) do
        local side = create("Frame", { Name = name, BackgroundTransparency = 1, Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = index, Parent = self.hintBar })
        Util.list(side, 14, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
        self["hint" .. name] = side
    end
    self.hints = {}
    -- the place name takes the room between the status and the hints
    local function placeCentre()
        local s = self.scale and self.scale.Scale or 1
        local left = 31 + Util.textWidth(status.Text, 10, Enum.Font.Gotham) + 12
        local right = (self.hintBar.Visible and hintLayout.AbsoluteContentSize.X / s + 26 + 14) or 26
        centre.Position = UDim2.fromOffset(left, 0)
        centre.Size = UDim2.new(1, -(left + right), 1, 0)
    end
    maid:connect(status:GetPropertyChangedSignal("Text"), placeCentre)
    maid:connect(hintLayout:GetPropertyChangedSignal("AbsoluteContentSize"), placeCentre)
    maid:connect(self.hintBar:GetPropertyChangedSignal("Visible"), placeCentre)
    self._placeCentre = placeCentre
    placeCentre()
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
    local dock = create("Frame", { Name = "Dock", Size = UDim2.fromOffset(DOCK_WIDTH, DOCK_TOP), BorderSizePixel = 0, BackgroundTransparency = 0.03, ZIndex = 40, ClipsDescendants = true, Parent = gui })
    dock:SetAttribute("ThemeGlass", true)
    Theme.bind(dock, "BackgroundColor3", "dock")
    corner(dock, 20)
    Theme.bind(stroke(dock), "Color", "line")
    self.dock = dock
    self.dockScale = create("UIScale", { Scale = 1, Parent = dock })
    -- drag handle (three lines) at the top of the dock moves the window like the header
    local dockGrip = create("TextButton", { Name = "DragHandle", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromOffset(5, 6), Size = UDim2.fromOffset(30, 28), ZIndex = 42, Parent = dock })
    local gripBars = {}
    for _, lineY in ipairs({ 9, 13, 17 }) do
        local bar = create("Frame", { Position = UDim2.fromOffset(9, lineY), Size = UDim2.fromOffset(12, 1), BorderSizePixel = 0, ZIndex = 43, Parent = dockGrip })
        Theme.bind(bar, "BackgroundColor3", "muted")
        gripBars[#gripBars + 1] = bar
    end
    self.dockGrip, self.dockGripBars, self.dockDividers = dockGrip, gripBars, {}

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
    local total, tall = self:_extent()
    -- the chosen UI scale (Settings / Window:SetUIScale), made smaller when the screen can't fit it
    local s = math.clamp(math.min(self.uiScale or 1, (viewport.X - 24) / total, (viewport.Y - 24) / tall), 0.4, 1.5)
    self.scale.Scale, self.dockScale.Scale = s, s
    local height = self.folded and HEADER or self.height
    self.main.Size = UDim2.fromOffset(self.width, height)
    if not self.topLeft then
        local saved = self.memory and self.memory.window
        if type(saved) == "table" and tonumber(saved.x) and tonumber(saved.y) then
            local room = Vector2.new(viewport.X - total * s, viewport.Y - tall * s)
            self.topLeft = Vector2.new(tonumber(saved.x) * room.X, tonumber(saved.y) * room.Y)
        else
            self.topLeft = Vector2.new((viewport.X - total * s) / 2, (viewport.Y - tall * s) / 2)
        end
    end
    -- (on whole pixels: a window at y = 96.5 puts every icon and line inside it between two pixels, a little blurred)
    local x = math.floor(math.clamp(self.topLeft.X, 8, math.max(8, viewport.X - total * s - 8)) + 0.5)
    local y = math.floor(math.clamp(self.topLeft.Y, 8, math.max(8, viewport.Y - (self.folded and height or tall) * s - 8)) + 0.5)
    self.topLeft = Vector2.new(x, y)
    self.main.Position = UDim2.fromOffset(x, y)
    local length = self.dockHeight or DOCK_TOP
    if self.dockSide == "Bottom" then
        self.dock.Size = UDim2.fromOffset(length, DOCK_WIDTH)
        self.dock.Position = UDim2.fromOffset(math.floor(x + (self.width - length) / 2 * s + 0.5), math.floor(y + (self.height + DOCK_GAP) * s + 0.5))
    else
        self.dock.Size = UDim2.fromOffset(DOCK_WIDTH, length)
        self.dock.Position = UDim2.fromOffset(math.floor(x + (self.width + DOCK_GAP) * s + 0.5), y)
    end
    self.dock.Visible = self.main.Visible and not self.folded and #self.Tabs > 0
    self.grip.Visible = not self.folded
    for _, tab in ipairs(self.Tabs) do for _, page in ipairs(tab.Pages) do page:_columns(self.width) end end
    self:_placePageTabs()
    self:_updateLocation()
end

-- The window with its dock: width and height (unscaled).
function Window:_extent()
    if self.dockSide == "Bottom" then
        return math.max(self.width, self.dockHeight or DOCK_TOP), self.height + DOCK_GAP + DOCK_WIDTH
    end
    return self.width + DOCK_GAP + DOCK_WIDTH, self.height
end

-- Window:SetDockSide("Right" | "Bottom")
function Window:SetDockSide(side)
    side = side == "Bottom" and "Bottom" or "Right"
    if side == self.dockSide then return end
    self.dockSide = side
    self:_layoutDock()
    self:_layout()
    self:_saveMemory()
end

-- Window:SetPageTabs("Row" | "Header")
function Window:SetPageTabs(mode)
    self.pageTabs = mode == "Header" and "Header" or "Row"
    self:_placePageTabs()
    self:_layoutBody()
    self:_updateLocation()
end

-- The page names of the open tab: in the title row (PageTabs = "Header", when they fit) or the row over the cards.
local PAGE_GAP = 14
function Window:_pageTabWidths(tab)
    local widths, total = {}, 0
    for index, page in ipairs(tab.Pages) do
        widths[index] = Util.textWidth(page.Name, 11, Enum.Font.GothamMedium) + PAGE_GAP
        total = total + widths[index]
    end
    return widths, total
end
function Window:_placePageTabs()
    local holder, tab = self.stripHolder, self.current
    if not holder then return end
    local inHeader = false
    -- (a header tab - Dashboard / Settings - has the header tabs up there: its pages keep the row)
    if self.pageTabs == "Header" and tab and #tab.Pages > 1 and not (tab.Header and self.cfg.HeaderTabs ~= false) then
        local _, total = self:_pageTabWidths(tab)
        local room = self.width - (self.headerRight or 90) - 16 - self:_titleWidth() - 16
        inHeader = total <= room
    end
    self.pagesInHeader = inHeader
    for _, other in ipairs(self.Tabs) do
        local header = inHeader and other == tab
        local widths = header and self:_pageTabWidths(other) or nil
        local x, count = 0, #other.Pages
        for index, page in ipairs(other.Pages) do
            local button, underline = page.button, page.underline
            if header then
                button.Position, button.Size = UDim2.fromOffset(x, 0), UDim2.fromOffset(widths[index], HEADER)
                button.TextSize = 11
                underline.Size = UDim2.new(1, -14, 0, 2)
                x = x + widths[index]
            else
                button.Position, button.Size = UDim2.new((index - 1) / count, 0, 0, 0), UDim2.new(1 / count, 0, 1, 0)
                button.TextSize = 10
                underline.Size = UDim2.fromOffset(math.max(12, Util.textWidth(page.Name, 10, Enum.Font.GothamMedium)), 1)
            end
            Theme.bind(button, "TextColor3", (other.current == page) and (header and "heading" or "accent") or (header and "muted" or "text"))
        end
    end
    if inHeader then
        local _, total = self:_pageTabWidths(tab)
        holder.Parent = self.main
        holder.AnchorPoint = Vector2.new(1, 0)
        holder.Position = UDim2.new(1, -(self.headerRight or 90), 0, 0)
        holder.Size = UDim2.fromOffset(total, HEADER)
    else
        holder.Parent = self.body
        holder.AnchorPoint = Vector2.new(0, 0)
        holder.Position = UDim2.fromOffset(16, 6)
        holder.Size = UDim2.new(1, -32, 0, 26)
    end
end

-- Saves position (as a 0-1 fraction of the free screen space) and size; written at most twice a second.
function Window:_saveMemory()
    if self.cfg.SaveWindow == false or not self.alive then return end
    local viewport = Util.viewport()
    local s = self.scale.Scale
    local total, tall = self:_extent()
    local room = Vector2.new(math.max(1, viewport.X - total * s), math.max(1, viewport.Y - tall * s))
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

-- Dock slots: drag handle, then one button per tab (37 px apart) with a divider before tabs marked Divider -
-- top to bottom (DockSide = "Right") or left to right ("Bottom"). `along` is the place on the dock's length.
function Window:_dockSpot(object, along, across)
    if self.dockSide == "Bottom" then object.Position = UDim2.fromOffset(along, across)
    else object.Position = UDim2.fromOffset(across, along) end
end
function Window:_dockLine(line, along)
    line.Size = self.dockSide == "Bottom" and UDim2.fromOffset(1, 22) or UDim2.fromOffset(22, 1)
    self:_dockSpot(line, along, 9)
end
function Window:_layoutDock()
    for _, divider in ipairs(self.dockDividers) do divider:Destroy() end
    self.dockDividers = {}
    local bottom = self.dockSide == "Bottom"
    self.dockGrip.Size = bottom and UDim2.fromOffset(28, 30) or UDim2.fromOffset(30, 28)
    self:_dockSpot(self.dockGrip, 6, 5)
    for index, bar in ipairs(self.dockGripBars) do
        bar.Position = UDim2.fromOffset(bottom and 8 or 9, (bottom and 10 or 9) + (index - 1) * 4)
    end
    local cursor = DOCK_TOP
    for _, tab in ipairs(self.Tabs) do
        if tab.Hidden then tab.button.Visible = false continue end
        tab.button.Visible = true
        if tab.Divider then
            local divider = create("Frame", { Name = "Divider", BorderSizePixel = 0, ZIndex = 42, Parent = self.dock })
            Theme.bind(divider, "BackgroundColor3", "line")
            self:_dockLine(divider, cursor + 1)
            self.dockDividers[#self.dockDividers + 1] = divider
            cursor = cursor + 8
        end
        tab.y = cursor
        self:_dockSpot(tab.button, cursor, 5)
        cursor = cursor + DOCK_STEP
    end
    self.dockHeight = cursor + 8
end

-- Page area: below the strip (if the open tab has pages) and above the key hint bar (if there are hints).
function Window:_layoutBody()
    local tab = self.current
    self:_placePageTabs()
    local top = (tab and #tab.Pages > 1 and not self.pagesInHeader) and 38 or 6
    self.pages.Position = UDim2.fromOffset(0, top)
    self.pages.Size = UDim2.new(1, 0, 1, -top)
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
    -- never wider than the free room (tags / long titles), and leave the middle to the header stats
    local share = math.floor(self.width * (self.monitorMode == "Header" and 0.25 or 0.45))
    local width = math.max(0, math.min(share, room))
    -- "Tab › Page" when it fits, else just the page (or tab) name, else nothing (no cut-off text)
    local label = self.locationLabel
    local full = (page and #tab.Pages > 1) and (tab.Title .. " › " .. page.Name) or tab.Title
    local short = (page and #tab.Pages > 1) and page.Name or tab.Title
    local function fits(text) return Util.textWidth(text, label.TextSize, label.Font) <= width end
    label.Text = fits(full) and full or short
    label.Visible = room >= 40 and fits(label.Text) and not self.headerTabs.Visible and not self.pagesInHeader
    label.Size = UDim2.fromOffset(width, 20)
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
    if self.dockSide == "Bottom" then
        -- over the button
        self.tip.AnchorPoint = Vector2.new(0, 1)
        self.tip.Position = UDim2.fromOffset(dockX + (y - 2) * s, self.dock.Position.Y.Offset - 6)
    elseif dockX + (DOCK_WIDTH + 8) * s + 150 > Util.viewport().X then
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
    -- (shown and hidden at once: a fade put the whole menu - thousands of objects - into a CanvasGroup and back on
    -- every toggle, a visible hitch in game)
    if visible then
        self.main.Visible = true
        self:_layout() -- (the dock shows again here, unless folded or without tabs)
    else
        self._drag = nil
        self.main.Visible = false
        self.dock.Visible = false
    end
end
function Window:Toggle() self:SetVisible(not self.visible) end

-- Window:SetUIScale(1.1): the whole menu bigger / smaller (0.6 - 1.5); remembered on this PC.
function Window:SetUIScale(value)
    value = math.clamp(tonumber(value) or 1, 0.6, 1.5)
    if self.cfg and self.cfg.UIScale == false then value = 1 end
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
--                  Pressed = function(key) end, Callback = function(newKey) end, Flag, ListTitle = "ESP / Silent Aim" })
-- (ListTitle: its name in Settings › Keys, when the caption is shouted)
-- A key badge with a caption above the footer; click the badge to rebind (Backspace clears, Escape cancels).
function Window:KeyHint(cfg)
    cfg = cfg or {}
    local right = cfg.Side == "Right"
    local group = create("Frame", {
        Name = tostring(cfg.Title or "Hint"), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 26), LayoutOrder = #self.hints + 1, Parent = right and self.hintRight or self.hintLeft,
    })
    Util.list(group, 6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    -- [KEY] Caption: a small key cap, then its caption
    local badge = create("TextButton", {
        Name = "Key", AutoButtonColor = false, BorderSizePixel = 0, Text = "", TextSize = 9,
        Font = Enum.Font.GothamMedium, Size = UDim2.fromOffset(40, 18), LayoutOrder = 1, Parent = group,
    })
    Theme.bind(badge, "TextColor3", "text")
    Theme.bind(badge, "BackgroundColor3", "input")
    corner(badge, 5)
    local outline = stroke(badge, nil, 0.3)
    Theme.bind(outline, "Color", "buttonEdge")
    local caption = label(group, tostring(cfg.Title or ""), 10, { Name = "Caption", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 20), LayoutOrder = 2, TextTruncate = Enum.TextTruncate.None })
    Theme.bind(caption, "TextColor3", "muted")

    local window = self
    local hint = { Type = "KeyHint", Title = cfg.Title, ListTitle = cfg.ListTitle, Row = group, Flag = cfg.Flag }
    local function show(text)
        badge.Text = text
        badge.Size = UDim2.fromOffset(math.max(28, Util.textWidth(text, 9, Enum.Font.GothamMedium) + 12), 18)
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
    badge.MouseEnter:Connect(function() Util.tween(outline, 0.12, { Transparency = 0 }) end)
    badge.MouseLeave:Connect(function() Util.tween(outline, 0.12, { Transparency = 0.3 }) end)
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
    -- the last window gone: the library's shared parts go too (toasts, the FPS sampler, the shine loop)
    if #self.Lib.Windows == 0 then self.Lib.maid:clean() end
    Util.safe(self.cfg.OnClose)
end

return Window
end

__modules["windowfx"] = function()
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
-- the text colour on a tag's fill: dark or white, whichever reads better
local function readableOn(color)
    local function channel(c) return c <= 0.03928 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4 end
    local luminance = 0.2126 * channel(color.R) + 0.7152 * channel(color.G) + 0.0722 * channel(color.B)
    local dark = 0.2126 * channel(18 / 255) + 0.7152 * channel(18 / 255) + 0.0722 * channel(22 / 255)
    return (luminance + 0.05) / (dark + 0.05) > 1.05 / (luminance + 0.05) and Color3.fromRGB(18, 18, 22) or Color3.new(1, 1, 1)
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
            Util.setRest(edge, 0) edge.Thickness = 1
            return
        end
        Theme.bind(edge, "Color", "accent")
        edge.Thickness = 1.5
        local last = 0
        self._glowConnection = Util.Services.RunService.Heartbeat:Connect(function()
            local now = os.clock()
            if now - last < 1 / 30 or not self.visible then return end -- (nothing to animate while the menu is hidden)
            last = now
            Util.setRest(edge, 0.55 + math.sin(now * 2.1) * 0.25) -- breathes between 0.3 and 0.8
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
    -- Small per-folder memory (welcome toast, changelog, tour...) in <Folder>/state.json. A copy also lives in
    -- getgenv(), so without file access (or when a write fails) a re-run in the same game still remembers it.
    function Window:_state(key, value)
        local env = (getgenv and getgenv()) or _G
        env.__QustahUIState = env.__QustahUIState or {}
        local memory = env.__QustahUIState[self.Config.folder]
        if not memory then memory = {} env.__QustahUIState[self.Config.folder] = memory end
        if not self._stateData then
            local ok, data = pcall(self.Config.ReadJSON, self.Config, "state")
            self._stateData = ok and type(data) == "table" and data or {}
            for name, item in pairs(memory) do if self._stateData[name] == nil then self._stateData[name] = item end end
        end
        if value ~= nil then
            self._stateData[key] = value
            memory[key] = value
            pcall(self.Config.WriteJSON, self.Config, "state", self._stateData)
        end
        local result = self._stateData[key]
        if result == nil then result = memory[key] end
        return result
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
    -- Changelog = { Version, Items, History = { { Version = "1.1", Items = {...} }, ... } }: every version's notes,
    -- newest first (Settings › Info › Version history)
    function Window:ShowVersionHistory()
        local log = self.cfg.Changelog
        if type(log) ~= "table" then return nil end
        local versions = { { Version = log.Version, Items = log.Items, Current = true } }
        for _, entry in ipairs(type(log.History) == "table" and log.History or {}) do versions[#versions + 1] = entry end
        local blocks = {}
        for index, entry in ipairs(versions) do
            if index > 6 then blocks[#blocks + 1] = "<font transparency=\"0.4\">and " .. (#versions - 6) .. " older</font>" break end
            local lines = { "<b>" .. tostring(entry.Version or "?") .. "</b>" .. (entry.Current and "  <font transparency=\"0.4\">current</font>" or "") }
            for count, item in ipairs(entry.Items or {}) do
                if count > 6 then lines[#lines + 1] = "   …" break end
                lines[#lines + 1] = "•  " .. tostring(item):gsub("<", "&lt;")
            end
            blocks[#blocks + 1] = table.concat(lines, "\n")
        end
        return self:Dialog({ Title = "Version history", Icon = "history", Content = table.concat(blocks, "\n\n"),
            Buttons = { { Title = "Close", Style = "Primary" } } })
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
        -- a theme that blurs the game (Glass): on with it; off again after it unless the Blur game switch is on
        self._themeBlur = Theme.extras.blur == true
        if self._themeBlur then self:SetBlur(true) end
        self.maid:give(Theme.onExtras(function(extras)
            if not self.alive then return end
            local themed = extras.blur == true
            if themed == self._themeBlur then return end
            self._themeBlur = themed
            local own = self.flags.__ui_blur and self.flags.__ui_blur.Value == true
            self:SetBlur(themed or own)
        end))
        self:_welcome()
        self:_changelog()
        if self._autoTour then self:_autoTour() end
    end
end
end

__modules["windowx"] = function()
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
            local at = self.dockHeight - 2
            self:_dockLine(self._profileLine, at)
            self:_dockSpot(self._profile, at + 7, 5)
            self.dockHeight = at + 7 + 30 + 8
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
            local avatar = Util.avatar(player.UserId, 60) -- (shown at 30 px: a clean 2x)
            button.Image = avatar
            self._profile, self._profileLine = button, line
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
end

return require("init")
