-- card:Gradient({ Title, Desc, Flag, Default = { Color3 start, Color3 end }, Rotation = 0, Callback = function(sequence, a, b) end })
-- Two-colour gradient (ESP fill, chams...). The row shows a preview bar; clicking it opens two colour pickers
-- (Start / End) with a Swap button. Value is { start, end }; :GetSequence() gives a ColorSequence.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local window = card.window
    local row, title, desc = Base.row(card, cfg, cfg.Desc and 40 or 30, { right = 100, button = true })
    local preview = create("TextButton", {
        Name = "Preview", Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(88, 18), Parent = row,
    })
    corner(preview, 5)
    Theme.bind(stroke(preview, nil, 0.2), "Color", "buttonEdge")
    local gradient = create("UIGradient", { Rotation = tonumber(cfg.Rotation) or 0, Parent = preview })

    -- the editor: a section of this card holding two colour pickers (no flags of their own)
    local section = create("Frame", {
        Name = "GradientEditor", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = row.LayoutOrder + 1, Visible = false, Parent = card.body,
    })
    Util.list(section, 4)
    local sub = setmetatable({ page = card.page, window = window, order = 0, body = section, frame = card.frame }, getmetatable(card))

    local element = Base.element(card, "Gradient", cfg, row, title, desc)
    local a, b = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
    local pickers = {}
    local applying = false
    local function render()
        gradient.Color = ColorSequence.new(a, b)
    end
    local function commit(silent)
        render()
        element.Value = { a, b }
        element:_fire(element.Value, true)
        if silent then return end
        element:_call(cfg.Callback, ColorSequence.new(a, b), a, b)
        for _, callback in ipairs(element._changed) do element:_call(callback, ColorSequence.new(a, b), a, b) end
    end
    pickers[1] = sub:ColorPicker({ Title = "Start", Flag = false, Default = a, Callback = function(color) if not applying then a = color commit() end end })
    pickers[2] = sub:ColorPicker({ Title = "End", Flag = false, Default = b, Callback = function(color) if not applying then b = color commit() end end })
    sub:Button({ Title = "Swap colours", Callback = function() element:Set({ b, a }) end })

    function element:Set(value, silent)
        if type(value) ~= "table" then return end
        local first, second = value[1], value[2]
        if type(first) == "string" then first = Util.fromHex(first) end
        if type(second) == "string" then second = Util.fromHex(second) end
        if typeof(first) ~= "Color3" or typeof(second) ~= "Color3" then return end
        local changed = first ~= a or second ~= b
        a, b = first, second
        applying = true
        pickers[1]:Set(a, true)
        pickers[2]:Set(b, true)
        applying = false
        commit(silent or not changed)
    end
    function element:Get() return a, b end
    function element:GetSequence() return ColorSequence.new(a, b) end
    function element:_save() return { Util.toHex(a), Util.toHex(b) } end
    function element:SetOpen(open) section.Visible = open == true end

    local function toggleOpen() if not element.Locked then section.Visible = not section.Visible end end
    row.Activated:Connect(toggleOpen)
    preview.Activated:Connect(toggleOpen)

    local default = type(cfg.Default) == "table" and cfg.Default or { Color3.fromRGB(215, 120, 120), Color3.fromRGB(120, 140, 230) }
    element:Set(default, true)
    return Base.finish(element, cfg)
end
