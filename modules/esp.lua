-- esp.lua
-- Player ESP + NPC/Monster/Enemy ESP

local ESP = {}

local Players = game:GetService("Players")

-- Player ESP tables (keyed by Player object)
local boxes       = {}
local beamTracers = {}
local skeletons   = {}
local healthBars  = {}
local nameLabels  = {}

-- NPC ESP tables (keyed by Model object)
local npcBoxes  = {}
local npcNames  = {}
local npcHBars  = {}

-- Track known NPCs so we don't re-scan every frame
local knownNPCs   = {}
local npcScanTick = 0
local NPC_SCAN_INTERVAL = 3  -- re-scan workspace every 3 seconds

local function createDrawing(drawType, props)
    local obj = Drawing.new(drawType)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

-- ── Player Cleanup ────────────────────────────────────────────
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

-- ── NPC Cleanup ───────────────────────────────────────────────
local function cleanupNPC(model)
    if npcBoxes[model]  then npcBoxes[model]:Remove();  npcBoxes[model]  = nil end
    if npcNames[model]  then
        if npcNames[model].line1 then npcNames[model].line1:Remove() end
        if npcNames[model].line2 then npcNames[model].line2:Remove() end
        npcNames[model] = nil
    end
    if npcHBars[model]  then npcHBars[model]:Remove();  npcHBars[model]  = nil end
end

local function cleanupAllNPCs()
    for model in pairs(knownNPCs) do cleanupNPC(model) end
    knownNPCs = {}
end

-- ── NPC Scanner ───────────────────────────────────────────────
local function scanNPCs()
    local playerChars = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then playerChars[p.Character] = true end
    end

    -- Remove stale NPCs
    for model in pairs(knownNPCs) do
        if not model or not model.Parent then
            cleanupNPC(model)
            knownNPCs[model] = nil
        end
    end

    -- Find new NPCs
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") then
            local model = obj.Parent
            if model and model:IsA("Model") and not playerChars[model] then
                local hrp = model:FindFirstChild("HumanoidRootPart")
                    or model:FindFirstChild("Torso")
                    or model:FindFirstChild("HRP")
                if hrp then
                    knownNPCs[model] = true
                end
            end
        end
    end
end

