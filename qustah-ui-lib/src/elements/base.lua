-- Shared parts of every element: the row (title + optional description), callbacks / OnChanged, flags,
-- Lock / Unlock with a reason tooltip, and the default save / load used by configs.
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")

local create, corner, label = Util.create, Util.corner, Util.label

local Base = {}

-- opts.right: pixels kept free on the right for the control; opts.button: the whole row is clickable.
function Base.row(card, cfg, height, opts)
    opts = opts or {}
    local row = create(opts.button and "TextButton" or "Frame", {
        Name = tostring(cfg.Title or "Row"), BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height), LayoutOrder = card:_order(), Parent = card.body,
    })
    if opts.button then row.Text = "" row.AutoButtonColor = false end
    local right = opts.right or 0
    local title = label(row, tostring(cfg.Title or ""), 11, {
        Name = "Title", Position = UDim2.fromOffset(0, cfg.Desc and 3 or 0),
        Size = UDim2.new(1, -right, 0, cfg.Desc and 18 or (opts.titleHeight or height)),
    })
    -- Risky = true: the title is red (a feature that can get you flagged); Risky = "text" also explains it on hover
    Theme.bind(title, "TextColor3", cfg.Risky and "danger" or "text")
    if type(cfg.Risky) == "string" and not cfg.Help then cfg.Help = cfg.Risky end
    local desc
    if cfg.Desc then
        desc = label(row, tostring(cfg.Desc), 9, { Name = "Desc", Position = UDim2.fromOffset(0, 23), Size = UDim2.new(1, -right, 0, 14) })
        Theme.bind(desc, "TextColor3", "muted")
    end
    -- Icon = "name": a small icon before the title (title / description move right)
    if cfg.Icon and not opts.noIcon then
        local icon = Icons.themed(row, cfg.Icon, 14, "muted", { Name = "RowIcon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0, cfg.Desc and 12 or height / 2) })
        if icon then
            title.Position = UDim2.new(0, 22, 0, title.Position.Y.Offset)
            title.Size = UDim2.new(1, title.Size.X.Offset - 22, 0, title.Size.Y.Offset)
            if desc then desc.Position = UDim2.fromOffset(22, 23) desc.Size = UDim2.new(1, desc.Size.X.Offset - 22, 0, 14) end
        end
    end
    -- Help = "text": a small "i" left of the control; click shows the text next to the mouse.
    if cfg.Help then
        local help = create("TextButton", {
            Name = "Help", Text = "i", TextSize = 10, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(opts.helpRight or right), 0, opts.helpY or height / 2),
            Size = UDim2.fromOffset(14, 16), ZIndex = 5, Parent = row,
        })
        Theme.bind(help, "TextColor3", "muted")
        help.Activated:Connect(function() card.window:_tip(cfg.Help) end)
        help.MouseLeave:Connect(function() card.window:_hideTip() end)
        title.Size = UDim2.new(1, -(opts.helpRight or right) - 16, 0, title.Size.Y.Offset)
    end
    return row, title, desc
end

function Base.element(card, kind, cfg, row, title, desc)
    local window = card.window
    local element = { Type = kind, Title = cfg.Title, Flag = cfg.Flag, Row = row, Card = card, Locked = false, _changed = {} }

    function element:OnChanged(callback)
        self._changed[#self._changed + 1] = callback
        return self
    end
    -- Stores the flag value; unless silent, runs Callback and the OnChanged listeners.
    function element:_fire(value, silent)
        if self.Flag then window.Lib.Flags[self.Flag] = value end
        if silent then return end
        -- errors in user callbacks are reported to the window (footer "Errors: N", Settings › Info)
        local source = tostring(self.Title or kind)
        window:_safe(source, cfg.Callback, value)
        for _, callback in ipairs(self._changed) do window:_safe(source, callback, value) end
    end
    function element:SetTitle(text) self.Title = text if title then title.Text = tostring(text) end end
    function element:SetDesc(text) if desc then desc.Text = tostring(text) end end
    function element:SetVisible(visible) row.Visible = visible ~= false end
    function element:Lock(reason)
        self.Locked = true
        self._lockReason = reason
        if not self._lock then
            local cover = create("TextButton", {
                Name = "Lock", Text = "", AutoButtonColor = false, BackgroundTransparency = 0.45, BorderSizePixel = 0,
                Position = UDim2.fromOffset(-4, -2), Size = UDim2.new(1, 8, 1, 4), ZIndex = 20, Parent = row,
            })
            Theme.bind(cover, "BackgroundColor3", "card")
            corner(cover, 6)
            cover.MouseEnter:Connect(function() if self._lockReason then window:_tip(self._lockReason) end end)
            cover.MouseLeave:Connect(function() window:_hideTip() end)
            self._lock = cover
        end
        self._lock.Visible = true
    end
    function element:Unlock()
        self.Locked = false
        if self._lock then self._lock.Visible = false end
        window:_hideTip()
    end
    function element:Destroy()
        if self.Flag and window.flags[self.Flag] == self then window.flags[self.Flag] = nil end
        window.binds[self] = nil
        row:Destroy()
    end
    function element:_save() return self.Value end
    function element:_load(value) self:Set(value) end

    if cfg.Flag then window:_register(cfg.Flag, element) end
    return element
end

-- Applied by every element after its first Set: initial lock state.
function Base.finish(element, cfg)
    if cfg.Locked then element:Lock(cfg.LockedTitle or cfg.LockedReason) end
    return element
end

return Base
