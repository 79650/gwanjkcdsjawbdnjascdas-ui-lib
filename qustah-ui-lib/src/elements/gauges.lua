-- card:Gauges({ Size = 62, Items = {
--     { Title = "FPS", Value = 60, Max = 60, Color = "heading" },
--     { Title = "Ping", Value = 40, Max = 150, Sub = "ms", Color = "warning" },
--     { Title = "Players", Value = 2, Max = 50, Sub = "of 50" },
-- } })
-- Round gauges side by side: a ring of dots that fills up to Value / Max, the value in the middle, a small line
-- under it and the title below. Source = "FPS" | "Ping" | function() return number end keeps one live.
-- :Set(gauge, value, max?, sub?) (gauge = index or title). No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Stats = require("stats")
local Parts = require("elements/parts")

local create, label = Util.create, Util.label

return function(card, cfg)
    local window = card.window
    local list = cfg.Items or {}
    local size = tonumber(cfg.Size) or 62
    local holder = create("Frame", { Name = tostring(cfg.Title or "Gauges"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, size + 20), LayoutOrder = card:_order(), Parent = card.body })
    local element = Base.element(card, "Gauges", cfg, holder, nil, nil)
    local gauges = {}
    local count = math.max(#list, 1)
    for index, spec in ipairs(list) do
        local slot = create("Frame", { Name = tostring(spec.Title or index), BackgroundTransparency = 1, Position = UDim2.new((index - 1) / count, 0, 0, 0), Size = UDim2.new(1 / count, 0, 1, 0), Parent = holder })
        local ring = create("Frame", { Name = "Ring", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(size, size), Parent = slot })
        local set = Parts.dotRing(ring, size, math.floor(size * 0.7), 3)
        local value = label(ring, "", 13, { Name = "Value", Position = UDim2.new(0, 0, 0.5, -11), Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold })
        Theme.bind(value, "TextColor3", "heading")
        local sub = label(ring, tostring(spec.Sub or ""), 8, { Name = "Sub", Position = UDim2.new(0, 0, 0.5, 5), Size = UDim2.new(1, 0, 0, 10), TextXAlignment = Enum.TextXAlignment.Center })
        Theme.bind(sub, "TextColor3", "muted")
        local title = label(slot, string.upper(tostring(spec.Title or "")), 8, { Name = "Title", Position = UDim2.fromOffset(0, size + 5), Size = UDim2.new(1, 0, 0, 12), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamMedium })
        Theme.bind(title, "TextColor3", "muted")
        local gauge = { spec = spec, set = set, value = value, sub = sub, max = tonumber(spec.Max) or 100 }
        gauges[index] = gauge
        gauges[tostring(spec.Title)] = gauge
    end
    local function find(which) return type(which) == "number" and gauges[which] or gauges[tostring(which)] end
    function element:Set(which, number, max, subText)
        local gauge = find(which)
        if not gauge then return end
        if max then gauge.max = tonumber(max) or gauge.max end
        number = tonumber(number) or 0
        gauge.current = number
        local spec = gauge.spec
        gauge.value.Text = spec.Format and spec.Format(number) or tostring(math.floor(number * 10 + 0.5) / 10)
        if subText ~= nil then gauge.sub.Text = tostring(subText) end
        local fraction = number / math.max(gauge.max, 1e-6)
        if spec.Invert then fraction = 1 - fraction end
        gauge.set(fraction, Parts.color(spec.Color, "heading"))
    end
    function element:Get(which) local gauge = find(which) return gauge and gauge.current end
    for index, gauge in ipairs(gauges) do element:Set(index, gauge.spec.Value or 0) end

    local live = {}
    for index, gauge in ipairs(gauges) do if gauge.spec.Source then live[#live + 1] = index end end
    if #live > 0 then
        Stats.start(window.Lib.maid)
        window.maid:give(Stats.listen(function()
            if not holder.Parent or not Util.shown(holder) then return end
            for _, index in ipairs(live) do
                local source = gauges[index].spec.Source
                local number
                if source == "FPS" then number = Stats.fps elseif source == "Ping" then number = Stats.ping
                elseif type(source) == "function" then local ok, v = pcall(source) number = ok and tonumber(v) or nil end
                if number then element:Set(index, number) end
            end
        end))
    end
    return Base.finish(element, cfg)
end
