-- esp.lua

local ESP = {}

local boxes       = {}
local beamTracers = {}
local skeletons   = {}
local healthBars  = {}  -- { text = Drawing "Text" }
local nameLabels  = {}  -- { display = Drawing "Text", username = Drawing "Text" }

local function createDrawing(drawType, props)
    local obj = Drawing.new(drawType)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

function ESP:Cleanup(plr)
    if boxes[plr]      then boxes[plr]:Remove();      boxes[plr] = nil end
    if nameLabels[plr] then
        if nameLabels[plr].display  then nameLabels[plr].display:Remove()  end
        if nameLabels[plr].username then nameLabels[plr].username:Remove() end
        nameLabels[plr] = nil
    end
    if healthBars[plr] then
        if healthBars[plr].text then healthBars[plr].text:Remove() end
        healthBars[plr] = nil
    end
    if skeletons[plr] then
        for _, l in pairs(skeletons[plr]) do l:Remove() end
        skeletons[plr] = nil
    end
    if beamTracers[plr] then beamTracers[plr]:Remove(); beamTracers[plr] = nil end
end

function ESP:Update(CONFIG, COLORS, rainbowHue)
    local player = game.Players.LocalPlayer
    local camera = workspace.CurrentCamera

    -- RGB fix: rainbowHue cycles 0→1, Color3.fromHSV gives full spectrum
    local function getRainbow()
        return Color3.fromHSV(rainbowHue % 1, 1, 1)
    end
    local function getESPColor()
        return CONFIG.BoxRainbow and getRainbow() or CONFIG.ESPColor
    end
    local function getSkelColor()
        return CONFIG.SkeletonRainbow and getRainbow() or CONFIG.SkeletonColor
    end
    local function getTracerColor()
        return CONFIG.TracerRainbow and getRainbow() or CONFIG.TracerColor
    end

    local function getPlayerColor(plr)
        if CONFIG.TeamFilter and player.Team and plr.Team and player.Team == plr.Team then
            return Color3.fromRGB(0, 255, 0)
        end
        return getESPColor()
    end

    local function shouldShow(plr)
        if plr == player then return false end
        if not CONFIG.TeamFilter then return true end
        if player.Team and plr.Team then return player.Team ~= plr.Team end
        return true
    end

    for _, plr in pairs(game.Players:GetPlayers()) do
        local char = plr.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChild("Humanoid")

        if not shouldShow(plr) or not hrp or not hum then
            if boxes[plr]      then boxes[plr].Visible = false end
            if nameLabels[plr] then
                nameLabels[plr].display.Visible  = false
                nameLabels[plr].username.Visible = false
            end
            if healthBars[plr] then
                healthBars[plr].text.Visible = false
            end
            if skeletons[plr] then
                for _, l in pairs(skeletons[plr]) do l:Remove() end
                skeletons[plr] = nil
            end
            if beamTracers[plr] then beamTracers[plr].Visible = false end
            continue
        end

        local rootPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        local dist = math.floor((camera.CFrame.Position - hrp.Position).Magnitude)
        local boxColor = getPlayerColor(plr)

        -- ── BOX ESP ───────────────────────────────────────────
        if CONFIG.BoxESP and onScreen then
            if not boxes[plr] then
                boxes[plr] = createDrawing("Square", {Thickness=1, Filled=false, Transparency=1})
            end
            local box  = boxes[plr]
            local size = (1000 / dist) * 2
            box.Size     = Vector2.new(size, size * 1.5)
            box.Position = Vector2.new(rootPos.X - box.Size.X/2, rootPos.Y - box.Size.Y/2)
            box.Color    = boxColor
            box.Visible  = true
        elseif boxes[plr] then boxes[plr]:Remove(); boxes[plr] = nil end

        -- Shared box reference for positioning
        local bSize = boxes[plr] and boxes[plr].Size     or Vector2.new(40, 60)
        local bPos  = boxes[plr] and boxes[plr].Position or Vector2.new(rootPos.X - 20, rootPos.Y - 30)
        local topY  = bPos.Y        -- top of box
        local botY  = bPos.Y + bSize.Y  -- bottom of box
        local cenX  = rootPos.X

        -- ── HEALTH BAR (text above box) ───────────────────────
        -- Format: "HP: 100 | 42 studs"
        if CONFIG.HealthBar and onScreen then
            if not healthBars[plr] then
                healthBars[plr] = {
                    text = createDrawing("Text", {
                        Size        = 11,
                        Center      = true,
                        Outline     = true,
                        Transparency = 1,
                        Color       = Color3.fromRGB(255, 255, 255),
                    })
                }
            end
            local hp     = math.floor(hum.Health)
            local maxHp  = math.floor(hum.MaxHealth)
            -- Color: green→yellow→red based on %
            local pct    = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local hpColor = Color3.fromHSV(pct * 0.33, 1, 1)

            local hbText = healthBars[plr].text
            hbText.Text     = "HP: " .. hp .. "/" .. maxHp .. " | " .. dist .. " studs"
            hbText.Position = Vector2.new(cenX, topY - 22)
            hbText.Color    = hpColor
            hbText.Visible  = true
        elseif healthBars[plr] then
            healthBars[plr].text:Remove()
            healthBars[plr] = nil
        end

        -- ── NAMES (compact, two lines) ────────────────────────
        -- Line 1: DisplayName  Line 2: @Username
        -- If HealthBar also on, shift names down a bit so they don't overlap
        if CONFIG.Names and onScreen then
            if not nameLabels[plr] then
                nameLabels[plr] = {
                    display  = createDrawing("Text", {Size=12, Center=true, Outline=true, Transparency=1, Color=Color3.fromRGB(255,255,255)}),
                    username = createDrawing("Text", {Size=10, Center=true, Outline=true, Transparency=1, Color=Color3.fromRGB(180,180,180)}),
                }
            end
            local nl   = nameLabels[plr]
            -- Position above box; if HP bar also showing, go a bit higher
            local baseY = topY - (CONFIG.HealthBar and 36 or 12)

            nl.display.Text     = plr.DisplayName
            nl.display.Position = Vector2.new(cenX, baseY - 14)
            nl.display.Visible  = true

            nl.username.Text     = "@" .. plr.Name
            nl.username.Position = Vector2.new(cenX, baseY)
            nl.username.Visible  = true
        elseif nameLabels[plr] then
            nameLabels[plr].display:Remove()
            nameLabels[plr].username:Remove()
            nameLabels[plr] = nil
        end

        -- ── TRACERS ───────────────────────────────────────────
        if CONFIG.Tracers and onScreen then
            if not beamTracers[plr] then
                beamTracers[plr] = createDrawing("Line", {Thickness=1, Transparency=1})
            end
            local tracer = beamTracers[plr]
            local vpSize = camera.ViewportSize
            tracer.From    = Vector2.new(vpSize.X/2, vpSize.Y)
            tracer.To      = Vector2.new(rootPos.X, rootPos.Y)
            tracer.Color   = getTracerColor()
            tracer.Visible = true
        elseif beamTracers[plr] then beamTracers[plr]:Remove(); beamTracers[plr] = nil end

        -- ── SKELETON ──────────────────────────────────────────
        if CONFIG.Skeleton and onScreen then
            local skeleton = skeletons[plr] or {}
            skeletons[plr] = skeleton
            local joints, connections = {}, {}

            if hum.RigType == Enum.HumanoidRigType.R15 then
                joints = {
                    Head=char:FindFirstChild("Head"),
                    UpperTorso=char:FindFirstChild("UpperTorso"),
                    LowerTorso=char:FindFirstChild("LowerTorso"),
                    LeftUpperArm=char:FindFirstChild("LeftUpperArm"),
                    LeftLowerArm=char:FindFirstChild("LeftLowerArm"),
                    LeftHand=char:FindFirstChild("LeftHand"),
                    RightUpperArm=char:FindFirstChild("RightUpperArm"),
                    RightLowerArm=char:FindFirstChild("RightLowerArm"),
                    RightHand=char:FindFirstChild("RightHand"),
                    LeftUpperLeg=char:FindFirstChild("LeftUpperLeg"),
                    LeftLowerLeg=char:FindFirstChild("LeftLowerLeg"),
                    RightUpperLeg=char:FindFirstChild("RightUpperLeg"),
                    RightLowerLeg=char:FindFirstChild("RightLowerLeg"),
                }
                connections = {
                    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
                    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},
                    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},
                    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
                    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
                }
            else
                joints = {
                    Head=char:FindFirstChild("Head"),
                    Torso=char:FindFirstChild("Torso"),
                    LeftArm=char:FindFirstChild("Left Arm"),
                    RightArm=char:FindFirstChild("Right Arm"),
                    LeftLeg=char:FindFirstChild("Left Leg"),
                    RightLeg=char:FindFirstChild("Right Leg"),
                }
                connections = {
                    {"Head","Torso"},{"Torso","LeftArm"},{"Torso","RightArm"},
                    {"Torso","LeftLeg"},{"Torso","RightLeg"},
                }
            end

            local skelColor = getSkelColor()
            for i, conn in ipairs(connections) do
                local partA, partB = joints[conn[1]], joints[conn[2]]
                if partA and partB then
                    local posA, osA = camera:WorldToViewportPoint(partA.Position)
                    local posB, osB = camera:WorldToViewportPoint(partB.Position)
                    local line = skeleton[i] or createDrawing("Line", {Thickness=2, Transparency=1})
                    skeleton[i] = line
                    line.Color = skelColor
                    if osA and osB then
                        line.From    = Vector2.new(posA.X, posA.Y)
                        line.To      = Vector2.new(posB.X, posB.Y)
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                elseif skeleton[i] then
                    skeleton[i].Visible = false
                end
            end
        elseif skeletons[plr] then
            for _, l in pairs(skeletons[plr]) do l:Remove() end
            skeletons[plr] = nil
        end
    end
end

return ESP
