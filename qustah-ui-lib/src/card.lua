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
        local icon = cfg.Icon and Icons.themed(head, cfg.Icon, 13, "accent", { Name = "CardIcon", Position = UDim2.fromOffset(-1, 3) })
        for ring = 3, (icon and 4 or 0), -1 do
            local dot = create("Frame", {
                Name = ring == 0 and "Dot" or "Glow", Position = UDim2.fromOffset(-ring, 7 - ring), Size = UDim2.fromOffset(6 + ring * 2, 6 + ring * 2),
                BorderSizePixel = 0, BackgroundTransparency = ring == 0 and 0 or 0.91, Parent = head,
            })
            Theme.bind(dot, "BackgroundColor3", "accent")
            corner(dot, ring == 0 and 3 or 6)
        end
        local collapsible = cfg.Collapsible ~= false
        local title = label(head, tostring(cfg.Title), 10, { Position = UDim2.fromOffset(icon and 18 or 13, 0), Size = UDim2.new(1, (icon and -18 or -13) - (collapsible and 22 or 0), 1, 0), Font = Enum.Font.GothamMedium })
        Theme.bind(title, "TextColor3", "heading")
        self.titleLabel = title
        -- Desc = "...": a muted line under the title
        if cfg.Desc then
            local desc = label(frame, tostring(cfg.Desc), 9, { Name = "CardDesc", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextTruncate = Enum.TextTruncate.None, LayoutOrder = 1 })
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
        if child:IsA("GuiObject") and child.Name ~= "Heading" and child.Name ~= "CardDesc" then
            if collapsed then
                if child.Visible then self._hidden[child] = true child.Visible = false end
            elseif self._hidden[child] then
                child.Visible = true
            end
        end
    end
    if not collapsed then self._hidden = {} end
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
    local icon = cfg.Icon and Icons.themed(head, cfg.Icon, 13, "accent", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0, 11) })
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

-- card:Row({ Gap = 6 }) -> elements put in it sit side by side with equal widths (buttons, small toggles...).
function Card:Row(cfg)
    cfg = cfg or {}
    local gap = tonumber(cfg.Gap) or 6
    local holder = create("Frame", { Name = "Row", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = self:_order(), Parent = self.body })
    Util.list(holder, gap, Enum.FillDirection.Horizontal)
    local function share()
        local children = {}
        for _, child in ipairs(holder:GetChildren()) do if child:IsA("GuiObject") and child.Visible then children[#children + 1] = child end end
        local n = #children
        for _, child in ipairs(children) do
            child.Size = UDim2.new(1 / n, -gap * (n - 1) / n, child.Size.Y.Scale, child.Size.Y.Offset)
        end
    end
    holder.ChildAdded:Connect(function() task.defer(share) end)
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

function Card:SetTitle(text) if self.titleLabel then self.titleLabel.Text = tostring(text) end end
function Card:SetVisible(visible) self.frame.Visible = visible ~= false end

return Card