-- ── Main Update ───────────────────────────────────────────────
function ESP:Update(CONFIG, COLORS, rainbowHue)
    local player = Players.LocalPlayer
    local camera = workspace.CurrentCamera

    local function getRainbow()   return Color3.fromHSV(rainbowHue % 1, 1, 1) end
    local function getESPColor()  return CONFIG.BoxRainbow     and getRainbow() or CONFIG.ESPColor end
    local function getSkelColor() return CONFIG.SkeletonRainbow and getRainbow() or CONFIG.SkeletonColor end
    local function getTracerColor() return CONFIG.TracerRainbow and getRainbow() or CONFIG.TracerColor end

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

    -- ══════════════════════════════════════════════════════════
    -- PLAYER ESP
    -- ══════════════════════════════════════════════════════════
    for _, plr in pairs(Players:GetPlayers()) do
        local char = plr.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChild("Humanoid")

        if not shouldShow(plr) or not hrp or not hum then
            if boxes[plr]      then boxes[plr].Visible = false end
            if nameLabels[plr] then
                nameLabels[plr].display.Visible  = false
                nameLabels[plr].username.Visible = false
            end
            if healthBars[plr] then healthBars[plr].text.Visible = false end
            if skeletons[plr]  then
                for _, l in pairs(skeletons[plr]) do l:Remove() end
                skeletons[plr] = nil
            end
            if beamTracers[plr] then beamTracers[plr].Visible = false end
            continue
        end

        local rootPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        local dist     = math.floor((camera.CFrame.Position - hrp.Position).Magnitude)
        local boxColor = getPlayerColor(plr)

        -- Box
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

        local bSize = boxes[plr] and boxes[plr].Size     or Vector2.new(40, 60)
        local bPos  = boxes[plr] and boxes[plr].Position or Vector2.new(rootPos.X-20, rootPos.Y-30)
        local topY  = bPos.Y
        local cenX  = rootPos.X

        -- Player Info (HP + Names together)
        if CONFIG.PlayerInfo and onScreen then
            -- Health bar text
            if not healthBars[plr] then
                healthBars[plr] = {
                    text = createDrawing("Text", {Size=10, Center=true, Outline=true, Transparency=1})
                }
            end
            local pct    = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            local hbText = healthBars[plr].text
            hbText.Text     = "HP: "..math.floor(hum.Health).."/"..math.floor(hum.MaxHealth).." | "..dist.." studs"
            hbText.Position = Vector2.new(cenX, topY - 38)
            hbText.Color    = Color3.fromHSV(pct * 0.33, 1, 1)
            hbText.Visible  = true

            -- Name labels
            if not nameLabels[plr] then
                nameLabels[plr] = {
                    display  = createDrawing("Text", {Size=12, Center=true, Outline=true, Transparency=1, Color=Color3.fromRGB(255,255,255)}),
                    username = createDrawing("Text", {Size=10, Center=true, Outline=true, Transparency=1, Color=Color3.fromRGB(180,180,180)}),
                }
            end
            local nl = nameLabels[plr]
            nl.display.Text      = plr.DisplayName
            nl.display.Position  = Vector2.new(cenX, topY - 26)
            nl.display.Visible   = true
            nl.username.Text     = "@"..plr.Name
            nl.username.Position = Vector2.new(cenX, topY - 14)
            nl.username.Visible  = true
        else
            if healthBars[plr] then healthBars[plr].text:Remove(); healthBars[plr] = nil end
            if nameLabels[plr] then
                nameLabels[plr].display:Remove()
                nameLabels[plr].username:Remove()
                nameLabels[plr] = nil
            end
        end

        -- Tracers
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

        -- Skeleton
        if CONFIG.Skeleton and onScreen then
            local skeleton = skeletons[plr] or {}
            skeletons[plr] = skeleton
            local joints, connections = {}, {}

            if hum.RigType == Enum.HumanoidRigType.R15 then
                joints = {
                    Head=char:FindFirstChild("Head"), UpperTorso=char:FindFirstChild("UpperTorso"),
                    LowerTorso=char:FindFirstChild("LowerTorso"),
                    LeftUpperArm=char:FindFirstChild("LeftUpperArm"), LeftLowerArm=char:FindFirstChild("LeftLowerArm"), LeftHand=char:FindFirstChild("LeftHand"),
                    RightUpperArm=char:FindFirstChild("RightUpperArm"), RightLowerArm=char:FindFirstChild("RightLowerArm"), RightHand=char:FindFirstChild("RightHand"),
                    LeftUpperLeg=char:FindFirstChild("LeftUpperLeg"), LeftLowerLeg=char:FindFirstChild("LeftLowerLeg"),
                    RightUpperLeg=char:FindFirstChild("RightUpperLeg"), RightLowerLeg=char:FindFirstChild("RightLowerLeg"),
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
                    Head=char:FindFirstChild("Head"), Torso=char:FindFirstChild("Torso"),
                    LeftArm=char:FindFirstChild("Left Arm"), RightArm=char:FindFirstChild("Right Arm"),
                    LeftLeg=char:FindFirstChild("Left Leg"), RightLeg=char:FindFirstChild("Right Leg"),
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
                        line.From = Vector2.new(posA.X, posA.Y)
                        line.To   = Vector2.new(posB.X, posB.Y)
                        line.Visible = true
                    else line.Visible = false end
                elseif skeleton[i] then skeleton[i].Visible = false end
            end
        elseif skeletons[plr] then
            for _, l in pairs(skeletons[plr]) do l:Remove() end
            skeletons[plr] = nil
        end
    end

    -- ══════════════════════════════════════════════════════════
    -- NPC / MONSTER / ENEMY ESP
    -- ══════════════════════════════════════════════════════════
    local anyNPCEnabled = CONFIG.NPCBoxESP or CONFIG.NPCInfo or CONFIG.NPCInfo

    -- Periodic workspace scan
    if anyNPCEnabled then
        npcScanTick = npcScanTick + 1
        if npcScanTick >= (NPC_SCAN_INTERVAL * 60) then
            npcScanTick = 0
            scanNPCs()
        end
        -- First time
        if not next(knownNPCs) then scanNPCs() end
    else
        -- All NPC ESP off — cleanup everything
        if next(npcBoxes) or next(npcNames) or next(npcHBars) then
            cleanupAllNPCs()
        end
        return
    end

    local npcColor = CONFIG.NPCColor or Color3.fromRGB(255, 100, 0)

    for model in pairs(knownNPCs) do
        -- Validate model still exists
        if not model or not model.Parent then
            cleanupNPC(model)
            knownNPCs[model] = nil
            continue
        end

        local hrp = model:FindFirstChild("HumanoidRootPart")
               or model:FindFirstChild("Torso")
               or model:FindFirstChild("HRP")
        local hum = model:FindFirstChildWhichIsA("Humanoid")

        if not hrp then
            -- Hide all drawings for this NPC
            if npcBoxes[model] then npcBoxes[model].Visible = false end
            if npcNames[model] then
                if npcNames[model].line1 then npcNames[model].line1.Visible = false end
                if npcNames[model].line2 then npcNames[model].line2.Visible = false end
            end
            if npcHBars[model] then npcHBars[model].Visible = false end
            continue
        end

        local rootPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        local dist = math.floor((camera.CFrame.Position - hrp.Position).Magnitude)

        -- NPC Box
        if CONFIG.NPCBoxESP and onScreen then
            if not npcBoxes[model] then
                npcBoxes[model] = createDrawing("Square", {Thickness=1, Filled=false, Transparency=1})
            end
            local box  = npcBoxes[model]
            local size = math.clamp((1000 / math.max(dist, 1)) * 2, 10, 600)
            box.Size     = Vector2.new(size, size * 1.5)
            box.Position = Vector2.new(rootPos.X - box.Size.X/2, rootPos.Y - box.Size.Y/2)
            box.Color    = npcColor
            box.Visible  = true
        elseif npcBoxes[model] then
            npcBoxes[model].Visible = false
        end

        local bSize = npcBoxes[model] and npcBoxes[model].Size     or Vector2.new(40, 60)
        local bPos  = npcBoxes[model] and npcBoxes[model].Position or Vector2.new(rootPos.X-20, rootPos.Y-30)
        local topY  = bPos.Y
        local cenX  = rootPos.X

        -- NPC Info (HP + Name together)
        if CONFIG.NPCInfo and onScreen then
            -- HP text
            if not npcHBars[model] then
                npcHBars[model] = createDrawing("Text", {Size=10, Center=true, Outline=true, Transparency=1})
            end
            local hbText = npcHBars[model]
            if hum then
                local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                hbText.Text  = "HP: "..math.floor(hum.Health).."/"..math.floor(hum.MaxHealth).." | "..dist.." studs"
                hbText.Color = Color3.fromHSV(pct * 0.33, 1, 1)
            else
                hbText.Text  = dist.." studs"
                hbText.Color = npcColor
            end
            hbText.Position = Vector2.new(cenX, topY - 36)
            hbText.Visible  = true

            -- Name
            if not npcNames[model] then
                npcNames[model] = {
                    line1 = createDrawing("Text", {Size=11, Center=true, Outline=true, Transparency=1, Color=npcColor}),
                    line2 = createDrawing("Text", {Size=9,  Center=true, Outline=true, Transparency=1, Color=Color3.fromRGB(200,150,100)}),
                }
            end
            local nn = npcNames[model]
            nn.line1.Text     = model.Name
            nn.line1.Position = Vector2.new(cenX, topY - 24)
            nn.line1.Visible  = true
            nn.line2.Text     = "[NPC] "..dist.." studs"
            nn.line2.Position = Vector2.new(cenX, topY - 13)
            nn.line2.Visible  = true
        else
            if npcHBars[model] then npcHBars[model].Visible = false end
            if npcNames[model] then
                npcNames[model].line1.Visible = false
                npcNames[model].line2.Visible = false
            end
        end
    end
end

-- Force rescan (call this when NPC ESP toggled on)
function ESP:RescanNPCs()
    cleanupAllNPCs()
    scanNPCs()
end

return ESP
