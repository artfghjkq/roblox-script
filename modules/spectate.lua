-- spectate.lua
-- Module version — called by main script
-- Usage: Spectate:Init(container, BW, createCorner, Notif)

local Spectate = {}

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- State
local spectating   = false
local specTarget   = nil
local spectateMode = "free"
local camConn      = nil
local orbitAngle   = 0

local function stopCam()
    if camConn then camConn:Disconnect(); camConn = nil end
    pcall(function()
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        local myHum = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
        workspace.CurrentCamera.CameraSubject = myHum or player.Character
    end)
end

local function startCam(tgt, mode)
    stopCam()
    if not tgt or not tgt.Character then return end
    local char = tgt.Character
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildWhichIsA("Humanoid")
    if not hrp then return end

    if mode == "free" then
        workspace.CurrentCamera.CameraType    = Enum.CameraType.Custom
        workspace.CurrentCamera.CameraSubject = hum or hrp
        return
    end

    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

    camConn = RunService.RenderStepped:Connect(function(dt)
        if not spectating or not tgt or not tgt.Character then stopCam(); return end
        local r = tgt.Character:FindFirstChild("HumanoidRootPart")
        local h = tgt.Character:FindFirstChild("Head")
        if not r then return end

        local bodyPos = r.CFrame.Position
        local eyePos  = h and h.CFrame.Position or (bodyPos + Vector3.new(0,1.5,0))

        if mode == "locked" then
            workspace.CurrentCamera.CFrame = CFrame.new(eyePos, eyePos + r.CFrame.LookVector * 10)
        elseif mode == "orbit" then
            orbitAngle = orbitAngle + dt * 0.5
            local off = Vector3.new(math.cos(orbitAngle)*8, 3, math.sin(orbitAngle)*8)
            workspace.CurrentCamera.CFrame = CFrame.new(bodyPos + off, bodyPos + Vector3.new(0,1,0))
        elseif mode == "third" then
            local off = r.CFrame:VectorToWorldSpace(Vector3.new(0, 4, 8))
            workspace.CurrentCamera.CFrame = CFrame.new(bodyPos + off, bodyPos + Vector3.new(0,1,0))
        end
    end)
end

function Spectate:SetTarget(tgt)
    specTarget  = tgt
    spectating  = tgt ~= nil
    orbitAngle  = 0
    if spectating then startCam(tgt, spectateMode)
    else stopCam() end
end

function Spectate:SetMode(mode)
    spectateMode = mode
    if spectating and specTarget then startCam(specTarget, mode) end
end

function Spectate:Stop()
    self:SetTarget(nil)
end

function Spectate:IsSpectating() return spectating end
function Spectate:GetTarget()    return specTarget  end
function Spectate:GetMode()      return spectateMode end

