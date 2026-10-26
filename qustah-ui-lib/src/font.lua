-- UI font. Every text object in a registered ScreenGui gets the chosen family; its weight (regular / medium /
-- semibold / bold) is kept. UIFont.set("Montserrat"), UIFont.register(gui, maid).
local UIFont = { current = "Gotham", guis = {} }

UIFont.order = { "Gotham", "BuilderSans", "Montserrat", "Ubuntu", "Roboto", "SourceSans", "Nunito", "Arimo" }

local function isText(object)
    return object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")
end

local function familyOf(name)
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
