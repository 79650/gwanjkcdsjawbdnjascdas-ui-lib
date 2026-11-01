-- card:Gallery({ Title, Flag, Columns = 4, Default = "Dark", Callback = function(name) end, Items = {
--     { Name = "Dark", Colors = { Color3.fromRGB(18, 18, 19), Color3.fromRGB(27, 27, 29), Color3.fromRGB(92, 92, 98) } },
--     { Name = "Gotham", Font = Enum.Font.Gotham },                       -- a font sample ("Aa")
--     { Name = "Logo", Image = "rbxassetid://..." },
-- } })
-- Pick one of several cards by how it looks: a theme thumbnail (Colors = { background, card, accent }), a font sample
-- (Font = Enum.Font or Font.new(...), Sample = "Aa"), or an image. The chosen one gets a bright outline.
-- Value is the item's Name. :Set(name), :Get(), :SetItems(items).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Parts = require("elements/parts")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local columns = math.max(1, tonumber(cfg.Columns) or 4)
    local cellH, gap = tonumber(cfg.Height) or 58, 6
    local top = (cfg.Title and 22 or 0)
    local holder = create("Frame", { Name = tostring(cfg.Title or "Gallery"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, top), LayoutOrder = card:_order(), Parent = card.body })
    local title
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Size = UDim2.new(1, 0, 0, 20) })
        Theme.bind(title, "TextColor3", "text")
    end
    local element = Base.element(card, "Gallery", cfg, holder, title, nil)
    local cells = {}
    local function render()
        for _, cell in ipairs(cells) do
            local on = cell.name == element.Value
            Theme.tweenTo(cell.edge, "Color", on and "heading" or "line", 0.1)
            cell.edge.Thickness = on and 1.5 or 1
            Theme.tweenTo(cell.caption, "TextColor3", on and "heading" or "muted", 0.1)
        end
    end
    function element:SetItems(items)
        for _, cell in ipairs(cells) do cell.button:Destroy() end
        table.clear(cells)
        items = items or {}
        holder.Size = UDim2.new(1, 0, 0, top + Parts.gridHeight(#items, columns, gap, cellH))
        for index, item in ipairs(items) do
            local name = tostring(item.Name or item.Title or index)
            local position, size = Parts.cell(index, columns, gap, cellH, top)
            local button = create("TextButton", { Name = name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Position = position, Size = size, Parent = holder })
            corner(button, 8)
            local edge = Util.stroke(button, nil, 0)
            local caption = label(button, name, 9, { Name = "Caption", Position = UDim2.new(0, 7, 1, -15), Size = UDim2.new(1, -14, 0, 12) })
            if item.Colors then
                local colors = item.Colors
                button.BackgroundColor3 = colors[1] or Color3.new()
                local preview = create("Frame", { Name = "Preview", Position = UDim2.fromOffset(5, 5), Size = UDim2.new(1, -10, 1, -24), BorderSizePixel = 0, BackgroundColor3 = colors[2] or colors[1], Parent = button })
                corner(preview, 5)
                local bar = create("Frame", { Name = "Bar", Position = UDim2.fromOffset(5, 5), Size = UDim2.new(1, -24, 0, 6), BorderSizePixel = 0, BackgroundColor3 = (colors[2] or Color3.new()):Lerp(Color3.new(1, 1, 1), 0.12), Parent = preview })
                corner(bar, 3)
                local knob = create("Frame", { Name = "Accent", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -5, 0, 5), Size = UDim2.fromOffset(10, 6), BorderSizePixel = 0, BackgroundColor3 = colors[3] or Color3.new(1, 1, 1), Parent = preview })
                corner(knob, 3)
                local bright = (colors[1].R + colors[1].G + colors[1].B) / 3 > 0.6
                caption.TextColor3 = bright and Color3.fromRGB(40, 40, 45) or Color3.fromRGB(225, 225, 230)
            else
                Theme.bind(button, "BackgroundColor3", "input")
                if item.Image then
                    create("ImageLabel", { Name = "Image", BackgroundTransparency = 1, Position = UDim2.fromOffset(5, 5), Size = UDim2.new(1, -10, 1, -24), Image = tostring(item.Image), ScaleType = Enum.ScaleType.Fit, Parent = button })
                else
                    local sample = label(button, tostring(item.Sample or cfg.Sample or "Aa"), 17, { Name = "Sample", Position = UDim2.fromOffset(8, 5), Size = UDim2.new(1, -16, 1, -22) })
                    sample:SetAttribute("QFixedFont", true)
                    if typeof(item.Font) == "EnumItem" then sample.Font = item.Font
                    elseif typeof(item.Font) == "Font" then sample.FontFace = item.Font end
                    Theme.bind(sample, "TextColor3", "heading")
                end
            end
            local cell = { name = name, button = button, edge = edge, caption = caption }
            if not item.Colors then Theme.bind(caption, "TextColor3", "muted") end
            cells[#cells + 1] = cell
            button.Activated:Connect(function() if not element.Locked then element:Set(name) end end)
            Util.hoverPop(button, 1.03)
        end
        render()
    end
    function element:Set(name, silent)
        self.Value = name ~= nil and tostring(name) or nil
        render()
        self:_fire(self.Value, silent)
    end
    function element:Get() return self.Value end
    element:SetItems(cfg.Items)
    element.Value = cfg.Default ~= nil and tostring(cfg.Default) or nil
    render()
    element:_fire(element.Value, true)
    return Base.finish(element, cfg)
end
