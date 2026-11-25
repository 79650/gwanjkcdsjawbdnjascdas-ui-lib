-- card:Code({ Title = "loader.lua", Code = "print('hi')", Copy = true, CopyIcon = true, CopyText = true, MaxHeight = 200, Truncate = false })
-- CopyValue = function() return text end: what Copy copies (default: the code); CopyTooltip: its tooltip.
-- Actions = { { Icon = "trash-2", Tooltip = "Clear", Callback = fn } }: more icons in the header, left of Copy.
-- A code block: monospace, Lua colouring (keywords, strings, numbers, comments, functions), scrolls sideways for long
-- lines and down past MaxHeight. Copy button in the header. :Set(code).
-- Truncate = true: one line that ends in "..." inside the box (the same room left and right) instead of scrolling -
-- for a long token to copy, like a share code.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

local KEYWORDS = {}
for word in ("and break do else elseif end false for function if in local nil not or repeat return then true until while continue"):gmatch("%a+") do KEYWORDS[word] = true end
local GLOBALS = {}
for word in ("game workspace script task math string table print warn pcall require loadstring getgenv Instance Vector3 Vector2 CFrame UDim2 Color3 Enum"):gmatch("%a+") do GLOBALS[word] = true end
-- colours come from the theme (codeKeyword...), so light packs get darker ones
local ROLES = { keyword = "codeKeyword", string = "codeString", number = "codeNumber", comment = "codeComment", global = "codeGlobal", call = "codeCall" }

local function escape(text) return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
local function paint(kind, text) return '<font color="#' .. Util.toHex(Theme.get(ROLES[kind])) .. '">' .. escape(text) .. "</font>" end

