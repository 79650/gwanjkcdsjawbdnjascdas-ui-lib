-- card:Hero({ Title = "Tester", Desc = "@Tester · #101", UserId = 1 | Image = "rbxassetid://...", Online = true,
--             Chips = { { "60 FPS", "activity" }, { "40 ms", "wifi" } }, Label = "SESSION", Value = "00:12:44" })
-- A profile header: round avatar (UserId: the player's headshot) with an online dot, a big name, a muted line, a row
-- of chips, and a small-caps label over a big value on the right (a timer, a score...).
-- :SetTitle, :SetDesc, :SetValue(text), :SetLabel(text), :SetChips(list), :SetChipText(index, text), :SetOnline(on),
-- :SetImage(image). hero.Value / hero.Avatar are the value label and the avatar image.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Parts = require("elements/parts")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local size = tonumber(cfg.AvatarSize) or 46
    local holder = create("Frame", { Name = tostring(cfg.Name or cfg.Title or "Hero"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, size + 8), LayoutOrder = card:_order(), Parent = card.body })
    local avatar = create("ImageLabel", { Name = "Avatar", Size = UDim2.fromOffset(size, size), Position = UDim2.fromOffset(0, 4), BorderSizePixel = 0, Image = "", Parent = holder })
    Theme.bind(avatar, "BackgroundColor3", "input")
    corner(avatar, size)
    Theme.bind(Util.stroke(avatar, nil, 0.1, 2), "Color", "buttonEdge")
    local online = create("Frame", { Name = "Online", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0), Size = UDim2.fromOffset(math.floor(size * 0.24), math.floor(size * 0.24)), BorderSizePixel = 0, ZIndex = 2, Parent = avatar })
    corner(online, size)
    Theme.bind(online, "BackgroundColor3", "success")
    Theme.bind(Util.stroke(online, nil, 0, 2), "Color", "card")
    local x = size + 12
    local title = label(holder, tostring(cfg.Title or ""), 15, { Name = "Title", Position = UDim2.fromOffset(x, 2), Size = UDim2.new(1, -x - 110, 0, 20), Font = Enum.Font.GothamBold })
    Theme.bind(title, "TextColor3", "heading")
    local desc = label(holder, tostring(cfg.Desc or ""), 9, { Name = "Desc", Position = UDim2.fromOffset(x, 21), Size = UDim2.new(1, -x - 110, 0, 12) })
    Theme.bind(desc, "TextColor3", "muted")
    local chipRow = create("Frame", { Name = "Chips", BackgroundTransparency = 1, Position = UDim2.fromOffset(x, 36), Size = UDim2.new(1, -x - 110, 0, 18), Parent = holder })
    Util.list(chipRow, 4, Enum.FillDirection.Horizontal)
    local small = label(holder, tostring(cfg.Label or ""), 8, { Name = "Label", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 8), Size = UDim2.fromOffset(120, 12), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium })
    Theme.bind(small, "TextColor3", "muted")
    local value = label(holder, tostring(cfg.Value or ""), 20, { Name = "Value", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 20), Size = UDim2.fromOffset(140, 24), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium })
    Theme.bind(value, "TextColor3", "heading")

    local element = Base.element(card, "Hero", { Title = cfg.Title }, holder, title, desc)
    local chipFrames, chipSetters = {}, {}
    function element:SetChips(list)
        for _, chip in ipairs(chipFrames) do chip:Destroy() end
        table.clear(chipFrames)
        table.clear(chipSetters)
        for index, item in ipairs(list or {}) do
            if type(item) ~= "table" then item = { item } end
            local chip, _, resize = Parts.chip(chipRow, tostring(item[1] or item.Text), item.Role or "text", item[2] or item.Icon, { LayoutOrder = index })
            chipFrames[#chipFrames + 1] = chip
            chipSetters[index] = resize
        end
    end
    -- one chip's text (live numbers), without rebuilding the row
    function element:SetChipText(index, text) if chipSetters[index] then chipSetters[index](text) end end
    function element:SetValue(text) value.Text = tostring(text) end
    function element:SetLabel(text) small.Text = tostring(text) end
    function element:SetOnline(on) online.Visible = on ~= false end
    function element:SetImage(image) avatar.Image = tostring(image or "") end
    element.Value, element.Avatar = value, avatar
    if cfg.UserId then element:SetImage(Util.avatar(cfg.UserId, 150)) elseif cfg.Image then element:SetImage(cfg.Image) end
    element:SetOnline(cfg.Online)
    element:SetChips(cfg.Chips)
    return Base.finish(element, cfg)
end
