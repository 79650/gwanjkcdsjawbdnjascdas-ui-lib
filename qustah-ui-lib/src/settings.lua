-- Window:SettingsTab({ Title, Icon, Divider }) - ready-made tab (create it LAST, after every other tab):
--   Interface  accent presets + custom colour, text glow, menu key, overlays (keybind list, session bar,
--              performance monitor), window reset / unload
--   Profiles   profile manager: create, load, overwrite, rename, duplicate, delete, autoload; a locked
--              "Default" profile holds the values the script started with
--   Info       versions, modules, error list with Copy report / Clear
local Util = require("util")
local Theme = require("theme")
local Glow = require("glow")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label
local RED, GREEN = Color3.fromRGB(215, 130, 130), Color3.fromRGB(110, 200, 130)

return function(window, cfg)
    cfg = cfg or {}
    local defaultSize = Vector2.new(window.width, window.height)
    local tab = window:Tab({ Title = cfg.Title or "Settings", Icon = cfg.Icon or "rbxassetid://11385220704", Divider = cfg.Divider ~= false, Header = cfg.Header ~= false })
    local interface = tab:Page("Interface")
    local profiles = tab:Page("Profiles", { Columns = 1 })
    local infoPage = tab:Page("Info")

    ------------------------------------------------------------ interface
    local look = interface:Card({ Title = "Appearance", Side = "Left" })
    local picker
    local swatches = look:Swatches({
        Title = "Accent", Default = "Neutral",
        Callback = function(color) if picker then picker:Set(color) end end,
    })
    picker = look:ColorPicker({
        Title = "Custom accent", Desc = "Any colour, saved with the profile", Flag = "__ui_accent", Default = Theme.get("accent"),
        Callback = function(color) Theme.set("accent", color) swatches:Set(color, true) end,
    })
    swatches:Set(Theme.get("accent"), true)
    look:Toggle({
        Title = "Text glow", Desc = "Shine on the title and highlights", Flag = "__ui_glow", Default = Glow.enabled,
        Callback = function(on) Glow.setEnabled(on) end,
    })

    local menu = interface:Card({ Title = "Menu", Side = "Right" })
    local menuKey = menu:Keybind({
        Title = "Menu key", Desc = "Opens and closes the menu", Flag = "__ui_menu_key", Default = window.key,
        Callback = function(key) window:SetToggleKey(key) end,
    })
    window._menuListeners = window._menuListeners or {}
    table.insert(window._menuListeners, function(key) if menuKey.Value ~= key then menuKey:Set(key, true) end end)
    menu:Button({
        Title = "Reset window size / position",
        Callback = function()
            window.width, window.height, window.topLeft = defaultSize.X, defaultSize.Y, nil
            window.memory.window = nil
            window:_layout()
            window:_saveMemory()
        end,
    })
    menu:Button({
        Title = "Unload",
        Callback = function()
            window:Confirm("Unload " .. window.Title .. "?", "The menu and everything it runs will be removed.", function() window:Destroy() end, "Unload", true)
        end,
    })

    local overlays = interface:Card({ Title = "Overlays", Side = "Right" })
    overlays:Toggle({ Title = "Keybind list", Desc = "Bound keys on screen", Flag = "__ui_hud_keys", Callback = function(on) window:KeybindList(on) end })
    overlays:Toggle({ Title = "Session bar", Desc = "FPS · ping · players · time", Flag = "__ui_hud_session", Callback = function(on) window:SessionBar(on) end })
    overlays:Dropdown({
        Title = "Performance", Options = { "Off", "Header", "Floating" }, Default = "Off", Flag = "__ui_hud_stats",
        Callback = function(mode) window:StatsMonitor(mode) end,
    })

    ------------------------------------------------------------ profiles
    local store = window.Config
    local defaults = store:Snapshot() -- values every flag had before any profile was loaded
    local manager = profiles:Card({ Title = "Profiles" })
    local nameInput = manager:Input({ Title = "New profile", Placeholder = "profile name" })
    local feedback
    local refresh
    local function say(text, bad)
        feedback:Set(text)
        feedback:SetColor(bad and RED or GREEN)
    end
    manager:Button({
        Title = "Create from current settings",
        Callback = function()
            local name = nameInput.Value
            if not name or name == "" then return say("Type a name first", true) end
            if name:lower() == "default" then return say("\"Default\" is reserved", true) end
            if store:Exists(name) then return say("\"" .. name .. "\" already exists - open it and press Overwrite", true) end
            local ok, err = store:Save(name)
            if ok then
                local meta = store:ReadMeta()
                meta[name] = { saved = os.time() }
                store:WriteMeta(meta)
                nameInput:Set("", true)
            end
            say(ok and ("Created \"" .. name .. "\"") or err, not ok)
            refresh()
        end,
    })
    feedback = manager:Label("")

    local listCard = profiles:Card({ Title = "Saved" })
    local holder = create("Frame", { Name = "ProfileList", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = listCard:_order(), Parent = listCard.body })
    Util.list(holder, 4)
    local open -- name of the expanded profile

    local function smallButton(parent, text, order, style)
        local button = create("TextButton", {
            Name = text, Text = text, TextSize = 9, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BorderSizePixel = 0,
            Size = UDim2.fromOffset(Util.textWidth(text, 9, Enum.Font.GothamMedium) + 18, 22), LayoutOrder = order, Parent = parent,
        })
        corner(button, 6)
        local outline = stroke(button)
        if style == "Danger" then
            button.BackgroundColor3, button.TextColor3, outline.Color, outline.Transparency = Color3.fromRGB(70, 32, 36), Color3.fromRGB(235, 150, 155), Color3.fromRGB(150, 60, 66), 0.3
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
        return button
    end

    local function profileRow(name, order, locked, autoload, meta)
        local frame = create("Frame", { Name = "Profile_" .. name, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, LayoutOrder = order, Parent = holder })
        Theme.bind(frame, "BackgroundColor3", open == name and "selected" or "input")
        corner(frame, 6)
        Theme.bind(stroke(frame), "Color", open == name and "buttonEdge" or "line")
        Util.list(frame, 0)
        local head = create("TextButton", { Name = "Head", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 1, Parent = frame })
        local dot = create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, Parent = head })
        Theme.bind(dot, "BackgroundColor3", autoload and "accent" or "buttonEdge")
        corner(dot, 3)
        local title = label(head, name, 11, { Position = UDim2.fromOffset(26, 0), Size = UDim2.new(0.5, -26, 1, 0), Font = Enum.Font.GothamMedium })
        Theme.bind(title, "TextColor3", open == name and "heading" or "text")
        local tags = {}
        if locked then tags[#tags + 1] = "locked" end
        if autoload then tags[#tags + 1] = "autoload" end
        if meta and meta.saved then tags[#tags + 1] = os.date("%d %b %H:%M", meta.saved) end
        local info = label(head, table.concat(tags, "  ·  "), 9, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0.5, -12, 1, 0), TextXAlignment = Enum.TextXAlignment.Right })
        Theme.bind(info, "TextColor3", "muted")
        head.Activated:Connect(function()
            open = open ~= name and name or nil
            refresh()
        end)
        if open ~= name then return end

        local actions = create("Frame", { Name = "Actions", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = frame })
        Util.padding(actions, 12, 12, 0, 10)
        Util.list(actions, 6)
        local buttons = create("Frame", { Name = "Buttons", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = actions })
        local flow = Util.list(buttons, 6, Enum.FillDirection.Horizontal)
        pcall(function() flow.Wraps = true end)

        smallButton(buttons, "Load", 1, "Primary").Activated:Connect(function()
            if locked then
                local failed = store:Apply(defaults)
                say(failed > 0 and (failed .. " setting(s) could not be reset") or "Default settings restored", failed > 0)
            else
                local ok, err = store:Load(name)
                say(ok and (err or ("Loaded \"" .. name .. "\"")) or err, not ok)
            end
        end)
        if not locked then
            smallButton(buttons, "Overwrite", 2).Activated:Connect(function()
                window:Confirm("Overwrite \"" .. name .. "\"?", "It will hold your current settings.", function()
                    local ok, err = store:Save(name)
                    if ok then local m = store:ReadMeta() m[name] = { saved = os.time() } store:WriteMeta(m) end
                    say(ok and ("Saved \"" .. name .. "\"") or err, not ok)
                    refresh()
                end, "Overwrite")
            end)
        end
        if not locked then -- Default is what you get when no profile autoloads
            smallButton(buttons, autoload and "Autoload off" or "Autoload", 3).Activated:Connect(function()
                if autoload then store:ClearAutoLoad() say("Autoload off")
                else store:SetAutoLoad(name) say("\"" .. name .. "\" loads on start") end
                refresh()
            end)
        end
        if not locked then
            smallButton(buttons, "Delete", 6, "Danger").Activated:Connect(function()
                window:Confirm("Delete \"" .. name .. "\"?", "This cannot be undone.", function()
                    local ok, err = store:Delete(name)
                    if ok then
                        local m = store:ReadMeta() m[name] = nil store:WriteMeta(m)
                        if store:GetAutoLoad() == name then store:ClearAutoLoad() end
                        open = nil
                    end
                    say(ok and ("Deleted \"" .. name .. "\"") or err, not ok)
                    refresh()
                end, "Delete", true)
            end)
        end

        -- name box: Rename / Duplicate use it
        local nameRow = create("Frame", { Name = "NameRow", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 1, Parent = actions })
        local box = create("TextBox", {
            Name = "NewName", Text = "", PlaceholderText = locked and "name for the copy" or "new name", TextSize = 10, Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, BorderSizePixel = 0, Size = UDim2.new(1, locked and -86 or -172, 1, 0), Parent = nameRow,
        })
        Theme.bind(box, "BackgroundColor3", "base")
        Theme.bind(box, "TextColor3", "text")
        Theme.bind(box, "PlaceholderColor3", "muted")
        corner(box, 6)
        Util.padding(box, 8, 8, 0, 0)
        local side = create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, locked and 80 or 166, 1, 0), Parent = nameRow })
        Util.list(side, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right)
        local function typed()
            local text = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
            if text == "" then say("Type a name in the box", true) return nil end
            if text:lower() == "default" then say("\"Default\" is reserved", true) return nil end
            return text
        end
        if not locked then
            smallButton(side, "Rename", 1).Activated:Connect(function()
                local new = typed()
                if not new then return end
                local ok, err = store:Rename(name, new)
                if ok then local m = store:ReadMeta() m[new], m[name] = m[name], nil store:WriteMeta(m) open = new end
                say(ok and ("Renamed to \"" .. new .. "\"") or err, not ok)
                refresh()
            end)
        end
        smallButton(side, "Duplicate", 2).Activated:Connect(function()
            local new = typed()
            if not new then return end
            local ok, err
            if locked then
                if store:Exists(new) then ok, err = false, "A profile with that name exists"
                else
                    ok, err = store:SaveFlags(new, defaults) -- the default values as a normal profile
                end
            else
                ok, err = store:Copy(name, new)
            end
            if ok then local m = store:ReadMeta() m[new] = { saved = os.time() } store:WriteMeta(m) open = new end
            say(ok and ("Copied to \"" .. new .. "\"") or (err or "Copy failed"), not ok)
            refresh()
        end)
    end

    function refresh()
        for _, child in ipairs(holder:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
        local auto = store:GetAutoLoad()
        local meta = store:ReadMeta()
        profileRow("Default", 1, true, auto == nil, nil)
        for index, name in ipairs(store:List()) do
            if name:lower() ~= "default" then profileRow(name, index + 1, false, auto == name, meta[name]) end
        end
    end
    refresh()
    -- files may change outside the menu (another script, Config:Save) - re-read when the page is shown
    profiles.frame:GetPropertyChangedSignal("Visible"):Connect(function() if profiles.frame.Visible then refresh() end end)

    ------------------------------------------------------------ info
    local about = infoPage:Card({ Title = "About", Side = "Left" })
    if window.Version ~= "" then about:Info({ Title = window.Title, Value = window.Version }) end
    about:Info({ Title = "qustah-ui-lib", Value = "v" .. tostring(window.Lib.Version) })
    for _, entry in ipairs(cfg.Info or {}) do about:Info({ Title = entry[1], Value = entry[2], Copy = entry.Copy }) end
    local files = type(writefile) == "function" and type(readfile) == "function"
    about:Info({ Title = "File access", Value = files and "Yes" or "No (profiles off)" })

    local modulesCard = infoPage:Card({ Title = "Modules", Side = "Left" })
    local moduleRows = {}
    local noModules = modulesCard:Label("No modules reported")

    local errorsCard = infoPage:Card({ Title = "Errors", Side = "Right" })
    local errorCount = errorsCard:Info({ Title = "Errors", Value = "0" })
    local errorText = errorsCard:Paragraph({ Content = "No errors" })
    errorsCard:Button({
        Title = "Copy report",
        Callback = function()
            local clipboard = setclipboard or toclipboard
            if type(clipboard) == "function" and pcall(clipboard, window:GetErrorReport()) then
                window:Notify({ Title = "Copied", Content = "Error report copied to clipboard" })
            else
                window:Notify({ Title = "Clipboard", Content = "setclipboard is not available", Color = RED })
            end
        end,
    })
    errorsCard:Button({ Title = "Clear", Callback = function() window:ClearErrors() end })

    local STATE = { On = GREEN, Off = nil, Limited = Color3.fromRGB(215, 180, 120), Error = RED }
    local function update()
        local order, modules = window:GetModules()
        noModules:SetVisible(#order == 0)
        for _, name in ipairs(order) do
            local row = moduleRows[name] or modulesCard:Info({ Title = name })
            moduleRows[name] = row
            local module = modules[name]
            row:Set(module.state .. (module.detail and module.state ~= "Error" and (" · " .. tostring(module.detail)) or ""))
            row:SetColor(STATE[module.state] or "muted")
        end
        local errors = window:GetErrors()
        local total = 0
        local lines = {}
        for index, entry in ipairs(errors) do
            total = total + entry.count
            if index <= 8 then
                lines[#lines + 1] = string.format("<font color=\"#d78282\">%s</font>%s  %s", entry.source, entry.count > 1 and (" ×" .. entry.count) or "", (tostring(entry.message):gsub("<", "&lt;")))
            end
        end
        if #errors > 8 then lines[#lines + 1] = "+" .. (#errors - 8) .. " more (Copy report)" end
        errorCount:Set(#errors == 0 and "0" or (#errors .. (total > #errors and (" (" .. total .. "×)") or "")))
        errorCount:SetColor(#errors > 0 and RED or "text")
        errorText:Set(#lines > 0 and table.concat(lines, "\n") or "No errors")
    end
    window:OnStatusChanged(update)
    update()
    return tab
end
