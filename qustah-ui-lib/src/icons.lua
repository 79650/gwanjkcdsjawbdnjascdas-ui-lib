-- Icons: names instead of asset ids, anywhere the library takes an Icon.
--   Icon = "house"                  default set (lucide, built in - 1700+ icons)
--   Icon = "solar:home-bold"        another set: lucide, solar, sfsymbols, gravity, geist, craft
--   Icon = "rbxassetid://123" / 123 a plain image
-- Sets other than lucide download once on first use (from this repo's icons/ folder; Footagesus/Icons, MIT).
--   Lib.Icons.Get(name)             -> { Image, RectSize, RectOffset, Parts } or nil
--   Lib.Icons.Apply(imageLabel, name) -> true when the icon was found
--   Lib.Icons.Image(name, { Size, Color }) -> ImageLabel
--   Lib.Icons.SetDefault("solar"), Lib.Icons.Add("mine", { ["skull"] = "rbxassetid://..." }), Lib.Icons.List(set)
local Icons = {
    Default = "lucide",
    Source = "https://raw.githubusercontent.com/79650/gwanjkcdsjawbdnjascdas-ui-lib/refs/heads/main/qustah-ui-lib/icons/",
    Remote = { solar = true, sfsymbols = true, gravity = true, geist = true, craft = true },
    Sets = {},
    _failed = {},
}

local Theme = require("theme")

-- lucide is embedded as name -> asset number
Icons.Sets.lucide = require("icons_lucide")

local ZERO = Vector2.new(0, 0)

-- Downloads a set (once). Returns true or false, reason.
function Icons.Load(set)
    if Icons.Sets[set] then return true end
    if not Icons.Remote[set] then return false, "unknown icon set " .. tostring(set) end
    if Icons._failed[set] then return false, Icons._failed[set] end
    local ok, data = pcall(function()
        local source = game:HttpGet(Icons.Source .. set .. ".lua")
        return loadstring(source)()
    end)
    if not ok or type(data) ~= "table" then
        Icons._failed[set] = tostring(data)
        require("util").log("[qustah-ui-lib] icon set " .. set .. " could not be loaded: " .. tostring(data))
        return false, Icons._failed[set]
    end
    Icons.Sets[set] = data
    return true
end

local function asset(value)
    if type(value) == "number" then return "rbxassetid://" .. value end
    return tostring(value)
end

local function lookup(set, name)
    local data = Icons.Sets[set]
    if not data then return nil end
    -- spritesheet sets: { Spritesheets = { ["1"] = id }, Icons = { name = { Image = 1, ImageRectPosition, ImageRectSize, Parts } } }
    if type(data.Icons) == "table" and type(data.Spritesheets) == "table" then
        local icon = data.Icons[name]
        if not icon then return nil end
        local parts
        for _, part in ipairs(icon.Parts or {}) do
            parts = parts or {}
            parts[#parts + 1] = lookup(set, part)
        end
        return {
            Image = asset(data.Spritesheets[tostring(icon.Image)] or icon.Image),
            RectSize = icon.ImageRectSize or ZERO, RectOffset = icon.ImageRectPosition or ZERO, Parts = parts,
        }
    end
    local value = data[name]
    if value == nil then return nil end
    return { Image = asset(value), RectSize = ZERO, RectOffset = ZERO }
end

function Icons.Get(name)
    if name == nil or name == "" then return nil end
    if type(name) == "number" or (type(name) == "string" and name:match("^%d+$")) then
        return { Image = "rbxassetid://" .. tostring(name), RectSize = ZERO, RectOffset = ZERO }
    end
    name = tostring(name)
    if name:match("^https?://") and not name:find("roblox%.com") then
        -- a picture on the web (logo...): downloaded once, shown through getcustomasset; not tinted
        return { Image = Icons._urls[name] or "", RectSize = ZERO, RectOffset = ZERO, Url = name }
    end
    if name:match("^rbxasset") or name:match("^https?://") then
        return { Image = name, RectSize = ZERO, RectOffset = ZERO }
    end
    local set, icon = name:match("^([%w_%-]+):(.+)$")
    if not set then set, icon = Icons.Default, name end
    set = set:lower()
    if not Icons.Sets[set] then Icons.Load(set) end
    return lookup(set, icon) or (set ~= "lucide" and not name:find(":") and lookup("lucide", icon)) or nil
end

-- Web images: request + writefile + getcustomasset (cached per url for the session and on disk).
Icons._urls = {}
Icons.Folder = "QustahUI/assets"
local function fetch(url, done)
    if Icons._urls[url] then return done(Icons._urls[url]) end
    task.spawn(function()
        local ok, asset = pcall(function()
            local name = url:match("([^/?#]+)[?#]?[^/]*$") or "image"
            name = name:gsub("%.[^%.]+$", ""):gsub("[^%w%-_]", "_"):sub(1, 40)
            local file = Icons.Folder .. "/" .. name .. "-" .. #url .. ".png"
            if not (isfile and isfile(file)) then
                local request = (syn and syn.request) or http_request or request
                local body
                if request then body = request({ Url = url, Method = "GET" }).Body else body = game:HttpGet(url) end
                assert(type(body) == "string" and #body > 0, "empty response")
                if makefolder and isfolder then
                    if not isfolder("QustahUI") then makefolder("QustahUI") end
                    if not isfolder(Icons.Folder) then makefolder(Icons.Folder) end
                end
                writefile(file, body)
            end
            return (getcustomasset or getsynasset)(file)
        end)
        if ok and asset then
            Icons._urls[url] = asset
            done(asset)
        else
            require("util").log("[qustah-ui-lib] image " .. url .. " could not be loaded: " .. tostring(asset))
        end
    end)
end

-- Puts the icon on an ImageLabel / ImageButton (two-tone icons get their extra parts as children).
function Icons.Apply(image, name)
    for _, child in ipairs(image:GetChildren()) do if child.Name == "IconPart" then child:Destroy() end end
    local icon = Icons.Get(name)
    if not icon then return false end
    if icon.Url then
        image.ImageColor3 = Color3.new(1, 1, 1)
        image.ImageRectSize, image.ImageRectOffset = ZERO, ZERO
        fetch(icon.Url, function(asset) image.Image = asset end)
        return true
    end
    image.Image = icon.Image
    image.ImageRectSize = icon.RectSize
    image.ImageRectOffset = icon.RectOffset
    for _, part in ipairs(icon.Parts or {}) do
        local child = Instance.new("ImageLabel")
        child.Name = "IconPart"
        child.BackgroundTransparency = 1
        child.Size = UDim2.fromScale(1, 1)
        child.Image, child.ImageRectSize, child.ImageRectOffset = part.Image, part.RectSize, part.RectOffset
        child.ImageTransparency = 0.5 -- second tone
        child.ZIndex = image.ZIndex
        child.Parent = image
        -- the part follows the icon's colour
        child.ImageColor3 = image.ImageColor3
        image:GetPropertyChangedSignal("ImageColor3"):Connect(function() child.ImageColor3 = image.ImageColor3 end)
    end
    return true
end

function Icons.Image(name, props)
    props = props or {}
    local image = Instance.new("ImageLabel")
    image.Name = props.Name or "Icon"
    image.BackgroundTransparency = 1
    image.ScaleType = Enum.ScaleType.Fit
    image.Size = props.Size or UDim2.fromOffset(16, 16)
    if typeof(props.Color) == "Color3" then image.ImageColor3 = props.Color end
    Icons.Apply(image, name)
    image.Parent = props.Parent
    return image
end

-- Library use: an icon whose colour follows a theme role (nil when the name is not an icon).
function Icons.themed(parent, name, size, role, props)
    if not Icons.Get(name) then return nil end
    local image = Icons.Image(name, { Size = UDim2.fromOffset(size, size), Name = props and props.Name or "Icon" })
    for key, value in pairs(props or {}) do if key ~= "Name" then image[key] = value end end
    -- web images keep their own colours
    if not Icons.Get(name).Url then Theme.bind(image, "ImageColor3", role or "text") end
    image.Parent = parent
    return image
end

function Icons.SetDefault(set)
    set = tostring(set):lower()
    if Icons.Sets[set] or Icons.Load(set) then Icons.Default = set return true end
    return false
end

function Icons.Add(set, data)
    set = tostring(set):lower()
    Icons.Sets[set] = Icons.Sets[set] or {}
    for name, value in pairs(data) do Icons.Sets[set][name] = value end
end

function Icons.List(set)
    set = tostring(set or Icons.Default):lower()
    if not Icons.Sets[set] then Icons.Load(set) end
    local data = Icons.Sets[set] or {}
    local names = {}
    for name in pairs(type(data.Icons) == "table" and data.Icons or data) do
        if type(name) == "string" then names[#names + 1] = name end
    end
    table.sort(names)
    return names
end

return Icons
