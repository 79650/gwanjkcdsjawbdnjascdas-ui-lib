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

-- Runs a user callback; an error is reported but never breaks the UI.
function Util.safe(callback, ...)
    if type(callback) ~= "function" then return end
    local ok, err = pcall(callback, ...)
    if not ok then warn("[qustah-ui-lib] callback error: " .. tostring(err)) end
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

function Util.textWidth(text, size, font)
    return Services.TextService:GetTextSize(tostring(text), size, font or Enum.Font.Gotham, Vector2.new(10000, 100)).X
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

-- Screen position of a pointer input (same space as AbsolutePosition in an IgnoreGuiInset ScreenGui).
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
        Name = name, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = order or 50,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) elseif protectgui then protectgui(gui) end end)
    gui.Parent = Util.guiParent()
    return gui
end

return Util
