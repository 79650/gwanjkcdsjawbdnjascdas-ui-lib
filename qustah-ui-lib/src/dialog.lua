-- In-window dialogs.
--   Window:Dialog({ Title, Content, Buttons = { { Title = "Cancel" }, { Title = "Enable", Style = "Danger", Callback = fn } } })
--   Window:Confirm(title, content, onConfirm, confirmText, danger)
-- The menu behind is dimmed and blocked; Escape or a click on the dim area closes it (as "cancel").
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")

local create, corner, stroke, label, tween = Util.create, Util.corner, Util.stroke, Util.label, Util.tween

return function(Window)
    function Window:Dialog(cfg)
        cfg = cfg or {}
        if self._dialog then self._dialog:Close() end
        local window = self
        local overlay = create("TextButton", {
            Name = "Dialog", Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 200, Parent = self.main,
        })
        local panel = create("Frame", {
            Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 330, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, ZIndex = 201, Active = true, Parent = overlay,
        })
        create("UISizeConstraint", { MaxSize = Vector2.new(330, 400), MinSize = Vector2.new(200, 0), Parent = panel })
        Theme.bind(panel, "BackgroundColor3", "card")
        corner(panel, 8)
        Theme.bind(stroke(panel), "Color", "line")
        Util.padding(panel, 16, 16, 12, 12)
        Util.list(panel, 8)
        local title = label(panel, tostring(cfg.Title or ""), 13, { Name = "Title", Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.GothamMedium, ZIndex = 202, LayoutOrder = 1 })
        Theme.bind(title, "TextColor3", "heading")
        -- Icon = "name" before the title (red when IconColor / a Danger button says so)
        if cfg.Icon and Icons.Get(cfg.Icon) then
            Util.padding(title, 24, 0, 0, 0)
            local icon = Icons.themed(title, cfg.Icon, 16, "accent", { Name = "DialogIcon", Position = UDim2.fromOffset(-24, 2), ZIndex = 203 })
            if typeof(cfg.IconColor) == "Color3" then Theme.bind(icon, "ImageColor3", cfg.IconColor) end
        end
        if cfg.Content then
            local content = label(panel, tostring(cfg.Content), 10, {
                Name = "Content", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
                TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top, RichText = true, ZIndex = 202, LayoutOrder = 2,
            })
            Theme.bind(content, "TextColor3", "muted")
        end
        local row = create("Frame", { Name = "Buttons", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 3, ZIndex = 202, Parent = panel })
        Util.list(row, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

        local dialog = { Frame = overlay }
        function dialog:Close(result)
            if not overlay.Parent then return end
            if window._dialog == dialog then window._dialog = nil end
            overlay:Destroy()
            if result == nil then window:_safe("Dialog", cfg.OnCancel) end
        end
        local buttons = cfg.Buttons or { { Title = "OK" } }
        for index, spec in ipairs(buttons) do
            local style = spec.Style
            local button = create("TextButton", {
                Name = tostring(spec.Title or "OK"), Text = tostring(spec.Title or "OK"), TextSize = 10, Font = Enum.Font.GothamMedium,
                AutoButtonColor = false, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(70, 28),
                LayoutOrder = index, ZIndex = 203, Parent = row,
            })
            Util.padding(button, 14, 14, 0, 0)
            corner(button, 6)
            local outline = stroke(button)
            if style == "Danger" then
                Theme.bind(button, "BackgroundColor3", "dangerDeep")
                Theme.bind(button, "TextColor3", "dangerText")
                Theme.bind(outline, "Color", "dangerEdge")
            elseif style == "Primary" then
                Theme.bind(button, "BackgroundColor3", "accentDeep")
                Theme.bind(button, "TextColor3", "accent")
                Theme.bind(outline, "Color", "accent")
                outline.Transparency = 0.45
            else
                Theme.bind(button, "BackgroundColor3", "input")
                Theme.bind(button, "TextColor3", "text")
                Theme.bind(outline, "Color", "buttonEdge")
            end
            button.Activated:Connect(function()
                dialog:Close(true)
                window:_safe("Dialog", spec.Callback)
            end)
        end
        overlay.Activated:Connect(function() dialog:Close() end)
        tween(overlay, 0.15, { BackgroundTransparency = 0.35 })
        self._dialog = dialog
        return dialog
    end

    function Window:Confirm(title, content, onConfirm, confirmText, danger)
        return self:Dialog({
            Title = title, Content = content, Icon = danger and "triangle-alert" or nil, IconColor = danger and Theme.get("danger") or nil,
            Buttons = { { Title = "Cancel" }, { Title = confirmText or "Confirm", Style = danger and "Danger" or "Primary", Callback = onConfirm } },
        })
    end
end
