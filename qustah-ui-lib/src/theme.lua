-- Colour roles. Objects bind a property to a role; changing a role (e.g. the accent) recolours every bound object.
local Util = require("util")

local Theme = {}
local rgb = Color3.fromRGB

Theme.colors = {
    base       = rgb(15, 15, 16),    -- window background
    footer     = rgb(12, 12, 13),
    dock       = rgb(16, 16, 16),
    selected   = rgb(33, 33, 36),
    icon       = rgb(192, 192, 192),
    card       = rgb(19, 19, 20),
    input      = rgb(25, 25, 27),    -- buttons, boxes
    hover      = rgb(33, 33, 36),
    line       = rgb(36, 36, 39),    -- card outlines, dividers
    edge       = rgb(30, 30, 30),    -- window outline
    buttonEdge = rgb(46, 46, 50),    -- button outline, switch off
    text       = rgb(168, 168, 172),
    muted      = rgb(118, 118, 124),
    heading    = rgb(205, 205, 210),
    knob       = rgb(190, 190, 195),
    accent     = rgb(177, 178, 183), -- Qustah neutral; Lib:SetAccent changes it
    -- states (footer dot, module rows, hints, danger buttons)
    success    = rgb(110, 200, 130),
    warning    = rgb(215, 180, 120),
    danger     = rgb(215, 130, 130),
    dangerDeep = rgb(70, 32, 36),    -- danger button fill
    dangerEdge = rgb(150, 60, 66),
    dangerText = rgb(235, 150, 155),
    -- code blocks
    codeKeyword = rgb(199, 146, 234), codeString = rgb(195, 232, 141), codeNumber = rgb(247, 140, 108),
    codeComment = rgb(107, 112, 128), codeGlobal = rgb(130, 170, 255), codeCall = rgb(255, 203, 107),
}
Theme.colors.accentUser = Theme.colors.accent -- the accent as chosen; "accent" may be darkened for light packs

local function luminance(c)
    local function channel(v) return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
    return 0.2126 * channel(c.R) + 0.7152 * channel(c.G) + 0.0722 * channel(c.B)
end
local function contrast(a, b)
    local la, lb = luminance(a), luminance(b)
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05)
end
Theme.contrast = contrast

-- Roles computed from the accent.
local function derive()
    local colors = Theme.colors
    -- on light backgrounds a pale accent (green, yellow...) is darkened until it reads (contrast 3:1 on cards)
    local accent = colors.accentUser or colors.accent
    local light = luminance(colors.base) > 0.5
    if light then
        -- it must also read on its own tinted fill (primary buttons, selected dock button) and on the dock
        local black = Color3.new(0, 0, 0)
        for _ = 1, 16 do
            local deep = colors.base:Lerp(accent, 0.12)
            if contrast(accent, colors.card) >= 3 and contrast(accent, deep) >= 3 and contrast(accent, colors.dock or colors.base) >= 3 then break end
            accent = accent:Lerp(black, 0.08)
        end
    end
    colors.accent = accent
    Theme.isLight = light
    colors.accentDeep = colors.base:Lerp(colors.accent, 0.12) -- selected dock button / indicator fill
    -- muted text is also the placeholder colour inside input boxes: keep it readable there (3:1)
    if colors.muted and colors.input and colors.text then
        for _ = 1, 10 do
            if contrast(colors.muted, colors.input) >= 3 then break end
            colors.muted = colors.muted:Lerp(colors.text, 0.12)
        end
    end
    -- switch track when on: light packs need a much stronger fill to read against the white knob
    colors.toggleOn = colors.input:Lerp(colors.accent, Theme.isLight and 0.85 or 0.42)
    colors.accentEdge = colors.base:Lerp(colors.accent, 0.35)
    -- knob / tick / text on an accent fill: whichever of the background and white reads better
    local white = Color3.new(1, 1, 1)
    colors.onAccent = contrast(colors.base, colors.accent) > contrast(white, colors.accent) and colors.base or white
end
derive()

-- object -> { property = role }. A normal (strong) table: Roblox collects the Lua handle of an Instance that no
-- script variable holds, even while the Instance is on screen, so a weak table silently lost bindings (outlines,
-- labels, boxes stayed in the old theme). Entries leave when their object is destroyed.
local bound = {}
local function track(object)
    local entry = {}
    bound[object] = entry
    pcall(function()
        local connection
        connection = object.Destroying:Connect(function()
            bound[object] = nil
            if connection then connection:Disconnect() end
        end)
    end)
    return entry
end
function Theme._binding(object) return bound[object] end
function Theme._boundCount()
    local count = 0
    for _ in pairs(bound) do count = count + 1 end
    return count
end
local listeners = {}

function Theme.get(role)
    return Theme.colors[role] or role
end

