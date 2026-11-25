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
local Util = require("util")

-- lucide is embedded as name, asset number pairs
do
    local list, set = require("icons_lucide"), {}
    for i = 1, #list, 2 do set[list[i]] = list[i + 1] end
    Icons.Sets.lucide = set
end

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
    local found = lookup(set, icon) or (set ~= "lucide" and not name:find(":") and lookup("lucide", icon))
    if found then return found end
    -- an icon that only a script's own sheet has (a hand drawing such as "frog"): Apply draws it from the sheet
    if not name:find(":") and Icons._sheetHas(name) then return { Image = "", RectSize = ZERO, RectOffset = ZERO } end
    return nil
end
Icons._sheetHas = function() return false end -- (set once the sheets below exist)

-- Web images: request + writefile + getcustomasset (cached per url for the session and on disk).
Icons._urls = {}
Icons.Folder = "QustahUI/assets"
local function fetch(url, done)
    if Icons._urls[url] then return done(Icons._urls[url]) end
    local name = (url:match("([^/?#]+)[?#]?[^/]*$") or "image"):gsub("%.[^%.]+$", ""):gsub("[^%w%-_]", "_"):sub(1, 32)
    local path = Icons.Folder .. "/" .. name .. "-" .. Util.hash(url) .. ".png"
    Util.cacheFiles({ { path = path, url = url } }, function(ids)
        Icons._urls[url] = ids[path]
        done(ids[path])
    end, function(reason)
        Util.log("[qustah-ui-lib] image " .. url .. " could not be loaded: " .. tostring(reason))
    end)
end

-- The lib's own icons (icons_qustah: drawn pixel for pixel at every size it uses) come from its sheet, downloaded
-- once into QustahUI/icons and shown through getcustomasset. Every other icon (lucide and the other sets) is a Roblox
-- asset id: nothing else is downloaded. A script can also pass "rbxassetid://..." or a number as an icon.
-- Lib.Icons.Sharp = false before the first window keeps the sheet off too (asset ids only).
Icons.Sharp = true
Icons.SheetFolder = "QustahUI/icons"
Icons.SheetSource = "https://raw.githubusercontent.com/79650/gwanjkcdsjawbdnjascdas-ui-lib/refs/heads/main/qustah/icons/"
local sharpImages = setmetatable({}, { __mode = "k" }) -- image -> sheet icon name, so it is re-drawn when the sheet is there
local applySharp
local queueSnap

