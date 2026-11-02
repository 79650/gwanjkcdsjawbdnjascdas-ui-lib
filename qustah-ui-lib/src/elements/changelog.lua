-- card:Changelog({ Items = {
--     { Version = "V1.00 · rev 571", Time = "now", Items = { "Click TP: the game's own teleport", "ESP: bars under the feet" } },
--     { Version = "rev 560", Time = "3 days ago", Items = { "Crosshair from the library" } },
-- }, Open = 1 })
-- Release notes: one row per version (bold version, muted time, a chevron); click a row to open its bullet list.
-- The Open-th entry starts open (0 = none). :SetItems(entries), :Open(index). No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, label = Util.create, Util.label
local BULLET = 12 -- (the text starts this far right of the bullet)

return function(card, cfg)
    local holder = create("Frame", { Name = tostring(cfg.Title or "Changelog"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = card:_order(), Parent = card.body })
    Util.list(holder, 0)
    local element = Base.element(card, "Changelog", { Title = cfg.Title }, holder, nil, nil)
    local entries = {}
    function element:Open(index)
        for i, entry in ipairs(entries) do
            local open = i == index and not entry.body.Visible
            entry.body.Visible = open
            if entry.chevron then Util.tween(entry.chevron, 0.15, { Rotation = open and 180 or 0 }) end
        end
    end
    function element:SetItems(list)
        for _, entry in ipairs(entries) do entry.frame:Destroy() end
        table.clear(entries)
        for index, data in ipairs(list or {}) do
            local frame = create("Frame", { Name = tostring(data.Version or index), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = index, Parent = holder })
            Util.list(frame, 0)
            local head = create("TextButton", { Name = "Head", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 1, Parent = frame })
            local version = label(head, tostring(data.Version or ""), 10, { Name = "Version", Size = UDim2.new(0, Util.textWidth(tostring(data.Version or ""), 10, Enum.Font.GothamBold) + 4, 1, 0), Font = Enum.Font.GothamBold })
            Theme.bind(version, "TextColor3", "heading")
            local time = label(head, tostring(data.Time or ""), 9, { Name = "Time", Position = UDim2.fromOffset(version.Size.X.Offset + 6, 0), Size = UDim2.new(1, -version.Size.X.Offset - 30, 1, 0) })
            Theme.bind(time, "TextColor3", "muted")
            local chevron = Icons.themed(head, "chevron-down", 12, "muted", { Name = "Chevron", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0) })
            local body = create("Frame", { Name = "Items", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Visible = false, Parent = frame })
            Util.list(body, 1)
            Util.padding(body, 8, 0, 0, 6)
            local lines = {}
            for order, text in ipairs(data.Items or {}) do
                -- the bullet on its own, the text beside it (a wrapped line starts under the text, not the bullet)
                local item = create("Frame", { Name = "Item", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = order, Parent = body })
                local dot = label(item, "•", 10, { Name = "Bullet", Size = UDim2.fromOffset(10, 13), TextYAlignment = Enum.TextYAlignment.Top })
                Theme.bind(dot, "TextColor3", "muted")
                local words = label(item, tostring(text), 10, { Name = "Text", Position = UDim2.fromOffset(BULLET, 0), Size = UDim2.new(1, -BULLET, 1, 0), TextWrapped = true, TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top })
                Theme.bind(words, "TextColor3", "text")
                lines[#lines + 1] = { frame = item, text = words }
            end
            -- each note as tall as its wrapped lines (measured from the text width, not left to AutomaticSize)
            local function wrap()
                local scale = card.window.scale and card.window.scale.Scale or 1
                local width = body.AbsoluteSize.X / scale - 8 - BULLET
                if width < 40 then return end
                for _, item in ipairs(lines) do
                    local count = math.max(1, math.ceil((Util.textWidth(item.text.Text, 10, Enum.Font.Gotham) * 1.08 + 6) / width))
                    item.frame.Size = UDim2.new(1, 0, 0, count * 13 + 1)
                end
            end
            body:GetPropertyChangedSignal("AbsoluteSize"):Connect(wrap)
            body:GetPropertyChangedSignal("Visible"):Connect(function() task.defer(wrap) end)
            task.defer(wrap)
            local line = create("Frame", { Name = "Line", Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, LayoutOrder = 3, Parent = frame })
            Theme.bind(line, "BackgroundColor3", "line")
            local entry = { frame = frame, body = body, chevron = chevron }
            entries[index] = entry
            head.Activated:Connect(function() element:Open(index) end)
        end
        local open = tonumber(cfg.Open) or 1
        if entries[open] then entries[open].body.Visible = true if entries[open].chevron then entries[open].chevron.Rotation = 180 end end
    end
    element:SetItems(cfg.Items)
    return Base.finish(element, cfg)
end
