-- UI font. Every text object in a registered ScreenGui gets the chosen family; its weight (regular / medium /
-- semibold / bold) is kept. UIFont.set("Ubuntu"), UIFont.register(gui, maid).
-- The fonts are the .ttf files in this repo's fonts/files: downloaded once into QustahUI/fonts, each family
-- written as a font JSON next to them and shown through getcustomasset. Until they are there (or where the
-- executor has no getcustomasset) Roblox's own copy of the same family is used.
local Util = require("util")

local UIFont = { current = "Montserrat", guis = {} }

UIFont.order = { "Montserrat", "Ubuntu", "Work Sans", "Josefin Sans", "Michroma" }
UIFont.Source = "https://raw.githubusercontent.com/79650/gwanjkcdsjawbdnjascdas-ui-lib/refs/heads/main/qustah-ui-lib/fonts/files/"
UIFont.Folder = "QustahUI/fonts"
-- name -> its files (Regular and, where there is one, SemiBold)
UIFont.Files = {
    Montserrat = { Regular = "Montserrat-Regular.ttf", SemiBold = "Montserrat-SemiBold.ttf" },
    Ubuntu = { Regular = "Ubuntu-Regular.ttf", SemiBold = "Ubuntu-SemiBold.ttf" },
    ["Work Sans"] = { Regular = "WorkSans-Regular.ttf", SemiBold = "WorkSans-SemiBold.ttf" },
    ["Josefin Sans"] = { Regular = "JosefinSans-Regular.ttf", SemiBold = "JosefinSans-SemiBold.ttf" },
    Michroma = { Regular = "Michroma-Regular.ttf" },
}
-- Roblox's own copy of each family (before the download / without getcustomasset)
UIFont.Fallback = {
    Montserrat = "Montserrat", Ubuntu = "Ubuntu", ["Josefin Sans"] = "JosefinSans", Michroma = "Michroma",
    ["Work Sans"] = "rbxassetid://12187373327",
}
-- How big a font draws next to Gotham at the same size: its text is sized by 1 / this, so a wide font (Michroma)
-- doesn't push labels out of their rows. Code text has its own font.
UIFont.Fit = { Michroma = 1.12, ["Josefin Sans"] = 0.96 }
-- Code text (Code, Console, Log; marked with the QCode attribute) uses Roblox's monospace RobotoMono unless
-- CreateWindow({ CodeFont = "..." }) names another Enum.Font. Text marked QFixedFont keeps whatever font it has
-- (the font list draws each name in its own font).
UIFont.code = "RobotoMono"
-- Text size (Settings > Interface > Text size): every text's own size times this, rounded.
UIFont.textScale = 1
UIFont.downloaded = {} -- name -> getcustomasset id of its font JSON

-- the fonts this executor can show (all of them: nothing is downloaded)
function UIFont.available() return table.clone(UIFont.order) end

local function isText(object)
    return object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")
end

local function familyOf(name)
    name = tostring(name)
    if UIFont.downloaded[name] then return UIFont.downloaded[name] end
    local fallback = UIFont.Fallback[name] or name
    if fallback:match("^rbxasset") then return fallback end
    local ok, face = pcall(function() return Font.fromEnum(Enum.Font[fallback]) end)
    return ok and face and face.Family or nil
end

-- Downloads the font files once and writes a font JSON per family (faces: Regular for 100 - 400, SemiBold - or
-- Regular where there is none - for 500 - 900, so medium / bold text gets the heavier file). Then every text is
-- re-drawn in the downloaded font.
local function isFont(body)
    local magic = body:sub(1, 4)
    return magic == "\0\1\0\0" or magic == "true" or magic == "OTTO"
end
local started = false
-- (tests) start over: forget the downloaded fonts
function UIFont._resetDownload() started = false table.clear(UIFont.downloaded) end
function UIFont.download()
    if started then return end
    started = true
    local files = {}
    for _, name in ipairs(UIFont.order) do
        for _, file in pairs(UIFont.Files[name] or {}) do
            files[#files + 1] = { path = UIFont.Folder .. "/" .. file, url = UIFont.Source .. file, check = isFont }
        end
    end
    Util.cacheFiles(files, function(ids)
        local custom = getcustomasset or getsynasset
        local HttpService = Util.Services.HttpService
        for _, name in ipairs(UIFont.order) do
            local set = UIFont.Files[name]
            local regular = ids[UIFont.Folder .. "/" .. set.Regular]
            local heavy = set.SemiBold and ids[UIFont.Folder .. "/" .. set.SemiBold] or regular
            local faces = {}
            for _, weight in ipairs({ 100, 200, 300, 400, 500, 600, 700, 800, 900 }) do
                faces[#faces + 1] = { name = tostring(weight), weight = weight, style = "normal", assetId = weight <= 400 and regular or heavy }
            end
            local ok, err = pcall(function()
                local path = UIFont.Folder .. "/" .. name:gsub(" ", "") .. ".json"
                writefile(path, HttpService:JSONEncode({ name = name, faces = faces }))
                UIFont.downloaded[name] = custom(path)
            end)
            if not ok then Util.log("[qustah-ui-lib] font " .. name .. " could not be set up: " .. tostring(err)) end
        end
        UIFont.refresh()
    end, function(reason)
        if Util.canCustomAsset() then Util.log("[qustah-ui-lib] fonts could not be downloaded (" .. tostring(reason) .. "); using Roblox's copies") end
    end, "fonts")
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
    local fit = object:GetAttribute("QCode") and 1 or (UIFont.Fit[UIFont.current] or 1)
    if object:GetAttribute("QFixedFont") then fit = 1 end
    local base = object:GetAttribute("QBaseSize")
    if base == nil then
        if (UIFont.textScale == 1 and fit == 1) or object.TextSize <= 9 then return end
        base = object.TextSize
        object:SetAttribute("QBaseSize", base)
    end
    local size = math.max(6, math.floor(base * UIFont.textScale / fit + 0.5))
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
    UIFont.download()
end

return UIFont
