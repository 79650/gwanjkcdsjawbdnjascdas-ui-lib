-- card:Graph({ Title, Source = "FPS" | "Ping" | function() return number end, Max, Suffix, Height = 70, Points = 40, Interval = 0.5 })
-- A small live bar chart. "FPS" / "Ping" use the library's shared sampler; a function is sampled every Interval
-- seconds while the graph is on screen. :Push(value) adds a sample by hand.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Stats = require("stats")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local window = card.window
    local points = math.clamp(tonumber(cfg.Points) or 40, 5, 120)
    local height = tonumber(cfg.Height) or 70
    local suffix = cfg.Suffix or (cfg.Source == "Ping" and " ms" or (cfg.Source == "FPS" and " FPS" or ""))
    local holder = create("Frame", { Name = tostring(cfg.Title or "Graph"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height + 24), LayoutOrder = card:_order(), Parent = card.body })
    local title = label(holder, tostring(cfg.Title or cfg.Source or "Graph"), 11, { Name = "Title", Size = UDim2.new(1, -90, 0, 20) })
    Theme.bind(title, "TextColor3", "text")
    local value = label(holder, "--", 10, { Name = "Value", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(90, 20), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium })
    Theme.bind(value, "TextColor3", "heading")
    local area = create("Frame", { Name = "Area", Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, BackgroundTransparency = 0.4, ClipsDescendants = true, Parent = holder })
    Theme.bind(area, "BackgroundColor3", "base")
    corner(area, 6)
    local bars = {}
    for index = 1, points do
        local bar = create("Frame", {
            AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((index - 1) / points, 1, 1, 0), Size = UDim2.new(1 / points, -2, 0, 0),
            BorderSizePixel = 0, BackgroundTransparency = 0.3, Parent = area,
        })
        Theme.bind(bar, "BackgroundColor3", "accent")
        bars[index] = bar
    end

    local element = Base.element(card, "Graph", {}, holder, title, nil)
    local samples = {}
    local function render()
        local top = tonumber(cfg.Max) or 1
        for _, sample in ipairs(samples) do top = math.max(top, sample) end
        for index = 1, points do
            local sample = samples[#samples - points + index]
            bars[index].Size = UDim2.new(1 / points, -2, sample and math.clamp(sample / top, 0.02, 1) or 0, 0)
        end
        local last = samples[#samples]
        value.Text = last and (tostring(math.floor(last + 0.5)) .. suffix) or "--"
    end
    function element:Push(sample)
        sample = tonumber(sample)
        if not sample then return end
        samples[#samples + 1] = sample
        if #samples > points then table.remove(samples, 1) end
        render()
    end
    function element:Set(list) samples = {} for _, sample in ipairs(list or {}) do self:Push(sample) end render() end

    local function onScreen()
        local object = holder
        while object and object ~= window.gui do
            if object:IsA("GuiObject") and not object.Visible then return false end
            object = object.Parent
        end
        return window.visible
    end
    if cfg.Source == "FPS" or cfg.Source == "Ping" then
        Stats.start(window.Lib.maid)
        local key = cfg.Source == "FPS" and "fps" or "ping"
        window.maid:give(Stats.listen(function(stats) if holder.Parent then element:Push(stats[key]) end end))
    elseif type(cfg.Source) == "function" then
        task.spawn(function()
            while window.alive and holder.Parent do
                if onScreen() then
                    local ok, sample = pcall(cfg.Source)
                    if ok then element:Push(sample) end
                end
                task.wait(tonumber(cfg.Interval) or 0.5)
            end
        end)
    end
    render()
    return element
end
