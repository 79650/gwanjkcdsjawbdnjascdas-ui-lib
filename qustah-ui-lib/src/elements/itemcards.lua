-- card:ItemCards({ Columns = 2, AddNew = "New profile", OnAdd = function() end, OnAction = function(item, index) end,
--     OnMenu = function(item, index) end, Items = {
--         { Title = "Default", Sub = "now · 46 settings", Desc = "Active · autoload", Color = Color3.fromRGB(232, 232, 236),
--           Badges = { "ACTIVE", "AUTO" }, Action = "Save", Highlight = true },
--     } })
-- A grid of small cards (profiles, saved setups, servers...): a coloured letter badge, a title and a muted line, a
-- "..." menu button, a description, badge tags and one action button. AddNew adds a dashed "+" card at the end.
-- Badges may be { Text = "ACTIVE", Role = "success" }. :SetItems(items), :GetItems(). No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")
local Parts = require("elements/parts")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local columns = math.max(1, tonumber(cfg.Columns) or 2)
    local cellH, gap = tonumber(cfg.Height) or 96, 6
    local holder = create("Frame", { Name = tostring(cfg.Title or "ItemCards"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = card:_order(), Parent = card.body })
    local element = Base.element(card, "ItemCards", { Title = cfg.Title }, holder, nil, nil)
    local items, frames = {}, {}
    local function button(parent, text, props)
        local width = Util.textWidth(text, 10, Enum.Font.GothamMedium) + 20
        local b = create("TextButton", { Name = text, Text = text, AutoButtonColor = false, BorderSizePixel = 0, Size = UDim2.fromOffset(width, 22), TextSize = 10, Font = Enum.Font.GothamMedium, Parent = parent })
        for key, value in pairs(props or {}) do b[key] = value end
        corner(b, 6)
        Theme.bind(b, "BackgroundColor3", "card")
        Theme.bind(b, "TextColor3", "text")
        Theme.bind(Util.stroke(b, nil, 0.2), "Color", "buttonEdge")
        b.MouseEnter:Connect(function() Theme.tweenTo(b, "BackgroundColor3", "hover", 0.1) end)
        b.MouseLeave:Connect(function() Theme.tweenTo(b, "BackgroundColor3", "card", 0.1) end)
        return b
    end
    function element:SetItems(list)
        for _, frame in ipairs(frames) do frame:Destroy() end
        table.clear(frames)
        items = list or {}
        local total = #items + (cfg.AddNew and 1 or 0)
        holder.Size = UDim2.new(1, 0, 0, Parts.gridHeight(total, columns, gap, cellH))
        for index, item in ipairs(items) do
            local position, size = Parts.cell(index, columns, gap, cellH)
            local box, edge = Parts.box(holder, { Name = tostring(item.Title or index), Position = position, Size = size })
            if item.Highlight then Theme.bind(edge, "Color", "buttonEdge") edge.Transparency = 0 end
            frames[#frames + 1] = box
            local color = typeof(item.Color) == "Color3" and item.Color or Theme.get("accent")
            local badge = create("Frame", { Name = "Letter", Position = UDim2.fromOffset(9, 9), Size = UDim2.fromOffset(26, 26), BorderSizePixel = 0, BackgroundColor3 = color, BackgroundTransparency = 0.82, Parent = box })
            corner(badge, 7)
            Util.stroke(badge, color, 0.55)
            local letter = label(badge, string.upper(string.sub(tostring(item.Letter or item.Title or "?"), 1, 1)), 12, { Name = "Text", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextColor3 = color })
            letter.TextColor3 = color
            local title = label(box, tostring(item.Title or ""), 11, { Name = "Title", Position = UDim2.fromOffset(42, 8), Size = UDim2.new(1, -70, 0, 15), Font = Enum.Font.GothamMedium })
            Theme.bind(title, "TextColor3", "heading")
            local sub = label(box, tostring(item.Sub or ""), 8, { Name = "Sub", Position = UDim2.fromOffset(42, 23), Size = UDim2.new(1, -70, 0, 11) })
            Theme.bind(sub, "TextColor3", "muted")
            if cfg.OnMenu then
                local menu = create("ImageButton", { Name = "Menu", BackgroundTransparency = 1, Image = "", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 9), Size = UDim2.fromOffset(18, 18), Parent = box })
                Icons.themed(menu, "ellipsis", 14, "muted", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
                menu.Activated:Connect(function() card.window:_safe("ItemCards menu", cfg.OnMenu, item, index) end)
            end
            local desc = label(box, tostring(item.Desc or ""), 9, { Name = "Desc", Position = UDim2.fromOffset(9, 40), Size = UDim2.new(1, -18, 0, 24), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })
            Theme.bind(desc, "TextColor3", "muted")
            local tags = create("Frame", { Name = "Badges", BackgroundTransparency = 1, Position = UDim2.new(0, 9, 1, -28), Size = UDim2.new(1, -90, 0, 20), Parent = box })
            Util.list(tags, 4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
            for order, tag in ipairs(item.Badges or {}) do
                if type(tag) ~= "table" then tag = { Text = tag } end
                local chip = Parts.chip(tags, tostring(tag.Text), tag.Role or "muted", nil, { LayoutOrder = order })
                chip.Size = UDim2.fromOffset(chip.Size.X.Offset, 16)
                chip:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 4)
            end
            if item.Action ~= false then
                local action = button(box, tostring(item.Action or "Open"), { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -9, 1, -8) })
                action.Activated:Connect(function() if cfg.OnAction then card.window:_safe("ItemCards", cfg.OnAction, item, index) end end)
            end
        end
        if cfg.AddNew then
            local position, size = Parts.cell(#items + 1, columns, gap, cellH)
            local add = create("TextButton", { Name = "AddNew", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = position, Size = size, Parent = holder })
            corner(add, 7)
            Theme.bind(Util.stroke(add, nil, 0.1), "Color", "buttonEdge")
            Icons.themed(add, "plus", 16, "muted", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -8) })
            local text = label(add, tostring(cfg.AddNew), 10, { Position = UDim2.new(0, 0, 0.5, 4), Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Center })
            Theme.bind(text, "TextColor3", "muted")
            add.Activated:Connect(function() if cfg.OnAdd then card.window:_safe("ItemCards add", cfg.OnAdd) end end)
            frames[#frames + 1] = add
        end
    end
    function element:GetItems() return items end
    element:SetItems(cfg.Items)
    return Base.finish(element, cfg)
end
