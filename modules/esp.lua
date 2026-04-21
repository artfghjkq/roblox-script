local ESP = {}

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local plrDrawings = {}
local entDrawings = {}

local knownEntities  = {}
local entityScanTick = 0
local SCAN_INTERVAL  = 180
local MAX_DIST_ALL   = 500
local MAX_DIST_SKEL  = 200

local aimbotActive  = false
local aimbotConn    = nil

local function cd(t, p)
    local o = Drawing.new(t)
    for k, v in pairs(p) do o[k] = v end
    return o
end

local function hideAll(d)
    if not d then return end
    for _, k in ipairs({"box","tagText","hpText","nameText","userText","tracer","tracerOutline"}) do
        if d[k] then d[k].Visible = false end
    end
    if d.skel then for _, l in pairs(d.skel) do l.Visible = false end end
end

local function removeAll(d)
    if not d then return end
    for _, k in ipairs({"box","tagText","hpText","nameText","userText","tracer","tracerOutline"}) do
        if d[k] then d[k]:Remove() end
    end
    if d.skel then for _, l in pairs(d.skel) do l:Remove() end end
end

local TEAMMATE_KW = {
    "sheriff", "innocent",
}

local ENEMY_KW = {
    "killer", "murderer", "siren", "cartoon_cat", "imposter",
}

local FRIENDLY_KW = {
    "npc", "civilian", "villager", "townsfolk", "merchant", "shopkeeper", "vendor", "trader",
    "quest", "guide", "helper", "friendly", "ally", "companion", "pet", "tamer",
    "mayor", "king", "queen", "prince", "princess", "knight", "hero", "saint",
    "child", "baby", "elder", "old", "sage", "farmer", "blacksmith", "innkeeper",
    "doctor", "nurse", "priest", "monk", "wizard", "mage",
}

local MONSTER_KW = {
    "zombie", "ghoul", "revenant", "lich", "mummy", "wight", "draugr", "risen",
    "ghost", "demon", "devil", "spirit", "shade", "phantom", "banshee", "poltergeist",
    "vampire", "werewolf", "witch", "cultist", "abomination", "cursed", "haunted",
    "creature", "beast", "mutant", "alien", "parasite", "infected", "horror",
    "spider", "wolf", "bear", "lion", "tiger", "shark", "snake", "rat", "bat",
    "hawk", "crow", "golem", "slime", "blob", "worm", "insect", "bug", "wasp", "scorpion",
    "goblin", "orc", "troll", "ogre", "dragon", "hydra", "wyvern", "titan", "giant",
    "fiend", "imp", "brute", "juggernaut", "colossus",
    "bandit", "pirate", "raider", "rogue", "outlaw", "thug", "gangster",
    "soldier", "guard", "mercenary", "grunt", "militia", "rebel",
    "enemy", "hostile", "attacker", "aggressor", "predator",
    "robot", "android", "drone", "turret", "mech", "cyborg", "sentinel",
    "boss", "minion", "stalker", "hunter", "crawler", "jumper", "runner", "charger",
    "pursuer", "monster", "mob",
    "killer", "murderer", "siren", "cartoon_cat", "imposter",
}

