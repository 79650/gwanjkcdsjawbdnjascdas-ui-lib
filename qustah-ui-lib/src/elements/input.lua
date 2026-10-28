-- card:Input({ Title, Desc, Flag, Default, Placeholder, Numeric, ClearOnFocus, Finished, Validate, Callback, Locked })
-- Callback runs when the box loses focus (with Finished = false it runs on every change).
-- Validate = function(text) return ok, message end: checked while typing. ok = true: green edge, false: red edge and
-- the value is not taken (the flag keeps the last good one), nil: no judgement. The message shows under the box.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local baseHeight = cfg.Desc and 40 or 30
    local row, title, desc = Base.row(card, cfg, baseHeight, { right = 160 })
    -- the title takes the left half, the box the right half (up to 170 px)
    title.Size = UDim2.new(0.55, -8, 0, title.Size.Y.Offset)
    if desc then desc.Size = UDim2.new(0.55, -8, 0, 14) end
    local box = create("TextBox", {
        Name = "Box", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0, baseHeight / 2), Size = UDim2.new(0.45, 0, 0, 24),
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
    -- measured with a hidden label in the box's own font (the UI font can be changed in Settings)
    local measure = create("TextLabel", { Name = "Measure", BackgroundTransparency = 1, TextTransparency = 1, Size = UDim2.fromOffset(0, 0), TextSize = 10, Font = box.Font, Text = "", Parent = row })
    local function textWidth(text)
        local ok, width = pcall(function()
            measure.FontFace = box.FontFace
            measure.Text = text
            return measure.TextBounds.X
        end)
        if ok and type(width) == "number" and width > 0 then return width end
        return Util.textWidth(text, 10, box.Font)
    end
    local function fit()
        local text = box.Text ~= "" and box.Text or box.PlaceholderText
        local most = 170
        local rowWidth = row.AbsoluteSize.X
        if rowWidth > 0 then most = math.min(most, math.floor(rowWidth * 0.45)) end
        local width = math.clamp(math.ceil(textWidth(text)) + PAD * 2 + 4, 56, math.max(56, most))
        box.Size = UDim2.fromOffset(width, 24)
    end
    box:GetPropertyChangedSignal("Text"):Connect(fit)
    box:GetPropertyChangedSignal("FontFace"):Connect(fit)
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

    ------------------------------------------------------------ Validate
    local focused = false
    local hint
    local state -- true / false / nil (last Validate result)
    local function edgeRole()
        if state == false then return "danger" end -- (a red edge stays until the text is fixed)
        if not focused then return "buttonEdge" end
        return state == true and "success" or "accent"
    end
    -- returns ok (true / false / nil) and shows it: edge colour + the message under the box
    local function validate(text)
        if type(cfg.Validate) ~= "function" then return nil end
        local ok, result, message = pcall(cfg.Validate, clean(text))
        if not ok then result, message = nil, nil end
        if clean(text) == "" and result == nil then message = nil end
        state = result
        element.Valid = result
        Theme.tweenTo(outline, "Color", edgeRole(), 0.1)
        local show = message ~= nil and tostring(message) ~= ""
        if show and not hint then
            hint = Util.label(row, "", 9, { Name = "Hint", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, baseHeight - 1), Size = UDim2.new(1, -4, 0, 13), TextXAlignment = Enum.TextXAlignment.Right })
        end
        if hint then
            hint.Visible = show
            hint.Text = show and tostring(message) or ""
            Theme.bind(hint, "TextColor3", result == true and "success" or (result == false and "danger" or "muted"))
        end
        row.Size = UDim2.new(1, 0, 0, baseHeight + (show and 13 or 0))
        return result
    end
    element.Validate = function(_, text) return validate(text == nil and box.Text or text) end

    box.Focused:Connect(function() focused = true Theme.tweenTo(outline, "Color", edgeRole(), 0.1) end)
    box.FocusLost:Connect(function()
        focused = false
        if validate(box.Text) == false then
            -- not taken: the value stays the last good one, the box keeps the text and the red hint
            Theme.tweenTo(outline, "Color", edgeRole(), 0.1)
            return
        end
        Theme.tweenTo(outline, "Color", edgeRole(), 0.1)
        -- a good value: its message goes away with the focus
        if hint and state ~= false then hint.Visible = false row.Size = UDim2.new(1, 0, 0, baseHeight) end
        element:Set(box.Text)
    end)
    if cfg.Validate then
        box:GetPropertyChangedSignal("Text"):Connect(function() if focused then validate(box.Text) end end)
    end
    if cfg.Finished == false then
        box:GetPropertyChangedSignal("Text"):Connect(function()
            if validate(box.Text) ~= false then element:Set(box.Text) end
        end)
    end
    element:Set(cfg.Default or "", true)
    if cfg.Validate and element.Value ~= "" then validate(element.Value) end
    if cfg.Locked then box.TextEditable = false end
    return Base.finish(element, cfg)
end
