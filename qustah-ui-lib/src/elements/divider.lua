-- card:Divider() - a thin line between groups of rows.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create = Util.create

return function(card)
    local holder = create("Frame", { Name = "Divider", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 7), LayoutOrder = card:_order(), Parent = card.body })
    local line = create("Frame", { Position = UDim2.fromOffset(0, 3), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, BackgroundTransparency = 0.3, Parent = holder })
    Theme.bind(line, "BackgroundColor3", "line")
    return Base.element(card, "Divider", {}, holder, nil, nil)
end
