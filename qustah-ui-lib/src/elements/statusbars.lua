-- card:StatusBars({ Slots = 30, Items = {
--     { Title = "ESP", State = "on", History = { "on", "on", "off", ... } },
--     { Title = "Misc", State = "limited" },
-- } })
-- A status-page row per item: its name, its state on the right ("Running" / "Limited" / "Off" / "Error", coloured),
-- and a strip of Slots small bars, one per sample (oldest left): green on, amber limited, red error, grey off.
-- :Push(title, state) adds a sample (and sets the state), :SetState(title, state, text). No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Parts = require("elements/parts")

local create, corner, label = Util.create, Util.corner, Util.label

local WORDS = { success = "Running", warning = "Limited", danger = "Error", muted = "Off" }

return function(card, cfg)
    local slots = math.max(5, tonumber(cfg.Slots) or 30)
    local holder = create("Frame", { Name = tostring(cfg.Title or "StatusBars"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = card:_order(), Parent = card.body })
    Util.list(holder, 2)
    local element = Base.element(card, "StatusBars", { Title = cfg.Title }, holder, nil, nil)
    local rows = {}
    local function paint(row)
        local count = #row.history
        for i, bar in ipairs(row.bars) do
            local state = row.history[count - slots + i]
            local role = state ~= nil and Parts.stateRole(state) or "line"
            Theme.bind(bar, "BackgroundColor3", role == "muted" and "buttonEdge" or role)
            bar.BackgroundTransparency = state == nil and 0.4 or (i > slots - 6 and 0 or 0.3)
        end
    end
    function element:SetState(titleText, stateName, text)
        local row = rows[tostring(titleText)]
        if not row then return end
        local role = Parts.stateRole(stateName)
        row.state.Text = text and tostring(text) or WORDS[role] or tostring(stateName)
        Theme.bind(row.state, "TextColor3", role)
        row.current = stateName
    end
    function element:Push(titleText, stateName)
        local row = rows[tostring(titleText)]
        if not row then return end
        row.history[#row.history + 1] = stateName
        while #row.history > slots do table.remove(row.history, 1) end
        self:SetState(titleText, stateName)
        paint(row)
    end
    for index, item in ipairs(cfg.Items or {}) do
        local frame = create("Frame", { Name = tostring(item.Title or index), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), LayoutOrder = index, Parent = holder })
        local title = label(frame, tostring(item.Title or ""), 10, { Name = "Title", Size = UDim2.new(1, -90, 0, 18) })
        Theme.bind(title, "TextColor3", "text")
        local state = label(frame, "", 9, { Name = "State", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(90, 18), TextXAlignment = Enum.TextXAlignment.Right })
        local strip = create("Frame", { Name = "Strip", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 12), Parent = frame })
        local bars = {}
        for i = 1, slots do
            local bar = create("Frame", { Name = "Bar", BorderSizePixel = 0, Position = UDim2.new((i - 1) / slots, (i - 1) * 2 / slots, 0, 0), Size = UDim2.new(1 / slots, -2 * (slots - 1) / slots, 1, 0), Parent = strip })
            corner(bar, 2)
            bars[i] = bar
        end
        local row = { title = title, state = state, bars = bars, history = table.clone(item.History or {}) }
        rows[tostring(item.Title)] = row
        rows[index] = row
        element:SetState(item.Title, item.State)
        paint(row)
    end
    return Base.finish(element, cfg)
end
