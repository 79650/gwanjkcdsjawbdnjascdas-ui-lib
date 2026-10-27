-- Contrast of every text-on-background pair the library uses, for every theme pack.
getfenv(0).SMOKE_STEPS = function(MOCK)
    local E = getfenv(0)
    local Lib = E.getgenv().TestLib
    local Theme = Lib.Theme
    local w = Lib.Windows[1]
    local pairs_ = {
        -- foreground, background, minimum, what
        { "text", "card", 4.5, "row titles" }, { "muted", "card", 3, "descriptions" }, { "heading", "card", 4.5, "headings" },
        { "muted", "input", 3, "placeholders" }, { "text", "input", 4.5, "button text" }, { "heading", "selected", 4.5, "selected chip" },
        { "accent", "card", 3, "accent text" }, { "accent", "accentDeep", 3, "primary button" },
        { "warning", "card", 3, "lock reasons / warnings" }, { "danger", "card", 3, "risky titles / errors" }, { "success", "card", 3, "success text" },
        { "dangerText", "dangerDeep", 4.5, "danger button" }, { "onAccent", "accent", 3, "checkbox tick" },
        { "knob", "toggleOn", 1.6, "switch knob (on)" }, { "knob", "buttonEdge", 1.6, "switch knob (off)" },
        { "buttonEdge", "card", 1.25, "outlines" }, { "line", "card", 1.08, "card lines" }, { "muted", "base", 3, "footer text" },
        { "icon", "dock", 3, "dock icons" }, { "accent", "dock", 3, "dock selected icon" },
    }
    local function lum(c)
        local function ch(v) return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
        return 0.2126 * ch(c.R) + 0.7152 * ch(c.G) + 0.0722 * ch(c.B)
    end
    local function contrast(a, b) local x, y = lum(a), lum(b) if x < y then x, y = y, x end return (x + 0.05) / (y + 0.05) end
    local bad = 0
    for _, accent in ipairs({ "Neutral", "Blue", "Green", "Orange" }) do
        for _, name in ipairs(Theme.packOrder) do
            Theme.applyPack(name)
            local presets = { Neutral = Theme.neutral(name), Blue = E.Color3.fromRGB(61, 151, 219), Green = E.Color3.fromRGB(110, 200, 130), Orange = E.Color3.fromRGB(215, 170, 105) }
            if accent ~= "Neutral" or true then Theme.set("accent", presets[accent]) end
            for _, p in ipairs(pairs_) do
                local fg, bg = Theme.get(p[1]), Theme.get(p[2])
                if typeof(fg) == "Color3" and typeof(bg) == "Color3" then
                    local c = contrast(fg, bg)
                    if c < p[3] then bad = bad + 1 print(string.format("LOW %-12s %-8s %-11s on %-11s %.2f < %.2f  (%s)", name, accent, p[1], p[2], c, p[3], p[4])) end
                else
                    print("MISSING", name, p[1], p[2])
                end
            end
        end
    end
    print("== CONTRAST low pairs", bad)
end
