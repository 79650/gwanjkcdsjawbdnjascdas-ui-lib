-- qustah-ui-lib example: every element once, laid out like Qustah.
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/79650/gwanjkcdsjawbdnjascdas-ui-lib/refs/heads/main/qustah-ui-lib/dist/qustah-ui-lib.lua"))()

local Window = Lib:CreateWindow({
    Debug     = false,                    -- true: a notification for every callback error (Settings › Info has the switch)
    Title     = "Qustāh",
    Version   = "V1.00",
    Folder    = "Qustah",                 -- configs go to Qustah/configs/*.json
    ToggleKey = Enum.KeyCode.RightShift,
    Size      = Vector2.new(540, 390),
    -- Accent = Color3.fromRGB(61, 151, 219), -- default is Qustah's neutral grey
})

-- Dock icons: lucide outline (built in, no download) - Dashboard "layout-dashboard", Visuals "eye", Silent "crosshair",
-- Misc "blocks", Settings "settings". Softer look (downloads the solar set once): "solar:widget-5-linear", "solar:eye-linear",
-- "solar:gps-linear", "solar:box-linear", "solar:settings-linear" (Dashboard / SettingsTab take Icon = too).
------------------------------------------------------------------------ Dashboard first (profile, session, info, server tools)
Window:DashboardTab({ Info = { { "Code revision", "571" } } })

------------------------------------------------------------------------ Visuals: two pages
local Visuals = Window:Tab({ Title = "Visuals", Icon = "eye" })            -- icon names (lucide), "solar:eye-linear", or "rbxassetid://..."
local Overview = Visuals:Page("Overview")
local Appearance = Visuals:Page("Appearance")

local General = Overview:Card({ Title = "General" })
General:Toggle({ Title = "ESP enabled", Desc = "Show player ESP.", Flag = "espEnabled", Default = true, Bindable = true, Marker = true,
    Help = "Right-click to bind a key.", Callback = function(on) print("ESP", on) end })
General:Toggle({ Title = "Highlight", Desc = "Character fill and outline", Flag = "highlight", Default = true, Badge = "NEW" })
General:Slider({ Title = "Max distance", Flag = "espRange", Min = 100, Max = 5000, Default = 1500, Step = 10, Suffix = "studs" })
General:Range({ Title = "Health filter", Desc = "Only players inside this health band", Flag = "hpBand", Min = 0, Max = 100, Default = { 0, 100 }, MinGap = 5 })

local Info = Overview:Card({ Title = "Player Info" })
Info:Toggle({ Title = "Display Name", Desc = "The player's visible name", Flag = "showDisplay", Default = true })
Info:Toggle({ Title = "Username", Desc = "The player's account name", Flag = "showUser" })
Info:Toggle({ Title = "Distance", Desc = "Show distance to players.", Flag = "showDistance", Default = true })

local Colors = Appearance:Card({ Title = "Colors" })
Colors:ColorPicker({ Title = "Fill color", Flag = "fillColor", Default = Color3.fromRGB(215, 120, 120) })          -- Rainbow button inside
Colors:ColorPicker({ Title = "Outline color", Flag = "outlineColor", Default = Color3.fromRGB(240, 240, 240), Apply = true }) -- changes only on Apply
Colors:Gradient({ Title = "Chams gradient", Flag = "chams", Default = { Color3.fromRGB(215, 120, 120), Color3.fromRGB(120, 140, 230) },
    Callback = function(sequence, a, b) print("gradient", a, b) end })
Colors:Slider({ Title = "Fill transparency", Flag = "fill", Min = 0, Max = 100, Default = 60, Suffix = "%",
    Icons = { From = "sun-dim", To = "sun" } })   -- icons at the ends (click = one step); a bubble shows the value while dragging
local Text = Appearance:Card({ Title = "Text" })
Text:Swatches({ Title = "Name color", Flag = "nameColor", Default = "Blue", Callback = function(color, name) print("name color", name) end })
Text:Dropdown({ Title = "Font", Flag = "font", Options = { "Gotham", "Code", "Ubuntu", "Arcade" }, Default = "Gotham" })
Text:Dropdown({ Title = "Show", Flag = "parts", Multi = true, Options = { "Name", "Health", "Distance", "Weapon" }, Default = { "Name", "Health" } })

------------------------------------------------------------------------ Silent: one page, locked element
local Silent = Window:Tab({ Title = "Silent", Icon = "crosshair" })
local Aim = Silent:Card({ Title = "Silent Aim" })
local silentToggle = Aim:Toggle({ Title = "Silent Aim", Desc = "Hits targets inside the FOV.", Flag = "silentAim", Bindable = true })
local prediction = Aim:Toggle({ Title = "Prediction", Desc = "Predicts target movement.", Flag = "prediction",
    Locked = true, LockedTitle = "Turn on Silent Aim first" })
silentToggle:OnChanged(function(on) if on then prediction:Unlock() else prediction:Lock("Turn on Silent Aim first") end end)
Aim:Slider({ Title = "Hit chance", Flag = "hitChance", Min = 0, Max = 100, Default = 100, Suffix = "%" })
Aim:Segment({ Title = "Aim part", Flag = "aimPart", Options = { "Head", "Body", "Closest" }, Default = "Head" })
-- dropdown options can carry an icon, a description, or be locked; AllowNone lets it be cleared
Aim:Dropdown({ Title = "Target priority", Flag = "priority", AllowNone = true, Default = "Closest", Options = {
    { Title = "Closest", Icon = "footprints", Desc = "Nearest to you" },
    { Title = "Crosshair", Icon = "crosshair", Desc = "Nearest to the mouse" },
    { Title = "Lowest HP", Icon = "heart", Desc = "Finish weak targets" },
    { Title = "Highest bounty", Icon = "gem", Desc = "Premium only", Locked = true },
} })
local Fov = Silent:Card({ Title = "FOV" })
Fov:Slider({ Title = "Radius", Flag = "fovRadius", Min = 10, Max = 600, Default = 120, Suffix = "px" })
Fov:Keybind({ Title = "Aim key", Icon = "target", Flag = "aimKey", Default = Enum.KeyCode.Q, Pressed = function() print("aim key") end })
Fov:Keybind({ Title = "Mark target", Desc = "Modifier + key or mouse", Chord = true, Flag = "markKey",
    Default = { Enum.KeyCode.LeftControl, Enum.UserInputType.MouseButton1 }, Pressed = function() print("mark") end })

-- one card, several sections switched from its header
local Targets = Silent:Card({ Title = "Targets", Icon = "users" })   -- Icon replaces the dot
local sections = Targets:Tabs({ "Players", "Filters" })
sections.Players:PlayerList({ Title = "Whitelist", Flag = "whitelist", Height = 120, Callback = function(ids) print(#ids, "whitelisted") end })
sections.Filters:Toggle({ Title = "Ignore squad", Flag = "ignoreSquad", Default = true })
sections.Filters:Toggle({ Title = "Ignore friends", Flag = "ignoreFriends" })

------------------------------------------------------------------------ Misc: input, buttons, paragraph
local Misc = Window:Tab({ Title = "Misc", Icon = "blocks" })
local Tools = Misc:Card({ Title = "Tools" })
Tools:Input({ Title = "Target name", Placeholder = "player name", Flag = "targetName" })
Tools:Button({ Title = "Rejoin", Icon = "refresh-cw", Callback = function() print("rejoin") end })
Tools:Button({ Title = "Server hop", Icon = "shuffle", Confirm = true, Callback = function() print("hop") end })
local Crosshair = Misc:Card({ Title = "Crosshair" })
Crosshair:ImagePicker({ Title = "Style", Flag = "crosshair", Columns = 4,
    Images = { "rbxassetid://9943168532", "rbxassetid://12614416478", "rbxassetid://6764432408", "rbxassetid://7072721682" } })
local Perf = Misc:Card({ Title = "Performance" })
Perf:Graph({ Title = "FPS", Source = "FPS", Max = 60 })
local farm = Perf:Progress({ Title = "Auto farm", Desc = "Quests this session", Value = 3, Max = 10, Suffix = "quests" })
local loading = Perf:Progress({ Title = "Loading assets", Indeterminate = true })
task.delay(4, function() loading:SetIndeterminate(false) loading:Set(100) end)

-- collapsible section, buttons side by side, a boxed group, a code block, a 3D preview
local Extras = Misc:Card({ Title = "Extras" })
local advanced = Extras:Section({ Title = "Advanced", Icon = "settings-2", Opened = false })
advanced:Toggle({ Title = "Bypass checks", Flag = "bypass" })
advanced:Slider({ Title = "Delay", Flag = "delay", Min = 0, Max = 1, Step = 0.05, Default = 0.2, Suffix = "s" })
local buttons = Extras:Row()
buttons:Button({ Title = "Start", Icon = "play", Callback = function() farm:Set(farm.Value + 1) end })
buttons:Button({ Title = "Stop", Icon = "square", Callback = function() print("stop") end })
local group = Extras:Group({ Title = "Server" })
group:Info({ Title = "Region", Value = "EU" })
group:Info({ Title = "Uptime", Value = "2h 14m" })
Extras:Code({ Title = "loader.lua", Code = 'loadstring(game:HttpGet("https://example.com/qustah.lua"))() -- load the script' })
local Preview = Misc:Card({ Title = "Preview", Icon = "person-standing" })
Preview:Viewport({ Object = game.Players.LocalPlayer.Character, Height = 150, Spin = true })
local About = Misc:Card({ Title = "About" })
About:Paragraph({ Title = "qustah-ui-lib", Content = "Every element on these pages comes from the library; the script only adds its features." })
About:Divider()
About:Button({ Title = "Notify", Callback = function() Window:Notify({ Title = "Hello", Content = "This is a notification", Duration = 3 }) end })

------------------------------------------------------------------------ key hint above the footer (MENU hint on the right is automatic)
Window:KeyHint({ Title = "ESP / SILENT AIM", Key = Enum.KeyCode.KeypadEight, Side = "Left", Flag = "espKey",
    Pressed = function() print("toggle ESP + Silent Aim") end })

------------------------------------------------------------------------ built-in settings (accent, menu key, configs) - a divider above it in the dock
Window:SettingsTab() -- create it last: its Default profile remembers the values above

-- module health: footer, Dashboard "Modules" and Settings › Info show it
Window:SetModule("ESP", "On")
Window:SetModule("Silent Aim", "Off")
Window:SetModule("Mark", "Limited", "client-side only")

-- your own data in profiles (saved / loaded / shared with them)
Window.Config:SetData("waypoints", { { "Spawn", 0, 10, 0 } })
Window.Config:OnDataLoaded(function(data) print("waypoints", data.waypoints and #data.waypoints) end)

-- header button (left of the bell)
Window:HeaderButton({ Icon = "refresh-cw", Tooltip = "Rejoin", Callback = function() print("rejoin") end })

Window.Config:LoadAutoLoad() -- may also run before the tabs exist: values wait for their elements
Window:Notify({ Title = "Qustāh", Content = "Loaded · RSHIFT to toggle", Icon = "sparkles" })
print(Lib.Flags.espRange) -- current value of any flag
