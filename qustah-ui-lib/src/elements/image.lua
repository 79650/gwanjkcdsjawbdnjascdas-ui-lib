-- card:Image({ Image = "rbxassetid://..." | "https://.../logo.png" | "icon-name", Height = 120, Radius = 8, Fit = "Crop" | "Fit", Caption })
-- A picture inside a card. Web images download once (getcustomasset). :Set(image).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local height = tonumber(cfg.Height) or 120
    local holder = create("Frame", { Name = tostring(cfg.Name or "Image"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height + (cfg.Caption and 18 or 0)), LayoutOrder = card:_order(), Parent = card.body })
    local frame = create("ImageLabel", {
        Name = "Picture", Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, ScaleType = cfg.Fit == "Fit" and Enum.ScaleType.Fit or Enum.ScaleType.Crop,
        Parent = holder,
    })
    Theme.bind(frame, "BackgroundColor3", "input")
    corner(frame, tonumber(cfg.Radius) or 8)
    if typeof(cfg.AspectRatio) == "number" then
        create("UIAspectRatioConstraint", { AspectRatio = cfg.AspectRatio, Parent = frame })
    end
    local caption
    if cfg.Caption then
        caption = label(holder, tostring(cfg.Caption), 9, { Name = "Caption", Position = UDim2.fromOffset(0, height + 4), Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Center })
        Theme.bind(caption, "TextColor3", "muted")
    end
    local element = Base.element(card, "Image", {}, holder, caption, nil)
    function element:Set(image)
        self.Value = image
        frame.Image = ""
        if image == nil then return end
        local icon = Icons.Get(image)
        if icon then Icons.Apply(frame, image) else frame.Image = tostring(image) end
        -- icon names are tinted like text; pictures keep their colours
        local isPicture = tostring(image):match("^rbxasset") or tostring(image):match("^%d+$") or tostring(image):match("^https?://")
        if isPicture then frame.ImageColor3 = Color3.new(1, 1, 1) else Theme.bind(frame, "ImageColor3", "heading") end
    end
    element:Set(cfg.Image)
    return element
end
