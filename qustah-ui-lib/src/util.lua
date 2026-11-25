-- Shared helpers: services, instance creation, tweens, cleanup (maid), text / colour / key helpers.
local Util = {}

local cloneref = cloneref or clonereference or function(object) return object end
Util.Services = setmetatable({}, {
    __index = function(cache, name)
        local service = cloneref(game:GetService(name))
        rawset(cache, name, service)
        return service
    end,
})
local Services = Util.Services

-- Secure mode (getgenv().QUSTAH_SECURE = true before loading, CreateWindow({ Secure = true }) or Lib:SetSecure(true)):
-- random ScreenGui names, nothing printed to the console, avatars as rbxthumb content (no web lookup).
local genv = (getgenv and getgenv()) or _G
Util.secure = genv.QUSTAH_SECURE == true
-- Library messages go through here so secure mode (or CreateWindow({ ConsoleLog = false })) keeps the console
-- quiet: the game's own scripts can read the console.
Util.quiet = false
function Util.log(message)
    if not Util.secure and not Util.quiet then warn(message) end
end

-- create("Frame", { Size = ..., Parent = ... }, { children }) - Parent is applied last.
function Util.create(class, props, children)
    local object = Instance.new(class)
    local parent
    for key, value in pairs(props or {}) do
        if key == "Parent" then parent = value else object[key] = value end
    end
    for _, child in ipairs(children or {}) do child.Parent = object end
    if parent then object.Parent = parent end
    return object
end
local create = Util.create

function Util.corner(object, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = object })
end
function Util.stroke(object, color, transparency, thickness)
    return create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = color or Color3.new(1, 1, 1),
        Transparency = transparency or 0, Thickness = thickness or 1, Parent = object,
    })
end
function Util.padding(object, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0), PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or 0), PaddingBottom = UDim.new(0, bottom or top or 0), Parent = object,
    })
end
function Util.list(object, padding, direction, horizontal, vertical)
    return create("UIListLayout", {
        Padding = UDim.new(0, padding or 0), FillDirection = direction or Enum.FillDirection.Vertical,
        HorizontalAlignment = horizontal or Enum.HorizontalAlignment.Left,
        VerticalAlignment = vertical or Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder, Parent = object,
    })
end
-- The UIScale on a gui and its ancestors, multiplied (1 when there is none).
function Util.uiScale(object)
    local scale = 1
    while object and not object:IsA("LayerCollector") do
        local found = object:FindFirstChildWhichIsA("UIScale")
        if found then scale = scale * found.Scale end
        object = object.Parent
    end
    return scale
