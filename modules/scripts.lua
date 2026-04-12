-- scripts.lua
-- Manages the SCRIPTS tab: built-in entries + auto-load from scripts.json
-- Fix: clears ALL script buttons (including built-in) before reload to prevent doubling

local SCRIPTS_JSON_URL = "https://raw.githubusercontent.com/artfghjkq/roblox-script/refs/heads/main/scripts.json"

local Scripts = {}

function Scripts:Init(scriptsContent, COLORS, galaxyGradient, createCorner, Notif)
    -- B&W fallback keys
    local BG   = COLORS.Panel   or COLORS.DarkBG  or Color3.fromRGB(18,18,18)
    local ROW  = COLORS.Row     or COLORS.Frame    or Color3.fromRGB(26,26,26)
    local ACT  = COLORS.Active  or COLORS.Galaxy1  or Color3.fromRGB(220,220,220)
    local AFGG = COLORS.ActFg   or Color3.fromRGB(10,10,10)
    local TXT  = COLORS.Text    or COLORS.White    or Color3.fromRGB(210,210,210)
    local DIM  = COLORS.Dim     or Color3.fromRGB(110,110,110)
    local BRD  = COLORS.Border  or Color3.fromRGB(55,55,55)

    -- Track ALL script button frames so we can fully clear on refresh
    local allScriptFrames = {}

    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -4, 0, 16)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Loading..."
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 8
    statusLabel.TextColor3 = DIM
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = scriptsContent

    -- Refresh button
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(1, -4, 0, 26)
    refreshBtn.BackgroundColor3 = ROW
    refreshBtn.Text = "[ R ]  Refresh Scripts"
    refreshBtn.TextColor3 = TXT
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 9
    refreshBtn.TextXAlignment = Enum.TextXAlignment.Left
    refreshBtn.Parent = scriptsContent
    createCorner(refreshBtn, 6)

    local rPad = Instance.new("UIPadding", refreshBtn)
    rPad.PaddingLeft = UDim.new(0, 8)

    local function createScriptBtn(name, desc, scriptStr)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -4, 0, 54)
        frame.BackgroundColor3 = ROW
        frame.Parent = scriptsContent
        createCorner(frame, 8)
        table.insert(allScriptFrames, frame)

        local nl = Instance.new("TextLabel")
        nl.Size = UDim2.new(1, -8, 0, 20)
        nl.Position = UDim2.new(0, 8, 0, 4)
        nl.BackgroundTransparency = 1
        nl.Text = name
        nl.Font = Enum.Font.GothamBold
        nl.TextSize = 10
        nl.TextColor3 = TXT
        nl.TextXAlignment = Enum.TextXAlignment.Left
        nl.Parent = frame

        local dl = Instance.new("TextLabel")
        dl.Size = UDim2.new(1, -90, 0, 14)
        dl.Position = UDim2.new(0, 8, 0, 22)
        dl.BackgroundTransparency = 1
        dl.Text = desc
        dl.Font = Enum.Font.Gotham
        dl.TextSize = 8
        dl.TextColor3 = DIM
        dl.TextXAlignment = Enum.TextXAlignment.Left
        dl.Parent = frame

        local eb = Instance.new("TextButton")
        eb.Size = UDim2.new(0, 60, 0, 24)
        eb.Position = UDim2.new(1, -68, 0.5, -12)
        eb.BackgroundColor3 = ACT
        eb.Text = "LOAD"
        eb.TextColor3 = AFGG
        eb.Font = Enum.Font.GothamBold
        eb.TextSize = 9
        eb.Parent = frame
        createCorner(eb, 6)

        local capStr  = scriptStr
        local capName = name
        eb.MouseButton1Click:Connect(function()
            eb.Text = "..."
            task.spawn(function()
                pcall(function() loadstring(capStr)() end)
                task.wait(1)
                eb.Text = "LOAD"
            end)
            if Notif then Notif:Send("Loading: " .. capName, 2) end
        end)
    end

    local function clearAll()
        for _, f in ipairs(allScriptFrames) do
            if f and f.Parent then f:Destroy() end
        end
        allScriptFrames = {}
    end

    local function loadAll()
        clearAll()
        statusLabel.Text = "Loading..."

        -- Always add built-in first
        createScriptBtn(
            "Mois7 Loader",
            "External script loader",
            [[loadstring(game:HttpGet("https://mois7.xyz/loader"))()]]
        )

        -- Fetch scripts.json
        local ok, raw = pcall(function()
            return game:HttpGet(SCRIPTS_JSON_URL)
        end)

        if not ok or not raw or raw == "" then
            statusLabel.Text = "Could not load scripts.json"
            return
        end

        -- Parse JSON array: [{"name":"...","desc":"...","url":"..."}]
        local scripts = {}
        for entry in raw:gmatch("{(.-)%s*}") do
            local name = entry:match('"name"%s*:%s*"(.-)"')
            local desc = entry:match('"desc"%s*:%s*"(.-)"')
            local url  = entry:match('"url"%s*:%s*"(.-)"')
            if name and url then
                -- Skip if already in built-ins (e.g. Mois7 already added above)
                local isDuplicate = false
                for _, existing in ipairs(allScriptFrames) do
                    local nl = existing:FindFirstChildWhichIsA("TextLabel")
                    if nl and nl.Text == name then isDuplicate = true break end
                end
                if not isDuplicate then
                    table.insert(scripts, {name=name, desc=desc or "", url=url})
                end
            end
        end

        for _, s in ipairs(scripts) do
            createScriptBtn(
                s.name,
                s.desc,
                string.format([[loadstring(game:HttpGet(%q))()]], s.url)
            )
        end

        statusLabel.Text = #allScriptFrames .. " script(s) loaded"
        if Notif then Notif:Send(#allScriptFrames .. " script(s) loaded.", 3) end
    end

    refreshBtn.MouseButton1Click:Connect(loadAll)
    task.spawn(loadAll)
end

return Scripts
