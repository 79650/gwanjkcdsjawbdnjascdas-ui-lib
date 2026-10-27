-- UI sounds: soft clicks for buttons, toggles, tabs. Off by default.
--   Lib.Sounds.Enabled = true (or CreateWindow({ Sounds = true }) / Settings › Menu › UI sounds)
--   Lib.Sounds.Volume = 0.35
--   Lib.Sounds.Set("click", "rbxassetid://123")   your own sound for "click" | "toggle" | "tab" | "error"
--   Lib.Sounds.Play("click")
-- The defaults are Roblox's built-in ping played short and high, so nothing has to be downloaded.
local Util = require("util")

local PING = "rbxasset://sounds/electronicpingshort.wav"

local Sounds = {
    Enabled = false,
    Volume = 0.35,
    -- id, playback speed, relative volume
    Map = {
        click = { PING, 2.2, 0.35 },
        toggle = { PING, 1.8, 0.4 },
        tab = { PING, 2.6, 0.25 },
        error = { PING, 0.7, 0.5 },
    },
}

local last = {}
function Sounds.Play(name)
    if not Sounds.Enabled then return end
    local entry = Sounds.Map[name]
    if not entry then return end
    -- the same sound at most every 60 ms (a dragged slider would machine-gun otherwise)
    local now = os.clock()
    if last[name] and now - last[name] < 0.06 then return end
    last[name] = now
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = entry[1]
        sound.PlaybackSpeed = entry[2] or 1
        sound.Volume = math.clamp((tonumber(Sounds.Volume) or 0.35) * (entry[3] or 1), 0, 1)
        sound.Parent = Util.Services.SoundService
        sound:Play()
        task.delay(2, function() sound:Destroy() end)
    end)
end

function Sounds.Set(name, id, speed, volume)
    local value = tostring(id or "")
    if value:match("^%d+$") then value = "rbxassetid://" .. value end
    Sounds.Map[name] = { value, tonumber(speed) or 1, tonumber(volume) or 1 }
end

return Sounds
