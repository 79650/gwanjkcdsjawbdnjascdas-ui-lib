-- Text glow: a light band slides across a label every few seconds, with a soft outline (Qustah's text glow).
-- Glow.add(label, { Base = "accent", Shine = "heading", Period = 3.2, Phase = 0 }) - colours are theme roles.
-- Glow.setEnabled(false) turns every glow off (plain text colour again).
local Util = require("util")
local Theme = require("theme")

local Glow = { enabled = true, items = {}, started = false }

local WHITE = Color3.new(1, 1, 1)

local function colors(fx)
    local base = Theme.get(fx.base)
    local shine = fx.shine and Theme.get(fx.shine) or base:Lerp(WHITE, 0.6)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, base), ColorSequenceKeypoint.new(0.36, base), ColorSequenceKeypoint.new(0.5, shine),
        ColorSequenceKeypoint.new(0.64, base), ColorSequenceKeypoint.new(1, base),
    }), base
end

local function apply(fx)
    local sequence, base = colors(fx)
    fx.gradient.Color = sequence
    fx.outline.Color = base
    fx.gradient.Enabled, fx.outline.Enabled = Glow.enabled, Glow.enabled
    -- with the glow on, the label is white and the gradient carries the colour
    Theme.bind(fx.label, "TextColor3", Glow.enabled and WHITE or fx.base)
end

-- The label must already be parented; it keeps its own theme role as Base.
function Glow.add(label, opts)
    opts = opts or {}
    local fx = {
        label = label, base = opts.Base or "text", shine = opts.Shine, period = opts.Period or 3.2, phase = opts.Phase or 0,
        gradient = Util.create("UIGradient", { Name = "Shine", Offset = Vector2.new(-1.2, 0), Parent = label }),
        outline = Util.create("UIStroke", {
            Name = "Glow", ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Round,
            Thickness = 1, Transparency = opts.GlowTransparency or 0.88, Parent = label,
        }),
    }
    Glow.items[#Glow.items + 1] = fx
    apply(fx)
    return fx
end

function Glow.setEnabled(enabled)
    Glow.enabled = enabled ~= false
    for _, fx in ipairs(Glow.items) do if fx.label.Parent then apply(fx) end end
end

local visible = Util.shown

-- One RenderStepped loop for all glows; hidden labels are skipped, destroyed ones dropped.
function Glow.start(maid)
    if Glow.started then return end
    Glow.started = true
    maid:connect(Util.Services.RunService.RenderStepped, function()
        if not Glow.enabled then return end
        local now = os.clock()
        for index = #Glow.items, 1, -1 do
            local fx = Glow.items[index]
            if not fx.label.Parent then
                table.remove(Glow.items, index)
            elseif visible(fx.label) then
                local p = ((now / fx.period) + fx.phase) % 1
                fx.gradient.Offset = Vector2.new(p < 0.6 and (-1.2 + (p / 0.6) * 2.4) or 1.2, 0)
            end
        end
    end)
    maid:give(function() Glow.started = false end)
    Theme.onChange(function() for _, fx in ipairs(Glow.items) do if fx.label.Parent then apply(fx) end end end)
end

return Glow
