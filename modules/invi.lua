-- invi.lua
-- Invisibility module for HALO-HALO
-- Method: sethiddenproperty CFrame flicker (IY-style)
-- Falls back to transparency-only if executor doesn't support it

local Invi = {}

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")

local player = Players.LocalPlayer

-- Internal state
local _conn   = nil
local _active = false

-- Attempt to use sethiddenproperty (best method — hides from server)
local _sethidden = (sethiddenproperty or set_hidden_property or set_hidden_prop)
local _useHidden = type(_sethidden) == "function"

-- ============================================================
-- CORE LOOP
-- ============================================================
local function _stopLoop()
    if _conn then
        _conn:Disconnect()
        _conn = nil
    end
end

local function _startLoop()
    _stopLoop()
    _conn = RunService.RenderStepped:Connect(function()
        if not _active then _stopLoop() return end

        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildWhichIsA("Humanoid")
        if not hrp or not hum then return end

        if _useHidden then
            -- Best method: hide CFrame via hidden property so server sees player
            -- underground while client sees them normally
            local orig = hrp.CFrame
            local camOff = hum.CameraOffset

            pcall(_sethidden, hrp, "CFrame", orig * CFrame.new(0, -1e6, 0))
            hum.CameraOffset = hrp.CFrame:ToObjectSpace(CFrame.new(orig.Position)).Position

            task.defer(function()
                if hrp and hrp.Parent then
                    pcall(_sethidden, hrp, "CFrame", orig)
                    hum.CameraOffset = camOff
                end
            end)
        else
            -- Fallback: standard CFrame flicker
            local orig   = hrp.CFrame
            local camOff = hum.CameraOffset

            hrp.CFrame = orig * CFrame.new(0, -1e6, 0)
            hum.CameraOffset = hrp.CFrame:ToObjectSpace(CFrame.new(orig.Position)).Position

            task.defer(function()
                if hrp and hrp.Parent then
                    hrp.CFrame = orig
                    hum.CameraOffset = camOff
                end
            end)
        end
    end)
end

-- ============================================================
-- TRANSPARENCY HELPERS
-- ============================================================
local _savedTransparency = {}

local function _hideChar(char)
    _savedTransparency = {}
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            _savedTransparency[part] = part.Transparency
            part.Transparency = 1
        end
    end
    -- Keep HRP visible to self so camera works, just fully transparent
end

local function _showChar(char)
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            local saved = _savedTransparency[part]
            part.Transparency = saved ~= nil and saved or 0
        end
    end
    _savedTransparency = {}
end

-- ============================================================
-- PUBLIC API
-- ============================================================

function Invi:Enable()
    _active = true
    local char = player.Character
    if char then _hideChar(char) end
    _startLoop()
end

function Invi:Disable()
    _active = false
    _stopLoop()
    local char = player.Character
    if char then _showChar(char) end
end

function Invi:Set(state)
    if state then
        self:Enable()
    else
        self:Disable()
    end
end

function Invi:IsActive()
    return _active
end

-- Re-apply on respawn (called by main script's CharacterAdded)
function Invi:OnCharacterAdded(char)
    if not _active then return end
    task.wait(0.5)
    _hideChar(char)
    _startLoop()
end

return Invi
