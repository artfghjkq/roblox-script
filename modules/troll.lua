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
local spectateMode    = "locked" -- "free" or "locked"
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

local function stopLockedCam()
    if lockedCamConn then
        lockedCamConn:Disconnect()
        lockedCamConn = nil
    end
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

local function startLockedCam(targetPlayer)
    stopLockedCam()
    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    lockedCamConn = RunService.RenderStepped:Connect(function()
        if not spectating or not targetPlayer or not targetPlayer.Character then
            stopLockedCam()
            return
        end
        local char = targetPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        -- Position camera at the target's head, looking where they look
        local head = char:FindFirstChild("Head")
        local eyePos = head and head.CFrame.Position or hrp.CFrame.Position + Vector3.new(0, 1.5, 0)
        workspace.CurrentCamera.CFrame = CFrame.new(eyePos, eyePos + hrp.CFrame.LookVector * 10)
    end)
end

function Troll:StartSpectate(targetPlayer, mode)
    if not targetPlayer or not targetPlayer.Character then return false end
    local hum = targetPlayer.Character:FindFirstChildWhichIsA("Humanoid")
    if not hum then return false end
    spectating = true
    specTarget = targetPlayer
    spectateMode = mode or spectateMode or "free"
    self.selectedTarget = targetPlayer

    if spectateMode == "locked" then
        startLockedCam(targetPlayer)
    else
        stopLockedCam()
        workspace.CurrentCamera.CameraSubject = hum
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
    stopLockedCam()
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

function Troll:ScareOnce()
    if scareCooldown then return false end
    local tgt = self.selectedTarget
    if not tgt or not tgt.Character then return false end
    local myRoot  = getRoot(player.Character)
    local tgtRoot = getRoot(tgt.Character)
    if not myRoot or not tgtRoot then return false end

    scareCooldown   = true
    self.scareReady = false

    task.spawn(function()
        local saved = myRoot.CFrame
        myRoot.CFrame = CFrame.new(
            tgtRoot.Position - tgtRoot.CFrame.LookVector * 2,
            tgtRoot.Position
        )
        task.wait(0.5)
        pcall(function() myRoot.CFrame = saved end)
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

return Troll
