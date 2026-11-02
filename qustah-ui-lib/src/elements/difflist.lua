-- card:DiffList({ Empty = "No changes", OnRevert = function(row, index) end, Items = {
--     { Tag = "ESP", Title = "Max distance", Old = "1000", New = "1500" },
-- } })
-- What changed: per row a small tag, the setting, the old value struck through in red, an arrow and the new value
-- in green, and (with OnRevert) a small undo button. :SetItems(rows), :GetItems(), :Count(). No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")
local Parts = require("elements/parts")

local create, label = Util.create, Util.label

return function(card, cfg)
    local holder = create("Frame", { Name = tostring(cfg.Title or "DiffList"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = card:_order(), Parent = card.body })
    Util.list(holder, 0)
    local element = Base.element(card, "DiffList", { Title = cfg.Title }, holder, nil, nil)
    local rows, frames = {}, {}
    function element:SetItems(list)
        for _, frame in ipairs(frames) do frame:Destroy() end
        table.clear(frames)
        rows = list or {}
        if #rows == 0 then
            local empty = label(holder, tostring(cfg.Empty or "No changes"), 10, { Name = "Empty", Size = UDim2.new(1, 0, 0, 24) })
            Theme.bind(empty, "TextColor3", "muted")
            frames[1] = empty
            return
        end
        for index, row in ipairs(rows) do
            local frame = create("Frame", { Name = tostring(row.Title or index), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = index, Parent = holder })
            local line = create("Frame", { Name = "Line", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = frame })
            Theme.bind(line, "BackgroundColor3", "line")
            local x = 0
            if row.Tag then
                local chip = Parts.chip(frame, tostring(row.Tag), "muted", nil, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) })
                chip.Size = UDim2.fromOffset(math.max(chip.Size.X.Offset, 66), 18)
                x = chip.Size.X.Offset + 8
            end
            local right = cfg.OnRevert and 22 or 0
            local new = label(frame, tostring(row.New or ""), 9, { Name = "New", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -right, 0.5, 0), Size = UDim2.fromOffset(78, 16), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.Code })
            Theme.bind(new, "TextColor3", "success")
            Icons.themed(frame, "arrow-right", 10, "muted", { Name = "Arrow", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -right - 82, 0.5, 0) })
            local old = label(frame, tostring(row.Old or ""), 9, { Name = "Old", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -right - 96, 0.5, 0), Size = UDim2.fromOffset(78, 16), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.Code, RichText = true })
            old.Text = "<s>" .. tostring(row.Old or ""):gsub("[<>&]", "") .. "</s>"
            Theme.bind(old, "TextColor3", "danger")
            local title = label(frame, tostring(row.Title or ""), 10, { Name = "Title", Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -x - right - 180, 1, 0) })
            Theme.bind(title, "TextColor3", "text")
            if cfg.OnRevert then
                local undo = create("ImageButton", { Name = "Revert", BackgroundTransparency = 1, Image = "", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(18, 18), Parent = frame })
                local icon = Icons.themed(undo, "undo-2", 12, "muted", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
                undo.MouseEnter:Connect(function() if icon then Theme.tweenTo(icon, "ImageColor3", "heading", 0.1) end card.window:_tip("Undo this change") end)
                undo.MouseLeave:Connect(function() if icon then Theme.tweenTo(icon, "ImageColor3", "muted", 0.1) end card.window:_hideTip() end)
                undo.Activated:Connect(function() card.window:_safe("DiffList", cfg.OnRevert, row, index) end)
            end
            frames[#frames + 1] = frame
        end
    end
    function element:GetItems() return rows end
    function element:Count() return #rows end
    element:SetItems(cfg.Items)
    return Base.finish(element, cfg)
end
