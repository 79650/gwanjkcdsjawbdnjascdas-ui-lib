-- Demo of the dashboard-style elements (1.10): run with test/widgets.sh (renders test/showcase/widgets_*.png).
local Lib = getgenv().TestLib
local W = Lib:CreateWindow({ Title = "Qustāh", Version = "V1.00", Tags = { "BETA" }, Size = Vector2.new(600, 470), Folder = "WidgetsDemo" })

------------------------------------------------------------ Board: Hero, StatTiles, SwitchGrid, Timeline
local Board = W:Tab({ Title = "Board", Icon = "layout-dashboard" })
local A, B, C = Board:Page("Overview"), Board:Page("Health"), Board:Page("Activity")
A:Card({ Wide = true }):Hero({ Title = "Tester", Desc = "@Tester · #101", Label = "SESSION", Value = "00:12:44",
    Chips = { { "60 FPS", "activity" }, { "40 ms", "wifi" }, { "2 / 50", "users" } } })
A:Card({ Wide = true }):StatTiles({ Items = {
    { Title = "FPS", Value = "60", Sub = "avg 59.8", History = { 58, 60, 61, 59, 60, 57, 60, 62, 60, 59, 60, 61 } },
    { Title = "Ping", Value = "40 ms", Sub = "peak 52", History = { 42, 40, 41, 45, 39, 40, 52, 44, 40, 41 }, Color = "warning" },
    { Title = "Players", Value = "2 / 50", Sub = "server", History = { 2, 2, 3, 3, 2, 2, 2 }, Color = Color3.fromRGB(127, 180, 232) },
    { Title = "Memory", Value = "26 MB", Sub = "Lua", History = { 20, 21, 22, 22, 23, 24, 25, 26 }, Color = Color3.fromRGB(180, 139, 232) },
} })
A:Card({ Title = "Modules", Icon = "layout-grid", Wide = true }):SwitchGrid({ Items = {
    { Title = "ESP", Icon = "eye", Flag = "demoEsp", Default = true }, { Title = "Silent Aim", Icon = "crosshair", Flag = "demoAim", Default = true },
    { Title = "Movement", Icon = "footprints", Flag = "demoMove" }, { Title = "Mechanics", Icon = "cog", Flag = "demoMech", Default = true },
    { Title = "Misc", Icon = "box", Status = "Limited" },
} })
local feed = A:Card({ Title = "Activity", Icon = "list", Wide = true }):Timeline({ Compact = true, Height = 110 })
for _, e in ipairs({ { "Qustah loaded", "success" }, { "Mechanics on", "success" }, { "Misc on · Anti-AFK limited", "warning" }, { "Click TP · 212 studs" } }) do
    feed:Add({ Title = e[1], Kind = e[2], Time = "19:19" })
end

B:Card({ Title = "Health", Icon = "gauge", Wide = true }):Gauges({ Items = {
    { Title = "FPS", Value = 60, Max = 60, Sub = "of 60" }, { Title = "Ping", Value = 40, Max = 150, Sub = "ms", Color = "warning" },
    { Title = "Players", Value = 2, Max = 50, Sub = "of 50", Color = Color3.fromRGB(127, 180, 232) }, { Title = "Memory", Value = 26, Max = 50, Sub = "MB", Color = Color3.fromRGB(180, 139, 232) },
} })
B:Card({ Title = "Modules", Icon = "layout-grid", Wide = true }):Tiles({ Columns = 4, Align = "Center", Items = {
    { Title = "ESP", Icon = "eye", State = "on" }, { Title = "Silent Aim", Icon = "crosshair", State = "on" }, { Title = "Movement", Icon = "footprints", State = "off" },
    { Title = "Mechanics", Icon = "cog", State = "on" }, { Title = "Skill Speed", Icon = "fast-forward", State = "off" }, { Title = "Camera", Icon = "camera", State = "on" },
    { Title = "Misc", Icon = "box", State = "limited" }, { Title = "Rejoin", Icon = "rotate-ccw", Callback = function() end },
} })
B:Card({ Title = "Modules · last 30 min", Icon = "activity", Wide = true }):StatusBars({ Items = {
    { Title = "ESP", State = "on", History = table.create(30, "on") }, { Title = "Movement", State = "off", History = table.create(30, "off") },
    { Title = "Misc", State = "limited", History = table.create(30, "limited") },
} })

