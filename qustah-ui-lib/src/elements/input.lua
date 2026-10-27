-- card:Input({ Title, Desc, Flag, Default, Placeholder, Numeric, ClearOnFocus, Finished, Callback, Locked })
-- Callback runs when the box loses focus (with Finished = false it runs on every change).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local row, title, desc = Base.row(card, cfg, cfg.Desc and 40 or 30, { right = 160 })
    -- the title takes the left half, the box the right half (up to 170 px)
    title.Size = UDim2.new(0.55, -8, 0, title.Size.Y.Offset)
    if desc then desc.Size = UDim2.new(0.55, -8, 0, 14) end
    local box = create("TextBox", {
        Name = "Box", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0.45, 0, 0, 24),
        BorderSizePixel = 0, Text = "", PlaceholderText = tostring(cfg.Placeholder or ""), TextSize = 10, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = cfg.ClearOnFocus == true, ClipsDescendants = true,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
    })
    Theme.bind(box, "BackgroundColor3", "input")
    Theme.bind(box, "TextColor3", "text")
    Theme.bind(box, "PlaceholderColor3", "muted")
    corner(box, 6)
    local outline = stroke(box)
    Theme.bind(outline, "Color", "buttonEdge")
    local PAD = 9
    Util.padding(box, PAD, PAD, 0, 0)
    -- the box hugs its text (or the placeholder): the same gap left and right, up to 170 px / 45% of the row
    local function fit()
        local text = box.Text ~= "" and box.Text or box.PlaceholderText
        local most = 170
        local rowWidth = row.AbsoluteSize.X
        if rowWidth > 0 then most = math.min(most, math.floor(rowWidth * 0.45)) end
        local width = math.clamp(math.ceil(Util.textWidth(text, 10, box.Font)) + PAD * 2 + 2, 56, math.max(56, most))
        box.Size = UDim2.fromOffset(width, 24)
    end
    box:GetPropertyChangedSignal("Text"):Connect(fit)
    row:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
    fit()

    local element = Base.element(card, "Input", cfg, row, title, desc)
    local function clean(text)
        text = tostring(text or "")
        if cfg.Numeric then text = text:gsub("[^%d%.%-]", "") end
        return text
    end
    function element:Set(text, silent)
        text = clean(text)
        local changed = text ~= self.Value
        self.Value = text
        if box.Text ~= text then box.Text = text end
        self._failed = false
        self:_fire(text, silent or not changed)
        if changed and not silent then self:_accepted("success") end
    end
    function element:Get() return self.Value end
    function element:SetPlaceholder(text) box.PlaceholderText = tostring(text or "") fit() end

    box.Focused:Connect(function() Theme.tweenTo(outline, "Color", "accent", 0.1) end)
    box.FocusLost:Connect(function()
        Theme.tweenTo(outline, "Color", "buttonEdge", 0.1)
        element:Set(box.Text)
    end)
    if cfg.Finished == false then
        box:GetPropertyChangedSignal("Text"):Connect(function() element:Set(box.Text) end)
    end
    element:Set(cfg.Default or "", true)
    if cfg.Locked then box.TextEditable = false end
    return Base.finish(element, cfg)
end
