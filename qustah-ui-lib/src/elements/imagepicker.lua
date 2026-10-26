-- card:ImagePicker({ Title, Flag, Images = { "251497633", "rbxassetid://12140499119", ... }, Default, Columns = 5, Callback })
-- A grid of images (crosshairs, icons...); the chosen one is outlined. Value is the image exactly as given.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

return function(card, cfg)
    local images = cfg.Images or {}
    local columns = math.max(1, tonumber(cfg.Columns) or 5)
    local cell = tonumber(cfg.CellSize) or 40
    local rowsCount = math.ceil(#images / columns)
    local top = cfg.Title and 24 or 0
    local holder = create("Frame", { Name = tostring(cfg.Title or "Images"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, top + rowsCount * (cell + 6)), LayoutOrder = card:_order(), Parent = card.body })
    local title
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Size = UDim2.new(1, 0, 0, 20) })
        Theme.bind(title, "TextColor3", "text")
    end
    local grid = create("Frame", { Name = "Grid", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 1, -top), Parent = holder })

    local element = Base.element(card, "ImagePicker", cfg, holder, title, nil)
    local buttons = {}
    local function asset(image)
        image = tostring(image)
        return image:match("^%d+$") and ("rbxassetid://" .. image) or image
    end
    local function render()
        for image, entry in pairs(buttons) do
            local on = image == element.Value
            Theme.tweenTo(entry.button, "BackgroundColor3", on and "selected" or "input", 0.1)
            Theme.tweenTo(entry.outline, "Color", on and "accent" or "line", 0.1)
            entry.outline.Transparency = on and 0.2 or 0.6
        end
    end
    for index, image in ipairs(images) do
        local key = tostring(image)
        local button = create("ImageButton", {
            Name = "Image" .. index, AutoButtonColor = false, BorderSizePixel = 0, Image = "", LayoutOrder = index, Parent = grid,
            Position = UDim2.new(((index - 1) % columns) / columns, 3, 0, ((index - 1) // columns) * (cell + 6)), Size = UDim2.new(1 / columns, -6, 0, cell),
        })
        corner(button, 6)
        local outline = stroke(button)
        create("ImageLabel", {
            Name = "Preview", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.62, 0.62),
            BackgroundTransparency = 1, Image = asset(image), ScaleType = Enum.ScaleType.Fit, Parent = button,
        })
        buttons[key] = { button = button, outline = outline }
        button.Activated:Connect(function() if not element.Locked then element:Set(key) end end)
    end

    function element:Set(image, silent)
        image = image ~= nil and tostring(image) or nil
        if image and not buttons[image] then return end
        local changed = image ~= self.Value
        self.Value = image
        render()
        self:_fire(image, silent or not changed)
    end
    function element:Get() return self.Value end

    element:Set(cfg.Default ~= nil and cfg.Default or images[1], true)
    return Base.finish(element, cfg)
end
