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