local ITEM_KW = {
    "gun", "rifle", "pistol", "shotgun", "sniper", "smg", "revolver", "musket",
    "ak47", "ak-47", "m16", "m4", "m4a1", "uzi", "deagle", "glock", "beretta",
    "colt", "mp5", "p90", "aug", "scar", "famas", "g36", "ak74", "vector",
    "minigun", "railgun", "lasergun", "plasmagun", "flamethrower",
    "weapon", "ammo", "bullet", "magazine", "clip", "grenade", "explosive",
    "mine", "landmine", "c4", "flashbang", "smoke",
    "knife", "sword", "blade", "axe", "bow", "crossbow", "spear", "hammer",
    "machete", "dagger", "katana", "scythe", "sickle", "mace", "club",
    "apple", "banana", "orange", "grape", "watermelon", "strawberry", "cherry",
    "lemon", "lime", "mango", "peach", "pear", "pineapple", "coconut", "blueberry",
    "raspberry", "kiwi", "papaya", "guava", "avocado", "melon", "pomegranate",
    "food", "meal", "ration", "snack", "bread", "burger", "sandwich", "pizza",
    "hotdog", "taco", "sushi", "rice", "noodle", "pasta", "soup", "stew",
    "cookie", "cake", "donut", "pie", "candy", "chocolate", "chips", "popcorn",
    "meat", "chicken", "fish", "beef", "pork", "egg", "cheese", "butter",
    "cereal", "cracker", "pretzel", "waffle", "pancake", "bacon", "biscuit",
    "water", "drink", "juice", "soda", "cola", "milk", "coffee", "tea",
    "beer", "wine", "smoothie", "shake", "energy",
    "medkit", "bandage", "heal", "aid", "potion", "elixir", "antidote",
    "pill", "syringe", "medicine", "herb", "remedy", "cure",
    "chest", "crate", "box", "barrel", "bag", "backpack", "case", "container",
    "trunk", "bin", "bucket", "basket", "vault", "safe", "locker",
    "drawer", "cabinet", "shelf", "rack", "cages",
    "loot", "drop", "pickup", "package", "airdrop", "supply", "supplies",
    "cache", "stash", "reward", "prize", "gift", "present",
    "ore", "wood", "stone", "metal", "iron", "steel", "copper", "silver",
    "crystal", "gem", "diamond", "ruby", "emerald", "sapphire",
    "coin", "coins", "gold", "cash", "money", "credit", "token",
    "chip", "key", "keycard", "fuel", "battery", "oil", "gas",
    "scrap", "material", "resource", "artifact", "relic",
    "plank", "log", "rock", "sand", "glass", "plastic", "rubber", "cloth",
    "computer", "laptop", "pc", "terminal", "console", "monitor", "screen",
    "keyboard", "server", "router", "tablet", "phone", "radio",
    "walkie", "radar", "scanner", "tracker",
    "tool", "equipment", "device", "machine", "generator", "engine",
    "wrench", "screwdriver", "drill", "saw", "crowbar",
    "flashlight", "torch", "lantern", "rope", "chain", "wire",
    "helmet", "armor", "vest", "shield", "mask", "goggle",
    "shop", "store", "market", "door", "button", "lever", "switch",
    "prop", "object", "item", "collectible", "trophy",
}

local function classifyModel(model)
    local n = model.Name:lower()

    for _, kw in ipairs(TEAMMATE_KW) do
        if n:find(kw, 1, true) then return "teammate" end
    end
    for _, kw in ipairs(ENEMY_KW) do
        if n:find(kw, 1, true) then return "monster" end
    end
    for _, kw in ipairs(FRIENDLY_KW) do
        if n:find(kw, 1, true) then return "item" end
    end
    for _, kw in ipairs(MONSTER_KW) do
        if n:find(kw, 1, true) then return "monster" end
    end
    for _, kw in ipairs(ITEM_KW) do
        if n:find(kw, 1, true) then return "item" end
    end

    local hum = model:FindFirstChildWhichIsA("Humanoid")
    return hum and "monster" or "item"
end

local function entityColor(CONFIG, cat)
    if cat == "monster" then
        return CONFIG.NPCMonsterColor or Color3.fromRGB(220, 50, 50)
    end
    return CONFIG.NPCItemColor or Color3.fromRGB(255, 165, 0)
end

local function tagLabel(cat)
    if cat == "monster" then return "[MONSTER]"
    elseif cat == "teammate" then return "[TEAMMATE]"
    else return "[ITEM]" end
end

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
        if isHRP or isHum then
            local model = obj.Parent
            if model and model:IsA("Model") and not chars[model] and not knownEntities[model] then
                knownEntities[model] = classifyModel(model)
            end
        end
    end
end

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
            skel[i] = line
            line.Color = color
            if osA and osB then
                line.From    = Vector2.new(posA.X, posA.Y)
                line.To      = Vector2.new(posB.X, posB.Y)
                line.Visible = true
            else
                line.Visible = false
            end
        elseif skel[i] then
            skel[i].Visible = false
        end
    end
end

local AIMBOT_SMOOTH = 0.15
local AIMBOT_FOV    = 300
local aimbotLocked     = false
local aimbotLockedPart = nil

