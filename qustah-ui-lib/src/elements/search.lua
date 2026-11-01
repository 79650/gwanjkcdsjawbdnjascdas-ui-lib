-- card:Search({ Placeholder = "Search settings…" })
-- A search box that filters the page it is on: rows whose title (or description, also of what is inside them) does
-- not contain the text hide,
-- and so do cards with nothing left; an empty box shows everything again. Put it in a card of its own at the top
-- (page:Card({ Wide = true })). :Set(text), :Get(), :Clear(). No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local holder = create("Frame", { Name = "Search", Size = UDim2.new(1, 0, 0, 30), BorderSizePixel = 0, LayoutOrder = card:_order(), Parent = card.body })
    Theme.bind(holder, "BackgroundColor3", "input")
    corner(holder, 7)
    Theme.bind(Util.stroke(holder, nil, 0.2), "Color", "buttonEdge")
    Icons.themed(holder, "search", 13, "muted", { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0) })
    local box = create("TextBox", {
        Name = "Box", BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -60, 1, 0), Text = "", ClearTextOnFocus = false,
        PlaceholderText = tostring(cfg.Placeholder or "Search…"), TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
    })
    Theme.bind(box, "TextColor3", "heading")
    local count = label(holder, "", 9, { Name = "Count", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(60, 14), TextXAlignment = Enum.TextXAlignment.Right })
    Theme.bind(count, "TextColor3", "muted")
    local element = Base.element(card, "Search", { Title = cfg.Title }, holder, nil, nil)
    local own = card.frame
    local page = card.page

    -- every card frame on the page (columns and wide areas), not the one holding the box
    local function cards()
        local out = {}
        for _, area in ipairs({ page.wide, page.left, page.right, page.wideBottom }) do
            if area then
                for _, child in ipairs(area:GetChildren()) do
                    if child:IsA("Frame") and child ~= own and child:FindFirstChildOfClass("UIListLayout") then out[#out + 1] = child end
                end
            end
        end
        return out
    end
    -- the text a row can be found by: its name, its Title / Desc labels
    -- (titles further in count too: a SideNav part, a Row of toggles, a grid of tiles)
    local function words(row)
        local parts = { row.Name }
        for _, item in ipairs(row:GetDescendants()) do
            if item:IsA("TextLabel") and (item.Name == "Title" or item.Name == "Desc") then parts[#parts + 1] = item.Text end
        end
        return string.lower(table.concat(parts, " "))
    end
    local hidden = {}
    local function apply(query)
        query = string.lower(query or "")
        for object, was in pairs(hidden) do if object.Parent then object.Visible = was end end
        table.clear(hidden)
        if query == "" then count.Text = "" return end
        local found = 0
        for _, frame in ipairs(cards()) do
            local any = false
            local heading = frame:FindFirstChild("Heading")
            local cardMatch = heading and string.find(string.lower(heading:FindFirstChildWhichIsA("TextLabel") and heading:FindFirstChildWhichIsA("TextLabel").Text or ""), query, 1, true)
            for _, row in ipairs(frame:GetChildren()) do
                if row:IsA("GuiObject") and row ~= heading and row.Name ~= "CardDesc" and row.Visible then
                    if cardMatch or string.find(words(row), query, 1, true) then
                        any = true found = found + 1
                    else
                        hidden[row] = row.Visible row.Visible = false
                    end
                end
            end
            if not any then hidden[frame] = frame.Visible frame.Visible = false end
        end
        count.Text = found == 1 and "1 match" or (found .. " matches")
    end
    box:GetPropertyChangedSignal("Text"):Connect(function() apply(box.Text) end)
    function element:Set(text) box.Text = tostring(text or "") apply(box.Text) end
    function element:Get() return box.Text end
    function element:Clear() self:Set("") end
    return Base.finish(element, cfg)
end
