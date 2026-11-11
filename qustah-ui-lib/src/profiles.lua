-- Settings › Profiles page (used by settings.lua).
--   Current   which profile is active, how many settings changed since it was loaded / saved, Save / Revert / Share
--   New       create from the current settings, or import a share code (QUSTAH1:...)
--   Saved     search, profile cards sorted by last use (Load on each); a card's "..." opens its tools under the
--             cards: note, rename / duplicate, Load, Overwrite, Autoload, Share, Delete. "Default" is locked and holds the values the script started with.
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label
local RED, GREEN, YELLOW = "danger", "success", "warning" -- theme roles

return function(window, page, defaults)
    local store = window.Config
    store.DefaultFlags = defaults
    local refresh, updateCurrent
    local open -- expanded row
    local query = ""

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

    ------------------------------------------------------------ current
    local current = page:Card({ Title = "Current", Icon = "bookmark" })
    local activeInfo = current:Info({ Title = "Profile", Value = "Default" })
    local changesInfo = current:Info({ Title = "Changes", Value = "--" })
    local bar = create("Frame", { Name = "CurrentActions", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = current:_order(), Parent = current.body })
    Util.list(bar, 6, Enum.FillDirection.Horizontal)

    local ICONS = {
        Save = "save", Revert = "rotate-ccw", ["Share current"] = "share-2", ["What changed?"] = "list-checks",
        Load = "download", Overwrite = "upload", Autoload = "star", ["Autoload off"] = "star-off", Share = "share-2",
        Delete = "trash-2", Rename = "pencil", Duplicate = "copy",
    }
    local function smallButton(parent, text, order, style)
        local iconName = ICONS[text]
        local button = create("TextButton", {
            Name = text, Text = text, TextSize = 9, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BorderSizePixel = 0,
            Size = UDim2.fromOffset(Util.textWidth(text, 9, Enum.Font.GothamMedium) + (iconName and 34 or 20), 22), LayoutOrder = order, Parent = parent,
        })
        -- icon + text centred together; both follow the button's TextColor3 (the button's own text is hidden)
        local icon = iconName and Icons.Image(iconName, { Name = "ButtonIcon", Size = UDim2.fromOffset(11, 11) })
        if icon then
            local content = create("Frame", { Name = "Content", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, Parent = button })
            Util.list(content, 5, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
            icon.LayoutOrder = 1
            icon.Parent = content
            local text_ = label(content, text, 9, { Name = "Label", Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, TextTruncate = Enum.TextTruncate.None, Font = Enum.Font.GothamMedium, LayoutOrder = 2 })
            button.TextTransparency = 1
            local function tint() icon.ImageColor3 = button.TextColor3 text_.TextColor3 = button.TextColor3 end
            button:GetPropertyChangedSignal("TextColor3"):Connect(tint)
            task.defer(tint)
        end
        corner(button, 6)
        local outline = stroke(button)
        if style == "Danger" then
            Theme.bind(button, "BackgroundColor3", "dangerDeep")
            Theme.bind(button, "TextColor3", "dangerText")
            Theme.bind(outline, "Color", "dangerEdge")
            outline.Transparency = 0.3
        elseif style == "Primary" then
            Theme.bind(button, "BackgroundColor3", "accentDeep")
            Theme.bind(button, "TextColor3", "accent")
            Theme.bind(outline, "Color", "accent")
            outline.Transparency = 0.5
        else
            Theme.bind(button, "BackgroundColor3", "input")
            Theme.bind(button, "TextColor3", "text")
            Theme.bind(outline, "Color", "buttonEdge")
        end
        button.MouseEnter:Connect(function() if style == nil then Theme.tweenTo(button, "BackgroundColor3", "hover", 0.1) end end)
        button.MouseLeave:Connect(function() if style == nil then Theme.tweenTo(button, "BackgroundColor3", "input", 0.1) end end)
        return button
    end

    local saveButton = smallButton(bar, "Save", 1, "Primary")
    saveButton.Activated:Connect(function()
        if store.Active then saveProfile(store.Active)
        else say("Default is locked - type a name under New profile and press Create", "warn") end
    end)
    smallButton(bar, "Revert", 2).Activated:Connect(function()
        local changes = store:Changes()
        if changes == 0 then return say("Nothing to revert") end
        window:Confirm("Revert " .. changes .. " change" .. (changes == 1 and "" or "s") .. "?", "Settings go back to \"" .. (store.Active or "Default") .. "\".", function()
            local failed = store:Apply(store.ActiveFlags or defaults)
            say(failed > 0 and (failed .. " setting(s) could not be reverted") or "Reverted", failed > 0)
            updateCurrent()
        end, "Revert")
    end)
    smallButton(bar, "Share current", 3).Activated:Connect(function()
        local code = store:Export(nil)
        if code then copy(code, "Share code") end
    end)
    smallButton(bar, "What changed?", 4).Activated:Connect(function()
        local count, names = store:Changes()
        if count == 0 then return say("No changes since \"" .. (store.Active or "Default") .. "\"") end
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
            Title = count .. " change" .. (count == 1 and "" or "s"),
            Content = table.concat(shown, ", ") .. (#titles > 12 and (" and " .. (#titles - 12) .. " more") or ""),
            Buttons = { { Title = "Close" } },
        })
    end)

    function updateCurrent()
        local name = store.Active
        activeInfo:Set(name or "Default")
        activeInfo:SetColor(name and "accent" or "text")
        local changes = store:Changes()
        if changes > 0 then
            changesInfo:Set(changes .. " unsaved")
            changesInfo:SetColor(YELLOW)
        else
            changesInfo:Set("Saved")
            changesInfo:SetColor(GREEN)
        end
    end

    ------------------------------------------------------------ new / import
    -- one card, two tabs in its header; each tab is a single field with the action inside it
    local newCard = page:Card({ Title = "New profile", Icon = "plus" })
    local sections = newCard:Tabs({ "From current", "From code" })
    local function count(flags) local n = 0 for _ in pairs(flags or {}) do n = n + 1 end return n end
    sections["From current"]:ActionInput({
        Name = "CreateProfile", Icon = "plus", Placeholder = "Profile name", Button = "Create",
        Hint = "Saves your current settings as a new profile",
        Validate = function(name)
            if name:lower() == "default" then return false, "\"Default\" is reserved" end
            if name:gsub("[%w_%- ]", "") ~= "" then return false, "Letters, numbers, spaces, - and _ only" end
            if store:Exists(name) then return false, "\"" .. name .. "\" already exists - open it and press Overwrite" end
            return true, "Saves " .. count(store:Snapshot()) .. " settings as \"" .. name .. "\""
        end,
        Callback = function(name)
            if saveProfile(name) then
                open = name
                say("Created \"" .. name .. "\"")
                refresh()
            end
        end,
    })
    sections["From code"]:ActionInput({
        Name = "ImportProfile", Icon = "import", Placeholder = "Paste a QUSTAH1: code", Button = "Import",
        Hint = "Get a code with Share on any profile",
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
            open = name
            say("Imported as \"" .. name .. "\" - open it and press Load")
            refresh()
        end,
    })

    -- per-game profiles (each game gets its own list + autoload); remembered with the window
    newCard:Toggle({
        Title = "Separate profiles per game", Desc = "Each game keeps its own list and autoload", Icon = "gamepad-2",
        Default = store.perGame ~= nil,
        Callback = function(on)
            store:SetPerGame(on and "Game" or false)
            window.memory.perGame = on and "Game" or false
            window:_saveMemory()
            open = nil
            refresh()
            say(on and ("Profiles for this game (#" .. game.GameId .. ")") or "Shared profiles for all games")
        end,
    })

    ------------------------------------------------------------ saved list
    local listCard = page:Card({ Title = "Saved", Icon = "folder-open" })
    local search = create("TextBox", {
        Name = "Search", Text = "", PlaceholderText = "Search profiles...", TextSize = 10, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 26), LayoutOrder = listCard:_order(), Parent = listCard.body,
    })
    Theme.bind(search, "BackgroundColor3", "input")
    Theme.bind(search, "TextColor3", "text")
    Theme.bind(search, "PlaceholderColor3", "muted")
    corner(search, 6)
    Theme.bind(stroke(search), "Color", "buttonEdge")
    Util.padding(search, 9, 9, 0, 0)
    local holder = create("Frame", { Name = "ProfileList", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = listCard:_order(), Parent = listCard.body })
    Util.list(holder, 4)
    local empty = listCard:Label("")

    -- the profiles as cards (ItemCards): a "..." on a card opens its tools under the grid
    local PALETTE = { Color3.fromRGB(232, 232, 236), Color3.fromRGB(74, 157, 224), Color3.fromRGB(94, 196, 110), Color3.fromRGB(232, 110, 176),
        Color3.fromRGB(226, 177, 90), Color3.fromRGB(160, 125, 232), Color3.fromRGB(79, 200, 216), Color3.fromRGB(224, 106, 106) }
    local function colorOf(name)
        if name == "Default" then return PALETTE[1] end
        local sum = 0
        for i = 1, #name do sum = sum + string.byte(name, i) end
        return PALETTE[2 + sum % (#PALETTE - 1)]
    end
    local cards = listCard:ItemCards({ Columns = 2, Height = 92,
        OnAction = function(item) loadProfile(item.Title, item.Locked) end,
        OnMenu = function(item) open = open ~= item.Title and item.Title or nil refresh() end,
    })
    holder.LayoutOrder = listCard:_order() -- (the tools of the open profile come under the cards)
    if empty.Row then empty.Row.LayoutOrder = listCard:_order() end

    -- the open profile's tools (note, rename / duplicate, Load, Overwrite, Autoload, Share, Delete)
    local function profileRow(name, order, locked, autoload, info)
        if open ~= name then return end
        local frame = create("Frame", { Name = "Profile_" .. name, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, LayoutOrder = order, Parent = holder })
        Theme.bind(frame, "BackgroundColor3", "selected")
        corner(frame, 6)
        Theme.bind(stroke(frame), "Color", "buttonEdge")
        Util.list(frame, 0)
        local note = info and info.note and tostring(info.note) or nil
        local head = create("TextButton", { Name = "Head", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 1, Parent = frame })
        local title = label(head, name, 11, { Name = "Name", Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -40, 1, 0), Font = Enum.Font.GothamMedium })
        Theme.bind(title, "TextColor3", "heading")
        Icons.themed(head, "x", 12, "muted", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0) })
        head.Activated:Connect(function() open = nil refresh() end)

        local actions = create("Frame", { Name = "Actions", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = frame })
        Util.padding(actions, 12, 12, 0, 10)
        Util.list(actions, 6)
        if not locked then
            -- what this profile would change
            local flags = store:Read(name)
            local differs = flags and store:Changes(flags) or 0
            local summary = label(actions, flags and (differs == 0 and "Same as your current settings" or (differs .. (differs == 1 and " setting differs" or " settings differ") .. " from your current settings")) or "File could not be read", 9, {
                Name = "Summary", Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 0,
            })
            Theme.bind(summary, "TextColor3", "muted")
        end

        local function box(name_, placeholder, order_, width)
            local object = create("TextBox", {
                Name = name_, Text = "", PlaceholderText = placeholder, TextSize = 10, Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, BorderSizePixel = 0, Size = width, LayoutOrder = order_,
            })
            Theme.bind(object, "BackgroundColor3", "base")
            Theme.bind(object, "TextColor3", "text")
            Theme.bind(object, "PlaceholderColor3", "muted")
            corner(object, 6)
            Util.padding(object, 8, 8, 0, 0)
            return object
        end
        -- note
        if not locked then
            local noteBox = box("Note", "Add a note (e.g. ranked, low graphics)", 1, UDim2.new(1, 0, 0, 24))
            noteBox.Text = note or ""
            noteBox.Parent = actions
            noteBox.FocusLost:Connect(function()
                local text = noteBox.Text:gsub("^%s+", ""):gsub("%s+$", ""):sub(1, 60)
                touch(name, { note = text ~= "" and text or false })
                refresh()
            end)
        end
        -- name box: Rename / Duplicate
        local nameRow = create("Frame", { Name = "NameRow", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 2, Parent = actions })
        local nameBox = box("NewName", locked and "name for the copy" or "new name", 1, UDim2.new(1, locked and -90 or -176, 1, 0))
        nameBox.Parent = nameRow
        local side = create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, locked and 84 or 170, 1, 0), Parent = nameRow })
        Util.list(side, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right)
        local function typed()
            local text = nameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
            if text == "" then say("Type a name in the box", true) return nil end
            if text:lower() == "default" then say("\"Default\" is reserved", true) return nil end
            return text
        end
        if not locked then
            smallButton(side, "Rename", 1).Activated:Connect(function()
                local new = typed()
                if not new then return end
                local ok, err = store:Rename(name, new)
                if ok then local m = meta() m[new], m[name] = m[name], nil store:WriteMeta(m) open = new end
                say(ok and ("Renamed to \"" .. new .. "\"") or err, not ok)
                refresh()
            end)
        end
        smallButton(side, "Duplicate", 2).Activated:Connect(function()
            local new = typed()
            if not new then return end
            local ok, err
            if store:Exists(new) then ok, err = false, "A profile with that name exists"
            elseif locked then ok, err = store:SaveFlags(new, defaults)
            else ok, err = store:Copy(name, new) end
            if ok then touch(new, { saved = os.time(), note = "Copy of " .. name }) open = new end
            say(ok and ("Copied to \"" .. new .. "\"") or (err or "Copy failed"), not ok)
            refresh()
        end)

        local buttons = create("Frame", { Name = "Buttons", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, Parent = actions })
        local flow = Util.list(buttons, 6, Enum.FillDirection.Horizontal)
        pcall(function() flow.Wraps = true end)
        smallButton(buttons, "Load", 1, "Primary").Activated:Connect(function() loadProfile(name, locked) end)
        if not locked then
            smallButton(buttons, "Overwrite", 2).Activated:Connect(function()
                window:Confirm("Overwrite \"" .. name .. "\"?", "It will hold your current settings.", function() saveProfile(name) end, "Overwrite")
            end)
            smallButton(buttons, autoload and "Autoload off" or "Autoload", 3).Activated:Connect(function()
                if autoload then store:ClearAutoLoad() say("Autoload off")
                else store:SetAutoLoad(name) say("\"" .. name .. "\" loads on start") end
                refresh()
            end)
        end
        smallButton(buttons, "Share", 4).Activated:Connect(function()
            local code = locked and ("QUSTAH1:" .. Util.base64encode(Util.Services.HttpService:JSONEncode({ n = "Default", f = defaults }))) or store:Export(name)
            if code then copy(code, "Share code for \"" .. name .. "\"") end
        end)
        if not locked then
            smallButton(buttons, "Delete", 6, "Danger").Activated:Connect(function()
                window:Confirm("Delete \"" .. name .. "\"?", "This cannot be undone.", function()
                    local ok, err = store:Delete(name)
                    if ok then
                        local m = meta() m[name] = nil store:WriteMeta(m)
                        if store:GetAutoLoad() == name then store:ClearAutoLoad() end
                        open = nil
                    end
                    say(ok and ("Deleted \"" .. name .. "\"") or err, not ok)
                    refresh()
                end, "Delete", true)
            end)
        end
    end

    function refresh()
        for _, child in ipairs(holder:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
        local auto = store:GetAutoLoad()
        local data = meta()
        local names = {}
        for _, name in ipairs(store:List()) do if name:lower() ~= "default" then names[#names + 1] = name end end
        -- most recently used / saved first
        table.sort(names, function(a, b)
            local ta = data[a] and (data[a].used or data[a].saved) or 0
            local tb = data[b] and (data[b].used or data[b].saved) or 0
            if ta ~= tb then return ta > tb end
            return a:lower() < b:lower()
        end)
        local q = query:lower()
        local shown = 0
        local items = {}
        local function add(name, locked, autoload, info)
            local active = (locked and store.Active == nil) or store.Active == name
            local badges = {}
            if active then badges[#badges + 1] = { Text = "ACTIVE", Role = "success" } end
            if autoload then badges[#badges + 1] = "AUTO" end
            if locked then badges[#badges + 1] = "LOCKED" end
            local when = info and (info.saved or info.used)
            local count = 0
            if not locked then local flags = store:Read(name) for _ in pairs(flags or {}) do count = count + 1 end end
            items[#items + 1] = {
                Title = name, Locked = locked, Color = colorOf(name), Badges = badges, Action = "Load", Highlight = active or open == name,
                Sub = (when and os.date("%d %b", when) or (locked and "starting values" or "")) .. (count > 0 and (" · " .. count .. " settings") or ""),
                Desc = info and info.note and tostring(info.note) or (locked and "The values the script started with" or ""),
            }
            profileRow(name, #items, locked, autoload, info)
            shown = shown + 1
        end
        if q == "" or ("default"):find(q, 1, true) then add("Default", true, auto == nil, nil) end
        for _, name in ipairs(names) do
            local info = data[name]
            local note = info and info.note and tostring(info.note):lower() or ""
            if q == "" or name:lower():find(q, 1, true) or note:find(q, 1, true) then add(name, false, auto == name, info) end
        end
        cards:SetItems(items)
        search.Visible = #names > 3 or q ~= ""
        empty:Set(#names == 0 and "No saved profiles yet - create one above." or (shown == 0 and "No profile matches \"" .. query .. "\"" or ""))
        empty:SetVisible(#names == 0 or shown == 0)
        updateCurrent()
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
