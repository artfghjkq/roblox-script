-- ui.lua
-- ScareHub UI – galaxy theme matching main HUB

local UI = {}

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local player = Players.LocalPlayer

-- ── Helpers ───────────────────────────────────────────────────
local function corner(obj, r)
    local c = Instance.new("UICorner", obj)
    c.CornerRadius = UDim.new(0, r or 8)
    return c
end

local function stroke(obj, col, t)
    local s = Instance.new("UIStroke", obj)
    s.Color = col
    s.Thickness = t or 1
    return s
end

local function tw(obj, props, dur, style)
    if not obj or not obj.Parent then return end
    pcall(function()
        TweenService:Create(obj, TweenInfo.new(
            dur or 0.18,
            style or Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ), props):Play()
    end)
end

-- ── Input row ─────────────────────────────────────────────────
local function inputRow(parent, lo, lTxt, default, C)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundColor3 = C.DarkBG
    row.LayoutOrder = lo
    row.ZIndex = 21
    row.Parent = parent
    corner(row, 5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -64, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = lTxt
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 9
    lbl.TextColor3 = Color3.fromRGB(160, 140, 180)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 22
    lbl.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 50, 0, 18)
    box.Position = UDim2.new(1, -56, 0.5, -9)
    box.BackgroundColor3 = C.Background
    box.Text = tostring(default)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 10
    box.TextColor3 = C.White
    box.ClearTextOnFocus = false
    box.TextXAlignment = Enum.TextXAlignment.Center
    box.ZIndex = 22
    box.Parent = row
    corner(box, 4)
    stroke(box, C.Galaxy1, 1)
    return box
end

