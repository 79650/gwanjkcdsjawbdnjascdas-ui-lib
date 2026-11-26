# Qustah UI documentation

[← Back to the README](README.md) · [Example](example.lua)

[Window](#window) · [Tabs, pages and cards](#tabs-pages-and-cards) · [Elements](#elements) · [Flags](#flags) · [Notifications](#notifications) · [Dialogs](#dialogs) · [Configs and profiles](#configs-and-profiles) · [Built-in tabs](#built-in-tabs) · [Overlays](#overlays) · [Themes](#themes) · [Icons](#icons) · [Status, errors and kicks](#status-errors-and-kicks) · [Window extras](#window-extras) · [Key system](#key-system) · [Tour](#tour) · [Changelog](#changelog) · [Links](#links) · [Secure mode](#secure-mode) · [Development](#development)

---

## Window

```lua
local Window = Lib:CreateWindow({ Title = "Qustāh", Version = "V1.00", Folder = "Qustah" })
```

| Option | Default | Description |
|---|---|---|
| `Title`, `Version` | `"Qustah UI"`, `""` | the title and the version badge next to it |
| `Icon` | — | logo before the title (icon name, asset id or web image) |
| `Tags` | — | chips next to the title: `{ "BETA", { Text = "PRO", Color = Color3 } }` |
| `Folder` | the title | folder for files (profiles, window position, themes) |
| `Size`, `MinSize`, `MaxSize` | `540×390` | `Vector2`; resized from the corner, scaled down on small screens |
| `ToggleKey` | `RightShift` | key that opens and closes the menu |
| `Accent` | Qustah grey | `Color3` |
| `Theme` | `"Ash"` | starting theme: `"Ash"`, `"Charcoal"`, `"Onyx"`, `"Charcoal Rose"`, `"Ice"`, `"Forest"`, `"Wine"`, `"Peach"`, `"Rust"` (see [Themes](#themes)) |
| `WaitForDownloads` | `true` | the window stays hidden while the download strip shows (icon sheets) and opens when it is done; `false` opens it at once |
| `DownloadTimeout` | `30` | seconds the window waits for the downloads at most |
| `Footer` | the game's name | text in the status bar, after the status |
| `KeyHints` | `true` | the `[RSHIFT] MENU` key cap on the right of the status bar |
| `CloseAction` | `"Hide"` | the X button: `"Hide"` hides the menu and shows how to reopen it, `"Destroy"` unloads everything |
| `SaveWindow` | `true` | remember position, size and floating panels |
| `UnlockMouse` | `true` | frees the mouse while the menu is open (shift lock, first person) |
| `Profile`, `Anonymous` | `true`, `false` | the avatar button in the dock; start in anonymous mode |
| `FullscreenButton` | `false` | a fullscreen button in the header (double click on the header still goes fullscreen) |
| `NotificationHistory` | `true` | the bell in the header (notification history) |
| `Background`, `BackgroundTransparency` | — | background image, window transparency |
| `LiveBackground`, `AccentGlow` | `false` | slow accent light drifting behind the content; window edge that pulses in the accent colour |
| `Welcome` | `true` | "Signed in as" toast the first time an account opens the menu |
| `AutoFlags` | `false` | gives elements without a Flag one based on their name (see [Flags](#flags)) |
| `ResetButtons` | `true` | the small reset icon after a changed element's title (see [Flags](#flags)) |
| `Font` | `"Jura"` | starting font: `"Ubuntu"`, `"Roboto"`, `"Michroma"`, `"Josefin Sans"`, or a list such as `{ "Ubuntu", "Roboto" }` (the first known one) (see [Themes](#themes)) |
| `CodeFont` | `"RobotoMono"` | font of Code, Console and Log text (an `Enum.Font` name) |
| `SegmentStyle` | `"Underline"` | look of every Segment: `"Underline"`, `"Boxed"`, `"Tab"`, `"Line"`, `"Dot"`, `"Divided"`, `"Ghost"`, `"Track"`, `"Pills"`, `"Capsule"` (see [Segment](#dropdown-segment-and-radio)) |
| `DockSide` | `"Right"` | where the tabs sit: `"Right"` (icons beside the window), `"Bottom"` (in a row under it) or `"Side"` (a sidebar inside the window with the tab names; the window grows by its 132 px so the pages keep their width; the profile becomes a card at its bottom: avatar, name, session time and an eye for anonymous mode); Settings › Interface › Window › Look › Dock, `Window:SetDockSide` |
| `Defaults` | - | the script's starting values, `{ flag = value }` in profile format (a saved profile's `flags`): a fresh start uses them and reset / "changes" compare against them; a saved profile or AutoLoad still wins |
| `PageTabs` | `"Header"` | a tab's page names: `"Header"` (in the middle of the title row, moved aside when the title or the header buttons would be under them; a tab whose names don't fit there keeps the row) or `"Row"` (over the cards); Settings › Window › Page tabs, `Window:SetPageTabs`. With `DockSide = "Side"` Dashboard / Settings have no header buttons (the sidebar lists them), so their pages go up there too |
| `OnePickerOpen` | `true` | opening a colour panel closes the other open one (see [ColorPicker](#colorpicker-gradient-and-swatches)) |
| `Debug` | `false` | a notification for every new error |
| `ConsoleLog` | `true` | `false`: nothing in the Roblox console (the game's scripts can read it); errors still show in Settings › Info and `Window:GetErrors()` |
| `KickLog`, `Rejoin`, `RejoinDelay` | `true`, `false`, `2` | log kicks; rejoin after a kick |
| `Secure` | `false` | [Secure mode](#secure-mode) |
| `Blur`, `BlurSize` | `false`, `12` | blur the game behind the open menu |
| `Scale` | `1` | the whole menu bigger / smaller (0.6 – 1.5); Settings › Behaviour › UI scale offers 80 / 100 / 110 / 120 % |
| `MobileButton` | `"Auto"` | reopen button while the menu is hidden: `"Auto"` = phones / tablets, `true`, `false` |
| `Sounds` | `false` | soft UI clicks (`Lib.Sounds`) |
| `KeySystem` | — | key screen before the window opens ([Key system](#key-system)) |
| `Changelog` | — | "What's new" dialog, shown once per version ([Changelog](#changelog)) |
| `Tour`, `TourDelay` | `false`, `2.5` | first-run guide, once per account: `true` for the built-in steps or your own list ([Tour](#tour)) |
| `OnClose` | — | function that runs when the window is destroyed |

| Method | |
|---|---|
| `Window:Tab({ Title, Icon, Divider, Header, Build })` | adds a tab to the dock (`Build`: see below) |
| `Window:SetUIScale(1.1)`, `:GetUIScale()` | menu size; smaller screens still fit |
| `Window:SetDockSide("Bottom")`, `Window:SetPageTabs("Header")` | dock under / beside the window or a sidebar in it (`"Side"`), page names in the title row / in their own row |
| `Window:SetVisible(bool)`, `:Toggle()`, `:Minimize()` | show, hide, or fold to the title bar |
| `Window:SetToggleKey(key)` | changes the menu key (the badge and Settings update too) |
| `Window:SelectTab(tab or "Title")` | opens a tab |
| `Window:SetFooter(text)`, `:SetStatus(text, color)` | footer texts |
| `Window:SetProfileStatus("live" / "waiting" / "idle")` | the sidebar profile card's avatar dot: green and pulsing / yellow / grey (untouched: green) |
| `Window:Notify(cfg)`, `:Toast(cfg)` | a notification, or a small pill notification |
| `Window:Destroy()` | closes everything (`OnClose` runs) |

## Tabs, pages and cards

```lua
local Visuals    = Window:Tab({ Title = "Visuals", Icon = "eye" })
local Overview   = Visuals:Page("Overview")                -- a page strip appears once a tab has 2+ pages
local Appearance = Visuals:Page("Appearance", { Columns = 1 })

local Left  = Overview:Card({ Title = "General" })          -- cards alternate between the left and right columns
local Right = Overview:Card({ Title = "Colors", Side = "Right", Icon = "palette", Desc = "Card description" })
local Top   = Overview:Card({ Title = "Server", Wide = true })   -- spans both columns, sits at the top
local Under = Overview:Card({ Title = "Notes", Wide = "Bottom" }) -- spans both columns, under them
Overview:MatchHeights(Left, Right)                              -- side-by-side cards as tall as the tallest
Overview:FillColumn(Stats)                                      -- Stats grows until both columns end on one line
Overview:FitHeight(List, Scroller, { Min = 110 })              -- Scroller (directly in List) gets the height that ends both columns on one line
-- With a Wide = "Bottom" card under the columns, the shorter column's last card grows on its own so both columns
-- end on one line (no gap above the bottom card). Tab:Page(name, { Balance = false }) turns it off.
```

**Tabs**
- `Icon` is shown in the dock.
- `Divider = true` puts a line above the tab.
- `Header = true` also shows the tab as a text tab in the header.
- `Tab:Card()` adds a card to the first page without creating one.
- `tab:SetHidden(true)` (or `Window:Tab({ Hidden = true })`) takes the icon out of the dock without leaving a gap; the tab still opens from code (`Select`, `Window:SelectTab`).
- `tab:SetBadge(3)` puts a number on the tab's dock icon (`"NEW"`, `true` for a dot, `0` / `nil` hides it; a second argument picks the colour, e.g. `"danger"`).
- `tab:SetActive(true)` puts a small green dot at the bottom corner of the dock icon, or at the right end of the row in the sidebar (something in this tab is running); `false` hides it.
- `Build = function(tab) ... end`: the tab's content is made later, so a big script starts faster. It builds itself 1.5 s after start (its key binds work without opening it); `BuildDelay = false` waits until the tab is opened. `Window:BuildAll()` builds every lazy tab now.

**Pages**
- `Columns = 1` gives a single column.
- When the window is narrower than 470 px, the two columns stack.
- `Warning = "..."` or `page:Warning("text", { Title, Icon, Level = "warning" | "danger" | "info" })` puts a banner at the top of the page.

**Cards**
- `card:HeaderSwitch({ Title = "Debug", Flag, Default, Callback })` puts a small switch in the card's title row.
- The arrow in the header folds the card. `Collapsible = false` removes the arrow, `Collapsed = true` starts folded, and the folded state is remembered.
- The title starts with an accent dot; `Icon = "name"` puts an icon there instead. `Dot = false` leaves the plain title, and `CreateWindow({ CardDots = false })` does that for every card without an icon.
- Methods: `card:SetCollapsed(bool)`, `card:SetTitle()`, `card:SetDesc()`, `card:SetVisible()`, `card:SetDot("success")` (the title dot in a theme role, e.g. green while what the card controls is running; `SetDot()` gives back the accent).
- A card with nothing visible in it shows "Nothing here" (`Empty = "your text"`, or `Empty = false`).

Layout inside a card:

```lua
local tabs = Card:Tabs({ "Players", "Filters" })          -- capsule switcher in the header, one section each
tabs.Players:Toggle({ Title = "Ignore friends" })

local advanced = Card:Section({ Title = "Advanced", Icon = "settings-2", Opened = false })  -- collapsible section
advanced:Slider({ Title = "Delay", Min = 0, Max = 1, Step = 0.05 })

local row = Card:Row()                                     -- children sit side by side (equal widths, or Widths = { 2, 1 })
row:Button({ Title = "Start", Icon = "play" })
row:Button({ Title = "Stop", Icon = "square" })

local group = Card:Group({ Title = "Server" })             -- boxed group
group:Info({ Title = "Region", Value = "EU" })
```

**Presets.** Chips in the card header that set several flags at once. The chip that matches the current values lights up by itself; once you change something by hand, **Custom** lights up instead. Going from Custom to a preset remembers your values, so clicking Custom brings them back.

<p align="center"><img src="assets/screens/features.png" alt="Card presets, key conflict, input validation and tab badges" width="720"></p>

```lua
local presets = Aim:Presets({
    { "Legit", { fov = 80,  smooth = 0.6, prediction = false } },
    { "Rage",  { fov = 400, smooth = 0,   prediction = true } },
}, { Callback = function(name) print(name) end })   -- Custom = false hides the Custom chip

presets:Select("Rage")    presets:Get()    presets:Add("Off", { fov = 0 })
```

---

## Elements

Each element is a method of a card, or of a Section, Row, Group or Tabs section: `card:Toggle({ ... })`.

**Common options**
- `Title`, `Desc`, `Flag`, `Callback`
- `Icon`: an icon left of the title
- `Help`: a small (i) icon in the row; hovering or tapping it shows this text
- `Risky`: red title; if you pass text, it becomes the (i) hint
- `Tooltip`: text shown next to the mouse after a short hover
- `DependsOn`: follow another flag (see below)
- `Locked`, `LockedTitle`
- `Reset = false`: no reset icon for this element (see [Flags](#flags))
- `Items`: every list an element takes is called `Items` - the choices of a Dropdown, Segment or Radio, the rows of a Table or DiffList, the tiles, gauges, swatches, images, a Changelog's versions - and `:SetItems(list)` replaces it (a Button's split menu: `Menu` / `:SetMenu(list)`)

**Common methods:**

| Method | |
|---|---|
| `:Set(value)`, `:Get()` | the value (Set also runs the callback) |
| `:OnChanged(fn)` | extra listener |
| `:Lock("reason")`, `:Unlock()` | locks the element; the reason replaces the description, or sits over the control with a lock icon if there is no description |
| `:SetTitle(text)`, `:SetDesc(text)`, `:SetVisible(bool)` | |
| `:MoveUp()`, `:MoveDown()`, `:MoveTo(index)`, `:GetIndex()` | position inside the card |
| `:Flash("success" \| "danger" \| "accent")` | a short tint behind the row |
| `:SetTooltip(text)` | |
| `:ResetToDefault()` | puts the starting value back (elements with a Flag) |
| `:Remove()` / `:Destroy()` | removes the element and its flag |

**DependsOn:** an element (or a whole card / section) follows other flags and updates by itself.

```lua
Card:Toggle({ Title = "Prediction", DependsOn = "silentAim" })                     -- locked until silentAim is on
Card:Slider({ Title = "Head offset", DependsOn = { Flag = "aimPart", Value = "Head" } })
Card:Toggle({ Title = "Legit mode", DependsOn = { Flag = "rage", Not = true, Mode = "Hide" } })   -- "Hide" instead of lock
Card:Button({ Title = "Farm", DependsOn = function(flags) return flags.esp and flags.range > 500 end })
Page:Card({ Title = "Rage settings", DependsOn = "rage" })                            -- the card shows only while rage is on
```

The lock reason is written for you ("Turn on Silent Aim first"); `Reason = "..."` sets your own. A lock you put on yourself is kept.

If a callback errors:
- the element flashes red;
- its title reads "Error · see Settings › Info" for 2 seconds;
- the error is listed in Settings › Info;
- the UI keeps working.

### Toggle and Checkbox

```lua
local esp = Card:Toggle({
    Title = "ESP", Desc = "Show player ESP", Flag = "esp", Default = true,
    Bindable = true,                          -- right-click the row to bind a key (Backspace clears, Esc cancels)
    Bind = Enum.KeyCode.F,                    -- starting key
    BindMode = "Toggle",                      -- "Hold": on only while the key is held
    Marker = true, Badge = "NEW",             -- accent bar on the left, chip after the title
    Callback = function(on) end,
})
esp:SetBind(Enum.KeyCode.G)

Card:Checkbox({ Title = "Visible only", Flag = "visibleOnly", Default = false, Callback = function(on) end })  -- a plain tick box
```

### Slider and Range

```lua
Card:Slider({
    Title = "FOV", Flag = "fov", Min = 10, Max = 600, Default = 120, Step = 1, Suffix = "px",
    Icons = { From = "minus", To = "plus" },  -- icons at the ends; a click moves one step
    Bubble = true,                            -- value bubble while dragging
    Callback = function(value, dragging)      -- dragging: true while held, then false once with the final value
        if not dragging then rebuildCircle(value) end
    end,
})
Card:Range({ Title = "Health filter", Flag = "hp", Min = 0, Max = 100, Default = { 20, 80 }, MinGap = 5 })  -- value is { low, high }
```

Click the value to type a number. `slider:SetRange(min, max)`.

```lua
Card:Stepper({ Title = "Clicks per second", Flag = "cps", Min = 1, Max = 20, Step = 1, Default = 8, Suffix = "" })
```

`[-] 8 [+]`: exact numbers without a slider. Hold a button to repeat (it speeds up); click the number to type one.

### Dropdown, Segment and Radio

```lua
Card:Dropdown({ Title = "Font", Flag = "font", Items = { "Gotham", "Code", "Arcade" }, Default = "Gotham" })

Card:Dropdown({ Title = "Show", Flag = "parts", Multi = true, Items = { "Name", "Health", "Distance" }, Default = { "Name" } })
-- (a multi box shows as many names as fit, then "+N": "Name, Health +2")

Card:Dropdown({ Title = "Target", Flag = "priority", AllowNone = true, Items = {
    { Title = "Closest",   Icon = "footprints", Desc = "Nearest to you" },
    { Title = "Crosshair", Icon = "crosshair" },
    { Title = "Bounty",    Icon = "gem", Locked = true },
} })

Card:Dropdown({ Title = "Mode", Items = { pvp = "PvP mode", farm = "Auto farm" } })   -- the value is the key ("pvp")

Card:Segment({ Title = "Aim part", Flag = "aimPart", Items = { "Head", "Body", "Closest" }, Default = "Head" })
-- Style (or CreateWindow({ SegmentStyle })): "Boxed" a framed button each · "Tab" words over a faint line, a short
-- line slides under the chosen one · "Underline" / "Line" / "Dot" / "Divided" / "Ghost" lighter word styles ·
-- "Track" one track with a sliding thumb · "Pills" / "Capsule" pills as wide as their word

Card:Radio({ Title = "Priority", Flag = "priority", Items = {         -- every option visible, one chosen
    "Closest",
    { Title = "Lowest HP", Value = "hp", Desc = "Finish weak targets" },
    { Title = "Bounty", Locked = true },
} })
```

- Lists with more than 8 options get a search box (`Search = true/false`).
- Thousands of options stay fast: the list is drawn in chunks.
- In multi lists you can drag over options to select them (`DragSelect = false` turns it off).
- `:SetItems(list, keepValue)` (`:Refresh(list)` is the same, keeping the value), `:GetLabel()`.
- An option table can carry `Font = family` (e.g. `"rbxassetid://12187365364"`): that option is drawn in that font.

### Keybind

```lua
Card:Keybind({ Title = "Aim key", Flag = "aimKey", Default = Enum.KeyCode.Q, Pressed = function(key) end })

Card:Keybind({ Title = "Mark", Chord = true,               -- modifier + key or mouse button (CTRL + M1)
    Default = { Enum.KeyCode.LeftControl, Enum.UserInputType.MouseButton1 } })

Card:Keybind({ Title = "Hold to aim", Default = Enum.KeyCode.E, Mode = "Hold",
    Pressed = function(down) aiming = down end })          -- true on press, false on release
```

Click the badge, then press a key (Backspace clears, Esc cancels). `Callback` runs when the key changes. `Pressed` runs on every press.

**Key conflicts.** When two binds (toggles, buttons, keybinds, key hints) use the same key, or one uses the menu key, their key tags turn yellow and hovering one says what else uses the key. A conflict made after the start also shows a notification. `Window:GetKeyConflicts()` returns `{ [key] = { titles } }`.

### ColorPicker, Gradient and Swatches

```lua
Card:ColorPicker({ Title = "Fill", Flag = "fill", Default = Color3.fromRGB(215, 120, 120),
    Rainbow = false, RainbowSpeed = 5,       -- there is also a Rainbow button inside
    Apply = false,                           -- true: changes only apply when Apply is pressed
    Alpha = true, Transparency = 0.3,        -- transparency bar
    Callback = function(color, transparency) end })

Card:Gradient({ Title = "Chams", Flag = "chams", Default = { Color3.new(1, 0, 0), Color3.new(0, 0, 1) },
    Callback = function(sequence, a, b) end })   -- :GetSequence()

Card:Swatches({ Title = "Name color", Flag = "nameColor", Default = "Blue",
    Callback = function(color, name) end })      -- without Items = { { "Blue", Color3 }, ... } it uses 8 presets
Card:Swatches({ Title = "Accent", Style = "Dots", Custom = function(open) end })   -- one row of round dots, the last for "any colour"
```

The picker has a saturation square, a hue bar, a transparency bar (with `Alpha`), R / G / B fields (0-255), a HEX box and Random · Rainbow · Done. It also accepts `"RRGGBB"` strings.

Only one colour panel is open at a time: opening a picker or gradient closes the one that was open (a gradient's own Start / End pickers open inside it). `picker:SetOpen(true)` opens one from code. `CreateWindow({ OnePickerOpen = false })` lets several stay open.

### Input, TextArea and ActionInput

```lua
Card:Input({ Title = "Target", Flag = "target", Placeholder = "player name", Numeric = false,
    Finished = true,                          -- false: the callback runs on every keystroke
    Callback = function(text) end })

Card:Input({ Title = "Job ID", Flag = "job", Placeholder = "paste id",
    Validate = function(text)                 -- checked while typing: true = green edge, false = red edge + message
        if text == "" then return nil end
        return #text >= 8, #text >= 8 and "Looks good" or "At least 8 characters"
    end })                                    -- a wrong value is not taken: the flag keeps the last good one

Card:TextArea({ Title = "Auto chat message", Flag = "chat", Placeholder = "gg", Height = 80, MaxLength = 200,
    Callback = function(text) end })         -- multi-line; a "12 / 200" counter with MaxLength

Card:ActionInput({ Icon = "plus", Placeholder = "Profile name", Button = "Create",
    Validate = function(text)                 -- live hint: ok = green, false = red
        if text == "" then return nil end
        return #text <= 20, #text <= 20 and "Looks good" or "Too long"
    end,
    Callback = function(text) end })          -- on the button or Enter
```

`input:SetPlaceholder(text)` changes the grey hint of an Input. `actionInput:Run()` presses an ActionInput's button from code.

### Button

<p align="center"><img src="assets/screens/buttons.png" alt="Button styles, sizes and rows" width="720"></p>

```lua
Card:Button({ Title = "Rejoin", Icon = "refresh-cw", Callback = function() end })
Card:Button({ Title = "Server hop", Confirm = true, Callback = hop })        -- asks for a second click within 2 s
Card:Button({ Title = "Delete all", Risky = true, Confirm = "Sure?", Callback = wipe })
```

**Styles.** `Style` picks the look. Every style follows the theme and the accent colour.

| Style | Look | Good for |
| --- | --- | --- |
| `Default` | Filled box with an outline (the standard button) | Most actions |
| `Primary` | Solid accent colour | The main action of a card |
| `Soft` | Light accent tint | Secondary actions that should still stand out |
| `Outline` | Only the outline, fills on hover | Quiet actions next to a Primary one |
| `Ghost` | No box until you hover it | Reset, cancel, small extras |
| `Danger` | Red tint | Delete, wipe, leave |
| `Link` | Accent text only | Links, "open Discord" |

```lua
Card:Button({ Title = "Start farm", Icon = "play", Style = "Primary" })
Card:Button({ Title = "Redeem codes", Icon = "sparkles", Style = "Soft" })
Card:Button({ Title = "Reset to default", Icon = "rotate-ccw", Style = "Ghost" })
Card:Button({ Title = "Delete profile", Icon = "trash-2", Style = "Danger", Confirm = "Sure?" })
```

**Size, icon and alignment.**

```lua
Card:Button({ Title = "Small", Size = "Small" })                              -- "Small" (22 px), "Default" (28 px), "Large" (34 px)
Card:Button({ Title = "Next step", Icon = "arrow-right", IconSide = "Right" }) -- icon after the text
Card:Button({ Title = "Teleport to spawn", Icon = "map-pin", Align = "Left" }) -- icon and text on the left
Card:Button({ Icon = "trash-2", Style = "Danger" })                            -- no Title: icon-only button
```

**Side by side.** Put buttons in a `Row` and they share the width. `Widths` sets the share of each one, in order.

```lua
local row = Card:Row()                                      -- equal widths
row:Button({ Title = "Rejoin", Icon = "refresh-cw" })
row:Button({ Title = "Server hop", Icon = "shuffle" })

local save = Card:Row({ Widths = { 3, 1 } })                 -- 3/4 and 1/4
save:Button({ Title = "Save config", Icon = "save", Style = "Primary" })
save:Button({ Icon = "trash-2", Style = "Danger" })

local player = Card:Row({ Gap = 4 })                         -- a strip of icon buttons
for _, icon in ipairs({ "play", "pause", "square", "skip-forward" }) do player:Button({ Icon = icon, Style = "Soft" }) end
```

**Smart buttons.**

<p align="center"><img src="assets/screens/smart.png" alt="Cooldown, hold, loading, key, toggle, menu and badge buttons; reset to default" width="720"></p>

| Option | What it does |
| --- | --- |
| `Cooldown = 5` | After a run the button empties over 5 seconds, shows the time left and ignores clicks until it is ready. |
| `Hold = 1.5` | Hold the button (or its key) until it fills up. Letting go early cancels. A nicer guard than `Confirm` for risky actions. |
| Loading | A callback that waits (`task.wait`, `HttpGet`...) shows a spinner and blocks clicks until it returns, then a short tick. `LoadingText = "Redeeming..."` changes the text meanwhile, `Loading = false` turns it off, `Done = false` skips the tick. |
| `Bind = Enum.KeyCode.R` | The key presses the button; a small key cap shows it. With `Bindable = true` right-click the button to set the key (Backspace clears it). |
| `Toggle = true` | An on / off button. `Callback(value)`, `Flag` keeps it. When on it uses `OnStyle` (default `"Primary"`), `OnTitle` and `OnIcon`. |
| `Menu = { ... }` | A split button. The arrow opens the list; a pick runs `Callback(option)`, and the main part runs it again with the same choice later. |
| `Badge = 3` / `"NEW"` | A small tag on the corner. `0`, `nil` or `""` hides it. |

```lua
Card:Button({ Title = "Server hop", Icon = "shuffle", Cooldown = 5, Callback = hop })
Card:Button({ Title = "Hold to wipe data", Icon = "trash-2", Style = "Danger", Hold = 1.5, Callback = wipe })
Card:Button({ Title = "Redeem all codes", Icon = "gift", LoadingText = "Redeeming...", Callback = function()
    for _, code in ipairs(codes) do redeem(code) task.wait(1) end   -- the spinner shows until this returns
end })
Card:Button({ Title = "Rejoin", Icon = "refresh-cw", Bind = Enum.KeyCode.R, Bindable = true, Callback = rejoin })
Card:Button({ Title = "Auto farm", Icon = "sprout", Toggle = true, Flag = "autoFarm", OnTitle = "Farming", Callback = function(on) end })
Card:Button({ Title = "Teleport", Icon = "map-pin", Menu = { "Spawn", { Title = "Shop", Icon = "store" }, "Arena" },
    Callback = function(place) teleportTo(place) end })
local inbox = Card:Button({ Icon = "inbox", Style = "Soft", Badge = 3 })
inbox:SetBadge("NEW")
```

Methods: `button:SetStyle("Primary")`, `button:SetTitle(text)`, `button:SetIcon(name)`, `button:Fire()`,
`button:SetLoading(true, "Saving...")`, `button:SetCooldown(seconds)`, `button:ResetCooldown()`, `button:SetBind(key)`,
`button:SetBadge(text)`, `button:Set(on)` / `button:Get()` (Toggle), `button:Select(option)` / `button:SetMenu(list)` (Menu).
Fields: `button.Value`, `button.Selected`, `button.Loading`, `button.CoolingDown`.

### Text: Label, Paragraph, Info, Divider and Code

```lua
Card:Label("A short line of text")
Card:Paragraph({ Title = "About", Content = "Longer text that wraps over as many lines as it needs." })
Card:Info({ Title = "User ID", Value = "#123", Copy = true })   -- a "name ...... value" row with a Copy button
Card:Divider()
Card:Code({ Title = "loader.lua", Code = 'print("hi")', Copy = true, MaxHeight = 200 })   -- Lua highlighting
-- (CopyText = false: the Copy button is just the copy icon; CopyIcon = false: just the word)
-- (CopyValue = function() return text end: what Copy copies; Actions = { { Icon, Tooltip, Callback, Danger } }: more header icons)
```

### Live data: Progress, Stat, Graph, Console and Table

```lua
local farm  = Card:Progress({ Title = "Auto farm", Value = 3, Max = 10, Suffix = "quests" })
local daily = Card:Progress({ Title = "Daily quests", Steps = 5, Value = 2 })     -- bar in 5 segments
local load  = Card:Progress({ Title = "Loading", Indeterminate = true })          -- moving stripe
farm:Set(4)  load:SetIndeterminate(false)

local coins = Card:Stat({ Title = "Coins", Icon = "coins", Value = 12450, Prefix = "$" })
local ping  = Card:Stat({ Title = "Ping", Value = 48, Suffix = " ms", Delta = "absolute", Invert = true })
coins:Add(250)     -- digits roll like an odometer, with a "+2.0%" chip

Card:Graph({ Title = "FPS", Source = "FPS", Max = 60 })     -- bars; Source = "Ping", or function() return n end
Card:Graph({ Title = "Network", Style = "Line", Series = {   -- lines, several in one chart with a legend
    { Name = "FPS", Source = "FPS" },
    { Name = "Ping", Source = "Ping", Color = "warning" },
} })
local tiles = Card:Row()                                   -- stat tiles: small title, big number, a small graph under it
tiles:Graph({ Title = "FPS", Style = "Line", Source = "FPS", Compact = true, Height = 34 })
tiles:Graph({ Title = "PING", Style = "Line", Source = "Ping", Compact = true, Height = 34, Color = "warning" })

local log = Card:Console({ Title = "Log", Height = 140, MaxLines = 200 })
log:Append("Loaded", "success")        -- "info" | "success" | "warning" | "error"
log:Print("Sold", 3, "items")
log:Log("Same as Append", "info")      -- (another name for Append)

local board = Card:Table({ Title = "Top players", Height = 160, Search = true,
    Columns = { "Name", { Title = "Kills", Align = "Right", Width = 0.25 }, "Team" },
    Items = { { "Nova", 31, "Red" }, { "Kite", 24, "Blue" } },
    SortBy = "Kills", Descending = true,
    OnRowClick = function(row, index) print(row[1]) end })
board:AddRow({ "Ash", 12, "Red" })
```

**Stat options**
- `Delta = "percent" | "absolute" | false`
- `Invert = true` counts a lower value as good (green)
- `Decimals`, `Separator`, `Format`

**Console**
- Scrolling up pauses follow; scrolling back to the bottom resumes it.
- The header has Follow, Clear and Copy buttons.
- Methods: `:Clear()`, `:GetText()`, `:SetFollow(bool)`.

**Table**
- Click a column header to sort, click again to flip; numbers sort as numbers, empty cells go last.
- Methods: `:SetItems(rows)`, `:AddRow(row)`, `:UpdateRow(i, row)`, `:RemoveRow(i)`, `:Clear()`, `:Sort(column, descending)`, `:GetItems()`.

### Visual: Image, ImagePicker, PlayerList and Viewport

```lua
Card:Image({ Image = "rbxassetid://123", Height = 120, Caption = "Preview" })   -- icon names and web images work too
Card:ImagePicker({ Title = "Crosshair", Flag = "cross", Columns = 4, Items = { "crosshair", "rbxassetid://9943168532" } })
Card:PlayerList({ Title = "Whitelist", Flag = "whitelist", Multi = true, Height = 150,
    Callback = function(userIds) end })          -- search; updates as players join and leave; :GetPlayers()
Card:Viewport({ Object = game.Players.LocalPlayer.Character, Height = 150, Spin = true })   -- drag to rotate, wheel to zoom
-- view.Model is the clone on show, view.Camera / view.View its camera and ViewportFrame
```

### Crosshair and FOV preview

```lua
-- a crosshair drawn on screen at the mouse: Plus, Plus + Dot, X, Dot, Circle, Circle + Dot (Lib.Crosshair.Styles)
local crosshair = Lib.Crosshair.Overlay({ Enabled = true, Style = "X", Color = Color3.new(1, 1, 1), Opacity = 100,
    Outline = true, Length = 8, Thickness = 2, Gap = 4, Spin = false, SpinSpeed = 120 })
crosshair:Update({ Style = "Circle + Dot" })     -- only the given settings change; :SetEnabled(bool), :Destroy()

local preview = Card:CrosshairPreview({ Height = 110 })          -- the same settings at 2x, the style in the corner
preview:Update({ Style = "X", Spin = true })                      -- turns while it is in view

local fov = Card:FovPreview()                                     -- the FOV round the cursor at its real size
fov:Update({ Radius = 140, Sides = 6, Thickness = 1, Color = Color3.new(1, 1, 1), Transparency = 0,
    Filled = true, FillColor = Color3.new(1, 1, 1), FillTransparency = 0.85, Visible = true })
-- "60 px · real size" (or "· shown at 40 %" when shrunk to fit) in the corner; under 16 sides the circle is drawn as the polygon it is
```

### Dashboard and settings blocks

Bigger building blocks for dashboards, info and settings pages. `test/widgets_demo.lua` uses every one of them (`test/widgets.sh` renders it).

**Header controls, sections, inline sliders**
```lua
Card:HeaderSwitch({ Flag = "dash", Callback = fn })              -- on / off switch in the card title row
Card:HeaderButton({ Title = "Claim all", Icon = "gift", Callback = fn })
Card:Divider({ Title = "Defense" })                               -- a section label inside a card
local row = Card:Row({ Gap = 10 })                                -- two columns side by side
local left, right = row:Column(), row:Column()                    -- plain stacks; compact follows the card
Card:Toggle({ Title = "Stop at spins", Flag = "stop", Slider = { Flag = "stopAt", Min = 50, Max = 1000, Default = 500 } })
Card:Segment({ Title = "Target part", Items = { "Head", "Torso" }, Wide = true })   -- buttons fill the row, no title
tiles:SetTileVisible("Back", false)                               -- Tiles: hide one tile, the rest close up
```

**Item list and canvas**
```lua
local list = Card:ItemList({ Items = { { Title = "Kage Office", Desc = "312 studs", Icon = "map-pin" } }, Button = "Go", Rows = 4,
    Placeholder = "Search places", Callback = function(item) print(item.Title) end })
list:SetDesc("Kage Office", "280 studs")       -- one row's muted line; :SetItems(items) replaces the list, :SetFilter(text)
local canvas = Card:Canvas({ Height = 80 })    -- canvas.Frame: an empty rounded frame for your own drawing
```
ItemList shows a search box and at most `Rows` rows (36 px each); longer lists scroll inside the card.

**Compact cards**
```lua
Window:Tab({ Title = "Combat", Icon = "crosshair", Compact = true })   -- every page of the tab
Tab:Page("Movement", { Compact = true })                               -- one page
Page:Card({ Title = "FOV", Compact = false })                          -- a card can opt out (or in)
Window:SettingsTab({ Compact = true })
Window:SettingsTab({ Icon = false })   -- no icon in the sidebar (like tabs made without one)
Window:SettingsTab({ Simple = true })   -- a small script: all four pages, Interface with the everyday settings only (Appearance with Theme | Text tabs, a compact Menu card with Behaviour | Window tabs, no dock choice) (theme, font, text size, menu key, scale, free mouse, anonymous, reset layout / unload, transparency, dock, blur)
```
Compact cards have tighter padding, a line under the title, 6 px shorter rows, slimmer buttons and sliders, and a check box in place of each toggle's switch (same element, same flag).

**Numbers and health**
```lua
local tiles = Card:StatTiles({ Columns = 4, Items = {
    { Title = "FPS", Source = "FPS" },                                  -- live, "avg ..." under it
    { Title = "Ping", Source = "Ping", Suffix = " ms", Color = "warning" },
    { Title = "Memory", Value = "26 MB", Sub = "Lua", History = { 20, 22, 26 }, Color = Color3.fromRGB(180, 140, 232) },
} })
tiles:Set("Memory", { Value = "30 MB" }) tiles:Push("Memory", 30)    -- by title or index
-- history is drawn as 12 grey bars (newest on the right); Bars = 20 for more, Style = "Line" for a line sparkline

local gauges = Card:Gauges({ Items = { { Title = "FPS", Source = "FPS", Max = 60 }, { Title = "Ping", Value = 40, Max = 150, Sub = "ms", Color = "warning" } } })
gauges:Set("Ping", 55)                                                 -- a ring of dots fills to Value / Max

local hero = Card:Hero({ Title = "Tester", Desc = "@Tester", UserId = player.UserId, Label = "SESSION", Value = "00:00:00",
    Chips = { { "60 FPS", "activity" }, { "40 ms", "wifi" } } })      -- :SetValue, :SetChips, :SetOnline
Card:StatusBars({ Slots = 30, Items = { { Title = "ESP", State = "on" }, { Title = "Misc", State = "limited" } } })   -- :Push(title, state)
Card:Checklist({ Items = { { Title = "File access", Ok = true, Note = "profiles" }, { Title = "getconnections", Ok = false } } })
Card:Notice({ Kind = "success", Title = "Everything is running", Desc = "1 module limited", Button = { Title = "Copy", Icon = "copy", Callback = fn } })
```
States everywhere: `"on"` / `"ok"` green, `"limited"` / `"warning"` amber, `"error"` red, `"off"` grey. Colours: a theme role (`"warning"`) or a `Color3`.

**Switches**
```lua
local mods = Card:SwitchGrid({ Columns = 2, Items = {                   -- boxed rows, each its own saved toggle
    { Title = "ESP", Icon = "eye", Flag = "esp", Default = true, Callback = fn },
    { Title = "Misc", Icon = "box", Status = "Limited" },                -- a chip instead of a switch (:SetStatus)
} })
mods.Items.ESP:Set(false)
Card:Tiles({ Columns = 4, Items = {                                     -- square tiles
    { Title = "Free mouse", Icon = "mouse-pointer", Flag = "freeMouse" },   -- toggle tile (On / Off)
    { Title = "ESP", Icon = "eye", State = "on" },                          -- status tile (:SetState)
    { Title = "Rejoin", Icon = "rotate-ccw", Callback = fn },               -- button tile
} })
Card:Chips({ Flag = "quick", Items = { { Title = "ESP", Icon = "eye" }, "Camera" }, Multi = true, Default = { "ESP" } })
Card:Chips({ Static = true, Items = { { Title = "Hit 100%", Icon = "crosshair" } } })   -- only shows values (:SetItems)
```

**Activity**
```lua
local feed = Card:Timeline({ Max = 50, Filters = { "All", "Modules", "Combat" } })   -- Compact = true: one line each
feed:Add({ Title = "Click TP", Desc = "212 studs", Icon = "navigation", Kind = "success", Tag = "Combat" })
Card:Changelog({ Items = { { Version = "1.10", Time = "now", Items = { "New blocks" } } } })   -- click a version to open it
```

**Settings pages**
```lua
Page:Card({ Wide = true }):Search({ Placeholder = "Search settings…" })    -- filters this page as you type
Card:ListItem({ Title = "Theme", Icon = "palette", Value = "Dark", Callback = fn })          -- link row with a chevron
Card:ListItem({ Title = "Free mouse", Icon = "mouse-pointer", Toggle = true, Flag = "free" })  -- or a switch
Card:Row():ListItem({ ... })                    -- two to a row: put them in a Row (Badge = "NEW", Risky = true as on a Toggle)
Card:Gallery({ Flag = "theme", Default = "Dark", Items = {
    { Name = "Dark", Colors = { background, card, accent } },          -- a theme thumbnail
    { Name = "Gotham", Font = Enum.Font.Gotham },                       -- an "Aa" font sample
} })
Card:ThemePreview({ Caption = "Gotham · Normal" })                     -- a tiny window in the live theme colours
Card:ThemeGallery({ Flag = "theme", Default = "Ash", New = fn })   -- the theme packs as small windows in their own colours (value: pack name)
local nav = Card:SideNav({ Items = { { "Appearance", "palette" }, { "Behaviour", "sliders-horizontal" } },
    Footer = function(part) part:Button({ Title = "Unload" }) end })
nav:Section("Appearance"):Toggle({ Title = "Text glow" })              -- each menu item has its own part
```

**Lists of things**
```lua
Card:ItemCards({ Columns = 2, AddNew = "New profile", OnAction = function(item) end, OnMenu = fn, OnAdd = fn, Items = {
    { Title = "Default", Sub = "now · 46 settings", Desc = "Active", Color = Color3.fromRGB(232, 232, 236),
      Badges = { { Text = "ACTIVE", Role = "success" }, "AUTO" }, Action = "Save", Highlight = true },
} })
Card:DiffList({ OnRevert = function(row) end, Items = { { Tag = "ESP", Title = "Max distance", Old = "1000", New = "1500" } } })
```

---

## Flags

Elements with a `Flag` are saved in profiles, and you can read their values:

```lua
print(Lib.Flags.esp)                -- flags of every window
print(Window.Flags.esp)             -- the same value
Window.Flags.range = 2000           -- updates the element and runs its callback
for flag, value in Window.Flags do print(flag, value) end

Window:SetFlag("esp", false)        -- if the element doesn't exist yet, the value is applied when it's created
Window:GetElement("esp"):Lock("Premium only")    -- (Window:GetFlag("esp") is the same element, from the library's flag list)
```

With `CreateWindow({ AutoFlags = true })`, value elements without a Flag get one named `"Tab.Card.Title"`. If two elements end up with the same name, the second gets `" 2"`. Settings and Dashboard elements don't get auto flags.

**Reset to default.** When an element with a Flag is changed from its default, a small reset icon shows after its title. Clicking it puts the default back (and runs the callback). It hides again once the value is back at the default.

```lua
Card:Slider({ Title = "Walk speed", Flag = "walk", Min = 16, Max = 100, Default = 16 })   -- shows the reset icon at 42, not at 16
Card:Toggle({ Title = "Silent", Flag = "silent", Reset = false })                         -- no reset icon for this one
Window:GetElement("walk"):ResetToDefault()                                                 -- the same from code
Lib:CreateWindow({ Title = "Hub", ResetButtons = false })                                 -- no reset icons anywhere
card:Toggle({ Title = "Fly", Flag = "fly", Reset = true })                                    -- with ResetButtons = false: this one still gets one
```

---

## Notifications

```lua
Window:Notify({ Title = "Saved", Content = "pvp profile", Icon = "circle-check", Color = "success" })

Window:Notify({ Title = "Profile deleted", Buttons = {
    { Title = "Undo", Callback = undo },
    { Title = "Close" },
} })

local t = Window:Notify({ Title = "Farming", Steps = 5, Content = "Starting" })
t:SetStep(2, "Quest 2")             -- closes itself at the end
```

| Option | |
|---|---|
| `Duration` | without it, 3–10 s depending on the text length; hovering pauses the timer (`PauseOnHover = false`) |
| `Color` | a `Color3` or a role: `"success"`, `"warning"`, `"danger"` |
| `Icon`, `Buttons`, `CanClose` | icon, a row of buttons, X in the corner |
| `Actions` | `{ { Icon = "copy", Tooltip, Callback } }`: small icons left of the X; a click turns the icon into a tick (a cross when the callback returns `false`), the notification stays |
| `Progress`, `Steps`, `Step`, `Persist` | progress notification (`:SetProgress`, `:SetStep`, `:Close`) |
| `Sound`, `Volume` | `true` (a short ping) or a sound id |
| `History` | `false`: kept out of the bell history |

At most `Lib.MaxNotifications` (6) notifications stay on screen, fewer when the screen is short; a new one closes the oldest. The same notification again while it is open counts up ("×3") and restarts its time instead of stacking (`Merge = false` turns it off). The bell in the header keeps the last 50.

**Toast:** a small pill at the top centre of the screen.

```lua
Window:Toast("Copied")
Window:Toast({ Text = "Saved", Icon = "check", Color = "success", Position = "Bottom", Duration = 2 })
```

## Dialogs

```lua
Window:Dialog({ Title = "Enable Silent Aim?", Content = "Can be detected in ranked servers.", Icon = "triangle-alert", Buttons = {
    { Title = "Cancel" },
    { Title = "Enable", Style = "Danger", Callback = function() end },
} })

Window:Confirm("Unload?", "Everything will be removed.", function() Window:Destroy() end, "Unload", true)

-- a text box: each button's Callback gets its text (Enter presses the last button)
Window:Dialog({ Title = "Rename", Input = { Text = "pvp", Placeholder = "New name" }, Buttons = {
    { Title = "Cancel" },
    { Title = "Rename", Style = "Primary", Callback = function(text) end },
} })

-- a context menu at the pointer (e.g. from a row's MouseButton2Click)
Window:Menu({ Owner = row, Items = {
    { Title = "Rename", Icon = "pencil", Callback = function() end },
    { Title = "Delete", Icon = "trash-2", Style = "Danger", Callback = function() end },
} })
```

The menu behind a dialog is dimmed and blocked. Escape or a click on the dimmed area cancels it. Escape also closes an open dropdown list or colour panel.

A context menu stays inside the screen. A click outside it, Escape or another menu closes it.

---

## Configs and profiles

Every element with a Flag is saved to `<Folder>/configs/<name>.json`.

```lua
local Config = Window.Config
Config:Save("pvp")    Config:Load("pvp")    Config:Delete("pvp")
Config:List()         Config:Exists("pvp")  Config:Rename("pvp", "ranked")   Config:Copy("pvp", "pvp 2")
Config:SetAutoLoad("pvp")    Config:LoadAutoLoad()

Config.Active                       -- the loaded profile
Config:Changes()                    -- how many settings changed since that profile
Config:Export("pvp")                -- "QUSTAH1:..." share code
Config:Decode(code)                 -- name, flags

Config:SetData("waypoints", list)   -- your own data, saved and shared with the profile
Config:OnDataLoaded(function(data) end)
```

- **Early loading:** you can call `LoadAutoLoad` before elements exist. Each value is applied when its element is created.
- **Crash-safe saves:**
  - every file is written to a `.tmp.txt` copy first and checked (where the executor refuses that, straight to the file);
  - if the game closes mid-save, the profile isn't damaged;
  - on the next start the profile is restored from that copy (`Config:OnRecovered(fn)`).

The Settings › Profiles page does all of this in the UI:
- shows the active profile and how many settings changed (click it to see which);
- Save and Revert;
- a table of profiles: Name, Note, Saved, Settings, Differs (how many settings it would change), Auto (loads on start), Load, and share / duplicate / delete icons; click a column title to sort;
- right click a row (long press on touch): Overwrite, Rename, Edit note, Duplicate, Share code, Delete;
- search, create and import with share codes;
- ACTIVE / LOCKED tags.

The locked **Default** profile holds the values the script started with.

## Built-in tabs

```lua
Window:DashboardTab({ Info = { { "Code revision", "571" } }, Server = true })   -- as the first tab
-- ... your tabs ...
Window:SettingsTab()                                                             -- as the last tab
```

**Dashboard:** (Session and Modules side by side are always the same height) profile card (a Hero: avatar, name, session time and live FPS / ping / players chips), live tiles under it (StatTiles: FPS, ping, players and Lua memory with their history; `Stats = false` leaves them out), Session (account, executor, version and your `Info` rows; User ID / Game ID / Place ID with copy buttons), Modules (a grid of tiles: icon, name and the state under it in its colour), Server (Rejoin, Server hop, Job ID).

**Settings › Interface**
- Theme: the theme packs as small windows drawn in their own colours (ThemeGallery; New opens the editor), the accent dots under an "Accent" label (the last one opens a picker for any colour), Edit colours (the theme editor, folded)
- Text: font, text size, text glow
- Behaviour: menu key, UI scale, free mouse, anonymous mode, UI sounds, haptics (touch devices), mobile button, welcome toast, Reset layout, Unload, Reset interface (only the look goes back to its defaults)
- Window › Look / Background / Overlays: transparency, dock side, page tabs, edge glow, blur · background image (and its visibility once one is set), animated background · watermark, keybind list, session bar, performance monitor

**Settings › Profiles:** one full-width card: the active profile with Revert / Save, a sortable table of the profiles (Note, Saved, Settings, Differs, Auto, Load, share / duplicate / delete), a right-click menu on each row, and New profile / Import share code under it. See [Configs and profiles](#configs-and-profiles).

**Settings › Keys:** every key the menu listens to (switch / button binds, keybinds, key hints, the menu key) with the setting and where it is; a key used twice is red with a `!`, and a click on a row opens that setting.

**Settings › Info:** Modules (each module's state over the last 15 minutes) and Executor (which functions it has and what they are needed for) on the left, Errors (a Debug switch in the card's title, the last errors with a copy icon for the debug info and a bin that clears them), "What's new" and This session (uptime, your `Window:Count` counters, Lua memory) on the right. With `Info` rows, `Links` or `Tour` an About card holds them.

## Overlays

Overlays stay on screen while the menu is closed. They can be dragged and their positions are remembered. You can also turn them on in Settings › Interface › Window › Overlays.

```lua
Window:Watermark(true, { Text = "extra" })     -- "Qustāh  V1.00 | 60 FPS | 40 ms | 22:10"
Window:KeybindList(true)                       -- bound keys; click a row to press it, use the eye to hide rows
Window:SessionBar(true)                        -- FPS · ping · players · time
Window:StatsMonitor("Header" | "Floating" | "Off")

Window:KeyHint({ Title = "ESP / SILENT AIM", Key = Enum.KeyCode.KeypadEight, Side = "Left",
    Pressed = function() end })                -- key badge in the footer bar; click it to rebind
```

---

## Themes

There are 9 built-in themes (`CreateWindow({ Theme = "Forest" })`, Settings › Interface › Theme):
- **Ash** (default): grey, white accent
- **Charcoal**: dark grey, neutral accent
- **Onyx**: near black, white accent
- **Charcoal Rose**: Charcoal with a rose accent (the selected sidebar row stays grey)
- **Ice**: near black with an ice blue accent (the selected sidebar row stays grey)
- **Forest**: soft dark green, mint accent
- **Wine**: soft red-brown, pink accent
- **Peach**: charcoal-brown, peach accent
- **Rust**: burnt brown, copper accent

The "live" dots (footer Connected, a tab's active dot, the profile dot) take the theme's accent; when the accent is a grey they stay green. Their role is `live`.

A theme can bring more than colours: `Theme.packs[name].extras` (`alpha` per colour role, `blur = true`, `plainSelection = true`).
`Lib.Theme.extras` is the current set; `Lib.Theme.onExtras(fn)` runs when it changes.

Accent presets (Settings › Interface › Theme): Neutral, Blue, Crimson, Violet, Mint, Gold.

Every theme passes an automatic contrast check: 4.5:1 for text, 3:1 for muted text. On light themes, pale accent colours are darkened until they are readable.

```lua
Lib.Theme.applyPack("Forest")
Lib:SetAccent(Color3.fromRGB(124, 156, 255))
Lib:SetColor("card", Color3.fromRGB(20, 20, 24))    -- base, card, input, line, text, muted, heading, accent, dock, icon...
```

The theme editor in Settings lets you:
- change each colour;
- save the result under a name;
- share or import it with a `QTHEME1:` code.

Fonts (Settings › Interface › Text): **Jura** (the default, Large text), **Ubuntu**, **Roboto**, **Michroma** (wide, for a techy look) and **Josefin Sans**. Picking one also picks the text size that suits it (Jura Large, Josefin Sans Small, the rest Normal: `Lib.Fonts.DefaultSize`); the size can be changed after, and a loaded profile keeps its own.

They are Roblox's own font families (`Lib.Fonts.Families`, through `Font.fromName`), so nothing is downloaded and every executor shows them.

In the font list every name is drawn in its own font. Code, Console and Log text use Roblox's monospace RobotoMono, or another `Enum.Font` with `CreateWindow({ CodeFont = "Code" })`.

**Text size** (Settings › Interface): Small, Normal or Large makes every text about 10 % smaller or larger while the menu keeps its size. Small print (9 px and under) stays as it is; in Large a long value in a narrow box can end in "…".

`Lib.Fonts.set("Ubuntu")`, `Lib.Fonts.setCode("RobotoMono")` and `Lib.Fonts.setTextScale(1.1)` do the same from code. `CreateWindow({ Font = "Jura" })` starts with a font (and its text size); `Font = { "Jura", "Roboto" }` starts with the first known one.

**Readable small text.** Elements are written with small sizes; each is drawn a step bigger (8 and 9 -> 10, 10 -> 11, 11 -> 12, 12 -> 13, then the text size setting), and text drawn at 11 px or less is at least Medium so thin strokes don't fade. `Lib.Fonts.Readable` and `Lib.Fonts.MediumBelow` hold the table and the limit; text marked `QNoScale` keeps its size.

**Profile files.** A profile keeps only the settings that differ from the defaults, named in words (`"ui accent"`, `"sa enabled"`) and written as indented JSON. Loading one puts every setting it doesn't list back to its default; files with every setting or the old names load the same way.

**Text widths follow the font.** `Lib.Util.textWidth(text, size, font)` adds up the chosen font's own character widths (each printable character measured once per weight with `TextService:GetTextBoundsAsync` in that font, in the background) at the size the text is really drawn, so buttons, tabs and pills fit their words in every font. Until a font is measured (a moment after start), Roblox's Gotham width at the drawn size stands in. Something you lay out by text width can size itself again when the font or text size changes: `Lib.Util.onTextMetrics(frame, function() ... end)` (stops when `frame` is destroyed).

**Icons.** The lib's own icons (and Qustah's) come from its sheet in `qustah/icons`: filled icons (Solar Bold, a few Material Design Icons where Solar has none) drawn at 14, 16, 20, 24, 28 and 30 px, every pixel on or off (no grey edges), downloaded once into `QustahUI/icons` and shown through `getcustomasset` with nearest-pixel sampling. `src/icons_qustah.lua` says where each one is; `tools/qustah_icons.json` which icon is drawn for which lucide name. Any other lucide icon comes from the 16 / 32 px lucide sheets, and without `getcustomasset` from its asset id.

**Icon sizes.** Icons are drawn only at `Lib.Icons.Sizes` (14, 16, 20, 24, 28, 30). A size you ask for goes to the nearest one (`Lib.Icons.fitSize(12)` is 14), keeping the icon's centre; at a UI scale the size on screen goes to the nearest one too (a 14 px icon at 125 % is 16 px on screen).

**Redrawing the sheet.** `python3 tools/gen_filled_sheet.py --iconify <icon-sets>/json --review out/` (needs Playwright's Chromium and the `json` folder of github.com/iconify/icon-sets). Each icon is drawn several ways at each size (candidates A - D); `tools/qustah_picks.json` holds the choices made by eye (`"eye@20": "C"`) and pixels fixed by hand (`"edits": { "user@14": ["6,1=1"] }`). Icons drawn by hand pixel by pixel live in `tools/qustah_drawn.json` (`"save": { "14": ["..##..", ...] }`) and replace that size outright; the other sizes are made from the drawing (doubled where they can be, fitted otherwise), so a drawn icon looks the same at every UI scale. `--review` writes contact sheets to look at; `--only eye,user` tries a few icons without writing the sheet.

**Download strip.** While the library fetches files (the icon sheets, a script's own sheet) a thin strip at the top of the screen says so, with the progress. It only shows when something is really downloaded, so later starts (everything already on disk) show nothing. `Lib.Loader.enabled = false` hides it. A download that never answers is given up after `Lib.Util.downloadTimeout` (20 s) and the plain icons are used. `Lib.Icons.Preload()` starts the sharp icon download early and `Lib.Loader.Wait(30)` (before `CreateWindow`) keeps the window back until the downloads are done.

<p align="center"><img src="assets/screens/strip.png" alt="Download strip" width="500"></p>

## Icons

Anything that takes an icon accepts a name. Asset ids and web images work too:

```lua
Window:Tab({ Title = "Visuals", Icon = "eye" })               -- lucide (built in)
Window:Tab({ Title = "Silent", Icon = "solar:target-bold" })  -- set:name
Card:Toggle({ Title = "ESP", Icon = "scan-eye" })
Lib:CreateWindow({ Title = "Qustāh", Icon = "https://example.com/logo.png" })
```

| Set | Icons | Notes |
|---|---|---|
| `lucide` | 1715 | built in, no download — [lucide.dev/icons](https://lucide.dev/icons) |
| `solar` | 7330 | `-bold`, `-linear`, `-broken`, `-bold-duotone`... |
| `sfsymbols` | 6984 | CamelCase: `sfsymbols:HouseFill` |
| `gravity` | 781 | |
| `geist` | 320 | two-tone |
| `craft` | 998 | |

Sets other than lucide download once, the first time you use them.

**Icons.** The library's own icons are drawn pixel for pixel at every size it uses (the qustah sheet, about 50 KB, downloaded once into `QustahUI/icons` and shown through `getcustomasset`). Every other icon, lucide and the other sets, is a Roblox asset id, so nothing else is downloaded. An icon can also be your own upload: `Icon = "rbxassetid://123456"` or just the number. `Lib.Icons.Sharp = false` (before the first window) keeps the sheet off too.

**A script's own sheet.** For the sharpest result, draw just your script's icons at every size they show at (no scaling at all; small sizes get slightly bolder lines): `python3 tools/gen_sheet.py <lucide icons dir> myscript 1 "eye,ghost,settings" 7-22 out/`. Host `out/myscript-1.png` somewhere raw and load it before the window:

```lua
Lib.Icons.UseSheet(require(path.to.myscript_manifest), "https://raw.githubusercontent.com/you/repo/main/icons/")
```

Icons and sizes in that sheet come from it; everything else from the lucide sheets.

```lua
Lib.Icons.SetDefault("solar")                            -- use solar without the prefix
Lib.Icons.Image("house", { Size = UDim2.fromOffset(24, 24), Parent = frame })
Lib.Icons.Apply(imageLabel, "solar:home-bold")
Lib.Icons.Add("mine", { skull = "rbxassetid://123" })    -- "mine:skull"
Lib.Icons.List("lucide")
```

Icons are from [Footagesus/Icons](https://github.com/Footagesus/Icons) (MIT, [`icons/LICENSE`](icons/LICENSE)); the sharp sheets are drawn from [lucide](https://github.com/lucide-icons/lucide) (ISC).

---

## Status, errors and kicks

```lua
Window:SetModule("ESP", "On")                         -- "On" | "Off" | "Limited" | "Error", detail
Window:SetModule("Mark", "Limited", "client-side only")
Window:SetModule("ESP", "On", nil, { Icon = "eye", Tab = "Visuals" })   -- tile icon; a click on the tile opens that tab
Window:ReportError("ESP", "attempt to index nil")
Window:GetErrorReport()   Window:ClearErrors()
```

Modules are shown on the Dashboard (two tiles a row; past six, three smaller ones with the state on hover - `DashboardTab({ ModuleColumns = 2 })` keeps two) and in Settings › Info. The footer updates by itself: `Connected` / `Limited` / `Errors: N`.

**Kick watcher**
- When the game disconnects you, the reason and error code are recorded.
- The last 20 are saved; read them with `Window:GetKicks()`.

```lua
Window:OnKick(function(info)
    print(info.Kind, info.Reason, info.Code)   -- "Kicked", "Exploiting", 267
end)
Window:GetKicks()
-- CreateWindow({ Rejoin = true })  -> teleports back to the same place after a kick
```

## Window extras

On phones and tablets the menu adapts: a reopen button while it is hidden, taller slider hit areas, haptics on, and the window scales down to fit the screen. Scroll bars appear only while scrolling; grid cells grow slightly on hover.

```lua
Window:HeaderButton({ Icon = "refresh-cw", Tooltip = "Rejoin", Callback = rejoin })
Window:AddTag("NEW", { Color = "warning", Style = "Solid" | "Soft" })   -- text colour is picked to read on the fill

Window:SetFullscreen(true)                      -- or Window:ToggleFullscreen(); a double click on the header does the same
Window:SetBackgroundImage("rbxassetid://123", 0.85)
Window:SetBackgroundTransparency(0.2)            -- the whole window: every surface and outline (the Settings slider goes to 25 %)
Window:SetLiveBackground(true)                  -- slow accent light drifting behind the content
Window:SetAccentGlow(true)                      -- the window edge pulses in the accent colour

Window:SetBlur(true)                            -- blurs the game behind the open menu
Window:SetAnonymous(true)                       -- hides your name and avatar everywhere (the avatar button in the dock)
Window:OnAnonymousChanged(function(on) end)     -- redraw your own name labels when it changes
Window:SetMouseUnlock(false)

Window:SetUIScale(1.25)                         -- bigger menu (Settings › Behaviour › UI scale)
Window:SetMobileButton(true)                    -- the reopen button (tap: open, drag: move) while the menu is hidden

Lib.Sounds.Enabled = true                       -- soft clicks on buttons, switches and tabs
Lib.Haptics.Enabled = true                      -- a short buzz on taps and notifications (on by default for phones)
Lib.Sounds.Set("click", "rbxassetid://123")     -- your own sound for "click" | "toggle" | "tab" | "error"
```

## Key system

```lua
local Window = Lib:CreateWindow({
    Title = "Qustāh",
    KeySystem = {
        Keys = { "QUSTAH-1234" },                         -- or Check = function(key) return ok, message end
        Url = "https://discord.gg/yourserver",            -- the "Get key" button copies it
        Note = "Keys reset every 24 hours",
        Remember = true,                                  -- saved in <Folder>/key.txt and checked again next time
    },
})
```

- `CreateWindow` waits until a key is accepted, then the window opens as usual.
- A wrong key shakes the box and says why; `Check` can return its own message (e.g. "Key expired").
- Closing the key screen stops the script (`OnCancel` runs first).
- `Lib:ForgetKey("Folder")` deletes the saved key.

## Tour

A first-run guide: the screen dims except one part of the menu, and a small card explains it (Next, Back, Skip; the arrow keys and Escape work too).

<p align="center"><img src="assets/screens/tour.png" alt="Tour step highlighting the Settings tab" width="640"></p>

```lua
Lib:CreateWindow({ Title = "Qustāh", Tour = true })   -- built-in steps (tabs, header, menu key, settings, status), once per account

Window:Tour({
    { Target = espToggle, Title = "ESP", Text = "Turn ESP on here." },            -- an element, card, tab or GuiObject
    { Target = "settings", Title = "Settings", Text = "Profiles and themes." },    -- "dock", "header", "footer", "menuKey", "status", "bell", "close"
    { Title = "Done", Text = "Have fun!" },                                         -- no Target: a card in the middle
}, { Id = "v2", Once = true, OnFinish = function(completed) end })

Window:HasSeenTour("v2")    Window:ResetTour("v2")
local tour = Window:Tour(steps)   tour:Next()   tour:Back()   tour:Go(3)   tour:Close()
```

The tab and page of a target open by themselves, and a long page scrolls to it. With `Tour` set, Settings › Info gets a "Show the tour" button.

## Changelog

```lua
Lib:CreateWindow({
    Title = "Qustāh", Version = "V1.2",
    Changelog = { Version = "1.2", Items = { "Added auto farm", "Fixed ESP flicker" },
        History = { { Version = "1.1", Items = { "Server hop" } }, { Version = "1.0", Items = { "First release" } } } },
})
```

The "What's new" dialog opens once for each new version. `Window:ShowChangelog()` (and Settings › Info › What's new) opens it again. With `History`, Settings › Info › **Version history** (`Window:ShowVersionHistory()`) lists every version's notes, newest first.

**This session** (Settings › Info): how long the script has run, the errors caught, Lua memory, and your own counters:

```lua
Window:Count("Teleports")          -- +1 (or Count("Coins", 250)); shown as a row, updated live
Window:GetCounts()                 -- order, { [name] = value }
```

## Links

```lua
Lib:CreateWindow({ Links = { { Title = "Discord", Url = "https://discord.gg/...", Icon = "message-circle" }, { Title = "Website", Url = "https://..." } } })
```

Settings › Info › About gets a button for each link (two per row); a click copies the link, since a game can't open a browser. Errors › the copy icon (`Window:GetDebugInfo()`) copies the versions, executor, game, screen, theme, modules and errors in one go for a bug report.

## Secure mode

```lua
getgenv().QUSTAH_SECURE = true                  -- before loading the library
-- or CreateWindow({ Secure = true }) / Lib:SetSecure(true)
```

In secure mode:
- ScreenGui names are random GUIDs;
- nothing is printed to the console;
- avatars load as `rbxthumb://` content, with no web request.

Icons still load as asset ids.

---

## Development

```
qustah-ui-lib/
  src/              source modules
    init.lua          entry point: Lib API
    window.lua        window, dock, tabs, pages
    card.lua          cards + element registry
    elements/         one file per element; base.lua holds the shared row, flash, lock and ordering code
    config.lua        profiles, crash-safe saves
    menu.lua          Window:Menu (context menus)
    theme.lua         colour roles, theme packs
    settings.lua      built-in Settings tab
    ...
  dist/             single-file bundle (built by build.py)
  icons/            downloadable icon sets
  test/             tests and screenshot scripts (they run in a Roblox mock that is not part of this repo)
  types/qustah.luau type definitions for autocomplete
  tools/lint.sh     selene lint (and a StyLua check with --format)
  build.py          src/ -> dist/qustah-ui-lib.lua + .min.lua
  example.lua       example that uses every element
```

**Autocomplete:** with luau-lsp (VS Code) copy `types/qustah.luau` into your project:

```lua
local Types = require(path.to.qustah)
local Lib = loadstring(game:HttpGet(URL))() :: Types.Lib   -- Window, tabs, cards and elements are typed from here
```

To change the library:
1. Edit the source files in `src/`.
2. Run `python3 build.py`.
3. Commit `dist/` together with the source; the raw link serves that file.

To add an element:
1. Write `src/elements/<name>.lua` (`return function(card, cfg) ... end`, using `elements/base`).
2. Add it to `Card.Elements` in `card.lua`.