-- ── UI ────────────────────────────────────────────────────────
function Spectate:Init(container, BW, createCorner, Notif)

    local function tw(obj, props, dur)
        if not obj or not obj.Parent then return end
        pcall(function()
            TweenService:Create(obj, TweenInfo.new(dur or 0.18,
                Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
        end)
    end

    local function stroke(obj, col, t)
        local s = Instance.new("UIStroke", obj)
        s.Color = col or BW.Border
        s.Thickness = t or 1
        return s
    end

    -- Current target badge
    local targetBadge = Instance.new("Frame")
    targetBadge.Size             = UDim2.new(1, -4, 0, 26)
    targetBadge.BackgroundColor3 = BW.Row
    targetBadge.LayoutOrder      = 1
    targetBadge.Parent           = container
    createCorner(targetBadge, 6)
    stroke(targetBadge, BW.Border, 1)

    local targetLbl = Instance.new("TextLabel")
    targetLbl.Size               = UDim2.new(1, -10, 1, 0)
    targetLbl.Position           = UDim2.new(0, 8, 0, 0)
    targetLbl.BackgroundTransparency = 1
    targetLbl.Text               = "Not spectating"
    targetLbl.Font               = Enum.Font.GothamBold
    targetLbl.TextSize           = 10
    targetLbl.TextColor3         = BW.Dim
    targetLbl.TextXAlignment     = Enum.TextXAlignment.Left
    targetLbl.TextTruncate       = Enum.TextTruncate.AtEnd
    targetLbl.Parent             = targetBadge

    -- Cam mode row
    local camRow = Instance.new("Frame")
    camRow.Size             = UDim2.new(1, -4, 0, 26)
    camRow.BackgroundColor3 = BW.Row
    camRow.LayoutOrder      = 2
    camRow.Parent           = container
    createCorner(camRow, 6)
    stroke(camRow, BW.Border, 1)

    local camModes = {"Free","Lock","Orb","3rd"}
    local camKeys  = {"free","locked","orbit","third"}
    local camBtns  = {}

    local camLayout = Instance.new("UIListLayout", camRow)
    camLayout.FillDirection       = Enum.FillDirection.Horizontal
    camLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    camLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
    camLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    camLayout.Padding             = UDim.new(0, 4)
    local camPad = Instance.new("UIPadding", camRow)
    camPad.PaddingLeft  = UDim.new(0, 4)
    camPad.PaddingRight = UDim.new(0, 4)

    for i, lbl in ipairs(camModes) do
        local cb = Instance.new("TextButton")
        cb.Size             = UDim2.new(0, 44, 0, 18)
        cb.BackgroundColor3 = (i==1) and BW.Active or BW.Panel
        cb.Text             = lbl
        cb.Font             = Enum.Font.GothamBold
        cb.TextSize         = 9
        cb.TextColor3       = (i==1) and BW.ActFg or BW.Dim
        cb.LayoutOrder      = i
        cb.Parent           = camRow
        createCorner(cb, 4)
        camBtns[camKeys[i]] = cb
    end

    local function setCamUI(mode)
        for _, k in ipairs(camKeys) do
            local on = (k == mode)
            camBtns[k].BackgroundColor3 = on and BW.Active or BW.Panel
            camBtns[k].TextColor3       = on and BW.ActFg or BW.Dim
        end
    end

    for _, k in ipairs(camKeys) do
        local capK = k
        camBtns[capK].MouseButton1Click:Connect(function()
            self:SetMode(capK)
            setCamUI(capK)
            if Notif then Notif:Send("Cam: "..capK, 1) end
        end)
    end

    -- Stop button
    local stopBtn = Instance.new("TextButton")
    stopBtn.Size             = UDim2.new(1, -4, 0, 26)
    stopBtn.BackgroundColor3 = BW.Row
    stopBtn.Text             = "STOP"
    stopBtn.TextColor3       = BW.Dim
    stopBtn.Font             = Enum.Font.GothamBold
    stopBtn.TextSize         = 10
    stopBtn.LayoutOrder      = 3
    stopBtn.Parent           = container
    createCorner(stopBtn, 6)
    stroke(stopBtn, BW.Border, 1)

    stopBtn.MouseButton1Click:Connect(function()
        self:Stop()
        targetLbl.Text       = "Not spectating"
        targetLbl.TextColor3 = BW.Dim
        refreshList()
        if Notif then Notif:Send("Spectate stopped", 1) end
    end)

    -- Refresh button
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size             = UDim2.new(1, -4, 0, 22)
    refreshBtn.BackgroundColor3 = BW.Panel
    refreshBtn.Text             = "[ R ]  Refresh List"
    refreshBtn.TextColor3       = BW.Dim
    refreshBtn.Font             = Enum.Font.GothamBold
    refreshBtn.TextSize         = 9
    refreshBtn.TextXAlignment   = Enum.TextXAlignment.Left
    refreshBtn.LayoutOrder      = 4
    refreshBtn.Parent           = container
    createCorner(refreshBtn, 6)
    local rPad = Instance.new("UIPadding", refreshBtn)
    rPad.PaddingLeft = UDim.new(0, 8)

    -- Player list frame
    local listFrame = Instance.new("Frame")
    listFrame.Size               = UDim2.new(1, -4, 0, 0)
    listFrame.AutomaticSize      = Enum.AutomaticSize.Y
    listFrame.BackgroundTransparency = 1
    listFrame.LayoutOrder        = 5
    listFrame.Parent             = container

    local listLayout = Instance.new("UIListLayout", listFrame)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding   = UDim.new(0, 3)

    local playerBtns = {}

    function refreshList()
        for _, b in pairs(playerBtns) do
            if b and b.Parent then b:Destroy() end
        end
        playerBtns = {}

        local plrs = Players:GetPlayers()
        local any  = false
        for _, p in ipairs(plrs) do
            if p ~= player then
                any = true
                local capP  = p
                local isSel = specTarget == capP
                local btn   = Instance.new("TextButton")
                btn.Size             = UDim2.new(1, 0, 0, 30)
                btn.BackgroundColor3 = isSel and BW.Active or BW.Row
                btn.Font             = Enum.Font.GothamBold
                btn.TextSize         = 9
                btn.Text             = capP.DisplayName .. "\n@" .. capP.Name
                btn.TextColor3       = isSel and BW.ActFg or BW.Text
                btn.TextXAlignment   = Enum.TextXAlignment.Left
                btn.TextWrapped      = true
                btn.Parent           = listFrame
                createCorner(btn, 6)
                local bPad = Instance.new("UIPadding", btn)
                bPad.PaddingLeft = UDim.new(0, 8)
                table.insert(playerBtns, btn)

                btn.MouseButton1Click:Connect(function()
                    if specTarget == capP then
                        self:Stop()
                        targetLbl.Text       = "Not spectating"
                        targetLbl.TextColor3 = BW.Dim
                        if Notif then Notif:Send("Spectate stopped", 1) end
                    else
                        self:SetTarget(capP)
                        targetLbl.Text       = "👁 " .. capP.DisplayName
                        targetLbl.TextColor3 = BW.Text
                        if Notif then Notif:Send("Spectating " .. capP.Name, 2) end
                    end
                    refreshList()
                end)
            end
        end

        if not any then
            local empty = Instance.new("TextLabel")
            empty.Size               = UDim2.new(1, 0, 0, 26)
            empty.BackgroundTransparency = 1
            empty.Text               = "No other players."
            empty.Font               = Enum.Font.Gotham
            empty.TextSize           = 9
            empty.TextColor3         = BW.Dim
            empty.Parent             = listFrame
            table.insert(playerBtns, empty)
        end
    end

    refreshBtn.MouseButton1Click:Connect(refreshList)

    -- Auto-refresh on join/leave
    Players.PlayerAdded:Connect(function() refreshList() end)
    Players.PlayerRemoving:Connect(function(p)
        if p == specTarget then
            self:Stop()
            targetLbl.Text       = "Not spectating"
            targetLbl.TextColor3 = BW.Dim
            if Notif then Notif:Send(p.Name .. " left", 2) end
        end
        refreshList()
    end)

    refreshList()
end

return Spectate
