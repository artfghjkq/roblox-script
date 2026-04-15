-- esp.lua
-- Player ESP + Entity ESP (Monster / Item classification)
-- All entity ESP shares one color per category, tracer+skeleton only within 200 studs

local ESP = {}

local Players = game:GetService("Players")

-- ── Drawing tables ────────────────────────────────────────────
-- Player (keyed by Player)
local plrDrawings = {}  -- [plr] = {box, hpText, nameText, userText, tagText, tracer, skel={}}

-- Entity (keyed by Model)
local entDrawings = {}  -- [model] = {box, hpText, nameText, tagText, tracer, skel={}}

-- Known entities cache
local knownEntities  = {}  -- [model] = "monster" | "item"
local entityScanTick = 0
local SCAN_INTERVAL  = 180  -- frames (~3s at 60fps)

-- Distance limits
local MAX_DIST_ALL    = 500   -- hide everything beyond this
local MAX_DIST_SKEL   = 200   -- skeleton+tracer only within this

-- ── Helpers ───────────────────────────────────────────────────
local function cd(drawType, props)
    local obj = Drawing.new(drawType)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

local function hideAll(t)
    if not t then return end
    if t.box      then t.box.Visible      = false end
    if t.hpText   then t.hpText.Visible   = false end
    if t.nameText then t.nameText.Visible = false end
    if t.userText then t.userText.Visible = false end
    if t.tagText  then t.tagText.Visible  = false end
    if t.tracer   then t.tracer.Visible   = false end
    if t.skel     then for _, l in pairs(t.skel) do l.Visible = false end end
end

local function removeAll(t)
    if not t then return end
    if t.box      then t.box:Remove()      end
    if t.hpText   then t.hpText:Remove()   end
    if t.nameText then t.nameText:Remove() end
    if t.userText then t.userText:Remove() end
    if t.tagText  then t.tagText:Remove()  end
    if t.tracer   then t.tracer:Remove()   end
    if t.skel     then for _, l in pairs(t.skel) do l:Remove() end end
end

-- ── Classification ─────────────────────────────────────────────
-- Keywords for monsters/enemies
local MONSTER_KEYWORDS = {
    "zombie","monster","enemy","mob","boss","creature","ghost","demon","npc",
    "alien","spider","wolf","bear","bandit","pirate","robot","mutant","horror",
    "undead","vampire","witch","skeleton","grunt","guard","soldier","evil",
}
-- Keywords for items/objects
local ITEM_KEYWORDS = {
    "chest","crate","barrel","box","item","pickup","loot","drop","treasure",
    "weapon","sword","gun","potion","coin","gem","ore","crystal","artifact",
    "door","button","lever","switch","prop","object","part",
}

local function classifyModel(model)
    local nameLower = model.Name:lower()
    for _, kw in ipairs(MONSTER_KEYWORDS) do
        if nameLower:find(kw) then return "monster" end
    end
    for _, kw in ipairs(ITEM_KEYWORDS) do
        if nameLower:find(kw) then return "item" end
    end
    -- Fallback: has Humanoid = monster/npc, no Humanoid = item
    local hum = model:FindFirstChildWhichIsA("Humanoid")
    return hum and "monster" or "item"
end

local function getEntityColor(CONFIG, category)
    if category == "monster" then
        return CONFIG.NPCMonsterColor or Color3.fromRGB(220, 50, 50)
    else
        return CONFIG.NPCItemColor or Color3.fromRGB(255, 165, 0)
    end
end

local function getTagLabel(category)
    return category == "monster" and "[MONSTER]" or "[ITEM]"
end

-- ── Entity Scanner ─────────────────────────────────────────────
local function scanEntities()
    local playerChars = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then playerChars[p.Character] = true end
    end

    -- Prune stale
    for model in pairs(knownEntities) do
        if not model or not model.Parent then
            removeAll(entDrawings[model])
            entDrawings[model]  = nil
            knownEntities[model] = nil
        end
    end

    -- Scan workspace for Models with HRP/Torso
    for _, obj in pairs(workspace:GetDescendants()) do
        if (obj:IsA("Humanoid") or obj:IsA("BasePart")) and obj.Name == "HumanoidRootPart" or
           (obj:IsA("BasePart") and (obj.Name == "Torso" or obj.Name == "HRP")) then
            local model = obj.Parent
            if model and model:IsA("Model") and not playerChars[model] and not knownEntities[model] then
                knownEntities[model] = classifyModel(model)
            end
        end
    end
