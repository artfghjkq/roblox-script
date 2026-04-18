-- esp.lua
-- Player ESP + Entity ESP (Monster / Item) + Aimbot

local ESP = {}

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ── Drawing tables ────────────────────────────────────────────
local plrDrawings = {}  -- [plr]   = {box, tagText, hpText, nameText, userText, tracer, skel={}}
local entDrawings = {}  -- [model] = {box, tagText, hpText, nameText, tracer, skel={}}

local knownEntities  = {}
local entityScanTick = 0
local SCAN_INTERVAL  = 180   -- ~3s at 60fps
local MAX_DIST_ALL   = 500   -- hide beyond this
local MAX_DIST_SKEL  = 200   -- tracer+skeleton only within this

-- ── Aimbot state ──────────────────────────────────────────────
local aimbotActive  = false
local aimbotConn    = nil

-- ── Helpers ───────────────────────────────────────────────────
local function cd(t, p)
    local o = Drawing.new(t)
    for k,v in pairs(p) do o[k]=v end
    return o
end

local function hideAll(d)
    if not d then return end
    for _, k in ipairs({"box","tagText","hpText","nameText","userText","tracer"}) do
        if d[k] then d[k].Visible = false end
    end
    if d.skel then for _, l in pairs(d.skel) do l.Visible = false end end
end

local function removeAll(d)
    if not d then return end
    for _, k in ipairs({"box","tagText","hpText","nameText","userText","tracer"}) do
        if d[k] then d[k]:Remove() end
    end
    if d.skel then for _, l in pairs(d.skel) do l:Remove() end end
end

-- ── Classification ─────────────────────────────────────────────
-- NPC/friendly keywords — these are NOT monsters even if they have a Humanoid
local FRIENDLY_KW = {
    "npc","civilian","villager","townsfolk","merchant","shopkeeper","vendor","trader",
    "quest","guide","helper","friendly","ally","companion","pet","tamer",
    "mayor","king","queen","prince","princess","knight","hero","saint",
    "child","baby","elder","old","sage","farmer","blacksmith","innkeeper",
    "doctor","nurse","priest","monk","wizard","mage",
}

-- MONSTER/ENEMY keywords — hostile, attacks player
local MONSTER_KW = {
    -- Undead
    "zombie","ghoul","revenant","lich","mummy","wight","draugr","risen",
    -- Supernatural
    "ghost","demon","devil","spirit","shade","phantom","banshee","poltergeist",
    "vampire","werewolf","witch","cultist","abomination","cursed","haunted",
    -- Creatures
    "creature","beast","mutant","alien","parasite","infected","horror",
    "spider","wolf","bear","lion","tiger","shark","snake","rat","bat",
    "hawk","crow","golem","slime","blob","worm","insect","bug","wasp","scorpion",
    -- Fantasy
    "goblin","orc","troll","ogre","dragon","hydra","wyvern","titan","giant",
    "fiend","imp","brute","juggernaut","colossus",
    -- Human enemies
    "bandit","pirate","raider","rogue","outlaw","thug","gangster",
    "soldier","guard","mercenary","grunt","militia","rebel",
    "enemy","hostile","attacker","aggressor","predator",
    -- Sci-fi
    "robot","android","drone","turret","mech","cyborg","sentinel",
    -- Game terms
    "boss","minion","stalker","hunter","crawler","jumper","runner","charger",
    "pursuer","zombie","monster","mob",
}

-- ITEM keywords — collectibles, containers, objects
local ITEM_KW = {
    -- Weapons as items (not humanoid)
    "gun","rifle","pistol","shotgun","sniper","smg","weapon","ammo","bullet",
    "magazine","clip","grenade","explosive","mine",
    "knife","sword","blade","axe","bow","crossbow","spear",
    -- Food & medical
    "food","water","drink","meal","ration","snack","fruit","meat","bread","can",
    "medkit","bandage","heal","aid","potion","elixir","antidote","pill","syringe",
    -- Containers / loot
    "crate","chest","box","barrel","bag","backpack","case","container",
    "loot","drop","pickup","package","airdrop","supply","cache","stash","locker",
    -- Resources
    "ore","wood","stone","metal","iron","steel","crystal","gem","diamond",
    "coin","gold","cash","money","credit","token","chip","key","fuel","battery",
    "scrap","material","resource","artifact","relic",
    -- Buildings / interactables
    "shop","store","vendor","market","door","button","lever","switch",
    "terminal","computer","console","machine","device","tool","equipment",
    "vault","safe","prop","object","item","pickup","collectible","trophy",
}

