-- Settings › Profiles page (used by settings.lua): one full-width card.
--   Top      the active profile, "· N unsaved" (click: what changed), Revert, Save
--   Search   shown when there are more than 3 profiles (name or note)
--   Table    Name (colour dot, ACTIVE / AUTO / LOCKED tags), Note, Saved, Settings, Differs (how many settings the
--            profile would change), Auto (loads on start), Load, and share / duplicate / delete icons.
--            Click Name, Saved, Settings or Differs to sort. Right click a row (long press on touch) for
--            Overwrite, Rename, Edit note, Duplicate, Share code, Delete. "Default" is locked: the starting values.
--   Bottom   New profile name + Create, Paste a share code + Import
--   Share    the active profile's share code with a Copy button
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label
local RED, GREEN, YELLOW = "danger", "success", "warning" -- theme roles

local ROW, HEAD = 30, 24
local AUTO_W, LOAD_W, ACTIONS_W = 40, 52, 70
local FIXED = AUTO_W + LOAD_W + ACTIONS_W
-- the columns left of the fixed ones share what is left: key, title, part, sortable
local COLUMNS = {
    { key = "name", title = "Name", part = 0.31, sort = true },
    { key = "note", title = "Note", part = 0.27 },
    { key = "saved", title = "Saved", part = 0.15, sort = true },
    { key = "count", title = "Settings", part = 0.14, sort = true },
    { key = "differs", title = "Differs", part = 0.13, sort = true },
}

