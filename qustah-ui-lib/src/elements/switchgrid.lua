-- card:SwitchGrid({ Columns = 2, Items = {
--     { Title = "ESP", Icon = "eye", Flag = "esp", Default = true, Callback = function(on) end },
--     { Title = "Misc", Icon = "box", Status = "Limited" },          -- no switch: a status chip instead
-- } })
-- Boxed rows two (Columns) to a line, each with an icon, a name and its own switch. Every item with a Flag is a
-- normal toggle (saved with the profile, Lib.Flags[flag], window.flags[flag]:Set(on)). Status = "text" shows a chip
-- (coloured by StatusRole = "warning" | "success" | "danger" ...) instead of a switch. Badge = "RISKY", Risky = true,
-- Tooltip = "text" work as on a Toggle.
-- Returns the grid; grid.Items[i] / grid.Items[title] are the toggles (:Set, :Get, :Lock), grid:SetStatus(title, text, role).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")
local Parts = require("elements/parts")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local list = cfg.Items or {}
    local columns = math.max(1, tonumber(cfg.Columns) or 2)
    local height, gap = 34, 6
    local holder = create("Frame", { Name = tostring(cfg.Title or "SwitchGrid"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Parts.gridHeight(#list, columns, gap, height)), LayoutOrder = card:_order(), Parent = card.body })
    local grid = Base.element(card, "SwitchGrid", { Title = cfg.Title }, holder, nil, nil)
    grid.Items = {}
    local chips = {}
    for index, spec in ipairs(list) do
        local position, size = Parts.cell(index, columns, gap, height)
        local box = create("TextButton", { Name = tostring(spec.Title or index), Text = "", AutoButtonColor = false, BorderSizePixel = 0, Position = position, Size = size, Parent = holder })
        Theme.bind(box, "BackgroundColor3", "input")
        corner(box, 7)
        Theme.bind(Util.stroke(box, nil, 0.2), "Color", "line")
        local x = 10
        if spec.Icon then
            local icon = Icons.themed(box, spec.Icon, 13, "icon", { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0) })
            if icon then x = 30 end
        end
        local title = label(box, tostring(spec.Title or ""), 10, { Name = "Title", Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -x - 52, 1, 0) })
        Theme.bind(title, "TextColor3", spec.Risky and "danger" or "text")
        -- Badge = "RISKY": a small tag after the name (Risky = true: the name is red too)
        if spec.Badge then
            local tag = Parts.chip(box, tostring(spec.Badge), spec.Risky and "danger" or "muted", nil, { Name = "Badge", AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, x + Util.textWidth(tostring(spec.Title or ""), 10, Enum.Font.Gotham) + 6, 0.5, 0) })
            tag.Size = UDim2.fromOffset(tag.Size.X.Offset, 15)
            tag:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 4)
        end
        if spec.Tooltip then
            box.MouseEnter:Connect(function() card.window:_tip(tostring(spec.Tooltip)) end)
            box.MouseLeave:Connect(function() card.window:_hideTip() end)
        end
        if spec.Status ~= nil then
            local chip, _, resize = Parts.chip(box, tostring(spec.Status), spec.StatusRole or "warning", nil, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0) })
            chips[tostring(spec.Title)] = { chip = chip, resize = resize }
            title.Size = UDim2.new(1, -x - chip.Size.X.Offset - 14, 1, 0)
        else
            local switch = create("Frame", { Name = "Switch", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(30, 16), BorderSizePixel = 0, Parent = box })
            corner(switch, 8)
            local knob = create("Frame", { Name = "Knob", Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(12, 12), BorderSizePixel = 0, Parent = switch })
            corner(knob, 6)
            Theme.bind(knob, "BackgroundColor3", "knob")
            local item = Base.element(card, "Toggle", { Title = spec.Title, Flag = spec.Flag, Callback = spec.Callback }, box, title, nil)
            item.Value = spec.Default == true
            local function render(animate)
                Theme.tweenTo(switch, "BackgroundColor3", item.Value and (spec.OnRole or "success") or "buttonEdge", animate and 0.15 or nil)
                Util.tween(knob, animate and 0.15 or 0, { Position = UDim2.fromOffset(item.Value and 16 or 2, 2) })
            end
            function item:Set(on, silent)
                on = on == true
                local changed = on ~= self.Value
                self.Value = on
                render(true)
                self:_fire(on, silent or not changed)
            end
            function item:Get() return self.Value end
            box.Activated:Connect(function() if not item.Locked then item:Set(not item.Value) end end)
            render(false)
            item:_fire(item.Value, true)
            grid.Items[index] = item
            grid.Items[tostring(spec.Title)] = item
        end
        box.MouseEnter:Connect(function() Theme.tweenTo(box, "BackgroundColor3", "hover", 0.1) end)
        box.MouseLeave:Connect(function() Theme.tweenTo(box, "BackgroundColor3", "input", 0.1) end)
    end
    function grid:SetStatus(titleText, text, role)
        local entry = chips[tostring(titleText)]
        if not entry then return end
        entry.resize(text)
        local textLabel = entry.chip:FindFirstChild("Text")
        if textLabel and role then Theme.bind(textLabel, "TextColor3", role) end
    end
    function grid:Get(titleText) local item = self.Items[titleText] return item and item.Value end
    function grid:Set(titleText, on) local item = self.Items[titleText] if item then item:Set(on) end end
    return Base.finish(grid, cfg)
end
