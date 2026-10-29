-- qustah-ui-lib: entry point. The build script bundles every module into dist/qustah-ui-lib.lua.
local Util = require("util")
local Theme = require("theme")
local Window = require("window")
local Notify = require("notify")
local Settings = require("settings")
local Dashboard = require("dashboard")
local Icons = require("icons")
local Sounds = require("sounds")
local Gate = require("gate")
require("status")(Window)
require("dialog")(Window)
require("hud")(Window)
require("inbox")(Window)
require("windowx")(Window)
require("windowfx")(Window)
require("kick")(Window)
require("mobile")(Window)
require("tour")(Window)

local Lib = {
    Version = "1.9.5",
    Flags = {},   -- Flag -> current value of every flagged element
    Windows = {},
    Theme = Theme,
    Icons = Icons, -- Lib.Icons.Get("house"), "solar:home-bold", Lib.Icons.SetDefault("solar")
    Sounds = Sounds, -- Lib.Sounds.Enabled = true, Lib.Sounds.Set("click", id)
    Haptics = require("haptics"), -- Lib.Haptics.Enabled (on for touch screens)
    Util = Util,
}
Lib.maid = Util.maid()

-- Lib:CreateWindow({ Title, Version, Size = Vector2, ToggleKey = Enum.KeyCode, Accent = Color3, Folder, Footer, OnClose })
-- With KeySystem the call waits until a key is accepted; closing the key screen stops the script.
function Lib:CreateWindow(cfg)
    cfg = cfg or {}
    if cfg.Secure then Util.secure = true end
    if type(cfg.KeySystem) == "table" and not Gate.run(self, cfg) then
        error("[qustah-ui-lib] no key entered - the script was stopped", 0)
    end
    return Window.new(self, cfg)
end
function Lib:ForgetKey(folder) Gate.forget(folder) end
-- Lib:Notify({ Title, Content, Duration, Color })
function Lib:Notify(cfg) return Notify.show(self, cfg) end
-- Lib:Toast("Saved") / Lib:Toast({ Text, Icon, Image, Color, Position = "Top" | "Bottom", Duration })
function Lib:Toast(cfg) return Notify.pill(self, cfg) end
Lib.MaxNotifications = 6
function Lib:SetAccent(color) Theme.set("accent", color) end
-- Any colour role: base, card, input, line, text, muted, heading, accent ...
function Lib:SetColor(role, color) Theme.set(role, color) end
function Lib:GetFlag(flag) return self.Flags[flag] end
-- Secure mode: random gui names, a silent console (also getgenv().QUSTAH_SECURE = true before loading)
function Lib:SetSecure(on) Util.secure = on ~= false end
function Lib:IsSecure() return Util.secure == true end
function Lib:Destroy()
    for index = #self.Windows, 1, -1 do self.Windows[index]:Destroy() end
    self.maid:clean()
end

-- (the built-in tabs keep their own flags: AutoFlags is off while they are built)
local function builtIn(window, build, cfg)
    window._noAutoFlags = true
    local ok, result = pcall(build, window, cfg)
    window._noAutoFlags = nil
    if not ok then error(result, 0) end
    return result
end
function Window:SettingsTab(cfg) return builtIn(self, Settings, cfg) end
function Window:DashboardTab(cfg) return builtIn(self, Dashboard, cfg) end

return Lib