local function classifyModel(model)
    local n = model.Name:lower()

    -- 1. Check friendly/NPC first — skip as monster
    for _, kw in ipairs(FRIENDLY_KW) do
        if n:find(kw, 1, true) then return "item" end -- treat as non-threat = item category
    end

    -- 2. Check monster keywords
    for _, kw in ipairs(MONSTER_KW) do
        if n:find(kw, 1, true) then return "monster" end
    end

    -- 3. Check item keywords
    for _, kw in ipairs(ITEM_KW) do
        if n:find(kw, 1, true) then return "item" end
    end

    -- 4. Fallback: Humanoid = monster (living unknown entity), else = item
    local hum = model:FindFirstChildWhichIsA("Humanoid")
    return hum and "monster" or "item"
end

local function entityColor(CONFIG, cat)
    return cat == "monster"
        and (CONFIG.NPCMonsterColor or Color3.fromRGB(220,50,50))
        or  (CONFIG.NPCItemColor    or Color3.fromRGB(255,165,0))
end

local function tagLabel(cat)
    return cat == "monster" and "[MONSTER]" or "[ITEM]"
end

-- ── Scanner ───────────────────────────────────────────────────
local function scanEntities()
    local chars = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then chars[p.Character] = true end
    end
    for model in pairs(knownEntities) do
        if not model or not model.Parent then
            removeAll(entDrawings[model])
            entDrawings[model]   = nil
            knownEntities[model] = nil
        end
    end
    for _, obj in pairs(workspace:GetDescendants()) do
        local isHRP = obj:IsA("BasePart") and
            (obj.Name == "HumanoidRootPart" or obj.Name == "Torso" or obj.Name == "HRP")
        local isHum = obj:IsA("Humanoid")
        if (isHRP or isHum) then
            local model = obj.Parent
            if model and model:IsA("Model") and not chars[model] and not knownEntities[model] then
                knownEntities[model] = classifyModel(model)
            end
        end
    end
end