end

-- ── Skeleton drawer ────────────────────────────────────────────
local function drawSkeleton(model, hum, skel, color, camera)
    local joints, connections = {}, {}
    local isR15 = hum and hum.RigType == Enum.HumanoidRigType.R15

    if isR15 then
        joints = {
            Head=model:FindFirstChild("Head"), UpperTorso=model:FindFirstChild("UpperTorso"),
            LowerTorso=model:FindFirstChild("LowerTorso"),
            LeftUpperArm=model:FindFirstChild("LeftUpperArm"), LeftLowerArm=model:FindFirstChild("LeftLowerArm"), LeftHand=model:FindFirstChild("LeftHand"),
            RightUpperArm=model:FindFirstChild("RightUpperArm"), RightLowerArm=model:FindFirstChild("RightLowerArm"), RightHand=model:FindFirstChild("RightHand"),
            LeftUpperLeg=model:FindFirstChild("LeftUpperLeg"), LeftLowerLeg=model:FindFirstChild("LeftLowerLeg"),
            RightUpperLeg=model:FindFirstChild("RightUpperLeg"), RightLowerLeg=model:FindFirstChild("RightLowerLeg"),
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
            Head=model:FindFirstChild("Head"), Torso=model:FindFirstChild("Torso"),
            LeftArm=model:FindFirstChild("Left Arm"), RightArm=model:FindFirstChild("Right Arm"),
            LeftLeg=model:FindFirstChild("Left Leg"), RightLeg=model:FindFirstChild("Right Leg"),
        }
        connections = {
            {"Head","Torso"},{"Torso","LeftArm"},{"Torso","RightArm"},
            {"Torso","LeftLeg"},{"Torso","RightLeg"},
        }
    end

    for i, conn in ipairs(connections) do
        local pA, pB = joints[conn[1]], joints[conn[2]]
        if pA and pB then
            local posA, osA = camera:WorldToViewportPoint(pA.Position)
            local posB, osB = camera:WorldToViewportPoint(pB.Position)
            local line = skel[i] or cd("Line", {Thickness=2, Transparency=1})
            skel[i]    = line
            line.Color = color
            if osA and osB then
                line.From = Vector2.new(posA.X, posA.Y)
                line.To   = Vector2.new(posB.X, posB.Y)
                line.Visible = true
            else line.Visible = false end
        elseif skel[i] then skel[i].Visible = false end
    end
end

-- ── Player Cleanup (public) ────────────────────────────────────
function ESP:Cleanup(plr)
    removeAll(plrDrawings[plr])
    plrDrawings[plr] = nil
end

function ESP:RescanNPCs()
    for model in pairs(knownEntities) do
        removeAll(entDrawings[model])
        entDrawings[model] = nil
    end
    knownEntities = {}
    scanEntities()
end

