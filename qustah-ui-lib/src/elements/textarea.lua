-- card:TextArea({ Title, Desc, Flag, Placeholder, Default, Height = 80, MaxLength, Callback, Locked })
-- A multi-line text box (notes, a script, a message). Callback runs when it loses focus (Finished = false: on
-- every change). With MaxLength a counter shows "12 / 200".
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

return function(card, cfg)
    local height = math.max(40, tonumber(cfg.Height) or 80)
    local maxLength = tonumber(cfg.MaxLength)
    local top = (cfg.Title and 20 or 0) + (cfg.Desc and 16 or 0) + (cfg.Title and 4 or 0)
    local holder = create("Frame", { Name = tostring(cfg.Title or "TextArea"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, top + height), LayoutOrder = card:_order(), Parent = card.body })
    local title, desc
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Size = UDim2.new(1, maxLength and -70 or 0, 0, 20) })
        Theme.bind(title, "TextColor3", cfg.Risky and "danger" or "text")
    end
    if cfg.Desc then
        desc = label(holder, tostring(cfg.Desc), 9, { Name = "Desc", Position = UDim2.fromOffset(0, cfg.Title and 20 or 0), Size = UDim2.new(1, 0, 0, 14) })
        Theme.bind(desc, "TextColor3", "muted")
    end
    local counter
    if maxLength then
        counter = label(holder, "", 9, { Name = "Counter", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(70, 20), TextXAlignment = Enum.TextXAlignment.Right })
        Theme.bind(counter, "TextColor3", "muted")
    end
    local box = create("TextBox", {
        Name = "Box", Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, Text = "",
        PlaceholderText = tostring(cfg.Placeholder or ""), TextSize = 10, Font = Enum.Font.Gotham, MultiLine = true, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ClearTextOnFocus = false, ClipsDescendants = true,
        Parent = holder,
    })
    Theme.bind(box, "BackgroundColor3", "input")
    Theme.bind(box, "TextColor3", "text")
    Theme.bind(box, "PlaceholderColor3", "muted")
    corner(box, 7)
    local outline = stroke(box)
    Theme.bind(outline, "Color", "buttonEdge")
    Util.padding(box, 10, 10, 8, 8)

    local element = Base.element(card, "TextArea", cfg, holder, title, desc)
    local function count()
        if counter then
            counter.Text = #box.Text .. " / " .. maxLength
            Theme.bind(counter, "TextColor3", #box.Text >= maxLength and "warning" or "muted")
        end
    end
    function element:Set(text, silent)
        text = tostring(text == nil and "" or text)
        if maxLength and #text > maxLength then text = text:sub(1, maxLength) end
        local changed = text ~= self.Value
        self.Value = text
        if box.Text ~= text then box.Text = text end
        count()
        self._failed = false
        self:_fire(text, silent or not changed)
        if changed and not silent then self:_accepted("success") end
    end
    function element:Get() return self.Value end
    box:GetPropertyChangedSignal("Text"):Connect(function()
        if maxLength and #box.Text > maxLength then box.Text = box.Text:sub(1, maxLength) return end
        count()
        if cfg.Finished == false then element:Set(box.Text) end
    end)
    box.Focused:Connect(function() Theme.tweenTo(outline, "Color", "accent", 0.1) end)
    box.FocusLost:Connect(function()
        Theme.tweenTo(outline, "Color", "buttonEdge", 0.1)
        element:Set(box.Text)
    end)
    element:Set(cfg.Default or "", true)
    if cfg.Locked then box.TextEditable = false end
    return Base.finish(element, cfg)
end
