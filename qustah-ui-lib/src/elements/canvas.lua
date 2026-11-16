-- card:Canvas({ Height = 90, Radius = 8, Background = true })
-- An empty rounded frame inside a card for a script's own drawing (a sky preview, an overlay over a Viewport...).
-- element.Frame is the frame to put things in (ClipsDescendants on); :SetHeight(px). No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local height = tonumber(cfg.Height) or 90
    local holder = create("Frame", {
        Name = tostring(cfg.Name or "Canvas"), Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, ClipsDescendants = true,
        BackgroundTransparency = cfg.Background == false and 1 or 0, LayoutOrder = card:_order(), Parent = card.body,
    })
    Theme.bind(holder, "BackgroundColor3", "base")
    corner(holder, tonumber(cfg.Radius) or 8)
    if cfg.Background ~= false then Theme.bind(stroke(holder), "Color", "line") end
    local element = Base.element(card, "Canvas", {}, holder, nil, nil)
    element.Frame = holder
    function element:SetHeight(px) holder.Size = UDim2.new(1, 0, 0, tonumber(px) or height) end
    return element
end
