-- UI font. Every text object in a registered ScreenGui gets the chosen family; its weight (regular / medium /
-- semibold / bold) is kept. UIFont.set("Poppins"), UIFont.register(gui, maid).
-- Gotham is Roblox's built-in default; every other font comes from Roblox's own font library (Creator Marketplace)
-- by asset id, like WindUI does: nothing to download, they work in every executor.
local UIFont = { current = "Gotham", guis = {} }

UIFont.order = {
    "Gotham", "Inter",
    -- clean
    "Work Sans", "Nunito Sans", "Poppins", "Rubik", "Fira Sans",
    -- with some character (pixel, bubble, rounded, soft, terminal)
    "Silkscreen", "Fuzzy Bubbles", "M PLUS Rounded", "Quicksand", "Sono Mono",
}
UIFont.Library = {
    Inter = 12187365364, ["Work Sans"] = 12187373327, ["Nunito Sans"] = 12187363368, Poppins = 11702779409,
    Rubik = 12187365977, ["Fira Sans"] = 12187374954, Silkscreen = 12187371840, ["Fuzzy Bubbles"] = 11322590111,
    ["M PLUS Rounded"] = 12188570269, Quicksand = 12187371324, ["Sono Mono"] = 12187362578,
}
-- Code text (Code, Console, Log; marked with the QCode attribute) has its own monospace font, Sono Mono unless
-- CreateWindow({ CodeFont = "Silkscreen" }) asks for another. Text marked QFixedFont keeps whatever font it has
-- (the font list draws each name in its own font).
UIFont.code = "Sono Mono"
-- Text size (Settings > Interface > Text size): every text's own size times this, rounded.
UIFont.textScale = 1

-- the fonts this executor can show (all of them: nothing is downloaded)
function UIFont.available() return table.clone(UIFont.order) end

local function isText(object)
    return object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")
end

local function familyOf(name)
    name = tostring(name)
    if UIFont.Library[name] then return "rbxassetid://" .. UIFont.Library[name] end
    local ok, face = pcall(function() return Font.fromEnum(Enum.Font[name]) end)
    return ok and face and face.Family or nil
end

-- the family an icon name's text should use: the font list's own faces stay, code text gets the code font
local function targetFor(object, uiTarget)
    if object:GetAttribute("QFixedFont") then return nil end
    if object:GetAttribute("QCode") then return familyOf(UIFont.code) end
    return uiTarget
end

-- Small print (9 px and under: badges, tags, captions) and text sized to a fixed box (QNoScale: rolling digits,
-- range values) keep their size; everything else grows or shrinks with the setting.
local function scaleText(object)
    if object:GetAttribute("QNoScale") then return end
    local base = object:GetAttribute("QBaseSize")
    if base == nil then
        if UIFont.textScale == 1 or object.TextSize <= 9 then return end
        base = object.TextSize
        object:SetAttribute("QBaseSize", base)
    end
    local size = math.max(6, math.floor(base * UIFont.textScale + 0.5))
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
        if face.Family ~= target then object.FontFace = Font.new(target, face.Weight, face.Style) end
    end)
end

-- the family behind a font name (a library id or a built-in Enum.Font)
function UIFont.family(name) return familyOf(name) end

-- Re-applies the current font to every registered gui (Gotham puts the library's own font back).
function UIFont.refresh()
    local target = familyOf(UIFont.current)
    for gui in pairs(UIFont.guis) do
        if gui.Parent then
            for _, object in ipairs(gui:GetDescendants()) do apply(object, target) end
        else
            UIFont.guis[gui] = nil
        end
    end
end

function UIFont.set(name)
    name = tostring(name or "Gotham")
    if not table.find(UIFont.order, name) or not familyOf(name) then return false end
    UIFont.current = name
    UIFont.refresh()
    return true
end

-- The code font (a library font; Sono Mono unless CreateWindow({ CodeFont = "..." }) picks another).
function UIFont.setCode(name)
    name = tostring(name or "Sono Mono")
    if not table.find(UIFont.order, name) or not familyOf(name) then return false end
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
            if UIFont.current == "Gotham" and UIFont.textScale == 1 and not object:GetAttribute("QCode") then return end
            apply(object, UIFont.current ~= "Gotham" and familyOf(UIFont.current) or nil)
        end)
    end)
    if maid then maid:give(connection) end
    task.defer(UIFont.refresh)
end

return UIFont
