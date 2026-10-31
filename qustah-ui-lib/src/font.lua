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

function UIFont.available() return table.clone(UIFont.order) end

local function isText(object)
    return object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")
end

local function familyOf(name)
    if UIFont.Library[name] then return "rbxassetid://" .. UIFont.Library[name] end
    local ok, face = pcall(function() return Font.fromEnum(Enum.Font[name]) end)
    return ok and face and face.Family or nil
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
    if not target then return end
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
