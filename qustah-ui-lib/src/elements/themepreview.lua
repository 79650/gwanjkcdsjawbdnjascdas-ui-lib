-- card:ThemePreview({ Height = 150, Caption = function() return "Gotham · Normal · 100%" end })
-- A tiny live copy of a window: title, two little cards with a switch and a slider, drawn with the theme's own
-- colours - change the theme, accent or font and it follows at once (next to the look settings).
-- :Refresh() updates the caption. No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local holder = create("Frame", { Name = "ThemePreview", BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, tonumber(cfg.Height) or 150), LayoutOrder = card:_order(), ClipsDescendants = true, Parent = card.body })
    Theme.bind(holder, "BackgroundColor3", "base")
    corner(holder, 9)
    Theme.bind(Util.stroke(holder), "Color", "edge")
    local title = label(holder, tostring(cfg.Name or card.window.Title or "Window"), 11, { Name = "WindowTitle", Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -60, 0, 18), Font = Enum.Font.GothamBold })
    Theme.bind(title, "TextColor3", "heading")
    local tab = create("Frame", { Name = "Tab", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 22), Size = UDim2.fromOffset(34, 2), BorderSizePixel = 0, Parent = holder })
    Theme.bind(tab, "BackgroundColor3", "accent")
    local function mini(x, name, on, withSlider)
        local box = create("Frame", { Name = name, Position = UDim2.new(x, x == 0 and 10 or 4, 0, 32), Size = UDim2.new(0.5, -14, 0, 74), BorderSizePixel = 0, Parent = holder })
        Theme.bind(box, "BackgroundColor3", "card")
        corner(box, 6)
        Theme.bind(Util.stroke(box), "Color", "line")
        local heading = label(box, name, 9, { Position = UDim2.fromOffset(8, 5), Size = UDim2.new(1, -16, 0, 12), Font = Enum.Font.GothamMedium })
        Theme.bind(heading, "TextColor3", "heading")
        local row = label(box, on and "Highlight" or "Silent Aim", 8, { Position = UDim2.fromOffset(8, 24), Size = UDim2.new(1, -40, 0, 12) })
        Theme.bind(row, "TextColor3", "text")
        local switch = create("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 24), Size = UDim2.fromOffset(20, 11), BorderSizePixel = 0, Parent = box })
        corner(switch, 6)
        Theme.bind(switch, "BackgroundColor3", on and "toggleOn" or "buttonEdge")
        local knob = create("Frame", { Position = UDim2.fromOffset(on and 10 or 1, 1), Size = UDim2.fromOffset(9, 9), BorderSizePixel = 0, Parent = switch })
        corner(knob, 5)
        Theme.bind(knob, "BackgroundColor3", "knob")
        if withSlider then
            local track = create("Frame", { Position = UDim2.fromOffset(8, 52), Size = UDim2.new(1, -16, 0, 3), BorderSizePixel = 0, Parent = box })
            corner(track, 2)
            Theme.bind(track, "BackgroundColor3", "buttonEdge")
            local fill = create("Frame", { Size = UDim2.fromScale(0.6, 1), BorderSizePixel = 0, Parent = track })
            corner(fill, 2)
            Theme.bind(fill, "BackgroundColor3", "accent")
        end
    end
    mini(0, "ESP", true, true)
    mini(0.5, "Aim", false, false)
    local caption = label(holder, "", 8, { Name = "Caption", Position = UDim2.new(0, 10, 1, -18), Size = UDim2.new(1, -20, 0, 12) })
    Theme.bind(caption, "TextColor3", "muted")
    local element = Base.element(card, "ThemePreview", { Title = cfg.Title }, holder, nil, nil)
    function element:Refresh()
        local ok, text = true, cfg.Caption
        if type(cfg.Caption) == "function" then ok, text = pcall(cfg.Caption) end
        caption.Text = ok and tostring(text or "") or ""
    end
    element:Refresh()
    return Base.finish(element, cfg)
end
