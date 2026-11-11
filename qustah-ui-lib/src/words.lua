-- Word pictures: a script's fixed words (its name, version, tags) shown as pictures drawn beforehand (letters fitted to
-- whole pixels, a real soft glow behind the name), tools/gen_words.py. Anything not on the sheet stays text.
--   Lib.Words.Use(manifest, "https://.../folder/")   before the window: the header's title, version and tags whose
--                                                    text and size are on the sheet show as pictures
--   Lib.Words.Apply(label)                           a label of your own
-- The picture follows the label: its colour (theme, accent, the text glow's shine) and its transparency. The label
-- keeps its place in the layout (its text is moved to the QWord attribute).
local Util = require("util")
local Theme = require("theme")

local Words = { sheet = nil, image = nil, waiting = {} }

local function entry(label)
    local sheet = Words.sheet
    local text = label:GetAttribute("QWord") or label.Text
    return sheet and sheet.Words[tostring(text) .. "|" .. tostring(label.TextSize)], text
end

local function attach(label)
    if label:FindFirstChild("Word") then return true end
    local place, text = entry(label)
    if not place or not Words.image then return false end
    local x, y, w, h, ink, line, glowX = place[1], place[2], place[3], place[4], place[5], place[6], place[7]
    local pad = Words.sheet.Pad or 8
    label:SetAttribute("QWord", text)
    -- (the label keeps the room the picture needs; its own text goes)
    label.AutomaticSize = Enum.AutomaticSize.None
    label.Size = UDim2.new(0, ink, label.Size.Y.Scale, label.Size.Y.Offset)
    label.Text = ""
    local function picture(name, offsetX, z)
        return Util.create("ImageLabel", {
            Name = name, BackgroundTransparency = 1, Image = Words.image, ImageRectOffset = Vector2.new(offsetX, y),
            ImageRectSize = Vector2.new(w, h), Size = UDim2.fromOffset(w, h),
            -- (its line of text centred in the label like Roblox centres text, on whole pixels)
            Position = UDim2.new(0, -pad, 0.5, -math.floor(line / 2) - pad),
            ZIndex = label.ZIndex, Parent = label,
        })
    end
    local glow = glowX and picture("WordGlow", glowX, math.max(1, label.ZIndex - 1)) or nil
    local word = picture("Word", x, label.ZIndex)
    -- the label's shine gradient (the text glow) moves onto the picture; its outline becomes the soft glow
    local shine = label:FindFirstChildOfClass("UIGradient")
    if shine then shine.Parent = word end
    local outline = label:FindFirstChild("Glow")
    local function follow()
        if not word.Parent then return end
        word.ImageColor3 = label.TextColor3
        word.ImageTransparency = label.TextTransparency
        if glow then
            local on = outline == nil or outline.Enabled
            glow.Visible = on
            glow.ImageColor3 = outline and outline.Color or label.TextColor3
            glow.ImageTransparency = 1 - (1 - label.TextTransparency) * 0.55
        end
    end
    label:GetPropertyChangedSignal("TextColor3"):Connect(follow)
    label:GetPropertyChangedSignal("TextTransparency"):Connect(follow)
    if outline then
        outline.Enabled = false
        outline:GetPropertyChangedSignal("Color"):Connect(follow)
        -- (Glow turns the outline on and off with the setting: the picture's glow follows, the outline stays off)
        local busy = false
        outline:GetPropertyChangedSignal("Enabled"):Connect(function()
            if busy then return end
            busy = true
            local on = outline.Enabled
            outline.Enabled = false
            if glow then glow.Visible = on end
            busy = false
        end)
    end
    follow()
    return true
end

-- Shows a label's text as its picture when the sheet has it (now, or once the sheet is downloaded).
function Words.Apply(label)
    if not (label and label:IsA("TextLabel")) then return false end
    if attach(label) then return true end
    if Words.sheet and not Words.image then Words.waiting[#Words.waiting + 1] = label end
    return false
end

-- The sheet: manifest from gen_words.py, source = the folder it is in. Downloaded once, like the icon sheets.
function Words.Use(manifest, source)
    if type(manifest) ~= "table" or type(source) ~= "string" then return end
    Words.sheet = manifest
    local path = "QustahUI/words/" .. tostring(manifest.Id) .. "-" .. tostring(manifest.File)
    Util.cacheFiles({ { path = path, url = source .. manifest.File, check = function(body) return body:sub(2, 4) == "PNG" end } },
        function(ids)
            Words.image = ids[path]
            local list = Words.waiting
            Words.waiting = {}
            for _, label in ipairs(list) do if label.Parent then pcall(attach, label) end end
        end, function() end, "words")
end

return Words
