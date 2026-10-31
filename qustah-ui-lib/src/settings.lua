-- Window:SettingsTab({ Title, Icon, Divider }) - ready-made tab (create it LAST, after every other tab):
--   Interface  theme pack, accent presets + custom colour, font, text glow, menu key, overlays (watermark,
--              keybind list, session bar, performance monitor), window reset / unload
--   Profiles   see profiles.lua (active profile + unsaved changes, share codes, notes, search...)
--   Info       versions, modules, error list with Copy report / Clear
local Util = require("util")
local Theme = require("theme")
local Glow = require("glow")
local UIFont = require("font")
local Profiles = require("profiles")

local RED, GREEN = "danger", "success" -- theme roles

return function(window, cfg)
    cfg = cfg or {}
    local defaultSize = Vector2.new(window.width, window.height)
    local tab = window:Tab({ Title = cfg.Title or "Settings", Icon = cfg.Icon or "settings", Divider = cfg.Divider ~= false, Header = cfg.Header ~= false })
    local interface = tab:Page("Interface")
    local profiles = tab:Page("Profiles", { Columns = 1 })
    local infoPage = tab:Page("Info")

    ------------------------------------------------------------ interface
    local look = interface:Card({ Title = "Appearance", Side = "Left", Icon = "palette" })
    local picker
    local swatches
    local function syncSwatches()
        if not swatches then return end
        -- the Neutral preset shows the pack's own neutral (Light uses a dark one)
        swatches:SetColor("Neutral", Theme.neutral(Theme.pack))
        local accent = Theme.get("accentUser")
        if accent == Theme.neutral(Theme.pack) then swatches:Set("Neutral", true) else swatches:Set(accent, true) end
    end
    -- custom themes saved on this PC (<Folder>/themes.json)
    local customThemes = window.Config:ReadJSON("themes")
    for name, data in pairs(customThemes) do Theme.registerCustom(name, data) end
    local themeDropdown = look:Dropdown({
        Title = "Theme", Options = Theme.packOrder, Default = "Dark", Flag = "__ui_theme",
        Callback = function(name)
            Theme.applyPack(name)
            -- the pack may swap the neutral accent: keep the picker / presets in step
            if picker then picker:Set(Theme.get("accentUser"), true) end
            syncSwatches()
        end,
    })
    -- accent: one row of colour dots; the last one opens a picker for any colour (saved with the profile)
    swatches = look:Swatches({
        Title = "Accent", Default = "Neutral", Style = "Dots",
        Custom = function(open) if picker then picker:SetOpen(open) end end,
        Callback = function(color, name)
            if name == "Neutral" then color = Theme.neutral(Theme.pack) end
            if picker then picker:Set(color) end
        end,
    })
    picker = look:ColorPicker({
        Title = "Custom accent", Flag = "__ui_accent", Default = Theme.get("accentUser"),
        Callback = function(color) Theme.set("accent", color) syncSwatches() end,
    })
    picker.Row.Visible = false -- (only its colour panel shows, under the dots)
    syncSwatches()
    -- Gotham (Roblox's default) and fonts from Roblox's font library; CreateWindow({ Font = "Inter" }) starts with one
    local fonts = UIFont.available()
    local startFont = table.find(fonts, tostring(window.cfg.Font)) and tostring(window.cfg.Font) or "Gotham"
    look:Dropdown({
        Title = "Font", Options = fonts, Default = startFont, Flag = "__ui_font",
        Callback = function(name)
            if not UIFont.set(name) then window:Notify({ Title = "Font", Content = name .. " is not available here", Color = RED }) end
        end,
    })
    if startFont ~= "Gotham" then UIFont.set(startFont) end
    look:Toggle({
        Title = "Text glow", Desc = "Shine on the title and highlights", Flag = "__ui_glow", Default = Glow.enabled,
        Callback = function(on) Glow.setEnabled(on) end,
    })

    local scaleDropdown
    local menu = interface:Card({ Title = "Behaviour", Side = "Right", Icon = "settings-2" })
    local menuKey = menu:Keybind({
        Title = "Menu key", Desc = "Opens and closes the menu", Flag = "__ui_menu_key", Default = window.key,
        Callback = function(key) window:SetToggleKey(key) end,
    })
    window._menuListeners = window._menuListeners or {}
    table.insert(window._menuListeners, function(key) if menuKey.Value ~= key then menuKey:Set(key, true) end end)
    -- UI scale: this PC only (not part of profiles)
    local SCALES = { "80%", "100%", "120%" }
    -- another scale (CreateWindow({ Scale = 1.1 }), or one saved from the older list) stays as it is; the list shows the nearest
    local percent = math.floor((window:GetUIScale() * 100) + 0.5)
    local nearest = 100
    for _, text in ipairs(SCALES) do
        local value = tonumber(text:match("%d+"))
        if math.abs(value - percent) < math.abs(nearest - percent) then nearest = value end
    end
    scaleDropdown = menu:Dropdown({
        Title = "UI scale", Desc = "Bigger or smaller menu", Options = SCALES, Default = nearest .. "%",
        Callback = function(text) window:SetUIScale((tonumber(text:match("%d+")) or 100) / 100) end,
    })
    window._scaleDropdown = scaleDropdown
    menu:Toggle({ Title = "Free mouse", Desc = "Free cursor while open", Icon = "hand", Flag = "__ui_mouse",
        Default = window.unlockMouse ~= false, Callback = function(on) window:SetMouseUnlock(on) end })
    menu:Toggle({ Title = "Anonymous mode", Desc = "Hides your name and avatar", Icon = "venetian-mask", Flag = "__ui_anon", Default = window.anonymous == true,
        Callback = function(on) window:SetAnonymous(on) end })
    if window.OnAnonymousChanged then
        window:OnAnonymousChanged(function(on) local t = window.flags.__ui_anon if t and t.Value ~= on then t:Set(on, true) end end)
    end
    local Sounds = require("sounds")
    menu:Toggle({
        Title = "UI sounds", Desc = "Soft clicks on buttons and switches", Flag = "__ui_sounds", Default = Sounds.Enabled,
        Callback = function(on) Sounds.Enabled = on end,
    })
    local Haptics = require("haptics")
    -- (phones / tablets only: nothing to buzz on a PC)
    if Util.Services.UserInputService.TouchEnabled then
        menu:Toggle({ Title = "Haptics", Desc = "Buzz on taps", Default = Haptics.Enabled, Callback = function(on) Haptics.Enabled = on end })
    end
    menu:Toggle({ Title = "Mobile button", Desc = "Reopen button while hidden", Default = window.mobileButton == true,
        Callback = function(on) window:SetMobileButton(on, true) end })
    menu:Toggle({
        Title = "Welcome toast", Desc = "Greets a new account on first open",
        Default = window:_state("welcomeToast") ~= false and window.cfg.Welcome ~= false,
        Callback = function(on) window:_state("welcomeToast", on) end,
    })
    local menuActions = menu:Row({ Widths = { 3, 2 } })
    menuActions:Button({
        Title = "Reset layout", Icon = "rotate-ccw", Tooltip = "Puts the window back to its default size and place",
        Callback = function()
            window.width, window.height, window.topLeft = defaultSize.X, defaultSize.Y, nil
            window.memory.window = nil
            window:_layout()
            window:_saveMemory()
        end,
    })
    menuActions:Button({
        Title = "Unload", Icon = "power", Style = "Danger",
        Callback = function()
            window:Confirm("Unload " .. window.Title .. "?", "The menu and everything it runs will be removed.", function() window:Destroy() end, "Unload", true)
        end,
    })
    -- the look of the menu back to its defaults (theme, accent, font, window, overlays, scale) - nothing else changes
    local LOOK_FLAGS = { "__ui_theme", "__ui_accent", "__ui_font", "__ui_glow", "__ui_transparency", "__ui_bg", "__ui_bg_alpha",
        "__ui_live", "__ui_edge_glow", "__ui_blur", "__ui_hud_watermark", "__ui_hud_keys", "__ui_hud_session", "__ui_hud_stats" }
    menu:Button({ Title = "Reset interface", Icon = "paintbrush", Style = "Ghost", Callback = function()
        window:Confirm("Reset the interface?", "Theme, accent, font, window look and overlays go back to their defaults. Your script settings stay.", function()
            for _, flag in ipairs(LOOK_FLAGS) do
                local element = window.flags[flag]
                local default = window.Config.Defaults[flag]
                if element and default ~= nil then
                    pcall(element._load or element.Set, element, default)
                    if element._updateReset then pcall(element._updateReset, element) end
                end
            end
            window:SetUIScale(1)
            if scaleDropdown then scaleDropdown:Set("100%", true) end
            window:Notify({ Title = "Interface reset", Content = "The menu looks like the first time", Icon = "paintbrush" })
        end, "Reset")
    end })

    local look2 = interface:Card({ Title = "Window", Side = "Left", Icon = "app-window" })
    look2:Slider({ Title = "Transparency", Flag = "__ui_transparency", Min = 0, Max = 60, Default = 0, Suffix = "%",
        Callback = function(value) window:SetBackgroundTransparency(value / 100) end })
    local bgAlpha
    look2:Input({ Title = "Background", Placeholder = "image id or url", Flag = "__ui_bg",
        Callback = function(text) window:SetBackgroundImage(text ~= "" and text or nil, bgAlpha and (1 - bgAlpha.Value / 100) or 0.85) end })
    bgAlpha = look2:Slider({ Title = "Background visibility", Flag = "__ui_bg_alpha", Min = 0, Max = 60, Default = 15, Suffix = "%",
        DependsOn = { Flag = "__ui_bg", Value = function(text) return type(text) == "string" and text ~= "" end, Mode = "Hide" },
        Callback = function(value) if window._background then window._background.ImageTransparency = 1 - value / 100 end end })
    look2:Toggle({ Title = "Animated background", Desc = "Slow glow behind the menu", Icon = "blend", Flag = "__ui_live",
        Default = window.liveBackground == true, Callback = function(on) window:SetLiveBackground(on) end })
    look2:Toggle({ Title = "Edge glow", Desc = "Pulsing accent border", Flag = "__ui_edge_glow",
        Default = window.accentGlow == true, Callback = function(on) window:SetAccentGlow(on) end })
    look2:Toggle({ Title = "Blur game", Desc = "Blurs the game while open", Flag = "__ui_blur",
        Default = window.blur == true, Callback = function(on) window:SetBlur(on) end })

    local overlays = interface:Card({ Title = "Overlays", Side = "Right", Icon = "layers" })
    overlays:Toggle({ Title = "Watermark", Desc = "Name · FPS · ping · clock", Flag = "__ui_hud_watermark", Callback = function(on) window:Watermark(on) end })
    overlays:Toggle({ Title = "Keybind list", Desc = "Bound keys on screen", Flag = "__ui_hud_keys", Callback = function(on) window:KeybindList(on) end })
    overlays:Toggle({ Title = "Session bar", Desc = "FPS · ping · players · time", Flag = "__ui_hud_session", Callback = function(on) window:SessionBar(on) end })
    overlays:Dropdown({
        Title = "Performance", Options = { "Off", "Header", "Floating" }, Default = "Off", Flag = "__ui_hud_stats",
        Callback = function(mode) window:StatsMonitor(mode) end,
    })

    ------------------------------------------------------------ theme editor
    local editorCard = interface:Card({ Title = "Theme editor", Side = "Left", Icon = "paintbrush" })
    local editor = editorCard:Section({ Title = "Edit colours", Opened = false })
    local ROLE_NAMES = { "Background", "Cards", "Inputs", "Outlines", "Text", "Muted text", "Headings", "Dock", "Icons", "Accent" }
    local ROLE_OF = {}
    for index, name in ipairs(ROLE_NAMES) do ROLE_OF[name] = Theme.EDITABLE[index] end
    local roleColor
    local roleDropdown = editor:Dropdown({ Title = "Colour", Options = ROLE_NAMES, Default = "Background",
        Callback = function(name)
            local role = ROLE_OF[name]
            if roleColor and role then roleColor:Set(Theme.get(role == "accent" and "accentUser" or role), true) end
        end })
    roleColor = editor:ColorPicker({ Title = "Value", Default = Theme.get("base"),
        Callback = function(color)
            local role = ROLE_OF[roleDropdown.Value or "Background"]
            if not role then return end
            if role == "accent" then picker:Set(color) else Theme.set(role, color) end
        end })
    local function saveThemes() window.Config:WriteJSON("themes", customThemes) end
    local function refreshThemeList(select)
        themeDropdown:SetOptions(Theme.packOrder, true)
        if select then themeDropdown:Set(select) end
    end
    editor:ActionInput({ Name = "SaveTheme", Icon = "save", Placeholder = "Theme name", Button = "Save",
        Hint = "Saves the colours above as a theme",
        Validate = function(name)
            if Theme.packs[name] and not Theme.packs[name].custom then return false, "\"" .. name .. "\" is a built-in theme" end
            return true, Theme.packs[name] and ("Overwrites \"" .. name .. "\"") or ("Adds \"" .. name .. "\" to the Theme list")
        end,
        Callback = function(name)
            customThemes[name] = Theme.export()
            Theme.registerCustom(name, customThemes[name])
            saveThemes()
            refreshThemeList(name)
            window:Notify({ Title = "Theme saved", Content = name, Icon = "palette" })
        end })
    local codeRow = editor:Row()
    codeRow:Button({ Title = "Copy code", Icon = "copy", Callback = function()
        local code = "QTHEME1:" .. Util.base64encode(Util.Services.HttpService:JSONEncode({ n = themeDropdown.Value or "Theme", t = Theme.export() }))
        local clipboard = setclipboard or toclipboard
        if clipboard and pcall(clipboard, code) then window:Notify({ Title = "Copied", Content = "Theme code copied", Icon = "palette" }) end
    end })
    codeRow:Button({ Title = "Delete", Icon = "trash-2", Risky = true, Callback = function()
        local name = themeDropdown.Value
        if not (name and Theme.packs[name] and Theme.packs[name].custom) then
            return window:Notify({ Title = "Theme", Content = "Only your own themes can be deleted", Color = "warning" })
        end
        window:Confirm("Delete theme \"" .. name .. "\"?", "It is removed from this PC.", function()
            customThemes[name] = nil
            Theme.removeCustom(name)
            saveThemes()
            refreshThemeList("Dark")
        end, "Delete", true)
    end })
    editor:ActionInput({ Name = "ImportTheme", Icon = "import", Placeholder = "Paste a theme code", Button = "Import",
        Validate = function(code)
            local body = code:gsub("%s", ""):match("^QTHEME1:(.+)$")
            if not body then return false, "Not a theme code" end
            local ok, data = pcall(function() return Util.Services.HttpService:JSONDecode(Util.base64decode(body)) end)
            if not ok or type(data) ~= "table" or type(data.t) ~= "table" then return false, "The code is damaged" end
            return true, "Theme \"" .. tostring(data.n) .. "\""
        end,
        Callback = function(code)
            local data = Util.Services.HttpService:JSONDecode(Util.base64decode(code:gsub("%s", ""):match("^QTHEME1:(.+)$")))
            local name = tostring(data.n or "Imported"):gsub("[^%w_%- ]", "")
            if Theme.packs[name] and not Theme.packs[name].custom then name = name .. " (2)" end
            customThemes[name] = data.t
            if Theme.registerCustom(name, data.t) then
                saveThemes()
                refreshThemeList(name)
                window:Notify({ Title = "Theme imported", Content = name, Icon = "palette" })
            end
        end })


    ------------------------------------------------------------ profiles
    -- Default profile = each element's starting value (recorded as elements are created, any order)
    Profiles(window, profiles, window.Config.Defaults)

    ------------------------------------------------------------ info
    local about = infoPage:Card({ Title = "About", Side = "Left", Icon = "info" })
    if window.Version ~= "" then about:Info({ Title = window.Title, Value = window.Version }) end
    about:Info({ Title = "qustah-ui-lib", Value = "v" .. tostring(window.Lib.Version) })
    for _, entry in ipairs(cfg.Info or {}) do about:Info({ Title = entry[1], Value = entry[2], Copy = entry.Copy }) end
    local files = type(writefile) == "function" and type(readfile) == "function"
    about:Info({ Title = "File access", Value = files and "Yes" or "No (profiles off)" })
    about:Info({ Title = "Secure mode", Value = Util.secure and "On" or "Off", Help = "Random gui names and a silent console. Turn it on with getgenv().QUSTAH_SECURE = true before loading, or CreateWindow({ Secure = true })" })
    -- the buttons after the facts, side by side when there are two
    local aboutButtons = (type(window.cfg.Changelog) == "table" and window.cfg.Tour) and about:Row() or about
    if type(window.cfg.Changelog) == "table" then
        aboutButtons:Button({ Title = "What's new", Icon = "newspaper", Callback = function() window:ShowChangelog() end })
    end
    -- every version's notes (Changelog.History), under the other buttons
    if type(window.cfg.Changelog) == "table" then
        about:Button({ Title = "Version history", Icon = "history", Style = "Ghost", Callback = function() window:ShowVersionHistory() end })
    end
    if window.cfg.Tour then
        aboutButtons:Button({ Title = "Show the tour", Icon = "map", Callback = function()
            local spec = window.cfg.Tour
            window:Tour(type(spec) == "table" and spec or nil, { Id = window.cfg.TourId, Force = true })
        end })
    end

    -- CreateWindow({ Links = { { Title = "Discord", Url = "https://discord.gg/...", Icon = "message-circle" }, ... } }):
    -- buttons that copy the link (a game can't open a browser), two per row
    if type(window.cfg.Links) == "table" and #window.cfg.Links > 0 then
        local linkRow
        for index, link in ipairs(window.cfg.Links) do
            if index % 2 == 1 then linkRow = about:Row() end
            linkRow:Button({ Title = tostring(link.Title or "Link"), Icon = link.Icon or "link", Style = "Soft", Tooltip = tostring(link.Url or ""),
                Callback = function()
                    local clipboard = setclipboard or toclipboard
                    if type(clipboard) == "function" and pcall(clipboard, tostring(link.Url or "")) then
                        window:Notify({ Title = "Link copied", Content = tostring(link.Title or "Link") .. " · paste it in your browser", Icon = link.Icon or "link" })
                    else
                        window:Notify({ Title = tostring(link.Title or "Link"), Content = tostring(link.Url or ""), Duration = 10 })
                    end
                end })
        end
    end

    -- kicks / disconnects seen by the kick watcher (kick.lua)
    if window.GetKicks and window.cfg.KickLog ~= false then
        local kicksCard = infoPage:Card({ Title = "Disconnects", Side = "Left", Icon = "log-out", Desc = "Kicks and drops, with Roblox's reason" })
        local kickText = kicksCard:Paragraph({ Content = "None yet" })
        local kicksClear
        local function showKicks()
            local list = window:GetKicks()
            local lines = {}
            for index, entry in ipairs(list) do
                if index > 5 then break end
                lines[#lines + 1] = string.format("<font color=\"#%s\">%s</font>  %s  <font color=\"#%s\">%s</font>",
                    Util.toHex(Theme.get((entry.Code == 277 or entry.Code == 279) and "warning" or "danger")), tostring(entry.Kind or "Kicked"),
                    (tostring(entry.Reason or ""):gsub("<", "&lt;")), Util.toHex(Theme.get("muted")), Util.ago(entry.Time))
            end
            kickText:Set(#lines > 0 and table.concat(lines, "\n") or "None yet")
            if kicksClear then kicksClear:SetVisible(#lines > 0) end -- (nothing to clear: no button)
        end
        kicksClear = kicksCard:Button({ Title = "Clear", Icon = "trash-2", Callback = function()
            window.Config:WriteJSON("kicks", { list = {} })
            showKicks()
        end })
        window:OnKick(showKicks)
        Theme.onChange(function() if infoPage.frame.Parent then showKicks() end end)
        showKicks()
    end

    local modulesCard = infoPage:Card({ Title = "Modules", Side = "Left", Icon = "boxes" })
    local moduleRows = {}
    local noModules = modulesCard:Label("No modules reported")

    local errorsCard = infoPage:Card({ Title = "Errors", Side = "Right", Icon = "bug" })
    -- debug mode: a small switch in the card's title row (a notification for every new error)
    errorsCard:HeaderSwitch({ Title = "Debug", Flag = "__ui_debug", Default = window.cfg.Debug == true, Tooltip = "A notification for every new error",
        Callback = function(on) window.debug = on end })
    local errorCount = errorsCard:Info({ Title = "Errors", Value = "0" })
    local errorText = errorsCard:Paragraph({ Content = "No errors" })
    local errorButtons = errorsCard:Row()
    errorButtons:Button({
        Title = "Copy debug info", Icon = "clipboard-copy", Tooltip = "Executor, versions, game, modules and errors - paste it into a bug report",
        Callback = function()
            local clipboard = setclipboard or toclipboard
            if type(clipboard) == "function" and pcall(clipboard, window:GetDebugInfo()) then
                window:Notify({ Title = "Copied", Content = "Debug info copied - paste it into your bug report", Icon = "clipboard-copy" })
            else
                window:Notify({ Title = "Clipboard", Content = "setclipboard is not available", Color = RED })
            end
        end,
    })
    local clearErrors = errorButtons:Button({ Title = "Clear", Icon = "trash-2", Callback = function() window:ClearErrors() end })

    local STATE = { On = GREEN, Off = nil, Limited = "warning", Error = RED }
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
                lines[#lines + 1] = string.format("<font color=\"#%s\">%s</font>%s  %s", Util.toHex(Theme.get("danger")), entry.source, entry.count > 1 and (" ×" .. entry.count) or "", (tostring(entry.message):gsub("<", "&lt;")))
            end
        end
        if #errors > 8 then lines[#lines + 1] = "+" .. (#errors - 8) .. " more (Copy debug info)" end
        errorCount:Set(#errors == 0 and "0" or (#errors .. (total > #errors and (" (" .. total .. "×)") or "")))
        errorCount:SetColor(#errors > 0 and RED or "text")
        errorText:Set(#lines > 0 and table.concat(lines, "\n") or "No errors")
        clearErrors:SetVisible(#errors > 0) -- (nothing to clear: Copy debug info takes the whole row)
    end
    window:OnStatusChanged(update)
    Theme.onChange(function() if infoPage.frame.Parent then update() end end)
    update()
    -- this session: how long, how many errors, the script's own counters (Window:Count), Lua memory
    window._startedAt = window._startedAt or os.clock()
    local sessionCard = infoPage:Card({ Title = "This session", Side = "Right", Icon = "timer" })
    local uptimeRow = sessionCard:Info({ Title = "Running for", Value = "0s" })
    local errorsRow = sessionCard:Info({ Title = "Errors caught", Value = "0" })
    local countRows = {}
    local memoryRow = sessionCard:Info({ Title = "Lua memory", Value = "--" })
    memoryRow.Row.LayoutOrder = 10000 -- (stays last when counters are added)
    local function memory()
        local ok, kb = pcall(collectgarbage, "count")
        if not ok or type(kb) ~= "number" then ok, kb = pcall(function() return gcinfo() end) end
        return ok and type(kb) == "number" and kb or nil
    end
    local function refreshSession()
        local seconds = math.floor(os.clock() - window._startedAt)
        uptimeRow:Set(seconds >= 3600 and string.format("%dh %02dm", seconds // 3600, (seconds // 60) % 60)
            or (seconds >= 60 and string.format("%dm %02ds", seconds // 60, seconds % 60) or (seconds .. "s")))
        local total = 0
        for _, entry in ipairs(window:GetErrors()) do total = total + entry.count end
        errorsRow:Set(tostring(total))
        errorsRow:SetColor(total > 0 and RED or "text")
        local order, counts = window:GetCounts()
        for _, name in ipairs(order) do
            countRows[name] = countRows[name] or sessionCard:Info({ Title = name })
            countRows[name]:Set(tostring(counts[name]))
        end
        local kb = memory()
        memoryRow:Set(kb and string.format("%.1f MB", kb / 1024) or "unavailable")
    end
    window:OnCount(function() if infoPage.frame.Visible then refreshSession() end end)
    task.spawn(function()
        while window.alive do
            if window.visible and infoPage.frame.Visible then refreshSession() end
            task.wait(1)
        end
    end)
    refreshSession()

    window.settingsTab = tab
    return tab
end
