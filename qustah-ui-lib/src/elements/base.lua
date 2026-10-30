-- Shared parts of every element: the row (title + optional description), callbacks / OnChanged, flags,
-- Lock / Unlock with a reason, Flash, MoveUp / MoveDown / MoveTo / Remove, and the default save / load used by configs.
-- A callback that errors makes its element flash red and say so for a moment (the error goes to Settings › Info).
-- DependsOn: the element follows another flag -
--   DependsOn = "silentAim"                                   locked while silentAim is off
--   DependsOn = { Flag = "aimPart", Value = "Head" }          ... unless aimPart is "Head" (in a list for multi dropdowns)
--   DependsOn = { Flag = "esp", Not = true, Mode = "Hide", Reason = "..." }   Mode "Hide" hides instead of locking
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
            cover.MouseEnter:Connect(function() if self._lockReason then window:_tip(self._lockReason) end end)
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
