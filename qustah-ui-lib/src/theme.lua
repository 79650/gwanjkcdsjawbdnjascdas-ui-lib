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
            if contrast(accent, colors.card) >= 3 and contrast(accent, deep) >= 3 and contrast(accent, colors.dock or colors.base) >= 3
                and contrast(accent, colors.selected or colors.card) >= 3 then break end
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

-- A data colour (a profile's colour, a series...) made readable on a theme colour: darkened on light packs,
-- lightened on dark ones until it reaches `ratio` (3:1). Theme.readable(color, "card", 3.5) -> Color3
function Theme.readable(color, role, ratio)
    local back = Theme.get(role or "card")
    local toward = luminance(back) > 0.5 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
    for _ = 1, 14 do
        if contrast(color, back) >= (ratio or 3) then break end
        color = color:Lerp(toward, 0.1)
    end
    return color
end
function Theme._bound() return bound end
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
    if property == "BackgroundColor3" and (Theme.alpha[role] or entry.__alpha ~= nil) then
        -- (not in its place yet: once it is)
        if object.Parent then Theme._alphaOf(object, entry) else task.defer(function() if object.Parent then pcall(Theme._alphaOf, object, entry) end end) end
    end
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
        -- a theme change while this runs must not be undone by it (see recolour)
        entry.__until = entry.__until or {}
        entry.__until[property] = os.clock() + duration
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
                if changed[boundRole] then
                    local running = properties.__until and properties.__until[property]
                    if running and running > os.clock() then
                        -- a tween to the old colour is still running: a new one (ending just after it) replaces it
                        pcall(Util.tween, object, running - os.clock() + 0.02, { [property] = Theme.get(boundRole) })
                    else
                        pcall(function() object[property] = Theme.get(boundRole) end)
                    end
                end
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

-- Theme packs: the background / text roles (the accent stays the user's), and what else the pack brings to the
-- window (Theme.packs[name].extras: see Theme.extras). Five built in:
--   Midnight  deep blue-black, the default        Graphite  neutral grey (Qustah 1.x)
--   Glass     see-through window and cards, light edges, the game blurred behind
--   OLED      true black                          Light     light
Theme.packs = {
    Midnight = {
        base = rgb(13, 14, 17), footer = rgb(11, 12, 15), dock = rgb(13, 14, 17), selected = rgb(30, 32, 39), icon = rgb(150, 155, 168),
        card = rgb(20, 21, 26), input = rgb(25, 26, 32), hover = rgb(30, 32, 39), line = rgb(33, 35, 42), edge = rgb(31, 33, 40),
        buttonEdge = rgb(44, 46, 55), text = rgb(196, 199, 207), muted = rgb(110, 115, 128), heading = rgb(238, 240, 244), knob = rgb(255, 255, 255),
    },
    Graphite = {},
    Glass = {
        base = rgb(14, 15, 19), footer = rgb(14, 15, 19), dock = rgb(14, 15, 19), selected = rgb(52, 55, 66), icon = rgb(170, 175, 188),
        card = rgb(40, 43, 52), input = rgb(48, 51, 61), hover = rgb(55, 58, 69), line = rgb(78, 82, 95), edge = rgb(92, 96, 110),
        buttonEdge = rgb(70, 74, 86), text = rgb(206, 209, 216), muted = rgb(140, 145, 158), heading = rgb(245, 246, 250), knob = rgb(255, 255, 255),
        extras = {
            -- (BackgroundTransparency per role: the window and dock let the game through, cards are lighter panes)
            alpha = { base = 0.3, footer = 1, dock = 0.3, card = 0.55, input = 0.45 },
            blur = true,
        },
    },
    OLED = {
        base = rgb(0, 0, 0), footer = rgb(0, 0, 0), dock = rgb(0, 0, 0), selected = rgb(26, 26, 28), icon = rgb(190, 190, 190),
        card = rgb(9, 9, 10), input = rgb(17, 17, 19), hover = rgb(26, 26, 28), line = rgb(34, 34, 37), edge = rgb(36, 36, 38),
        buttonEdge = rgb(46, 46, 50), text = rgb(176, 176, 180), muted = rgb(118, 118, 124), heading = rgb(225, 225, 230), knob = rgb(255, 255, 255),
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
-- Custom themes (Settings › Theme editor): a few colours, the rest derived with the same steps as Graphite (card /
-- input / hover / outline at fixed distances between the background and the text), then checked: text at least
-- 4.5:1 and muted text 3:1 on cards.
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
Theme.packOrder = { "Midnight", "Graphite", "Glass", "OLED", "Light" }
Theme.defaultPack = "Midnight"
local DEFAULTS = {}
for role, color in pairs(Theme.colors) do DEFAULTS[role] = color end
Theme.defaults = DEFAULTS
-- The accent a pack starts with ("Neutral" preset): Light a dark grey, the others Qustah grey.
function Theme.neutral(pack)
    local data = Theme.packs[pack]
    if data and data.accent then return data.accent end
    return pack == "Light" and rgb(70, 70, 80) or rgb(177, 178, 183)
end

-- Transparency per role (Glass): a surface bound to one of these roles takes its BackgroundTransparency (only
-- surfaces that show a background at all; their own value comes back when the pack has none).
Theme.alpha = {}
-- (only inside the window and the dock - a frame marked with the ThemeGlass attribute: popups, notifications and
-- the HUD over the game stay solid so their text reads on any background)
local function inGlass(object)
    local parent = object
    while parent do
        if parent:GetAttribute("ThemeGlass") then return true end
        parent = parent.Parent
    end
    return false
end
local function alphaOf(object, entry)
    local role = entry.BackgroundColor3
    local wanted = role and Theme.alpha[role]
    if wanted and not inGlass(object) then wanted = nil end
    if wanted then
        if entry.__alpha == nil then
            if object.BackgroundTransparency >= 1 then return end
            entry.__alpha = object.BackgroundTransparency
        end
        if object.BackgroundTransparency ~= wanted then object.BackgroundTransparency = wanted end
    elseif entry.__alpha ~= nil then
        object.BackgroundTransparency = entry.__alpha
        entry.__alpha = nil
    end
end
Theme._alphaOf = alphaOf
local function applyAlpha()
    for object, entry in pairs(Theme._bound()) do
        if object.Parent and entry.BackgroundColor3 then pcall(alphaOf, object, entry) end
    end
end

-- What the pack brings besides colours: { alpha = { role = transparency }, blur = true }. Windows listen with
-- Theme.onExtras(fn(extras)) (the blur).
Theme.extras = {}
local extrasListeners = {}
-- returns a function that removes the listener (a window gives it to its maid)
function Theme.onExtras(callback)
    extrasListeners[#extrasListeners + 1] = callback
    return function()
        local index = table.find(extrasListeners, callback)
        if index then table.remove(extrasListeners, index) end
    end
end

function Theme.applyPack(name)
    local pack = Theme.packs[name]
    if not pack then return false end
    local colors = {}
    for role, color in pairs(DEFAULTS) do if role ~= "accent" and role ~= "accentUser" then colors[role] = color end end
    for role, color in pairs(pack) do if role ~= "accent" and typeof(color) == "Color3" then colors[role] = color end end
    -- the pack's own accent follows the pack; an accent the user picked is kept
    local accent = Theme.colors.accentUser
    if accent == Theme.neutral(Theme.pack) or accent == Theme.neutral("Graphite") or accent == Theme.neutral("Light") then colors.accentUser = Theme.neutral(name) end
    Theme.pack = name
    Theme.extras = pack.extras or {}
    Theme.alpha = Theme.extras.alpha or {}
    Theme.setMany(colors)
    applyAlpha()
    for _, listener in ipairs(extrasListeners) do Util.safe(listener, Theme.extras) end
    return true
end
Theme.pack = "Graphite"

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

-- returns a function that removes the listener
function Theme.onChange(callback)
    listeners[#listeners + 1] = callback
    return function()
        local index = table.find(listeners, callback)
        if index then table.remove(listeners, index) end
    end
end

return Theme
