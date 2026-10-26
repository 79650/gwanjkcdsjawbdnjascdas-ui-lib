-- qustah-ui-lib example: every element once, laid out like Qustah.
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/79650/gwanjkcdsjawbdnjascdas-ui-lib/refs/heads/main/qustah-ui-lib/dist/qustah-ui-lib.lua"))()

local Window = Lib:CreateWindow({
    Title     = "Qustāh",
    Version   = "V1.00",
    Folder    = "Qustah",                 -- configs go to Qustah/configs/*.json
    ToggleKey = Enum.KeyCode.RightShift,
    Size      = Vector2.new(540, 390),
    -- Accent = Color3.fromRGB(61, 151, 219), -- default is Qustah's neutral grey
})

------------------------------------------------------------------------ Dashboard first (profile, session, info, server tools)
Window:DashboardTab({ Info = { { "Code revision", "571" } } })

------------------------------------------------------------------------ Visuals: two pages
local Visuals = Window:Tab({ Title = "Visuals", Icon = "rbxassetid://78134819718605" })
local Overview = Visuals:Page("Overview")
local Appearance = Visuals:Page("Appearance")

local General = Overview:Card({ Title = "General" })
General:Toggle({ Title = "ESP enabled", Desc = "Show player ESP.", Flag = "espEnabled", Default = true, Bindable = true,
    Help = "Right-click to bind a key.", Callback = function(on) print("ESP", on) end })
General:Toggle({ Title = "Highlight", Desc = "Character fill and outline", Flag = "highlight", Default = true })
General:Slider({ Title = "Max distance", Flag = "espRange", Min = 100, Max = 5000, Default = 1500, Step = 10, Suffix = "studs" })

local Info = Overview:Card({ Title = "Player Info" })
Info:Toggle({ Title = "Display Name", Desc = "The player's visible name", Flag = "showDisplay", Default = true })
Info:Toggle({ Title = "Username", Desc = "The player's account name", Flag = "showUser" })
Info:Toggle({ Title = "Distance", Desc = "Show distance to players.", Flag = "showDistance", Default = true })

local Colors = Appearance:Card({ Title = "Colors" })
Colors:ColorPicker({ Title = "Fill color", Flag = "fillColor", Default = Color3.fromRGB(215, 120, 120) })
Colors:ColorPicker({ Title = "Outline color", Flag = "outlineColor", Default = Color3.fromRGB(240, 240, 240) })
Colors:Slider({ Title = "Fill transparency", Flag = "fill", Min = 0, Max = 100, Default = 60, Suffix = "%" })
local Text = Appearance:Card({ Title = "Text" })
Text:Dropdown({ Title = "Font", Flag = "font", Options = { "Gotham", "Code", "Ubuntu", "Arcade" }, Default = "Gotham" })
Text:Dropdown({ Title = "Show", Flag = "parts", Multi = true, Options = { "Name", "Health", "Distance", "Weapon" }, Default = { "Name", "Health" } })

------------------------------------------------------------------------ Silent: one page, locked element
local Silent = Window:Tab({ Title = "Silent", Icon = "rbxassetid://11738355467" })
local Aim = Silent:Card({ Title = "Silent Aim" })
local silentToggle = Aim:Toggle({ Title = "Silent Aim", Desc = "Hits targets inside the FOV.", Flag = "silentAim", Bindable = true })
local prediction = Aim:Toggle({ Title = "Prediction", Desc = "Predicts target movement.", Flag = "prediction",
    Locked = true, LockedTitle = "Turn on Silent Aim first" })
silentToggle:OnChanged(function(on) if on then prediction:Unlock() else prediction:Lock("Turn on Silent Aim first") end end)
Aim:Slider({ Title = "Hit chance", Flag = "hitChance", Min = 0, Max = 100, Default = 100, Suffix = "%" })
Aim:Segment({ Title = "Aim part", Flag = "aimPart", Options = { "Head", "Body", "Closest" }, Default = "Head" })
local Fov = Silent:Card({ Title = "FOV" })
Fov:Slider({ Title = "Radius", Flag = "fovRadius", Min = 10, Max = 600, Default = 120, Suffix = "px" })
Fov:Keybind({ Title = "Aim key", Flag = "aimKey", Default = Enum.KeyCode.Q, Pressed = function() print("aim key") end })

------------------------------------------------------------------------ Misc: input, buttons, paragraph
local Misc = Window:Tab({ Title = "Misc", Icon = "rbxassetid://87846110657364" })
local Tools = Misc:Card({ Title = "Tools" })
Tools:Input({ Title = "Target name", Placeholder = "player name", Flag = "targetName" })
Tools:Button({ Title = "Rejoin", Callback = function() print("rejoin") end })
Tools:Button({ Title = "Server hop", Confirm = true, Callback = function() print("hop") end })
local About = Misc:Card({ Title = "About" })
About:Paragraph({ Title = "qustah-ui-lib", Content = "Every element on these pages comes from the library; the script only adds its features." })
About:Divider()
About:Button({ Title = "Notify", Callback = function() Window:Notify({ Title = "Hello", Content = "This is a notification", Duration = 3 }) end })

------------------------------------------------------------------------ key hint above the footer (MENU hint on the right is automatic)
Window:KeyHint({ Title = "ESP / SILENT AIM", Key = Enum.KeyCode.KeypadEight, Side = "Left", Flag = "espKey",
    Pressed = function() print("toggle ESP + Silent Aim") end })

------------------------------------------------------------------------ built-in settings (accent, menu key, configs) - a divider above it in the dock
Window:SettingsTab()

Window.Config:LoadAutoLoad()
Window:Notify({ Title = "Qustāh", Content = "Loaded · RSHIFT to toggle" })
print(Lib.Flags.espRange) -- current value of any flag
