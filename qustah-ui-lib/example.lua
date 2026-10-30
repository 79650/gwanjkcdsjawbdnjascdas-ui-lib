-- qustah-ui-lib example (v1.9): every element once - Visuals, Combat, Player, Live, Components and Server tabs, then the built-in Settings.
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/79650/gwanjkcdsjawbdnjascdas-ui-lib/refs/heads/main/qustah-ui-lib/dist/qustah-ui-lib.lua"))()

local Window = Lib:CreateWindow({
    Debug     = false,                    -- true: a notification for every callback error (Settings › Info has the switch)
    PerGame   = false,                    -- "Game": every game gets its own profiles (also a switch in Settings › Profiles)
    UnlockMouse = true,                   -- the mouse is free while the menu is open (shift lock / first person)
    Title     = "Qustāh",
    Version   = "V1.00",
    Folder    = "Qustah",                 -- configs go to Qustah/configs/*.json
    ToggleKey = Enum.KeyCode.RightShift,
    Size      = Vector2.new(540, 390),
    Tags      = { "BETA" },               -- small chips after the title ({ Text = "PRO", Color = Color3.fromRGB(240, 190, 80) })
    -- Tour = true,                       -- a short first-run guide, once per account (or Window:Tour({ steps }))
    -- LiveBackground = true,             -- slow accent glow behind the content (Settings › Window has the switch)
    -- AccentGlow = true,                 -- the window edge breathes in the accent
    -- Secure = true,                     -- random gui names + silent console (or getgenv().QUSTAH_SECURE = true before loading)
    -- AutoFlags = true,                  -- elements without a Flag get "Tab.Card.Title" and are saved in profiles too
    -- Rejoin = true,                     -- teleport back after a kick (Settings › Info lists the kicks either way)
    -- Blur = true, Sounds = true,        -- blur the game behind the menu, soft UI clicks (both also in Settings)
    -- Scale = 1.1,                       -- the whole menu bigger / smaller (Settings › Menu › UI scale)
    -- MobileButton = "Auto",             -- reopen button while hidden: "Auto" = phones / tablets, true, false
    -- KeySystem = { Keys = { "QUSTAH-KEY" }, Url = "https://discord.gg/yourserver", Note = "Keys reset daily" },
    Changelog = { Version = "1.00", Items = { "New Session card with live stats", "Tables, radio lists and line graphs" },   -- shown once per version
        History = { { Version = "0.90", Items = { "First public build" } } } },                                      -- Settings › Info › Version history
    -- Accent = Color3.fromRGB(61, 151, 219), -- default is Qustah's neutral grey
})

-- Dock: Dashboard | Visuals, Combat, Player, Live, Components, Server | Settings (dividers are automatic)
-- Icons: lucide outline built in (no download); softer: "solar:eye-linear" (downloads the solar set once), or "rbxassetid://..."
------------------------------------------------------------------------ Dashboard first (profile, session, modules, server tools)
Window:DashboardTab({ Info = { { "Code revision", "571" } } })

------------------------------------------------------------------------ Visuals: two pages (a strip under the header)
local Visuals = Window:Tab({ Title = "Visuals", Icon = "eye" })
local Overview = Visuals:Page("Overview")
local Appearance = Visuals:Page("Appearance")

local General = Overview:Card({ Title = "General", Icon = "scan-eye" })
General:Toggle({ Title = "ESP enabled", Desc = "Show player ESP.", Flag = "espEnabled", Default = true, Bindable = true, Marker = true,
    Help = "Right-click to bind a key.", Callback = function(on) print("ESP", on) end })
General:Toggle({ Title = "Highlight", Desc = "Character fill and outline", Flag = "highlight", Default = true, Badge = "NEW" })
General:Slider({ Title = "Max distance", Flag = "espRange", Min = 100, Max = 5000, Default = 1500, Step = 10, Suffix = "studs" })
General:Range({ Title = "Health filter", Desc = "Only players inside this health band", Flag = "hpBand", Min = 0, Max = 100, Default = { 0, 100 }, MinGap = 5 })

local Info = Overview:Card({ Title = "Player Info", Icon = "id-card" })
Info:Toggle({ Title = "Display Name", Desc = "The player's visible name", Flag = "showDisplay", Default = true })
Info:Toggle({ Title = "Username", Desc = "The player's account name", Flag = "showUser" })
Info:Toggle({ Title = "Distance", Desc = "Show distance to players.", Flag = "showDistance", Default = true })
Info:Dropdown({ Title = "Show", Flag = "parts", Multi = true, Options = { "Name", "Health", "Distance", "Weapon" }, Default = { "Name", "Health" } })

local Colors = Appearance:Card({ Title = "Colors", Icon = "palette" })
Colors:ColorPicker({ Title = "Fill color", Flag = "fillColor", Default = Color3.fromRGB(215, 120, 120) })          -- Rainbow button inside
Colors:ColorPicker({ Title = "Outline color", Flag = "outlineColor", Default = Color3.fromRGB(240, 240, 240), Apply = true }) -- changes only on Apply
Colors:ColorPicker({ Title = "Glow color", Flag = "glowColor", Default = Color3.fromRGB(120, 170, 255), Alpha = true, Transparency = 0.35,
    Callback = function(color, transparency) print("glow", color, transparency) end })   -- Alpha: a transparency bar too
Colors:Gradient({ Title = "Chams gradient", Flag = "chams", Default = { Color3.fromRGB(215, 120, 120), Color3.fromRGB(120, 140, 230) },
    Callback = function(sequence, a, b) print("gradient", a, b) end })
Colors:Slider({ Title = "Fill transparency", Flag = "fill", Min = 0, Max = 100, Default = 60, Suffix = "%",
    Icons = { From = "sun-dim", To = "sun" } })   -- icons at the ends (click = one step); a bubble shows the value while dragging
local Text = Appearance:Card({ Title = "Text", Icon = "type" })
Text:Swatches({ Title = "Name color", Flag = "nameColor", Default = "Blue", Callback = function(color, name) print("name color", name) end })
Text:Dropdown({ Title = "Font", Flag = "font", Options = { "Gotham", "Code", "Ubuntu", "Arcade" }, Default = "Gotham" })
Text:Slider({ Title = "Text size", Flag = "textSize", Min = 8, Max = 24, Default = 13, Suffix = "px" })

------------------------------------------------------------------------ Combat: one page (no strip), risky + locked elements, presets
local Combat = Window:Tab({ Title = "Combat", Icon = "crosshair" })
local Aim = Combat:Card({ Title = "Silent Aim", Icon = "target", Desc = "Redirects your shots to the target" })   -- cards fold with the arrow
Combat.Pages[1]:Warning("Silent aim can be detected in ranked servers.", { Title = "Risky features" })   -- shown above the cards
local silentToggle = Aim:Toggle({ Title = "Silent Aim", Desc = "Hits targets inside the FOV.", Flag = "silentAim", Bindable = true,
    Risky = "Can get you flagged in ranked" })   -- red title + this text on the "i"
local prediction = Aim:Toggle({ Title = "Prediction", Desc = "Predicts target movement.", Flag = "prediction",
    Locked = true, LockedTitle = "Turn on Silent Aim first" })
silentToggle:OnChanged(function(on) if on then prediction:Unlock() else prediction:Lock("Turn on Silent Aim first") end end)
Aim:Slider({ Title = "Hit chance", Flag = "hitChance", Min = 0, Max = 100, Default = 100, Suffix = "%" })
Aim:Checkbox({ Title = "Visible only", Flag = "visibleOnly", DependsOn = "silentAim",   -- locked until Silent Aim is on
    Tooltip = "Skips targets behind walls" })
Aim:Segment({ Title = "Aim part", Flag = "aimPart", Options = { "Head", "Body", "Closest" }, Default = "Head" })
-- presets: chips in the card header that set several flags at once ("Custom" lights up after a manual change)
Aim:Presets({ { "Legit", { hitChance = 70, aimPart = "Body" } }, { "Rage", { hitChance = 100, aimPart = "Head" } } })
-- dropdown options can carry an icon, a description, or be locked; AllowNone lets it be cleared
Aim:Dropdown({ Title = "Target priority", Flag = "priority", AllowNone = true, Default = "Closest", Options = {
    { Title = "Closest", Icon = "footprints", Desc = "Nearest to you" },
    { Title = "Crosshair", Icon = "crosshair", Desc = "Nearest to the mouse" },
    { Title = "Lowest HP", Icon = "heart", Desc = "Finish weak targets" },
    { Title = "Highest bounty", Icon = "gem", Desc = "Premium only", Locked = true },
} })
local Fov = Combat:Card({ Title = "FOV", Icon = "circle-dashed" })
Fov:Slider({ Title = "Radius", Flag = "fovRadius", Min = 10, Max = 600, Default = 120, Suffix = "px",
    Callback = function(value, dragging) if not dragging then print("radius", value) end end })   -- dragging = true while the knob is held
Fov:Toggle({ Title = "Aim assist", Desc = "Hold right mouse", Flag = "aimAssist", Bind = Enum.UserInputType.MouseButton2, BindMode = "Hold" })
Fov:Keybind({ Title = "Aim key", Icon = "target", Flag = "aimKey", Default = Enum.KeyCode.Q, Pressed = function() print("aim key") end })
Fov:Keybind({ Title = "Mark target", Desc = "Modifier + key or mouse", Chord = true, Flag = "markKey",
    Default = { Enum.KeyCode.LeftControl, Enum.UserInputType.MouseButton1 }, Pressed = function() print("mark") end })

-- one card, several sections switched from its header
local Targets = Combat:Card({ Title = "Targets", Icon = "users" })
local sections = Targets:Tabs({ "Players", "Filters" })
sections.Players:PlayerList({ Title = "Whitelist", Flag = "whitelist", Height = 120, Callback = function(ids) print(#ids, "whitelisted") end })
sections.Filters:Toggle({ Title = "Ignore squad", Flag = "ignoreSquad", Default = true })
sections.Filters:Toggle({ Title = "Ignore friends", Flag = "ignoreFriends" })
sections.Filters:Radio({ Title = "When two are close", Flag = "tieBreak", Options = { "Lower health", "Closer to mouse", { Title = "Random", Desc = "Harder to spot" } } })

------------------------------------------------------------------------ Player: movement, character, 3D preview
local Player = Window:Tab({ Title = "Player", Icon = "person-standing" })
local Move = Player:Card({ Title = "Movement", Icon = "footprints" })
Move:Slider({ Title = "Walk speed", Flag = "walkSpeed", Min = 16, Max = 100, Default = 16, Suffix = " studs/s" })
Move:Slider({ Title = "Jump power", Flag = "jumpPower", Min = 0, Max = 200, Default = 50 })
Move:Toggle({ Title = "Fly", Desc = "WASD + Space / Ctrl", Icon = "plane", Flag = "fly", Bind = Enum.KeyCode.F })   -- the key cap shows the bind
Move:Toggle({ Title = "Infinite jump", Icon = "rabbit", Flag = "infJump" })
Move:Keybind({ Title = "Noclip", Icon = "ghost", Flag = "noclipKey", Default = Enum.KeyCode.N, Pressed = function() print("noclip") end })
local Char = Player:Card({ Title = "Character", Icon = "user-round", Side = "Right" })
Char:Viewport({ Object = game.Players.LocalPlayer.Character, Height = 150, Spin = true })   -- a spinning 3D preview
Char:Button({ Title = "Teleport", Icon = "map-pin", Flag = "tpSpot", Menu = { "Spawn", "Shop", "Arena" },   -- split button: the arrow picks
    Callback = function(spot) print("teleport to", spot) end })
Char:Button({ Title = "Hold to reset character", Icon = "rotate-ccw", Style = "Danger", Hold = 1.2,   -- fills while held, runs when full
    Callback = function() print("reset") end })

------------------------------------------------------------------------ Live: numbers that move (stats, graphs, progress, log, table)
local Live = Window:Tab({ Title = "Live", Icon = "activity" })
local Perf = Live:Card({ Title = "Performance", Icon = "gauge", Side = "Left" })
Perf:Graph({ Title = "FPS", Source = "FPS", Max = 60 })
Perf:Graph({ Title = "Network", Style = "Line", Series = { { Name = "FPS", Source = "FPS" }, { Name = "Ping", Source = "Ping", Color = "warning" } } })
local Farm = Live:Card({ Title = "Farm", Icon = "sprout", Side = "Left" })
local farm = Farm:Progress({ Title = "Auto farm", Desc = "Quests this session", Value = 3, Max = 10, Suffix = "quests" })
local loading = Farm:Progress({ Title = "Loading assets", Indeterminate = true })
task.delay(4, function() loading:SetIndeterminate(false) loading:Set(100) end)
local farmButtons = Farm:Row({ Widths = { 3, 1 } })                          -- side by side: 3/4 and 1/4
farmButtons:Button({ Title = "Auto farm", Icon = "sprout", Toggle = true, Flag = "autoFarm", OnTitle = "Farming",   -- an on / off button
    Callback = function(on) if on then farm:Set(farm.Value + 1) end end })
farmButtons:Button({ Icon = "inbox", Style = "Soft", Badge = 3, Tooltip = "Inbox" })   -- icon-only, with a badge
Farm:Button({ Title = "Redeem all codes", Icon = "gift", LoadingText = "Redeeming...",   -- a spinner while this waits
    Callback = function() task.wait(2) end })

local Session = Live:Card({ Title = "Session", Icon = "activity", Side = "Right" })
local coins = Session:Stat({ Title = "Coins", Icon = "coins", Value = 12450, Prefix = "$" })   -- digits roll, the chip shows the change
local pingStat = Session:Stat({ Title = "Ping", Icon = "wifi", Value = 48, Suffix = " ms", Delta = "absolute", Invert = true }) -- lower is better
Session:Progress({ Title = "Daily quests", Steps = 5, Value = 2 })   -- 5 segments
local log = Session:Console({ Title = "Log", Height = 130, MaxLines = 100 })
Session:Table({ Title = "Top players", Height = 120, Columns = { "Name", { Title = "Kills", Align = "Right", Width = 0.25 }, { Title = "Team", Width = 0.25 } },
    Rows = { { "Nova", 31, "Red" }, { "Kite", 24, "Blue" }, { "Ash", 12, "Red" } }, SortBy = "Kills", Descending = true,
    OnRowClick = function(row) print("spectate", row[1]) end })   -- click a header to sort
log:Append("Script loaded", "success")
task.spawn(function()
    while task.wait(4) do
        if not Window.alive then break end
        local earned = math.random(20, 400)
        coins:Add(earned)
        pingStat:Set(math.random(35, 90))
        log:Print("Sold loot for", earned, "coins")
    end
end)

------------------------------------------------------------------------ Components: every remaining element, one page per kind
local Components = Window:Tab({ Title = "Components", Icon = "component" })
Components:SetBadge("NEW")   -- a tag on the dock icon (a number, "NEW", or true for a dot; nil hides it)
-- (a big tab can also be built on first open: Window:Tab({ Title = "Components", Build = function(tab) ... end }))
local ButtonsPage = Components:Page("Buttons")
local InputsPage = Components:Page("Inputs")
local ContentPage = Components:Page("Content")

local Styles = ButtonsPage:Card({ Title = "Styles", Icon = "mouse-pointer-click" })
for _, style in ipairs({ { "Default", "refresh-cw", "Rejoin" }, { "Primary", "play", "Start farm" }, { "Soft", "sparkles", "Redeem codes" },
    { "Outline", "shuffle", "Server hop" }, { "Ghost", "rotate-ccw", "Reset to default" }, { "Danger", "trash-2", "Delete profile" },
    { "Link", "external-link", "Open Discord" } }) do
    Styles:Button({ Title = style[3], Icon = style[2], Style = style[1], Callback = function() print(style[1]) end })
end
local Smart = ButtonsPage:Card({ Title = "Smart buttons", Icon = "zap", Side = "Right" })
Smart:Button({ Title = "Server hop", Icon = "shuffle", Cooldown = 5, Callback = function() print("hop") end })   -- refills over 5 s
Smart:Button({ Title = "Rejoin", Icon = "refresh-cw", Style = "Primary", Bind = Enum.KeyCode.F6, Bindable = true,   -- F6 presses it; right-click to change
    Callback = function() print("rejoin") end })
Smart:Button({ Title = "Wipe saved data", Icon = "trash-2", Style = "Danger", Confirm = true,   -- asks "Sure?" on the first click
    Callback = function() print("wiped") end })
local sizes = Smart:Row()
sizes:Button({ Title = "Small", Size = "Small", Icon = "minimize-2" })
sizes:Button({ Title = "Next", Size = "Small", Icon = "arrow-right", IconSide = "Right", Style = "Outline" })
local media = Smart:Row()
for _, icon in ipairs({ "play", "pause", "square", "skip-forward" }) do media:Button({ Icon = icon, Style = "Soft" }) end

local Fields = InputsPage:Card({ Title = "Text", Icon = "text-cursor-input" })
Fields:Input({ Title = "Target name", Placeholder = "player name", Flag = "targetName",
    Validate = function(text)                 -- checked while typing: green / red edge + a short message
        if text == "" then return nil end
        local ok = #text >= 3 and #text <= 20 and not text:find("[^%w_]")
        return ok, ok and "Looks like a username" or "3-20 letters, digits or _"
    end })
Fields:Stepper({ Title = "Clicks per second", Flag = "cps", Min = 1, Max = 20, Default = 8 })   -- [-] 8 [+], hold to repeat
Fields:TextArea({ Title = "Auto chat message", Flag = "chatMessage", Placeholder = "gg, good game", Height = 60, MaxLength = 120 })
local advanced = Fields:Section({ Title = "Advanced", Icon = "settings-2", Opened = false })   -- folds inside the card
advanced:Toggle({ Title = "Bypass checks", Flag = "bypass" })
advanced:Slider({ Title = "Delay", Flag = "delay", Min = 0, Max = 1, Step = 0.05, Default = 0.2, Suffix = "s" })
local Pick = InputsPage:Card({ Title = "Pick", Icon = "list-checks", Side = "Right" })
Pick:ImagePicker({ Title = "Crosshair style", Flag = "crosshair", Columns = 4,   -- asset ids ("rbxassetid://...") or icon names
    Images = { "crosshair", "locate-fixed", "scan", "plus" } })
Pick:Checkbox({ Title = "Remember choice", Flag = "remember", Default = true })
Pick:Radio({ Title = "Quality", Flag = "quality", Options = { "Low", "Medium", "High" }, Default = "Medium" })

local Notes = ContentPage:Card({ Title = "Messages", Icon = "bell" })
Notes:Button({ Title = "Notify", Icon = "bell", Callback = function() Window:Notify({ Title = "Hello", Content = "This is a notification", Icon = "bell" }) end }) -- time follows the text, hover pauses
Notes:Button({ Title = "Toast", Icon = "check", Callback = function() Window:Toast({ Text = "Saved", Icon = "check" }) end })   -- small pill at the top
Notes:Button({ Title = "Progress toast", Icon = "loader", Callback = function()
    local toast = Window:Notify({ Title = "Farming", Steps = 5, Content = "Starting", Icon = "sprout", Sound = true })
    for step = 1, 5 do task.wait(0.6) toast:SetStep(step, step == 5 and "Done" or "Quest " .. step) end
end })
Notes:Button({ Title = "Ask first", Icon = "message-square", Callback = function()
    Window:Dialog({ Title = "Enable Silent Aim?", Content = "Can be detected in ranked servers.", Icon = "triangle-alert", Buttons = {
        { Title = "Cancel" }, { Title = "Enable", Style = "Danger", Callback = function() Window:SetFlag("silentAim", true) end } } })
end })
local About = ContentPage:Card({ Title = "About", Icon = "info", Side = "Right" })
About:Image({ Image = "layers", Height = 48 })   -- an icon name, asset id or web image
About:Label("Made with qustah-ui-lib")
About:Paragraph({ Title = "qustah-ui-lib", Content = "Every element on these pages comes from the library; the script only adds its features." })
About:Divider()
local group = About:Group({ Title = "Build" })   -- a boxed group
group:Info({ Title = "Version", Value = "1.00" })
group:Info({ Title = "Updated", Value = "today" })
About:Code({ Title = "loader.lua", Code = 'loadstring(game:HttpGet("https://example.com/qustah.lua"))() -- load the script' })

------------------------------------------------------------------------ Server: info, rejoin / hop, network graph
local Server = Window:Tab({ Title = "Server", Icon = "server" })
local ServerInfo = Server:Card({ Title = "This server", Icon = "info" })
ServerInfo:Info({ Title = "Players", Value = #game.Players:GetPlayers() .. " / " .. game.Players.MaxPlayers })
ServerInfo:Info({ Title = "Job ID", Value = string.sub(game.JobId, 1, 8), Copy = game.JobId })   -- Copy button copies the full id
ServerInfo:Toggle({ Title = "Auto rejoin on kick", Flag = "autoRejoin" })
ServerInfo:ActionInput({ Icon = "log-in", Placeholder = "Job ID", Button = "Join", Hint = "Paste a server's Job ID to join it",   -- text field with its own button
    Validate = function(text) if text == "" then return nil end return #text >= 8, #text >= 8 and "Looks like a Job ID" or "Too short" end,
    Callback = function(jobId) print("join", jobId) end })
local hop = ServerInfo:Row()
hop:Button({ Title = "Rejoin", Icon = "refresh-cw", Callback = function() print("rejoin") end })
hop:Button({ Title = "Hop", Icon = "shuffle", Cooldown = 5, Flag = "hopPrefer",   -- split button + a 5 s cooldown
    Menu = { "Smallest", "Lowest ping", "Random" },   -- the arrow picks the kind of server; the main part hops again with it
    Callback = function(prefer) print("hop to a server:", prefer) end })
local Network = Server:Card({ Title = "Network", Side = "Right", Icon = "wifi" })
Network:Graph({ Title = "Ping", Source = "Ping", Style = "Line", Suffix = " ms" })

------------------------------------------------------------------------ key hint above the footer (MENU hint on the right is automatic)
Window:KeyHint({ Title = "ESP / SILENT AIM", Key = Enum.KeyCode.KeypadEight, Side = "Left", Flag = "espKey",
    Pressed = function() print("toggle ESP + Silent Aim") end })

------------------------------------------------------------------------ built-in settings (accent, menu key, configs) - a divider above it in the dock
Window:SettingsTab() -- create it last: its Default profile remembers the values above

-- module health: footer, Dashboard "Modules" and Settings › Info show it
Window:SetModule("ESP", "On", nil, { Icon = "eye", Tab = "Visuals" })        -- icon + tab for the Dashboard tile (a click opens it)
Window:SetModule("Silent Aim", "Off", nil, { Icon = "crosshair", Tab = "Combat" })
Window:SetModule("Mark", "Limited", "client-side only", { Icon = "target", Tab = "Combat" })

-- your own data in profiles (saved / loaded / shared with them)
Window.Config:SetData("waypoints", { { "Spawn", 0, 10, 0 } })
Window.Config:OnDataLoaded(function(data) print("waypoints", data.waypoints and #data.waypoints) end)

-- header button (left of the bell)
Window:HeaderButton({ Icon = "refresh-cw", Tooltip = "Rejoin", Callback = function() print("rejoin") end })

-- kicks: reason + code (also listed in Settings › Info)
Window:OnKick(function(info) print("kicked:", info.Kind, info.Reason, info.Code) end)

Window.Config:LoadAutoLoad() -- may also run before the tabs exist: values wait for their elements
Window:Notify({ Title = "Qustāh", Content = "Loaded · RSHIFT to toggle", Icon = "sparkles" })
print(Window.Flags.espRange) -- current value of any flag; Window.Flags.espRange = 2000 sets it (UI + callback)
