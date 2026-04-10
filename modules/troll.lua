local Troll = {}

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")

local player = Players.LocalPlayer

local function getRoot(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local scareConn       = nil
local flinging        = false
local flingDiedConn   = nil
local walkFlinging    = false
local walkFlingThread = nil
local antiFlingConn   = nil

local function setNoclip(state)
    if state then
        RunService.Stepped:Connect(function()
            local char = player.Character
            if not char then return end
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    end
end

function Troll:StartScare(targetPlayer)
    if scareConn then scareConn:Disconnect(); scareConn = nil end
    scareConn = RunService.Heartbeat:Connect(function()
        local myChar   = player.Character
        local myRoot   = getRoot(myChar)
        local tgt      = targetPlayer or (Players:GetPlayers()[2] ~= player and Players:GetPlayers()[2]) or nil
        if not tgt then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player then tgt = p break end
            end
        end
        if not myRoot or not tgt then return end
        local tgtRoot = getRoot(tgt.Character)
        if not tgtRoot then return end
        local savedCFrame = myRoot.CFrame
        myRoot.CFrame = tgtRoot.CFrame + tgtRoot.CFrame.LookVector * 2
        myRoot.CFrame = CFrame.new(myRoot.Position, tgtRoot.Position)
        task.wait(0.5)
        pcall(function() myRoot.CFrame = savedCFrame end)
    end)
end

function Troll:StopScare()
    if scareConn then scareConn:Disconnect(); scareConn = nil end
end

function Troll:ScareOnce(targetPlayer)
    local myChar  = player.Character
    local myRoot  = getRoot(myChar)
    if not myRoot then return end
    local tgt = targetPlayer
    if not tgt then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player then tgt = p break end
        end
    end
    if not tgt then return end
    local tgtRoot = getRoot(tgt.Character)
    if not tgtRoot then return end
    local savedCFrame = myRoot.CFrame
    myRoot.CFrame = tgtRoot.CFrame + tgtRoot.CFrame.LookVector * 2
    myRoot.CFrame = CFrame.new(myRoot.Position, tgtRoot.Position)
    task.wait(0.5)
    pcall(function() myRoot.CFrame = savedCFrame end)
end

function Troll:StartFling()
    if flinging then self:StopFling() end
    local char = player.Character
    if not char then return end
    for _, child in pairs(char:GetDescendants()) do
        if child:IsA("BasePart") then
            pcall(function()
                child.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
            end)
        end
    end
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
            pcall(function() v.Massless = true end)
            v.Velocity = Vector3.new(0, 0, 0)
        end
    end
    local root = getRoot(char)
    if not root then return end
    local bav = Instance.new("BodyAngularVelocity")
    bav.Name = "HH_FlingBAV"
    bav.AngularVelocity = Vector3.new(0, 99999, 0)
    bav.MaxTorque = Vector3.new(0, math.huge, 0)
    bav.P = math.huge
    bav.Parent = root
    flinging = true
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        flingDiedConn = hum.Died:Connect(function()
            Troll:StopFling()
        end)
    end
    task.spawn(function()
        repeat
            pcall(function() bav.AngularVelocity = Vector3.new(0, 99999, 0) end)
            task.wait(0.2)
            pcall(function() bav.AngularVelocity = Vector3.new(0, 0, 0) end)
            task.wait(0.1)
        until not flinging
    end)
end

function Troll:StopFling()
    flinging = false
    if flingDiedConn then flingDiedConn:Disconnect(); flingDiedConn = nil end
    task.wait(0.1)
    local char = player.Character
    if not char then return end
    local root = getRoot(char)
    if root then
        for _, v in pairs(root:GetChildren()) do
            if v.Name == "HH_FlingBAV" then v:Destroy() end
        end
    end
    for _, child in pairs(char:GetDescendants()) do
        if child.ClassName == "Part" or child.ClassName == "MeshPart" then
            pcall(function()
                child.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
            end)
        end
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
                    if v:IsA("BasePart") then
                        v.CanCollide = false
                    end
                end
            end
        end
    end)
end

function Troll:StopAntiFling()
    if antiFlingConn then
        antiFlingConn:Disconnect()
        antiFlingConn = nil
    end
end

function Troll:IsAntiFling()
    return antiFlingConn ~= nil
end

return Troll