-- ── Skeleton ──────────────────────────────────────────────────
local function drawSkel(container, hum, skel, color, camera)
    local joints, conns = {}, {}
    local isR15 = hum and hum.RigType == Enum.HumanoidRigType.R15
    if isR15 then
        joints = {
            Head=container:FindFirstChild("Head"), UpperTorso=container:FindFirstChild("UpperTorso"),
            LowerTorso=container:FindFirstChild("LowerTorso"),
            LeftUpperArm=container:FindFirstChild("LeftUpperArm"), LeftLowerArm=container:FindFirstChild("LeftLowerArm"), LeftHand=container:FindFirstChild("LeftHand"),
            RightUpperArm=container:FindFirstChild("RightUpperArm"), RightLowerArm=container:FindFirstChild("RightLowerArm"), RightHand=container:FindFirstChild("RightHand"),
            LeftUpperLeg=container:FindFirstChild("LeftUpperLeg"), LeftLowerLeg=container:FindFirstChild("LeftLowerLeg"),
            RightUpperLeg=container:FindFirstChild("RightUpperLeg"), RightLowerLeg=container:FindFirstChild("RightLowerLeg"),
        }
        conns = {
            {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
            {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},
            {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},
            {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
            {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
        }
    else
        joints = {
            Head=container:FindFirstChild("Head"), Torso=container:FindFirstChild("Torso"),
            LeftArm=container:FindFirstChild("Left Arm"), RightArm=container:FindFirstChild("Right Arm"),
            LeftLeg=container:FindFirstChild("Left Leg"), RightLeg=container:FindFirstChild("Right Leg"),
        }
        conns = {
            {"Head","Torso"},{"Torso","LeftArm"},{"Torso","RightArm"},
            {"Torso","LeftLeg"},{"Torso","RightLeg"},
        }
    end
    for i, c in ipairs(conns) do
        local pA, pB = joints[c[1]], joints[c[2]]
        if pA and pB then
            local posA, osA = camera:WorldToViewportPoint(pA.Position)
            local posB, osB = camera:WorldToViewportPoint(pB.Position)
            local line = skel[i] or cd("Line", {Thickness=2, Transparency=1})
            skel[i] = line; line.Color = color
            if osA and osB then
                line.From = Vector2.new(posA.X, posA.Y)
                line.To   = Vector2.new(posB.X, posB.Y)
                line.Visible = true
            else line.Visible = false end
        elseif skel[i] then skel[i].Visible = false end
    end
end

-- ── Aimbot ────────────────────────────────────────────────────
local AIMBOT_SMOOTH = 0.15   -- lerp factor per frame (0.05=slow, 0.3=fast)
local AIMBOT_FOV    = 300    -- max screen pixel radius to look for targets

local function getAimbotTarget(CONFIG, player, camera)
    local bestDist = math.huge
    local bestPart = nil
    local vpSize   = camera.ViewportSize
    local center   = Vector2.new(vpSize.X/2, vpSize.Y/2)

    local function tryPart(char, part)
        if not char or not part then return end
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if not hum or hum.Health <= 0 then return end
        local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
        if not onScreen then return end
        local sp  = Vector2.new(screenPos.X, screenPos.Y)
        local d   = (sp - center).Magnitude
        if d < AIMBOT_FOV and d < bestDist then
            bestDist = d
            bestPart = part
        end
    end

    -- Players
    if CONFIG.AimbotPlayers then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local char = plr.Character
                local part = (CONFIG.AimbotTarget == "head")
                    and char:FindFirstChild("Head")
                    or  char:FindFirstChild("HumanoidRootPart")
                tryPart(char, part)
            end
        end
    end

    -- Monsters
    if CONFIG.AimbotMonsters then
        for model, cat in pairs(knownEntities) do
            if cat == "monster" and model and model.Parent then
                local part = (CONFIG.AimbotTarget == "head")
                    and model:FindFirstChild("Head")
                    or (model:FindFirstChild("HumanoidRootPart")
                        or model:FindFirstChild("Torso"))
                tryPart(model, part)
            end
        end
    end

    return bestPart
end

function ESP:StartAimbot(CONFIG)
    if aimbotConn then return end
    local player = Players.LocalPlayer
    local camera = workspace.CurrentCamera
    aimbotActive = true

    aimbotConn = RunService.RenderStepped:Connect(function(dt)
        if not CONFIG.Aimbot or not aimbotActive then return end
        if not (CONFIG.AimbotPlayers or CONFIG.AimbotMonsters) then return end

        local tgtPart = getAimbotTarget(CONFIG, player, camera)
        if not tgtPart or not tgtPart.Parent then return end

        -- Smooth lerp towards target using slerp on camera CFrame
        local camPos   = camera.CFrame.Position
        local tgtPos   = tgtPart.Position
        local curLook  = camera.CFrame.LookVector
        local wantLook = (tgtPos - camPos).Unit

        -- Smooth factor scales with dt so it's frame-rate independent
        local smooth = math.clamp(AIMBOT_SMOOTH * (dt * 60), 0.01, 1)
        local newLook = curLook:Lerp(wantLook, smooth).Unit

        camera.CFrame = CFrame.new(camPos, camPos + newLook)
    end)
end

function ESP:StopAimbot()
    aimbotActive = false
    if aimbotConn then aimbotConn:Disconnect(); aimbotConn = nil end
end

-- ── Cleanup ───────────────────────────────────────────────────
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

    local function rainbow()       return Color3.fromHSV(rainbowHue % 1, 1, 1) end
    local function boxColor()      return CONFIG.BoxRainbow      and rainbow() or CONFIG.ESPColor end
    local function espInfoColor()  return CONFIG.ESPColor end

    local function plrBoxColor(plr)
        if CONFIG.TeamFilter and player.Team and plr.Team and player.Team == plr.Team then
            return Color3.fromRGB(0,255,0)
        end
        return boxColor()
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
        local d    = plrDrawings[plr]

        if not shouldShow(plr) or not hrp or not hum then
            hideAll(d); continue
        end

        local rootPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        local dist = math.floor((camera.CFrame.Position - hrp.Position).Magnitude)

        if dist > MAX_DIST_ALL or not onScreen then
            hideAll(d); continue
        end

        if not d then
            d = {
                box      = cd("Square", {Thickness=1, Filled=false, Transparency=1}),
                tagText  = cd("Text", {Size=10, Center=true, Outline=true, Transparency=1, Color=Color3.fromRGB(0,220,255)}),
                hpText   = cd("Text", {Size=10, Center=true, Outline=true, Transparency=1}),
                nameText = cd("Text", {Size=12, Center=true, Outline=true, Transparency=1, Color=Color3.fromRGB(255,255,255)}),
                userText = cd("Text", {Size=10, Center=true, Outline=true, Transparency=1, Color=Color3.fromRGB(180,180,180)}),
                tracer   = cd("Line", {Thickness=1, Transparency=1}),
                skel     = {},
            }
            plrDrawings[plr] = d
        end

        local bCol = plrBoxColor(plr)
        local sz   = math.clamp((1000 / math.max(dist,1)) * 2, 10, 600)
        local bW, bH = sz, sz * 1.5
        local bX     = rootPos.X - bW/2
        local bY     = rootPos.Y - bH/2
        local topY   = bY
        local cenX   = rootPos.X

        -- Box
        if CONFIG.BoxESP then
            d.box.Size     = Vector2.new(bW, bH)
            d.box.Position = Vector2.new(bX, bY)
            d.box.Color    = bCol
            d.box.Visible  = true
        else d.box.Visible = false end

        -- Player Info: tag + hp + names + tracer + skeleton (all one toggle)
        if CONFIG.PlayerInfo then
            local pct = math.clamp(hum.Health / math.max(hum.MaxHealth,1), 0, 1)
            local infoColor = CONFIG.BoxRainbow and rainbow() or CONFIG.ESPColor

            d.tagText.Text     = "[PLAYER]"
            d.tagText.Color    = Color3.fromRGB(0,220,255)
            d.tagText.Position = Vector2.new(cenX, topY - 50)
            d.tagText.Visible  = true

            d.hpText.Text     = "HP: "..math.floor(hum.Health).."/"..math.floor(hum.MaxHealth).." | "..dist.." studs"
            d.hpText.Color    = Color3.fromHSV(pct * 0.33, 1, 1)
            d.hpText.Position = Vector2.new(cenX, topY - 38)
            d.hpText.Visible  = true

            d.nameText.Text     = plr.DisplayName
            d.nameText.Color    = Color3.fromRGB(255,255,255)
            d.nameText.Position = Vector2.new(cenX, topY - 26)
            d.nameText.Visible  = true

            d.userText.Text     = "(@"..plr.Name..")"
            d.userText.Color    = Color3.fromRGB(180,180,180)
            d.userText.Position = Vector2.new(cenX, topY - 14)
            d.userText.Visible  = true

            -- Tracer + skeleton only within 200 studs
            if dist <= MAX_DIST_SKEL then
                local vpSize = camera.ViewportSize
                d.tracer.From    = Vector2.new(vpSize.X/2, vpSize.Y)
                d.tracer.To      = Vector2.new(cenX, rootPos.Y)
                d.tracer.Color   = infoColor
                d.tracer.Visible = true
                drawSkel(char, hum, d.skel, infoColor, camera)
            else
                d.tracer.Visible = false
                if d.skel then for _, l in pairs(d.skel) do l.Visible = false end end
            end
        else
            d.tagText.Visible  = false
            d.hpText.Visible   = false
            d.nameText.Visible = false
            d.userText.Visible = false
            d.tracer.Visible   = false
            if d.skel then for _, l in pairs(d.skel) do l.Visible = false end end
        end
    end

    -- ══════════════════════════════════════════════════════════
    -- ENTITY ESP
    -- ══════════════════════════════════════════════════════════
    local anyEntity = CONFIG.NPCBoxESP or CONFIG.NPCMonster or CONFIG.NPCItem

    if not anyEntity then
        for model in pairs(knownEntities) do hideAll(entDrawings[model]) end
        return
    end

    entityScanTick = entityScanTick + 1
    if entityScanTick >= SCAN_INTERVAL then
        entityScanTick = 0
        scanEntities()
    end
    if not next(knownEntities) then scanEntities() end

    for model, cat in pairs(knownEntities) do
        if not model or not model.Parent then
            removeAll(entDrawings[model])
            entDrawings[model]   = nil
            knownEntities[model] = nil
            continue
        end

        local showInfo = (cat == "monster" and CONFIG.NPCMonster) or (cat == "item" and CONFIG.NPCItem)
        local showBox  = CONFIG.NPCBoxESP

        if not showInfo and not showBox then
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

        local eCol = entityColor(CONFIG, cat)
        local d    = entDrawings[model]

        if not d then
            d = {
                box      = cd("Square", {Thickness=1, Filled=false, Transparency=1}),
                tagText  = cd("Text", {Size=10, Center=true, Outline=true, Transparency=1}),
                hpText   = cd("Text", {Size=10, Center=true, Outline=true, Transparency=1}),
                nameText = cd("Text", {Size=11, Center=true, Outline=true, Transparency=1}),
                tracer   = cd("Line", {Thickness=1, Transparency=1}),
                skel     = {},
            }
            entDrawings[model] = d
        end

        local sz   = math.clamp((1000 / math.max(dist,1)) * 2, 10, 600)
        local bW, bH = sz, sz * 1.5
        local bX   = rootPos.X - bW/2
        local bY   = rootPos.Y - bH/2
        local topY = bY
        local cenX = rootPos.X

        -- Box
        if showBox then
            d.box.Size     = Vector2.new(bW, bH)
            d.box.Position = Vector2.new(bX, bY)
            d.box.Color    = eCol
            d.box.Visible  = true
        else d.box.Visible = false end

        -- Info (tag + hp + name + tracer + skeleton)
        if showInfo then
            d.tagText.Text     = tagLabel(cat)
            d.tagText.Color    = eCol
            d.tagText.Position = Vector2.new(cenX, topY - 38)
            d.tagText.Visible  = true

            if hum then
                local pct = math.clamp(hum.Health / math.max(hum.MaxHealth,1), 0, 1)
                d.hpText.Text  = "HP: "..math.floor(hum.Health).."/"..math.floor(hum.MaxHealth).." | "..dist.." studs"
                d.hpText.Color = Color3.fromHSV(pct * 0.33, 1, 1)
            else
                d.hpText.Text  = dist.." studs"
                d.hpText.Color = eCol
            end
            d.hpText.Position  = Vector2.new(cenX, topY - 26)
            d.hpText.Visible   = true

            d.nameText.Text     = model.Name
            d.nameText.Color    = eCol
            d.nameText.Position = Vector2.new(cenX, topY - 14)
            d.nameText.Visible  = true

            if dist <= MAX_DIST_SKEL then
                local vpSize = camera.ViewportSize
                d.tracer.From    = Vector2.new(vpSize.X/2, vpSize.Y)
                d.tracer.To      = Vector2.new(cenX, rootPos.Y)
                d.tracer.Color   = eCol
                d.tracer.Visible = true
                if hum then drawSkel(model, hum, d.skel, eCol, camera) end
            else
                d.tracer.Visible = false
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
