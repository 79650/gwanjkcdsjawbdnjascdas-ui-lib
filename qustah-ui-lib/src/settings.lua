-- Window:SettingsTab({ Title, Icon }) - ready-made tab: accent colour, menu key, window reset, unload and configs.
local Theme = require("theme")

return function(window, cfg)
    cfg = cfg or {}
    local defaultSize = Vector2.new(window.width, window.height)
    local tab = window:Tab({ Title = cfg.Title or "Settings", Icon = cfg.Icon or "rbxassetid://11385220704", Divider = cfg.Divider ~= false })
    local interface = tab:Page("Interface")
    local configs = tab:Page("Configs", { Columns = 1 })

    ------------------------------------------------------------ interface
    local look = interface:Card({ Title = "Interface", Side = "Left" })
    look:ColorPicker({
        Title = "Accent color", Desc = "Saved with your config", Flag = "__ui_accent", Default = Theme.get("accent"),
        Callback = function(color) Theme.set("accent", color) end,
    })
    local menuKey = look:Keybind({
        Title = "Menu key", Desc = "Opens and closes the menu", Flag = "__ui_menu_key", Default = window.key,
        Callback = function(key) window:SetToggleKey(key) end,
    })
    window._menuListeners = window._menuListeners or {}
    table.insert(window._menuListeners, function(key) if menuKey.Value ~= key then menuKey:Set(key, true) end end)
    local windowCard = interface:Card({ Title = "Window", Side = "Right" })
    windowCard:Label("Drag the bottom-right corner to resize the window.")
    windowCard:Button({
        Title = "Reset window size",
        Callback = function()
            window.width, window.height, window.topLeft = defaultSize.X, defaultSize.Y, nil
            window:_layout()
        end,
    })
    windowCard:Button({ Title = "Unload", Confirm = "Click again to unload", Callback = function() window:Destroy() end })

    ------------------------------------------------------------ configs
    local store = window.Config
    local card = configs:Card({ Title = "Configs" })
    local nameInput = card:Input({ Title = "Config name", Placeholder = "my config" })
    local list = card:Dropdown({ Title = "Saved configs", Options = store:List() })
    local autoload = card:Label("")
    local function refresh()
        list:SetOptions(store:List(), true)
        local name = store:GetAutoLoad()
        autoload:Set("Autoload: " .. (name or "none"))
    end
    local function target()
        local typed = nameInput.Value
        if typed and typed ~= "" then return typed end
        return list.Value
    end
    local function report(ok, message, done)
        window:Notify({ Title = ok and done or "Config", Content = message or "", Color = not ok and Color3.fromRGB(215, 130, 130) or nil })
    end
    card:Divider()
    card:Button({ Title = "Save", Callback = function()
        local name = target()
        if not name then return report(false, "Type a name or pick a config") end
        local ok, err = store:Save(name)
        report(ok, ok and name or err, "Saved")
        refresh()
    end })
    card:Button({ Title = "Load", Callback = function()
        local name = target()
        if not name then return report(false, "Pick a config") end
        local ok, err = store:Load(name)
        report(ok, err or name, "Loaded")
    end })
    card:Button({ Title = "Set as autoload", Callback = function()
        local name = target()
        if not name then return report(false, "Pick a config") end
        store:SetAutoLoad(name)
        report(true, name, "Autoload set")
        refresh()
    end })
    card:Button({ Title = "Delete", Confirm = "Click again to delete", Callback = function()
        local name = target()
        if not name then return report(false, "Pick a config") end
        local ok, err = store:Delete(name)
        report(ok, ok and name or err, "Deleted")
        refresh()
    end })
    card:Button({ Title = "Refresh list", Callback = refresh })
    refresh()
    return tab
end
