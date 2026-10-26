-- Health of the script, shown in the footer, the Dashboard "Modules" card and the Settings "Info" page.
--   Window:SetModule("ESP", "On" | "Off" | "Error" | "Limited", detail)
--   Window:ReportError(source, message)   (callback errors are reported here automatically)
--   Window:SetStatus(text, color)          manual footer text; SetStatus(nil) goes back to automatic
--   Window:GetErrors(), Window:GetErrorReport(), Window:ClearErrors(), Window:OnStatusChanged(fn)
local Util = require("util")

local GREEN, YELLOW, RED = Color3.fromRGB(82, 207, 132), Color3.fromRGB(215, 180, 120), Color3.fromRGB(215, 130, 130)

return function(Window)
    local function changed(self)
        self:_refreshStatus()
        for _, listener in ipairs(self._statusListeners or {}) do Util.safe(listener, self) end
    end

    function Window:OnStatusChanged(callback)
        self._statusListeners = self._statusListeners or {}
        table.insert(self._statusListeners, callback)
    end

    function Window:SetModule(name, state, detail)
        name = tostring(name)
        self.modules = self.modules or {}
        self.moduleOrder = self.moduleOrder or {}
        if not self.modules[name] then table.insert(self.moduleOrder, name) end
        self.modules[name] = { state = tostring(state or "Off"), detail = detail }
        if state == "Error" then self:ReportError(name, detail or "Module stopped with an error") return end
        changed(self)
    end
    function Window:GetModules() return self.moduleOrder or {}, self.modules or {} end

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
            warn(string.format("[%s / %s] %s", self.Title, source, message))
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

    function Window:SetStatus(text, color)
        self._manualStatus = text ~= nil and { text = tostring(text), color = color } or nil
        self:_refreshStatus()
    end

    -- Footer: manual text > "Errors: N" > "Limited" > "Connected".
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
        self.statusLabel.Text = text
        if typeof(color) == "Color3" then self.statusDot.BackgroundColor3 = color end
    end

    -- Runs a user callback; an error is reported (footer, Info page) instead of breaking the UI.
    function Window:_safe(source, callback, ...)
        if type(callback) ~= "function" then return end
        local ok, err = pcall(callback, ...)
        if not ok then self:ReportError(source, err) end
    end
end
