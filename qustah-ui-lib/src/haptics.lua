-- Haptics: a short buzz on phones / controllers for presses and notifications (Roblox HapticEffect).
--   Lib.Haptics.Enabled (default: on for touch screens), Lib.Haptics.Play("click" | "notify")
-- Silent on devices / clients without HapticEffect.
local Util = require("util")

local Haptics = { Enabled = Util.isTouch() }

local TYPES
local function types()
    if TYPES ~= nil then return TYPES end
    TYPES = false
    pcall(function()
        Instance.new("HapticEffect"):Destroy() -- (older clients don't have the class)
        TYPES = { click = Enum.HapticEffectType.UIHover, notify = Enum.HapticEffectType.UIClick }
    end)
    return TYPES
end

local pool = {}
local last = 0
function Haptics.Play(kind)
    if not Haptics.Enabled then return end
    local list = types()
    local hapticType = list and list[kind or "click"]
    if not hapticType then return end
    local now = os.clock()
    if now - last < 0.04 then return end -- a dragged slider would buzz non-stop
    last = now
    pcall(function()
        local effect = pool[kind]
        if not (effect and effect.Parent) then
            effect = Instance.new("HapticEffect")
            effect.Type = hapticType
            effect.Parent = Util.guiParent()
            pool[kind] = effect
        end
        effect:Play()
    end)
end

function Haptics.Clear()
    for kind, effect in pairs(pool) do pcall(effect.Destroy, effect) pool[kind] = nil end
end

return Haptics
