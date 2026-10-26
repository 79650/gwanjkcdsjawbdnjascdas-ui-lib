-- qustah-ui-lib: entry point. The build script bundles every module into dist/qustah-ui-lib.lua.
local Util = require("util")
local Theme = require("theme")
local Window = require("window")
local Notify = require("notify")
local Settings = require("settings")
local Dashboard = require("dashboard")
local Icons = require("icons")
require("status")(Window)
require("dialog")(Window)
require("hud")(Window)
require("inbox")(Window)
require("windowx")(Window)

local Lib = {
    Version = "1.4.1",
    Flags = {},   -- Flag -> current value of every flagged element
    Windows = {},
    Theme = Theme,
    Icons = Icons, -- Lib.Icons.Get("house"), "solar:home-bold", Lib.Icons.SetDefault("solar")
    Util = Util,
}
Lib.maid = Util.maid()

-- Lib:CreateWindow({ Title, Version, Size = Vector2, ToggleKey = Enum.KeyCode, Accent = Color3, Folder, Footer, OnClose })
function Lib:CreateWindow(cfg) return Window.new(self, cfg) end
-- Lib:Notify({ Title, Content, Duration, Color })
function Lib:Notify(cfg) return Notify.show(self, cfg) end
function Lib:SetAccent(color) Theme.set("accent", color) end
-- Any colour role: base, card, input, line, text, muted, heading, accent ...
function Lib:SetColor(role, color) Theme.set(role, color) end
function Lib:GetFlag(flag) return self.Flags[flag] end
function Lib:Destroy()
    for index = #self.Windows, 1, -1 do self.Windows[index]:Destroy() end
    self.maid:clean()
end

function Window:SettingsTab(cfg) return Settings(self, cfg) end
function Window:DashboardTab(cfg) return Dashboard(self, cfg) end

return Lib
