-- UI font. Every text object in a registered ScreenGui gets the chosen family; its weight (regular / medium /
-- semibold / bold) is kept. UIFont.set("Ubuntu"), UIFont.register(gui, maid).
-- The fonts are Roblox's own font families (UIFont.Families: built in or an rbxassetid), so nothing is downloaded.
local Util = require("util")

local UIFont = { current = "Jura", guis = {} }

UIFont.order = { "Jura", "Ubuntu", "Roboto", "Michroma", "Josefin Sans" }
-- name -> its Roblox font family: a built-in family's name for Font.fromName (letters only, no spaces) or a font
-- library asset id for Font.fromId
UIFont.Families = { Ubuntu = "Ubuntu", Jura = "Jura", Roboto = "Roboto", Michroma = "Michroma", ["Josefin Sans"] = "JosefinSans" }
-- the text size (Settings › Text size) a font starts with when it is picked; the size can be changed after
UIFont.DefaultSize = { Ubuntu = "Normal", Jura = "Large", Roboto = "Normal", Michroma = "Normal", ["Josefin Sans"] = "Small" }
-- How big a font draws next to Gotham at the same size: its text is sized by 1 / this, so a wide font (Michroma)
-- doesn't push labels out of their rows. Code text has its own font.
UIFont.Fit = { Michroma = 1.12, ["Josefin Sans"] = 0.96 }
-- Code text (Code, Console, Log; marked with the QCode attribute) uses Roblox's monospace RobotoMono unless
-- CreateWindow({ CodeFont = "..." }) names another Enum.Font. Text marked QFixedFont keeps whatever font it has
-- (the font list draws each name in its own font).
UIFont.code = "RobotoMono"
-- Text size (Settings > Interface > Text size): every text's own size times this, rounded.
UIFont.textScale = 1

-- the fonts this executor can show (all of them: nothing is downloaded)
function UIFont.available() return table.clone(UIFont.order) end

local function isText(object)
    return object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")
end

local function familyOf(name)
    name = tostring(name)
    local family = UIFont.Families[name] or name
    if type(family) == "number" then
        local ok, face = pcall(Font.fromId, family)
        return ok and face and face.Family or nil
    end
    if family:match("^rbxasset") then return family end
    local ok, face = pcall(Font.fromName, family)
    if not (ok and face) then ok, face = pcall(function() return Font.fromEnum(Enum.Font[family]) end) end
    return ok and face and face.Family or nil
end

-- the family an icon name's text should use: the font list's own faces stay, code text gets the code font
local function targetFor(object, uiTarget)
    if object:GetAttribute("QFixedFont") then return nil end
    if object:GetAttribute("QCode") then return familyOf(UIFont.code) end
    return uiTarget
end

-- Readable sizes: the lib's elements are written with small sizes (8 - 12 px); each is drawn a step bigger so small
-- print stays legible (8 and 9 -> 10, 10 -> 11, 11 -> 12, 12 -> 13), then the text size setting and the wide-font fit
-- apply. Text sized to a fixed box (QNoScale: rolling digits, range values) keeps its size.
UIFont.Readable = { [7] = 9, [8] = 10, [9] = 10, [10] = 11, [11] = 12, [12] = 13 }
-- Text drawn at this size or smaller is at least Medium: thin strokes of small regular text fade into the
-- background and the letters look unevenly spaced.
UIFont.MediumBelow = 11
function UIFont.drawnSize(base, fixedFit)
    base = tonumber(base) or 10
    local fit = fixedFit or UIFont.Fit[UIFont.current] or 1
    return math.max(6, math.floor((UIFont.Readable[base] or base) * UIFont.textScale / fit + 0.5))
end
local function scaleText(object)
    if object:GetAttribute("QNoScale") then return end
    local fit = object:GetAttribute("QCode") and 1 or (UIFont.Fit[UIFont.current] or 1)
    if object:GetAttribute("QFixedFont") then fit = 1 end
    local base = object:GetAttribute("QBaseSize")
    if base == nil then
        base = object.TextSize
        object:SetAttribute("QBaseSize", base)
    end
    local size = UIFont.drawnSize(base, fit)
    if object.TextSize ~= size then object.TextSize = size end
end

local function apply(object, uiTarget)
    if not isText(object) then return end
    pcall(scaleText, object)
    local target = targetFor(object, uiTarget)
    if not target then return end
    pcall(function()
        local face = object.FontFace
        if not face then object.FontFace = Font.new(target) return end
        -- the weight it was made with (kept, so a bigger text size can give the regular weight back)
        local weight = face.Weight
        local okName, name = pcall(function() return object:GetAttribute("QBaseWeight") or face.Weight.Name end)
        if okName and name then
            if object:GetAttribute("QBaseWeight") == nil then object:SetAttribute("QBaseWeight", name) end
            weight = Enum.FontWeight[name] or face.Weight
            local okSmall, small = pcall(function()
                return object.TextSize <= UIFont.MediumBelow and weight.Value < Enum.FontWeight.Medium.Value and not object:GetAttribute("QCode")
            end)
            if okSmall and small then weight = Enum.FontWeight.Medium end
        end
        if face.Family ~= target or face.Weight ~= weight then object.FontFace = Font.new(target, weight, face.Style) end
    end)
end

-- the family behind a font name (a library id or a built-in Enum.Font)
function UIFont.family(name) return familyOf(name) end