return function(window, page, defaults)
    local store = window.Config
    store.DefaultFlags = defaults
    local refresh, updateCurrent
    local query = ""
    local sortKey, descending = "saved", true

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
    local function count(flags) local n = 0 for _ in pairs(flags or {}) do n = n + 1 end return n end
    local function trim(text) return (tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
    local function badName(name)
        if name == "" then return "Type a name" end
        if name:lower() == "default" then return "\"Default\" is reserved" end
        if name:gsub("[%w_%- ]", "") ~= "" then return "Letters, numbers, spaces, - and _ only" end
        return nil
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
    -- a profile's share code ("Default" is the starting values)
    local function shareCodeOf(name, locked)
        if locked then return "QUSTAH1:" .. Util.base64encode(Util.Services.HttpService:JSONEncode({ n = "Default", f = defaults })) end
        return store:Export(name)
    end
    local function shareProfile(name, locked)
        local code = shareCodeOf(name, locked)
        if code then copy(code, "Share code for \"" .. name .. "\"") end
    end
    local function overwriteProfile(name)
        window:Confirm("Overwrite \"" .. name .. "\"?", "It will hold your current settings.", function() saveProfile(name) end, "Overwrite")
    end
    local function renameProfile(name)
        window:Dialog({
            Title = "Rename \"" .. name .. "\"", Icon = "pencil", Input = { Text = name, Placeholder = "New name" },
            Buttons = { { Title = "Cancel" }, { Title = "Rename", Style = "Primary", Callback = function(text)
                local new = trim(text)
                if new == name then return end
                local bad = badName(new)
                if bad then return say(bad, true) end
                local ok, err = store:Rename(name, new)
                if ok then local m = meta() m[new], m[name] = m[name], nil store:WriteMeta(m) end
                say(ok and ("Renamed to \"" .. new .. "\"") or err, not ok)
                refresh()
            end } },
        })
    end
    local function editNote(name, note)
        window:Dialog({
            Title = "Note for \"" .. name .. "\"", Icon = "sticky-note", Input = { Text = note or "", Placeholder = "e.g. ranked, low graphics" },
            Buttons = { { Title = "Cancel" }, { Title = "Save", Style = "Primary", Callback = function(text)
                text = trim(text):sub(1, 60)
                touch(name, { note = text ~= "" and text or false })
                refresh()
            end } },
        })
    end
    local function duplicateProfile(name, locked)
        window:Dialog({
            Title = "Duplicate \"" .. name .. "\"", Icon = "copy", Input = { Text = store:FreeName(name), Placeholder = "Name for the copy" },
            Buttons = { { Title = "Cancel" }, { Title = "Duplicate", Style = "Primary", Callback = function(text)
                local new = trim(text)
                local bad = badName(new)
                if bad then return say(bad, true) end
                if store:Exists(new) then return say("A profile with that name exists", true) end
                local ok, err
                if locked then ok, err = store:SaveFlags(new, defaults) else ok, err = store:Copy(name, new) end
                if ok then touch(new, { saved = os.time(), note = "Copy of " .. name }) end
                say(ok and ("Copied to \"" .. new .. "\"") or (err or "Copy failed"), not ok)
                refresh()
            end } },
        })
    end
    local function deleteProfile(name)
        window:Confirm("Delete \"" .. name .. "\"?", "This cannot be undone.", function()
            local ok, err = store:Delete(name)
            if ok then
                local m = meta() m[name] = nil store:WriteMeta(m)
                if store:GetAutoLoad() == name then store:ClearAutoLoad() end
            end
            say(ok and ("Deleted \"" .. name .. "\"") or err, not ok)
            refresh()
        end, "Delete", true)
    end
    local function setAuto(name, locked, on)
        if locked or not on then
            if store:GetAutoLoad() then store:ClearAutoLoad() say("Nothing loads on start") end
        else
            store:SetAutoLoad(name)
            say("\"" .. name .. "\" loads on start")
        end
        refresh()
    end
    local function openMenu(row, info)
        local name, locked = info.name, info.locked
        local items = {}
        if not locked then
            items[#items + 1] = { Title = "Overwrite", Icon = "upload", Callback = function() overwriteProfile(name) end }
            items[#items + 1] = { Title = "Rename", Icon = "pencil", Callback = function() renameProfile(name) end }
            items[#items + 1] = { Title = "Edit note", Icon = "sticky-note", Callback = function() editNote(name, info.note) end }
        end
        items[#items + 1] = { Title = "Duplicate", Icon = "copy", Callback = function() duplicateProfile(name, locked) end }
        items[#items + 1] = { Title = "Share code", Icon = "share-2", Callback = function() shareProfile(name, locked) end }
        if not locked then
            items[#items + 1] = { Title = "Delete", Icon = "trash-2", Style = "Danger", Callback = function() deleteProfile(name) end }
        end
        window:Menu({ Items = items, Owner = row })
    end

    ------------------------------------------------------------ small buttons (Save, Revert, Load): text only
    local function smallButton(parent, text, order, style)
        local button = create("TextButton", {
            Name = text, Text = text, TextSize = 9, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BorderSizePixel = 0,
            Size = UDim2.fromOffset(Util.textWidth(text, 9, Enum.Font.GothamMedium) + 20, 22), LayoutOrder = order, Parent = parent,
        })
        corner(button, 6)
        local outline = stroke(button)
        if style == "Primary" then
            Theme.bind(button, "BackgroundColor3", "accentDeep")
            Theme.bind(button, "TextColor3", "accent")
            Theme.bind(outline, "Color", "accent")
            outline.Transparency = 0.5
        else
            Theme.bind(button, "BackgroundColor3", "input")
            Theme.bind(button, "TextColor3", "text")
            Theme.bind(outline, "Color", "buttonEdge")
            button.MouseEnter:Connect(function() Theme.tweenTo(button, "BackgroundColor3", "hover", 0.1) end)
            button.MouseLeave:Connect(function() Theme.tweenTo(button, "BackgroundColor3", "input", 0.1) end)
        end
        return button
    end

    local card = page:Card({ Title = "Profiles", Icon = "list" })

    ------------------------------------------------------------ top: active profile, unsaved, Revert / Save
    local top = create("Frame", { Name = "Current", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = card:_order(), Parent = card.body })
    local activeName = label(top, "Default", 13, { Name = "Profile", Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, TextTruncate = Enum.TextTruncate.None, Font = Enum.Font.GothamMedium })
    Theme.bind(activeName, "TextColor3", "heading")
    local changesButton = create("TextButton", { Name = "Changes", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(0, 120, 1, 0), Parent = top })
    local changesText = label(changesButton, "", 10, { Name = "Text", Size = UDim2.fromScale(1, 1) })
    local topButtons = create("Frame", { Name = "Buttons", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 200, 0, 22), Parent = top })
    Util.list(topButtons, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right)
    smallButton(topButtons, "Revert", 1).Activated:Connect(function()
        local changes = store:Changes()
        if changes == 0 then return say("Nothing to revert") end
        window:Confirm("Revert " .. changes .. " change" .. (changes == 1 and "" or "s") .. "?", "Settings go back to \"" .. (store.Active or "Default") .. "\".", function()
            local failed = store:Apply(store.ActiveFlags or defaults)
            say(failed > 0 and (failed .. " setting(s) could not be reverted") or "Reverted", failed > 0)
            refresh()
        end, "Revert")
    end)
    smallButton(topButtons, "Save", 2, "Primary").Activated:Connect(function()
        if store.Active then saveProfile(store.Active)
        else say("Default is locked - type a name under the table and press Create", "warn") end
    end)
    changesButton.Activated:Connect(function()
        local changes, names = store:Changes()
        if changes == 0 then return say("No changes since \"" .. (store.Active or "Default") .. "\"") end
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
            Title = changes .. " change" .. (changes == 1 and "" or "s"),
            Content = table.concat(shown, ", ") .. (#titles > 12 and (" and " .. (#titles - 12) .. " more") or ""),
            Buttons = { { Title = "Close" } },
        })
    end)

    function updateCurrent()
        activeName.Text = store.Active or "Default"
        local changes = store:Changes()
        changesText.Text = changes > 0 and ("· " .. changes .. " unsaved") or "· saved"
        Theme.bind(changesText, "TextColor3", changes > 0 and YELLOW or "muted")
        changesButton.Position = UDim2.new(0, Util.textWidth(activeName.Text, 13, Enum.Font.GothamMedium) + 7, 0, 0)
    end

    ------------------------------------------------------------ search
    local search = create("TextBox", {
        Name = "Search", Text = "", PlaceholderText = "Search profiles...", TextSize = 10, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 26), LayoutOrder = card:_order(), Parent = card.body,
    })
    Theme.bind(search, "BackgroundColor3", "input")
    Theme.bind(search, "TextColor3", "text")
    Theme.bind(search, "PlaceholderColor3", "muted")
    corner(search, 6)
    Theme.bind(stroke(search), "Color", "buttonEdge")
    Util.padding(search, 9, 9, 0, 0)

    ------------------------------------------------------------ table
    local box = create("Frame", { Name = "ProfileTable", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = card:_order(), Parent = card.body })
    Theme.bind(box, "BackgroundColor3", "base")
    corner(box, 7)
    Theme.bind(stroke(box), "Color", "line")
    Util.list(box, 0)

    -- (x, width) of a scaled column: the scaled ones share the width left of the fixed columns
    local function span(index)
        local start = 0
        for i = 1, index - 1 do start = start + COLUMNS[i].part end
        local part = COLUMNS[index].part
        return UDim2.new(start, -FIXED * start + 10, 0, 0), UDim2.new(part, -FIXED * part - 12, 1, 0)
    end
    local function fixedX(offset) return UDim2.new(1, -FIXED + offset, 0, 0) end

    local head = create("Frame", { Name = "Head", Size = UDim2.new(1, 0, 0, HEAD), BorderSizePixel = 0, LayoutOrder = 0, Parent = box })
    Theme.bind(head, "BackgroundColor3", "input")
    local headers = {}
    for index, column in ipairs(COLUMNS) do
        local position, size = span(index)
        local button = create("TextButton", { Name = column.title, Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = position, Size = size, Parent = head })
        local text = label(button, column.title, 9, { Name = "Text", Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamMedium })
        Theme.bind(text, "TextColor3", "muted")
        headers[column.key] = { text = text }
        if column.sort then
            button.Activated:Connect(function()
                if sortKey == column.key then descending = not descending
                else sortKey, descending = column.key, column.key ~= "name" end
                refresh()
            end)
        end
    end
    local autoHead = label(head, "Auto", 9, { Name = "Auto", Position = fixedX(6), Size = UDim2.new(0, AUTO_W, 1, 0), Font = Enum.Font.GothamMedium })
    Theme.bind(autoHead, "TextColor3", "muted")
    local rowsFrame = create("Frame", { Name = "Rows", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = box })
    Util.list(rowsFrame, 0)
    local empty = label(card.body, "", 9, { Name = "Empty", Size = UDim2.new(1, 0, 0, 14), LayoutOrder = card:_order(), Visible = false })
    Theme.bind(empty, "TextColor3", "muted")

    -- the colour of a profile: Default white, the others from the name
    local PALETTE = { Color3.fromRGB(232, 232, 236), Color3.fromRGB(74, 157, 224), Color3.fromRGB(94, 196, 110), Color3.fromRGB(232, 110, 176),
        Color3.fromRGB(226, 177, 90), Color3.fromRGB(160, 125, 232), Color3.fromRGB(79, 200, 216), Color3.fromRGB(224, 106, 106) }
    local function colorOf(name)
        if name == "Default" then return PALETTE[1] end
        local sum = 0
        for i = 1, #name do sum = sum + string.byte(name, i) end
        return PALETTE[2 + sum % (#PALETTE - 1)]
    end

    local function iconButton(parent, iconName, x, hoverRole, tip, callback)
        local button = create("ImageButton", { Name = tip, BackgroundTransparency = 1, AutoButtonColor = false, AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, x, 0.5, 0), Size = UDim2.fromOffset(18, 18), Image = "", Parent = parent })
        local icon = Icons.themed(button, iconName, 12, "muted", { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
        button.MouseEnter:Connect(function() if icon then Theme.bind(icon, "ImageColor3", hoverRole) end window:_tip(tip) end)
        button.MouseLeave:Connect(function() if icon then Theme.bind(icon, "ImageColor3", "muted") end window:_hideTip() end)
        button.Activated:Connect(function() window:_safe("Profiles", callback) end)
        return button
    end
    local function switch(parent, on, callback)
        local track = create("TextButton", { Name = "Auto", Text = "", AutoButtonColor = false, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.fromOffset(24, 13), Parent = parent })
        corner(track, 7)
        Theme.bind(track, "BackgroundColor3", on and "accent" or "line")
        local knob = create("Frame", { Name = "Knob", BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, on and 13 or 2, 0.5, 0), Size = UDim2.fromOffset(9, 9), Parent = track })
        corner(knob, 5)
        Theme.bind(knob, "BackgroundColor3", on and "base" or "muted")
        track.Activated:Connect(function() window:_safe("Profiles", callback, not on) end)
        return track
    end

    local function drawRow(info, order)
        local row = create("TextButton", { Name = "Profile_" .. info.name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundTransparency = info.active and 0 or 1,
            Size = UDim2.new(1, 0, 0, ROW), LayoutOrder = order, Parent = rowsFrame })
        Theme.bind(row, "BackgroundColor3", info.active and "selected" or "hover")
        local line = create("Frame", { Name = "Line", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = row })
        Theme.bind(line, "BackgroundColor3", "line")
        line.BackgroundTransparency = 0.4
        if not info.active then
            row.MouseEnter:Connect(function() Util.tween(row, 0.08, { BackgroundTransparency = 0 }) end)
            row.MouseLeave:Connect(function() Util.tween(row, 0.08, { BackgroundTransparency = 1 }) end)
        end

        -- name: dot, name, tags
        local position, size = span(1)
        -- dot, name and tags side by side by their real widths (a list layout, no estimate); a tag that does not fit
        -- in the cell is left out (the last one first) instead of being cut in half
        local nameCell = create("Frame", { Name = "Name", BackgroundTransparency = 1, Position = position, Size = size, ClipsDescendants = true, Parent = row })
        local cellList = Util.list(nameCell, 6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
        local dot = create("Frame", { Name = "Dot", BorderSizePixel = 0, Size = UDim2.fromOffset(7, 7), BackgroundColor3 = colorOf(info.name), LayoutOrder = 1, Parent = nameCell })
        corner(dot, 4)
        local nameText = label(nameCell, info.name, 10, { Name = "Text", Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, TextTruncate = Enum.TextTruncate.None, Font = Enum.Font.GothamMedium, LayoutOrder = 2 })
        Theme.bind(nameText, "TextColor3", info.active and "heading" or "text")
        local tags = create("Frame", { Name = "Tags", BackgroundTransparency = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 3, Parent = nameCell })
        Util.list(tags, 3, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
        local chips = {}
        for tagOrder, tag in ipairs(info.tags) do
            -- as wide as its word (padding left and right), not a 9 px chip squeezed down to 7 px text
            local chip = create("Frame", { Name = "Chip", Size = UDim2.fromOffset(0, 14), AutomaticSize = Enum.AutomaticSize.X, BorderSizePixel = 0, LayoutOrder = tagOrder, Parent = tags })
            Theme.bind(chip, "BackgroundColor3", "input")
            corner(chip, 4)
            Theme.bind(stroke(chip, nil, 0.3), "Color", "buttonEdge")
            Util.padding(chip, 5, 5, 0, 0)
            local text = label(chip, tag[1], 7, { Name = "Text", Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, TextTruncate = Enum.TextTruncate.None, Font = Enum.Font.GothamMedium })
            Theme.bind(text, "TextColor3", tag[2])
            chips[#chips + 1] = chip
        end
        local function fitTags()
            if cellList.AbsoluteContentSize.X <= nameCell.AbsoluteSize.X + 1 then return end
            for index = #chips, 1, -1 do
                if chips[index].Visible then chips[index].Visible = false return end
            end
        end
        cellList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fitTags)
        task.defer(fitTags)

        local function cell(index, text, role)
            local p, s = span(index)
            local object = label(row, text, 9, { Name = COLUMNS[index].title, Position = p, Size = s })
            Theme.bind(object, "TextColor3", role)
            return object
        end
        cell(2, info.note or "", "muted")
        cell(3, info.when, "text")
        cell(4, info.count and tostring(info.count) or "—", "text")
        cell(5, info.differs and tostring(info.differs) or "—", info.active and info.differs and info.differs > 0 and YELLOW or "text")

        local fixed = create("Frame", { Name = "Fixed", BackgroundTransparency = 1, Position = fixedX(0), Size = UDim2.new(0, FIXED, 1, 0), Parent = row })
        switch(fixed, info.auto, function(on) setAuto(info.name, info.locked, on) end)
        if not info.active then
            local load = smallButton(fixed, "Load", 0)
            load.AnchorPoint = Vector2.new(0, 0.5)
            load.Position = UDim2.new(0, AUTO_W, 0.5, 0)
            load.Size = UDim2.fromOffset(LOAD_W - 8, 20)
            load.Activated:Connect(function() loadProfile(info.name, info.locked) end)
        end
        local x = AUTO_W + LOAD_W
        iconButton(fixed, "share-2", x, "heading", "Share code", function() shareProfile(info.name, info.locked) end)
        iconButton(fixed, "copy", x + 21, "heading", "Duplicate", function() duplicateProfile(info.name, info.locked) end)
        if not info.locked then
            iconButton(fixed, "trash-2", x + 42, RED, "Delete", function() deleteProfile(info.name) end)
        end

        -- right click (long press on touch): the row's menu
        row.MouseButton2Click:Connect(function() openMenu(row, info) end)
        local pressed = 0
        row.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Touch then return end
            pressed = pressed + 1
            local mine = pressed
            task.delay(0.5, function() if pressed == mine and row.Parent then openMenu(row, info) end end)
        end)
        row.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then pressed = pressed + 1 end end)
        return row
    end

    ------------------------------------------------------------ bottom: create / import
    local bottom = create("Frame", { Name = "Bottom", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = card:_order(), Parent = card.body })
    Util.list(bottom, 8, Enum.FillDirection.Horizontal)
    local create_ = card:ActionInput({
        Name = "CreateProfile", Icon = "plus", Placeholder = "New profile name", Button = "Create",
        Hint = "Saves your current settings",
        Validate = function(name)
            local bad = badName(name)
            if bad then return false, bad end
            if store:Exists(name) then return false, "\"" .. name .. "\" exists - right click it › Overwrite" end
            return true, "Saves " .. count(store:Snapshot()) .. " settings as \"" .. name .. "\""
        end,
        Callback = function(name)
            if saveProfile(name) then say("Created \"" .. name .. "\"") end
        end,
    })
    local import = card:ActionInput({
        Name = "ImportProfile", Icon = "import", Placeholder = "Paste a share code", Button = "Import",
        Hint = "Get one with the share icon on a row",
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
            say("Imported as \"" .. name .. "\" - press Load on its row")
            refresh()
        end,
    })
    for order, element in ipairs({ create_, import }) do
        element.Row.Parent = bottom
        element.Row.LayoutOrder = order
        element.Row.Size = UDim2.new(0.5, -4, 0, 0)
    end

    ------------------------------------------------------------ share
    -- the active profile's share code, ready to copy (paste it into Import on another PC or for a friend)
    local shareCard = page:Card({}) -- (a plain card: no title row, just the code block)
    local shareCode = shareCard:Code({ Title = "share code", Code = "", CopyText = false, Highlight = false, Truncate = true })
    local function updateShare()
        local name = store.Active or "Default"
        local code = shareCodeOf(name, store.Active == nil)
        if code and code ~= shareCode.Value then shareCode:Set(code) end
    end

    ------------------------------------------------------------ refresh
    function refresh()
        for _, child in ipairs(rowsFrame:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
        local auto = store:GetAutoLoad()
        local data = meta()
        local rows = {}
        local function add(name, locked)
            local info = data[name] or {}
            local flags = locked and defaults or store:Read(name)
            local when = info.saved or info.used
            local note = locked and "Starting values" or (info.note and tostring(info.note) or nil)
            local active = (locked and store.Active == nil) or store.Active == name
            local tags = {}
            if active then tags[#tags + 1] = { "ACTIVE", GREEN } end
            if locked then tags[#tags + 1] = { "LOCKED", "muted" } end
            rows[#rows + 1] = {
                name = name, locked = locked, active = active, note = note, time = when or 0,
                when = locked and "script" or (when and Util.ago(when) or "—"),
                count = not locked and flags and count(flags) or nil,
                differs = flags and store:Changes(flags) or nil,
                auto = locked and auto == nil or auto == name,
            }
            rows[#rows].tags = tags
        end
        local names = {}
        for _, name in ipairs(store:List()) do if name:lower() ~= "default" then names[#names + 1] = name end end
        local q = query:lower()
        for _, name in ipairs(names) do
            local note = data[name] and data[name].note and tostring(data[name].note):lower() or ""
            if q == "" or name:lower():find(q, 1, true) or note:find(q, 1, true) then add(name, false) end
        end
        table.sort(rows, function(a, b)
            local x, y
            if sortKey == "name" then x, y = a.name:lower(), b.name:lower()
            elseif sortKey == "count" then x, y = a.count or -1, b.count or -1
            elseif sortKey == "differs" then x, y = a.differs or -1, b.differs or -1
            else x, y = a.time, b.time end
            if x == y then return a.name:lower() < b.name:lower() end
            if descending then return x > y end
            return x < y
        end)
        -- Default always first
        if q == "" or ("default"):find(q, 1, true) or ("starting values"):find(q, 1, true) then
            add("Default", true)
            table.insert(rows, 1, table.remove(rows))
        end
        for order, info in ipairs(rows) do drawRow(info, order) end
        for key, header in pairs(headers) do
            local on = sortKey == key
            -- (the sorted column's title is in the accent colour; no arrow)
            Theme.bind(header.text, "TextColor3", on and "accent" or "muted")
        end
        search.Visible = #names > 3 or q ~= ""
        empty.Text = #names == 0 and "No saved profiles yet - type a name below and press Create." or (#rows == 0 and ("No profile matches \"" .. query .. "\"") or "")
        empty.Visible = empty.Text ~= ""
        updateCurrent()
        updateShare()
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
