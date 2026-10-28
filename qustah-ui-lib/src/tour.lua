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

return function(Window)
    local function guiOf(window, target)
        if typeof(target) == "Instance" then return target end
        if type(target) == "string" then
            local name = target:lower()
            if name == "dock" then return window.dock end
            if name == "header" then return window.main and window.main:FindFirstChild("Header") end
            if name == "footer" then return window.footer end
            if name == "status" then return window.statusLabel end
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
            { Target = "status", Title = "Status", Text = "Green means everything works. If a feature fails, it turns red and Settings > Info says why." },
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
            for _ = 1, 40 do
                if not self.alive then return end
                if not self._dialog and self.visible then break end
                task.wait(0.5)
            end
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
            if s and s.X > 0 then
                x, y, w, h = p.X - PAD, p.Y - PAD, s.X + PAD * 2, s.Y + PAD * 2
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
        show(1)
        return tour
    end
end
