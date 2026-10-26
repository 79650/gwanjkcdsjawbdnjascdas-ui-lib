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

function Theme.onChange(callback)
    listeners[#listeners + 1] = callback
end

return Theme
