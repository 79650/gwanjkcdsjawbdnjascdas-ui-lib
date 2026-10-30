-- card:Info({ Title = "User ID", Value = "#123", Copy = true | "text to copy" | function() return ... end })
-- A read-only "name ........ value" row; :Set(value) updates it. With Copy a small Copy button copies the value.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

return function(card, cfg)
    local row = create("Frame", { Name = tostring(cfg.Title or "Info"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = card:_order(), Parent = card.body })
    local title = label(row, tostring(cfg.Title or ""), 10, { Name = "Title", Size = UDim2.new(0.42, -6, 1, 0) })
    Theme.bind(title, "TextColor3", "muted")
    local copyWidth = cfg.Copy and 40 or 0
    local value = label(row, "", 10, {
        Name = "Value", Position = UDim2.new(0.42, copyWidth, 0, 0), Size = UDim2.new(0.58, -copyWidth, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium,
    })
    Theme.bind(value, "TextColor3", "text")

    local element = Base.element(card, "Info", {}, row, title, nil)
    -- without a Copy button a long value borrows room from the name (down to what the name needs),
    -- so a long value ("Limited · client-side only") isn't cut next to a short name
    local function share()
        if cfg.Copy then return end
        local scale = card.window.scale and card.window.scale.Scale or 1
        local width = row.AbsoluteSize.X / scale
        if width <= 0 then return end
        local need = Util.textWidth(title.Text, 10, Enum.Font.Gotham) + 10
        local valueNeed = Util.textWidth(value.Text, 10, Enum.Font.GothamMedium)
        -- 42% for the name; less when the value needs it (never less than the name needs), more when a long name fits
        local titleWidth = width * 0.42
        if need > titleWidth then
            titleWidth = math.max(titleWidth, math.min(need, width - valueNeed - 8)) -- a long name takes what a short value leaves
        elseif valueNeed + 10 > width - titleWidth then
            titleWidth = math.max(need, width - valueNeed - 10) -- (a little slack: fonts measure a few px wider on some screens)
        end
        title.Size = UDim2.new(0, titleWidth - 6, 1, 0)
        value.Position = UDim2.new(0, titleWidth, 0, 0)
        value.Size = UDim2.new(1, -titleWidth, 1, 0)
    end
    row:GetPropertyChangedSignal("AbsoluteSize"):Connect(share)
    function element:Set(text) self.Value = text value.Text = tostring(text) share() end
    function element:Get() return self.Value end
    -- a theme role ("success") or a Color3
    function element:SetColor(color) Theme.bind(value, "TextColor3", color or "text") end

    if cfg.Copy then
        local copy = create("TextButton", {
            Name = "Copy", Text = "Copy", TextSize = 8, Font = Enum.Font.Gotham, AutoButtonColor = false, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.42, 0, 0.5, 0), Size = UDim2.fromOffset(34, 16), Parent = row,
        })
        Theme.bind(copy, "BackgroundColor3", "input")
        Theme.bind(copy, "TextColor3", "text")
        corner(copy, 5)
        Theme.bind(stroke(copy), "Color", "buttonEdge")
        copy.Activated:Connect(function()
            local text = cfg.Copy
            if type(text) == "function" then local ok, result = pcall(text) text = ok and result or nil end
            if text == true or text == nil then text = tostring(element.Value):gsub("^#", "") end
            local clipboard = setclipboard or toclipboard
            local ok = type(clipboard) == "function" and pcall(clipboard, tostring(text))
            copy.Text = ok and "OK" or "!"
            task.delay(1.2, function() if copy.Parent then copy.Text = "Copy" end end)
            if ok then card.window:Notify({ Title = "Copied", Content = tostring(cfg.Title or "Value") .. " copied to clipboard" }) end
        end)
    end
    element:Set(cfg.Value ~= nil and cfg.Value or "--")
    return element
end
