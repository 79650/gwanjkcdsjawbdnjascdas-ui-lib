-- Context menus.
--   Window:Menu({ Items = { { Title = "Rename", Icon = "pencil", Callback = fn }, { Title = "Delete", Icon = "trash-2", Style = "Danger", Callback = fn } },
--                 At = Vector2 (screen point, default the pointer), Owner = guiObject })
-- A small list at the pointer (moved inside the screen). A click on an item runs it; a click outside, Escape or
-- another menu closes it. Returns { Frame, Close }.
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")

local create, corner, stroke = Util.create, Util.corner, Util.stroke
local ITEM = 26

return function(Window)
    function Window:Menu(cfg)
        cfg = cfg or {}
        local window = self
        self:_closePopup()
        local items = {}
        for _, entry in ipairs(cfg.Items or {}) do
            if type(entry) == "table" and entry.Title then items[#items + 1] = entry end
        end
        if #items == 0 then return nil end

        local scale = self.scale and self.scale.Scale or 1
        local width = 140
        for _, entry in ipairs(items) do
            width = math.max(width, Util.textWidth(tostring(entry.Title), 10, Enum.Font.GothamMedium) + 50)
        end
        local height = #items * ITEM + 8
        local viewport = Util.viewport()
        local at = typeof(cfg.At) == "Vector2" and cfg.At or Util.pointer()
        local x = math.clamp(at.X, 8, math.max(8, viewport.X - width * scale - 8))
        local y = at.Y + height * scale + 8 > viewport.Y and at.Y - height * scale or at.Y
        local popup = create("Frame", {
            Name = "ContextMenu", BorderSizePixel = 0, ZIndex = 260, Size = UDim2.fromOffset(width, height),
            Position = UDim2.fromOffset(x, math.max(8, y)), Parent = self.gui,
        })
        create("UIScale", { Scale = scale, Parent = popup })
        Theme.bind(popup, "BackgroundColor3", "input")
        corner(popup, 7)
        Theme.bind(stroke(popup), "Color", "buttonEdge")
        Util.padding(popup, 4, 4, 4, 4)
        Util.list(popup, 0)

        for index, entry in ipairs(items) do
            local danger = entry.Style == "Danger"
            local item = create("TextButton", {
                Name = tostring(entry.Title), Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, ITEM), LayoutOrder = index, ZIndex = 261, Parent = popup,
            })
            Theme.bind(item, "BackgroundColor3", "hover")
            corner(item, 5)
            local left = 9
            if entry.Icon and Icons.Get(entry.Icon) then
                Icons.themed(item, entry.Icon, 12, danger and "dangerText" or "muted", { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0), ZIndex = 262 })
                left = 28
            end
            local text = Util.label(item, tostring(entry.Title), 10, { Name = "Text", Position = UDim2.fromOffset(left, 0), Size = UDim2.new(1, -left - 8, 1, 0), ZIndex = 262 })
            Theme.bind(text, "TextColor3", danger and "dangerText" or "text")
            item.MouseEnter:Connect(function() Util.tween(item, 0.08, { BackgroundTransparency = 0 }) end)
            item.MouseLeave:Connect(function() Util.tween(item, 0.08, { BackgroundTransparency = 1 }) end)
            item.Activated:Connect(function()
                window:_closePopup()
                require("sounds").Play("click")
                window:_safe("Menu", entry.Callback)
            end)
        end

        local menu = { Frame = popup }
        function menu:Close()
            if window._popup and window._popup.frame == popup then window:_closePopup() end
        end
        self:_openPopup(popup, cfg.Owner, function() if popup.Parent then popup:Destroy() end end)
        return menu
    end
end
