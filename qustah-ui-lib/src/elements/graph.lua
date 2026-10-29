-- card:Graph({ Title, Source = "FPS" | "Ping" | function() return number end, Max, Suffix, Height = 70, Points = 40, Interval = 0.5,
--              Style = "Bars" | "Line" })
-- A small live chart. "FPS" / "Ping" use the library's shared sampler; a function is sampled every Interval
-- seconds while the graph is on screen. :Push(value) adds a sample by hand.
-- Several lines in one chart: Style = "Line", Series = { { Name = "FPS", Source = "FPS" }, { Name = "Ping", Source = "Ping", Color = "warning" } }
-- (Color: a theme role or Color3). A legend shows each line's last value; :Push(value, "Ping") feeds one series.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Stats = require("stats")

local create, corner, label = Util.create, Util.corner, Util.label

local PALETTE = { "accent", "warning", "success", "danger", "codeGlobal", "codeKeyword" }

return function(card, cfg)
    local window = card.window
    local points = math.clamp(tonumber(cfg.Points) or 40, 5, 120)
    local height = tonumber(cfg.Height) or 70
    local function suffixFor(source, given)
        return given or (source == "Ping" and " ms" or (source == "FPS" and " FPS" or ""))
    end
    -- one series unless Series is given
    local series = {}
    if type(cfg.Series) == "table" and #cfg.Series > 0 then
        for index, spec in ipairs(cfg.Series) do
            series[index] = {
                name = tostring(spec.Name or spec.Source or ("Series " .. index)), source = spec.Source,
                color = spec.Color or PALETTE[(index - 1) % #PALETTE + 1], suffix = suffixFor(spec.Source, spec.Suffix), samples = {},
            }
        end
    else
        series[1] = { name = tostring(cfg.Title or cfg.Source or "Graph"), source = cfg.Source, color = cfg.Color or "accent", suffix = suffixFor(cfg.Source, cfg.Suffix), samples = {} }
    end
    local line = cfg.Style == "Line" or #series > 1

    local holder = create("Frame", { Name = tostring(cfg.Title or "Graph"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height + 24), LayoutOrder = card:_order(), Parent = card.body })
    local title = label(holder, tostring(cfg.Title or cfg.Source or "Graph"), 11, { Name = "Title", Size = UDim2.new(1, -90, 0, 20) })
    Theme.bind(title, "TextColor3", "text")
    -- one series: its value on the right; several: a legend (dot, name, value) instead
    local value, legend
    if #series == 1 then
        value = label(holder, "--", 10, { Name = "Value", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(90, 20), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium })
        Theme.bind(value, "TextColor3", "heading")
    else
        title.Size = UDim2.new(0.35, 0, 0, 20)
        legend = create("Frame", { Name = "Legend", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.65, 0, 0, 20), Parent = holder })
        Util.list(legend, 10, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
        for index, entry in ipairs(series) do
            local item = create("Frame", { Name = entry.name, BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 20), LayoutOrder = index, Parent = legend })
            Util.list(item, 4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
            local dot = create("Frame", { Name = "Dot", Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, Parent = item })
            corner(dot, 3)
            Theme.bind(dot, "BackgroundColor3", entry.color)
            entry.legend = label(item, entry.name .. " --", 9, { Name = "Text", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 20), TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2 })
            Theme.bind(entry.legend, "TextColor3", "muted")
        end
    end
    local area = create("Frame", { Name = "Area", Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, BackgroundTransparency = 0.4, ClipsDescendants = true, Parent = holder })
    Theme.bind(area, "BackgroundColor3", "base")
    corner(area, 6)

    local bars = {}
    if line then
        -- faint guide lines at 25 / 50 / 75 %
        for _, y in ipairs({ 0.25, 0.5, 0.75 }) do
            local guide = create("Frame", { Name = "Guide", Position = UDim2.fromScale(0, y), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, BackgroundTransparency = 0.6, Parent = area })
            Theme.bind(guide, "BackgroundColor3", "line")
        end
        for _, entry in ipairs(series) do
            entry.segments = {}
            for index = 1, points - 1 do
                local segment = create("Frame", { Name = "Segment", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(0, 2), BorderSizePixel = 0, Visible = false, ZIndex = 2, Parent = area })
                corner(segment, 1)
                Theme.bind(segment, "BackgroundColor3", entry.color)
                entry.segments[index] = segment
            end
            entry.head = create("Frame", { Name = "Head", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(5, 5), BorderSizePixel = 0, Visible = false, ZIndex = 3, Parent = area })
            corner(entry.head, 3)
            Theme.bind(entry.head, "BackgroundColor3", entry.color)
        end
    else
        for index = 1, points do
            local bar = create("Frame", {
                AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((index - 1) / points, 1, 1, 0), Size = UDim2.new(1 / points, -2, 0, 0),
                BorderSizePixel = 0, BackgroundTransparency = 0.3, Parent = area,
            })
            Theme.bind(bar, "BackgroundColor3", series[1].color)
            bars[index] = bar
        end
    end

    local element = Base.element(card, "Graph", {}, holder, title, nil)
    local function top()
        local highest = tonumber(cfg.Max) or 1
        for _, entry in ipairs(series) do for _, sample in ipairs(entry.samples) do highest = math.max(highest, sample) end end
        -- without a Max a line gets some room above it (a steady value would otherwise run along the top edge)
        if line and not tonumber(cfg.Max) then highest = highest * 1.25 end
        return highest
    end
    local function text(entry)
        local last = entry.samples[#entry.samples]
        return last and (tostring(math.floor(last + 0.5)) .. entry.suffix) or "--"
    end
    local function render()
        local highest = top()
        if line then
            local size = area.AbsoluteSize
            local width, tall = size.X, size.Y
            for _, entry in ipairs(series) do
                local samples = entry.samples
                local count = #samples
                -- newest sample on the right edge, one step per point
                local function point(i)
                    local sample = samples[i]
                    local x = width * ((points - (count - i) - 1) / (points - 1))
                    local y = tall - 3 - math.clamp(sample / highest, 0, 1) * (tall - 6)
                    return x, y
                end
                for index, segment in ipairs(entry.segments) do
                    local i = count - (points - 1) + index -- the segment ends at sample i
                    if i >= 2 and width > 0 then
                        local x1, y1 = point(i - 1)
                        local x2, y2 = point(i)
                        local dx, dy = x2 - x1, y2 - y1
                        segment.Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
                        segment.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + 1, 2)
                        segment.Rotation = math.deg(math.atan2(dy, dx))
                        segment.Visible = true
                    else
                        segment.Visible = false
                    end
                end
                if count > 0 and width > 0 then
                    local x, y = point(count)
                    entry.head.Position = UDim2.fromOffset(x - 2, y)
                    entry.head.Visible = true
                end
                if entry.legend then entry.legend.Text = entry.name .. " " .. text(entry) end
            end
        else
            local samples = series[1].samples
            for index = 1, points do
                local sample = samples[#samples - points + index]
                bars[index].Size = UDim2.new(1 / points, -2, sample and math.clamp(sample / highest, 0.02, 1) or 0, 0)
            end
        end
        if value then value.Text = text(series[1]) end
    end
    local dirty = false
    local function find(name)
        if name == nil then return series[1] end
        for _, entry in ipairs(series) do if entry.name == name then return entry end end
    end
    function element:Push(sample, name)
        sample = tonumber(sample)
        local entry = find(name)
        if not sample or not entry then return end
        entry.samples[#entry.samples + 1] = sample
        if #entry.samples > points then table.remove(entry.samples, 1) end
        -- (off screen - another page, the menu hidden - only the samples are kept; drawn when it can be seen)
        if Util.shown(holder) then
            dirty = false render()
        else
            dirty = true -- (the numbers are cheap: kept current)
            for _, item in ipairs(series) do if item.legend then item.legend.Text = item.name .. " " .. text(item) end end
            if value then value.Text = text(series[1]) end
        end
    end
    function element:Set(list, name)
        local entry = find(name)
        if not entry then return end
        entry.samples = {}
        for _, sample in ipairs(list or {}) do
            sample = tonumber(sample)
            if sample then
                entry.samples[#entry.samples + 1] = sample
                if #entry.samples > points then table.remove(entry.samples, 1) end
            end
        end
        render()
    end
    function element:Get(name) local entry = find(name) return entry and entry.samples end
    area:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
    -- catch up as soon as the page shows again
    task.spawn(function()
        while window.alive and holder.Parent do
            if dirty and Util.shown(holder) then dirty = false render() end
            task.wait(0.25)
        end
    end)

    local function onScreen()
        local object = holder
        while object and object ~= window.gui do
            if object:IsA("GuiObject") and not object.Visible then return false end
            object = object.Parent
        end
        return window.visible
    end
    local polled = {}
    for _, entry in ipairs(series) do
        if entry.source == "FPS" or entry.source == "Ping" then
            Stats.start(window.Lib.maid)
            local key = entry.source == "FPS" and "fps" or "ping"
            window.maid:give(Stats.listen(function(stats) if holder.Parent then element:Push(stats[key], entry.name) end end))
        elseif type(entry.source) == "function" then
            polled[#polled + 1] = entry
        end
    end
    if #polled > 0 then
        task.spawn(function()
            while window.alive and holder.Parent do
                if onScreen() then
                    for _, entry in ipairs(polled) do
                        local ok, sample = pcall(entry.source)
                        if ok then element:Push(sample, entry.name) end
                    end
                end
                task.wait(tonumber(cfg.Interval) or 0.5)
            end
        end)
    end
    render()
    return element
end
