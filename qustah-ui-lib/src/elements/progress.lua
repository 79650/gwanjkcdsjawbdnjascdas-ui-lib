-- card:Progress({ Title, Desc, Value = 0, Max = 100, Suffix = "%", Format = function(value, max) return "3 / 10" end, Indeterminate })
-- A progress bar (farm, download, cooldown...). :Set(value), :SetMax(max), :SetIndeterminate(true) shows a moving
-- stripe for "working, no number yet". No flag (it reports, it does not configure).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local window = card.window
    local top = cfg.Desc and 38 or 22
    local row, title, desc = Base.row(card, cfg, top + 12, { right = 90, titleHeight = 22 })
    local value = label(row, "", 10, { Name = "Value", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 1), Size = UDim2.fromOffset(86, 20), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium })
    Theme.bind(value, "TextColor3", "text")
    if desc then desc.Size = UDim2.new(1, desc.Size.X.Offset, 0, 14) end
    local track = create("Frame", { Name = "Track", Position = UDim2.new(0, 0, 0, top + 4), Size = UDim2.new(1, 0, 0, 6), BorderSizePixel = 0, ClipsDescendants = true, Parent = row })
    Theme.bind(track, "BackgroundColor3", "input")
    corner(track, 3)
    local fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = track })
    Theme.bind(fill, "BackgroundColor3", "accent")
    corner(fill, 3)
    create("UIGradient", { Transparency = NumberSequence.new(0.25, 0), Parent = fill })

    local element = Base.element(card, "Progress", {}, row, title, desc)
    local max = math.max(tonumber(cfg.Max) or 100, 1e-9)
    local suffix = cfg.Suffix
    local indeterminate = false
    local function text()
        if indeterminate then return cfg.IndeterminateText or "Working..." end
        if type(cfg.Format) == "function" then
            local ok, result = pcall(cfg.Format, element.Value, max)
            if ok then return tostring(result) end
        end
        if suffix == nil and max == 100 then return math.floor(element.Value + 0.5) .. "%" end
        return math.floor(element.Value + 0.5) .. " / " .. math.floor(max + 0.5) .. (suffix and (" " .. suffix) or "")
    end
    local function render(animate)
        value.Text = text()
        if indeterminate then return end
        local ratio = math.clamp(element.Value / max, 0, 1)
        fill.Position = UDim2.fromScale(0, 0)
        if animate then Util.tween(fill, 0.25, { Size = UDim2.fromScale(ratio, 1) }) else fill.Size = UDim2.fromScale(ratio, 1) end
    end
    function element:Set(v) self.Value = math.max(0, tonumber(v) or 0) render(true) end
    function element:SetMax(m) max = math.max(tonumber(m) or max, 1e-9) render(true) end
    function element:Get() return self.Value, max end
    local spinner
    function element:SetIndeterminate(on)
        indeterminate = on == true
        if spinner then spinner:Disconnect() spinner = nil end
        if indeterminate then
            fill.Size = UDim2.fromScale(0.3, 1)
            local started = os.clock()
            spinner = window.maid:connect(Util.Services.RunService.Heartbeat, function()
                if not row.Parent then return end
                local t = ((os.clock() - started) / 1.2) % 1
                fill.Position = UDim2.fromScale(-0.3 + t * 1.3, 0)
            end)
        end
        render(false)
    end
    element.Value = math.max(0, tonumber(cfg.Value or cfg.Default) or 0)
    render(false)
    if cfg.Indeterminate then element:SetIndeterminate(true) end
    return element
end
