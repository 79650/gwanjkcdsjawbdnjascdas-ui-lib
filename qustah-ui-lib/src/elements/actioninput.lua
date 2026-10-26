-- card:ActionInput({ Icon = "plus", Placeholder, Button = "Create", Hint, Validate, Callback = function(text) end, ClearOnAction = true })
-- One field with an icon, the text and an action button inside it (Enter also runs it). Under it a hint line
-- that Validate(text) can turn into live feedback: return ok, message ("ok" green, false red, nil = plain hint).
-- :SetHint(text, state) shows a message ("ok" / "error" / nil); :Focus(); :Set(text).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label
local GREEN, RED = Color3.fromRGB(110, 200, 130), Color3.fromRGB(215, 130, 130)

return function(card, cfg)
    local window = card.window
    local holder = create("Frame", { Name = tostring(cfg.Name or cfg.Button or "ActionInput"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = card:_order(), Parent = card.body })
    Util.list(holder, 5)
    local field = create("Frame", { Name = "Field", Size = UDim2.new(1, 0, 0, 34), BorderSizePixel = 0, LayoutOrder = 1, Parent = holder })
    Theme.bind(field, "BackgroundColor3", "input")
    corner(field, 8)
    local outline = stroke(field)
    Theme.bind(outline, "Color", "buttonEdge")

    local left = 12
    local icon = cfg.Icon and Icons.themed(field, cfg.Icon, 14, "muted", { Name = "FieldIcon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 11, 0.5, 0) })
    if icon then left = 33 end

    local buttonText = tostring(cfg.Button or "OK")
    local buttonWidth = Util.textWidth(buttonText, 10, Enum.Font.GothamMedium) + 26
    local button = create("TextButton", {
        Name = "Action", Text = buttonText, TextSize = 10, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -5, 0.5, 0), Size = UDim2.fromOffset(buttonWidth, 24), Parent = field,
    })
    corner(button, 6)
    local buttonEdge = stroke(button)

    local box = create("TextBox", {
        Name = "Box", Text = "", PlaceholderText = tostring(cfg.Placeholder or ""), TextSize = 10, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, BackgroundTransparency = 1, ClipsDescendants = true,
        Position = UDim2.fromOffset(left, 0), Size = UDim2.new(1, -(left + buttonWidth + 14), 1, 0), Parent = field,
    })
    Theme.bind(box, "TextColor3", "heading")
    Theme.bind(box, "PlaceholderColor3", "muted")

    local hintRow = create("Frame", { Name = "HintRow", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 2, Parent = holder })
    local hintDot = create("Frame", { Name = "Dot", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(5, 5), BorderSizePixel = 0, Visible = false, Parent = hintRow })
    corner(hintDot, 3)
    local hint = label(hintRow, tostring(cfg.Hint or ""), 9, { Name = "Hint", Position = UDim2.fromOffset(2, 0), Size = UDim2.new(1, -2, 1, 0) })
    Theme.bind(hint, "TextColor3", "muted")
    hintRow.Visible = cfg.Hint ~= nil or cfg.Validate ~= nil

    local element = Base.element(card, "ActionInput", cfg, holder, nil, nil)
    element.Value = ""
    local ready = false
    local function style()
        Theme.tweenTo(button, "BackgroundColor3", ready and "accentDeep" or "base", 0.1)
        Theme.tweenTo(button, "TextColor3", ready and "accent" or "muted", 0.1)
        Theme.tweenTo(buttonEdge, "Color", ready and "accent" or "line", 0.1)
        buttonEdge.Transparency = ready and 0.45 or 0
    end
    function element:SetHint(text, state)
        hintRow.Visible = true
        hint.Text = tostring(text or cfg.Hint or "")
        local color = state == "ok" and GREEN or (state == "error" and RED or nil)
        hintDot.Visible = color ~= nil
        hint.Position = UDim2.fromOffset(color and 13 or 2, 0)
        if color then hint.TextColor3, hintDot.BackgroundColor3 = color, color else Theme.bind(hint, "TextColor3", "muted") end
    end
    local function validate()
        local text = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
        element.Value = text
        if text == "" then
            ready = false
            element:SetHint(cfg.Hint)
        elseif type(cfg.Validate) == "function" then
            local okCall, ok, message = pcall(cfg.Validate, text)
            if not okCall then ok, message = false, tostring(ok) end
            ready = ok ~= false
            if message then element:SetHint(message, ok == true and "ok" or (ok == false and "error" or nil)) else element:SetHint(cfg.Hint) end
        else
            ready = true
        end
        style()
    end
    local function run()
        validate()
        if not ready or element.Locked then return end
        window:_safe(tostring(cfg.Button or "Action"), cfg.Callback, element.Value)
        if cfg.ClearOnAction ~= false then box.Text = "" end
        validate()
    end
    box:GetPropertyChangedSignal("Text"):Connect(validate)
    box.Focused:Connect(function() Theme.tweenTo(outline, "Color", "accent", 0.12) outline.Transparency = 0.4 end)
    box.FocusLost:Connect(function(enter)
        Theme.tweenTo(outline, "Color", "buttonEdge", 0.12)
        outline.Transparency = 0
        if enter then run() end
    end)
    button.Activated:Connect(run)
    button.MouseEnter:Connect(function() if ready then Theme.tweenTo(button, "TextColor3", "heading", 0.1) end end)
    button.MouseLeave:Connect(style)

    function element:Set(text) box.Text = tostring(text or "") validate() end
    function element:Get() return self.Value end
    function element:Focus() pcall(function() box:CaptureFocus() end) end
    function element:Run() run() end
    validate()
    return Base.finish(element, cfg)
end
