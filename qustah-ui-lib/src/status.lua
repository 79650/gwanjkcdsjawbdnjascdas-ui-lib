-- Health of the script, shown in the footer, the Dashboard "Modules" card and the Settings "Info" page.
--   Window:SetModule("ESP", "On" | "Off" | "Error" | "Limited", detail)
--   Window:ReportError(source, message)   (callback errors are reported here automatically)
--   Window:SetStatus(text, color)          manual footer text; SetStatus(nil) goes back to automatic
--   Window:GetErrors(), Window:GetErrorReport(), Window:ClearErrors(), Window:OnStatusChanged(fn)
local Util = require("util")

local Theme = require("theme")
-- theme roles, so the colours suit every theme pack
local GREEN, YELLOW, RED = "success", "warning", "danger"

return function(Window)
    local function changed(self)
        self:_refreshStatus()
        for _, listener in ipairs(self._statusListeners or {}) do Util.safe(listener, self) end
    end

    function Window:OnStatusChanged(callback)
        self._statusListeners = self._statusListeners or {}
        table.insert(self._statusListeners, callback)
    end

    -- meta (optional, kept between calls): { Icon = "eye", Tab = "ESP" } for the dashboard tiles
    function Window:SetModule(name, state, detail, meta)
        name = tostring(name)
        if type(meta) == "table" then
            self.moduleMeta = self.moduleMeta or {}
            self.moduleMeta[name] = meta
        end
        self.modules = self.modules or {}
        self.moduleOrder = self.moduleOrder or {}
        if not self.modules[name] then table.insert(self.moduleOrder, name) end
        self.modules[name] = { state = tostring(state or "Off"), detail = detail }
        if state == "Error" then self:ReportError(name, detail or "Module stopped with an error") return end
        changed(self)
    end
    function Window:GetModules() return self.moduleOrder or {}, self.modules or {} end

    -- session counters shown in Settings › Info › This session: Window:Count("Teleports"), Count("Server hops", 1)
    function Window:Count(name, amount)
        name = tostring(name)
        self.counts = self.counts or {}
        self.countOrder = self.countOrder or {}
        if self.counts[name] == nil then self.counts[name] = 0 table.insert(self.countOrder, name) end
        self.counts[name] = self.counts[name] + (tonumber(amount) or 1)
        for _, listener in ipairs(self._countListeners or {}) do Util.safe(listener, name, self.counts[name]) end
        return self.counts[name]
    end
    function Window:GetCounts() return self.countOrder or {}, self.counts or {} end
    function Window:OnCount(callback)
        self._countListeners = self._countListeners or {}
        table.insert(self._countListeners, callback)
    end

    function Window:ReportError(source, message)
        source, message = tostring(source or "Script"), tostring(message or "Unknown error")
        self.errors = self.errors or {}
        self._errorIndex = self._errorIndex or {}
        local key = source .. "\0" .. message
        local entry = self._errorIndex[key]
        if entry then
            entry.count = entry.count + 1
            entry.last = os.time()
        else
            entry = { source = source, message = message, count = 1, first = os.time(), last = os.time() }
            self._errorIndex[key] = entry
            table.insert(self.errors, entry)
            Util.log(string.format("[%s / %s] %s", self.Title, source, message))
            -- Debug mode (CreateWindow{ Debug = true } or Settings › Info): a toast for every new error
            if self.debug == nil then self.debug = self.cfg.Debug == true end
            if self.debug and self.Notify then
                local short = message:gsub("^.-:%d+: ", "")
                self:Notify({
                    Title = "Error · " .. source, Content = short, Icon = "triangle-alert", Color = RED, Duration = 6,
                    Buttons = { { Title = "Copy", Callback = function()
                        local clipboard = setclipboard or toclipboard
                        if clipboard then pcall(clipboard, source .. ": " .. message) end
                    end } },
                })
            end
        end
        changed(self)
    end
    function Window:GetErrors() return self.errors or {} end
    function Window:ClearErrors()
        self.errors, self._errorIndex = {}, {}
        for _, module in pairs(self.modules or {}) do if module.state == "Error" then module.state = "Off" end end
        changed(self)
    end
    function Window:GetErrorReport()
        local lines = { string.format("%s %s - error report (%s)", self.Title, self.Version, os.date("%Y-%m-%d %H:%M")) }
        for _, name in ipairs(self.moduleOrder or {}) do
            local module = self.modules[name]
            lines[#lines + 1] = string.format("module %s: %s%s", name, module.state, module.detail and (" (" .. tostring(module.detail) .. ")") or "")
        end
        for _, entry in ipairs(self.errors or {}) do
            lines[#lines + 1] = string.format("x%d %s: %s", entry.count, entry.source, entry.message)
        end
        if #(self.errors or {}) == 0 then lines[#lines + 1] = "no errors" end
        return table.concat(lines, "\n")
    end

    -- everything a bug report needs, as plain text: script / lib versions, executor, game, screen, theme, modules, errors
    function Window:GetDebugInfo()
        local executor = "Unknown"
        pcall(function()
            if type(identifyexecutor) == "function" then executor = table.concat({ identifyexecutor() }, " ")
            elseif type(getexecutorname) == "function" then executor = tostring(getexecutorname()) end
        end)
        local camera = workspace.CurrentCamera
        local screen = camera and camera.ViewportSize or Vector2.zero
        local lines = {
            string.format("%s %s · qustah-ui-lib v%s", self.Title, self.Version ~= "" and self.Version or "-", tostring(self.Lib and self.Lib.Version or "?")),
            "executor: " .. executor,
            string.format("game: %s · place %s · job %s", tostring(game.GameId), tostring(game.PlaceId), game.JobId ~= "" and game.JobId or "studio"),
            string.format("screen: %dx%d · ui scale %d%% · theme %s", screen.X, screen.Y, math.floor((self.GetUIScale and self:GetUIScale() or 1) * 100 + 0.5), tostring(require("theme").pack or "Dark")),
            string.format("files: %s · secure: %s", (type(writefile) == "function" and type(readfile) == "function") and "yes" or "no", Util.secure and "on" or "off"),
            "",
        }
        return table.concat(lines, "\n") .. self:GetErrorReport()
    end

    function Window:SetStatus(text, color)
        self._manualStatus = text ~= nil and { text = tostring(text), color = color } or nil
        self:_refreshStatus()
    end

    -- Footer: manual text > "Errors: N" > "Limited" > "Connected" (with a dot in green / yellow / red).
    function Window:_refreshStatus()
        if not self.statusLabel then return end
        local text, color
        local errorCount = #(self.errors or {})
        local limited = false
        for _, module in pairs(self.modules or {}) do if module.state == "Limited" then limited = true end end
        if self._manualStatus then
            text, color = self._manualStatus.text, self._manualStatus.color
        elseif errorCount > 0 then
            text, color = "Errors: " .. errorCount, RED
        elseif limited then
            text, color = "Limited", YELLOW
        else
            text, color = "Connected", GREEN
        end
        self.statusText = text
        self.statusLabel.Text = text
        if color ~= nil and self.statusDot then Theme.bind(self.statusDot, "ImageColor3", color) end
    end

    -- Runs a user callback; an error is reported (footer, Info page) instead of breaking the UI.
    -- Returns true / false (nil when there was nothing to run).
    function Window:_safe(source, callback, ...)
        if type(callback) ~= "function" then return nil end
        local ok, err = pcall(callback, ...)
        if not ok then self:ReportError(source, err) end
        return ok
    end
end
