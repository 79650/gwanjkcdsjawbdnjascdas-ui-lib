-- UI font. Every text object in a registered ScreenGui gets the chosen family; its weight (regular / medium /
-- semibold / bold) is kept. UIFont.set("Poppins"), UIFont.register(gui, maid).
-- Gotham is Roblox's built-in default. Most fonts come from Roblox's own font library (Creator Marketplace) by
-- asset id, like WindUI does: nothing to download, they work in every executor. Vercel's Geist, Geist Mono and Geist
-- Pixel are not in that library: they download once (fonts/ in this repo, OFL) and are shown through getcustomasset,
-- so they are only offered where the executor has that.
local UIFont = { current = "Gotham", guis = {} }

UIFont.order = {
    "Gotham", "Inter", "Geist", "Geist Mono", "Geist Pixel",
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
-- downloaded (not in Roblox's library): name -> folder in fonts/, or { Folder =, Single = true } for one-weight fonts
UIFont.Downloadable = { Geist = "Geist", ["Geist Mono"] = "GeistMono", ["Geist Pixel"] = { Folder = "GeistPixel", Single = true } }
UIFont.Source = "https://raw.githubusercontent.com/79650/gwanjkcdsjawbdnjascdas-ui-lib/refs/heads/main/qustah-ui-lib/fonts/"
UIFont.Folder = "QustahUI/fonts"
UIFont.Version = 2
UIFont.onFailed = nil -- function(name, reason): set by the Settings tab to tell the user
local WEIGHTS = { { "Regular", 400 }, { "Medium", 500 }, { "SemiBold", 600 }, { "Bold", 700 } }
local loaded = {} -- downloadable name -> family id, false while loading, nil before
local shown = "Gotham" -- the font on screen (stays while a downloaded one is still on its way)

-- Code text (Code, Console, Log; marked with the QCode attribute) has its own monospace font, Sono Mono unless
-- CreateWindow({ CodeFont = "Geist Mono" }) asks for another. Text marked QFixedFont keeps whatever font it has
-- (the font list draws each name in its own font).
UIFont.code = "Sono Mono"
-- Text size (Settings > Interface > Text size): every text's own size times this, rounded.
UIFont.textScale = 1

local function canDownload() return require("util").canCustomAsset() end

-- the fonts this executor can show
function UIFont.available()
    local list = {}
    for _, name in ipairs(UIFont.order) do
        if not UIFont.Downloadable[name] or canDownload() then list[#list + 1] = name end
    end
    return list
end

-- (tests) forget downloaded families
function UIFont._reset() table.clear(loaded) end

local function isText(object)
    return object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")
end

local function familyOf(name)
    name = tostring(name)
    if UIFont.Library[name] then return "rbxassetid://" .. UIFont.Library[name] end
    if UIFont.Downloadable[name] then return loaded[name] or nil end
    local ok, face = pcall(function() return Font.fromEnum(Enum.Font[name]) end)
    return ok and face and face.Family or nil
end

-- Downloads a family's four weights once and writes a font-family file for them; done(ok, reason).
local function isFont(body) local head = body:sub(1, 4) return head == "\0\1\0\0" or head == "true" or head == "OTTO" end
local function loadFamily(name, done)
    local spec = UIFont.Downloadable[name]
    local dir = type(spec) == "table" and spec.Folder or spec
    local single = type(spec) == "table" and spec.Single
    local base = UIFont.Folder .. "/v" .. UIFont.Version .. "-" .. dir
    local files = {}
    for _, weight in ipairs(single and { WEIGHTS[1] } or WEIGHTS) do
        files[#files + 1] = { path = base .. "-" .. weight[1] .. ".ttf", url = UIFont.Source .. dir .. "/" .. dir .. "-" .. weight[1] .. ".ttf", check = isFont }
    end
    loaded[name] = false
    require("util").cacheFiles(files, function(ids)
        local ok, family = pcall(function()
            local faces = {}
            for index, weight in ipairs(WEIGHTS) do
                faces[index] = { name = weight[1], weight = weight[2], style = "normal", assetId = ids[files[single and 1 or index].path] }
            end
            writefile(base .. ".json", game:GetService("HttpService"):JSONEncode({ name = dir, faces = faces }))
            return (getcustomasset or getsynasset)(base .. ".json")
        end)
        if ok and type(family) == "string" and family ~= "" then
            loaded[name] = family
            done(true)
        else
            loaded[name] = nil
            done(false, tostring(family))
        end
    end, function(reason)
        loaded[name] = nil
        done(false, reason)
    end, "font (" .. name .. ")")
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

-- the family behind a font name (nil for a downloaded one that is not there yet)
function UIFont.family(name) return familyOf(name) end

-- Re-applies the current font to every registered gui (Gotham puts the library's own font back).
function UIFont.refresh()
    local target = familyOf(UIFont.current)
    if target then shown = UIFont.current else target = familyOf(shown) end -- (a downloaded family on its way: the shown font stays)
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
    if not table.find(UIFont.order, name) then return false end
    if UIFont.Downloadable[name] then
        if not canDownload() then return false end
        UIFont.current = name
        if loaded[name] then UIFont.refresh() return true end
        if loaded[name] == false then return true end -- already on its way
        local before = shown
        loadFamily(name, function(ok, reason)
            if ok then
                if UIFont.current == name then UIFont.refresh() end
            elseif UIFont.current == name then
                -- back to what was on screen before
                UIFont.current = before
                UIFont.refresh()
                if UIFont.onFailed then pcall(UIFont.onFailed, name, reason, before) end
            end
        end)
        return true
    end
    if not familyOf(name) then return false end
    UIFont.current = name
    UIFont.refresh()
    return true
end

-- The code font: a library font, or a downloaded one (Geist Mono) once it is there; Sono Mono meanwhile.
function UIFont.setCode(name)
    name = tostring(name or "Sono Mono")
    if not table.find(UIFont.order, name) then return false end
    if UIFont.Downloadable[name] then
        if not canDownload() then return false end
        if loaded[name] then UIFont.code = name UIFont.refresh() return true end
        if loaded[name] ~= false then
            loadFamily(name, function(ok) if ok then UIFont.code = name UIFont.refresh() end end)
        end
        return true
    end
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
            if shown == "Gotham" and UIFont.textScale == 1 and not object:GetAttribute("QCode") then return end
            apply(object, shown ~= "Gotham" and familyOf(shown) or nil)
        end)
    end)
    if maid then maid:give(connection) end
    task.defer(UIFont.refresh)
end

return UIFont
