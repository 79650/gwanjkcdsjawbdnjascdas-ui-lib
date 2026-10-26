-- On-screen overlays outside the menu (they stay while the menu is hidden):
--   Window:KeybindList(true / false)   draggable list of bound keys; toggles that are on are bright
--   Window:SessionBar(true / false)    "60 FPS · 40 ms · 2/50 · 00:12:03" at the top of the screen
--   Window:StatsMonitor("Header" | "Floating" | "Off")   FPS / ping in the header or in a small draggable graph
-- Positions of the draggable panels are remembered with the window (see Window memory).
local Util = require("util")
local Theme = require("theme")
local Stats = require("stats")

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
        return Util.keyName(element.Value or element.BindKey)
    end
    function Window:KeybindList(visible)
        visible = visible ~= false
        if not self._keybindHud then
            local panel, handle = self:_floating("Keybinds", 210, 60, Vector2.new(0.02, 0.18))
            local caption = label(handle, "Keybinds", 10, { Position = UDim2.fromOffset(12, 3), Size = UDim2.new(1, -24, 1, -3), ZIndex = 72 })
            Theme.bind(caption, "TextColor3", "muted")
            local list = create("Frame", { Name = "List", BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 30), Size = UDim2.new(1, -24, 1, -36), ZIndex = 71, Parent = panel })
            Util.list(list, 2)
            local rows = {}
            local function row(index)
                if rows[index] then return rows[index] end
                local holder = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = index, ZIndex = 72, Parent = list })
                local name = label(holder, "", 10, { Size = UDim2.new(1, -74, 1, 0), ZIndex = 73 })
                local key = label(holder, "", 9, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 72, 1, 0), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium, ZIndex = 73 })
                Theme.bind(key, "TextColor3", "muted")
                rows[index] = { holder = holder, name = name, key = key }
                return rows[index]
            end
            local function refresh()
                local entries = { { title = "Menu", key = Util.keyName(self.key), on = true } }
                for element, bound in pairs(self.binds) do
                    if bound and element.Row and element.Row.Parent and element.Title then
                        local on = element.Type == "Toggle" and element.Value == true or element.Type ~= "Toggle"
                        entries[#entries + 1] = { title = tostring(element.Title), key = chordText(element), on = on, toggle = element.Type == "Toggle" }
                    end
                end
                table.sort(entries, function(a, b)
                    if a.on ~= b.on then return a.on end
                    return a.title < b.title
                end)
                for index, entry in ipairs(entries) do
                    local r = row(index)
                    r.holder.Visible = true
                    r.name.Text, r.key.Text = entry.title, "[" .. entry.key .. "]"
                    Theme.bind(r.name, "TextColor3", entry.on and "heading" or "muted")
                end
                for index = #entries + 1, #rows do rows[index].holder.Visible = false end
                panel.Size = UDim2.fromOffset(210, 36 + #entries * 22)
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
end