-- Things that lay out by text width (the window, segments, header buttons...) call UIFont.onChange(fn): fn runs
-- after the font, the text size or a font's measured width changes. Returns a function that stops it.
local listeners = {}
function UIFont.onChange(fn)
    listeners[fn] = true
    return function() listeners[fn] = nil end
end
local pendingChange = false
local function changed()
    if pendingChange then return end
    pendingChange = true
    task.defer(function()
        pendingChange = false
        for fn in pairs(listeners) do Util.safe(fn) end
    end)
end
UIFont._changed = changed
-- How much bigger than written a text of this size is drawn now (the text size setting, the wide-font fit; 9 px
-- and under keep their size), the same way scaleText applies it.
function UIFont.drawnScale(size)
    size = tonumber(size) or 10
    return UIFont.drawnSize(size) / size
end

-- Real text widths: every printable ASCII character of the font in use measured once per weight (Regular, Medium,
-- Bold) with TextService:GetTextBoundsAsync, in that font itself. Until a font's table is there (it is measured on
-- its own thread: the call yields, a moment after start) Util.textWidth uses Roblox's Gotham width at the drawn size;
-- every listener (UIFont.onChange) lays out again when it arrives.
local glyphs = {} -- family .. "\0" .. weight -> { [codepoint] = width at size 100 } (false while measuring)
local GLYPH_WEIGHTS = { "Regular", "Medium", "Bold" }
function UIFont.measureGlyphs(name)
    local family = familyOf(name or UIFont.current)
    if not family then return end
    for _, weightName in ipairs(GLYPH_WEIGHTS) do
        local key = family .. "\0" .. weightName
        if glyphs[key] == nil then
            glyphs[key] = false
            task.spawn(function()
                local TextService = Util.Services.TextService
                local face = Font.new(family, Enum.FontWeight[weightName])
                local function width(text)
                    local params = Instance.new("GetTextBoundsParams")
                    params.Text, params.Font, params.Size, params.Width = text, face, 100, 100000
                    return TextService:GetTextBoundsAsync(params).X
                end
                local ok, made = pcall(function()
                    local widths = {}
                    for code = 33, 126 do widths[code] = width(string.char(code)) end
                    widths[32] = math.max(0, width("a a") - width("aa")) -- (a lone space measures 0)
                    return widths
                end)
                if ok then
                    glyphs[key] = made
                    changed()
                end
            end)
        end
    end
end
-- the weight a text of this Enum font and drawn size has on screen (see apply: small regular text is Medium)
local function weightOf(font, drawn)
    local name = typeof(font) == "EnumItem" and font.Name or ""
    if name:find("Bold") or name:find("Black") or name:find("Heavy") then return "Bold" end
    if name:find("Medium") or name:find("Semibold") then return "Medium" end
    return drawn <= UIFont.MediumBelow and "Medium" or "Regular"
end
-- width of `text` written at `size` (the size the lib gives it: drawn bigger by the readable steps and the text size
-- setting) in the font in use, or nil while that font is not measured yet
function UIFont.textWidth(text, size, font)
    local family = familyOf(UIFont.current)
    if not family then return nil end
    size = tonumber(size) or 10
    local drawn = UIFont.drawnSize(size)
    local widths = glyphs[family .. "\0" .. weightOf(font, drawn)]
    if not widths then return nil end
    local total, fallback = 0, widths[111] or 55 -- (a character outside ASCII: about an "o")
    local ok = pcall(function()
        for _, code in utf8.codes(tostring(text)) do total = total + (widths[code] or fallback) end
    end)
    if not ok then return nil end
    return total * drawn / 100
end

-- Re-applies the current font to every registered gui.
function UIFont.refresh()
    local target = familyOf(UIFont.current)
    for gui in pairs(UIFont.guis) do
        if gui.Parent then
            for _, object in ipairs(gui:GetDescendants()) do apply(object, target) end
        else
            UIFont.guis[gui] = nil
        end
    end
    UIFont.measureGlyphs(UIFont.current)
    changed()
end

function UIFont.set(name)
    name = tostring(name or "Jura")
    if not table.find(UIFont.order, name) or not familyOf(name) then return false end
    UIFont.current = name
    UIFont.refresh()
    return true
end

-- The code font (an Enum.Font name; RobotoMono unless CreateWindow({ CodeFont = "..." }) picks another).
function UIFont.setCode(name)
    name = tostring(name or "RobotoMono")
    if not familyOf(name) then return false end
    UIFont.code = name
    UIFont.refresh()
    return true
end

-- Text size: 0.9 small, 1 normal, 1.1 large (every text's own size times this).
function UIFont.setTextScale(scale)
    UIFont.textScale = math.clamp(tonumber(scale) or 1, 0.7, 1.4)
    UIFont.refresh()
end

function UIFont.register(gui, maid)
    if UIFont.guis[gui] then return end
    UIFont.guis[gui] = true
    local connection = gui.DescendantAdded:Connect(function(object)
        if not isText(object) then return end
        -- deferred: creators may still set FontFace (e.g. SemiBold) or the QCode / QFixedFont marks right after parenting
        task.defer(function()
            if not object.Parent then return end
            apply(object, familyOf(UIFont.current))
        end)
    end)
    if maid then maid:give(connection) end
    task.defer(UIFont.refresh)
end

return UIFont
