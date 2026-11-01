-- card:Checklist({ Items = { { Title = "File access", Ok = true, Note = "profiles, icons" }, { Title = "getconnections", Ok = false, Note = "Anti-AFK" } } })
-- A list of checks: a green tick or a red cross, the name, a muted note on the right. Ok = nil shows a grey dash
-- (unknown / not checked). :Set(title, ok, note), :Count() -> passed, total. No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, label = Util.create, Util.label

return function(card, cfg)
    local holder = create("Frame", { Name = tostring(cfg.Title or "Checklist"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = card:_order(), Parent = card.body })
    Util.list(holder, 0)
    local element = Base.element(card, "Checklist", { Title = cfg.Title }, holder, nil, nil)
    local rows, order = {}, {}
    local function paint(row)
        local icon = row.ok == true and "check" or row.ok == false and "x" or "minus"
        local role = row.ok == true and "success" or row.ok == false and "danger" or "muted"
        if row.icon then row.icon:Destroy() end
        row.icon = Icons.themed(row.frame, icon, 12, role, { Name = "Mark", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) })
        row.note.Text = tostring(row.noteText or "")
    end
    for index, item in ipairs(cfg.Items or {}) do
        local frame = create("Frame", { Name = tostring(item.Title or index), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = index, Parent = holder })
        local title = label(frame, tostring(item.Title or ""), 10, { Name = "Title", Position = UDim2.fromOffset(20, 0), Size = UDim2.new(0.6, -20, 1, 0) })
        Theme.bind(title, "TextColor3", "text")
        local note = label(frame, "", 9, { Name = "Note", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.4, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Right })
        Theme.bind(note, "TextColor3", "muted")
        local row = { frame = frame, note = note, ok = item.Ok, noteText = item.Note }
        rows[tostring(item.Title)] = row
        order[#order + 1] = row
        paint(row)
    end
    function element:Set(titleText, ok, note)
        local row = rows[tostring(titleText)]
        if not row then return end
        row.ok = ok
        if note ~= nil then row.noteText = note end
        paint(row)
    end
    function element:Count()
        local passed = 0
        for _, row in ipairs(order) do if row.ok == true then passed = passed + 1 end end
        return passed, #order
    end
    return Base.finish(element, cfg)
end
