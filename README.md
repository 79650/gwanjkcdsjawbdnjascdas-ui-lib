<div align="center">

![Qustah UI](qustah-ui-lib/assets/banner-live.png)

**A clean, fast UI library for Roblox scripts.**<br>
Dock navigation, real profiles, 20 themes and 18k icons, loaded with one line.

<br>

![version](https://img.shields.io/badge/version-1.9.14-2b2b2f?style=flat-square&labelColor=18181a)
![luau](https://img.shields.io/badge/Luau-executor-2b2b2f?style=flat-square&labelColor=18181a)
![size](https://img.shields.io/badge/min-420_KB-2b2b2f?style=flat-square&labelColor=18181a)

[Install](#install) · [Quick start](#quick-start) · [Screenshots](#screenshots) · [Documentation](qustah-ui-lib/DOCS.md) · [Example](qustah-ui-lib/example.lua)

</div>

## Features

- **Finished look.** Dock, two-column cards, footer bar, key hints and smooth animations.
- **Real profiles.** Save, autoload, share codes and per-game lists. An interrupted save never damages a profile.
- **20 themes.** Tokyo Night, Catppuccin, Dracula and more, all contrast-checked. Make your own and share it as a code.
- **18k icons.** Write an icon's name anywhere (`"eye"`, `"solar:target-bold"`). Lucide is built in.
- **Hard to break.** A callback error flashes the element red and is listed; the UI keeps working.
- **Ready to ship.** One line adds a Dashboard and a full Settings tab. Key system, tour, "What's new" and autocomplete types included.

## Install

```lua
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/79650/gwanjkcdsjawbdnjascdas-ui-lib/refs/heads/main/qustah-ui-lib/dist/qustah-ui-lib.lua"))()
```

<sub>The minified build is the same code and about 25% smaller: replace <code>qustah-ui-lib.lua</code> with <code>qustah-ui-lib.min.lua</code>.</sub>

## Quick start

```lua
local Window = Lib:CreateWindow({ Title = "Qustāh", Version = "V1.00", Folder = "Qustah" })

local Main = Window:Tab({ Title = "Main", Icon = "eye" }):Card({ Title = "General" })
Main:Toggle({ Title = "ESP", Flag = "esp", Default = true, Callback = function(on) print(on) end })
Main:Slider({ Title = "Distance", Flag = "range", Min = 100, Max = 5000, Default = 1500, Suffix = "studs" })

Window:SettingsTab()          -- theme, font, menu key, profiles...
Window.Config:LoadAutoLoad()  -- loads the profile marked as autoload
```

## Screenshots

<table>
<tr>
<td width="50%"><img src="qustah-ui-lib/assets/screens/dashboard.png" alt="Dashboard"><br><sub><b>Dashboard</b> (built in): profile, live chips, session, module tiles, server tools</sub></td>
<td width="50%"><img src="qustah-ui-lib/assets/screens/combat.png" alt="Combat tab"><br><sub><b>Combat</b>: page warning, risky toggle, locks, presets, chord keybinds</sub></td>
</tr>
<tr>
<td width="50%"><img src="qustah-ui-lib/assets/screens/player.png" alt="Player tab"><br><sub><b>Player</b>: icon rows, key caps, 3D preview, split and hold buttons</sub></td>
<td width="50%"><img src="qustah-ui-lib/assets/screens/buttons.png" alt="Components tab, Buttons page"><br><sub><b>Components › Buttons</b>: every style, cooldown, key, confirm, rows</sub></td>
</tr>
</table>

<details>
<summary><b>More screenshots</b></summary>
<br>

<table>
<tr>
<td width="50%"><img src="qustah-ui-lib/assets/screens/live.png" alt="Live tab"><br><sub><b>Live</b>: graphs, progress, rolling stats, console, table</sub></td>
<td width="50%"><img src="qustah-ui-lib/assets/screens/visuals.png" alt="Visuals tab"><br><sub><b>Visuals</b>: page strip, bindable toggle, badge, slider, range, multi dropdown</sub></td>
</tr>
<tr>
<td width="50%"><img src="qustah-ui-lib/assets/screens/appearance.png" alt="Visuals, Appearance page"><br><sub><b>Visuals › Appearance</b>: colour pickers, gradient, swatches</sub></td>
<td width="50%"><img src="qustah-ui-lib/assets/screens/inputs.png" alt="Components tab, Inputs page"><br><sub><b>Components › Inputs</b>: validation, stepper, text area, image picker, radio</sub></td>
</tr>
<tr>
<td width="50%"><img src="qustah-ui-lib/assets/screens/content.png" alt="Components tab, Content page"><br><sub><b>Components › Content</b>: notifications, dialog, image, group, code</sub></td>
<td width="50%"><img src="qustah-ui-lib/assets/screens/settings.png" alt="Settings"><br><sub><b>Settings</b> (built in): appearance, window, behaviour, profiles, info</sub></td>
</tr>
<tr>
<td width="50%"><img src="qustah-ui-lib/assets/screens/tokyo.png" alt="Tokyo Night theme"><br><sub>Tokyo Night theme</sub></td>
<td width="50%"><img src="qustah-ui-lib/assets/screens/light.png" alt="Light theme"><br><sub>Light theme</sub></td>
</tr>
</table>

</details>

## Elements

| | | | | |
|---|---|---|---|---|
| Toggle | Checkbox | Slider | Range | Stepper |
| Dropdown | Radio | Segment | Keybind | ColorPicker |
| Gradient | Swatches | Input | TextArea | ActionInput |
| Button | Label | Paragraph | Info | Divider |
| Code | Progress | Stat | Graph | Console |
| Table | Image | ImagePicker | PlayerList | Viewport |

<sub>All elements share Flags, DependsOn, Tooltips, Lock with a reason, Help hints, Risky styling, MoveUp/MoveDown and error flashes. You lay them out with Tabs, Sections, Rows and Groups inside a card.</sub>

## Documentation

The full reference is in **[DOCS.md](qustah-ui-lib/DOCS.md)**. [example.lua](qustah-ui-lib/example.lua) uses every element once.

| | |
|---|---|
| [**Window**](qustah-ui-lib/DOCS.md#window)<br><sub>Every CreateWindow option</sub> | [**Icons**](qustah-ui-lib/DOCS.md#icons)<br><sub>Lucide, Solar and other icon sets</sub> |
| [**Tabs, pages and cards**](qustah-ui-lib/DOCS.md#tabs-pages-and-cards)<br><sub>Dock tabs, page strips, two-column cards</sub> | [**Status, errors and kicks**](qustah-ui-lib/DOCS.md#status-errors-and-kicks)<br><sub>Module health, error list, kick log</sub> |
| [**Elements**](qustah-ui-lib/DOCS.md#elements)<br><sub>All 30 elements and their options</sub> | [**Window extras**](qustah-ui-lib/DOCS.md#window-extras)<br><sub>Header buttons, tags, phones and tablets</sub> |
| [**Flags**](qustah-ui-lib/DOCS.md#flags)<br><sub>Reading and setting values, reset to default</sub> | [**Key system**](qustah-ui-lib/DOCS.md#key-system)<br><sub>Key screen before the window opens</sub> |
| [**Notifications**](qustah-ui-lib/DOCS.md#notifications)<br><sub>Notifications, toasts, progress toasts</sub> | [**Tour**](qustah-ui-lib/DOCS.md#tour)<br><sub>First-run guide</sub> |
| [**Dialogs**](qustah-ui-lib/DOCS.md#dialogs)<br><sub>Dialogs and confirms</sub> | [**Changelog**](qustah-ui-lib/DOCS.md#changelog)<br><sub>"What's new" and version history</sub> |
| [**Configs and profiles**](qustah-ui-lib/DOCS.md#configs-and-profiles)<br><sub>Saving, autoload, share codes, your own data</sub> | [**Links**](qustah-ui-lib/DOCS.md#links)<br><sub>Discord and other link buttons</sub> |
| [**Built-in tabs**](qustah-ui-lib/DOCS.md#built-in-tabs)<br><sub>Dashboard and Settings</sub> | [**Secure mode**](qustah-ui-lib/DOCS.md#secure-mode)<br><sub>Random GUI names, silent console</sub> |
| [**Overlays**](qustah-ui-lib/DOCS.md#overlays)<br><sub>Watermark, keybind list, session bar, key hints</sub> | [**Development**](qustah-ui-lib/DOCS.md#development)<br><sub>Project layout, build, autocomplete types</sub> |
| [**Themes**](qustah-ui-lib/DOCS.md#themes)<br><sub>20 themes, custom themes, theme codes</sub> |  |

<br>

<div align="center">
<sub>Icons from <a href="https://github.com/Footagesus/Icons">Footagesus/Icons</a> (MIT) · made for Qustah</sub>
</div>
