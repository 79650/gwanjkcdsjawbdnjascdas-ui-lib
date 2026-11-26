-- Window:SettingsTab({ Title, Icon (false: none), Divider, Simple }) - ready-made tab (create it LAST, after every other tab):
--   Interface  theme pack, accent presets + custom colour, font, text glow, menu key, overlays (watermark,
--              keybind list, session bar, performance monitor), window reset / unload
--   Profiles   see profiles.lua (active profile + unsaved changes, share codes, notes, search...)
--   Keys       every bound key, the ones used twice in red; a click opens the setting
--   Info       modules, executor, errors (copy debug info / clear icons), what's new, this session
-- Simple = true: for a small script - the same four pages, Interface with the everyday settings only: an
--   Appearance card (Theme | Text tabs) and a compact Menu card with Behaviour (menu key, scale, free mouse, anonymous,
--   reset layout / unload) and Window (transparency, blur) tabs. No dock choice: the dock stays where the script put it.
local Util = require("util")
local Theme = require("theme")
local Glow = require("glow")
local UIFont = require("font")
local Profiles = require("profiles")

local RED = "danger" -- theme role

return function(window, cfg)
    cfg = cfg or {}
    -- Reset layout goes back to the script's own size (CreateWindow({ Size })), not to a size remembered from last time
    local configured = typeof(window.cfg.Size) == "Vector2" and window.cfg.Size or Vector2.new(540, 390)
    local defaultSize = Vector2.new(math.clamp(configured.X, window.minSize.X, window.maxSize.X), math.clamp(configured.Y, window.minSize.Y, window.maxSize.Y))
    -- (Icon = false: no icon, like tabs made without one)
    local icon = cfg.Icon
    if icon == nil then icon = "settings" elseif icon == false then icon = nil end
    local tab = window:Tab({ Title = cfg.Title or "Settings", Icon = icon, Divider = cfg.Divider ~= false, Header = cfg.Header ~= false, Compact = cfg.Compact == true })
    local interface = tab:Page("Interface")
    local profiles = tab:Page("Profiles", { Columns = 1 })
    local simple = cfg.Simple == true
    local keysPage = tab:Page("Keys", { Columns = 1 })
    local infoPage = tab:Page("Info")

    ------------------------------------------------------------ interface
    -- Theme (the packs as small windows, the accent dots, the theme editor folded) and Text on the left; Behaviour and
    -- Window (Look / Background / Overlays tabs) on the right.
    -- (Simple: Theme and Text are the two tabs of one Appearance card)
    local appearanceTabs = simple and interface:Card({ Title = "Appearance", Side = "Left", Icon = "palette" }):Tabs({ "Theme", "Text" }) or nil
    local look = appearanceTabs and appearanceTabs.Theme or interface:Card({ Title = "Theme", Side = "Left", Icon = "palette" })
    local editor                                                     -- the "Edit colours" section (made further down)
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
    local themeDropdown = look:ThemeGallery({
        Title = "Theme", Items = Theme.packOrder, Default = Theme.pack, Flag = "__ui_theme",
        New = not simple and function() if editor then editor:SetOpen(true) end end or nil, -- (Simple: no colour editor)
        Callback = function(name)
            Theme.applyPack(name)
            -- the pack may swap the neutral accent: keep the picker / presets in step
            if picker then picker:Set(Theme.get("accentUser"), true) end
            syncSwatches()
        end,
    })
    -- accent: one row of colour dots; the last one opens a picker for any colour (saved with the profile)
    look:Divider({ Title = "Accent" })
    local accentCard = look
    swatches = accentCard:Swatches({
        Name = "Accent color", Default = "Neutral", Style = "Dots",
        Custom = function(open) if picker then picker:SetOpen(open) end end,
        Callback = function(color, name)
            if name == "Neutral" then color = Theme.neutral(Theme.pack) end
            if picker then picker:Set(color) end
        end,
    })
    picker = accentCard:ColorPicker({
        Title = "Custom accent", Flag = "__ui_accent", Default = Theme.get("accentUser"),
        Callback = function(color) Theme.set("accent", color) syncSwatches() end,
    })
    picker.Row.Visible = false -- (only its colour panel shows, under the dots)
    syncSwatches()
    -- the fonts (font.lua: Roblox's own families). CreateWindow({ Font = "Ubuntu" }) starts with one (else Jura);
    -- a list ({ "Jura", "Roboto" }) starts with the first known name
    local fonts = UIFont.available()
    local wanted = type(window.cfg.Font) == "table" and window.cfg.Font or { window.cfg.Font }
    local usable = {}
    for _, name in ipairs(wanted) do if table.find(fonts, tostring(name)) then usable[#usable + 1] = tostring(name) end end
    local startFont = usable[1] or "Jura"
    -- each name drawn in its own font
    local fontOptions = {}
    for _, name in ipairs(fonts) do fontOptions[#fontOptions + 1] = { Title = name, Font = UIFont.family(name) } end
    local fontTab = appearanceTabs and appearanceTabs.Text or interface:Card({ Title = "Text", Side = "Left", Icon = "type" })
    -- picking a font also picks the text size that suits it (UIFont.DefaultSize) - not while a profile loads (its
    -- own text size stays) and not while the page is built
    local textSize
    local fontPicked = false
    task.defer(function() fontPicked = true end)
    fontTab:Dropdown({
        Title = "Font", Items = fontOptions, Default = startFont, Flag = "__ui_font",
        Callback = function(name)
            local changed = name ~= UIFont.current
            if not UIFont.set(name) then window:Notify({ Title = "Font", Content = name .. " is not available here", Color = RED }) return end
            local size = UIFont.DefaultSize[name]
            if changed and fontPicked and size and textSize and (window.Config.applying or 0) == 0 then textSize:Set(size) end
        end,
    })
    UIFont.set(startFont)
    -- the font of Code, Console and Log text: RobotoMono, or CreateWindow({ CodeFont = "Code" }) (an Enum.Font name)
    if window.cfg.CodeFont then UIFont.setCode(window.cfg.CodeFont) end
    -- text size: every text a bit smaller / larger, the menu itself stays the same size
    local TEXT_SIZES = { Small = 0.9, Normal = 1, Large = 1.1 }
    textSize = fontTab:Segment({
        Title = "Text size", Flag = "__ui_textsize", Items = { "Small", "Normal", "Large" }, Default = UIFont.DefaultSize[startFont] or "Normal",
        Callback = function(choice) UIFont.setTextScale(TEXT_SIZES[choice] or 1) end,
    })
    if not simple then fontTab:Toggle({
        Title = "Text glow", Desc = "Shine on the title and highlights", Flag = "__ui_glow", Default = Glow.enabled,
        Callback = function(on) Glow.setEnabled(on) end,
    }) end

    local scaleDropdown
    -- (Simple: Behaviour and Window are the two tabs of one compact Menu card - check boxes, shorter rows)
    local menuTabs = simple and interface:Card({ Title = "Menu", Side = "Right", Icon = "settings-2", Compact = true }):Tabs({ "Behaviour", "Window" }) or nil
    local menu = menuTabs and menuTabs.Behaviour or interface:Card({ Title = "Behaviour", Side = "Right", Icon = "settings-2" })
    local menuKey = menu:Keybind({
        Title = "Menu key", Desc = "Opens and closes the menu", Flag = "__ui_menu_key", Default = window.key,
        Callback = function(key) window:SetToggleKey(key) end,
    })
    window._menuListeners = window._menuListeners or {}
    table.insert(window._menuListeners, function(key) if menuKey.Value ~= key then menuKey:Set(key, true) end end)
    -- UI scale: this PC only (not part of profiles)
    local SCALES = { "80%", "100%", "110%", "120%" }
    -- another scale (CreateWindow({ Scale = 0.9 })) stays as it is; the list shows the nearest
    local percent = math.floor((window:GetUIScale() * 100) + 0.5)
    local nearest = 100
    for _, text in ipairs(SCALES) do
        local value = tonumber(text:match("%d+"))
        if math.abs(value - percent) < math.abs(nearest - percent) then nearest = value end
    end
    if window.cfg.UIScale ~= false then
        scaleDropdown = menu:Dropdown({
            Title = "UI scale", Desc = "Bigger or smaller menu", Items = SCALES, Default = nearest .. "%",
            Callback = function(text) window:SetUIScale((tonumber(text:match("%d+")) or 100) / 100) end,
        })
    end
    window._scaleDropdown = scaleDropdown
    menu:Toggle({ Title = "Free mouse", Desc = "Free cursor while open", Flag = "__ui_mouse",
        Default = window.unlockMouse ~= false, Callback = function(on) window:SetMouseUnlock(on) end })
    menu:Toggle({ Title = "Anonymous mode", Desc = "Hides your name and avatar", Flag = "__ui_anon", Default = window.anonymous == true,
        Callback = function(on) window:SetAnonymous(on) end })
    if window.OnAnonymousChanged then
        window:OnAnonymousChanged(function(on) local t = window.flags.__ui_anon if t and t.Value ~= on then t:Set(on, true) end end)
    end
    local Sounds = require("sounds")
    if not simple then
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
    end
    local menuActions = menu:Row({ Widths = { 3, 2 } })
    menuActions:Button({
        Title = "Reset layout", Tooltip = "Puts the window back to its default size and place",
        Callback = function()
            window.width, window.height, window.topLeft = defaultSize.X, defaultSize.Y, nil
            window.memory.window = nil
            window:_layout()
            window:_saveMemory()
        end,
    })
    menuActions:Button({
        Title = "Unload", Style = "Danger",
        Callback = function()
            window:Confirm("Unload " .. window.Title .. "?", "The menu and everything it runs will be removed.", function() window:Destroy() end, "Unload", true)
        end,
    })
    -- the look of the menu back to its defaults (theme, accent, font, window, overlays, scale) - nothing else changes
    local LOOK_FLAGS = { "__ui_theme", "__ui_accent", "__ui_font", "__ui_textsize", "__ui_glow", "__ui_transparency", "__ui_bg", "__ui_bg_alpha",
        "__ui_live", "__ui_edge_glow", "__ui_blur", "__ui_hud_watermark", "__ui_hud_keys", "__ui_hud_session", "__ui_hud_stats", "__ui_dock", "__ui_pagetabs" }
    if not simple then menu:Button({ Title = "Reset interface", Icon = "paintbrush", Style = "Ghost", Callback = function()
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
    end }) end

    -- Window: Look (transparency, where the tab icons and page names sit, edge glow, blur), Background (image,
    -- animated glow), Overlays
    local windowCard = menuTabs and menuTabs.Window or interface:Card({ Title = "Window", Side = "Right", Icon = "app-window" })
    -- (Simple: one plain card, no Background / Overlays tabs)
    local windowTabs = not simple and windowCard:Tabs({ "Look", "Background", "Overlays" }) or nil
    local look2 = windowTabs and windowTabs.Look or windowCard
    look2:Slider({ Title = "Transparency", Flag = "__ui_transparency", Min = 0, Max = 25, Default = 0, Suffix = "%",
        Callback = function(value) window:SetBackgroundTransparency(value / 100) end })
    -- Right / Bottom: the dock outside the window; Sidebar: the tabs with their names inside it (DockSide "Side")
    -- (Simple: no dock choice - the dock stays where the script put it)
    if not simple then look2:Segment({ Title = "Dock", Items = { "Right", "Bottom", "Sidebar" }, Default = window.dockSide == "Side" and "Sidebar" or window.dockSide,
        Flag = "__ui_dock", Callback = function(side) window:SetDockSide(side == "Sidebar" and "Side" or side) end }) end
    if not simple then look2:Segment({ Title = "Page tabs", Items = { "Header", "Row" }, Default = window.pageTabs, Flag = "__ui_pagetabs",
        Callback = function(mode) window:SetPageTabs(mode) end }) end

    if not simple then
    local background = windowTabs.Background
    local bgAlpha
    background:Input({ Title = "Background", Placeholder = "image id or url", Flag = "__ui_bg",
        Callback = function(text) window:SetBackgroundImage(text ~= "" and text or nil, bgAlpha and (1 - bgAlpha.Value / 100) or 0.85) end })
    bgAlpha = background:Slider({ Title = "Background visibility", Flag = "__ui_bg_alpha", Min = 0, Max = 60, Default = 15, Suffix = "%",
        DependsOn = { Flag = "__ui_bg", Value = function(text) return type(text) == "string" and text ~= "" end, Mode = "Hide" },
        Callback = function(value) if window._background then window._background.ImageTransparency = 1 - value / 100 end end })
    background:Toggle({ Title = "Animated background", Desc = "Slow glow behind the menu", Flag = "__ui_live",
        Default = window.liveBackground == true, Callback = function(on) window:SetLiveBackground(on) end })
    end
    if not simple then look2:Toggle({ Title = "Edge glow", Desc = "Pulsing accent border", Flag = "__ui_edge_glow",
        Default = window.accentGlow == true, Callback = function(on) window:SetAccentGlow(on) end }) end
    look2:Toggle({ Title = "Blur game", Desc = "Blurs the game while open", Flag = "__ui_blur",
        Default = window.blur == true, Callback = function(on) window:SetBlur(on) end })

    if not simple then
    local overlays = windowTabs.Overlays
    overlays:Toggle({ Title = "Watermark", Desc = "Name · FPS · ping · clock", Flag = "__ui_hud_watermark", Callback = function(on) window:Watermark(on) end })
    overlays:Toggle({ Title = "Keybind list", Desc = "Bound keys on screen", Flag = "__ui_hud_keys", Callback = function(on) window:KeybindList(on) end })
    overlays:Toggle({ Title = "Session bar", Desc = "FPS · ping · players · time", Flag = "__ui_hud_session", Callback = function(on) window:SessionBar(on) end })
    overlays:Dropdown({
        Title = "Performance", Items = { "Off", "Header", "Floating" }, Default = "Off", Flag = "__ui_hud_stats",
        Callback = function(mode) window:StatsMonitor(mode) end,
    })
    end

    if not simple then
    ------------------------------------------------------------ theme editor
    editor = look:Section({ Title = "Edit colours", Opened = false })           -- the last part of the Theme card
    local ROLE_NAMES = { "Background", "Cards", "Inputs", "Outlines", "Text", "Muted text", "Headings", "Dock", "Icons", "Accent" }
    local ROLE_OF = {}
    for index, name in ipairs(ROLE_NAMES) do ROLE_OF[name] = Theme.EDITABLE[index] end
    local roleColor
    local roleDropdown = editor:Dropdown({ Title = "Colour", Items = ROLE_NAMES, Default = "Background",
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
        themeDropdown:SetItems(Theme.packOrder, true)
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
            refreshThemeList(Theme.defaultPack)
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


    end

    ------------------------------------------------------------ profiles
    -- Default profile = each element's starting value (recorded as elements are created, any order)
    Profiles(window, profiles, window.Config.Defaults)

    ------------------------------------------------------------ info
    ------------------------------------------------------------ keys
    -- every key the menu listens to: switches / buttons with a bind, keybinds (unbound ones too, so they can be set
    -- here), key hints and the menu key. A key used twice is marked (!). A click on a row waits for a new key for it
    -- (Escape: keep the old one, Backspace: no key).
    do
        local card = keysPage:Card({ Title = "Keys", Icon = "keyboard", Wide = true, Desc = "Click a key to change it" })
        local list
        local rows = {}
        local function where(element)
            if element.Type == "KeyHint" then return "Footer" end
            local page = element.Card and element.Card.page
            local owner = page and page.tab
            if not owner then return "" end
            return #owner.Pages > 1 and (owner.Title .. " › " .. page.Name) or owner.Title
        end
        -- (the card's title in front when the element's own one says little: "Click to Teleport › Keys")
        local function titleOf(element)
            local title = tostring(element.ListTitle or element.Title or element.Type or "Key")
            local cardTitle = element.Card and element.Card.title
            if type(cardTitle) == "string" and cardTitle ~= "" and cardTitle ~= title and #title <= 8 then title = cardTitle .. " › " .. title end
            return title
        end
        local function refresh()
            local conflicts = window:GetKeyConflicts()
            table.clear(rows)
            rows[#rows + 1] = { key = Util.keyName(window.key), title = "Open / close the menu", place = "Settings › Interface" }
            for element, key in pairs(window.binds) do
                if key ~= nil and element.Row and element.Row.Parent and not (type(element.Flag) == "string" and element.Flag:sub(1, 2) == "__") then
                    local name = Util.keyName(key)
                    if element.Chord and element.Chord[1] ~= nil and element.Chord[2] ~= nil then
                        name = Util.keyName(element.Chord[1]) .. " + " .. Util.keyName(element.Chord[2])
                    end
                    if name ~= "None" then
                        rows[#rows + 1] = { key = name, title = titleOf(element), place = where(element), element = element,
                            clash = conflicts[name] ~= nil }
                    end
                end
            end
            -- keybinds and bindable switches without a key yet, so they can be given one here
            for _, element in pairs(window.flags) do
                local unbound = (element.Type == "Keybind" and element.Value == nil) or (element.Bindable and element.BindKey == nil)
                if unbound and element.Row and element.Row.Parent
                    and not (type(element.Flag) == "string" and element.Flag:sub(1, 2) == "__") then
                    rows[#rows + 1] = { key = "—", title = titleOf(element), place = where(element), element = element }
                end
            end
            if conflicts[Util.keyName(window.key)] then rows[1].clash = true end
            -- bound keys first (A-Z), the unbound ones after them
            table.sort(rows, function(a, b)
                if (a.key == "—") ~= (b.key == "—") then return b.key == "—" end
                if a.key ~= b.key then return a.key < b.key end
                return a.title < b.title
            end)
            local items, clashes = {}, {}
            for _, row in ipairs(rows) do
                items[#items + 1] = { (row.clash and "! " or "") .. row.key, row.title, row.place }
                if row.clash then clashes[row.key] = true end
            end
            local count = 0
            for _ in pairs(clashes) do count = count + 1 end
            card:SetDesc("Click a key to change it" .. (count > 0 and (" · " .. count .. " used twice (!)") or ""))
            list:SetItems(items)
        end
        -- the new key for a row: the menu key through Settings' own Menu key, a keybind its value, a switch / button
        -- its bind
        local function rebind(row, key)
            local element = row.element
            if not element then
                local menuKeyElement = window.flags.__ui_menu_key
                if key == nil then return end -- (the menu always keeps a key)
                if menuKeyElement then menuKeyElement:Set(key) else window:SetToggleKey(key) end
            elseif element.Type == "Keybind" then
                element:Set(key)
            elseif element.SetBind then
                element:SetBind(key)
            end
        end
        list = card:Table({
            Height = 140, Columns = { { Title = "Key", Width = 0.26 }, { Title = "Setting", Width = 0.4 }, "Where" },
            Items = {},
            RowColor = function(row) return tostring(row[1]):sub(1, 2) == "! " and "danger" or nil end,
            OnRowClick = function(_, index)
                local row = rows[index]
                if not row or (row.element and row.element.Chord) then return end -- (a two-key chord is set on its own row)
                list:UpdateRow(index, { "Press a key...", row.title, row.place })
                window._capture = function(key)
                    if key == Enum.KeyCode.Escape then refresh() return end
                    if key == Enum.KeyCode.Backspace then key = nil end
                    if row.element and key == window.key then refresh() return end -- the menu key stays the menu key
                    pcall(rebind, row, key)
                    refresh()
                end
            end,
        })
        -- (filled when the page opens, and again after a key changes while it is open)
        keysPage.frame:GetPropertyChangedSignal("Visible"):Connect(function() if keysPage.frame.Visible then refresh() end end)
        local check = window._checkKeys
        window._checkKeys = function(self, ...)
            check(self, ...)
            if keysPage.frame.Visible then refresh() end
        end
    end

    -- what this executor can do (each line: the feature it is needed for)
    local executorName = "Unknown"
    pcall(function()
        if type(identifyexecutor) == "function" then executorName = table.concat({ identifyexecutor() }, " ")
        elseif type(getexecutorname) == "function" then executorName = tostring(getexecutorname()) end
    end)
    local function has(name) return type(getfenv(0)[name]) == "function" or (getgenv and type(getgenv()[name]) == "function") end
    local files = type(writefile) == "function" and type(readfile) == "function"

    -- CreateWindow({ Info = { { "Discord", "qustah" } }, Links = ..., Tour = ... }): an About card, only when given
    local hasLinks = type(window.cfg.Links) == "table" and #window.cfg.Links > 0
    if (cfg.Info and #cfg.Info > 0) or hasLinks or window.cfg.Tour then
        local about = infoPage:Card({ Title = "About", Side = "Left", Icon = "info" })
        for _, entry in ipairs(cfg.Info or {}) do about:Info({ Title = entry[1], Value = entry[2], Copy = entry.Copy }) end
        if window.cfg.Tour then
            about:Button({ Title = "Show the tour", Icon = "map", Callback = function()
                local spec = window.cfg.Tour
                window:Tour(type(spec) == "table" and spec or nil, { Id = window.cfg.TourId, Force = true })
            end })
        end
        -- CreateWindow({ Links = { { Title = "Discord", Url = "https://discord.gg/...", Icon = "message-circle" }, ... } }):
        -- buttons that copy the link (a game can't open a browser), two per row
        if hasLinks then
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
    end

    -- each module's state over the last 15 minutes (a sample every 30 s)
    local modulesCard = infoPage:Card({ Title = "Modules", Side = "Left", Icon = "boxes", Desc = "Last 15 minutes" })
    local noModules = modulesCard:Label("No modules reported")
    local moduleBars = modulesCard:StatusBars({ Slots = 30, Items = {} })
    task.spawn(function()
        while window.alive do
            task.wait(30)
            if not window.alive then break end
            local order, modules = window:GetModules()
            for _, name in ipairs(order) do moduleBars:Push(name, modules[name].state) end
        end
    end)

    infoPage:Card({ Title = "Executor", Side = "Left", Icon = "square-terminal", Desc = executorName }):Checklist({ Items = {
        { Title = "File access", Ok = files, Note = "profiles, themes" },
        { Title = "getcustomasset", Ok = has("getcustomasset"), Note = "icon sheet" },
        { Title = "gethui", Ok = has("gethui"), Note = "hidden interface" },
        { Title = "Drawing", Ok = (function() local d = getfenv(0).Drawing return type(d) == "table" and type(d.new) == "function" end)(), Note = "screen drawings" },
        { Title = "getconnections", Ok = has("getconnections"), Note = "connection control" },
        { Title = "hookmetamethod", Ok = has("hookmetamethod"), Note = "game hooks" },
        { Title = "setclipboard", Ok = has("setclipboard") or has("toclipboard"), Note = "copy buttons" },
    } })

    local errorsCard = infoPage:Card({ Title = "Errors", Side = "Right", Icon = "bug" })
    -- debug mode: a small switch in the card's title row (a notification for every new error)
    errorsCard:HeaderSwitch({ Title = "Debug", Flag = "__ui_debug", Default = window.cfg.Debug == true, Tooltip = "A notification for every new error",
        Callback = function(on) window.debug = on end })
    -- the newest errors as a code block; in its header the copy icon (the whole debug info: executor, versions,
    -- game, modules and every error - for a bug report) and a bin that clears them
    local noErrors = errorsCard:Label("No errors in this session")
    local errorText = errorsCard:Code({
        Title = "Last errors", Code = "", MaxHeight = 180, CopyText = false,
        CopyValue = function() return window:GetDebugInfo() end, CopyTooltip = "Copy debug info",
        Actions = { { Icon = "trash-2", Tooltip = "Clear", Danger = true, Callback = function() window:ClearErrors() end } },
    })

    -- release notes (CreateWindow({ Changelog = { Version, Items, History } }))
    if type(window.cfg.Changelog) == "table" then
        local log = window.cfg.Changelog
        local entries = { { Version = tostring(log.Version or window.Version), Time = "this version", Items = log.Items or {} } }
        for _, old in ipairs(log.History or {}) do entries[#entries + 1] = { Version = tostring(old.Version or ""), Time = old.Date or old.Time, Items = old.Items or {} } end
        infoPage:Card({ Title = "What's new", Side = "Right", Icon = "newspaper" }):Changelog({ Items = entries })
    end

    local function update()
        local order, modules = window:GetModules()
        noModules:SetVisible(#order == 0)
        for _, name in ipairs(order) do
            local module = modules[name]
            moduleBars:AddItem({ Title = name, State = module.state, History = { module.state } })
            moduleBars:SetState(name, module.state, module.state .. (module.detail and module.state ~= "Error" and (" · " .. tostring(module.detail)) or ""))
        end
        local errors = window:GetErrors()
        local lines = {}
        for index, entry in ipairs(errors) do
            if index > #errors - 8 then
                local head = string.format("[%s] %s%s", os.date("%H:%M:%S", entry.last or os.time()), (entry.context or entry.source), entry.count > 1 and (" ×" .. entry.count) or "")
                table.insert(lines, 1, head .. "\n" .. tostring(entry.message))
            end
        end
        if #errors > 8 then lines[#lines + 1] = "-- +" .. (#errors - 8) .. " older (the copy icon copies them all)" end
        errorText:Set(table.concat(lines, "\n\n"))
        errorText:SetVisible(#lines > 0)
        noErrors:SetVisible(#lines == 0)
    end

    window:OnStatusChanged(update)
    Theme.onChange(function() if infoPage.frame.Parent then update() end end)
    update()
    -- this session: how long, the script's own counters (Window:Count), Lua memory
    window._startedAt = window._startedAt or os.clock()
    local sessionCard = infoPage:Card({ Title = "This session", Side = "Right", Icon = "book" })
    local uptimeRow = sessionCard:Info({ Title = "Running for", Value = "0s" })
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
