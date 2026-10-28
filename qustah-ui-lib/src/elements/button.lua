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
--   :SetCooldown(seconds), :ResetCooldown(), :Set(value) / :Get() (Toggle), :SetOptions(list), :Select(option), :Fire()
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
local SIZES = { Small = { 22, 9, 11 }, Default = { 28, 10, 13 }, Large = { 34, 11, 15 } }
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
        Theme.tweenTo(keyText, "TextColor3", role, duration)
        keyText.TextTransparency = 0.35
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
        if selectedLabel and selectedLabel.Visible then reserved = reserved + Util.textWidth(selectedLabel.Text, textSize, Enum.Font.Gotham) + 6 end
        local room = math.max(0, math.floor(width - reserved))
        local need = Util.textWidth(textLabel.Text, textSize, Enum.Font.Gotham)
        if textLabel.Text ~= "" and need > room then
            textLabel.AutomaticSize = Enum.AutomaticSize.None
            textLabel.Size = UDim2.new(0, room, 1, 0)
            textLabel.TextTruncate = Enum.TextTruncate.AtEnd
            if cfg.Tooltip == nil then element._tooltip = textLabel.Text end
        else
            textLabel.AutomaticSize = Enum.AutomaticSize.X
            textLabel.Size = UDim2.fromScale(0, 1)
            textLabel.TextTruncate = Enum.TextTruncate.None
            if cfg.Tooltip == nil then element._tooltip = nil end
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
        end
        if not silent then run(option) end
    end
    function element:SetOptions(list)
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
        local position, buttonSize = button.AbsolutePosition, button.AbsoluteSize
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
                textLabel.Text = type(cfg.Confirm) == "string" and cfg.Confirm or "Click again to confirm"
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
