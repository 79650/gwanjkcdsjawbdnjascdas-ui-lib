-- card:Tiles({ Columns = 4, Items = {
--     { Title = "Free mouse", Icon = "mouse-pointer", Flag = "freeMouse", Default = true },   -- a toggle tile
--     { Title = "ESP", Icon = "eye", State = "on" },                                          -- a status tile
--     { Title = "Rejoin", Icon = "rotate-ccw", Callback = function() end },                   -- a button tile
-- } })
-- Square-ish tiles: an icon, a name and a small line under it. A tile with a Flag flips on click (On / Off under the
-- name, lit while on; saved like any toggle). A tile with State is tinted by it ("on" green, "limited" amber,
-- "error" red, "off" plain) - :SetState(title, state, sub). A tile with only a Callback is a button.
-- tiles.Items[i] / [title] are the toggle tiles (:Set, :Get).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")
local Parts = require("elements/parts")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local list = cfg.Items or {}
    local columns = math.max(1, tonumber(cfg.Columns) or 4)
    local height, gap = tonumber(cfg.Height) or 58, 6
    local holder = create("Frame", { Name = tostring(cfg.Title or "Tiles"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Parts.gridHeight(#list, columns, gap, height)), LayoutOrder = card:_order(), Parent = card.body })
    local element = Base.element(card, "Tiles", { Title = cfg.Title }, holder, nil, nil)
    element.Items = {}
    local states = {}
    local centered = cfg.Align == "Center"
    for index, spec in ipairs(list) do
        local position, size = Parts.cell(index, columns, gap, height)
        local box = create("TextButton", { Name = tostring(spec.Title or index), Text = "", AutoButtonColor = false, BorderSizePixel = 0, Position = position, Size = size, Parent = holder })
        corner(box, 9)
        local edge = Util.stroke(box, nil, 0.1)
        local icon = spec.Icon and Icons.themed(box, spec.Icon, 15, "muted", { Name = "Icon", AnchorPoint = Vector2.new(centered and 0.5 or 0, 0), Position = centered and UDim2.new(0.5, 0, 0, 10) or UDim2.fromOffset(9, 9) })
        local title = label(box, tostring(spec.Title or ""), 10, { Name = "Title", Position = UDim2.new(0, 9, 1, -28), Size = UDim2.new(1, -18, 0, 13), TextXAlignment = centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left })
        local sub = label(box, tostring(spec.Sub or ""), 8, { Name = "Sub", Position = UDim2.new(0, 9, 1, -15), Size = UDim2.new(1, -18, 0, 11), TextXAlignment = centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left })
        Theme.bind(sub, "TextColor3", "muted")
        local function paint(lit, role)
            -- lit: a light tile; role: a state colour for the icon / outline
            Theme.tweenTo(box, "BackgroundColor3", lit and "selected" or "input", 0.12)
            Theme.tweenTo(edge, "Color", role and role ~= "muted" and role or (lit and "buttonEdge" or "line"), 0.12)
            edge.Transparency = role and role ~= "muted" and 0.45 or 0.1
            if icon then Theme.tweenTo(icon, "ImageColor3", role and role ~= "muted" and role or (lit and "heading" or "muted"), 0.12) end
            Theme.tweenTo(title, "TextColor3", lit and "heading" or "text", 0.12)
        end
        if spec.Flag ~= nil or spec.Default ~= nil and spec.State == nil then
            local item = Base.element(card, "Toggle", { Title = spec.Title, Flag = spec.Flag, Callback = spec.Callback }, box, title, nil)
            item.Value = spec.Default == true
            local function render()
                paint(item.Value, nil)
                if spec.Sub == nil then sub.Text = item.Value and "On" or "Off" end
            end
            function item:Set(on, silent)
                on = on == true
                local changed = on ~= self.Value
                self.Value = on
                render()
                self:_fire(on, silent or not changed)
            end
            function item:Get() return self.Value end
            box.Activated:Connect(function() if not item.Locked then item:Set(not item.Value) end end)
            render()
            item:_fire(item.Value, true)
            element.Items[index] = item
            element.Items[tostring(spec.Title)] = item
        elseif spec.State ~= nil then
            local function set(state, subText)
                local role = Parts.stateRole(state)
                paint(role ~= "muted", role)
                if subText ~= nil then sub.Text = tostring(subText) end
            end
            states[tostring(spec.Title)] = set
            set(spec.State, spec.Sub)
            if spec.Callback then box.Activated:Connect(function() card.window:_safe(tostring(spec.Title), spec.Callback) end) end
        else
            paint(false, nil)
            box.Activated:Connect(function() if spec.Callback then card.window:_safe(tostring(spec.Title), spec.Callback) end end)
            box.MouseEnter:Connect(function() Theme.tweenTo(box, "BackgroundColor3", "hover", 0.1) end)
            box.MouseLeave:Connect(function() Theme.tweenTo(box, "BackgroundColor3", "input", 0.1) end)
        end
        Util.hoverPop(box, 1.02)
    end
    function element:SetState(titleText, state, subText)
        local set = states[tostring(titleText)]
        if set then set(state, subText) end
    end
    return Base.finish(element, cfg)
end