local quick = C:Card({ Title = "Quick switches", Icon = "zap", Wide = true })
quick:Chips({ Flag = "demoChips", Items = { { Title = "ESP", Icon = "eye" }, { Title = "Silent Aim", Icon = "crosshair" }, { Title = "Movement", Icon = "footprints" }, { Title = "Camera", Icon = "camera" } }, Default = { "ESP", "Camera" } })
local tl = C:Card({ Title = "Timeline", Icon = "history", Wide = true }):Timeline({ Height = 230, Filters = { "All", "Modules", "Combat" } })
tl:Add({ Title = "Qustah loaded", Desc = "V1.00 · revision 571", Icon = "rocket", Kind = "success", Time = "19:19:17", Tag = "Modules" })
tl:Add({ Title = "Silent Aim on", Desc = "FOV 60 px · Body", Icon = "crosshair", Kind = "success", Time = "19:19:22", Tag = "Modules" })
tl:Add({ Title = "Misc on", Desc = "Anti-AFK limited: connection control needed", Icon = "box", Kind = "warning", Time = "19:19:22", Tag = "Modules" })
tl:Add({ Title = "Click TP", Desc = "212 studs · onto Player2", Icon = "navigation", Time = "19:21:40", Tag = "Combat" })
tl:Add({ Title = "Perfect block", Desc = "against Player2", Icon = "shield", Time = "19:22:05", Tag = "Combat" })

------------------------------------------------------------ Look: Search, Gallery, ListItem, ThemePreview, SideNav
local Look = W:Tab({ Title = "Look", Icon = "palette" })
local L1, L2, L3 = Look:Page("Gallery"), Look:Page("List"), Look:Page("Side menu")
L1:Card({ Title = "Theme", Icon = "palette", Wide = true }):Gallery({ Flag = "demoTheme", Default = "Dark", Items = {
    { Name = "Dark", Colors = { Color3.fromRGB(18, 18, 19), Color3.fromRGB(27, 27, 29), Color3.fromRGB(92, 92, 98) } },
    { Name = "Midnight", Colors = { Color3.fromRGB(13, 16, 24), Color3.fromRGB(21, 26, 38), Color3.fromRGB(80, 90, 120) } },
    { Name = "Graphite", Colors = { Color3.fromRGB(26, 26, 26), Color3.fromRGB(36, 36, 36), Color3.fromRGB(100, 100, 100) } },
    { Name = "Light", Colors = { Color3.fromRGB(236, 236, 240), Color3.fromRGB(255, 255, 255), Color3.fromRGB(90, 90, 98) } },
} })
L1:Card({ Title = "Font", Icon = "type", Side = "Left" }):Gallery({ Flag = "demoFont", Columns = 3, Default = "Gotham", Items = {
    { Name = "Gotham", Font = Enum.Font.Gotham }, { Name = "Arcade", Font = Enum.Font.Arcade }, { Name = "Code", Font = Enum.Font.Code },
} })
L1:Card({ Title = "Preview", Icon = "monitor", Side = "Right" }):ThemePreview({ Height = 140, Caption = "Gotham · Normal · 100%" })

L2:Card({ Wide = true }):Search({ Placeholder = "Search settings…" })
local g1 = L2:Card({ Title = "Appearance", Wide = true })
g1:ListItem({ Title = "Theme", Icon = "palette", Value = "Dark" })
g1:ListItem({ Title = "Font", Icon = "type", Value = "Gotham" })
g1:ListItem({ Title = "Text glow", Icon = "sparkles", Toggle = true, Flag = "demoGlow", Default = true })
local g2 = L2:Card({ Title = "Behaviour", Wide = true })
g2:ListItem({ Title = "Menu key", Icon = "keyboard", Value = "RSHIFT" })
g2:ListItem({ Title = "Free mouse", Icon = "mouse-pointer", Toggle = true, Flag = "demoFree", Default = true })
g2:ListItem({ Title = "UI sounds", Icon = "volume-2", Toggle = true, Flag = "demoSounds" })

