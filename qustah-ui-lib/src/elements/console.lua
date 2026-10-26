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
    local list = create("Frame", { Name = "List", BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = scroller })
    Util.list(list, 1)
    Util.padding(list, 0, 0, 0, 8)
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
