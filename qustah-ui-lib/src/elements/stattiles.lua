-- card:StatTiles({ Columns = 4, Tiles = {
--     { Title = "FPS", Source = "FPS" },                                   -- live (the library's sampler)
--     { Title = "Ping", Source = "Ping", Suffix = " ms", Color = "warning" },
--     { Title = "Memory", Value = "26 MB", Sub = "Lua", History = { 20, 22, 26 }, Color = Color3.fromRGB(180, 140, 232) },
-- } })
-- KPI tiles: a small caps title, a big value, a muted line under it and a sparkline of its history.
-- Source = "FPS" | "Ping" | function() return number end (sampled every Interval = 0.5 s while in view; Sub shows
-- "avg ..." on its own). :Set(tile, { Value, Sub }) (tile = index or title), :Push(tile, number) adds to the line.
-- No flag (it shows numbers).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Stats = require("stats")
local Parts = require("elements/parts")

local create, label = Util.create, Util.label

return function(card, cfg)
    local window = card.window
    local list = cfg.Tiles or {}
    local columns = math.max(1, tonumber(cfg.Columns) or math.min(#list, 4))
    local height, gap = tonumber(cfg.Height) or 74, 6
    local holder = create("Frame", { Name = tostring(cfg.Title or "StatTiles"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Parts.gridHeight(#list, columns, gap, height)), LayoutOrder = card:_order(), Parent = card.body })
    local element = Base.element(card, "StatTiles", cfg, holder, nil, nil)
    local tiles = {}
    for index, spec in ipairs(list) do
        local position, size = Parts.cell(index, columns, gap, height)
        local box = Parts.box(holder, { Name = tostring(spec.Title or index), Position = position, Size = size })
        local title = label(box, string.upper(tostring(spec.Title or "")), 8, { Name = "Title", Position = UDim2.fromOffset(9, 6), Size = UDim2.new(1, -18, 0, 12), Font = Enum.Font.GothamMedium })
        Theme.bind(title, "TextColor3", "muted")
        local value = label(box, tostring(spec.Value or "-"), 15, { Name = "Value", Position = UDim2.fromOffset(9, 18), Size = UDim2.new(1, -18, 0, 20), Font = Enum.Font.GothamBold })
        Theme.bind(value, "TextColor3", "heading")
        local sub = label(box, tostring(spec.Sub or ""), 8, { Name = "Sub", Position = UDim2.fromOffset(9, 37), Size = UDim2.new(1, -18, 0, 11) })
        Theme.bind(sub, "TextColor3", "muted")
        local spark = create("Frame", { Name = "Line", BackgroundTransparency = 1, Position = UDim2.new(0, 8, 1, -24), Size = UDim2.new(1, -16, 0, 18), Parent = box })
        local draw = Parts.sparkline(spark, Parts.color(spec.Color, "heading"), Parts.scaleOf(window))
        local tile = { spec = spec, box = box, value = value, sub = sub, draw = draw, history = table.clone(spec.History or {}) }
        tiles[index] = tile
        tiles[tostring(spec.Title)] = tile
        task.defer(draw, tile.history)
    end
    local function find(which) return type(which) == "number" and tiles[which] or tiles[tostring(which)] end
    function element:Set(which, data)
        local tile = find(which)
        if not tile then return end
        if type(data) ~= "table" then data = { Value = data } end
        if data.Value ~= nil then tile.value.Text = tostring(data.Value) end
        if data.Sub ~= nil then tile.sub.Text = tostring(data.Sub) end
    end
    function element:Push(which, number, keep)
        local tile = find(which)
        if not tile or type(number) ~= "number" then return end
        table.insert(tile.history, number)
        while #tile.history > (keep or 30) do table.remove(tile.history, 1) end
        if Util.shown(holder) then tile.draw(tile.history) end
    end
    function element:Get(which) local tile = find(which) return tile and tile.value.Text end

    -- live tiles
    local live = {}
    for index, tile in ipairs(tiles) do if tile.spec.Source then live[#live + 1] = index end end
    if #live > 0 then
        local function sample(index)
            local spec = tiles[index].spec
            local number
            if spec.Source == "FPS" then number = Stats.fps elseif spec.Source == "Ping" then number = Stats.ping
            elseif type(spec.Source) == "function" then local ok, v = pcall(spec.Source) number = ok and tonumber(v) or nil end
            if not number then return end
            element:Push(index, number)
            local sum = 0
            for _, v in ipairs(tiles[index].history) do sum = sum + v end
            local average = sum / math.max(#tiles[index].history, 1)
            local fmt = spec.Format or function(v) return tostring(math.floor(v + 0.5)) .. (spec.Suffix or "") end
            element:Set(index, { Value = fmt(number), Sub = spec.Sub or ("avg " .. fmt(average)) })
        end
        Stats.start(window.Lib.maid)
        -- (only while the tiles are on screen: nothing runs for a closed menu or another page)
        window.maid:give(Stats.listen(function()
            if not holder.Parent or not Util.shown(holder) then return end
            for _, index in ipairs(live) do if tiles[index].spec.Source == "FPS" or tiles[index].spec.Source == "Ping" then sample(index) end end
        end))
        task.spawn(function()
            while holder.Parent and window.alive ~= false do
                for _, index in ipairs(live) do if type(tiles[index].spec.Source) == "function" and Util.shown(holder) then sample(index) end end
                task.wait(tonumber(cfg.Interval) or 0.5)
            end
        end)
    end
    return Base.finish(element, cfg)
end
