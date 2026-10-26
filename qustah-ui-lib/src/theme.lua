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
}

-- Roles computed from the accent.
local function derive()
    local colors = Theme.colors
    colors.accentDeep = colors.base:Lerp(colors.accent, 0.12) -- selected dock button / indicator fill
    colors.toggleOn = colors.input:Lerp(colors.accent, 0.42)
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
    Theme.colors[role] = color
    if role == "accent" or role == "base" or role == "input" then derive() end
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
    for role, color in pairs(colors) do if typeof(color) == "Color3" then Theme.colors[role] = color end end
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
    for role, color in pairs(DEFAULTS) do if role ~= "accent" then colors[role] = color end end
    for role, color in pairs(pack) do colors[role] = color end
    -- the neutral accent follows the pack; any other accent is kept
    local accent = Theme.colors.accent
    if accent == Theme.neutral("Dark") or accent == Theme.neutral("Light") then colors.accent = Theme.neutral(name) end
    Theme.pack = name
    Theme.setMany(colors)
    return true
end
Theme.pack = "Dark"

function Theme.onChange(callback)
    listeners[#listeners + 1] = callback
end

return Theme
