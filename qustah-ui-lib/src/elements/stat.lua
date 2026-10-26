-- card:Stat({ Title = "Coins", Value = 0, Icon = "coins", Prefix = "$", Suffix = " /h", Decimals = 0, Separator = ",",
--             Delta = "percent" | "absolute" | false, Invert = false, Format = function(value) return "..." end })
-- A big number whose digits roll like an odometer when it changes, with a chip showing the last change
-- (+12.5% green, -3 red; Invert = true when lower is better, e.g. ping). :Set(value), :Add(amount), :Get().
-- No flag (it shows something, it does not configure).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

local SIZE, HEIGHT = 18, 22
local FONT = Enum.Font.GothamBold

local function group(text, separator)
    if separator == "" then return text end
    local sign, whole, rest = text:match("^([%-]?)(%d+)(.*)$")
    if not whole then return text end
    whole = whole:reverse():gsub("(%d%d%d)", "%1" .. separator:reverse()):reverse()
    if whole:sub(1, #separator) == separator then whole = whole:sub(#separator + 1) end
    return sign .. whole .. rest
end

return function(card, cfg)
    local hasIcon = cfg.Icon and Icons.Get(cfg.Icon)
    local x = hasIcon and 44 or 0
    local holder = create("Frame", { Name = tostring(cfg.Title or "Stat"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = card:_order(), Parent = card.body })
    if hasIcon then
        local tile = create("Frame", { Name = "IconTile", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(34, 34), BorderSizePixel = 0, Parent = holder })
        Theme.bind(tile, "BackgroundColor3", "accentDeep")
        corner(tile, 9)
        local edge = stroke(tile, nil, 0.6)
        Theme.bind(edge, "Color", "accent")
        Icons.themed(tile, cfg.Icon, 16, "accent", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
    end
    local title = label(holder, tostring(cfg.Title or ""), 9, { Name = "Title", Position = UDim2.fromOffset(x, 2), Size = UDim2.new(1, -x - 80, 0, 14), Font = Enum.Font.GothamMedium })
    Theme.bind(title, "TextColor3", "muted")
    local digits = create("Frame", { Name = "Digits", BackgroundTransparency = 1, Position = UDim2.fromOffset(x, 17), Size = UDim2.new(1, -x - 80, 0, HEIGHT), ClipsDescendants = true, Parent = holder })
    Util.list(digits, 0, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)

    -- change chip on the right
    local chip = create("Frame", { Name = "Delta", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, BorderSizePixel = 0, Visible = false, Parent = holder })
    corner(chip, 10)
    Util.list(chip, 4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    Util.padding(chip, 7, 8, 0, 0)
    local chipIcon = Icons.themed(chip, "trending-up", 11, "success", { Name = "Arrow", LayoutOrder = 1 })
    local chipText = label(chip, "", 9, { Name = "Text", Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2 })

    local element = Base.element(card, "Stat", {}, holder, title, nil)
    local decimals = math.max(0, math.floor(tonumber(cfg.Decimals) or 0))
    local separator = cfg.Separator == nil and "," or tostring(cfg.Separator)
    local digitWidth = math.max(8, Util.textWidth("0", SIZE, FONT) + 2)

    local function format(value)
        if type(cfg.Format) == "function" then
            local ok, result = pcall(cfg.Format, value)
            if ok then return tostring(result) end
        end
        local text = decimals > 0 and string.format("%." .. decimals .. "f", value) or tostring(math.floor(value + 0.5))
        return tostring(cfg.Prefix or "") .. group(text, separator) .. tostring(cfg.Suffix or "")
    end

    -- one column per character: digits are a 0-9 strip that slides, everything else a plain label
    local columns, shape = {}, nil
    local function build(text)
        for _, column in ipairs(columns) do column.frame:Destroy() end
        columns = {}
        for index = 1, #text do
            local char = text:sub(index, index)
            local digit = tonumber(char)
            if digit then
                local frame = create("Frame", { Name = "Digit", BackgroundTransparency = 1, Size = UDim2.fromOffset(digitWidth, HEIGHT), ClipsDescendants = true, LayoutOrder = index, Parent = digits })
                local strip = create("Frame", { Name = "Strip", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, -digit * HEIGHT), Size = UDim2.fromOffset(digitWidth, HEIGHT * 10), Parent = frame })
                for n = 0, 9 do
                    local glyph = label(strip, tostring(n), SIZE, { Name = tostring(n), Position = UDim2.fromOffset(0, n * HEIGHT), Size = UDim2.fromOffset(digitWidth, HEIGHT), Font = FONT, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.None })
                    Theme.bind(glyph, "TextColor3", "heading")
                end
                columns[index] = { frame = frame, strip = strip, digit = digit }
            else
                local frame = label(digits, char, SIZE, { Name = "Char", Size = UDim2.fromOffset(char == " " and 4 or 0, HEIGHT), AutomaticSize = char == " " and Enum.AutomaticSize.None or Enum.AutomaticSize.X, Font = FONT, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.None, LayoutOrder = index })
                Theme.bind(frame, "TextColor3", "heading")
                columns[index] = { frame = frame, char = char }
            end
        end
    end
    -- the layout of digits / other characters, e.g. "$9,999": a change here rebuilds, otherwise digits roll
    local function shapeOf(text) return (text:gsub("%d", "#")) end

    local function show(text, animate)
        local newShape = shapeOf(text)
        if newShape ~= shape then
            shape = newShape
            build(text)
            return
        end
        for index = 1, #text do
            local column, digit = columns[index], tonumber(text:sub(index, index))
            if column and column.strip and digit and digit ~= column.digit then
                column.digit = digit
                local target = UDim2.fromOffset(0, -digit * HEIGHT)
                if animate then
                    -- the further right, the quicker (like a real counter)
                    Util.tween(column.strip, 0.35 + (#text - index) * 0.04, { Position = target }, Enum.EasingStyle.Quint)
                else
                    column.strip.Position = target
                end
            end
        end
    end

    local mode = cfg.Delta == nil and "percent" or cfg.Delta
    local function renderDelta(old, new)
        if not mode or old == nil or old == new then return end
        local change = new - old
        local good = (change > 0) ~= (cfg.Invert == true)
        local role = good and "success" or "danger"
        local text
        if mode == "absolute" then
            text = (change > 0 and "+" or "") .. format(change):gsub("^" .. tostring(cfg.Prefix or ""):gsub("%p", "%%%0"), "")
        else
            if old == 0 then text = change > 0 and "+new" or "-" else text = string.format("%+.1f%%", change / math.abs(old) * 100) end
        end
        chipText.Text = text
        Theme.bind(chip, "BackgroundColor3", role)
        chip.BackgroundTransparency = 0.86
        Theme.bind(chipText, "TextColor3", role)
        if chipIcon then
            Icons.Apply(chipIcon, change > 0 and "trending-up" or "trending-down")
            Theme.bind(chipIcon, "ImageColor3", role)
        end
        chip.Visible = true
    end

    function element:Set(value, silent)
        value = tonumber(value)
        if not value then return end
        local old = self.Value
        self.Value = value
        show(format(value), old ~= nil and not silent)
        renderDelta(old, value)
    end
    function element:Add(amount) self:Set((self.Value or 0) + (tonumber(amount) or 0)) end
    function element:Get() return self.Value end
    function element:SetTitle(text) title.Text = tostring(text) end
    element:Set(tonumber(cfg.Value or cfg.Default) or 0, true)
    return element
end
