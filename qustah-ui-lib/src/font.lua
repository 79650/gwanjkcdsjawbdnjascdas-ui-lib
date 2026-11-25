-- UI font. Every text object in a registered ScreenGui gets the chosen family; its weight (regular / medium /
-- semibold / bold) is kept. UIFont.set("Ubuntu"), UIFont.register(gui, maid).
-- The fonts are Roblox's own font families (UIFont.Families: built in or an rbxassetid), so nothing is downloaded.
local Util = require("util")

local UIFont = { current = "Montserrat", guis = {} }

UIFont.order = { "Montserrat", "Ubuntu", "Work Sans", "Josefin Sans", "Michroma" }
-- name -> its Roblox font family: built into the client (rbxasset) or from Roblox's font library (rbxassetid)
UIFont.Families = {
    Montserrat = "rbxasset://fonts/families/Montserrat.json", Ubuntu = "rbxasset://fonts/families/Ubuntu.json",
    ["Josefin Sans"] = "rbxasset://fonts/families/JosefinSans.json", Michroma = "rbxasset://fonts/families/Michroma.json",
    ["Work Sans"] = "rbxassetid://12187373327",
}
-- How big a font draws next to Gotham at the same size: its text is sized by 1 / this, so a wide font (Michroma)
-- doesn't push labels out of their rows. Code text has its own font.
UIFont.Fit = { Michroma = 1.12, ["Josefin Sans"] = 0.96 }
-- How wide each font's text is next to Gotham's at the same size (regular / medium-and-heavier text): the lib
-- measures its labels with Gotham (Util.textWidth) and scales by this. These are estimates; the real ratios are
-- measured once a font is in use (UIFont.measure), and every listener (UIFont.onChange) lays out again then.
UIFont.Width = {
    Montserrat = { regular = 1.08, heavy = 1.08 }, Ubuntu = { regular = 0.97, heavy = 0.98 }, ["Work Sans"] = { regular = 1.0, heavy = 1.01 },
    ["Josefin Sans"] = { regular = 0.9, heavy = 0.92 }, Michroma = { regular = 1.32, heavy = 1.32 },
}
UIFont.measured = {}
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
    if family:match("^rbxasset") then return family end
    local ok, face = pcall(function() return Font.fromEnum(Enum.Font[family]) end)
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
-- How much wider than Gotham a text of this Enum font and size is drawn now: the font's width ratio for its weight
-- class, and the text size setting / wide-font fit the same way scaleText applies them (9 px and under keep size).
function UIFont.widthFactor(font, size)
    local ratio = UIFont.Width[UIFont.current]
    size = tonumber(size) or 10
    local drawn = UIFont.drawnSize(size)
    local heavy = drawn <= UIFont.MediumBelow or (font ~= Enum.Font.Gotham and font ~= Enum.Font.GothamLight and font ~= Enum.Font.SourceSans)
    local factor = ratio and (heavy and ratio.heavy or ratio.regular) or 1
    return factor * drawn / size
end

-- Measures a font's real width next to Gotham (TextService:GetTextBoundsAsync can wait while the font loads, so this
-- runs on its own thread, once per font) and lays everything out again with it.
local SAMPLE = "The quick brown fox jumps over 1234567890 lazy dogs"
function UIFont.measure(name)
    name = tostring(name or UIFont.current)
    local family = familyOf(name)
    local key = name .. "\0" .. tostring(family)
    if not family or UIFont.measured[key] then return end
    UIFont.measured[key] = true
    task.spawn(function()
        local TextService = Util.Services.TextService
        local function width(face)
            local params = Instance.new("GetTextBoundsParams")
            params.Text, params.Font, params.Size, params.Width = SAMPLE, face, 100, 100000
            return TextService:GetTextBoundsAsync(params).X
        end
        local gotham = Font.fromEnum(Enum.Font.Gotham).Family
        local ok, result = pcall(function()
            local regular = width(Font.new(family, Enum.FontWeight.Regular)) / width(Font.new(gotham, Enum.FontWeight.Regular))
            local heavy = width(Font.new(family, Enum.FontWeight.SemiBold)) / width(Font.new(gotham, Enum.FontWeight.Medium))
            return { regular = regular, heavy = heavy }
        end)
        if ok and result.regular > 0.3 and result.regular < 3 and result.heavy > 0.3 and result.heavy < 3 then
            UIFont.Width[name] = result
            changed()
        end
    end)
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
    UIFont.measure(UIFont.current)
    changed()
end

function UIFont.set(name)
    name = tostring(name or "Montserrat")
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
