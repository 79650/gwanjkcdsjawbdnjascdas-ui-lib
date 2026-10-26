-- card:Paragraph({ Title = "Heading", Content = "Longer text, wraps to any number of lines." })
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create = Util.create

return function(card, cfg)
    local holder = create("Frame", {
        Name = "Paragraph", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = card:_order(), Parent = card.body,
    })
    Util.list(holder, 2)
    local title = Util.label(holder, tostring(cfg.Title or ""), 11, { Name = "Title", Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamMedium, LayoutOrder = 1 })
    Theme.bind(title, "TextColor3", "heading")
    title.Visible = cfg.Title ~= nil
    local content = Util.label(holder, tostring(cfg.Content or ""), 10, {
        Name = "Content", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top, RichText = true, LayoutOrder = 2,
    })
    Theme.bind(content, "TextColor3", "muted")
    local element = Base.element(card, "Paragraph", {}, holder, title, content)
    function element:Set(text) content.Text = tostring(text) end
    function element:SetContent(text) content.Text = tostring(text) end
    return element
end