-- Small Lua tokenizer -> RichText (one pass, no nesting issues).
local function highlight(source)
    local out, i, n = {}, 1, #source
    while i <= n do
        local c = source:sub(i, i)
        if source:sub(i, i + 1) == "--" then
            local long = source:match("^%-%-%[(=*)%[", i)
            local stop
            if long then stop = select(2, source:find("%]" .. long .. "%]", i)) end
            stop = stop or (source:find("\n", i) or n + 1) - 1
            out[#out + 1] = paint("comment", source:sub(i, stop))
            i = stop + 1
        elseif c == '"' or c == "'" then
            local j = i + 1
            while j <= n do
                local d = source:sub(j, j)
                if d == "\\" then j = j + 2 elseif d == c or d == "\n" then break else j = j + 1 end
            end
            out[#out + 1] = paint("string", source:sub(i, j))
            i = j + 1
        elseif source:match("^%[=*%[", i) then
            local eq = source:match("^%[(=*)%[", i)
            local stop = select(2, source:find("%]" .. eq .. "%]", i)) or n
            out[#out + 1] = paint("string", source:sub(i, stop))
            i = stop + 1
        elseif c:match("%d") then
            local number = source:match("^0[xX]%x+", i) or source:match("^%d+%.?%d*[eE][%-+]?%d+", i) or source:match("^%d+%.?%d*", i)
            out[#out + 1] = paint("number", number)
            i = i + #number
        elseif c:match("[%a_]") then
            local word = source:match("^[%w_]+", i)
            local after = source:match("^%s*(.)", i + #word)
            if KEYWORDS[word] then out[#out + 1] = paint("keyword", word)
            elseif GLOBALS[word] then out[#out + 1] = paint("global", word)
            elseif after == "(" then out[#out + 1] = paint("call", word)
            else out[#out + 1] = escape(word) end
            i = i + #word
        else
            out[#out + 1] = escape(c)
            i = i + 1
        end
    end
    return table.concat(out)
end

return function(card, cfg)
    local window = card.window
    local maxHeight = tonumber(cfg.MaxHeight) or 200
    local holder = create("Frame", { Name = tostring(cfg.Title or "Code"), Size = UDim2.new(1, 0, 0, 60), BorderSizePixel = 0, LayoutOrder = card:_order(), Parent = card.body })
    Theme.bind(holder, "BackgroundColor3", "base")
    corner(holder, 7)
    Theme.bind(stroke(holder), "Color", "line")
    local head = create("Frame", { Name = "Head", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), Parent = holder })
    Icons.themed(head, "code", 12, "muted", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0) })
    local title = label(head, tostring(cfg.Title or "Code"), 10, { Name = "Title", Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -90, 1, 0), Font = Enum.Font.GothamMedium })
    Theme.bind(title, "TextColor3", "text")
    local line = create("Frame", { Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = holder })
    Theme.bind(line, "BackgroundColor3", "line")
    local scroller = create("ScrollingFrame", {
        Name = "Body", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 27), Size = UDim2.new(1, 0, 1, -27),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.XY, ScrollBarThickness = 3, Parent = holder,
    })
    Theme.bind(scroller, "ScrollBarImageColor3", "muted")
    Util.fadeScrollbar(scroller)
    local truncate = cfg.Truncate == true
    local text = create("TextLabel", {
        Name = "Code", BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 8), Size = truncate and UDim2.new(1, -20, 0, 14) or UDim2.fromOffset(0, 0),
        AutomaticSize = truncate and Enum.AutomaticSize.None or Enum.AutomaticSize.XY,
        Font = Enum.Font.Code, TextSize = 11, RichText = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = false, TextTruncate = truncate and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None, Text = "", Parent = scroller,
    })
    text:SetAttribute("QCode", true) -- the code font (RobotoMono / CreateWindow CodeFont)
    Theme.bind(text, "TextColor3", "heading")
    if truncate then
        scroller.ScrollingEnabled = false
        scroller.AutomaticCanvasSize = Enum.AutomaticSize.None
    else
        create("UIPadding", { PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 10), Parent = text })
    end

    local element = Base.element(card, "Code", {}, holder, title, nil)
    local function fit()
        local lines = select(2, (element.Value or ""):gsub("\n", "\n")) + 1
        holder.Size = UDim2.new(1, 0, 0, math.min(maxHeight, 27 + 18 + lines * 14))
    end
    function element:Set(code)
        self.Value = tostring(code or "")
        text.Text = cfg.Highlight == false and self.Value:gsub("<", "&lt;") or highlight(self.Value)
        fit()
    end
    function element:Get() return self.Value end

    if cfg.Copy ~= false then
        -- CopyText = false: just the copy icon, no box (it turns into a tick / a cross for a moment)
        if cfg.CopyText == false then
            local copy = create("ImageButton", {
                Name = "Copy", Image = "", BackgroundTransparency = 1, AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(18, 18), Parent = head,
            })
            local copyIcon = Icons.themed(copy, "copy", 14, "muted", { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
            local busy = false
            copy.MouseEnter:Connect(function() if not busy and copyIcon then Theme.tweenTo(copyIcon, "ImageColor3", "heading", 0.1) end window:_tip(cfg.CopyTooltip or "Copy") end)
            copy.MouseLeave:Connect(function() if not busy and copyIcon then Theme.tweenTo(copyIcon, "ImageColor3", "muted", 0.1) end window:_hideTip() end)
            copy.Activated:Connect(function()
                local clipboard = setclipboard or toclipboard
                local ok = type(clipboard) == "function" and pcall(function() clipboard(type(cfg.CopyValue) == "function" and cfg.CopyValue() or element.Value) end)
                if ok and cfg.OnCopy then window:_safe("Code", cfg.OnCopy) end
                if not copyIcon then return end
                busy = true
                Icons.Apply(copyIcon, ok and "check" or "x")
                Theme.bind(copyIcon, "ImageColor3", ok and "success" or "danger")
                task.delay(1.4, function()
                    busy = false
                    if copy.Parent then Icons.Apply(copyIcon, "copy") Theme.bind(copyIcon, "ImageColor3", "muted") end
                end)
            end)
        else
            local copy = create("TextButton", {
                Name = "Copy", Text = "", AutoButtonColor = false, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(52, 18), Parent = head,
            })
            Theme.bind(copy, "BackgroundColor3", "input")
            corner(copy, 5)
            Theme.bind(stroke(copy), "Color", "buttonEdge")
            -- (CopyIcon = false: the word alone, centred)
            local withIcon = cfg.CopyIcon ~= false
            local copyText = label(copy, "Copy", 9, { Position = UDim2.fromOffset(withIcon and 20 or 0, 0), Size = UDim2.new(1, withIcon and -22 or 0, 1, 0),
                Font = Enum.Font.GothamMedium, TextXAlignment = withIcon and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center })
            Theme.bind(copyText, "TextColor3", "text")
            local copyIcon = withIcon and Icons.themed(copy, "copy", 10, "text", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 7, 0.5, 0) }) or nil
            copy.Activated:Connect(function()
                local clipboard = setclipboard or toclipboard
                local ok = type(clipboard) == "function" and pcall(function() clipboard(type(cfg.CopyValue) == "function" and cfg.CopyValue() or element.Value) end)
                copyText.Text = ok and "Copied" or "Failed"
                if copyIcon then Icons.Apply(copyIcon, ok and "check" or "x") end
                if ok and cfg.OnCopy then window:_safe("Code", cfg.OnCopy) end
                task.delay(1.4, function()
                    if copy.Parent then copyText.Text = "Copy" if copyIcon then Icons.Apply(copyIcon, "copy") end end
                end)
            end)
        end
    end
    -- more header icons, right to left from the Copy button
    local x = cfg.Copy == false and 8 or (cfg.CopyText == false and 8 + 18 + 6 or 6 + 52 + 8)
    element.Actions = {}
    for index, action in ipairs(cfg.Actions or {}) do
        local button = create("ImageButton", {
            Name = tostring(action.Tooltip or ("Action" .. index)), Image = "", BackgroundTransparency = 1, AutoButtonColor = false,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -x, 0.5, 0), Size = UDim2.fromOffset(18, 18), Parent = head,
        })
        local icon = Icons.themed(button, action.Icon, 14, "muted", { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
        local hover = action.Danger and "danger" or "heading"
        button.MouseEnter:Connect(function() if icon then Theme.tweenTo(icon, "ImageColor3", hover, 0.1) end if action.Tooltip then window:_tip(action.Tooltip) end end)
        button.MouseLeave:Connect(function() if icon then Theme.tweenTo(icon, "ImageColor3", "muted", 0.1) end window:_hideTip() end)
        button.Activated:Connect(function() if action.Callback then window:_safe("Code", action.Callback) end end)
        element.Actions[index] = button
        x = x + 18 + 6
    end
    title.Size = UDim2.new(1, -(28 + x + 4), 1, 0)
    element:Set(cfg.Code or "")
    element.Maid:give(Theme.onChange(function() if holder.Parent then element:Set(element.Value) end end))
    return element
end
