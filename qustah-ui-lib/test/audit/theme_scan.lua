-- Theme coverage: every visible colour property should follow a theme role (or be on the allow list).
getfenv(0).SMOKE_STEPS = function(MOCK)
    local E = getfenv(0)
    local Lib = E.getgenv().TestLib
    local w = Lib.Windows[1]
    local function wait(t) MOCK.advance(t or 0.5, MOCK.frame) end
    wait(2)
    if w._dialog then w._dialog:Close() end
    -- open everything that is built lazily: every tab / page, popups, panels, overlays, toasts, a dialog, the key screen
    for _, tab in ipairs(w.Tabs) do tab:Select() wait(0.1) for _, page in ipairs(tab.Pages) do page:Select() wait(0.1) end end
    for flag, element in pairs(w.flags) do if element.SetOpen then pcall(element.SetOpen, element, true) end end
    w:Watermark(true) w:KeybindList(true) w:SessionBar(true) w:StatsMonitor("Floating")
    w:Notify({ Title = "Scan", Content = "toast", Buttons = { { Title = "A" }, { Title = "B" } }, Icon = "check" })
    Lib:Toast({ Text = "pill", Icon = "check" })
    w:AddTag("SOFT", { Style = "Soft" })
    w:SetLiveBackground(true)
    w:Dialog({ Title = "Dialog", Content = "x", Buttons = { { Title = "No" }, { Title = "Yes", Style = "Danger" }, { Title = "Ok", Style = "Primary" } } })
    E.task.spawn(function() pcall(function() Lib:CreateWindow({ Title = "ScanKey", Folder = "ScanKey", KeySystem = { Keys = { "k" }, Url = "x" } }) end) end)
    wait(1)
    local roots = { w.gui, Lib._notifyHolder and Lib._notifyHolder.Parent, Lib._pillGui, Lib.Util.guiParent():FindFirstChild("QustahUI_Key") }
    local Theme = Lib.Theme
    -- intentional fixed colours (picker gradients, dim overlays, pictures, coloured swatches...)
    local allow = { Square = true, Hue = true, Shade = true, Dialog = true, Dot = true, AlphaBacking = true, Alpha = true, Background = true, Preview = true, Avatar = true, Profile = true }
    local issues, seen = {}, 0
    local function path(o) local parts = {} while o and #parts < 5 do table.insert(parts, 1, o.Name) o = o.Parent end return table.concat(parts, "/") end
    local function report(o, prop) issues[#issues + 1] = string.format("%-14s %-22s %s", o.ClassName, prop, path(o)) end
    local function bound(o, prop) local b = Theme._binding(o) return b and b[prop] ~= nil end
    local function allowed(o)
        local x = o
        for _ = 1, 3 do if not x then break end if allow[x.Name] then return true end x = x.Parent end
        return false
    end
    for _, root in ipairs(roots) do
        if root then
            for _, o in ipairs(root:GetDescendants()) do
                seen = seen + 1
                if not allowed(o) then
                    if o:IsA("GuiObject") then
                        if o.BackgroundTransparency < 1 and not bound(o, "BackgroundColor3") then report(o, "BackgroundColor3") end
                        if (o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")) and o.Text ~= "" and o.TextTransparency < 1 and not bound(o, "TextColor3") then report(o, "TextColor3") end
                        if o:IsA("TextBox") and not bound(o, "PlaceholderColor3") then report(o, "PlaceholderColor3") end
                        if (o:IsA("ImageLabel") or o:IsA("ImageButton")) and o.Image ~= "" and o.ImageTransparency < 1 and not bound(o, "ImageColor3")
                            and not tostring(o.Image):match("rbxthumb") and o.Name ~= "IconPart" and not tostring(o.Image):match("^rbxasset://") then report(o, "ImageColor3") end
                        if o:IsA("ScrollingFrame") and not bound(o, "ScrollBarImageColor3") then report(o, "ScrollBarImageColor3") end
                    elseif o:IsA("UIStroke") and o.Transparency < 1 and o.Enabled ~= false and not bound(o, "Color") then
                        report(o, "Stroke.Color")
                    end
                end
            end
        end
    end
    print("== THEME SCAN objects", seen, "unbound", #issues)
    table.sort(issues)
    for _, line in ipairs(issues) do print("UNBOUND " .. line) end
end
