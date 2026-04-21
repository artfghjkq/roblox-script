local Camera = {}

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player     = Players.LocalPlayer
local camera     = workspace.CurrentCamera

local activeMode     = "normal"
local thirdConn      = nil
local thirdOffset    = Vector3.new(2.5, 1.5, 6)
local thirdFov       = 80
local origFov        = camera.FieldOfView
local origCamType    = camera.CameraType

local function tw(obj, props, dur)
    if not obj or not obj.Parent then return end
    pcall(function()
        TweenService:Create(obj,
            TweenInfo.new(dur or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            props
        ):Play()
    end)
end

local function stopThird()
    if thirdConn then thirdConn:Disconnect(); thirdConn = nil end
    pcall(function()
        camera.CameraType    = Enum.CameraType.Custom
        camera.FieldOfView   = origFov
    end)
end

local function startThird()
    stopThird()
    pcall(function()
        camera.CameraType  = Enum.CameraType.Scriptable
        camera.FieldOfView = thirdFov
    end)

    thirdConn = RunService.RenderStepped:Connect(function()
        pcall(function()
            local char = player.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local hum    = char:FindFirstChildWhichIsA("Humanoid")
            local lookDir = hrp.CFrame.LookVector
            local offset  = thirdOffset
            local camPos  = hrp.Position
                + hrp.CFrame.RightVector * offset.X
                + Vector3.new(0, offset.Y, 0)
                - lookDir * offset.Z
            camera.CFrame = CFrame.new(camPos, hrp.Position + Vector3.new(0, 1.5, 0))
        end)
    end)
end

local function setMode(mode)
    activeMode = mode
    if mode == "normal" then
        stopThird()
    elseif mode == "third" then
        startThird()
    end
end

function Camera:GetMode() return activeMode end

function Camera:Stop()
    stopThird()
    activeMode = "normal"
end

function Camera:BuildHub(screenGui, Notif, CONFIG, createCorner, toggleSyncs)
    local HUB_W = 240
    local HUB_H = 260

    local BW = {
        BG     = Color3.fromRGB(10,  10,  10),
        Panel  = Color3.fromRGB(18,  18,  18),
        Row    = Color3.fromRGB(26,  26,  26),
        Border = Color3.fromRGB(55,  55,  55),
        Active = Color3.fromRGB(220, 220, 220),
        ActFg  = Color3.fromRGB(10,  10,  10),
        Text   = Color3.fromRGB(210, 210, 210),
        Dim    = Color3.fromRGB(110, 110, 110),
        White  = Color3.fromRGB(255, 255, 255),
    }

    local hub = Instance.new("Frame")
    hub.Name             = "CameraHub"
    hub.Size             = UDim2.new(0, HUB_W, 0, HUB_H)
    hub.Position         = UDim2.new(0.5, -HUB_W/2 + 160, 0.5, -HUB_H/2)
    hub.BackgroundColor3 = BW.BG
    hub.Active           = true
    hub.Draggable        = true
    hub.Visible          = false
    hub.ZIndex           = 20
    hub.ClipsDescendants = true
    hub.Parent           = screenGui
    createCorner(hub, 12)
    local hubStroke = Instance.new("UIStroke", hub)
    hubStroke.Color     = BW.Border
    hubStroke.Thickness = 1

    local topBar = Instance.new("Frame")
    topBar.Size             = UDim2.new(1, 0, 0, 36)
    topBar.BackgroundColor3 = BW.Panel
    topBar.ZIndex           = 21
    topBar.Parent           = hub
    createCorner(topBar, 12)
    local topFill = Instance.new("Frame")
    topFill.Size             = UDim2.new(1, 0, 0.5, 0)
    topFill.Position         = UDim2.new(0, 0, 0.5, 0)
    topFill.BackgroundColor3 = BW.Panel
    topFill.BorderSizePixel  = 0
    topFill.ZIndex           = 21
    topFill.Parent           = topBar

    local hubTitle = Instance.new("TextLabel")
    hubTitle.Size               = UDim2.new(1, -70, 1, 0)
    hubTitle.Position           = UDim2.new(0, 12, 0, 0)
    hubTitle.BackgroundTransparency = 1
    hubTitle.Text               = "CAMERA HUB"
    hubTitle.Font               = Enum.Font.GothamBold
    hubTitle.TextSize           = 12
    hubTitle.TextColor3         = BW.White
    hubTitle.TextXAlignment     = Enum.TextXAlignment.Left
    hubTitle.ZIndex             = 22
    hubTitle.Parent             = topBar

    local function topBtn(xOff, txt)
        local b = Instance.new("TextButton")
        b.Size             = UDim2.new(0, 22, 0, 22)
        b.Position         = UDim2.new(1, xOff, 0.5, -11)
        b.BackgroundColor3 = BW.Row
        b.Text             = txt
        b.TextColor3       = BW.Dim
        b.Font             = Enum.Font.GothamBold
        b.TextSize         = 10
        b.ZIndex           = 22
        b.Parent           = topBar
        createCorner(b, 5)
        local bs = Instance.new("UIStroke", b)
        bs.Color = BW.Border; bs.Thickness = 1
        b.MouseEnter:Connect(function() tw(b, {TextColor3 = BW.White}) end)
        b.MouseLeave:Connect(function() tw(b, {TextColor3 = BW.Dim}) end)
        return b
    end

    local hubMinimize = topBtn(-50, "—")
    local hubClose    = topBtn(-26, "✕")

    local body = Instance.new("ScrollingFrame")
    body.Size                 = UDim2.new(1, -6, 1, -40)
    body.Position             = UDim2.new(0, 3, 0, 38)
    body.BackgroundTransparency = 1
    body.BorderSizePixel      = 0
    body.ScrollBarThickness   = 2
    body.ScrollBarImageColor3 = BW.Border
    body.CanvasSize           = UDim2.new(0, 0, 0, 0)
    body.AutomaticCanvasSize  = Enum.AutomaticSize.Y
    body.ZIndex               = 20
    body.Parent               = hub

    local bodyLayout = Instance.new("UIListLayout", body)
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bodyLayout.Padding   = UDim.new(0, 6)

    local bodyPad = Instance.new("UIPadding", body)
    bodyPad.PaddingTop    = UDim.new(0, 6)
    bodyPad.PaddingBottom = UDim.new(0, 6)
    bodyPad.PaddingLeft   = UDim.new(0, 6)
    bodyPad.PaddingRight  = UDim.new(0, 6)

    local function sectionLabel(txt, lo)
        local lbl = Instance.new("TextLabel")
        lbl.Size               = UDim2.new(1, 0, 0, 14)
        lbl.BackgroundTransparency = 1
        lbl.Text               = txt
        lbl.Font               = Enum.Font.GothamBold
        lbl.TextSize           = 8
        lbl.TextColor3         = BW.Dim
        lbl.TextXAlignment     = Enum.TextXAlignment.Left
        lbl.LayoutOrder        = lo or 0
        lbl.ZIndex             = 21
        lbl.Parent             = body
    end

    sectionLabel("VIEW MODE", 1)

    local modeRow = Instance.new("Frame")
    modeRow.Size             = UDim2.new(1, 0, 0, 34)
    modeRow.BackgroundColor3 = BW.Row
    modeRow.LayoutOrder      = 2
    modeRow.ZIndex           = 21
    modeRow.Parent           = body
    createCorner(modeRow, 8)
    local mRowStroke = Instance.new("UIStroke", modeRow)
    mRowStroke.Color = BW.Border; mRowStroke.Thickness = 1

    local modeLayout = Instance.new("UIListLayout", modeRow)
    modeLayout.FillDirection         = Enum.FillDirection.Horizontal
    modeLayout.SortOrder             = Enum.SortOrder.LayoutOrder
    modeLayout.HorizontalAlignment   = Enum.HorizontalAlignment.Center
    modeLayout.VerticalAlignment     = Enum.VerticalAlignment.Center
    modeLayout.Padding               = UDim.new(0, 6)
    local modePad = Instance.new("UIPadding", modeRow)
    modePad.PaddingLeft  = UDim.new(0, 6)
    modePad.PaddingRight = UDim.new(0, 6)

    local MODES     = {"Normal", "Third"}
    local modeKeys  = {"normal", "third"}
    local modeBtns  = {}

    local function updateModeBtns(current)
        for i, key in ipairs(modeKeys) do
            local on = (key == current)
            modeBtns[i].BackgroundColor3 = on and BW.Active or BW.Panel
            modeBtns[i].TextColor3       = on and BW.ActFg or BW.Dim
        end
    end

    for i, label in ipairs(MODES) do
        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(0, 88, 0, 22)
        btn.BackgroundColor3 = (i == 1) and BW.Active or BW.Panel
        btn.Text             = label:upper()
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = 9
        btn.TextColor3       = (i == 1) and BW.ActFg or BW.Dim
        btn.ZIndex           = 22
        btn.LayoutOrder      = i
        btn.Parent           = modeRow
        createCorner(btn, 6)
        modeBtns[i] = btn

        local capKey = modeKeys[i]
        btn.MouseButton1Click:Connect(function()
            setMode(capKey)
            updateModeBtns(capKey)
            CONFIG.CameraMode = capKey
            Notif:Send("Camera: " .. label, 2)
        end)
    end

    sectionLabel("THIRD PERSON SETTINGS", 3)

    local function numRow(lo, labelTxt, defaultVal, minVal, maxVal, onChange)
        local row = Instance.new("Frame")
        row.Size             = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = BW.Row
        row.LayoutOrder      = lo
        row.ZIndex           = 21
        row.Parent           = body
        createCorner(row, 7)
        local rStroke = Instance.new("UIStroke", row)
        rStroke.Color = BW.Border; rStroke.Thickness = 1

        local lbl = Instance.new("TextLabel")
        lbl.Size               = UDim2.new(1, -70, 1, 0)
        lbl.Position           = UDim2.new(0, 8, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text               = labelTxt
        lbl.Font               = Enum.Font.GothamSemibold
        lbl.TextSize           = 9
        lbl.TextColor3         = BW.Text
        lbl.TextXAlignment     = Enum.TextXAlignment.Left
        lbl.ZIndex             = 22
        lbl.Parent             = row

        local box = Instance.new("TextBox")
        box.Size               = UDim2.new(0, 54, 0, 18)
        box.Position           = UDim2.new(1, -60, 0.5, -9)
        box.BackgroundColor3   = BW.Panel
        box.Text               = tostring(defaultVal)
        box.Font               = Enum.Font.GothamBold
        box.TextSize           = 10
        box.TextColor3         = BW.White
        box.ClearTextOnFocus   = false
        box.TextXAlignment     = Enum.TextXAlignment.Center
        box.ZIndex             = 22
        box.Parent             = row
        createCorner(box, 4)
        local bStroke = Instance.new("UIStroke", box)
        bStroke.Color = BW.Border; bStroke.Thickness = 1

        box.FocusLost:Connect(function()
            local v = tonumber(box.Text)
            if v then
                v = math.clamp(v, minVal, maxVal)
                box.Text = tostring(v)
                onChange(v)
            else
                box.Text = tostring(defaultVal)
            end
        end)

        return box
    end

    numRow(4, "Distance (Z)", thirdOffset.Z, 2, 20, function(v)
        thirdOffset = Vector3.new(thirdOffset.X, thirdOffset.Y, v)
        if activeMode == "third" then startThird() end
    end)

    numRow(5, "Side Offset (X)", thirdOffset.X, -5, 5, function(v)
        thirdOffset = Vector3.new(v, thirdOffset.Y, thirdOffset.Z)
        if activeMode == "third" then startThird() end
    end)

    numRow(6, "Height Offset (Y)", thirdOffset.Y, -3, 5, function(v)
        thirdOffset = Vector3.new(thirdOffset.X, v, thirdOffset.Z)
        if activeMode == "third" then startThird() end
    end)

    numRow(7, "Field of View", thirdFov, 50, 120, function(v)
        thirdFov = v
        if activeMode == "third" then
            pcall(function() camera.FieldOfView = thirdFov end)
        end
    end)

    local minimized = false
    local savedH    = HUB_H

    hubMinimize.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            savedH = hub.AbsoluteSize.Y
            tw(hub, {Size = UDim2.new(0, HUB_W, 0, 36)}, 0.2)
            hubMinimize.Text = "+"
        else
            tw(hub, {Size = UDim2.new(0, HUB_W, 0, savedH)}, 0.25, Enum.EasingStyle.Back)
            hubMinimize.Text = "—"
        end
    end)

    hubClose.MouseButton1Click:Connect(function()
        hub.Visible    = false
        CONFIG.CameraView = false
        if toggleSyncs and toggleSyncs["CameraView"] then toggleSyncs["CameraView"](false) end
        Camera:Stop()
    end)

    return hub
end

return Camera
