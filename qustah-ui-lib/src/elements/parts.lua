-- Small pieces shared by the dashboard-style elements (StatTiles, Gauges, Tiles, Timeline, ...):
-- grid cells, chips, sparklines, dotted rings, state colours. Not an element itself.
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

local Parts = {}

-- a state name -> theme role: "on" / "ok" green, "limited" / "warn" amber, "error" red, anything else muted
Parts.STATE = {
    on = "success", ok = "success", running = "success", success = "success", good = "success",
    limited = "warning", warn = "warning", warning = "warning", pending = "warning",
    error = "danger", danger = "danger", failed = "danger", off = "muted", idle = "muted", none = "muted",
}
function Parts.stateRole(state)
    if state == true then return "success" elseif state == false or state == nil then return "muted" end
    return Parts.STATE[string.lower(tostring(state))] or "muted"
end

-- Color = "warning" (a theme role) or a Color3: what Theme.bind takes
function Parts.color(value, fallback)
    if typeof(value) == "Color3" or type(value) == "string" then return value end
    return fallback or "heading"
end

-- position / size of cell `index` (1-based) in a grid of `columns` with `gap` px between cells
function Parts.cell(index, columns, gap, height, top)
    local col, row = (index - 1) % columns, math.floor((index - 1) / columns)
    return UDim2.new(col / columns, col * gap / columns, 0, (top or 0) + row * (height + gap)),
        UDim2.new(1 / columns, -gap * (columns - 1) / columns, 0, height)
end
function Parts.gridHeight(count, columns, gap, height)
    local rows = math.ceil(count / columns)
    return rows > 0 and rows * height + (rows - 1) * gap or 0
end

-- a box like the library's inputs (tile background)
function Parts.box(parent, props)
    local frame = create("Frame", { BorderSizePixel = 0, Parent = parent })
    for key, value in pairs(props or {}) do frame[key] = value end
    Theme.bind(frame, "BackgroundColor3", "input")
    corner(frame, 7)
    local edge = stroke(frame, nil, 0.2)
    Theme.bind(edge, "Color", "line")
    return frame, edge
end

-- a small rounded chip: [icon] text. Returns the frame and its label; chip:SetText via the label.
function Parts.chip(parent, text, role, iconName, props)
    local width = Util.textWidth(text, 9, Enum.Font.GothamMedium) + (iconName and 38 or 24)
    local frame = create("Frame", { Name = "Chip", Size = UDim2.fromOffset(width, 18), BorderSizePixel = 0, Parent = parent })
    for key, value in pairs(props or {}) do frame[key] = value end
    Theme.bind(frame, "BackgroundColor3", "input")
    corner(frame, 9)
    Theme.bind(stroke(frame, nil, 0.3), "Color", "buttonEdge")
    local x = 8
    if iconName then
        local icon = Icons.themed(frame, iconName, 10, role or "muted", { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 7, 0.5, 0) })
        if icon then x = 21 end
    end
    local text_ = label(frame, text, 9, { Name = "Text", Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -x - 6, 1, 0), Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.None })
    Theme.bind(text_, "TextColor3", role or "text")
    local function resize(value)
        text_.Text = tostring(value)
        frame.Size = UDim2.fromOffset(Util.textWidth(text_.Text, 9, Enum.Font.GothamMedium) + x + 16, 18)
    end
    return frame, text_, resize
end

-- a small status dot
function Parts.dot(parent, role, size, props)
    local dot = create("Frame", { Name = "Dot", Size = UDim2.fromOffset(size or 6, size or 6), BorderSizePixel = 0, Parent = parent })
    for key, value in pairs(props or {}) do dot[key] = value end
    corner(dot, (size or 6))
    Theme.bind(dot, "BackgroundColor3", role or "muted")
    return dot
end

-- A sparkline (line of frames) inside `parent` (fills it). Returns draw(values): redraws with these values.
-- Lines are drawn from the frame's own size (AbsoluteSize, without the window's UI scale).
function Parts.sparkline(parent, role, scaleOf)
    local holder = create("Frame", { Name = "Spark", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ClipsDescendants = true, Parent = parent })
    local segments, last = {}, nil
    local function draw(values)
        last = values or last
        values = last or {}
        local scale = scaleOf and scaleOf() or 1
        local w, h = holder.AbsoluteSize.X / scale, holder.AbsoluteSize.Y / scale
        local count = #values
        if w <= 0 or h <= 0 or count < 2 then for _, s in ipairs(segments) do s.Visible = false end return end
        local low, high = math.huge, -math.huge
        for _, v in ipairs(values) do low, high = math.min(low, v), math.max(high, v) end
        if high - low < 1e-6 then low, high = low - 1, high + 1 end
        local function point(i) return (i - 1) / (count - 1) * w, h - 2 - (values[i] - low) / (high - low) * (h - 4) end
        for i = 1, math.max(#segments, count - 1) do
            local seg = segments[i]
            if not seg then
                seg = create("Frame", { Name = "Seg", AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Parent = holder })
                Theme.bind(seg, "BackgroundColor3", role or "heading")
                segments[i] = seg
            end
            if i < count then
                local x1, y1 = point(i)
                local x2, y2 = point(i + 1)
                local dx, dy = x2 - x1, y2 - y1
                seg.Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
                seg.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + 1, 1.5)
                seg.Rotation = math.deg(math.atan2(dy, dx))
                seg.Visible = true
            else
                seg.Visible = false
            end
        end
    end
    holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() draw() end)
    return draw, holder
end

-- A ring of `count` dots round the centre of `parent` (size px); set(fraction, role) lights the first part.
function Parts.dotRing(parent, size, count, dotSize)
    count, dotSize = count or 40, dotSize or 3
    local dots = {}
    local radius = size / 2 - dotSize
    for i = 1, count do
        local angle = (i - 1) / count * math.pi * 2 - math.pi / 2
        local dot = create("Frame", {
            Name = "Seg", AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Size = UDim2.fromOffset(dotSize, dotSize),
            Position = UDim2.new(0.5, math.cos(angle) * radius, 0.5, math.sin(angle) * radius), Parent = parent,
        })
        corner(dot, dotSize)
        Theme.bind(dot, "BackgroundColor3", "line")
        dots[i] = dot
    end
    return function(fraction, role)
        local lit = math.floor(math.clamp(tonumber(fraction) or 0, 0, 1) * count + 0.5)
        for i, dot in ipairs(dots) do Theme.bind(dot, "BackgroundColor3", i <= lit and (role or "heading") or "line") end
    end
end

-- the window's UI scale (for drawing in px)
function Parts.scaleOf(window)
    return function() return window and window.scale and window.scale.Scale or 1 end
end

-- a header line for an element: title (left) and an optional right-hand text; returns title, right labels
function Parts.header(holder, cfg, y)
    local title, right
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Position = UDim2.fromOffset(0, y or 0), Size = UDim2.new(1, -90, 0, 20) })
        Theme.bind(title, "TextColor3", "text")
        right = label(holder, "", 9, { Name = "Right", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, y or 0), Size = UDim2.fromOffset(90, 20), TextXAlignment = Enum.TextXAlignment.Right })
        Theme.bind(right, "TextColor3", "muted")
    end
    return title, right
end

return Parts
