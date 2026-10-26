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
    if luminance(colors.base) > 0.5 then
        local black = Color3.new(0, 0, 0)
        for _ = 1, 12 do
            if contrast(accent, colors.card) >= 3 then break end
            accent = accent:Lerp(black, 0.08)
        end
    end
    colors.accent = accent
    Theme.isLight = luminance(colors.base) > 0.5
    colors.accentDeep = colors.base:Lerp(colors.accent, 0.12) -- selected dock button / indicator fill
    -- switch track when on: light packs need a much stronger fill to read against the white knob
    colors.toggleOn = colors.input:Lerp(colors.accent, Theme.isLight and 0.85 or 0.42)
    colors.accentEdge = colors.base:Lerp(colors.accent, 0.35)
    local a = colors.accent
    local luminance = 0.299 * a.R + 0.587 * a.G + 0.114 * a.B
    colors.onAccent = luminance > 0.6 and colors.base or Color3.new(1, 1, 1) -- knob / text on an accent fill
end
derive()

local bound = setmetatable({}, { __mode = "k" })
local listeners = {}

function Theme.get(role)
    return Theme.colors[role] or role
end

-- bind(object, "BackgroundColor3", "card")
function Theme.bind(object, property, role)
    local entry = bound[object]
    if not entry then entry = {} bound[object] = entry end
    entry[property] = role
    object[property] = Theme.get(role)
    return object
end

-- Rebinds and animates to the role's colour (state changes such as a toggle turning on).
function Theme.tweenTo(object, property, role, duration)
    local entry = bound[object]
    if not entry then entry = {} bound[object] = entry end
    entry[property] = role
    if duration and duration > 0 then
        Util.tween(object, duration, { [property] = Theme.get(role) })
    else
        object[property] = Theme.get(role)
    end
end

function Theme.set(role, color)
    if typeof(color) ~= "Color3" then return end
    if role == "accent" then role = "accentUser" end
    Theme.colors[role] = color
    if role == "accentUser" or role == "base" or role == "input" or role == "card" then derive() end
    for object, properties in pairs(bound) do
        if object.Parent then
            for property, boundRole in pairs(properties) do
                pcall(function() object[property] = Theme.get(boundRole) end)
            end
        end
    end
    for _, listener in ipairs(listeners) do Util.safe(listener, role, color) end
end

-- Several roles at once (one recolour pass).
function Theme.setMany(colors)
    for role, color in pairs(colors) do
        if typeof(color) == "Color3" then Theme.colors[role == "accent" and "accentUser" or role] = color end
    end
    derive()
    for object, properties in pairs(bound) do
        if object.Parent then
            for property, boundRole in pairs(properties) do
                pcall(function() object[property] = Theme.get(boundRole) end)
            end
        end
    end
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
Theme.packOrder = { "Dark", "Midnight", "AMOLED", "Light" }
local DEFAULTS = {}
for role, color in pairs(Theme.colors) do DEFAULTS[role] = color end
Theme.defaults = DEFAULTS
-- the "Neutral" accent for a pack (Light needs a dark one)
function Theme.neutral(pack) return pack == "Light" and rgb(70, 70, 80) or rgb(177, 178, 183) end
function Theme.applyPack(name)
    local pack = Theme.packs[name]
    if not pack then return false end
    local colors = {}
    for role, color in pairs(DEFAULTS) do if role ~= "accent" and role ~= "accentUser" then colors[role] = color end end
    for role, color in pairs(pack) do colors[role] = color end
    -- the neutral accent follows the pack; any other accent is kept
    local accent = Theme.colors.accentUser
    if accent == Theme.neutral("Dark") or accent == Theme.neutral("Light") then colors.accentUser = Theme.neutral(name) end
    Theme.pack = name
    Theme.setMany(colors)
    return true
end
Theme.pack = "Dark"

function Theme.onChange(callback)
    listeners[#listeners + 1] = callback
end

return Theme
