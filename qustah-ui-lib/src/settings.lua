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

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label
local RED, GREEN = Color3.fromRGB(215, 130, 130), Color3.fromRGB(110, 200, 130)

return function(window, cfg)
    cfg = cfg or {}
    local defaultSize = Vector2.new(window.width, window.height)
    local tab = window:Tab({ Title = cfg.Title or "Settings", Icon = cfg.Icon or "settings", Divider = cfg.Divider ~= false, Header = cfg.Header ~= false })
    local interface = tab:Page("Interface")
    local profiles = tab:Page("Profiles", { Columns = 1 })
    local infoPage = tab:Page("Info")

    ------------------------------------------------------------ interface
    local look = interface:Card({ Title = "Appearance", Side = "Left" })
    local picker
    local swatches
    local function syncSwatches()
        if not swatches then return end
        local accent = Theme.get("accent")
        if accent == Theme.neutral(Theme.pack) then swatches:Set("Neutral", true) else swatches:Set(accent, true) end
    end
    look:Dropdown({
        Title = "Theme", Options = Theme.packOrder, Default = "Dark", Flag = "__ui_theme",
        Callback = function(name)
            Theme.applyPack(name)
            -- the pack may swap the neutral accent: keep the picker / presets in step
            if picker then picker:Set(Theme.get("accent"), true) end
            syncSwatches()
        end,
    })
    swatches = look:Swatches({
        Title = "Accent", Default = "Neutral",
        Callback = function(color, name)
            if name == "Neutral" then color = Theme.neutral(Theme.pack) end
            if picker then picker:Set(color) end
        end,
    })
    picker = look:ColorPicker({
        Title = "Custom accent", Desc = "Any colour, saved with the profile", Flag = "__ui_accent", Default = Theme.get("accent"),
        Callback = function(color) Theme.set("accent", color) syncSwatches() end,
    })
    syncSwatches()
    look:Dropdown({
        Title = "Font", Options = UIFont.order, Default = "Gotham", Flag = "__ui_font",
        Callback = function(name)
            if not UIFont.set(name) then window:Notify({ Title = "Font", Content = name .. " is not available here", Color = RED }) end
        end,
    })
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
    overlays:Toggle({ Title = "Watermark", Desc = "Name · FPS · ping · clock", Flag = "__ui_hud_watermark", Callback = function(on) window:Watermark(on) end })
    overlays:Toggle({ Title = "Keybind list", Desc = "Bound keys on screen", Flag = "__ui_hud_keys", Callback = function(on) window:KeybindList(on) end })
    overlays:Toggle({ Title = "Session bar", Desc = "FPS · ping · players · time", Flag = "__ui_hud_session", Callback = function(on) window:SessionBar(on) end })
    overlays:Dropdown({
        Title = "Performance", Options = { "Off", "Header", "Floating" }, Default = "Off", Flag = "__ui_hud_stats",
        Callback = function(mode) window:StatsMonitor(mode) end,
    })

    ------------------------------------------------------------ profiles
    local defaults = window.Config:Snapshot() -- values every flag had before any profile was loaded
    Profiles(window, profiles, defaults)

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
