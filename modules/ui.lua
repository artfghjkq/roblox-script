-- ui.lua
-- ScareHub UI module – black & white minimal theme

local UI = {}

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- ── Palette (black & white only) ─────────────────────────────
local C = {
    BG       = Color3.fromRGB(10,  10,  10),   -- window background
    Panel    = Color3.fromRGB(18,  18,  18),   -- panel / inner cards
    Row      = Color3.fromRGB(26,  26,  26),   -- row / button fill
    RowHover = Color3.fromRGB(36,  36,  36),
    Border   = Color3.fromRGB(55,  55,  55),   -- subtle outline
    AccentBg = Color3.fromRGB(220, 220, 220),  -- active highlight bg (near-white)
    AccentFg = Color3.fromRGB(10,  10,  10),   -- text on active highlight
    Text     = Color3.fromRGB(210, 210, 210),  -- primary text
    Dim      = Color3.fromRGB(110, 110, 110),  -- secondary / disabled text
    White    = Color3.fromRGB(255, 255, 255),
    Black    = Color3.fromRGB(0,   0,   0),
    Red      = Color3.fromRGB(220, 60,  60),
}

-- ── Helpers ───────────────────────────────────────────────────
local TweenService = game:GetService("TweenService")

local function corner(obj, r)
    local c = Instance.new("UICorner", obj)
    c.CornerRadius = UDim.new(0, r or 6)
    return c
end

local function stroke(obj, col, t)
    local s = Instance.new("UIStroke", obj)
    s.Color = col or C.Border
    s.Thickness = t or 1
    return s
end