-- A sheet's files in SheetFolder (as <prefix><file>), downloaded once; done(ids by file name).
local function isPng(body) return body:sub(2, 4) == "PNG" end
local function loadFiles(prefix, source, files, done)
    local list = {}
    for _, file in ipairs(files) do
        list[#list + 1] = { path = Icons.SheetFolder .. "/" .. prefix .. file, url = source .. file, check = isPng, name = file }
    end
    Util.cacheFiles(list, function(ids)
        local byName = {}
        for _, file in ipairs(list) do byName[file.name] = ids[file.path] end
        done(byName)
    end, function(reason)
        if Util.canCustomAsset() then Util.log("[qustah-ui-lib] icon sheet could not be loaded (" .. tostring(reason) .. "); using the asset ids") end
    end, "icons")
end

local function redrawSharp()
    for image, name in pairs(sharpImages) do if name and image.Parent then pcall(applySharp, image, name) end end
end

-- the lib's own sheet: started with the first icon drawn
local ownSheet = false
local function startOwnSheet()
    if ownSheet then return end
    ownSheet = true
    if Icons.Sharp == false then return end
    Icons.UseSheet(require("icons_qustah"), Icons.SheetSource)
end

-- The sizes icons are drawn at (the qustah sheet has each one, pixel for pixel): a requested size and the size on
-- screen after the UI scale both go to the nearest of these (ties to the bigger; under 14 -> 14, over 30 -> 30).
Icons.Sizes = { 14, 16, 20, 24, 28, 30 }
function Icons.fitSize(size)
    local best = Icons.Sizes[1]
    for _, allowed in ipairs(Icons.Sizes) do
        if math.abs(allowed - size) <= math.abs(best - size) then best = allowed end
    end
    return best
end

-- A script's own sheet (tools/gen_sheet.py): its icons drawn at every on-screen size, used before the asset id
-- whenever an icon's size is in it. Lib.Icons.UseSheet(manifest, "https://.../folder/") before the window.
local customSheets = {}
function Icons.UseSheet(manifest, source)
    if type(manifest) ~= "table" or type(source) ~= "string" then return end
    local sheet = { manifest = manifest, index = {}, ready = false, ids = {} }
    local i = 0
    for name in string.gmatch(manifest.Names or "", "[^,]+") do i = i + 1 sheet.index[name] = i end
    customSheets[#customSheets + 1] = sheet
    if Icons.Sharp == false then return end
    loadFiles(tostring(manifest.Id) .. "-v" .. tostring(manifest.Version) .. "-", source, manifest.Files or {}, function(ids)
        sheet.ids = ids
        sheet.ready = true
        redrawSharp()
    end)
end

-- Starts the lib's sheet download now (it otherwise starts with the first icon drawn), so a script can wait for it
-- with Lib.Loader.Wait before its window opens.
function Icons.Preload() startOwnSheet() end

-- the exact cell for an icon `pixels` tall, from a script sheet: image, offset, size
local function sheetRect(name, pixels)
    local size = math.floor(pixels + 0.5)
    for _, sheet in ipairs(customSheets) do
        local index = sheet.ready and sheet.index[name]
        local place = index and sheet.manifest.Sizes[size]
        if place then
            local page, y0, cols = place[1], place[2], place[3]
            local pitch = size + 2
            local image = sheet.ids[sheet.manifest.Files[page]]
            if image then
                return image, Vector2.new(((index - 1) % cols) * pitch + 1, y0 + math.floor((index - 1) / cols) * pitch + 1), Vector2.new(size, size)
            end
        end
    end
end

-- (tests) start over: forget the loaded sheets
function Icons._resetSheets() ownSheet = false table.clear(customSheets) end

-- the sheet name behind an icon name ("eye", "lucide:eye"), when a sheet (the lib's or a script's) has it
local function sheetName(name)
    if type(name) ~= "string" then return nil end
    local set, icon = name:match("^([%w_%-]+):(.+)$")
    if set then if set:lower() ~= "lucide" then return nil end name = icon
    elseif Icons.Default ~= "lucide" then return nil end
    for _, sheet in ipairs(customSheets) do if sheet.index[name] then return name end end
    return nil
end

local function pixelsOf(image)
    local size = image.AbsoluteSize
    if size and size.Y > 0 then return math.max(size.X, size.Y) end
    return math.max(image.Size.X.Offset, image.Size.Y.Offset)
end

-- A square icon sized in pixels lands on a size the sheets have, in whole screen pixels: at a UI scale like 125 % a
-- 16 px icon would be 20 px - fine - but a 14 px one 17.5 px; it becomes 16 px on screen (Icons.fitSize), so 16 / 1.25
-- in the menu. Icons from the lucide sheets only round to whole pixels. The original size is kept in the QIconSize
-- attribute, so a later scale starts from it again; an icon that is not laid out keeps its centre.
local function laidOut(object)
    local parent = object.Parent
    return parent == nil or parent:FindFirstChildWhichIsA("UIGridStyleLayout") ~= nil
end
local function inSheet(name)
    for _, sheet in ipairs(customSheets) do if sheet.index[name] then return true end end
    return false
end
Icons._sheetHas = function(name) startOwnSheet() return inSheet(name) end
local function resize(image, size)
    local old = image.Size.X.Offset
    image.Size = UDim2.fromOffset(size, size)
    if not laidOut(image) then
        local position, anchor, grow = image.Position, image.AnchorPoint, size - old
        image.Position = UDim2.new(position.X.Scale, position.X.Offset - grow * (0.5 - anchor.X), position.Y.Scale, position.Y.Offset - grow * (0.5 - anchor.Y))
    end
end
local function snapToPixels(image, name)
    local size = image.Size
    if size.X.Scale ~= 0 or size.Y.Scale ~= 0 then return end
    local base = image:GetAttribute("QIconSize") or size.X.Offset
    if base <= 0 or size.X.Offset ~= size.Y.Offset then return end
    local absolute = image.AbsoluteSize
    if not absolute or absolute.X <= 0 then return end
    local scale = absolute.X / size.X.Offset
    if scale <= 0 then return end
    local onScreen = base * scale
    local snapped
    if name and inSheet(name) then snapped = Icons.fitSize(onScreen) / scale
    elseif math.abs(scale - 1) < 0.001 then snapped = base
    else snapped = math.max(1, math.floor(onScreen + 0.5)) / scale end
    if math.abs(snapped - size.X.Offset) > 0.001 then
        image:SetAttribute("QIconSize", base)
        resize(image, snapped)
    end
end

-- A pixel-exact icon between two pixels is blurred again (an 11 px icon centred in a 16 px box sits at 2.5): it is
-- moved by under half a pixel onto whole pixels. An icon its parent lays out (a list: a button's icon and text)
-- can't move itself, so that parent moves instead, when nothing lays the parent out. The original position stays
-- in QIconX / QIconY; a position someone else sets later becomes the new one.
local function snapPosition(image)
    if Icons.SnapPosition == false then return end
    local target = image
    if laidOut(image) then
        target = image.Parent
        if not (target and target:IsA("GuiObject")) or target:IsA("ScrollingFrame") or laidOut(target) then return end
    end
    local position = target.Position
    local mine = target:GetAttribute("QIconSet")
    local baseX, baseY = target:GetAttribute("QIconX"), target:GetAttribute("QIconY")
    if baseX == nil or (mine and (math.abs(position.X.Offset - mine.X) > 0.001 or math.abs(position.Y.Offset - mine.Y) > 0.001)) then
        baseX, baseY = position.X.Offset, position.Y.Offset -- (first time, or moved by someone else)
    end
    local absolute, size = image.AbsolutePosition, image.AbsoluteSize
    if not absolute or not size or size.X <= 0 or image.Size.X.Offset <= 0 then return end
    local scale = size.X / image.Size.X.Offset
    -- (where the icon would be with the target at its own position, then how far that is from whole pixels)
    local atX = absolute.X + (baseX - position.X.Offset) * scale
    local atY = absolute.Y + (baseY - position.Y.Offset) * scale
    local dx, dy = math.floor(atX + 0.5) - atX, math.floor(atY + 0.5) - atY
    local x, y = baseX + dx / scale, baseY + dy / scale
    target:SetAttribute("QIconX", baseX)
    target:SetAttribute("QIconY", baseY)
    target:SetAttribute("QIconSet", Vector2.new(x, y))
    if math.abs(x - position.X.Offset) > 0.001 or math.abs(y - position.Y.Offset) > 0.001 then
        target.Position = UDim2.new(position.X.Scale, x, position.Y.Scale, y)
    end
end

-- (gathered and done once a frame: a card that opens resizes many boxes, each icon is placed once; an icon that
-- will not settle - something keeps resizing its box - is left alone after a few tries a second)
local queued, queueRunning = {}, false
local tries = setmetatable({}, { __mode = "k" })
queueSnap = function(image)
    local now = os.clock()
    local t = tries[image]
    if not t or now - t.since > 1 then t = { since = now, count = 0 } tries[image] = t end
    if t.count >= 6 then return end
    t.count = t.count + 1
    queued[image] = true
    if queueRunning then return end
    queueRunning = true
    task.defer(function()
        queueRunning = false
        local list = queued
        queued = {}
        for icon in pairs(list) do if icon.Parent then pcall(snapPosition, icon) end end
    end)
end

applySharp = function(image, name)
    pcall(snapToPixels, image, name)
    pcall(snapPosition, image)
    local pixels = pixelsOf(image)
    local picture, offset, size = sheetRect(name, pixels)
    -- a sheet cell is drawn 1:1, so nearest-pixel sampling keeps it sharp even half a pixel off; an asset id image
    -- is scaled and keeps the smooth filter
    pcall(function() image.ResampleMode = picture and Enum.ResamplerMode.Pixelated or Enum.ResamplerMode.Default end)
    if not picture then return false end
    image.Image, image.ImageRectOffset, image.ImageRectSize = picture, offset, size
    return true
end

-- Puts the icon on an ImageLabel / ImageButton (two-tone icons get their extra parts as children).
function Icons.Apply(image, name)
    image:SetAttribute("QIcon", name) -- which icon this is (debugging, previews)
    for _, child in ipairs(image:GetChildren()) do if child.Name == "IconPart" then child:Destroy() end end
    local icon = Icons.Get(name)
    if not icon then sharpImages[image] = nil return false end
    startOwnSheet() -- (a sheet icon is only known once the sheet's names are in)
    local sharp = not icon.Url and sheetName(name)
    if sharp then
        if sharpImages[image] == nil then
            -- a bigger / smaller menu (UI scale) can move the icon to the other sheet
            image:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                local current = sharpImages[image]
                if current then applySharp(image, current) end
            end)
            -- (its box laid out or resized: onto whole pixels again. Not on every move: the window and the pages
            -- only move by whole pixels, and thousands of icons listening to every move would cost a drag)
            local boxWatch
            local function watchBox()
                if boxWatch then boxWatch:Disconnect() boxWatch = nil end
                local parent = image.Parent
                if parent and parent:IsA("GuiObject") then
                    boxWatch = parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                        if sharpImages[image] then queueSnap(image) end
                    end)
                end
                if sharpImages[image] then queueSnap(image) end
            end
            -- (an icon gets its parent after it is made: Icons.Image, then .Parent)
            if Icons.SnapPosition ~= false then
                image:GetPropertyChangedSignal("Parent"):Connect(watchBox)
                watchBox()
            end
        end
        sharpImages[image] = sharp
        if applySharp(image, sharp) then return true end
    elseif sharpImages[image] then
        sharpImages[image] = false
    end
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
    local size = props.Size or UDim2.fromOffset(16, 16)
    -- (a square size in pixels goes to the nearest of Icons.Sizes)
    if size.X.Scale == 0 and size.Y.Scale == 0 and size.X.Offset == size.Y.Offset and size.X.Offset > 0 then
        local fitted = Icons.fitSize(size.X.Offset)
        size = UDim2.fromOffset(fitted, fitted)
    end
    image.Size = size
    if typeof(props.Color) == "Color3" then image.ImageColor3 = props.Color end
    Icons.Apply(image, name)
    image.Parent = props.Parent
    return image
end

-- Library use: an icon whose colour follows a theme role (nil when the name is not an icon).
-- The size goes to the nearest of Icons.Sizes; the icon keeps the centre it would have had at the asked size.
function Icons.themed(parent, name, size, role, props)
    if not Icons.Get(name) then return nil end
    local fitted = Icons.fitSize(size)
    local image = Icons.Image(name, { Size = UDim2.fromOffset(fitted, fitted), Name = props and props.Name or "Icon" })
    for key, value in pairs(props or {}) do if key ~= "Name" then image[key] = value end end
    if fitted ~= size and not (parent and parent:FindFirstChildWhichIsA("UIGridStyleLayout")) then
        local position, anchor, grow = image.Position, image.AnchorPoint, fitted - size
        image.Position = UDim2.new(position.X.Scale, position.X.Offset - grow * (0.5 - anchor.X), position.Y.Scale, position.Y.Offset - grow * (0.5 - anchor.Y))
    end
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
