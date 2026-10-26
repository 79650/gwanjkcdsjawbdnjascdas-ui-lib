-- Notification history: a bell in the window header (left of minimize) with an unread dot; it opens a list of
-- the last 50 notifications. CreateWindow({ NotificationHistory = false }) leaves it out.
--   Window:OpenInbox(), Window:ClearInbox()
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label
local HEADER = 44

return function(Window)
    function Window:_buildInbox()
        if self.cfg.NotificationHistory == false then return end
        local Lib = self.Lib
        local button = self._windowButton("Inbox", self:_headerSlot(), false, true)
        -- bell drawn from frames: dome, rim, clapper (no glyphs / images needed)
        local parts = {}
        local function part(props, radius)
            local object = create("Frame", props)
            object.BorderSizePixel = 0
            object.Parent = button
            if radius then corner(object, radius) end
            Theme.bind(object, "BackgroundColor3", "muted")
            parts[#parts + 1] = object
            return object
        end
        part({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(8, 9) }, 4)
        part({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 15), Size = UDim2.fromOffset(12, 2) }, 1)
        part({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 18), Size = UDim2.fromOffset(3, 2) }, 1)
        local dot = create("Frame", { Name = "Unread", Position = UDim2.new(0.5, 3, 0, 6), Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, Visible = false, ZIndex = 3, Parent = button })
        corner(dot, 3)
        Theme.bind(dot, "BackgroundColor3", "accent")
        Theme.bind(stroke(dot, nil, 0, 1.5), "Color", "base")
        button.MouseEnter:Connect(function() for _, p in ipairs(parts) do Theme.tweenTo(p, "BackgroundColor3", "heading", 0.12) end end)
        button.MouseLeave:Connect(function() for _, p in ipairs(parts) do Theme.tweenTo(p, "BackgroundColor3", "muted", 0.12) end end)

        local seen = 0
        local panel
        local function unread()
            local history = Lib.NotifyHistory or {}
            local count = 0
            for _, entry in ipairs(history) do if entry.Time and entry._id and entry._id > seen then count = count + 1 end end
            return count
        end
        -- ids so "unread" survives the list being trimmed
        local nextId = 0
        local function stamp()
            for index = #(Lib.NotifyHistory or {}), 1, -1 do
                local entry = Lib.NotifyHistory[index]
                if not entry._id then nextId = nextId + 1 entry._id = nextId end
            end
        end
        local function close()
            if panel then panel:Destroy() panel = nil end
        end
        local function render()
            if not panel then return end
            local list = panel:FindFirstChild("List")
            for _, child in ipairs(list:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
            local history = Lib.NotifyHistory or {}
            panel:FindFirstChild("Empty").Visible = #history == 0
            for index, entry in ipairs(history) do
                local item = create("Frame", { Name = "Entry", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, entry.Content and 38 or 24), LayoutOrder = index, ZIndex = 232, Parent = list })
                local mark = create("Frame", { Position = UDim2.fromOffset(0, 5), Size = UDim2.new(0, 2, 1, -10), BorderSizePixel = 0, ZIndex = 233, Parent = item })
                corner(mark, 1)
                if typeof(entry.Color) == "Color3" then mark.BackgroundColor3 = entry.Color else Theme.bind(mark, "BackgroundColor3", "accent") end
                local entryIcon = entry.Icon and Icons.themed(item, entry.Icon, 12, "accent", { Position = UDim2.fromOffset(10, 5), ZIndex = 233 })
                if entryIcon and typeof(entry.Color) == "Color3" then Theme.bind(entryIcon, "ImageColor3", entry.Color) end
                local title = label(item, entry.Title, 10, { Position = UDim2.fromOffset(entryIcon and 28 or 10, 3), Size = UDim2.new(1, entryIcon and -82 or -64, 0, 16), Font = Enum.Font.GothamMedium, ZIndex = 233 })
                Theme.bind(title, "TextColor3", "heading")
                local time = label(item, Util.ago(entry.Time), 9, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 3), Size = UDim2.fromOffset(54, 16), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 233 })
                Theme.bind(time, "TextColor3", "muted")
                if entry.Content then
                    local content = label(item, entry.Content, 9, { Position = UDim2.fromOffset(entryIcon and 28 or 10, 19), Size = UDim2.new(1, entryIcon and -28 or -10, 0, 14), ZIndex = 233 })
                    Theme.bind(content, "TextColor3", "muted")
                end
            end
        end
        function self:OpenInbox()
            close()
            stamp()
            panel = create("Frame", {
                Name = "InboxPanel", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, HEADER - 4), Size = UDim2.fromOffset(270, 260),
                BorderSizePixel = 0, ZIndex = 230, Active = true, Parent = self.main,
            })
            Theme.bind(panel, "BackgroundColor3", "card")
            corner(panel, 8)
            Theme.bind(stroke(panel), "Color", "line")
            local heading = label(panel, "Notifications", 11, { Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -90, 0, 20), Font = Enum.Font.GothamMedium, ZIndex = 231 })
            Theme.bind(heading, "TextColor3", "heading")
            local clear = create("TextButton", {
                Name = "Clear", Text = "Clear", TextSize = 9, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BorderSizePixel = 0,
                AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 9), Size = UDim2.fromOffset(44, 18), ZIndex = 231, Parent = panel,
            })
            Theme.bind(clear, "BackgroundColor3", "input")
            Theme.bind(clear, "TextColor3", "text")
            corner(clear, 5)
            Theme.bind(stroke(clear), "Color", "buttonEdge")
            clear.Activated:Connect(function() self:ClearInbox() end)
            local line = create("Frame", { Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 1), BorderSizePixel = 0, ZIndex = 231, Parent = panel })
            Theme.bind(line, "BackgroundColor3", "line")
            local list = create("ScrollingFrame", {
                Name = "List", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(14, 40), Size = UDim2.new(1, -22, 1, -48),
                CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollingDirection = Enum.ScrollingDirection.Y,
                ZIndex = 231, Parent = panel,
            })
            Theme.bind(list, "ScrollBarImageColor3", "muted")
            Util.list(list, 2)
            local empty = label(panel, "No notifications yet", 10, { Name = "Empty", Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -48), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 231 })
            Theme.bind(empty, "TextColor3", "muted")
            render()
            seen = nextId
            dot.Visible = false
            self:_openPopup(panel, button, close)
        end
        function self:ClearInbox()
            Lib.NotifyHistory = {}
            render()
            dot.Visible = false
        end
        button.Activated:Connect(function()
            if panel then self:_closePopup() else self:OpenInbox() end
        end)
        Lib._historyListeners = Lib._historyListeners or {}
        local function listener()
            if not self.alive then return end
            stamp()
            if panel then render() seen = nextId else dot.Visible = unread() > 0 end
        end
        table.insert(Lib._historyListeners, listener)
        self.maid:give(function()
            local index = table.find(Lib._historyListeners, listener)
            if index then table.remove(Lib._historyListeners, index) end
        end)
        self.inboxButton = button
    end
end
