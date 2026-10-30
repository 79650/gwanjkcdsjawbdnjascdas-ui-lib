<div align="center">

![Qustah UI](qustah-ui-lib/assets/banner-live.png)

**A clean, fast UI library for Roblox scripts.**<br>
Dock navigation, real profiles, 20 themes and 18k icons, loaded with one line.

<br>

![version](https://img.shields.io/badge/version-1.9.14-2b2b2f?style=flat-square&labelColor=18181a)
![luau](https://img.shields.io/badge/Luau-executor-2b2b2f?style=flat-square&labelColor=18181a)
![size](https://img.shields.io/badge/min-420_KB-2b2b2f?style=flat-square&labelColor=18181a)

[Install](#install) · [Quick start](#quick-start) · [Screenshots](#screenshots) · [Documentation](#documentation) · [Example](qustah-ui-lib/example.lua)

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

<p align="center"><img src="qustah-ui-lib/assets/screens/tabs.gif" alt="Switching between the example's tabs" width="820"></p>

### Themes

<p align="center"><img src="qustah-ui-lib/assets/screens/themes.png" alt="Dark, Light, Tokyo Night, Cyberpunk, Gruvbox and Mint themes"></p>

<p align="center"><sub>6 of the 20 built-in themes. You can also make your own and share it as a code.</sub></p>

## Documentation

Every option, with code, is in **[DOCS.md](qustah-ui-lib/DOCS.md)**. **[example.lua](qustah-ui-lib/example.lua)** builds the window in the GIF and uses every element once.

### Elements

<table>
<tr>
<td width="20%" valign="top"><b>Switches</b><br><br><code>Toggle</code><br><code>Checkbox</code></td>
<td width="20%" valign="top"><b>Numbers</b><br><br><code>Slider</code><br><code>Range</code><br><code>Stepper</code></td>
<td width="20%" valign="top"><b>Choices</b><br><br><code>Dropdown</code><br><code>Segment</code><br><code>Radio</code></td>
<td width="20%" valign="top"><b>Colours</b><br><br><code>ColorPicker</code><br><code>Gradient</code><br><code>Swatches</code></td>
<td width="20%" valign="top"><b>Text input</b><br><br><code>Input</code><br><code>TextArea</code><br><code>ActionInput</code><br><code>Keybind</code></td>
</tr>
<tr>
<td width="20%" valign="top"><b>Buttons</b><br><br><code>Button</code></td>
<td width="20%" valign="top"><b>Text</b><br><br><code>Label</code><br><code>Paragraph</code><br><code>Info</code><br><code>Divider</code><br><code>Code</code></td>
<td width="20%" valign="top"><b>Live data</b><br><br><code>Progress</code><br><code>Stat</code><br><code>Graph</code><br><code>Console</code><br><code>Table</code></td>
<td width="20%" valign="top"><b>Visual</b><br><br><code>Image</code><br><code>ImagePicker</code><br><code>PlayerList</code><br><code>Viewport</code></td>
<td width="20%" valign="top"><b>Layout</b><br><br><code>Section</code><br><code>Row</code><br><code>Group</code><br><code>Tabs</code></td>
</tr>
</table>

<sub>Every element can be saved in profiles, depend on another element, show a tooltip or help hint, be locked with a reason, and flashes red when its callback errors.</sub>

### Guides

<table>
<tr>
<td width="20%" valign="top"><b>Build</b><br><br><a href="qustah-ui-lib/DOCS.md#window"><code>Window</code></a><br><a href="qustah-ui-lib/DOCS.md#tabs-pages-and-cards"><code>Tabs, pages and cards</code></a><br><a href="qustah-ui-lib/DOCS.md#elements"><code>Elements</code></a><br><a href="qustah-ui-lib/DOCS.md#flags"><code>Flags</code></a></td>
<td width="20%" valign="top"><b>Talk to the user</b><br><br><a href="qustah-ui-lib/DOCS.md#notifications"><code>Notifications</code></a><br><a href="qustah-ui-lib/DOCS.md#dialogs"><code>Dialogs</code></a><br><a href="qustah-ui-lib/DOCS.md#tour"><code>Tour</code></a><br><a href="qustah-ui-lib/DOCS.md#changelog"><code>Changelog</code></a></td>
<td width="20%" valign="top"><b>Save and style</b><br><br><a href="qustah-ui-lib/DOCS.md#configs-and-profiles"><code>Configs and profiles</code></a><br><a href="qustah-ui-lib/DOCS.md#themes"><code>Themes</code></a><br><a href="qustah-ui-lib/DOCS.md#icons"><code>Icons</code></a></td>
<td width="20%" valign="top"><b>Built in</b><br><br><a href="qustah-ui-lib/DOCS.md#built-in-tabs"><code>Dashboard and Settings</code></a><br><a href="qustah-ui-lib/DOCS.md#overlays"><code>Overlays</code></a><br><a href="qustah-ui-lib/DOCS.md#window-extras"><code>Window extras</code></a><br><a href="qustah-ui-lib/DOCS.md#links"><code>Links</code></a></td>
<td width="20%" valign="top"><b>Ship it</b><br><br><a href="qustah-ui-lib/DOCS.md#status-errors-and-kicks"><code>Status, errors and kicks</code></a><br><a href="qustah-ui-lib/DOCS.md#key-system"><code>Key system</code></a><br><a href="qustah-ui-lib/DOCS.md#secure-mode"><code>Secure mode</code></a><br><a href="qustah-ui-lib/DOCS.md#development"><code>Development</code></a></td>
</tr>
</table>