-- ══════════════════════════════════════════════════════════════
-- MAIN UPDATE
-- ══════════════════════════════════════════════════════════════
function ESP:Update(CONFIG, COLORS, rainbowHue)
    local player = Players.LocalPlayer
    local camera = workspace.CurrentCamera

    local function getRainbow()     return Color3.fromHSV(rainbowHue % 1, 1, 1) end
    local function getBoxColor()    return CONFIG.BoxRainbow      and getRainbow() or CONFIG.ESPColor end
    local function getSkelColor()   return CONFIG.SkeletonRainbow and getRainbow() or CONFIG.SkeletonColor end
    local function getTracerColor() return CONFIG.TracerRainbow   and getRainbow() or CONFIG.TracerColor end

    local function playerBoxColor(plr)
        if CONFIG.TeamFilter and player.Team and plr.Team and player.Team == plr.Team then
            return Color3.fromRGB(0, 255, 0)
        end
        return getBoxColor()
    end

    local function shouldShowPlayer(plr)
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
        local d    = plrDrawings[plr]

        if not shouldShowPlayer(plr) or not hrp or not hum then
            hideAll(d); continue
        end

        local rootPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        local dist = math.floor((camera.CFrame.Position - hrp.Position).Magnitude)

        -- Distance limit
        if dist > MAX_DIST_ALL or not onScreen then
            hideAll(d); continue
        end

        -- Init drawings
        if not d then
            d = {
                box      = cd("Square", {Thickness=1, Filled=false, Transparency=1}),
                tagText  = cd("Text",   {Size=10, Center=true, Outline=true, Transparency=1, Color=Color3.fromRGB(0,220,255)}),
                hpText   = cd("Text",   {Size=10, Center=true, Outline=true, Transparency=1}),
                nameText = cd("Text",   {Size=12, Center=true, Outline=true, Transparency=1, Color=Color3.fromRGB(255,255,255)}),
                userText = cd("Text",   {Size=10, Center=true, Outline=true, Transparency=1, Color=Color3.fromRGB(180,180,180)}),
                tracer   = cd("Line",   {Thickness=1, Transparency=1}),
                skel     = {},
            }
            plrDrawings[plr] = d
        end

        local bColor = playerBoxColor(plr)
        local size   = math.clamp((1000 / math.max(dist,1)) * 2, 10, 600)
        local bW, bH = size, size * 1.5
        local bX     = rootPos.X - bW/2
        local bY     = rootPos.Y - bH/2
        local topY   = bY
        local cenX   = rootPos.X

        -- Box
        if CONFIG.BoxESP then
            d.box.Size     = Vector2.new(bW, bH)
            d.box.Position = Vector2.new(bX, bY)
            d.box.Color    = bColor
            d.box.Visible  = true
        else d.box.Visible = false end

        -- Player Info (tag + hp + names)
        if CONFIG.PlayerInfo then
            local pct = math.clamp(hum.Health / math.max(hum.MaxHealth,1), 0, 1)

            d.tagText.Text     = "[PLAYER]"
            d.tagText.Color    = Color3.fromRGB(0, 220, 255)
            d.tagText.Position = Vector2.new(cenX, topY - 50)
            d.tagText.Visible  = true

            d.hpText.Text     = "HP: "..math.floor(hum.Health).."/"..math.floor(hum.MaxHealth).." | "..dist.." studs"
            d.hpText.Color    = Color3.fromHSV(pct * 0.33, 1, 1)
            d.hpText.Position = Vector2.new(cenX, topY - 38)
            d.hpText.Visible  = true

            d.nameText.Text     = plr.DisplayName
            d.nameText.Position = Vector2.new(cenX, topY - 26)
            d.nameText.Visible  = true

            d.userText.Text     = "(@"..plr.Name..")"
            d.userText.Position = Vector2.new(cenX, topY - 14)
            d.userText.Visible  = true
        else
            d.tagText.Visible  = false
            d.hpText.Visible   = false
            d.nameText.Visible = false
            d.userText.Visible = false
        end

        -- Tracer (only within 200 studs, only if PlayerInfo on)
        if CONFIG.PlayerInfo and dist <= MAX_DIST_SKEL then
            local vpSize = camera.ViewportSize
            d.tracer.From    = Vector2.new(vpSize.X/2, vpSize.Y)
            d.tracer.To      = Vector2.new(cenX, rootPos.Y)
            d.tracer.Color   = getTracerColor()
            d.tracer.Visible = true
        else d.tracer.Visible = false end

        -- Skeleton (only within 200 studs, only if PlayerInfo on)
        if CONFIG.PlayerInfo and dist <= MAX_DIST_SKEL then
            drawSkeleton(char, hum, d.skel, getSkelColor(), camera)
        else
            if d.skel then for _, l in pairs(d.skel) do l.Visible = false end end
        end
    end

    -- ══════════════════════════════════════════════════════════
    -- ENTITY ESP (Monster + Item)
    -- ══════════════════════════════════════════════════════════
    local anyEntityEnabled = CONFIG.NPCBoxESP or CONFIG.NPCMonster or CONFIG.NPCItem

    if not anyEntityEnabled then
        for model in pairs(knownEntities) do
            hideAll(entDrawings[model])
        end
        return
    end

    -- Periodic rescan
    entityScanTick = entityScanTick + 1
    if entityScanTick >= SCAN_INTERVAL then
        entityScanTick = 0
        scanEntities()
    end
    if not next(knownEntities) then scanEntities() end

    for model, category in pairs(knownEntities) do
        if not model or not model.Parent then
            removeAll(entDrawings[model])
            entDrawings[model]   = nil
            knownEntities[model] = nil
            continue
        end

        -- Category filter
        local showThis = false
        if category == "monster" and CONFIG.NPCMonster then showThis = true end
        if category == "item"    and CONFIG.NPCItem    then showThis = true end
        -- Box ESP shows all if NPCBoxESP on
        local showBox = CONFIG.NPCBoxESP

        if not showThis and not showBox then
            hideAll(entDrawings[model]); continue
        end

        local hrp = model:FindFirstChild("HumanoidRootPart")
               or  model:FindFirstChild("Torso")
               or  model:FindFirstChild("HRP")
        if not hrp then hideAll(entDrawings[model]); continue end

        local hum     = model:FindFirstChildWhichIsA("Humanoid")
        local rootPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        local dist    = math.floor((camera.CFrame.Position - hrp.Position).Magnitude)

        if dist > MAX_DIST_ALL or not onScreen then
            hideAll(entDrawings[model]); continue
        end

        local eColor = getEntityColor(CONFIG, category)
        local d      = entDrawings[model]

        if not d then
            d = {
                box      = cd("Square", {Thickness=1, Filled=false, Transparency=1}),
                tagText  = cd("Text",   {Size=10, Center=true, Outline=true, Transparency=1}),
                hpText   = cd("Text",   {Size=10, Center=true, Outline=true, Transparency=1}),
                nameText = cd("Text",   {Size=11, Center=true, Outline=true, Transparency=1}),
                tracer   = cd("Line",   {Thickness=1, Transparency=1}),
                skel     = {},
            }
            entDrawings[model] = d
        end

        local size = math.clamp((1000 / math.max(dist,1)) * 2, 10, 600)
        local bW, bH = size, size * 1.5
        local bX  = rootPos.X - bW/2
        local bY  = rootPos.Y - bH/2
        local topY = bY
        local cenX = rootPos.X

        -- Box
        if showBox then
            d.box.Size     = Vector2.new(bW, bH)
            d.box.Position = Vector2.new(bX, bY)
            d.box.Color    = eColor
            d.box.Visible  = true
        else d.box.Visible = false end

        -- Info (tag + hp + name)
        if showThis then
            local tagLabel = getTagLabel(category)
            d.tagText.Text     = tagLabel
            d.tagText.Color    = eColor
            d.tagText.Position = Vector2.new(cenX, topY - 38)
            d.tagText.Visible  = true

            if hum then
                local pct = math.clamp(hum.Health / math.max(hum.MaxHealth,1), 0, 1)
                d.hpText.Text  = "HP: "..math.floor(hum.Health).."/"..math.floor(hum.MaxHealth).." | "..dist.." studs"
                d.hpText.Color = Color3.fromHSV(pct * 0.33, 1, 1)
            else
                d.hpText.Text  = dist.." studs"
                d.hpText.Color = eColor
            end
            d.hpText.Position  = Vector2.new(cenX, topY - 26)
            d.hpText.Visible   = true

            d.nameText.Text     = model.Name
            d.nameText.Color    = eColor
            d.nameText.Position = Vector2.new(cenX, topY - 14)
            d.nameText.Visible  = true

            -- Tracer (within 200 studs)
            if dist <= MAX_DIST_SKEL then
                local vpSize = camera.ViewportSize
                d.tracer.From    = Vector2.new(vpSize.X/2, vpSize.Y)
                d.tracer.To      = Vector2.new(cenX, rootPos.Y)
                d.tracer.Color   = eColor
                d.tracer.Visible = true
            else d.tracer.Visible = false end

            -- Skeleton (within 200 studs, only if has humanoid)
            if dist <= MAX_DIST_SKEL and hum then
                drawSkeleton(model, hum, d.skel, eColor, camera)
            else
                if d.skel then for _, l in pairs(d.skel) do l.Visible = false end end
            end
        else
            d.tagText.Visible  = false
            d.hpText.Visible   = false
            d.nameText.Visible = false
            d.tracer.Visible   = false
            if d.skel then for _, l in pairs(d.skel) do l.Visible = false end end
        end
    end
end

return ESP
