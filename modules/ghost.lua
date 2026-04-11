-- ghost.lua
-- Ghost mode: avatar stays frozen in place, you free-roam as a ghost camera
-- Supports 4 cam modes: free, locked (to nearest player), orbit, third-person follow

local Ghost = {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")

local player = Players.LocalPlayer

local ghostActive   = false
local ghostMode     = "free"  -- "free" | "locked" | "orbit" | "third"
local ghostConn     = nil
local savedCamType  = nil
local savedCamSubj  = nil
local frozenRoot    = nil
local frozenCFrame  = nil
local bodyGyro      = nil
local bodyPos       = nil

-- Ghost free-roam state
local ghostCFrame   = CFrame.new(0, 0, 0)
local GHOST_SPEED   = 32
local orbitAngle    = 0

Ghost.active      = false
Ghost.onChanged   = nil

-- ============================================================
-- HELPERS
-- ============================================================
local function getRoot(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function getNearestPlayer()
    local nearest, nearestDist = nil, math.huge
    local myPos = ghostCFrame.Position
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hrp = getRoot(p.Character)
            if hrp then
                local d = (hrp.Position - myPos).Magnitude
                if d < nearestDist then
                    nearestDist = d
                    nearest = p
                end
            end
        end
    end
    return nearest
end

-- Freeze avatar in place
local function freezeAvatar()
    local char = player.Character
    if not char then return end
    local hrp = getRoot(char)
    if not hrp then return end
    frozenCFrame = hrp.CFrame

    -- BodyGyro keeps rotation
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P = math.huge
    bodyGyro.CFrame = frozenCFrame
    bodyGyro.Parent = hrp

    -- BodyPosition keeps position
    bodyPos = Instance.new("BodyPosition")
    bodyPos.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyPos.P = math.huge
    bodyPos.Position = frozenCFrame.Position
    bodyPos.Parent = hrp

    frozenRoot = hrp

    -- Stop humanoid from moving
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if hum then
        hum.WalkSpeed = 0
        hum.JumpPower = 0
    end
end

local function unfreezeAvatar()
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
    if bodyPos  then bodyPos:Destroy();  bodyPos  = nil end
    frozenRoot = nil

    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
    end
end

-- ============================================================
-- GHOST CAM LOOP
-- ============================================================
local function startGhostCam()
    if ghostConn then ghostConn:Disconnect() end

    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    ghostCFrame = cam.CFrame  -- start from current cam position

    ghostConn = RunService.RenderStepped:Connect(function(dt)
        if not ghostActive then
            ghostConn:Disconnect()
            ghostConn = nil
            return
        end

        local cam2 = workspace.CurrentCamera

        if ghostMode == "free" then
            -- WASD/QE free-roam ghost movement
            local moveDir = Vector3.new(0, 0, 0)
            if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + ghostCFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - ghostCFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - ghostCFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + ghostCFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.E) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.Q) then moveDir = moveDir - Vector3.new(0, 1, 0) end

            local speed = GHOST_SPEED
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed * 2.5 end

            if moveDir.Magnitude > 0 then
                ghostCFrame = ghostCFrame + moveDir.Unit * speed * dt
            end

            -- Mouse look (right mouse button held, or always)
            local mouseDelta = UIS:GetMouseDelta()
            local rotX = CFrame.Angles(0, -mouseDelta.X * 0.003, 0)
            local rotY = CFrame.Angles(-mouseDelta.Y * 0.003, 0, 0)
            ghostCFrame = rotX * ghostCFrame * rotY

            cam2.CFrame = ghostCFrame

        elseif ghostMode == "locked" then
            -- Lock to nearest player's POV
            local nearest = getNearestPlayer()
            if nearest and nearest.Character then
                local hrp  = getRoot(nearest.Character)
                local head = nearest.Character:FindFirstChild("Head")
                if hrp then
                    local eyePos = head and head.CFrame.Position or (hrp.CFrame.Position + Vector3.new(0, 1.5, 0))
                    cam2.CFrame = CFrame.new(eyePos, eyePos + hrp.CFrame.LookVector * 10)
                end
            end

        elseif ghostMode == "orbit" then
            -- Orbit around nearest player
            local nearest = getNearestPlayer()
            if nearest and nearest.Character then
                local hrp = getRoot(nearest.Character)
                if hrp then
                    orbitAngle = orbitAngle + dt * 0.5
                    local dist   = 8
                    local height = 3
                    local offset = Vector3.new(math.cos(orbitAngle) * dist, height, math.sin(orbitAngle) * dist)
                    local bodyP  = hrp.Position
                    cam2.CFrame  = CFrame.new(bodyP + offset, bodyP + Vector3.new(0, 1, 0))
                end
            end

        elseif ghostMode == "third" then
            -- Third-person follow nearest player
            local nearest = getNearestPlayer()
            if nearest and nearest.Character then
                local hrp = getRoot(nearest.Character)
                if hrp then
                    local bodyP  = hrp.Position
                    local offset = hrp.CFrame:VectorToWorldSpace(Vector3.new(0, 4, 8))
                    cam2.CFrame  = CFrame.new(bodyP + offset, bodyP + Vector3.new(0, 1, 0))
                end
            end
        end
    end)
end

local function stopGhostCam()
    if ghostConn then ghostConn:Disconnect(); ghostConn = nil end
    local cam = workspace.CurrentCamera
    cam.CameraType = savedCamType or Enum.CameraType.Custom
    cam.CameraSubject = savedCamSubj or (player.Character and player.Character:FindFirstChildWhichIsA("Humanoid"))
end

-- ============================================================
-- PUBLIC API
-- ============================================================
function Ghost:Start(mode)
    if ghostActive then self:Stop() end

    local cam = workspace.CurrentCamera
    savedCamType = cam.CameraType
    savedCamSubj = cam.CameraSubject

    ghostMode   = mode or ghostMode or "free"
    ghostActive = true
    Ghost.active = true

    freezeAvatar()
    startGhostCam()

    if self.onChanged then self.onChanged(true, ghostMode) end
end

function Ghost:Stop()
    ghostActive  = false
    Ghost.active = false

    stopGhostCam()
    unfreezeAvatar()

    if self.onChanged then self.onChanged(false, ghostMode) end
end

function Ghost:SetMode(mode)
    ghostMode = mode
    if ghostActive then
        -- restart cam with new mode
        startGhostCam()
    end
    if self.onChanged then self.onChanged(ghostActive, ghostMode) end
end

function Ghost:GetMode()
    return ghostMode
end

function Ghost:IsActive()
    return ghostActive
end

return Ghost
