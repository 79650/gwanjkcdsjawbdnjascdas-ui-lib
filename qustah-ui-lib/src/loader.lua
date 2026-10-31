-- Download strip: a thin pill at the top of the screen while the library downloads something (icon sheets, a
-- script's icon sheet) - "Qustāh  Downloading icons  ▬▬▬▭▭  62%". It only appears when a file is
-- really fetched (files already on disk show nothing) and fades out when everything is done.
-- Util.cacheFiles(files, done, fail, "icons") drives it; Loader.title is set by the first window.
local Util = require("util")
local Theme = require("theme")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label
local Loader = { jobs = {}, title = nil, enabled = true }
local ui -- { gui, pill, title, text, fill, percent, spinner }
local spin

local function build()
    local gui = Util.screenGui("QustahUI_Loading", 65)
    pcall(function() require("font").register(gui) end)
    local pill = create("Frame", {
        Name = "Loading", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 26), Size = UDim2.fromOffset(0, 34),
        AutomaticSize = Enum.AutomaticSize.X, BorderSizePixel = 0, Parent = gui,
    })
    pill:SetAttribute("QFadedOut", true)
    Theme.bind(pill, "BackgroundColor3", "base")
    corner(pill, 17)
    Theme.bind(stroke(pill), "Color", "line")
    local row = create("Frame", { Name = "Row", BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), Parent = pill })
    Util.list(row, 10, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    Util.padding(row, 12, 16, 0, 0)
    local spinner = require("icons").themed(row, "loader-circle", 14, "muted", { Name = "Spinner", LayoutOrder = 1 })
    local title = label(row, "", 11, { Name = "Title", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 34), TextTruncate = Enum.TextTruncate.None, Font = Enum.Font.GothamBold, LayoutOrder = 2 })
    Theme.bind(title, "TextColor3", "heading")
    local text = label(row, "", 10, { Name = "Text", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 34), TextTruncate = Enum.TextTruncate.None, LayoutOrder = 3 })
    Theme.bind(text, "TextColor3", "muted")
    local track = create("Frame", { Name = "Track", Size = UDim2.fromOffset(110, 3), BorderSizePixel = 0, LayoutOrder = 4, Parent = row })
    Theme.bind(track, "BackgroundColor3", "input")
    corner(track, 2)
    local fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = track })
    Theme.bind(fill, "BackgroundColor3", "accent")
    corner(fill, 2)
    local percent = label(row, "", 10, { Name = "Percent", Size = UDim2.fromOffset(30, 34), TextXAlignment = Enum.TextXAlignment.Right, LayoutOrder = 5 })
    Theme.bind(percent, "TextColor3", "muted")
    pill.Visible = false
    ui = { gui = gui, pill = pill, title = title, text = text, fill = fill, percent = percent, spinner = spinner }
end

local function render()
    if not Loader.enabled then return end
    local active = #Loader.jobs > 0
    if active and not ui then build() end
    if not ui then return end
    if active then
        local done, total = 0, 0
        for _, job in ipairs(Loader.jobs) do done, total = done + job.done, total + job.total end
        local share = total > 0 and done / total or 0
        local newest = Loader.jobs[#Loader.jobs]
        ui.title.Text = Loader.title or "Loading"
        ui.text.Text = "Downloading " .. newest.label
        ui.percent.Text = math.floor(share * 100 + 0.5) .. "%"
        Util.tween(ui.fill, 0.2, { Size = UDim2.fromScale(math.max(share, 0.04), 1) })
        if not ui.pill.Visible or ui.pill:GetAttribute("QFadedOut") then
            ui.pill.Visible = true
            Util.fadeTree(ui.pill, 0.18, 0)
        end
        if not spin then
            spin = Util.Services.RunService.Heartbeat:Connect(function(dt)
                if ui and ui.spinner then ui.spinner.Rotation = (ui.spinner.Rotation + dt * 360) % 360 end
            end)
        end
    else
        Loader.visible = false
        if spin then spin:Disconnect() spin = nil end
        if ui.pill.Visible and not ui.pill:GetAttribute("QFadedOut") then
            ui.fill.Size = UDim2.fromScale(1, 1)
            ui.percent.Text = "100%"
            Util.fadeTree(ui.pill, 0.25, 1)
            task.delay(0.26, function() if ui and #Loader.jobs == 0 then ui.pill.Visible = false end end)
        end
        return
    end
    Loader.visible = true
end

-- A download of `total` files: job:step() after each one, job:finish() at the end (done or failed).
function Loader.start(what, total)
    local job = { label = tostring(what), total = math.max(1, total or 1), done = 0 }
    function job.step() job.done = math.min(job.total, job.done + 1) render() end
    function job.finish()
        local index = table.find(Loader.jobs, job)
        if index then table.remove(Loader.jobs, index) end
        render()
    end
    Loader.jobs[#Loader.jobs + 1] = job
    render()
    return job
end

-- the first window's title (shown in the strip)
function Loader.setTitle(text)
    Loader.title = text
    if ui and #Loader.jobs > 0 then ui.title.Text = text end
end

return Loader