local function tween(obj, props, dur, style)
    if not obj or not obj.Parent then return end
    pcall(function()
        TweenService:Create(obj, TweenInfo.new(dur or 0.18,
            style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
    end)
end

local function label(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font       = Enum.Font.GothamBold
    l.TextSize   = props.size   or 10
    l.TextColor3 = props.color  or C.Text
    l.Text       = props.text   or ""
    l.Size       = props.sz     or UDim2.new(1, 0, 0, 18)
    l.Position   = props.pos    or UDim2.new(0, 0, 0, 0)
    l.TextXAlignment = props.align or Enum.TextXAlignment.Left
    l.ZIndex     = props.z      or 20
    l.Parent     = parent
    return l
end

local function divider(parent, lo)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 1)
    f.BackgroundColor3 = C.Border
    f.BorderSizePixel = 0
    f.LayoutOrder = lo or 0
    f.ZIndex = 20
    f.Parent = parent
    return f
end

-- ── Input row helper (label + TextBox) ───────────────────────
local function inputRow(parent, lo, lTxt, default)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundColor3 = C.Panel
    row.LayoutOrder = lo
    row.ZIndex = 21
    row.Parent = parent
    corner(row, 5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = lTxt
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 10
    lbl.TextColor3 = C.Dim
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 22
    lbl.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 54, 0, 20)
    box.Position = UDim2.new(1, -60, 0.5, -10)
    box.BackgroundColor3 = C.Row
    box.Text = tostring(default)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 11
    box.TextColor3 = C.White
    box.ClearTextOnFocus = false
    box.TextXAlignment = Enum.TextXAlignment.Center
    box.ZIndex = 22
    box.Parent = row
    corner(box, 4)
    stroke(box, C.Border, 1)

    return box
end

-- ── Build ScareHub ────────────────────────────────────────────
function UI:BuildScareHub(screenGui, Troll, Notif, CONFIG, createCorner, toggleSyncs)
    local HUB_W = 280
    local HUB_H = 440

    local hub = Instance.new("Frame")
    hub.Name = "ScareHub"
    hub.Size = UDim2.new(0, HUB_W, 0, HUB_H)
    hub.Position = UDim2.new(0.5, -HUB_W/2, 0.5, -HUB_H/2)
    hub.BackgroundColor3 = C.BG
    hub.Active = true
    hub.Draggable = true
    hub.Visible = false
    hub.ZIndex = 20
    hub.ClipsDescendants = true
    hub.Parent = screenGui
    corner(hub, 10)
    stroke(hub, C.Border, 1)

    -- ── Top bar ───────────────────────────────────────────────
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 38)
    topBar.BackgroundColor3 = C.Panel
    topBar.ZIndex = 21
    topBar.Parent = hub
    corner(topBar, 10)

    -- Flat bottom so rounded top only
    local topBarFill = Instance.new("Frame")
    topBarFill.Size = UDim2.new(1, 0, 0.5, 0)
    topBarFill.Position = UDim2.new(0, 0, 0.5, 0)
    topBarFill.BackgroundColor3 = C.Panel
    topBarFill.BorderSizePixel = 0
    topBarFill.ZIndex = 21
    topBarFill.Parent = topBar

    local hubTitle = Instance.new("TextLabel")
    hubTitle.Size = UDim2.new(1, -80, 1, 0)
    hubTitle.Position = UDim2.new(0, 14, 0, 0)
    hubTitle.BackgroundTransparency = 1
    hubTitle.Text = "SCARE HUB"
    hubTitle.Font = Enum.Font.GothamBold
    hubTitle.TextSize = 12
    hubTitle.TextColor3 = C.White
    hubTitle.TextXAlignment = Enum.TextXAlignment.Left
    hubTitle.ZIndex = 22
    hubTitle.Parent = topBar

    local function topBtn(xOff, txt)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 24, 0, 24)
        b.Position = UDim2.new(1, xOff, 0.5, -12)
        b.BackgroundColor3 = C.Row
        b.Text = txt
        b.TextColor3 = C.Dim
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        b.ZIndex = 22
        b.Parent = topBar
        corner(b, 5)
        stroke(b, C.Border, 1)
        b.MouseEnter:Connect(function() tween(b, {TextColor3=C.White}) end)
        b.MouseLeave:Connect(function() tween(b, {TextColor3=C.Dim}) end)
        return b
    end

    local hubMinimize = topBtn(-56, "—")
    local hubClose    = topBtn(-28, "✕")

    -- ── Scroll body ───────────────────────────────────────────
    local body = Instance.new("ScrollingFrame")
    body.Size = UDim2.new(1, -8, 1, -46)
    body.Position = UDim2.new(0, 4, 0, 42)
    body.BackgroundTransparency = 1
    body.BorderSizePixel = 0
    body.ScrollBarThickness = 2
    body.ScrollBarImageColor3 = C.Border
    body.CanvasSize = UDim2.new(0, 0, 0, 0)
    body.AutomaticCanvasSize = Enum.AutomaticSize.Y
    body.ZIndex = 20
    body.Parent = hub

    local bodyLayout = Instance.new("UIListLayout", body)
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bodyLayout.Padding = UDim.new(0, 4)

    local bodyPad = Instance.new("UIPadding", body)
    bodyPad.PaddingTop    = UDim.new(0, 4)
    bodyPad.PaddingBottom = UDim.new(0, 8)

    -- ── Section header helper ─────────────────────────────────
    local function sectionHeader(txt, lo)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 22)
        row.BackgroundTransparency = 1
        row.LayoutOrder = lo or 0
        row.ZIndex = 20
        row.Parent = body

        local line1 = Instance.new("Frame")
        line1.Size = UDim2.new(0.15, 0, 0, 1)
        line1.Position = UDim2.new(0, 0, 0.5, 0)
        line1.BackgroundColor3 = C.Border
        line1.BorderSizePixel = 0
        line1.ZIndex = 20
        line1.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.7, 0, 1, 0)
        lbl.Position = UDim2.new(0.15, 0, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = txt
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 9
        lbl.TextColor3 = C.Dim
        lbl.ZIndex = 21
        lbl.Parent = row

        local line2 = Instance.new("Frame")
        line2.Size = UDim2.new(0.15, 0, 0, 1)
        line2.Position = UDim2.new(0.85, 0, 0.5, 0)
        line2.BackgroundColor3 = C.Border
        line2.BorderSizePixel = 0
        line2.ZIndex = 20
        line2.Parent = row

        return row
    end

    -- ── TARGET section ────────────────────────────────────────
    sectionHeader("TARGET", 1)

    -- Current target badge
    local targetBadge = Instance.new("Frame")
    targetBadge.Size = UDim2.new(1, 0, 0, 32)
    targetBadge.BackgroundColor3 = C.Panel
    targetBadge.LayoutOrder = 2
    targetBadge.ZIndex = 20
    targetBadge.Parent = body
    corner(targetBadge, 6)
    stroke(targetBadge, C.Border, 1)

    local targetLabel = Instance.new("TextLabel")
    targetLabel.Size = UDim2.new(1, -16, 1, 0)
    targetLabel.Position = UDim2.new(0, 12, 0, 0)
    targetLabel.BackgroundTransparency = 1
    targetLabel.Text = "No target selected"
    targetLabel.Font = Enum.Font.GothamBold
    targetLabel.TextSize = 11
    targetLabel.TextColor3 = C.Dim
    targetLabel.TextXAlignment = Enum.TextXAlignment.Left
    targetLabel.ZIndex = 21
    targetLabel.Parent = targetBadge

    -- Player selector row (dropdown + SPEC + cam modes)
    local selectorRow = Instance.new("Frame")
    selectorRow.Size = UDim2.new(1, 0, 0, 28)
    selectorRow.BackgroundTransparency = 1
    selectorRow.LayoutOrder = 3
    selectorRow.ZIndex = 20
    selectorRow.Parent = body

    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(0, 100, 1, 0)
    dropBtn.BackgroundColor3 = C.Row
    dropBtn.Font = Enum.Font.GothamBold
    dropBtn.TextSize = 9
    dropBtn.Text = "Select player ▼"
    dropBtn.TextColor3 = C.Dim
    dropBtn.TextTruncate = Enum.TextTruncate.AtEnd
    dropBtn.ZIndex = 21
    dropBtn.Parent = selectorRow
    corner(dropBtn, 5)
    stroke(dropBtn, C.Border, 1)
    local dpPad = Instance.new("UIPadding", dropBtn)
    dpPad.PaddingLeft = UDim.new(0, 8)
    dpPad.PaddingRight = UDim.new(0, 4)

    local specBtn = Instance.new("TextButton")
    specBtn.Size = UDim2.new(0, 42, 1, 0)
    specBtn.Position = UDim2.new(0, 104, 0, 0)
    specBtn.BackgroundColor3 = C.Row
    specBtn.Font = Enum.Font.GothamBold
    specBtn.TextSize = 9
    specBtn.Text = "SPEC"
    specBtn.TextColor3 = C.Dim
    specBtn.ZIndex = 21
    specBtn.Parent = selectorRow
    corner(specBtn, 5)
    stroke(specBtn, C.Border, 1)

    local camModes = {"Free","Lock","Orb","3rd"}
    local camKeys  = {"free","locked","orbit","third"}
    local camBtns  = {}
    local camX = 150
    for i, lbl2 in ipairs(camModes) do
        local cb = Instance.new("TextButton")
        cb.Size = UDim2.new(0, 28, 1, 0)
        cb.Position = UDim2.new(0, camX + (i-1)*31, 0, 0)
        cb.BackgroundColor3 = (i==1) and C.AccentBg or C.Row
        cb.Font = Enum.Font.GothamBold
        cb.TextSize = 8
        cb.Text = lbl2
        cb.TextColor3 = (i==1) and C.AccentFg or C.Dim
        cb.ZIndex = 21
        cb.Parent = selectorRow
        corner(cb, 5)
        camBtns[camKeys[i]] = cb
    end

    local function setCamModeUI(mode)
        for _, k in ipairs(camKeys) do
            local active = (k == mode)
            camBtns[k].BackgroundColor3 = active and C.AccentBg or C.Row
            camBtns[k].TextColor3       = active and C.AccentFg or C.Dim
        end
    end

    for _, k in ipairs(camKeys) do
        camBtns[k].MouseButton1Click:Connect(function()
            Troll:SetSpectateMode(k)
            setCamModeUI(k)
            if Troll:IsSpectating() then
                Notif:Send("Cam: " .. k, 1)
            end
        end)
    end

    -- SPEC toggle
    local function refreshSpecToggle()
        local isSpec = Troll:IsSpectating() and Troll:GetSpectateTarget() == Troll:GetTarget()
        specBtn.BackgroundColor3 = isSpec and C.AccentBg or C.Row
        specBtn.TextColor3       = isSpec and C.AccentFg or C.Dim
    end

    specBtn.MouseButton1Click:Connect(function()
        local tgt = Troll:GetTarget()
        if not tgt then Notif:Send("Select a target first!", 2); return end
        if Troll:IsSpectating() and Troll:GetSpectateTarget() == tgt then
            Troll:StopSpectate()
            Notif:Send("Spectate OFF", 1)
        else
            local ok = Troll:StartSpectate(tgt, Troll:GetSpectateMode())
            if ok then Notif:Send("Spectating " .. tgt.Name, 2) end
        end
        refreshSpecToggle()
    end)

    -- Dropdown popup (floats over hub content)
    local dropPopup = Instance.new("Frame")
    dropPopup.Size = UDim2.new(1, -8, 0, 0)
    dropPopup.Position = UDim2.new(0, 4, 0, 84)
    dropPopup.BackgroundColor3 = C.Panel
    dropPopup.ZIndex = 50
    dropPopup.Visible = false
    dropPopup.AutomaticSize = Enum.AutomaticSize.Y
    dropPopup.Parent = hub
    corner(dropPopup, 6)
    stroke(dropPopup, C.Border, 1)

    local dpLayout = Instance.new("UIListLayout", dropPopup)
    dpLayout.SortOrder = Enum.SortOrder.LayoutOrder
    dpLayout.Padding = UDim.new(0, 2)
    local dpPadding2 = Instance.new("UIPadding", dropPopup)
    dpPadding2.PaddingTop    = UDim.new(0, 4)
    dpPadding2.PaddingBottom = UDim.new(0, 4)
    dpPadding2.PaddingLeft   = UDim.new(0, 4)
    dpPadding2.PaddingRight  = UDim.new(0, 4)

    local dropOpen = false
    local function closeDrop() dropOpen = false; dropPopup.Visible = false end

    local function buildDropdown()
        for _, ch in pairs(dropPopup:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        local plrs = Players:GetPlayers()
        local any = false
        for _, p in ipairs(plrs) do
            if p ~= player then
                any = true
                local capP = p
                local isSel = Troll:GetTarget() == capP
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 26)
                btn.BackgroundColor3 = isSel and C.AccentBg or C.Row
                btn.Font = Enum.Font.GothamBold
                btn.TextSize = 10
                btn.Text = capP.DisplayName .. " (@" .. capP.Name .. ")"
                btn.TextColor3 = isSel and C.AccentFg or C.Text
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.ZIndex = 51
                btn.Parent = dropPopup
                corner(btn, 4)
                local bPad = Instance.new("UIPadding", btn)
                bPad.PaddingLeft = UDim.new(0, 8)
                btn.MouseButton1Click:Connect(function()
                    if Troll:IsSpectating() then Troll:StopSpectate() end
                    Troll:SetTarget(capP)
                    targetLabel.Text = capP.DisplayName .. " (@" .. capP.Name .. ")"
                    targetLabel.TextColor3 = C.White
                    dropBtn.Text = capP.DisplayName .. " ▼"
                    dropBtn.TextColor3 = C.White
                    Notif:Send("Target: " .. capP.Name, 2)
                    refreshSpecToggle()
                    closeDrop()
                end)
            end
        end
        if not any then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, 0, 0, 22)
            empty.BackgroundTransparency = 1
            empty.Text = "No other players in server."
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 9
            empty.TextColor3 = C.Dim
            empty.ZIndex = 51
            empty.Parent = dropPopup
        end
    end

    dropBtn.MouseButton1Click:Connect(function()
        dropOpen = not dropOpen
        if dropOpen then buildDropdown(); dropPopup.Visible = true
        else closeDrop() end
    end)

    -- ── SCARE section ─────────────────────────────────────────
    sectionHeader("SCARE", 4):LayoutOrder = 4

    -- Type selector
    local typeRow = Instance.new("Frame")
    typeRow.Size = UDim2.new(1, 0, 0, 30)
    typeRow.BackgroundColor3 = C.Panel
    typeRow.LayoutOrder = 5
    typeRow.ZIndex = 20
    typeRow.Parent = body
    corner(typeRow, 6)
    stroke(typeRow, C.Border, 1)

    local typePad = Instance.new("UIPadding", typeRow)
    typePad.PaddingLeft  = UDim.new(0, 4)
    typePad.PaddingRight = UDim.new(0, 4)

    local scareTypes = {"Scare", "Rush", "Combo"}
    local typeBtns = {}
    local selectedType = "Scare"

    local typeLayout = Instance.new("UIListLayout", typeRow)
    typeLayout.FillDirection = Enum.FillDirection.Horizontal
    typeLayout.SortOrder = Enum.SortOrder.LayoutOrder
    typeLayout.Padding = UDim.new(0, 4)
    typeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    typeLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    for i, t in ipairs(scareTypes) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 74, 0, 22)
        btn.BackgroundColor3 = (i==1) and C.AccentBg or C.Row
        btn.Text = t:upper()
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.TextColor3 = (i==1) and C.AccentFg or C.Dim
        btn.ZIndex = 21
        btn.LayoutOrder = i
        btn.Parent = typeRow
        corner(btn, 4)
        typeBtns[t] = btn
    end

    local function selectType(key)
        selectedType = key
        for _, t in ipairs(scareTypes) do
            local active = (t == key)
            typeBtns[t].BackgroundColor3 = active and C.AccentBg or C.Row
            typeBtns[t].TextColor3       = active and C.AccentFg or C.Dim
        end
    end

    for _, t in ipairs(scareTypes) do
        local capT = t
        typeBtns[capT].MouseButton1Click:Connect(function() selectType(capT) end)
    end

    -- ── Settings cards ────────────────────────────────────────
    local settingsHolder = Instance.new("Frame")
    settingsHolder.Size = UDim2.new(1, 0, 0, 0)
    settingsHolder.AutomaticSize = Enum.AutomaticSize.Y
    settingsHolder.BackgroundTransparency = 1
    settingsHolder.LayoutOrder = 6
    settingsHolder.ZIndex = 20
    settingsHolder.Parent = body

    local shLayout = Instance.new("UIListLayout", settingsHolder)
    shLayout.SortOrder = Enum.SortOrder.LayoutOrder
    shLayout.Padding = UDim.new(0, 4)

    -- Scare card
    local cardScare = Instance.new("Frame")
    cardScare.Size = UDim2.new(1, 0, 0, 0)
    cardScare.AutomaticSize = Enum.AutomaticSize.Y
    cardScare.BackgroundColor3 = C.Panel
    cardScare.LayoutOrder = 1
    cardScare.Visible = true
    cardScare.ZIndex = 21
    cardScare.Parent = settingsHolder
    corner(cardScare, 6)
    stroke(cardScare, C.Border, 1)

    local cardScarePad = Instance.new("UIPadding", cardScare)
    cardScarePad.PaddingTop    = UDim.new(0, 4)
    cardScarePad.PaddingBottom = UDim.new(0, 6)
    cardScarePad.PaddingLeft   = UDim.new(0, 6)
    cardScarePad.PaddingRight  = UDim.new(0, 6)

    local cardScareLayout = Instance.new("UIListLayout", cardScare)
    cardScareLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cardScareLayout.Padding = UDim.new(0, 4)

    local holdTimeBox = inputRow(cardScare, 1, "Hold Time (s):", Troll.scareHoldTime or 1)
    local studBox     = inputRow(cardScare, 2, "Distance (studs):", Troll.scareDistance or 6)

    -- Emote row
    local emoteRow = Instance.new("Frame")
    emoteRow.Size = UDim2.new(1, 0, 0, 28)
    emoteRow.BackgroundColor3 = C.Row
    emoteRow.LayoutOrder = 3
    emoteRow.ZIndex = 21
    emoteRow.Parent = cardScare
    corner(emoteRow, 5)

    local emoteLbl = Instance.new("TextLabel")
    emoteLbl.Size = UDim2.new(0.4, 0, 1, 0)
    emoteLbl.Position = UDim2.new(0, 10, 0, 0)
    emoteLbl.BackgroundTransparency = 1
    emoteLbl.Text = "Emote:"
    emoteLbl.Font = Enum.Font.Gotham
    emoteLbl.TextSize = 10
    emoteLbl.TextColor3 = C.Dim
    emoteLbl.TextXAlignment = Enum.TextXAlignment.Left
    emoteLbl.ZIndex = 22
    emoteLbl.Parent = emoteRow

    local selectedEmote = nil

    local emotePickBtn = Instance.new("TextButton")
    emotePickBtn.Size = UDim2.new(0, 100, 0, 20)
    emotePickBtn.Position = UDim2.new(1, -106, 0.5, -10)
    emotePickBtn.BackgroundColor3 = C.Row
    emotePickBtn.Text = "none ▼"
    emotePickBtn.Font = Enum.Font.GothamBold
    emotePickBtn.TextSize = 9
    emotePickBtn.TextColor3 = C.Dim
    emotePickBtn.ZIndex = 22
    emotePickBtn.Parent = emoteRow
    corner(emotePickBtn, 4)
    stroke(emotePickBtn, C.Border, 1)

    -- Auto emote toggle row
    local autoEmoteRow = Instance.new("Frame")
    autoEmoteRow.Size = UDim2.new(1, 0, 0, 28)
    autoEmoteRow.BackgroundColor3 = C.Row
    autoEmoteRow.LayoutOrder = 4
    autoEmoteRow.ZIndex = 21
    autoEmoteRow.Parent = cardScare
    corner(autoEmoteRow, 5)

    local autoEmotelbl = Instance.new("TextLabel")
    autoEmotelbl.Size = UDim2.new(0.7, 0, 1, 0)
    autoEmotelbl.Position = UDim2.new(0, 10, 0, 0)
    autoEmotelbl.BackgroundTransparency = 1
    autoEmotelbl.Text = "Auto Emote"
    autoEmotelbl.Font = Enum.Font.Gotham
    autoEmotelbl.TextSize = 10
    autoEmotelbl.TextColor3 = C.Dim
    autoEmotelbl.TextXAlignment = Enum.TextXAlignment.Left
    autoEmotelbl.ZIndex = 22
    autoEmotelbl.Parent = autoEmoteRow

    -- Mini pill toggle
    local autoEmoteToggle = Instance.new("TextButton")
    autoEmoteToggle.Size = UDim2.new(0, 38, 0, 18)
    autoEmoteToggle.Position = UDim2.new(1, -44, 0.5, -9)
    autoEmoteToggle.BackgroundColor3 = C.Row
    autoEmoteToggle.Text = "OFF"
    autoEmoteToggle.Font = Enum.Font.GothamBold
    autoEmoteToggle.TextSize = 8
    autoEmoteToggle.TextColor3 = C.Dim
    autoEmoteToggle.ZIndex = 22
    autoEmoteToggle.Parent = autoEmoteRow
    corner(autoEmoteToggle, 5)
    stroke(autoEmoteToggle, C.Border, 1)

    local autoEmoteOn = false
    local autoEmoteConn = nil

    local function setAutoEmote(state)
        autoEmoteOn = state
        if state then
            tween(autoEmoteToggle, {BackgroundColor3 = C.AccentBg}, 0.18)
            autoEmoteToggle.TextColor3 = C.AccentFg
            autoEmoteToggle.Text = "ON"
            autoEmoteConn = RunService.Heartbeat:Connect(function()
                if not selectedEmote then return end
                pcall(function()
                    local hum = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
                    if hum then hum:PlayEmote(selectedEmote) end
                end)
            end)
        else
            tween(autoEmoteToggle, {BackgroundColor3 = C.Row}, 0.18)
            autoEmoteToggle.TextColor3 = C.Dim
            autoEmoteToggle.Text = "OFF"
            if autoEmoteConn then autoEmoteConn:Disconnect(); autoEmoteConn = nil end
        end
    end

    autoEmoteToggle.MouseButton1Click:Connect(function()
        if not selectedEmote and not autoEmoteOn then Notif:Send("Select an emote first!", 2); return end
        setAutoEmote(not autoEmoteOn)
    end)

    -- Emote dropdown popup
    local emotePopup = Instance.new("Frame")
    emotePopup.Size = UDim2.new(1, -8, 0, 160)
    emotePopup.Position = UDim2.new(0, 4, 0, 270)
    emotePopup.BackgroundColor3 = C.Panel
    emotePopup.ZIndex = 40
    emotePopup.Visible = false
    emotePopup.Parent = hub
    corner(emotePopup, 6)
    stroke(emotePopup, C.Border, 1)

    local epTopRow = Instance.new("Frame")
    epTopRow.Size = UDim2.new(1, 0, 0, 24)
    epTopRow.BackgroundTransparency = 1
    epTopRow.ZIndex = 41
    epTopRow.Parent = emotePopup

    local epTitle = Instance.new("TextLabel")
    epTitle.Size = UDim2.new(1, -30, 1, 0)
    epTitle.Position = UDim2.new(0, 10, 0, 0)
    epTitle.BackgroundTransparency = 1
    epTitle.Text = "Select Emote"
    epTitle.Font = Enum.Font.GothamBold
    epTitle.TextSize = 10
    epTitle.TextColor3 = C.Text
    epTitle.TextXAlignment = Enum.TextXAlignment.Left
    epTitle.ZIndex = 42
    epTitle.Parent = epTopRow

    local epClose = Instance.new("TextButton")
    epClose.Size = UDim2.new(0, 20, 0, 20)
    epClose.Position = UDim2.new(1, -24, 0.5, -10)
    epClose.BackgroundColor3 = C.Row
    epClose.Text = "✕"
    epClose.Font = Enum.Font.GothamBold
    epClose.TextSize = 9
    epClose.TextColor3 = C.Dim
    epClose.ZIndex = 42
    epClose.Parent = epTopRow
    corner(epClose, 4)
    epClose.MouseButton1Click:Connect(function() emotePopup.Visible = false end)

    local emoteScroll = Instance.new("ScrollingFrame")
    emoteScroll.Size = UDim2.new(1, -8, 1, -28)
    emoteScroll.Position = UDim2.new(0, 4, 0, 26)
    emoteScroll.BackgroundTransparency = 1
    emoteScroll.BorderSizePixel = 0
    emoteScroll.ScrollBarThickness = 2
    emoteScroll.ScrollBarImageColor3 = C.Border
    emoteScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    emoteScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    emoteScroll.ZIndex = 41
    emoteScroll.Parent = emotePopup
    local emoteListLayout = Instance.new("UIListLayout", emoteScroll)
    emoteListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    emoteListLayout.Padding = UDim.new(0, 3)

    local emoteRowBtns = {}

    local function buildEmoteList()
        for _, v in pairs(emoteScroll:GetChildren()) do
            if v:IsA("TextButton") then v:Destroy() end
        end
        emoteRowBtns = {}
        local ok2, emotes = pcall(function()
            local hd = Players:GetHumanoidDescriptionFromUserId(player.UserId)
            local list = {}
            for _, e in ipairs(hd:GetEquippedEmotes()) do
                table.insert(list, {name=e.Name, id=e.AssetId})
            end
            return list
        end)
        if not ok2 or not emotes or #emotes == 0 then
            local noE = Instance.new("TextLabel")
            noE.Size = UDim2.new(1, 0, 0, 22)
            noE.BackgroundTransparency = 1
            noE.Text = "No equipped emotes."
            noE.Font = Enum.Font.Gotham
            noE.TextSize = 9
            noE.TextColor3 = C.Dim
            noE.ZIndex = 42
            noE.Parent = emoteScroll
            return
        end
        for _, emote in ipairs(emotes) do
            local capEmote = emote
            local eBtn = Instance.new("TextButton")
            eBtn.Size = UDim2.new(1, 0, 0, 24)
            eBtn.BackgroundColor3 = (selectedEmote == capEmote.name) and C.AccentBg or C.Row
            eBtn.Text = capEmote.name
            eBtn.Font = Enum.Font.GothamBold
            eBtn.TextSize = 9
            eBtn.TextColor3 = (selectedEmote == capEmote.name) and C.AccentFg or C.Text
            eBtn.TextXAlignment = Enum.TextXAlignment.Left
            eBtn.ZIndex = 42
            eBtn.Parent = emoteScroll
            corner(eBtn, 4)
            local ePad = Instance.new("UIPadding", eBtn)
            ePad.PaddingLeft = UDim.new(0, 8)
            emoteRowBtns[capEmote.name] = eBtn
            eBtn.MouseButton1Click:Connect(function()
                for _, b in pairs(emoteRowBtns) do
                    b.BackgroundColor3 = C.Row
                    b.TextColor3 = C.Text
                end
                selectedEmote = capEmote.name
                emotePickBtn.Text = capEmote.name .. " ▼"
                emotePickBtn.TextColor3 = C.White
                eBtn.BackgroundColor3 = C.AccentBg
                eBtn.TextColor3 = C.AccentFg
                emotePopup.Visible = false
                pcall(function()
                    local hum = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
                    if hum then hum:PlayEmote(capEmote.name) end
                end)
            end)
        end
    end

    emotePickBtn.MouseButton1Click:Connect(function()
        buildEmoteList()
        emotePopup.Visible = not emotePopup.Visible
    end)

    holdTimeBox.FocusLost:Connect(function()
        local v = tonumber(holdTimeBox.Text)
        if v and v > 0 then Troll.scareHoldTime = math.clamp(v, 0.1, 5)
        else holdTimeBox.Text = tostring(Troll.scareHoldTime or 1) end
    end)
    studBox.FocusLost:Connect(function()
        local v = tonumber(studBox.Text)
        if v and v > 0 then Troll.scareDistance = math.clamp(v, 1, 30)
        else studBox.Text = tostring(Troll.scareDistance or 6) end
    end)

    -- Rush card
    local cardRush = Instance.new("Frame")
    cardRush.Size = UDim2.new(1, 0, 0, 0)
    cardRush.AutomaticSize = Enum.AutomaticSize.Y
    cardRush.BackgroundColor3 = C.Panel
    cardRush.LayoutOrder = 2
    cardRush.Visible = false
    cardRush.ZIndex = 21
    cardRush.Parent = settingsHolder
    corner(cardRush, 6)
    stroke(cardRush, C.Border, 1)

    local cardRushPad = Instance.new("UIPadding", cardRush)
    cardRushPad.PaddingTop    = UDim.new(0, 4)
    cardRushPad.PaddingBottom = UDim.new(0, 6)
    cardRushPad.PaddingLeft   = UDim.new(0, 6)
    cardRushPad.PaddingRight  = UDim.new(0, 6)

    local cardRushLayout = Instance.new("UIListLayout", cardRush)
    cardRushLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cardRushLayout.Padding = UDim.new(0, 4)

    local rushSpeedBox = inputRow(cardRush, 1, "Rush Speed:", Troll.rushSpeed or 100)
    local rushHoldBox  = inputRow(cardRush, 2, "Hold Time (s):", Troll.rushHoldTime or 1)

    rushSpeedBox.FocusLost:Connect(function()
        local v = tonumber(rushSpeedBox.Text)
        if v and v > 0 then Troll.rushSpeed = math.clamp(v, 10, 500)
        else rushSpeedBox.Text = tostring(Troll.rushSpeed or 100) end
    end)
    rushHoldBox.FocusLost:Connect(function()
        local v = tonumber(rushHoldBox.Text)
        if v and v > 0 then Troll.rushHoldTime = math.clamp(v, 0.1, 5)
        else rushHoldBox.Text = tostring(Troll.rushHoldTime or 1) end
    end)

    -- Combo card
    local cardCombo = Instance.new("Frame")
    cardCombo.Size = UDim2.new(1, 0, 0, 0)
    cardCombo.AutomaticSize = Enum.AutomaticSize.Y
    cardCombo.BackgroundColor3 = C.Panel
    cardCombo.LayoutOrder = 3
    cardCombo.Visible = false
    cardCombo.ZIndex = 21
    cardCombo.Parent = settingsHolder
    corner(cardCombo, 6)
    stroke(cardCombo, C.Border, 1)

    local cardComboPad = Instance.new("UIPadding", cardCombo)
    cardComboPad.PaddingTop    = UDim.new(0, 4)
    cardComboPad.PaddingBottom = UDim.new(0, 6)
    cardComboPad.PaddingLeft   = UDim.new(0, 6)
    cardComboPad.PaddingRight  = UDim.new(0, 6)

    local cardComboLayout = Instance.new("UIListLayout", cardCombo)
    cardComboLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cardComboLayout.Padding = UDim.new(0, 4)

    local comboAppearBox = inputRow(cardCombo, 1, "Appear Dist:", Troll.comboAppearDist or 10)
    local comboSpeedBox  = inputRow(cardCombo, 2, "Chase Speed:", Troll.comboRushSpeed or 100)
    local comboHoldBox   = inputRow(cardCombo, 3, "Hold Time (s):", Troll.comboHoldTime or 1)

    comboAppearBox.FocusLost:Connect(function()
        local v = tonumber(comboAppearBox.Text)
        if v and v > 0 then Troll.comboAppearDist = math.clamp(v, 1, 30)
        else comboAppearBox.Text = tostring(Troll.comboAppearDist or 10) end
    end)
    comboSpeedBox.FocusLost:Connect(function()
        local v = tonumber(comboSpeedBox.Text)
        if v and v > 0 then Troll.comboRushSpeed = math.clamp(v, 10, 500)
        else comboSpeedBox.Text = tostring(Troll.comboRushSpeed or 100) end
    end)
    comboHoldBox.FocusLost:Connect(function()
        local v = tonumber(comboHoldBox.Text)
        if v and v > 0 then Troll.comboHoldTime = math.clamp(v, 0.1, 5)
        else comboHoldBox.Text = tostring(Troll.comboHoldTime or 1) end
    end)

    -- Switch cards on type select
    local cards = {Scare=cardScare, Rush=cardRush, Combo=cardCombo}
    for _, t in ipairs(scareTypes) do
        local capT = t
        typeBtns[capT].MouseButton1Click:Connect(function()
            for _, tc in ipairs(scareTypes) do
                cards[tc].Visible = (tc == capT)
            end
        end)
    end

    -- ── GO button ─────────────────────────────────────────────
    local goBtn = Instance.new("TextButton")
    goBtn.Size = UDim2.new(1, 0, 0, 36)
    goBtn.BackgroundColor3 = C.AccentBg
    goBtn.Text = "GO"
    goBtn.TextColor3 = C.AccentFg
    goBtn.Font = Enum.Font.GothamBold
    goBtn.TextSize = 14
    goBtn.LayoutOrder = 7
    goBtn.ZIndex = 21
    goBtn.Parent = body
    corner(goBtn, 6)

    local function setGoReady(ready)
        if ready then
            tween(goBtn, {BackgroundColor3 = C.AccentBg}, 0.2)
            goBtn.TextColor3 = C.AccentFg
            goBtn.Text = "GO"
        else
            tween(goBtn, {BackgroundColor3 = C.Row}, 0.2)
            goBtn.TextColor3 = C.Dim
            goBtn.Text = "Cooldown..."
        end
    end

    goBtn.MouseButton1Click:Connect(function()
        closeDrop()
        if not Troll:GetTarget() then Notif:Send("No target selected!", 2); return end
        local name = Troll:GetTarget().Name
        if selectedType == "Scare" then
            if Troll:IsScareCooldown() then return end
            local ok = Troll:ScareOnce()
            if ok then setGoReady(false); Notif:Send("Scaring " .. name, 2) end
        elseif selectedType == "Rush" then
            if Troll:IsRushCooldown() then return end
            local ok = Troll:RushScare()
            if ok then setGoReady(false); Notif:Send("Rushing " .. name, 2) end
        elseif selectedType == "Combo" then
            if Troll:IsComboCooldown() then return end
            local ok = Troll:ComboScare()
            if ok then setGoReady(false); Notif:Send("Combo on " .. name, 2) end
        end
    end)

    -- Ready callbacks
    Troll.onScareReady = function()
        if selectedType == "Scare" then setGoReady(true); Notif:Send("Scare ready!", 2) end
    end
    Troll.onRushReady = function()
        if selectedType == "Rush" then setGoReady(true); Notif:Send("Rush ready!", 2) end
    end
    Troll.onComboReady = function()
        if selectedType == "Combo" then setGoReady(true); Notif:Send("Combo ready!", 2) end
    end

    -- Spectate callback
    Troll.onSpectateChanged = function(specPlayer)
        if specPlayer then
            targetLabel.Text = "Spectating: " .. specPlayer.DisplayName
            targetLabel.TextColor3 = C.White
        else
            local tgt = Troll:GetTarget()
            if tgt then
                targetLabel.Text = tgt.DisplayName .. " (@" .. tgt.Name .. ")"
                targetLabel.TextColor3 = C.White
            else
                targetLabel.Text = "No target selected"
                targetLabel.TextColor3 = C.Dim
            end
        end
        refreshSpecToggle()
    end

    -- ── Minimize + Close ──────────────────────────────────────
    local minimized = false
    local savedH = HUB_H

    hubMinimize.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            savedH = hub.AbsoluteSize.Y
            tween(hub, {Size = UDim2.new(0, HUB_W, 0, 38)}, 0.22, Enum.EasingStyle.Quad)
            hubMinimize.Text = "+"
        else
            tween(hub, {Size = UDim2.new(0, HUB_W, 0, savedH)}, 0.28, Enum.EasingStyle.Back)
            hubMinimize.Text = "—"
        end
    end)

    hubClose.MouseButton1Click:Connect(function()
        closeDrop()
        hub.Visible = false
        CONFIG.Scare = false
        if toggleSyncs["Scare"] then toggleSyncs["Scare"](false) end
    end)

    -- Return hub frame so main script can control visibility
    return hub
end

return UI
