-- card:Dropdown({ Title, Desc, Flag, Options = {...}, Default, Multi, AllowNone, Search, DragSelect, Callback, Locked })
-- Single: Value is the chosen option. Multi: Value is a list of chosen options.
-- Options can be:
--   strings                                   { "Head", "Body" }
--   tables                                    { { Title = "Head", Icon = "user", Image = "rbxassetid://..", Desc = "...", Locked = true } }
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
    setOptions(cfg.Options or cfg.Values)
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
    element.Options = options

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
            local titles = {}
            for _, key in ipairs(element.Value) do titles[#titles + 1] = titleOf(key) end
            text = #titles > 0 and table.concat(titles, ", ") or "None"
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
        local position, size = button.AbsolutePosition, button.AbsoluteSize
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
    -- SetOptions accepts the same forms as Options; chosen values that no longer exist are dropped
    function element:SetOptions(list, keep)
        setOptions(list)
        self.Options = options
        if popup then window:_closePopup() end
        self:Set(keep and self.Value or (multi and {} or nil), true)
    end
    function element:Refresh(list) self:SetOptions(list, true) end

    if multi then
        element.Value = {}
        element:Set(cfg.Default or {}, true)
    else
        element:Set(cfg.Default, true)
    end
    return Base.finish(element, cfg)
end
