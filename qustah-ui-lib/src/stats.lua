-- Shared FPS / ping sampler (one RenderStepped counter for the whole library, started on first use).
-- Stats.fps, Stats.ping (ms), Stats.history.fps / .ping (last 60 samples, one every 0.5 s).
local Util = require("util")

local Services = Util.Services

local Stats = { fps = 0, ping = 0, history = { fps = {}, ping = {} }, running = false }
local listeners = {}
local HISTORY = 60

function Stats.start(maid)
    if Stats.running then return end
    Stats.running = true
    local frames, last = 0, os.clock()
    maid:connect(Services.RunService.RenderStepped, function() frames = frames + 1 end)
    task.spawn(function()
        while Stats.running do
            task.wait(0.5)
            local now = os.clock()
            Stats.fps = math.floor(frames / math.max(now - last, 1e-3) + 0.5)
            frames, last = 0, now
            local ok, ping = pcall(function() return Services.Players.LocalPlayer:GetNetworkPing() * 1000 end)
            Stats.ping = ok and math.floor(ping + 0.5) or Stats.ping
            for key, value in pairs({ fps = Stats.fps, ping = Stats.ping }) do
                local list = Stats.history[key]
                list[#list + 1] = value
                if #list > HISTORY then table.remove(list, 1) end
            end
            for _, listener in ipairs(listeners) do Util.safe(listener, Stats) end
        end
    end)
    maid:give(function() Stats.running = false end)
end

-- Runs callback(Stats) after every sample; returns a function that removes it.
function Stats.listen(callback)
    listeners[#listeners + 1] = callback
    return function()
        local index = table.find(listeners, callback)
        if index then table.remove(listeners, index) end
    end
end

return Stats