local nav = L3:Card({ Wide = true }):SideNav({ Items = { { "Appearance", "palette" }, { "Behaviour", "sliders-horizontal" }, { "Window", "app-window" }, { "Overlays", "layers" } },
    Footer = function(part) part:Button({ Title = "Unload", Danger = true }) end })
local look = nav:Section("Appearance")
look:Dropdown({ Title = "Theme", Items = { "Dark", "Light" }, Default = "Dark" })
look:Swatches({ Title = "Accent", Style = "Dots" })
look:Segment({ Title = "Text size", Items = { "Small", "Normal", "Large" }, Default = "Normal" })
look:Toggle({ Title = "Text glow", Desc = "Shine on the title and highlights", Default = true })
nav:Section("Behaviour"):Toggle({ Title = "Free mouse", Default = true })

------------------------------------------------------------ Data: ItemCards, DiffList, Notice, Checklist, Changelog
local Data = W:Tab({ Title = "Data", Icon = "database" })
local D1, D2 = Data:Page("Profiles"), Data:Page("Info")
D1:Card({ Wide = true }):Notice({ Kind = "warning", Title = "5 unsaved changes on Default", Desc = "ESP · Silent Aim · Click TP", Button = { Title = "Save", Icon = "save" } })
D1:Card({ Title = "Profiles", Icon = "folder", Wide = true }):ItemCards({ AddNew = "New profile", OnMenu = function() end, Items = {
    { Title = "Default", Sub = "now · 46 settings", Desc = "Active · autoload", Color = Color3.fromRGB(232, 232, 236), Badges = { { Text = "ACTIVE", Role = "success" }, "AUTO" }, Action = "Save", Highlight = true },
    { Title = "Ranked", Sub = "2 days ago · 51 settings", Desc = "Tight FOV, no ESP fade", Color = Color3.fromRGB(74, 157, 224), Action = "Load" },
    { Title = "Farm", Sub = "last week · 38 settings", Desc = "Anti-AFK, auto reset", Color = Color3.fromRGB(94, 196, 110), Badges = { "LOCKED" }, Action = "Load" },
} })
D1:Card({ Title = "Unsaved changes", Icon = "git-compare", Wide = true }):DiffList({ OnRevert = function() end, Items = {
    { Tag = "ESP", Title = "Max distance", Old = "1000", New = "1500" }, { Tag = "Silent Aim", Title = "FOV radius", Old = "100 px", New = "60 px" },
    { Tag = "Misc", Title = "Click TP keys", Old = "LCTRL + M1", New = "LCTRL + M2" },
} })
D2:Card({ Wide = true }):Notice({ Kind = "success", Title = "Everything is running", Desc = "1 module limited by the executor · 47 s", Button = { Title = "Debug info", Icon = "copy" } })
D2:Card({ Title = "Executor", Icon = "terminal-square", Side = "Left" }):Checklist({ Items = {
    { Title = "File access", Ok = true, Note = "profiles" }, { Title = "getcustomasset", Ok = true, Note = "icons" },
    { Title = "gethui", Ok = true, Note = "hidden ESP" }, { Title = "getconnections", Ok = false, Note = "Anti-AFK" },
} })
D2:Card({ Title = "What's new", Icon = "sparkles", Side = "Right" }):Changelog({ Items = {
    { Version = "V1.00 · rev 571", Time = "now", Items = { "Click TP: the game's own teleport", "ESP: bars under the feet", "FOV preview at real size" } },
    { Version = "rev 560", Time = "3 days ago", Items = { "Crosshair from the library" } },
    { Version = "rev 541", Time = "last week", Items = { "Icon sheets redrawn" } },
} })

W:SettingsTab()
