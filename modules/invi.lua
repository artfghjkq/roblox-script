local Invi = {}

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local _active      = false
local _steppedConn = nil
local _flyConn     = nil
local _keyDownConn = nil
local _keyUpConn   = nil
local _flying      = false
local _realChar    = nil

local function getRoot(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function stopFly()
    _flying = false
    if _keyDownConn then _keyDownConn:Disconnect(); _keyDownConn = nil end
    if _keyUpConn   then _keyUpConn:Disconnect();   _keyUpConn   = nil end
    if _flyConn     then _flyConn:Disconnect();     _flyConn     = nil end
end

local function startFly(root)
    if _flying then stopFly() end
    _flying = true

    local bg = Instance.new("BodyGyro")
    bg.P = 9e4
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.CFrame = root.CFrame
    bg.Parent = root

    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Parent = root

    local ctrl  = {F=0, B=0, L=0, R=0}
    local speed = 50

    _keyDownConn = UserInputService.InputBegan:Connect(function(input, proc)
        if proc then return end
        if input.KeyCode == Enum.KeyCode.W then ctrl.F =  speed
        elseif input.KeyCode == Enum.KeyCode.S then ctrl.B = -speed
        elseif input.KeyCode == Enum.KeyCode.A then ctrl.L = -speed
        elseif input.KeyCode == Enum.KeyCode.D then ctrl.R =  speed
        end
    end)

    _keyUpConn = UserInputService.InputEnded:Connect(function(input, proc)
        if proc then return end
        if input.KeyCode == Enum.KeyCode.W then ctrl.F = 0
        elseif input.KeyCode == Enum.KeyCode.S then ctrl.B = 0
        elseif input.KeyCode == Enum.KeyCode.A then ctrl.L = 0
        elseif input.KeyCode == Enum.KeyCode.D then ctrl.R = 0
        end
    end)

    _flyConn = RunService.Heartbeat:Connect(function()
        if not _flying or not root or not root.Parent then
            stopFly()
            return
        end
        local cam  = workspace.CurrentCamera
        local move = cam.CFrame.LookVector  * (ctrl.F + ctrl.B)
                   + cam.CFrame.RightVector * (ctrl.L + ctrl.R)
        bg.CFrame  = cam.CFrame
        bv.Velocity = move
    end)
end

local function startSteppedLoop(root)
    if _steppedConn then _steppedConn:Disconnect() end
    _steppedConn = RunService.Stepped:Connect(function()
        if not _active then
            _steppedConn:Disconnect()
            _steppedConn = nil
            return
        end
        if root and root.Parent then
            root.CanCollide = false
        end
    end)
end

function Invi:Enable()
    if _active then return end
    _active   = true
    _realChar = player.Character
    if not _realChar then _active = false return end

    local hum = _realChar:FindFirstChildWhichIsA("Humanoid")
    if hum then
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        end)
    end

    local dummy   = Instance.new("Model")
    dummy.Name    = "HH_InviDummy"
    dummy.Parent  = workspace

    local dTorso          = Instance.new("Part")
    dTorso.Name           = "Torso"
    dTorso.CanCollide     = false
    dTorso.Anchored       = true
    dTorso.Position       = Vector3.new(0, 9999, 0)
    dTorso.Parent         = dummy

    local dHead           = Instance.new("Part")
    dHead.Name            = "Head"
    dHead.CanCollide      = false
    dHead.Anchored        = true
    dHead.Position        = Vector3.new(0, 9999, 0)
    dHead.Parent          = dummy

    local dHum            = Instance.new("Humanoid")
    dHum.Name             = "Humanoid"
    dHum.Parent           = dummy

    player.Character = dummy
    task.wait(3)

    if not _active then
        player.Character = _realChar
        dummy:Destroy()
        return
    end

    player.Character = _realChar
    task.wait(3)

    if not _active then
        dummy:Destroy()
        return
    end

    local newHum        = Instance.new("Humanoid")
    newHum.Parent       = _realChar

    local root = getRoot(_realChar)

    for _, v in pairs(_realChar:GetChildren()) do
        if v ~= root
        and v.Name ~= "Humanoid"
        and not v:IsA("Script")
        and not v:IsA("LocalScript")
        and not v:IsA("ModuleScript") then
            pcall(function() v:Destroy() end)
        end
    end

    if root then
        root.Transparency = 1
        root.CanCollide   = false
        workspace.CurrentCamera.CameraSubject = root
        startSteppedLoop(root)
        startFly(root)
    end

    dummy:Destroy()
end

function Invi:Disable()
    if not _active then return end
    _active = false

    stopFly()
    if _steppedConn then _steppedConn:Disconnect(); _steppedConn = nil end

    pcall(function()
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            hum.PlatformStand = false
        end
        local root = getRoot(char)
        if root then
            root.Transparency = 0
            root.CanCollide   = true
        end
        workspace.CurrentCamera.CameraSubject = hum or char
    end)

    _realChar = nil
end

function Invi:Set(state)
    if state then self:Enable() else self:Disable() end
end

function Invi:IsActive()
    return _active
end

function Invi:OnCharacterAdded()
    if not _active then return end
    _active = false
    task.wait(1)
    self:Enable()
end

return Invi