-- ══════════════════════════════════════════════════════════════
-- BUILD SCARE HUB
-- ══════════════════════════════════════════════════════════════
function UI:BuildScareHub(screenGui, Troll, Notif, CONFIG, createCorner, toggleSyncs, COLORS, galaxyGradient)

    local G1  = COLORS.Galaxy1
    local G2  = COLORS.Galaxy2
    local G3  = COLORS.Galaxy3
    local GA  = COLORS.GalaxyAccent
    local BG  = COLORS.Background
    local DBG = COLORS.DarkBG
    local FRM = COLORS.Frame
    local WHT = COLORS.White
    local GRY = COLORS.Gray
    local DIM = Color3.fromRGB(160, 140, 180)

    local HUB_W = 260
    local HUB_H = 350

    -- Hub frame
    local hub = Instance.new("Frame")
    hub.Name = "ScareHub"
    hub.Size = UDim2.new(0, HUB_W, 0, HUB_H)
    hub.Position = UDim2.new(0.5, -HUB_W/2, 0.5, -HUB_H/2)
    hub.BackgroundColor3 = BG
    hub.Active = true
    hub.Draggable = true
    hub.Visible = false
    hub.ZIndex = 20
    hub.ClipsDescendants = true
    hub.Parent = screenGui
    corner(hub, 12)
    stroke(hub, G1, 2)

    -- Top bar
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 36)
    topBar.BackgroundColor3 = G1
    topBar.ZIndex = 21
    topBar.Parent = hub
    corner(topBar, 12)
    -- flat bottom
    local topFill = Instance.new("Frame")
    topFill.Size = UDim2.new(1, 0, 0.5, 0)
    topFill.Position = UDim2.new(0, 0, 0.5, 0)
    topFill.BackgroundColor3 = G1
    topFill.BorderSizePixel = 0
    topFill.ZIndex = 21
    topFill.Parent = topBar
    galaxyGradient(topBar, 90)

    local hubTitle = Instance.new("TextLabel")
    hubTitle.Size = UDim2.new(1, -70, 1, 0)
    hubTitle.Position = UDim2.new(0, 12, 0, 0)
    hubTitle.BackgroundTransparency = 1
    hubTitle.Text = "SCARE HUB"
    hubTitle.Font = Enum.Font.GothamBold
    hubTitle.TextSize = 12
    hubTitle.TextColor3 = WHT
    hubTitle.TextXAlignment = Enum.TextXAlignment.Left
    hubTitle.ZIndex = 22
    hubTitle.Parent = topBar

    local function topBtn(xOff, txt)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 22, 0, 22)
        b.Position = UDim2.new(1, xOff, 0.5, -11)
        b.BackgroundColor3 = DBG
        b.Text = txt
        b.TextColor3 = WHT
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        b.ZIndex = 22
        b.Parent = topBar
        corner(b, 5)
        return b
    end

    local hubMinimize = topBtn(-50, "—")
    local hubClose    = topBtn(-26, "✕")

    -- Scroll body
    local body = Instance.new("ScrollingFrame")
    body.Size = UDim2.new(1, -6, 1, -40)
    body.Position = UDim2.new(0, 3, 0, 38)
    body.BackgroundTransparency = 1
    body.BorderSizePixel = 0
    body.ScrollBarThickness = 2
    body.ScrollBarImageColor3 = G1
    body.CanvasSize = UDim2.new(0, 0, 0, 0)
    body.AutomaticCanvasSize = Enum.AutomaticSize.Y
    body.ZIndex = 20
    body.Parent = hub

    local bodyLayout = Instance.new("UIListLayout", body)
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bodyLayout.Padding = UDim.new(0, 4)

    local bodyPad = Instance.new("UIPadding", body)
    bodyPad.PaddingTop    = UDim.new(0, 4)
    bodyPad.PaddingBottom = UDim.new(0, 6)
    bodyPad.PaddingLeft   = UDim.new(0, 2)
    bodyPad.PaddingRight  = UDim.new(0, 2)

    -- Section header
    local function sectionHeader(txt, lo)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 18)
        row.BackgroundTransparency = 1
        row.LayoutOrder = lo or 0
        row.ZIndex = 20
        row.Parent = body

        local l1 = Instance.new("Frame")
        l1.Size = UDim2.new(0.1, 0, 0, 1)
        l1.Position = UDim2.new(0, 0, 0.5, 0)
        l1.BackgroundColor3 = G1
        l1.BorderSizePixel = 0
        l1.ZIndex = 20
        l1.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.8, 0, 1, 0)
        lbl.Position = UDim2.new(0.1, 0, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = txt
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 8
        lbl.TextColor3 = DIM
        lbl.ZIndex = 21
        lbl.Parent = row

        local l2 = Instance.new("Frame")
        l2.Size = UDim2.new(0.1, 0, 0, 1)
        l2.Position = UDim2.new(0.9, 0, 0.5, 0)
        l2.BackgroundColor3 = G1
        l2.BorderSizePixel = 0
        l2.ZIndex = 20
        l2.Parent = row
    end

    -- ══════════════════════════════════════════════════════════
    -- TARGET
    -- ══════════════════════════════════════════════════════════
    sectionHeader("TARGET", 1)

    local targetBadge = Instance.new("Frame")
    targetBadge.Size = UDim2.new(1, 0, 0, 26)
    targetBadge.BackgroundColor3 = FRM
    targetBadge.LayoutOrder = 2
    targetBadge.ZIndex = 20
    targetBadge.Parent = body
    corner(targetBadge, 6)
    stroke(targetBadge, G1, 1)

    local targetLabel = Instance.new("TextLabel")
    targetLabel.Size = UDim2.new(1, -10, 1, 0)
    targetLabel.Position = UDim2.new(0, 8, 0, 0)
    targetLabel.BackgroundTransparency = 1
    targetLabel.Text = "No target selected"
    targetLabel.Font = Enum.Font.GothamBold
    targetLabel.TextSize = 10
    targetLabel.TextColor3 = DIM
    targetLabel.TextXAlignment = Enum.TextXAlignment.Left
    targetLabel.TextTruncate = Enum.TextTruncate.AtEnd
    targetLabel.ZIndex = 21
    targetLabel.Parent = targetBadge

    -- Selector row
    local selectorRow = Instance.new("Frame")
    selectorRow.Size = UDim2.new(1, 0, 0, 24)
    selectorRow.BackgroundTransparency = 1
    selectorRow.LayoutOrder = 3
    selectorRow.ZIndex = 20
    selectorRow.Parent = body

    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(0, 88, 1, 0)
    dropBtn.Position = UDim2.new(0, 0, 0, 0)
    dropBtn.BackgroundColor3 = FRM
    dropBtn.Font = Enum.Font.GothamBold
    dropBtn.TextSize = 8
    dropBtn.Text = "Select ▼"
    dropBtn.TextColor3 = DIM
    dropBtn.TextTruncate = Enum.TextTruncate.AtEnd
    dropBtn.ZIndex = 21
    dropBtn.Parent = selectorRow
    corner(dropBtn, 5)
    stroke(dropBtn, G1, 1)
    Instance.new("UIPadding", dropBtn).PaddingLeft = UDim.new(0, 6)

    local specBtn = Instance.new("TextButton")
    specBtn.Size = UDim2.new(0, 34, 1, 0)
    specBtn.Position = UDim2.new(0, 92, 0, 0)
    specBtn.BackgroundColor3 = FRM
    specBtn.Font = Enum.Font.GothamBold
    specBtn.TextSize = 8
    specBtn.Text = "SPEC"
    specBtn.TextColor3 = DIM
    specBtn.ZIndex = 21
    specBtn.Parent = selectorRow
    corner(specBtn, 5)
    stroke(specBtn, G1, 1)

    local camModes = {"Free","Lock","Orb","3rd"}
    local camKeys  = {"free","locked","orbit","third"}
    local camBtns  = {}
    for i, lbl2 in ipairs(camModes) do
        local cb = Instance.new("TextButton")
        cb.Size = UDim2.new(0, 26, 1, 0)
        cb.Position = UDim2.new(0, 130 + (i-1)*29, 0, 0)
        cb.BackgroundColor3 = (i==1) and G1 or FRM
        cb.Font = Enum.Font.GothamBold
        cb.TextSize = 7
        cb.Text = lbl2
        cb.TextColor3 = (i==1) and WHT or DIM
        cb.ZIndex = 21
        cb.Parent = selectorRow
        corner(cb, 4)
        camBtns[camKeys[i]] = cb
    end

    local function setCamModeUI(mode)
        for _, k in ipairs(camKeys) do
            local on = (k == mode)
            camBtns[k].BackgroundColor3 = on and G1 or FRM
            camBtns[k].TextColor3       = on and WHT or DIM
        end
    end
    for _, k in ipairs(camKeys) do
        local capK = k
        camBtns[capK].MouseButton1Click:Connect(function()
            Troll:SetSpectateMode(capK)
            setCamModeUI(capK)
            if Troll:IsSpectating() then Notif:Send("Cam: "..capK, 1) end
        end)
    end

    local function refreshSpecToggle()
        local on = Troll:IsSpectating() and Troll:GetSpectateTarget() == Troll:GetTarget()
        specBtn.BackgroundColor3 = on and G1 or FRM
        specBtn.TextColor3       = on and WHT or DIM
    end

    specBtn.MouseButton1Click:Connect(function()
        local tgt = Troll:GetTarget()
        if not tgt then Notif:Send("Select a target first!", 2); return end
        if Troll:IsSpectating() and Troll:GetSpectateTarget() == tgt then
            Troll:StopSpectate()
            Notif:Send("Spectate OFF", 1)
        else
            if Troll:StartSpectate(tgt, Troll:GetSpectateMode()) then
                Notif:Send("Spectating "..tgt.Name, 2)
            end
        end
        refreshSpecToggle()
    end)

    -- ── Dropdown popup (scrollable, fixed doubling) ───────────
    -- Parent is hub (not body) so it floats above body content
    local dropPopup = Instance.new("Frame")
    dropPopup.Name = "DropPopup"
    dropPopup.Size = UDim2.new(1, -4, 0, 110)
    dropPopup.Position = UDim2.new(0, 2, 0, 68)  -- just below selector row
    dropPopup.BackgroundColor3 = DBG
    dropPopup.ZIndex = 60
    dropPopup.Visible = false
    dropPopup.ClipsDescendants = true
    dropPopup.Parent = hub
    corner(dropPopup, 6)
    stroke(dropPopup, G1, 1)

    local dpScroll = Instance.new("ScrollingFrame")
    dpScroll.Size = UDim2.new(1, 0, 1, 0)
    dpScroll.BackgroundTransparency = 1
    dpScroll.BorderSizePixel = 0
    dpScroll.ScrollBarThickness = 2
    dpScroll.ScrollBarImageColor3 = G1
    dpScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    dpScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    dpScroll.ZIndex = 61
    dpScroll.Parent = dropPopup

    local dpLayout = Instance.new("UIListLayout", dpScroll)
    dpLayout.SortOrder = Enum.SortOrder.LayoutOrder
    dpLayout.Padding = UDim.new(0, 2)
    local dpPad = Instance.new("UIPadding", dpScroll)
    dpPad.PaddingTop    = UDim.new(0, 4)
    dpPad.PaddingBottom = UDim.new(0, 4)
    dpPad.PaddingLeft   = UDim.new(0, 4)
    dpPad.PaddingRight  = UDim.new(0, 4)

    local dropOpen = false
    local function closeDrop()
        dropOpen = false
        dropPopup.Visible = false
    end

    local function buildDropdown()
        -- Always clear first — prevents doubling
        for _, ch in pairs(dpScroll:GetChildren()) do
            if ch:IsA("GuiObject") and not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
                ch:Destroy()
            end
        end

        local any = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                any = true
                local capP = p
                local isSel = Troll:GetTarget() == capP
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 26)
                btn.BackgroundColor3 = isSel and G1 or FRM
                btn.Font = Enum.Font.GothamBold
                btn.TextSize = 9
                btn.Text = capP.DisplayName.." (@"..capP.Name..")"
                btn.TextColor3 = WHT
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.TextTruncate = Enum.TextTruncate.AtEnd
                btn.ZIndex = 62
                btn.Parent = dpScroll
                corner(btn, 4)
                local bPad = Instance.new("UIPadding", btn)
                bPad.PaddingLeft = UDim.new(0, 8)

                btn.MouseButton1Click:Connect(function()
                    if Troll:IsSpectating() then Troll:StopSpectate() end
                    Troll:SetTarget(capP)
                    targetLabel.Text = capP.DisplayName.." (@"..capP.Name..")"
                    targetLabel.TextColor3 = WHT
                    dropBtn.Text = capP.DisplayName.." ▼"
                    dropBtn.TextColor3 = WHT
                    Notif:Send("Target: "..capP.Name, 2)
                    local ok = Troll:StartSpectate(capP, Troll:GetSpectateMode())
                    if ok then Notif:Send("Spectating "..capP.Name, 2) end
                    refreshSpecToggle()
                    closeDrop()
                end)
            end
        end

        if not any then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, 0, 0, 22)
            empty.BackgroundTransparency = 1
            empty.Text = "No other players."
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 9
            empty.TextColor3 = DIM
            empty.ZIndex = 62
            empty.Parent = dpScroll
        end
    end

    dropBtn.MouseButton1Click:Connect(function()
        dropOpen = not dropOpen
        if dropOpen then
            buildDropdown()
            dropPopup.Visible = true
        else
            closeDrop()
        end
    end)

    -- ══════════════════════════════════════════════════════════
    -- SCARE
    -- ══════════════════════════════════════════════════════════
    sectionHeader("SCARE", 4)

    local typeRow = Instance.new("Frame")
    typeRow.Size = UDim2.new(1, 0, 0, 26)
    typeRow.BackgroundColor3 = FRM
    typeRow.LayoutOrder = 5
    typeRow.ZIndex = 20
    typeRow.Parent = body
    corner(typeRow, 6)
    stroke(typeRow, G1, 1)
    Instance.new("UIPadding", typeRow).PaddingLeft = UDim.new(0, 4)
    Instance.new("UIPadding", typeRow).PaddingRight = UDim.new(0, 4)

    local scareTypes = {"Scare","Rush","Combo"}
    local typeBtns   = {}
    local selectedType = "Scare"

    local tLayout = Instance.new("UIListLayout", typeRow)
    tLayout.FillDirection = Enum.FillDirection.Horizontal
    tLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tLayout.Padding = UDim.new(0, 4)
    tLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    for i, t in ipairs(scareTypes) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 66, 0, 18)
        btn.BackgroundColor3 = (i==1) and G1 or DBG
        btn.Text = t:upper()
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 9
        btn.TextColor3 = WHT
        btn.ZIndex = 21
        btn.LayoutOrder = i
        btn.Parent = typeRow
        corner(btn, 4)
        typeBtns[t] = btn
    end

    local function selectType(key)
        selectedType = key
        for _, t in ipairs(scareTypes) do
            typeBtns[t].BackgroundColor3 = (t==key) and G1 or DBG
        end
    end
    for _, t in ipairs(scareTypes) do
        local capT = t
        typeBtns[capT].MouseButton1Click:Connect(function() selectType(capT) end)
    end

    -- Cards
    local settingsHolder = Instance.new("Frame")
    settingsHolder.Size = UDim2.new(1, 0, 0, 0)
    settingsHolder.AutomaticSize = Enum.AutomaticSize.Y
    settingsHolder.BackgroundTransparency = 1
    settingsHolder.LayoutOrder = 6
    settingsHolder.ZIndex = 20
    settingsHolder.Parent = body
    local shL = Instance.new("UIListLayout", settingsHolder)
    shL.SortOrder = Enum.SortOrder.LayoutOrder
    shL.Padding = UDim.new(0, 3)

    local function makeCard(lo, visible)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 0)
        card.AutomaticSize = Enum.AutomaticSize.Y
        card.BackgroundColor3 = FRM
        card.LayoutOrder = lo
        card.Visible = visible or false
        card.ZIndex = 21
        card.Parent = settingsHolder
        corner(card, 6)
        stroke(card, G1, 1)
        local pad = Instance.new("UIPadding", card)
        pad.PaddingTop    = UDim.new(0, 4)
        pad.PaddingBottom = UDim.new(0, 4)
        pad.PaddingLeft   = UDim.new(0, 6)
        pad.PaddingRight  = UDim.new(0, 6)
        local layout = Instance.new("UIListLayout", card)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 3)
        return card
    end

    local cardScare = makeCard(1, true)
    local holdTimeBox = inputRow(cardScare, 1, "Hold Time (s):", Troll.scareHoldTime or 1, COLORS)
    local studBox     = inputRow(cardScare, 2, "Distance (studs):", Troll.scareDistance or 6, COLORS)

    holdTimeBox.FocusLost:Connect(function()
        local v = tonumber(holdTimeBox.Text)
        if v and v > 0 then Troll.scareHoldTime = math.clamp(v,0.1,5)
        else holdTimeBox.Text = tostring(Troll.scareHoldTime or 1) end
    end)
    studBox.FocusLost:Connect(function()
        local v = tonumber(studBox.Text)
        if v and v > 0 then Troll.scareDistance = math.clamp(v,1,30)
        else studBox.Text = tostring(Troll.scareDistance or 6) end
    end)

    local cardRush = makeCard(2, false)
    local rushSpeedBox = inputRow(cardRush, 1, "Rush Speed:", Troll.rushSpeed or 100, COLORS)
    local rushHoldBox  = inputRow(cardRush, 2, "Hold Time (s):", Troll.rushHoldTime or 1, COLORS)
    rushSpeedBox.FocusLost:Connect(function()
        local v = tonumber(rushSpeedBox.Text)
        if v and v > 0 then Troll.rushSpeed = math.clamp(v,10,500)
        else rushSpeedBox.Text = tostring(Troll.rushSpeed or 100) end
    end)
    rushHoldBox.FocusLost:Connect(function()
        local v = tonumber(rushHoldBox.Text)
        if v and v > 0 then Troll.rushHoldTime = math.clamp(v,0.1,5)
        else rushHoldBox.Text = tostring(Troll.rushHoldTime or 1) end
    end)

    local cardCombo = makeCard(3, false)
    local comboAppearBox = inputRow(cardCombo, 1, "Appear Dist:", Troll.comboAppearDist or 10, COLORS)
    local comboSpeedBox  = inputRow(cardCombo, 2, "Chase Speed:", Troll.comboRushSpeed or 100, COLORS)
    local comboHoldBox   = inputRow(cardCombo, 3, "Hold Time (s):", Troll.comboHoldTime or 1, COLORS)
    comboAppearBox.FocusLost:Connect(function()
        local v = tonumber(comboAppearBox.Text)
        if v and v > 0 then Troll.comboAppearDist = math.clamp(v,1,30)
        else comboAppearBox.Text = tostring(Troll.comboAppearDist or 10) end
    end)
    comboSpeedBox.FocusLost:Connect(function()
        local v = tonumber(comboSpeedBox.Text)
        if v and v > 0 then Troll.comboRushSpeed = math.clamp(v,10,500)
        else comboSpeedBox.Text = tostring(Troll.comboRushSpeed or 100) end
    end)
    comboHoldBox.FocusLost:Connect(function()
        local v = tonumber(comboHoldBox.Text)
        if v and v > 0 then Troll.comboHoldTime = math.clamp(v,0.1,5)
        else comboHoldBox.Text = tostring(Troll.comboHoldTime or 1) end
    end)

    local cards = {Scare=cardScare, Rush=cardRush, Combo=cardCombo}
    for _, t in ipairs(scareTypes) do
        local capT = t
        typeBtns[capT].MouseButton1Click:Connect(function()
            for _, tc in ipairs(scareTypes) do cards[tc].Visible = (tc==capT) end
        end)
    end

    -- ══════════════════════════════════════════════════════════
    -- GO BUTTON
    -- ══════════════════════════════════════════════════════════
    local goBtn = Instance.new("TextButton")
    goBtn.Size = UDim2.new(1, 0, 0, 30)
    goBtn.BackgroundColor3 = G1
    goBtn.Text = "GO"
    goBtn.TextColor3 = WHT
    goBtn.Font = Enum.Font.GothamBold
    goBtn.TextSize = 13
    goBtn.LayoutOrder = 7
    goBtn.ZIndex = 21
    goBtn.Parent = body
    corner(goBtn, 6)
    galaxyGradient(goBtn, 90)

    local function setGoReady(ready)
        if ready then
            tw(goBtn, {BackgroundColor3 = G1}, 0.2)
            goBtn.TextColor3 = WHT
            goBtn.Text = "GO"
        else
            tw(goBtn, {BackgroundColor3 = DBG}, 0.2)
            goBtn.TextColor3 = Color3.fromRGB(160,140,180)
            goBtn.Text = "Cooldown..."
        end
    end

    goBtn.MouseButton1Click:Connect(function()
        closeDrop()
        if not Troll:GetTarget() then Notif:Send("No target selected!", 2); return end
        local name = Troll:GetTarget().Name
        if selectedType == "Scare" then
            if Troll:IsScareCooldown() then return end
            if Troll:ScareOnce() then setGoReady(false); Notif:Send("Scaring "..name, 2) end
        elseif selectedType == "Rush" then
            if Troll:IsRushCooldown() then return end
            if Troll:RushScare() then setGoReady(false); Notif:Send("Rushing "..name, 2) end
        elseif selectedType == "Combo" then
            if Troll:IsComboCooldown() then return end
            if Troll:ComboScare() then setGoReady(false); Notif:Send("Combo on "..name, 2) end
        end
    end)

    Troll.onScareReady = function()
        if selectedType == "Scare" then setGoReady(true); Notif:Send("Scare ready!", 2) end
    end
    Troll.onRushReady = function()
        if selectedType == "Rush" then setGoReady(true); Notif:Send("Rush ready!", 2) end
    end
    Troll.onComboReady = function()
        if selectedType == "Combo" then setGoReady(true); Notif:Send("Combo ready!", 2) end
    end

    Troll.onSpectateChanged = function(specPlayer)
        if specPlayer then
            targetLabel.Text = "👁 "..specPlayer.DisplayName
            targetLabel.TextColor3 = WHT
        else
            local tgt = Troll:GetTarget()
            if tgt then
                targetLabel.Text = tgt.DisplayName.." (@"..tgt.Name..")"
                targetLabel.TextColor3 = WHT
            else
                targetLabel.Text = "No target selected"
                targetLabel.TextColor3 = DIM
            end
        end
        refreshSpecToggle()
    end

    -- Minimize + Close
    local minimized = false
    local savedH = HUB_H

    hubMinimize.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            savedH = hub.AbsoluteSize.Y
            tw(hub, {Size = UDim2.new(0, HUB_W, 0, 36)}, 0.2)
            hubMinimize.Text = "+"
            closeDrop()
        else
            tw(hub, {Size = UDim2.new(0, HUB_W, 0, savedH)}, 0.25, Enum.EasingStyle.Back)
            hubMinimize.Text = "—"
        end
    end)

    hubClose.MouseButton1Click:Connect(function()
        closeDrop()
        hub.Visible = false
        CONFIG.Scare = false
        if toggleSyncs and toggleSyncs["Scare"] then toggleSyncs["Scare"](false) end
        if Troll:IsSpectating() then Troll:StopSpectate() end
    end)

    return hub
end

return UI
