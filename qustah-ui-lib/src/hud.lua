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
                        self:_safe(entry.title, entry.element._onBind, entry.element)
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
        end
        self._sessionBar.bar.Visible = visible
        if visible then self._sessionBar.refresh() end
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
    end
end
