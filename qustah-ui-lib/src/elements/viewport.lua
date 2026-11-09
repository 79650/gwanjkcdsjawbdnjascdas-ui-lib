-- card:Viewport({ Object = workspace.Model | BasePart, Height = 170, Interactive = true, Spin = false, Distance, Lower = 0 })
-- A 3D preview of a clone of the object (an avatar, a weapon...). Drag to turn it, wheel to zoom (the page doesn't
-- scroll while the pointer is over it). The clone has no scripts and no Animator (nothing plays on it).
-- :SetObject(obj) swaps the model; :SetSpin(true) turns it slowly. element.Model is the clone on show,
-- element.Camera / element.View its camera and ViewportFrame.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

return function(card, cfg)
    local window = card.window
    local height = tonumber(cfg.Height) or 170
    local holder = create("Frame", { Name = tostring(cfg.Name or "Viewport"), Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, LayoutOrder = card:_order(), Parent = card.body })
    Theme.bind(holder, "BackgroundColor3", "base")
    corner(holder, 8)
    Theme.bind(stroke(holder), "Color", "line")
    local view = create("ViewportFrame", {
        Name = "View", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(150, 150, 155),
        LightColor = Color3.fromRGB(255, 255, 255), LightDirection = Vector3.new(-1, -1, -0.6), Parent = holder,
    })
    corner(view, 8)
    local camera = Instance.new("Camera")
    camera.FieldOfView = 40
    camera.Parent = view
    view.CurrentCamera = camera
    local world = Instance.new("WorldModel")
    world.Parent = view
    local empty = label(holder, "No object", 10, { Name = "Empty", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })
    Theme.bind(empty, "TextColor3", "muted")

    local element = Base.element(card, "Viewport", {}, holder, nil, nil)
    element.Camera, element.View = camera, view -- (to project points of the model onto the frame)
    local center, radius = Vector3.zero, 5
    local yaw, pitch, zoom = math.rad(25), math.rad(-12), 1
    local spin = cfg.Spin == true
    local function place()
        local distance = (tonumber(cfg.Distance) or radius / math.tan(math.rad(camera.FieldOfView / 2)) * 1.15) * zoom
        local rotation = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
        -- (Lower: the model sits that share of its size under the middle, room for what is drawn over it)
        local aim = center + (rotation * Vector3.new(0, 1, 0)) * radius * (tonumber(cfg.Lower) or 0)
        camera.CFrame = CFrame.new(aim) * rotation * CFrame.new(0, 0, distance)
        camera.Focus = CFrame.new(aim)
    end
    function element:SetObject(object)
        world:ClearAllChildren()
        self.Value, self.Model = object, nil
        empty.Visible = object == nil
        if not object then return end
        local ok, copy = pcall(function()
            local archivable = object.Archivable
            object.Archivable = true
            local clone = object:Clone()
            object.Archivable = archivable
            return clone
        end)
        if not ok or not copy then empty.Text = "Cannot preview" empty.Visible = true return end
        -- scripts out, physics off
        for _, d in ipairs(copy:GetDescendants()) do
            -- (an Animator left in the clone can play the character's animations on it: a dash pose stuck in the preview)
            if d:IsA("LuaSourceContainer") or d:IsA("Animator") then d:Destroy() elseif d:IsA("BasePart") then d.Anchored = true end
        end
        if copy:IsA("BasePart") then copy.Anchored = true end
        copy.Parent = world
        self.Model = copy -- (the clone being shown: a script can recolour it)
        local okBox, cf, size = pcall(function()
            if copy:IsA("Model") then return copy:GetBoundingBox() end
            return copy.CFrame, copy.Size
        end)
        if okBox then center, radius = cf.Position, math.max(size.Magnitude / 2, 0.5) end
        place()
    end
    -- turning: a per-frame step only while Spin is on (and nothing done while the preview is out of sight)
    local spinConnection
    function element:SetSpin(on)
        spin = on == true
        if spin and not spinConnection then
            spinConnection = window.maid:connect(Util.Services.RunService.Heartbeat, function(dt)
                if not holder.Parent then spinConnection:Disconnect() spinConnection = nil return end
                if holder.AbsoluteSize.X > 0 and Util.shown(holder) then yaw = yaw + (dt or 0.016) * 0.6 place() end
            end)
        elseif not spin and spinConnection then
            spinConnection:Disconnect() spinConnection = nil
        end
    end

    if cfg.Interactive ~= false then
        local hit = create("TextButton", { Name = "Drag", Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = holder })
        hit.InputBegan:Connect(function(input)
            if not Util.isPress(input) then return end
            local last = Util.pointer(input)
            window:_beginDrag(input, function(point)
                local delta = point - last
                last = point
                yaw = yaw - delta.X * 0.012
                pitch = math.clamp(pitch - delta.Y * 0.01, -1.3, 1.3)
                place()
            end)
        end)
        -- (the wheel zooms here: the page's own scrolling waits while the pointer is over the preview)
        local scroller
        hit.MouseEnter:Connect(function()
            local node = holder.Parent
            while node and not node:IsA("ScrollingFrame") do node = node.Parent end
            if node and node.ScrollingEnabled ~= false then scroller = node node.ScrollingEnabled = false end
        end)
        hit.MouseLeave:Connect(function()
            if scroller then scroller.ScrollingEnabled = true scroller = nil end
        end)
        hit.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseWheel then
                zoom = math.clamp(zoom * (input.Position.Z > 0 and 0.9 or 1.1), 0.4, 3)
                place()
            end
        end)
    end
    element:SetSpin(spin)
    element:SetObject(cfg.Object)
    return element
end