end
-- A ScrollingFrame's canvas, sized from its content by hand. Roblox's AutomaticCanvasSize gets it wrong under a
-- UIScale (the menu's UI scale / small screens): the canvas comes out too short and the last items can't be
-- scrolled to. source: the content's UIListLayout / UIGridLayout, or the content frame itself. extra: more room (px).
-- (Until the content has a measured size, AutomaticCanvasSize stays on.)
function Util.fitCanvas(scroller, source, extra)
    local function update()
        if not scroller.Parent then return end
        local scale = Util.uiScale(scroller)
        if scale <= 0 then scale = 1 end
        local height
        if source:IsA("UIGridStyleLayout") then
            height = source.AbsoluteContentSize.Y / scale
        else
            height = source.AbsoluteSize.Y / scale + source.Position.Y.Offset
        end
        if height <= 0 then return end
        local padding = scroller:FindFirstChildWhichIsA("UIPadding")
        if padding then height = height + padding.PaddingTop.Offset + padding.PaddingBottom.Offset end
        scroller.AutomaticCanvasSize = Enum.AutomaticSize.None
        scroller.CanvasSize = UDim2.new(0, 0, 0, math.ceil(height + (extra or 0)))
    end
    source:GetPropertyChangedSignal(source:IsA("UIGridStyleLayout") and "AbsoluteContentSize" or "AbsoluteSize"):Connect(update)
    task.defer(update)
    return update
end
function Util.label(parent, text, size, props)
    local object = create("TextLabel", {
        BackgroundTransparency = 1, Text = text or "", TextSize = size or 11, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd, BorderSizePixel = 0, Parent = parent,
    })
    for key, value in pairs(props or {}) do object[key] = value end
    return object
end

function Util.tween(object, duration, props, style, direction)
    local tween = Services.TweenService:Create(object,
        TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end

-- Fades a small piece of UI (toast, pill, key screen) by tweening each part's own transparency, so nothing is
-- drawn through a CanvasGroup texture (sharp text and icons) and it can stay inside a list layout. Each part's
-- resting transparency is remembered the first time. fromHidden: start everything invisible (a new toast).
local FADE_PROPS = {
    { "GuiObject", "BackgroundTransparency" }, { "TextLabel", "TextTransparency" }, { "TextButton", "TextTransparency" },
    { "TextBox", "TextTransparency" }, { "ImageLabel", "ImageTransparency" }, { "ImageButton", "ImageTransparency" },
    { "UIStroke", "Transparency" },
}
function Util.fadeTree(root, duration, target, fromHidden)
    fromHidden = fromHidden or root:GetAttribute("QFadedOut") == true
    root:SetAttribute("QFadedOut", target >= 1)
    local objects = root:GetDescendants()
    table.insert(objects, root)
    for _, object in ipairs(objects) do
        for _, spec in ipairs(FADE_PROPS) do
            if object:IsA(spec[1]) then
                local prop = spec[2]
                local key = "QRest" .. prop
                local rest = object:GetAttribute(key)
                if rest == nil then
                    rest = object[prop]
                    object:SetAttribute(key, rest)
                end
                if rest < 1 then
                    if fromHidden then object[prop] = 1 end
                    Util.tween(object, duration, { [prop] = 1 - (1 - rest) * (1 - target) })
                end
            end
        end
    end
end

-- Sets an outline's normal transparency (respected by Util.fade); applied now unless its group is faded out.
function Util.setRest(strokeObject, value)
    strokeObject:SetAttribute("QRest", value)
    local group = strokeObject.Parent
    if not (group and group:IsA("CanvasGroup") and group.GroupTransparency > 0.01) then strokeObject.Transparency = value end
end

-- Downloaded files shown through getcustomasset (icon sheets, fonts, web images) --------------------------------
function Util.canCustomAsset()
    return type(getcustomasset or getsynasset) == "function" and type(writefile) == "function" and type(isfile) == "function"
end

-- A short stable name for a link (djb2), so two different links never share a file.
function Util.hash(text)
    local h = 5381
    for i = 1, #text do h = (h * 33 + string.byte(text, i)) % 4294967296 end
    return string.format("%08x", h)
end

local function makeFolders(path)
    if type(makefolder) ~= "function" or type(isfolder) ~= "function" then return end
    local built = ""
    for part in string.gmatch(path:match("^(.*)/[^/]*$") or "", "[^/]+") do
        built = built == "" and part or (built .. "/" .. part)
        if not isfolder(built) then makefolder(built) end
    end
end

-- Util.cacheFiles({ { path = "QustahUI/x.png", url = "https://...", check = function(body) return ok end }, ... },
--     done(ids), fail(reason), what)
-- what ("icons"): shown in the download strip at the top of the screen while files are fetched.
-- Every missing file is downloaded once and kept on disk; done gets { [path] = getcustomasset id }. It runs at once
-- when everything is already there (so the first frame can use it), after the download otherwise. fail runs when
-- the executor can't show downloaded files or a download / check fails.
Util.downloadTimeout = 20
function Util.cacheFiles(files, done, fail, what)
    fail = fail or function() end
    if not Util.canCustomAsset() then fail("getcustomasset is not available") return end
    local custom = getcustomasset or getsynasset
    local function finish()
        local ids = {}
        for _, file in ipairs(files) do
            local ok, id = pcall(custom, file.path)
            if not ok or type(id) ~= "string" or id == "" then fail(tostring(id)) return end
            ids[file.path] = id
        end
        done(ids)
    end
    local missing = {}
    for _, file in ipairs(files) do
        local ok, exists = pcall(isfile, file.path)
        if not (ok and exists) then missing[#missing + 1] = file end
    end
    if #missing == 0 then finish() return end
    -- (required here, not at the top: the strip itself is built from util)
    local job = what and require("loader").start(what, #missing)
    -- every missing file at once (one after the other, the strip sat at 0% through the whole first sheet). An http
    -- request reaches any host (raw.githubusercontent.com works with HttpGet too). A request that never answers
    -- would keep the strip (and whoever waits for it) forever: given up after Util.downloadTimeout seconds, the
    -- caller falls back (plain icons).
    local request = (syn and syn.request) or http_request or request
    local left, failed = #missing, nil
    local function settle(reason)
        if reason ~= nil and failed == nil then failed = reason end
        left = left - 1
        if left > 0 then return end
        if job then job.finish() end
        if failed == nil then finish() else fail(tostring(failed)) end
    end
    for _, file in ipairs(missing) do
        task.spawn(function()
            local body, finished, failure = nil, false, nil
            local worker = task.spawn(function()
                local got, value = pcall(function()
                    if request and not file.url:find("githubusercontent", 1, true) then
                        return request({ Url = file.url, Method = "GET" }).Body
                    end
                    return game:HttpGet(file.url)
                end)
                if got then body = value else failure = value end
                finished = true
            end)
            local started = os.clock()
            while not finished and os.clock() - started < Util.downloadTimeout do task.wait(0.1) end
            local ok, reason = pcall(function()
                if not finished then pcall(task.cancel, worker) error("timed out", 0) end
                if failure ~= nil then error(failure, 0) end
                assert(type(body) == "string" and #body > 0, "empty response")
                if file.check then assert(file.check(body), "unexpected file") end
                makeFolders(file.path)
                writefile(file.path, body)
            end)
            if ok and job then job.step() end
            settle(not ok and reason or nil)
        end)
    end
end

-- Runs a user callback; an error is reported but never breaks the UI.
function Util.safe(callback, ...)
    if type(callback) ~= "function" then return end
    local ok, err = pcall(callback, ...)
    if not ok then Util.log("[qustah-ui-lib] callback error: " .. tostring(err)) end
end

-- A maid owns connections, instances and cleanup functions; clean() releases all of them (newest first).
function Util.maid()
    local maid = { items = {} }
    function maid:give(item) self.items[#self.items + 1] = item return item end
    function maid:connect(signal, callback) return self:give(signal:Connect(callback)) end
    function maid:clean()
        for index = #self.items, 1, -1 do
            local item = self.items[index]
            self.items[index] = nil
            if typeof(item) == "Instance" then
                pcall(item.Destroy, item)
            elseif type(item) == "function" then
                pcall(item)
            elseif item and (typeof(item) == "RBXScriptConnection" or type(item) == "table") and item.Disconnect then
                pcall(item.Disconnect, item)
            end
        end
    end
    return maid
end

-- text widths are asked for a lot (buttons fitting their text, the tour, tooltips): remembered, the table starts over at 1000
local widthCache, widthCount = {}, 0
local fontModule -- (the font module, found on first use: it requires util itself)
-- (font: an Enum.Font. A label drawn in a font from Roblox's font library or a downloaded one reports
-- Enum.Font.Unknown, which GetTextSize refuses: Gotham stands in, about as wide.)
function Util.textWidth(text, size, font)
    text = tostring(text)
    if typeof(font) ~= "EnumItem" or font == Enum.Font.Unknown then font = Enum.Font.Gotham end
    -- the UI font's own measured widths when they are there (code fonts keep their Enum.Font size)
    if font ~= Enum.Font.Code and font ~= Enum.Font.RobotoMono then
        if fontModule == nil then Util._fontFactor(font, size) end
        local measured = fontModule and fontModule.textWidth and fontModule.textWidth(text, size, font)
        if measured then return measured end
    end
    local key = text .. "\0" .. tostring(size) .. "\0" .. tostring(font)
    local width = widthCache[key]
    if width then return width * Util._fontFactor(font, size) end
    local ok, bounds = pcall(function() return Services.TextService:GetTextSize(text, size, font, Vector2.new(10000, 100)) end)
    width = ok and bounds.X or #text * (tonumber(size) or 10) * 0.55
    if widthCount >= 1000 then widthCache, widthCount = {}, 0 end
    widthCache[key], widthCount = width, widthCount + 1
    return width * Util._fontFactor(font, size)
end
-- Util.onTextMetrics(object, fn): fn runs whenever text widths change (another font, text size, a measured font)
-- while `object` is alive, so something laid out by Util.textWidth can size itself again.
function Util.onTextMetrics(object, fn)
    local ok, font = pcall(require, "font")
    if not ok or type(font) ~= "table" or not font.onChange then return function() end end
    local stop = font.onChange(function() if object.Parent then fn() end end)
    object.Destroying:Connect(stop)
    return stop
end
-- (the UI font's width next to Gotham, set by the font module; 1 until it loads)
function Util._fontFactor(font, size)
    if fontModule == nil then
        local ok, module = pcall(require, "font")
        fontModule = ok and module or false
    end
    if not fontModule then return 1 end
    local ok, factor = pcall(fontModule.widthFactor, font, size)
    return ok and factor or 1
end
-- true while the object can actually be seen: it and every parent Visible, the ScreenGui enabled
function Util.shown(object)
    while object do
        if object:IsA("GuiObject") and not object.Visible then return false end
        if object:IsA("LayerCollector") then return object.Enabled end
        object = object.Parent
    end
    return false
end

-- Screen visibility for previews, including cards scrolled out of a scrolling page.
function Util.inView(object)
    if not Util.shown(object) then return false end
    local p, size = object.AbsolutePosition, object.AbsoluteSize
    local l, t, r, b = p.X, p.Y, p.X + size.X, p.Y + size.Y
    if l >= r or t >= b then return false end
    local camera = Services.Workspace.CurrentCamera
    if camera then
        local extent = camera.ViewportSize
        local originX, originY = 0, 0
        local screen = object:FindFirstAncestorWhichIsA("ScreenGui")
        if screen and not screen.IgnoreGuiInset then
            local ok, inset = pcall(function() return Services.GuiService:GetGuiInset() end)
            if ok then originX, originY = -inset.X, -inset.Y end
        end
        l, t = math.max(l, originX), math.max(t, originY)
        r, b = math.min(r, originX + extent.X), math.min(b, originY + extent.Y)
        if l >= r or t >= b then return false end
    end
    local parent = object.Parent
    while parent and not parent:IsA("LayerCollector") do
        if parent:IsA("GuiObject") and (parent.ClipsDescendants or parent:IsA("ScrollingFrame")) then
            local a = parent.AbsolutePosition
            local extent = parent:IsA("ScrollingFrame") and parent.AbsoluteWindowSize or parent.AbsoluteSize
            l, t = math.max(l, a.X), math.max(t, a.Y)
            r, b = math.min(r, a.X + extent.X), math.min(b, a.Y + extent.Y)
            if l >= r or t >= b then return false end
        end
        parent = parent.Parent
    end
    return true
end

-- Util.watchInView(object, callback): callback(true / false) whenever the object comes into or goes out of view
-- (Util.inView), worked out from property changes of the object and its ancestors instead of a per-frame check.
-- Returns stop(); stopping (or the object being destroyed) while it was in view calls callback(false).
function Util.watchInView(object, callback)
    local links = {}
    local alive, pending, last = true, false, nil
    local ancestry, destroying, cameraChanged, cameraSize
    local function schedule()
        if pending or not alive then return end
        pending = true
        task.defer(function()
            pending = false
            if not alive then return end
            local shown = Util.inView(object)
            if shown ~= last then last = shown callback(shown) end
        end)
    end
    local function watch(o, property)
        links[#links + 1] = o:GetPropertyChangedSignal(property):Connect(schedule)
    end
    local function clear()
        for _, link in ipairs(links) do link:Disconnect() end
        table.clear(links)
    end
    local function bind()
        clear()
        watch(object, "AbsolutePosition")
        watch(object, "AbsoluteSize")
        local node = object
        while node do
            if node:IsA("LayerCollector") then watch(node, "Enabled") break end
            if node:IsA("GuiObject") then
                watch(node, "Visible")
                if node ~= object then
                    watch(node, "ClipsDescendants")
                    watch(node, "AbsoluteSize")
                    if node:IsA("ScrollingFrame") then
                        watch(node, "AbsoluteWindowSize")
                        watch(node, "CanvasPosition")
                    end
                end
            end
            node = node.Parent
        end
        schedule()
    end
    local function stop()
        if not alive then return end
        alive = false
        clear()
        if ancestry then ancestry:Disconnect() end
        if destroying then destroying:Disconnect() end
        if cameraChanged then cameraChanged:Disconnect() end
        if cameraSize then cameraSize:Disconnect() end
        if last then callback(false) end
    end
    ancestry = object.AncestryChanged:Connect(bind)
    destroying = object.Destroying:Connect(stop)
    local function watchCamera()
        if cameraSize then cameraSize:Disconnect() cameraSize = nil end
        local camera = Services.Workspace.CurrentCamera
        if camera then cameraSize = camera:GetPropertyChangedSignal("ViewportSize"):Connect(schedule) end
        schedule()
    end
    cameraChanged = Services.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
    watchCamera()
    bind()
    return stop
end

-- Rendering-only animation: disconnect the frame callback offscreen.
-- Returns stop() and sync(); sync() re-evaluates the feature's enabled predicate.
function Util.animateInView(object, signal, tick, enabled)
    local alive, visible, connection = true, false, nil
    local function sync()
        local active = alive and visible and (not enabled or enabled())
        if active and not connection then
            connection = signal:Connect(tick)
        elseif not active and connection then
            connection:Disconnect()
            connection = nil
        end
    end
    local stopVisibility = Util.watchInView(object, function(on) visible = on sync() end)
    local function stop()
        if not alive then return end
        alive = false
        local release = stopVisibility
        stopVisibility = nil
        release()
        sync()
        signal, tick, enabled = nil, nil, nil
    end
    return stop, sync
end

local scrollOwners = setmetatable({}, { __mode = "k" })
function Util.lockScroll(owner)
    local node = owner.Parent
    while node and not node:IsA("ScrollingFrame") do node = node.Parent end
    if not node then return function() end end
    local state = scrollOwners[node]
    if not state then state = { count = 0, original = node.ScrollingEnabled } scrollOwners[node] = state end
    state.count += 1
    node.ScrollingEnabled = false
    local alive = true
    return function()
        if not alive then return end
        alive = false state.count -= 1
        if state.count == 0 then
            scrollOwners[node] = nil
            pcall(function() node.ScrollingEnabled = state.original end)
        end
    end
end
function Util.captureScroll(owner, enabled)
    local maid, release = Util.maid(), nil
    local function clear() if release then release() release = nil end end
    local function sync() if enabled and not enabled() then clear() end end
    maid:connect(owner.MouseEnter, function()
        clear()
        if Util.inView(owner) and (not enabled or enabled()) then release = Util.lockScroll(owner) end
    end)
    maid:connect(owner.MouseLeave, clear)
    maid:give(Util.watchInView(owner, function(on) if not on then clear() end end))
    maid:connect(owner.Destroying, function() maid:clean() clear() end)
    maid:give(clear)
    return { Sync = sync, Destroy = function() maid:clean() clear() end }
end
function Util.dependencyIcons(Window)
    local hub = { Running = true, Cleanup = {} }
	local marks = {}
	for _, el in pairs(Window.flags or {}) do
		local row = type(el) == "table" and el.Row
		local title = row and row:FindFirstChild("Title")
		if title then
			local ok, img = pcall(function()
				return require("icons").Image("lock", { Size = UDim2.fromOffset(10, 10), Color = Color3.fromRGB(150, 155, 168) })
			end)
			if ok and img then
				img.AnchorPoint, img.ZIndex, img.Visible, img.Parent = Vector2.new(0, 0.5), 23, false, row
				local mark = { row = row, image = img, visible = false }
				function mark.paint()
					local show = el._depLocked == true and title.Parent ~= nil
					img.Visible = show
					if show then
						img.Position = UDim2.fromOffset(
							title.AbsolutePosition.X - row.AbsolutePosition.X + title.TextBounds.X + 5,
							title.AbsolutePosition.Y - row.AbsolutePosition.Y + title.AbsoluteSize.Y / 2)
					end
				end
				local links = {}
				local function clear()
					for _, c in ipairs(links) do c:Disconnect() end
					table.clear(links)
				end
				local stop = Util.watchInView(row, function(visible)
					clear()
					mark.visible = visible and hub.Running
					if mark.visible then
						mark.paint()
						for _, spec in ipairs({ { title, "TextBounds" }, { title, "AbsolutePosition" }, { title, "AbsoluteSize" }, { row, "AbsolutePosition" } }) do
							links[#links + 1] = spec[1]:GetPropertyChangedSignal(spec[2]):Connect(mark.paint)
						end
					else img.Visible = false end
				end)
				marks[#marks + 1] = mark
				hub.Cleanup[#hub.Cleanup + 1] = function() stop() clear() end
			end
		end
	end
	-- The dependents list runs from its end, so this runs before the rows' own DependsOn checks: the repaint waits a
	-- step to see the new lock states, and several flag changes in a row share one repaint.
	local queued = false
	Window._dependents = Window._dependents or {}
	Window._dependents[#Window._dependents + 1] = function()
		if not hub.Running then return false end
		if not queued then
			queued = true
			task.defer(function()
				queued = false
                if not hub.Running then return end
				for _, mark in ipairs(marks) do
					if mark.visible and mark.row.Parent then mark.paint() end
				end
			end)
		end
		return true
	end
    local alive = true
    local function stop()
        if not alive then return end
        alive, hub.Running = false, false
        for _, cleanup in ipairs(hub.Cleanup) do cleanup() end
        for _, mark in ipairs(marks) do
            local image = mark.image
            if image then image:Destroy() end
        end
    end
    Window.maid:give(stop)
    return stop
end
function Util.round(value, step)
    step = step or 1
    if step <= 0 then return value end
    return math.floor(value / step + 0.5) * step
end
function Util.decimals(step)
    local text = tostring(step)
    local dot = text:find("%.")
    return dot and #text - dot or 0
end

function Util.toHex(color)
    return string.format("%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end
function Util.fromHex(text)
    text = tostring(text or ""):gsub("#", ""):gsub("%s", "")
    if not text:match("^%x%x%x%x%x%x$") then return nil end
    return Color3.fromRGB(tonumber(text:sub(1, 2), 16), tonumber(text:sub(3, 4), 16), tonumber(text:sub(5, 6), 16))
end

local SHORT_KEYS = {
    LeftShift = "LSHIFT", RightShift = "RSHIFT", LeftControl = "LCTRL", RightControl = "RCTRL",
    LeftAlt = "LALT", RightAlt = "RALT", MouseButton1 = "M1", MouseButton2 = "M2", MouseButton3 = "M3", Return = "ENTER",
    KeypadZero = "NUM 0", KeypadOne = "NUM 1", KeypadTwo = "NUM 2", KeypadThree = "NUM 3", KeypadFour = "NUM 4",
    KeypadFive = "NUM 5", KeypadSix = "NUM 6", KeypadSeven = "NUM 7", KeypadEight = "NUM 8", KeypadNine = "NUM 9",
}
-- KeyCode / UserInputType / name -> short label ("RSHIFT", "NUM 8", "F").
function Util.keyName(key)
    if key == nil then return "None" end
    local name = typeof(key) == "EnumItem" and key.Name or tostring(key)
    if name == "None" or name == "" or name == "Unknown" then return "None" end
    return SHORT_KEYS[name] or name:upper()
end
-- Saved key names back to an Enum (KeyCode first, then mouse buttons).
function Util.toKey(name)
    if typeof(name) == "EnumItem" then return name end
    if type(name) ~= "string" or name == "" or name == "None" then return nil end
    if name:match("^MouseButton%d$") then
        local found, button = pcall(function() return Enum.UserInputType[name] end)
        if found and button then return button end
    end
    local ok, key = pcall(function() return Enum.KeyCode[name] end)
    if ok and key then return key end
    ok, key = pcall(function() return Enum.UserInputType[name] end)
    if ok and key then return key end
    return nil
end
-- The key an input means for binds: the KeyCode for keyboards, the UserInputType for mouse buttons 2/3
-- (and mouse button 1 when allowPrimary is set - only chords like CTRL + M1 use it).
function Util.inputKey(input, allowPrimary)
    if input.UserInputType == Enum.UserInputType.Keyboard then return input.KeyCode end
    if input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
        return input.UserInputType
    end
    if allowPrimary and input.UserInputType == Enum.UserInputType.MouseButton1 then return input.UserInputType end
    return nil
end
local MODIFIERS = {
    LeftShift = true, RightShift = true, LeftControl = true, RightControl = true, LeftAlt = true, RightAlt = true,
}
function Util.isModifier(key) return typeof(key) == "EnumItem" and MODIFIERS[key.Name] == true end
-- Is this key (KeyCode or mouse UserInputType) held down right now?
function Util.isDown(key)
    if typeof(key) ~= "EnumItem" then return false end
    local UserInputService = Services.UserInputService
    local ok, down = pcall(function()
        if tostring(key):match("^Enum%.KeyCode%.") then return UserInputService:IsKeyDown(key) end
        return UserInputService:IsMouseButtonPressed(key)
    end)
    return ok and down == true
end

-- Where a gui object really is on the screen (top-left of the whole screen, the space GetMouseLocation uses and
-- the space a child placed with Position = fromOffset(x, y) in our IgnoreGuiInset ScreenGui ends up in).
-- AbsolutePosition alone is not enough: depending on where the gui lives it can come out shifted by the top bar
-- inset (pop-ups then opened ~58 px above their button). A zero-size probe at (0, 0) in the same ScreenGui
-- measures that shift, so this is right either way.
local probes = setmetatable({}, { __mode = "k" })
function Util.origin(object)
    local gui = object and object:FindFirstAncestorWhichIsA("LayerCollector")
    if not gui then return Vector2.new(0, 0) end
    local probe = probes[gui]
    if not probe or probe.Parent ~= gui then
        probe = Instance.new("Frame")
        probe.Name = "Origin"
        probe.BackgroundTransparency = 1
        probe.Size = UDim2.fromOffset(0, 0)
        probe.Position = UDim2.fromOffset(0, 0)
        probe.Parent = gui
        probes[gui] = probe
    end
    return probe.AbsolutePosition
end
function Util.screenPos(object)
    return object.AbsolutePosition - Util.origin(object)
end

-- Screen position of a pointer input (same space as Util.screenPos).
function Util.pointer(input)
    if input and input.UserInputType == Enum.UserInputType.Touch then
        local inset = Services.GuiService:GetGuiInset()
        return Vector2.new(input.Position.X + inset.X, input.Position.Y + inset.Y)
    end
    return Services.UserInputService:GetMouseLocation()
end
function Util.isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

-- Head shot of a user as rbxthumb content (no web request).
function Util.avatar(userId, size)
    size = size or 48
    return string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=%d&h=%d", tonumber(userId) or 0, size, size)
end

-- Scroll bars that only show while scrolling or hovered (fade out ~1 s after).
function Util.fadeScrollbar(scroller, shown)
    shown = shown or 0.35
    local hovering, token = false, 0
    scroller.ScrollBarImageTransparency = 1
    local function show()
        token = token + 1
        local mine = token
        Util.tween(scroller, 0.12, { ScrollBarImageTransparency = shown })
        task.delay(1.2, function()
            if mine == token and not hovering and scroller.Parent then Util.tween(scroller, 0.35, { ScrollBarImageTransparency = 1 }) end
        end)
    end
    scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(show)
    scroller.MouseEnter:Connect(function() hovering = true show() end)
    scroller.MouseLeave:Connect(function() hovering = false show() end)
    return scroller
end

-- A touch screen without a keyboard (phones / tablets): bigger hit areas, the reopen button.
function Util.isTouch()
    local UserInputService = Services.UserInputService
    local ok, touch = pcall(function() return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled end)
    return ok and touch == true
end

-- Hover "pop": a slight grow (grid cells: images, swatches). Returns the UIScale.
function Util.hoverPop(button, amount)
    local scale = create("UIScale", { Scale = 1, Parent = button })
    button.MouseEnter:Connect(function() Util.tween(scale, 0.12, { Scale = amount or 1.05 }) end)
    button.MouseLeave:Connect(function() Util.tween(scale, 0.15, { Scale = 1 }) end)
    return scale
end

-- HH:MM:SS
function Util.clock(seconds)
    seconds = math.max(0, math.floor(seconds))
    return string.format("%02d:%02d:%02d", seconds // 3600, (seconds // 60) % 60, seconds % 60)
end

function Util.viewport()
    local camera = workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

-- gethui() > CoreGui (if writable) > PlayerGui.
function Util.guiParent()
    local ok, hidden = pcall(function() return gethui and gethui() end)
    if ok and hidden then return hidden end
    local probe = Instance.new("Folder")
    local coreOk = pcall(function() probe.Parent = Services.CoreGui end)
    probe:Destroy()
    if coreOk then return Services.CoreGui end
    return Services.Players.LocalPlayer:WaitForChild("PlayerGui")
end
function Util.screenGui(name, order)
    local gui = create("ScreenGui", {
        Name = Util.secure and Services.HttpService:GenerateGUID(false) or name, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = order or 50,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) elseif protectgui then protectgui(gui) end end)
    gui.Parent = Util.guiParent()
    return gui
end

-- The temporary copy of a file: <file>.tmp.txt (many executors only write known extensions such as .txt / .json and
-- refuse ".tmp" with "Illegal extension").
function Util.tmpOf(path) return path .. ".tmp.txt" end
local function tmpFiles(path) return { path .. ".tmp.txt" } end
Util.tmpFiles = tmpFiles

-- Crash-safe writes: the text goes to <file>.tmp.txt first, is read back, then written over the file and the .tmp removed.
-- If the game closes half way, either the old file or a complete .tmp survives (Util.readJSON picks it up).
-- Util.prettyJSON(value): JSON that is easy to read and compare - two-space indents, keys in order, short lists of
-- plain values on one line. (Profiles, themes and the window memory are written this way.)
function Util.prettyJSON(value)
    local HttpService = Services.HttpService
    local function scalar(v) return type(v) ~= "table" end
    local function isArray(t)
        local n = 0
        for k in pairs(t) do
            if type(k) ~= "number" then return false end
            n = n + 1
        end
        return n == #t
    end
    local function encode(v, indent)
        if type(v) ~= "table" then return HttpService:JSONEncode(v) end
        local inner = indent .. "  "
        if isArray(v) then
            if #v == 0 then return "[]" end
            local parts, simple = {}, true
            for _, item in ipairs(v) do
                parts[#parts + 1] = encode(item, inner)
                if not scalar(item) then simple = false end
            end
            if simple then return "[" .. table.concat(parts, ", ") .. "]" end
            return "[\n" .. inner .. table.concat(parts, ",\n" .. inner) .. "\n" .. indent .. "]"
        end
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = tostring(k) end
        if #keys == 0 then return "{}" end
        table.sort(keys)
        local parts = {}
        for _, k in ipairs(keys) do
            local item = v[k]
            if item == nil then item = v[tonumber(k)] end
            parts[#parts + 1] = HttpService:JSONEncode(k) .. ": " .. encode(item, inner)
        end
        return "{\n" .. inner .. table.concat(parts, ",\n" .. inner) .. "\n" .. indent .. "}"
    end
    local ok, text = pcall(encode, value, "")
    return ok and text or HttpService:JSONEncode(value)
end

function Util.writeAtomic(path, text)
    if type(writefile) ~= "function" then return false, "writefile is not available" end
    local tmp = Util.tmpOf(path)
    local ok, err = pcall(writefile, tmp, text)
    if not ok then
        -- no temporary copy possible here: write the file itself
        ok, err = pcall(writefile, path, text)
        if not ok then return false, tostring(err) end
        return true
    end
    if type(readfile) == "function" then
        local read, back = pcall(readfile, tmp)
        -- (some executors turn \n into \r\n on Windows)
        if not read or (back ~= text and (tostring(back):gsub("\r\n", "\n")) ~= (text:gsub("\r\n", "\n"))) then
            return false, "the file could not be written completely" -- the old file stays
        end
    end
    ok, err = pcall(writefile, path, text)
    if not ok then return false, tostring(err) end
    if type(delfile) == "function" then pcall(delfile, tmp) end
    return true
end
-- Reads a JSON table. A missing / damaged file falls back to the .tmp of an interrupted save (and the file is repaired).
-- Returns data, recovered | nil, "missing" | "damaged".
function Util.readJSON(path)
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return nil, "missing" end
    local function decode(file)
        if not isfile(file) then return nil, "missing" end
        local ok, data = pcall(function() return Services.HttpService:JSONDecode(readfile(file)) end)
        if ok and type(data) == "table" then return data end
        return nil, "damaged"
    end
    -- the temporary copy that is there (new name first), else the new name
    local tmp = Util.tmpOf(path)
    for _, file in ipairs(tmpFiles(path)) do
        if isfile(file) then tmp = file break end
    end
    local data, problem = decode(path)
    if data then
        if isfile(tmp) then
            -- both complete but different: the game closed after the .tmp was checked and before the file was
            -- written, so the .tmp is the newer save
            local newer = decode(tmp)
            local read, saved, current = pcall(function() return readfile(tmp), readfile(path) end)
            if newer and read and saved ~= current then
                pcall(function() writefile(path, readfile(tmp)) end)
                if type(delfile) == "function" then pcall(delfile, tmp) end
                return newer, true
            end
            if type(delfile) == "function" then pcall(delfile, tmp) end -- leftover of a save that finished
        end
        return data, false
    end
    local saved = decode(tmp)
    if saved then
        pcall(function() writefile(path, readfile(tmp)) end)
        if type(delfile) == "function" then pcall(delfile, tmp) end
        return saved, true
    end
    return nil, problem
end

-- Base64 (profile share codes).
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
function Util.base64encode(data)
    local out = {}
    for i = 1, #data, 3 do
        local a, b, c = data:byte(i, i + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        local c1, c2, c3, c4 = n // 262144, (n // 4096) % 64, (n // 64) % 64, n % 64
        out[#out + 1] = B64:sub(c1 + 1, c1 + 1) .. B64:sub(c2 + 1, c2 + 1)
            .. (b and B64:sub(c3 + 1, c3 + 1) or "=") .. (c and B64:sub(c4 + 1, c4 + 1) or "=")
    end
    return table.concat(out)
end
function Util.base64decode(data)
    data = tostring(data):gsub("[^%w%+/=]", "")
    local out, bits, count = {}, 0, 0
    for i = 1, #data do
        local char = data:sub(i, i)
        if char == "=" then break end
        local value = B64:find(char, 1, true)
        if not value then return nil end
        bits = bits * 64 + (value - 1)
        count = count + 6
        if count >= 8 then
            count = count - 8
            out[#out + 1] = string.char((bits // (2 ^ count)) % 256)
            bits = bits % (2 ^ count)
        end
    end
    return table.concat(out)
end

-- "2m ago"
function Util.ago(time)
    local seconds = math.max(0, os.time() - (tonumber(time) or os.time()))
    if seconds < 60 then return "now" end
    if seconds < 3600 then return (seconds // 60) .. "m ago" end
    if seconds < 86400 then return (seconds // 3600) .. "h ago" end
    return (seconds // 86400) .. "d ago"
end

return Util