-- bind(object, "BackgroundColor3", "card")
function Theme.bind(object, property, role)
    local entry = bound[object] or track(object)
    entry[property] = role
    object[property] = Theme.get(role)
    -- a text box's placeholder follows the theme too (muted) unless something else was chosen for it
    if property == "TextColor3" and entry.PlaceholderColor3 == nil and object:IsA("TextBox") then
        entry.PlaceholderColor3 = "muted"
        object.PlaceholderColor3 = Theme.get("muted")
    end
    return object
end

-- Rebinds and animates to the role's colour (state changes such as a toggle turning on).
function Theme.tweenTo(object, property, role, duration)
    local entry = bound[object] or track(object)
    entry[property] = role
    if duration and duration > 0 then
        Util.tween(object, duration, { [property] = Theme.get(role) })
    else
        object[property] = Theme.get(role)
    end
end

-- recolours only what uses a role whose colour really changed (dragging the accent picker touches a handful of
-- roles, not every one of the thousands of bound properties)
local function recolour(before)
    local changed, any = {}, false
    for role, color in pairs(Theme.colors) do
        if before[role] ~= color then changed[role] = true any = true end
    end
    if not any then return end
    for object, properties in pairs(bound) do
        if object.Parent then
            for property, boundRole in pairs(properties) do
                if changed[boundRole] then pcall(function() object[property] = Theme.get(boundRole) end) end
            end
        end
    end
end

function Theme.set(role, color)
    if typeof(color) ~= "Color3" then return end
    if role == "accent" then role = "accentUser" end
    local before = table.clone(Theme.colors)
    Theme.colors[role] = color
    if role == "accentUser" or role == "base" or role == "input" or role == "card" or role == "muted" or role == "text" or role == "dock" then derive() end
    recolour(before)
    for _, listener in ipairs(listeners) do Util.safe(listener, role, color) end
end

-- Several roles at once (one recolour pass).
function Theme.setMany(colors)
    local before = table.clone(Theme.colors)
    for role, color in pairs(colors) do
        if typeof(color) == "Color3" then Theme.colors[role == "accent" and "accentUser" or role] = color end
    end
    derive()
    recolour(before)
    for _, listener in ipairs(listeners) do Util.safe(listener, "*", nil) end
end

