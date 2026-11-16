-- card:Divider() - a thin line between groups of rows.
-- card:Divider({ Title = "Defense" }) - a section label: small upper-case text with the line running after it.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, label = Util.create, Util.label

return function(card, cfg)
    cfg = type(cfg) == "table" and cfg or {}
    if cfg.Title then
        local holder = create("Frame", { Name = "Section", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = card:_order(), Parent = card.body })
        local text = string.upper(tostring(cfg.Title))
        local width = Util.textWidth(text, 8, Enum.Font.GothamBold) + 2
        local title = label(holder, text, 8, { Name = "Title", Position = UDim2.fromOffset(0, 4), Size = UDim2.new(0, width, 0, 12), Font = Enum.Font.GothamBold })
        Theme.bind(title, "TextColor3", "muted")
        local line = create("Frame", { Name = "Line", Position = UDim2.new(0, width + 6, 0, 10), Size = UDim2.new(1, -(width + 6), 0, 1), BorderSizePixel = 0, BackgroundTransparency = 0.3, Parent = holder })
        Theme.bind(line, "BackgroundColor3", "line")
        return Base.element(card, "Divider", { Title = cfg.Title }, holder, nil, nil)
    end
    local holder = create("Frame", { Name = "Divider", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 7), LayoutOrder = card:_order(), Parent = card.body })
    local line = create("Frame", { Position = UDim2.fromOffset(0, 3), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, BackgroundTransparency = 0.3, Parent = holder })
    Theme.bind(line, "BackgroundColor3", "line")
    return Base.element(card, "Divider", {}, holder, nil, nil)
end
