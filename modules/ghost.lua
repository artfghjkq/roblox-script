-- ghost.lua
-- Ghost mode: clones your character as a semi-transparent ghost you control,
-- while your original avatar stays frozen in place.
-- Adapted from roblox-ts reference implementation.

local Ghost = {}

local Players = game:GetService("Players")
local player  = Players.LocalPlayer

local originalCharacter = nil
local ghostCharacter    = nil
local lastPosition      = nil
local diedConn          = nil
local ghostMode         = "locked"

Ghost.active    = false
Ghost.onChanged = nil

-- ============================================================
-- HELPERS
-- ============================================================
local function getRoot(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local screenGuisDisabled = {}
local function disableResetOnSpawn()
    local playerGui = player:FindFirstChildWhichIsA("PlayerGui")
    if not playerGui then return end
    for _, obj in pairs(playerGui:GetChildren()) do
        if obj:IsA("ScreenGui") and obj.ResetOnSpawn then
            table.insert(screenGuisDisabled, obj)
            obj.ResetOnSpawn = false
        end
    end
end

local function enableResetOnSpawn()
    for _, obj in pairs(screenGuisDisabled) do
        pcall(function() obj.ResetOnSpawn = true end)
    end
    screenGuisDisabled = {}
end

-- ============================================================
-- ACTIVATE
-- ============================================================
local function activateGhost()
    local character = player.Character
    local humanoid  = character and character:FindFirstChildWhichIsA("Humanoid")
    if not character or not humanoid then return false end

    -- Clone current character as ghost
    character.Archivable = true
    ghostCharacter = character:Clone()
    character.Archivable = false

    -- Save original root position
    local rootPart    = getRoot(character)
    lastPosition      = rootPart and rootPart.CFrame
    originalCharacter = character

    -- Make ghost semi-transparent
    local ghostHumanoid = ghostCharacter:FindFirstChildWhichIsA("Humanoid")
    for _, child in pairs(ghostCharacter:GetDescendants()) do
        if child:IsA("BasePart") then
            child.Transparency = 1 - (1 - child.Transparency) * 0.5
        end
    end

    -- Ghost emoji display name
    if ghostHumanoid then
        pcall(function()
            ghostHumanoid.DisplayName = utf8.char(128123)
        end)
    end

    -- Move Animate script to ghost so it plays animations
    local existingAnimate = ghostCharacter:FindFirstChild("Animate")
    if existingAnimate then existingAnimate:Destroy() end
    local animation = originalCharacter:FindFirstChild("Animate")
    if animation then
        animation.Disabled = true
        animation.Parent   = ghostCharacter
    end

    -- Switch player to ghost character (ikaw ang ghost na naglalakad)
    disableResetOnSpawn()
    ghostCharacter.Parent = character.Parent
    player.Character = ghostCharacter
    workspace.CurrentCamera.CameraSubject = ghostHumanoid
    enableResetOnSpawn()

    -- Re-enable animation on ghost
    if animation then animation.Disabled = false end

    -- Freeze original avatar in place
    if rootPart then
        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.P         = math.huge
        bg.CFrame    = rootPart.CFrame
        bg.Parent    = rootPart

        local bp = Instance.new("BodyPosition")
        bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bp.P        = math.huge
        bp.Position = rootPart.Position
        bp.Parent   = rootPart
    end

    -- Stop if original dies
    if diedConn then diedConn:Disconnect() end
    diedConn = humanoid.Died:Connect(function()
        diedConn:Disconnect()
        diedConn = nil
        Ghost:Stop()
    end)

    Ghost.active = true
    if Ghost.onChanged then Ghost.onChanged(true, ghostMode) end
    return true
end

-- ============================================================
-- DEACTIVATE
-- ============================================================
local function deactivateGhost()
    if not originalCharacter or not ghostCharacter then return end

    -- Get ghost's current position to teleport original there
    local ghostRoot  = getRoot(ghostCharacter)
    local currentPos = ghostRoot and ghostRoot.CFrame

    -- Save animation script before destroying ghost
    local animation = ghostCharacter:FindFirstChild("Animate")
    if animation then
        animation.Disabled = true
        animation.Parent   = nil
    end

    -- Destroy ghost
    ghostCharacter:Destroy()

    -- Stop playing animations on original
    local humanoid = originalCharacter:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            track:Stop()
        end
    end

    -- Remove freeze constraints from original
    local origRoot = getRoot(originalCharacter)
    if origRoot then
        for _, child in pairs(origRoot:GetChildren()) do
            if child:IsA("BodyGyro") or child:IsA("BodyPosition") then
                child:Destroy()
            end
        end
        -- Teleport original to where ghost ended up
        local pos = currentPos or lastPosition
        if pos then pcall(function() origRoot.CFrame = pos end) end
    end

    -- Restore original character
    disableResetOnSpawn()
    player.Character = originalCharacter
    workspace.CurrentCamera.CameraSubject = humanoid
    enableResetOnSpawn()

    -- Restore animation to original
    if animation then
        animation.Parent   = originalCharacter
        animation.Disabled = false
    end

    originalCharacter = nil
    ghostCharacter    = nil
    lastPosition      = nil

    Ghost.active = false
    if Ghost.onChanged then Ghost.onChanged(false, ghostMode) end
end

-- ============================================================
-- PUBLIC API
-- ============================================================
function Ghost:Start(mode)
    if Ghost.active then self:Stop() end
    ghostMode = mode or ghostMode or "free"
    local ok = activateGhost()
    if not ok then warn("[ghost] Could not activate: no character") end
end

function Ghost:Stop()
    if diedConn then diedConn:Disconnect(); diedConn = nil end
    deactivateGhost()
end

function Ghost:SetMode(mode)
    ghostMode = mode
    if Ghost.onChanged then Ghost.onChanged(Ghost.active, ghostMode) end
end

function Ghost:GetMode()
    return ghostMode
end

function Ghost:IsActive()
    return Ghost.active
end

return Ghost
