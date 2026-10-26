-- Kick watcher: notices when the game disconnects you and says why.
--   Window:OnKick(function(info) end)   info = { Reason, Code, Kind, Message, Time }
--   Window:GetKicks()                    the last 20, newest first (saved in <Folder>/kicks.json)
--   Window.LastKick
-- CreateWindow({ KickLog = false }) turns it off; Rejoin = true teleports back to the same place after a kick.
-- It reads Roblox's own error prompt (GuiService), so it works for kicks from the server, anti-cheats and
-- connection drops alike.
local Util = require("util")

-- Roblox error codes that matter here
local KINDS = {
    [267] = "Kicked", [268] = "Unexpected client behaviour", [273] = "Logged in elsewhere", [274] = "Server shut down",
    [277] = "Connection lost", [278] = "Idle (AFK) disconnect", [279] = "Failed to connect", [282] = "Disconnected",
    [292] = "Game removed", [517] = "Server full", [524] = "Not allowed", [529] = "Service error", [600] = "Banned",
}

local function parse(message, code)
    message = tostring(message or "")
    code = tonumber(code) or tonumber(message:match("[Ee]rror [Cc]ode:?%s*(%d+)"))
    -- "You were kicked from this experience: <reason>" / "...game: <reason>"
    local reason = message:match("[Kk]icked from this [%a]+:%s*(.-)%s*%(?[Ee]rror [Cc]ode")
        or message:match("[Kk]icked from this [%a]+:%s*(.+)$")
        or message:match("^(.-)%s*%(?[Ee]rror [Cc]ode") or message
    reason = reason:gsub("%s+$", ""):gsub("^%s+", "")
    if reason == "" then reason = KINDS[code] or "Disconnected" end
    return { Reason = reason, Code = code, Kind = KINDS[code] or (code and ("Error " .. code)) or "Disconnected", Message = message, Time = os.time() }
end

return function(Window)
    Window._parseKick = parse

    function Window:OnKick(callback)
        self._kickListeners = self._kickListeners or {}
        table.insert(self._kickListeners, callback)
    end
    function Window:GetKicks()
        local data = self.Config:ReadJSON("kicks")
        return type(data.list) == "table" and data.list or {}
    end

    function Window:_kicked(message, code)
        local info = parse(message, code)
        -- the prompt and the error signal both report the same kick: keep one
        if self.LastKick and self.LastKick.Message == info.Message and os.time() - self.LastKick.Time < 10 then return end
        self.LastKick = info
        local list = self:GetKicks()
        table.insert(list, 1, { Reason = info.Reason, Code = info.Code, Kind = info.Kind, Time = info.Time, Place = game.PlaceId })
        while #list > 20 do table.remove(list) end
        self.Config:WriteJSON("kicks", { list = list })
        for _, listener in ipairs(self._kickListeners or {}) do self:_safe("OnKick", listener, info) end
        if self.cfg.Rejoin and info.Code ~= 273 and info.Code ~= 600 then
            task.delay(tonumber(self.cfg.RejoinDelay) or 2, function()
                pcall(function() Util.Services.TeleportService:Teleport(game.PlaceId, Util.Services.Players.LocalPlayer) end)
            end)
        end
    end

    function Window:_watchKicks()
        if self.cfg.KickLog == false then return end
        local GuiService = Util.Services.GuiService
        pcall(function()
            self.maid:connect(GuiService.ErrorMessageChanged, function(message)
                if not message or message == "" then return end
                local code
                pcall(function() code = GuiService:GetErrorCode().Value end)
                self:_kicked(message, code)
            end)
        end)
        -- the error prompt itself (some executors see this before the signal)
        task.spawn(function()
            pcall(function()
                local prompt = Util.Services.CoreGui:FindFirstChild("RobloxPromptGui")
                local overlay = prompt and prompt:FindFirstChild("promptOverlay")
                if not overlay then return end
                self.maid:connect(overlay.ChildAdded, function(child)
                    if child.Name ~= "ErrorPrompt" then return end
                    task.wait(0.1)
                    local text = child:FindFirstChild("ErrorMessage", true)
                    if text and text.Text ~= "" then self:_kicked(text.Text) end
                end)
            end)
        end)
    end
end