local function getAimbotTarget(CONFIG, player, camera)
    if aimbotLocked and aimbotLockedPart and aimbotLockedPart.Parent then
        local hum = aimbotLockedPart.Parent:FindFirstChildWhichIsA("Humanoid")
            or (aimbotLockedPart.Parent.Parent and aimbotLockedPart.Parent.Parent:FindFirstChildWhichIsA("Humanoid"))
        if hum and hum.Health > 0 then
            return aimbotLockedPart
        else
            aimbotLocked     = false
            aimbotLockedPart = nil
        end
    end

    local bestDist = math.huge
    local bestPart = nil
    local vpSize   = camera.ViewportSize
    local center   = Vector2.new(vpSize.X / 2, vpSize.Y / 2)

    local function tryPart(char, part)
        if not char or not part then return end
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if not hum or hum.Health <= 0 then return end
        local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
        if not onScreen then return end
        local sp = Vector2.new(screenPos.X, screenPos.Y)
        local d  = (sp - center).Magnitude
        if d < AIMBOT_FOV and d < bestDist then
            bestDist = d
            bestPart = part
        end
    end

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

    if CONFIG.AimbotMonsters then
        for model, cat in pairs(knownEntities) do
            if cat == "monster" and model and model.Parent then
                local part = (CONFIG.AimbotTarget == "head")
                    and model:FindFirstChild("Head")
                    or (model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso"))
                tryPart(model, part)
            end
        end
    end

    return bestPart
end

function ESP:SetAimbotLocked(locked)
    aimbotLocked = locked
    if not locked then aimbotLockedPart = nil end
end

function ESP:IsAimbotLocked() return aimbotLocked end
function ESP:GetLockedPart()  return aimbotLockedPart end

function ESP:StartAimbot(CONFIG)
    if aimbotConn then return end
    local player = Players.LocalPlayer
    local camera = workspace.CurrentCamera
    aimbotActive = true

    aimbotConn = RunService.RenderStepped:Connect(function(dt)
        if not CONFIG.Aimbot or not aimbotActive then return end
        if not (CONFIG.AimbotPlayers or CONFIG.AimbotMonsters) then return end

        local tgtPart = getAimbotTarget(CONFIG, player, camera)
        if not tgtPart or not tgtPart.Parent then
            if aimbotLocked then
                aimbotLocked     = false
                aimbotLockedPart = nil
            end
            return
        end

        if not aimbotLocked then aimbotLockedPart = tgtPart end

        local camPos   = camera.CFrame.Position
        local tgtPos   = tgtPart.Position
        local curLook  = camera.CFrame.LookVector
        local wantLook = (tgtPos - camPos).Unit
        local smooth   = math.clamp(AIMBOT_SMOOTH * (dt * 60), 0.01, 1)
        local newLook  = curLook:Lerp(wantLook, smooth).Unit

        camera.CFrame = CFrame.new(camPos, camPos + newLook)
    end)
end

function ESP:StopAimbot()
    aimbotActive     = false
    aimbotLocked     = false
    aimbotLockedPart = nil
    if aimbotConn then aimbotConn:Disconnect(); aimbotConn = nil end
end

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

function ESP:Update(CONFIG, COLORS, rainbowHue)
    local player = Players.LocalPlayer
    local camera = workspace.CurrentCamera

    local function rainbow() return Color3.fromHSV(rainbowHue % 1, 1, 1) end

    local function getRoleFromName(plr)
        local n = plr.Name:lower()
        local t = plr.Team and plr.Team.Name:lower() or ""
        for _, kw in ipairs(TEAMMATE_KW) do
            if n:find(kw, 1, true) or t:find(kw, 1, true) then return "teammate" end
        end
        for _, kw in ipairs(ENEMY_KW) do
            if n:find(kw, 1, true) or t:find(kw, 1, true) then return "enemy" end
        end
        return "neutral"
    end

    local function isEnemy(plr)
        if not CONFIG.TeamFilter then return false end
        if player.Team and plr.Team then return player.Team ~= plr.Team end
        return getRoleFromName(plr) == "enemy"
    end

    local function isTeammate(plr)
        if not CONFIG.TeamFilter then return false end
        if player.Team and plr.Team then return player.Team == plr.Team end
        return getRoleFromName(plr) == "teammate"
    end

    local function plrTracerColor(plr)
        if CONFIG.TeamFilter then
            if isEnemy(plr)    then return Color3.fromRGB(220, 50, 50) end
            if isTeammate(plr) then return Color3.fromRGB(50, 220, 100) end
        end
        return CONFIG.BoxRainbow and rainbow() or CONFIG.ESPColor
    end

    local function plrBoxColor(plr)
        if CONFIG.TeamFilter then
            if isEnemy(plr)    then return Color3.fromRGB(220, 50, 50) end
            if isTeammate(plr) then return Color3.fromRGB(50, 220, 100) end
        end
        return CONFIG.BoxRainbow and rainbow() or CONFIG.ESPColor
    end

    for _, plr in pairs(Players:GetPlayers()) do
        local char = plr.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChild("Humanoid")
        local d    = plrDrawings[plr]

        if plr == player or not hrp or not hum then hideAll(d); continue end

        local rootPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        local dist = math.floor((camera.CFrame.Position - hrp.Position).Magnitude)

        if dist > MAX_DIST_ALL or not onScreen then hideAll(d); continue end

        if not d then
            d = {
                box           = cd("Square", {Thickness=1, Filled=false, Transparency=1}),
                tagText       = cd("Text", {Size=10, Center=true, Outline=true, Transparency=1, Color=Color3.fromRGB(0,220,255)}),
                hpText        = cd("Text", {Size=10, Center=true, Outline=true, Transparency=1}),
                nameText      = cd("Text", {Size=12, Center=true, Outline=true, Transparency=1, Color=Color3.fromRGB(255,255,255)}),
                userText      = cd("Text", {Size=10, Center=true, Outline=true, Transparency=1, Color=Color3.fromRGB(180,180,180)}),
                tracer        = cd("Line", {Thickness=2, Transparency=1}),
                tracerOutline = cd("Line", {Thickness=4, Transparency=0.6}),
                skel          = {},
            }
            plrDrawings[plr] = d
        end

        local bCol = plrBoxColor(plr)
        local tCol = plrTracerColor(plr)
        local sz   = math.clamp((1000 / math.max(dist, 1)) * 2, 10, 600)
        local bW   = sz
        local bH   = sz * 1.5
        local bX   = rootPos.X - bW / 2
        local bY   = rootPos.Y - bH / 2
        local topY = bY
        local cenX = rootPos.X

        if CONFIG.BoxESP then
            d.box.Size     = Vector2.new(bW, bH)
            d.box.Position = Vector2.new(bX, bY)
            d.box.Color    = bCol
            d.box.Visible  = true
        else
            d.box.Visible = false
        end

        if CONFIG.PlayerInfo then
            local pct      = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            local enemy    = isEnemy(plr)
            local teammate = isTeammate(plr)

            local tagColor, tagStr
            if CONFIG.TeamFilter then
                if enemy then
                    tagColor = Color3.fromRGB(220, 50, 50)
                    tagStr   = "[ENEMY]"
                elseif teammate then
                    tagColor = Color3.fromRGB(50, 220, 100)
                    tagStr   = "[TEAMMATE]"
                else
                    tagColor = Color3.fromRGB(0, 220, 255)
                    tagStr   = "[PLAYER]"
                end
            else
                tagColor = Color3.fromRGB(0, 220, 255)
                tagStr   = "[PLAYER]"
            end

            d.tagText.Text     = tagStr
            d.tagText.Color    = tagColor
            d.tagText.Position = Vector2.new(cenX, topY - 50)
            d.tagText.Visible  = true

            d.hpText.Text     = "HP: " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. " | " .. dist .. " studs"
            d.hpText.Color    = Color3.fromHSV(pct * 0.33, 1, 1)
            d.hpText.Position = Vector2.new(cenX, topY - 38)
            d.hpText.Visible  = true

            d.nameText.Text     = plr.DisplayName
            d.nameText.Color    = Color3.fromRGB(255, 255, 255)
            d.nameText.Position = Vector2.new(cenX, topY - 26)
            d.nameText.Visible  = true

            d.userText.Text     = "(@" .. plr.Name .. ")"
            d.userText.Color    = Color3.fromRGB(180, 180, 180)
            d.userText.Position = Vector2.new(cenX, topY - 14)
            d.userText.Visible  = true

            if dist <= MAX_DIST_SKEL then
                local vpSize = camera.ViewportSize
                local fromPt = Vector2.new(vpSize.X / 2, vpSize.Y)
                local toPt   = Vector2.new(cenX, rootPos.Y)

                d.tracerOutline.From      = fromPt
                d.tracerOutline.To        = toPt
                d.tracerOutline.Color     = Color3.fromRGB(0, 0, 0)
                d.tracerOutline.Thickness = 4
                d.tracerOutline.Visible   = true

                d.tracer.From      = fromPt
                d.tracer.To        = toPt
                d.tracer.Color     = tCol
                d.tracer.Thickness = 2
                d.tracer.Visible   = true

                drawSkel(char, hum, d.skel, tCol, camera)
            else
                d.tracer.Visible        = false
                d.tracerOutline.Visible = false
                if d.skel then for _, l in pairs(d.skel) do l.Visible = false end end
            end
        else
            d.tagText.Visible       = false
            d.hpText.Visible        = false
            d.nameText.Visible      = false
            d.userText.Visible      = false
            d.tracer.Visible        = false
            d.tracerOutline.Visible = false
            if d.skel then for _, l in pairs(d.skel) do l.Visible = false end end
        end
    end

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

        if not showInfo and not showBox then hideAll(entDrawings[model]); continue end

        local hrp = model:FindFirstChild("HumanoidRootPart")
               or  model:FindFirstChild("Torso")
               or  model:FindFirstChild("HRP")
        if not hrp then hideAll(entDrawings[model]); continue end

        local hum               = model:FindFirstChildWhichIsA("Humanoid")
        local rootPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        local dist              = math.floor((camera.CFrame.Position - hrp.Position).Magnitude)

        if dist > MAX_DIST_ALL or not onScreen then hideAll(entDrawings[model]); continue end

        local eCol = entityColor(CONFIG, cat)
        local d    = entDrawings[model]

        if not d then
            d = {
                box           = cd("Square", {Thickness=1, Filled=false, Transparency=1}),
                tagText       = cd("Text", {Size=10, Center=true, Outline=true, Transparency=1}),
                hpText        = cd("Text", {Size=10, Center=true, Outline=true, Transparency=1}),
                nameText      = cd("Text", {Size=11, Center=true, Outline=true, Transparency=1}),
                tracer        = cd("Line", {Thickness=2, Transparency=1}),
                tracerOutline = cd("Line", {Thickness=4, Transparency=0.6}),
                skel          = {},
            }
            entDrawings[model] = d
        end

        local sz     = math.clamp((1000 / math.max(dist, 1)) * 2, 10, 600)
        local bW     = sz
        local bH     = sz * 1.5
        local bX     = rootPos.X - bW / 2
        local bY     = rootPos.Y - bH / 2
        local topY   = bY
        local cenX   = rootPos.X

        if showBox then
            d.box.Size     = Vector2.new(bW, bH)
            d.box.Position = Vector2.new(bX, bY)
            d.box.Color    = eCol
            d.box.Visible  = true
        else
            d.box.Visible = false
        end

        if showInfo then
            d.tagText.Text     = tagLabel(cat)
            d.tagText.Color    = eCol
            d.tagText.Position = Vector2.new(cenX, topY - 38)
            d.tagText.Visible  = true

            if hum then
                local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                d.hpText.Text  = "HP: " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. " | " .. dist .. " studs"
                d.hpText.Color = Color3.fromHSV(pct * 0.33, 1, 1)
            else
                d.hpText.Text  = dist .. " studs"
                d.hpText.Color = eCol
            end
            d.hpText.Position = Vector2.new(cenX, topY - 26)
            d.hpText.Visible  = true

            d.nameText.Text     = model.Name
            d.nameText.Color    = eCol
            d.nameText.Position = Vector2.new(cenX, topY - 14)
            d.nameText.Visible  = true

            if dist <= MAX_DIST_SKEL then
                local vpSize = camera.ViewportSize
                local fromPt = Vector2.new(vpSize.X / 2, vpSize.Y)
                local toPt   = Vector2.new(cenX, rootPos.Y)

                d.tracerOutline.From      = fromPt
                d.tracerOutline.To        = toPt
                d.tracerOutline.Color     = Color3.fromRGB(0, 0, 0)
                d.tracerOutline.Thickness = 4
                d.tracerOutline.Visible   = true

                d.tracer.From      = fromPt
                d.tracer.To        = toPt
                d.tracer.Color     = eCol
                d.tracer.Thickness = 2
                d.tracer.Visible   = true

                if hum then drawSkel(model, hum, d.skel, eCol, camera) end
            else
                d.tracer.Visible        = false
                d.tracerOutline.Visible = false
                if d.skel then for _, l in pairs(d.skel) do l.Visible = false end end
            end
        else
            d.tagText.Visible       = false
            d.hpText.Visible        = false
            d.nameText.Visible      = false
            d.tracer.Visible        = false
            d.tracerOutline.Visible = false
            if d.skel then for _, l in pairs(d.skel) do l.Visible = false end end
        end
    end
end

return ESP
