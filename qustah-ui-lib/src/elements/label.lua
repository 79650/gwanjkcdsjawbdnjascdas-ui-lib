-- card:Label("text") or card:Label({ Title = "text", Color = Color3 }) - a wrapped line of muted text.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

return function(card, cfg)
    local text = Util.label(card.body, tostring(cfg.Title or cfg.Text or ""), 10, {
        Name = "Label", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None, RichText = true, LayoutOrder = card:_order(),
    })
    if typeof(cfg.Color) == "Color3" then text.TextColor3 = cfg.Color else Theme.bind(text, "TextColor3", "muted") end
    local element = Base.element(card, "Label", {}, text, text, nil)
    function element:Set(value) text.Text = tostring(value) end
    function element:SetColor(color) if typeof(color) == "Color3" then text.TextColor3 = color end end
    return element
end