-- Theme packs: background / text roles only (the accent stays the user's).
-- Light also has its own neutral accent (see Theme.neutral).
Theme.packs = {
    Dark = {},
    Midnight = {
        base = rgb(12, 14, 22), footer = rgb(9, 11, 18), dock = rgb(13, 15, 24), selected = rgb(30, 34, 50), icon = rgb(180, 188, 210),
        card = rgb(16, 19, 29), input = rgb(22, 26, 39), hover = rgb(30, 35, 52), line = rgb(33, 38, 55), edge = rgb(28, 32, 46),
        buttonEdge = rgb(45, 51, 72), text = rgb(165, 172, 192), muted = rgb(110, 118, 140), heading = rgb(208, 214, 232), knob = rgb(196, 202, 220),
    },
    AMOLED = {
        base = rgb(0, 0, 0), footer = rgb(0, 0, 0), dock = rgb(0, 0, 0), selected = rgb(26, 26, 28), icon = rgb(190, 190, 190),
        card = rgb(8, 8, 9), input = rgb(16, 16, 18), hover = rgb(26, 26, 28), line = rgb(30, 30, 33), edge = rgb(28, 28, 28),
        buttonEdge = rgb(42, 42, 46), text = rgb(170, 170, 174), muted = rgb(115, 115, 120), heading = rgb(215, 215, 220), knob = rgb(195, 195, 200),
    },
    Light = {
        base = rgb(238, 238, 241), footer = rgb(229, 229, 233), dock = rgb(234, 234, 238), selected = rgb(216, 216, 222), icon = rgb(85, 85, 95),
        card = rgb(247, 247, 249), input = rgb(231, 231, 235), hover = rgb(221, 221, 226), line = rgb(214, 214, 220), edge = rgb(200, 200, 206),
        buttonEdge = rgb(190, 190, 198), text = rgb(62, 62, 70), muted = rgb(120, 120, 130), heading = rgb(25, 25, 30), knob = rgb(255, 255, 255),
        success = rgb(30, 135, 70), warning = rgb(165, 105, 15), danger = rgb(190, 55, 55),
        dangerDeep = rgb(252, 230, 230), dangerEdge = rgb(225, 150, 150), dangerText = rgb(170, 40, 40),
        codeKeyword = rgb(135, 55, 195), codeString = rgb(35, 125, 55), codeNumber = rgb(195, 85, 35),
        codeComment = rgb(135, 135, 145), codeGlobal = rgb(35, 95, 200), codeCall = rgb(150, 100, 0),
    },
}
-- Palette themes: a few colours from the original palette, the rest derived with the same steps as Qustah's own
-- Dark (card / input / hover / outline sit at fixed distances between the background and the text), then checked:
-- text at least 4.5:1 and muted text 3:1 on cards.
local hex = function(text) return Color3.fromRGB(tonumber(text:sub(2, 3), 16), tonumber(text:sub(4, 5), 16), tonumber(text:sub(6, 7), 16)) end
Theme.hex = hex
function Theme.makePack(p)
    local base, text = hex(p.base), hex(p.text)
    local function step(t) return base:Lerp(text, t) end
    local pack = {
        base = base, footer = base:Lerp(Color3.new(0, 0, 0), 0.18), dock = p.dock and hex(p.dock) or base,
        card = p.card and hex(p.card) or step(0.026), input = p.input and hex(p.input) or step(0.065),
        selected = step(0.118), hover = step(0.118), line = step(0.137), edge = step(0.098), buttonEdge = step(0.203),
        text = text, muted = hex(p.muted), heading = hex(p.heading or p.text), icon = text:Lerp(hex(p.heading or p.text), 0.5),
        knob = text:Lerp(Color3.new(1, 1, 1), 0.15), accent = p.accent and hex(p.accent) or nil,
    }
    for _ = 1, 10 do if contrast(pack.text, pack.card) >= 4.5 then break end pack.text = pack.text:Lerp(pack.heading, 0.2) end
    for _ = 1, 10 do if contrast(pack.muted, pack.card) >= 3 then break end pack.muted = pack.muted:Lerp(pack.text, 0.15) end
    -- switch-off track / button outlines must still show on cards
    for _ = 1, 10 do if contrast(pack.buttonEdge, pack.card) >= 1.35 then break end pack.buttonEdge = pack.buttonEdge:Lerp(text, 0.08) end
    return pack
end
local PALETTES = {
    { "Tokyo Night", { base = "#1a1b26", card = "#1f2131", input = "#272a3d", text = "#a9b1d6", muted = "#6a7299", heading = "#c0caf5", accent = "#7aa2f7" } },
    { "Catppuccin", { base = "#1e1e2e", card = "#232334", input = "#2b2b3e", text = "#bac2de", muted = "#7f849c", heading = "#cdd6f4", accent = "#cba6f7" } },
    { "Dracula", { base = "#21222c", card = "#282a36", input = "#30323f", text = "#d6d6d0", muted = "#7484b8", heading = "#f8f8f2", accent = "#bd93f9" } },
    { "Nord", { base = "#2e3440", card = "#343b49", input = "#3b4252", text = "#d8dee9", muted = "#8892a6", heading = "#eceff4", accent = "#88c0d0" } },
    { "Gruvbox", { base = "#1d2021", card = "#252525", input = "#2e2c2b", text = "#d5c4a1", muted = "#928374", heading = "#fbf1c7", accent = "#fabd2f" } },
    { "One Dark", { base = "#21252b", card = "#282c34", input = "#2f343e", text = "#abb2bf", muted = "#727a87", heading = "#d7dae0", accent = "#61afef" } },
    { "Monokai", { base = "#1e1f1c", card = "#272822", input = "#30312a", text = "#d6d6cf", muted = "#8a8571", heading = "#f8f8f2", accent = "#a6e22e" } },
    { "Rose Pine", { base = "#191724", card = "#1f1d2e", input = "#26233a", text = "#d2cfea", muted = "#7f7a99", heading = "#e0def4", accent = "#c4a7e7" } },
    { "Everforest", { base = "#272e33", card = "#2d353b", input = "#343f44", text = "#d3c6aa", muted = "#859289", heading = "#e6dcc0", accent = "#a7c080" } },
    { "Kanagawa", { base = "#1a1a22", card = "#1f1f28", input = "#2a2a37", text = "#dcd7ba", muted = "#7a7970", heading = "#f2ecbc", accent = "#7e9cd8" } },
    { "Solarized", { base = "#00212b", card = "#002b36", input = "#073642", text = "#93a1a1", muted = "#657b83", heading = "#eee8d5", accent = "#268bd2" } },
    { "Oceanic", { base = "#17252d", card = "#1b2b34", input = "#22343e", text = "#c0c5ce", muted = "#6f7d88", heading = "#d8dee9", accent = "#6699cc" } },
    { "Fatality", { base = "#140f2b", card = "#1a1436", input = "#221a44", text = "#c9c2e6", muted = "#7f76a6", heading = "#efeaff", accent = "#f0024f" } },
    { "Mint", { base = "#141615", card = "#191c1a", input = "#202422", text = "#c2ccc6", muted = "#7c8781", heading = "#e3ebe6", accent = "#3db488" } },
    { "Cyberpunk", { base = "#0d0a17", card = "#130f21", input = "#1b152d", text = "#c9c1e8", muted = "#7d74a0", heading = "#f0e9ff", accent = "#f72585" } },
}
for _, entry in ipairs(PALETTES) do Theme.packs[entry[1]] = Theme.makePack(entry[2]) end
-- Latte: the light Catppuccin
Theme.packs.Latte = {
    base = rgb(230, 233, 239), footer = rgb(220, 224, 232), dock = rgb(230, 233, 239), selected = rgb(204, 208, 218), icon = rgb(76, 79, 105),
    card = rgb(239, 241, 245), input = rgb(220, 224, 232), hover = rgb(210, 214, 224), line = rgb(204, 208, 218), edge = rgb(188, 192, 204),
    buttonEdge = rgb(172, 176, 190), text = rgb(76, 79, 105), muted = rgb(124, 127, 147), heading = rgb(48, 52, 70), knob = rgb(255, 255, 255),
    accent = rgb(136, 57, 239),
    success = rgb(40, 130, 40), warning = rgb(170, 100, 10), danger = rgb(200, 40, 70),
    dangerDeep = rgb(250, 225, 230), dangerEdge = rgb(230, 150, 165), dangerText = rgb(180, 30, 60),
    codeKeyword = rgb(136, 57, 239), codeString = rgb(64, 160, 43), codeNumber = rgb(254, 100, 11),
    codeComment = rgb(140, 143, 161), codeGlobal = rgb(30, 102, 245), codeCall = rgb(223, 142, 29),
}
Theme.packOrder = { "Dark", "Midnight", "AMOLED", "Light", "Latte" }
for _, entry in ipairs(PALETTES) do table.insert(Theme.packOrder, entry[1]) end
local DEFAULTS = {}
for role, color in pairs(Theme.colors) do DEFAULTS[role] = color end
Theme.defaults = DEFAULTS
-- the pack's own accent ("Neutral" preset): palette themes bring theirs, Light a dark grey, the rest Qustah grey
function Theme.neutral(pack)
    local data = Theme.packs[pack]
    if data and data.accent then return data.accent end
    return pack == "Light" and rgb(70, 70, 80) or rgb(177, 178, 183)
end
function Theme.applyPack(name)
    local pack = Theme.packs[name]
    if not pack then return false end
    local colors = {}
    for role, color in pairs(DEFAULTS) do if role ~= "accent" and role ~= "accentUser" then colors[role] = color end end
    for role, color in pairs(pack) do if role ~= "accent" then colors[role] = color end end
    -- the pack's own accent follows the pack; an accent the user picked is kept
    local accent = Theme.colors.accentUser
    if accent == Theme.neutral(Theme.pack) or accent == Theme.neutral("Dark") or accent == Theme.neutral("Light") then colors.accentUser = Theme.neutral(name) end
    Theme.pack = name
    Theme.setMany(colors)
    return true
end
Theme.pack = "Dark"

-- Custom themes: { base = "#101010", card = ..., accent = ... } (hex per role) <-> packs
Theme.EDITABLE = { "base", "card", "input", "line", "text", "muted", "heading", "dock", "icon", "accent" }
function Theme.export()
    local data = {}
    for _, role in ipairs(Theme.EDITABLE) do
        local color = Theme.colors[role == "accent" and "accentUser" or role]
        data[role] = "#" .. Util.toHex(color)
    end
    return data
end
function Theme.registerCustom(name, data)
    if type(data) ~= "table" or type(data.base) ~= "string" or type(data.text) ~= "string" then return false end
    local ok, pack = pcall(function()
        local made = Theme.makePack({
            base = data.base, card = data.card, input = data.input, text = data.text, muted = data.muted or data.text,
            heading = data.heading, accent = data.accent, dock = data.dock,
        })
        if data.line then made.line = hex(data.line) end
        if data.icon then made.icon = hex(data.icon) end
        -- light custom themes get the light state / code colours
        if luminance(made.base) > 0.5 then
            for role, color in pairs(Theme.packs.Light) do if made[role] == nil or role:match("^code") or role:match("^danger") or role == "success" or role == "warning" then made[role] = made[role] or color end end
            for _, role in ipairs({ "success", "warning", "danger", "dangerDeep", "dangerEdge", "dangerText", "codeKeyword", "codeString", "codeNumber", "codeComment", "codeGlobal", "codeCall" }) do made[role] = Theme.packs.Light[role] end
        end
        made.custom = true
        return made
    end)
    if not ok then return false end
    Theme.packs[name] = pack
    if not table.find(Theme.packOrder, name) then table.insert(Theme.packOrder, name) end
    return true
end
function Theme.removeCustom(name)
    if not (Theme.packs[name] and Theme.packs[name].custom) then return false end
    Theme.packs[name] = nil
    local index = table.find(Theme.packOrder, name)
    if index then table.remove(Theme.packOrder, index) end
    return true
end

function Theme.onChange(callback)
    listeners[#listeners + 1] = callback
end

return Theme
