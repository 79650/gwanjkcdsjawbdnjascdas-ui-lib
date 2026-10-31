-- UI font. Every text object in a registered ScreenGui gets the chosen family; its weight (regular / medium /
-- semibold / bold) is kept. UIFont.set("Montserrat"), UIFont.register(gui, maid).
local UIFont = { current = "Gotham", guis = {} }

UIFont.order = { "Gotham", "Inter", "Geist", "Manrope", "JetBrains Mono", "BuilderSans", "Montserrat", "Ubuntu", "Roboto", "SourceSans", "Nunito", "Arimo" }

-- Downloadable families (fonts/ in this repo, OFL, tools/gen_fonts.py): fetched once into QustahUI/fonts the first
-- time one is chosen, described in a font-family file and shown through getcustomasset. Without getcustomasset
-- they are not offered (UIFont.available()).
UIFont.Downloadable = { Inter = "Inter", Geist = "Geist", Manrope = "Manrope", ["JetBrains Mono"] = "JetBrainsMono" }
UIFont.Source = "https://raw.githubusercontent.com/79650/gwanjkcdsjawbdnjascdas-ui-lib/refs/heads/main/qustah-ui-lib/fonts/"
UIFont.Folder = "QustahUI/fonts"
UIFont.Version = 1
local WEIGHTS = { { "Regular", 400 }, { "Medium", 500 }, { "SemiBold", 600 }, { "Bold", 700 } }
local loaded = {} -- name -> family id, false while loading, nil before
UIFont.onFailed = nil -- function(name, reason): set by the Settings tab to tell the user

local function canDownload() return require("util").canCustomAsset() end

function UIFont.available()
    local list = {}
    for _, name in ipairs(UIFont.order) do
        if not UIFont.Downloadable[name] or canDownload() then list[#list + 1] = name end
    end
    return list
end

-- (tests) forget loaded families
function UIFont._reset() table.clear(loaded) end

local function isText(object)
    return object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")
end

local function familyOf(name)
    if UIFont.Downloadable[name] then return loaded[name] or nil end
    local ok, face = pcall(function() return Font.fromEnum(Enum.Font[name]) end)
    return ok and face and face.Family or nil
end

-- Loads a downloadable family; done(true) when it can be used, done(false, reason) when not.
local function isFont(body) local head = body:sub(1, 4) return head == "\0\1\0\0" or head == "true" or head == "OTTO" end
local function loadFamily(name, done)
    local dir = UIFont.Downloadable[name]
    local base = UIFont.Folder .. "/v" .. UIFont.Version .. "-" .. dir
    local files = {}
    for _, weight in ipairs(WEIGHTS) do
        files[#files + 1] = { path = base .. "-" .. weight[1] .. ".ttf", url = UIFont.Source .. dir .. "/" .. dir .. "-" .. weight[1] .. ".ttf", check = isFont }
    end
    loaded[name] = false
    require("util").cacheFiles(files, function(ids)
        -- a font-family file pointing at the four weights, itself shown through getcustomasset
        local ok, family = pcall(function()
            local faces = {}
            for index, weight in ipairs(WEIGHTS) do
                faces[index] = { name = weight[1], weight = weight[2], style = "normal", assetId = ids[files[index].path] }
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
    end)
end

local function apply(object, target)
    if not target or not isText(object) then return end
    pcall(function()
        local face = object.FontFace
        if face.Family ~= target then object.FontFace = Font.new(target, face.Weight, face.Style) end
    end)
end

-- Re-applies the current font to every registered gui (Gotham puts the library's own font back).
function UIFont.refresh()
    local target = familyOf(UIFont.current)
    if not target then return end -- a downloadable family still loading
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
        loadFamily(name, function(ok, reason)
            if ok then
                if UIFont.current == name then UIFont.refresh() end
            elseif UIFont.current == name then
                UIFont.current = "Gotham"
                UIFont.refresh()
                if UIFont.onFailed then pcall(UIFont.onFailed, name, reason) end
            end
        end)
        return true
    end
    if not familyOf(name) then return false end
    UIFont.current = name
    UIFont.refresh()
    return true
end

function UIFont.register(gui, maid)
    if UIFont.guis[gui] then return end
    UIFont.guis[gui] = true
    local connection = gui.DescendantAdded:Connect(function(object)
        if UIFont.current == "Gotham" or not isText(object) then return end
        -- deferred: creators may still set FontFace (e.g. SemiBold) right after parenting
        task.defer(function()
            if object.Parent then apply(object, familyOf(UIFont.current)) end
        end)
    end)
    if maid then maid:give(connection) end
    if UIFont.current ~= "Gotham" then task.defer(UIFont.refresh) end
end

return UIFont
