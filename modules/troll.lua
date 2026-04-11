local Troll = {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local function getRoot(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local scareCooldown   = false
local flinging        = false
local flingBav        = nil
local flingNoclipConn = nil
local flingDiedConn   = nil
local walkFlinging    = false
local walkFlingThread = nil
local antiFlingConn   = nil
local spectating      = false
local specTarget      = nil
local spectateMode    = "free" -- "free" or "locked"
local lockedCamConn   = nil

Troll.selectedTarget  = nil
Troll.scareReady      = true
Troll.onScareReady    = nil
Troll.onSpectateChanged = nil

function Troll:SetTarget(targetPlayer)
    self.selectedTarget = targetPlayer
end

function Troll:GetTarget()
    return self.selectedTarget
end

local function stopScriptedCam()
    if lockedCamConn then
        lockedCamConn:Disconnect()
        lockedCamConn = nil
    end
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

local function startScriptedCam(targetPlayer, mode)
    stopScriptedCam()
    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

    -- orbit state for fixed orbit
    local orbitAngle = 0

    lockedCamConn = RunService.RenderStepped:Connect(function(dt)
        if not spectating or not targetPlayer or not targetPlayer.Character then
            stopScriptedCam()
            return
        end
        local char = targetPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local head    = char:FindFirstChild("Head")
        local eyePos  = head and head.CFrame.Position or (hrp.CFrame.Position + Vector3.new(0, 1.5, 0))
        local bodyPos = hrp.CFrame.Position

        if mode == "locked" then
            -- Exact POV of target
            workspace.CurrentCamera.CFrame = CFrame.new(eyePos, eyePos + hrp.CFrame.LookVector * 10)

        elseif mode == "orbit" then
            -- Fixed orbit: camera circles target at fixed distance, player controls angle
            orbitAngle = orbitAngle + dt * 0.4
            local dist   = 8
            local height = 3
            local offset = Vector3.new(math.cos(orbitAngle) * dist, height, math.sin(orbitAngle) * dist)
            workspace.CurrentCamera.CFrame = CFrame.new(bodyPos + offset, bodyPos + Vector3.new(0, 1, 0))

        elseif mode == "third" then
            -- Auto third-person: fixed offset behind & above target, follows their rotation
            local offset = hrp.CFrame:VectorToWorldSpace(Vector3.new(0, 4, 8))
            local camPos = bodyPos + offset
            workspace.CurrentCamera.CFrame = CFrame.new(camPos, bodyPos + Vector3.new(0, 1, 0))
        end
    end)
end

function Troll:StartSpectate(targetPlayer, mode)
    if not targetPlayer or not targetPlayer.Character then return false end
    local hum = targetPlayer.Character:FindFirstChildWhichIsA("Humanoid")
    if not hum then return false end
    spectating    = true
    specTarget    = targetPlayer
    spectateMode  = mode or spectateMode or "free"
    self.selectedTarget = targetPlayer

    if spectateMode == "free" then
        stopScriptedCam()
        workspace.CurrentCamera.CameraSubject = hum
    else
        startScriptedCam(targetPlayer, spectateMode)
    end

    if self.onSpectateChanged then self.onSpectateChanged(targetPlayer) end
    return true
end

function Troll:SetSpectateMode(mode)
    spectateMode = mode
    if spectating and specTarget then
        self:StartSpectate(specTarget, mode)
    end
end

function Troll:GetSpectateMode()
    return spectateMode
end

function Troll:StopSpectate()
    spectating = false
    specTarget = nil
    stopScriptedCam()
    local myChar = player.Character
    local myHum  = myChar and myChar:FindFirstChildWhichIsA("Humanoid")
    workspace.CurrentCamera.CameraSubject = myHum or myChar
    if self.onSpectateChanged then self.onSpectateChanged(nil) end
end

function Troll:IsSpectating()
    return spectating
end

function Troll:GetSpectateTarget()
    return specTarget
end

-- Optional: set this from main script so ScareOnce can temporarily disable invi
Troll.inviModule   = nil
Troll.scareHoldTime = 1   -- seconds to stay in front of target (editable from UI)
Troll.scareDistance = 6   -- studs in front of target (editable from UI)

function Troll:ScareOnce()
    if scareCooldown then return false end
    local tgt = self.selectedTarget
    if not tgt or not tgt.Character then return false end
    local myChar  = player.Character
    local myRoot  = getRoot(myChar)
    local tgtRoot = getRoot(tgt.Character)
    if not myRoot or not tgtRoot then return false end

    scareCooldown   = true
    self.scareReady = false

    task.spawn(function()
        local saved = myRoot.CFrame

        -- Step 1: Temporarily un-invisible so target can actually see us
        local wasInvi = self.inviModule and self.inviModule:IsActive()
        if wasInvi then
            -- Restore HRP transparency so we appear visible
            pcall(function()
                myRoot.Transparency = 0
            end)
            -- Re-add body parts briefly if they were destroyed
            -- (invi destroys parts, so we need to respawn char — instead just make HRP visible)
        end

        -- Step 2: Teleport directly in front of target (face-to-face)
        local dist     = self.scareDistance or 6
        local holdTime = self.scareHoldTime or 1
        local targetCF = tgtRoot.CFrame
        local spawnCF  = targetCF * CFrame.new(0, 0, -dist)
        -- Face the target
        spawnCF = CFrame.new(spawnCF.Position, tgtRoot.Position)

        myRoot.CFrame = spawnCF

        -- Step 3: Wait for physics/network replication (critical!)
        task.wait(0)   -- yield so engine flushes CFrame to server
        task.wait(0)   -- second yield for good measure

        -- Step 4: Hold position for target to see us
        local elapsed  = 0
        local stepConn
        stepConn = RunService.Stepped:Connect(function(_, dt)
            elapsed = elapsed + dt
            if elapsed >= holdTime then
                stepConn:Disconnect()
                return
            end
            -- Keep re-applying CFrame so network latency can't undo it
            pcall(function()
                myRoot.CFrame = CFrame.new(spawnCF.Position, tgtRoot.Position)
            end)
        end)

        task.wait(holdTime + 0.05)

        -- Step 5: Return to original position
        pcall(function() myRoot.CFrame = saved end)

        -- Step 6: Restore invisibility state
        if wasInvi then
            pcall(function()
                myRoot.Transparency = 1
            end)
        end

        task.wait(2.5)
        scareCooldown   = false
        self.scareReady = true
        if self.onScareReady then self.onScareReady() end
    end)

    return true
end

function Troll:IsScareCooldown()
    return scareCooldown
end

function Troll:StartFling()
    if flinging then self:StopFling() end
    local char = player.Character
    if not char then return end
    local root = getRoot(char)
    if not root then return end

    for _, child in pairs(char:GetDescendants()) do
        if child:IsA("BasePart") then
            pcall(function()
                child.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
                child.CanCollide = false
            end)
        end
    end

    flingBav = Instance.new("BodyAngularVelocity")
    flingBav.Name = "HH_FlingBAV"
    flingBav.AngularVelocity = Vector3.new(0, 99999, 0)
    flingBav.MaxTorque = Vector3.new(0, math.huge, 0)
    flingBav.P = math.huge
    flingBav.Parent = root

    flinging = true

    flingNoclipConn = RunService.Stepped:Connect(function()
        if not flinging then
            flingNoclipConn:Disconnect()
            flingNoclipConn = nil
            return
        end
        local c = player.Character
        if not c then return end
        for _, p in pairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
        local r = getRoot(c)
        if r then r.Velocity = Vector3.new(r.Velocity.X, 0, r.Velocity.Z) end
    end)

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        flingDiedConn = hum.Died:Connect(function() Troll:StopFling() end)
    end

    task.spawn(function()
        repeat
            if flingBav and flingBav.Parent then
                flingBav.AngularVelocity = Vector3.new(0, 99999, 0)
            end
            task.wait(0.2)
            if flingBav and flingBav.Parent then
                flingBav.AngularVelocity = Vector3.new(0, 0, 0)
            end
            task.wait(0.1)
        until not flinging
    end)
end

function Troll:StopFling()
    flinging = false
    if flingDiedConn   then flingDiedConn:Disconnect();   flingDiedConn   = nil end
    if flingNoclipConn then flingNoclipConn:Disconnect(); flingNoclipConn = nil end
    if flingBav        then flingBav:Destroy();           flingBav        = nil end

    local char = player.Character
    if not char then return end
    local root = getRoot(char)

    if root then
        root.Velocity        = Vector3.new(0, 0, 0)
        root.RotVelocity     = Vector3.new(0, 0, 0)
        pcall(function()
            root.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end)
    end

    task.wait(0.05)

    for _, child in pairs(char:GetDescendants()) do
        if child.ClassName == "Part" or child.ClassName == "MeshPart" then
            pcall(function()
                child.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
                child.CanCollide = true
            end)
        end
    end

    if root then
        root.Velocity    = Vector3.new(0, 0, 0)
        root.RotVelocity = Vector3.new(0, 0, 0)
    end
end

function Troll:IsFling()
    return flinging
end

function Troll:StartWalkFling()
    if walkFlinging then self:StopWalkFling() end
    walkFlinging = true
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if hum then
        hum.Died:Connect(function() Troll:StopWalkFling() end)
    end
    walkFlingThread = task.spawn(function()
        repeat
            RunService.Heartbeat:Wait()
            local c    = player.Character
            local root = getRoot(c)
            if not (c and c.Parent and root and root.Parent) then
                RunService.Heartbeat:Wait()
                c    = player.Character
                root = getRoot(c)
            end
            if not root then continue end
            local vel   = root.Velocity
            local movel = 0.1
            root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            if c and c.Parent and root and root.Parent then
                root.Velocity = vel
            end
            RunService.Stepped:Wait()
            if c and c.Parent and root and root.Parent then
                root.Velocity = vel + Vector3.new(0, movel, 0)
                movel = movel * -1
            end
        until not walkFlinging
    end)
end

function Troll:StopWalkFling()
    walkFlinging = false
    if walkFlingThread then
        task.cancel(walkFlingThread)
        walkFlingThread = nil
    end
    local char = player.Character
    local root = getRoot(char)
    if root then
        root.Velocity    = Vector3.new(0, 0, 0)
        root.RotVelocity = Vector3.new(0, 0, 0)
    end
end

function Troll:IsWalkFling()
    return walkFlinging
end

function Troll:StartAntiFling()
    if antiFlingConn then antiFlingConn:Disconnect() end
    antiFlingConn = RunService.Stepped:Connect(function()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                for _, v in pairs(p.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end
    end)
end

function Troll:StopAntiFling()
    if antiFlingConn then antiFlingConn:Disconnect(); antiFlingConn = nil end
end

function Troll:IsAntiFling()
    return antiFlingConn ~= nil
end

-- ============================================================
-- RUSH SCARE
-- ============================================================
local rushScareActive = false
local rushScareConn   = nil
local rushCooldown    = false

Troll.rushSpeed    = 100
Troll.rushHoldTime = 1
Troll.onRushReady  = nil

function Troll:RushScare()
    if rushCooldown then return false end
    local tgt = self.selectedTarget
    if not tgt or not tgt.Character then return false end
    local myChar = player.Character
    local myRoot = getRoot(myChar)
    local myHum  = myChar and myChar:FindFirstChildWhichIsA("Humanoid")
    if not myRoot or not myHum then return false end

    rushCooldown    = true
    rushScareActive = true

    task.spawn(function()
        local savedSpeed = myHum.WalkSpeed
        local savedCF    = myRoot.CFrame

        -- Show avatar if invisible
        local wasInvi = self.inviModule and self.inviModule:IsActive()
        if wasInvi then pcall(function() myRoot.Transparency = 0 end) end

        -- Use PathfindingService + Humanoid:MoveTo so the character
        -- walks naturally through the map without touching CanCollide at all
        local PathfindingService = game:GetService("PathfindingService")

        myHum.WalkSpeed = self.rushSpeed or 100

        local reached   = false
        local elapsed   = 0

        local function doRush()
            local tgtRoot = getRoot(tgt.Character)
            if not tgtRoot then reached = true return end

            -- Compute path
            local path = PathfindingService:CreatePath({
                AgentRadius  = 2,
                AgentHeight  = 5,
                AgentCanJump = true,
                AgentCanClimb = false,
            })

            local ok = pcall(function()
                path:ComputeAsync(myRoot.Position, tgtRoot.Position)
            end)

            local waypoints = {}
            if ok and path.Status == Enum.PathStatus.Success then
                waypoints = path:GetWaypoints()
            end

            -- Walk each waypoint
            for _, wp in ipairs(waypoints) do
                if not rushScareActive then break end
                local tgtRoot2 = getRoot(tgt.Character)
                if not tgtRoot2 then break end

                -- Stop if already close enough to final target
                if (myRoot.Position - tgtRoot2.Position).Magnitude <= 4 then
                    reached = true
                    break
                end

                -- Jump waypoint
                if wp.Action == Enum.PathWaypointAction.Jump then
                    myHum.Jump = true
                end

                myHum:MoveTo(wp.Position)

                -- Wait until we reach this waypoint or timeout per step
                local stepTimer = 0
                repeat
                    task.wait(0.05)
                    stepTimer  = stepTimer + 0.05
                    elapsed    = elapsed + 0.05
                until not rushScareActive
                    or (myRoot.Position - wp.Position).Magnitude < 3
                    or stepTimer > 3
                    or elapsed > 10
            end

            -- Final check
            local tgtRoot3 = getRoot(tgt.Character)
            if tgtRoot3 and (myRoot.Position - tgtRoot3.Position).Magnitude <= 6 then
                reached = true
            end

            -- If pathfinding failed or still not close, teleport as last resort
            if not reached then
                local tgtRoot4 = getRoot(tgt.Character)
                if tgtRoot4 then
                    myRoot.CFrame = CFrame.new(
                        (tgtRoot4.CFrame * CFrame.new(0, 0, -4)).Position,
                        tgtRoot4.Position
                    )
                    task.wait(0)
                    task.wait(0)
                    reached = true
                end
            end
        end

        doRush()

        myHum:MoveTo(myRoot.Position) -- stop movement

        -- Hold in front of target's face
        local holdTime    = self.rushHoldTime or 1
        local holdElapsed = 0
        local holdConn
        holdConn = RunService.Stepped:Connect(function(_, dt)
            holdElapsed = holdElapsed + dt
            if holdElapsed >= holdTime then holdConn:Disconnect(); return end
            local tgtRoot = getRoot(tgt.Character)
            if tgtRoot then
                pcall(function()
                    myRoot.CFrame = CFrame.new(
                        (tgtRoot.CFrame * CFrame.new(0, 0, -4)).Position,
                        tgtRoot.Position
                    )
                end)
            end
        end)

        task.wait(holdTime + 0.05)

        -- Restore everything
        rushScareActive = false
        myHum.WalkSpeed = savedSpeed
        pcall(function() myRoot.CFrame = savedCF end)
        if wasInvi then pcall(function() myRoot.Transparency = 1 end) end

        task.wait(2.5)
        rushCooldown = false
        if self.onRushReady then self.onRushReady() end
    end)

    return true
end

function Troll:StopRushScare()
    rushScareActive = false
    if rushScareConn then rushScareConn:Disconnect(); rushScareConn = nil end
end

function Troll:IsRushCooldown()
    return rushCooldown
end

return Troll
