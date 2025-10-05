-- Roblox: 学習用スクリプト（改良版）
-- 配置: StarterPlayer > StarterPlayerScripts に入れて使用
-- 学習・デモ用: 実際のゲームでの不正行為用ではありません

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ===== 設定 =====
local CONFIG = {
    EnemyContainerName = "Enemies",
    MaxDetectDistance = 200,
    ESPEnabled = true,
    WallCheckEnabled = true,
    TeamCheckEnabled = true,
    ESPScale = 1.0,
}

-- ===== ヘルパー =====
local function hasLineOfSight(fromPos, toPos, ignoreList)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = ignoreList or {}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = true
    local dir = toPos - fromPos
    local result = workspace:Raycast(fromPos, dir, rayParams)
    if not result then return true end
    return result
end

local function gatherEnemies()
    local enemies = {}
    local container = workspace:FindFirstChild(CONFIG.EnemyContainerName)
    if not container then return enemies end
    for _, obj in pairs(container:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            table.insert(enemies, obj)
        end
    end
    return enemies
end

local function sameTeamCheck(targetModel)
    if not CONFIG.TeamCheckEnabled then return false end
    local plTeam = LocalPlayer.Team
    if not plTeam then return false end
    local owner = Players:GetPlayerFromCharacter(targetModel)
    if owner then return owner.Team == plTeam end
    return false
end

-- ===== ESP: BillboardGuiを改良 =====
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "_ESP_Markers"
ESPFolder.Parent = LocalPlayer:WaitForChild("PlayerGui")

local function createOrUpdateESP(targetModel)
    local root = targetModel:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local tag = ESPFolder:FindFirstChild(targetModel.Name)
    if not tag then
        local bg = Instance.new("BillboardGui")
        bg.Name = targetModel.Name
        bg.Adornee = root
        bg.Size = UDim2.new(0, 150, 0, 60)
        bg.StudsOffset = Vector3.new(0, 2.5, 0)
        bg.AlwaysOnTop = true

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 0.4
        frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
        frame.Parent = bg

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -4, 0, 20)
        nameLabel.Position = UDim2.new(0, 2, 0, 2)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextScaled = true
        nameLabel.Text = targetModel.Name
        nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
        nameLabel.Parent = frame

        local healthLabel = Instance.new("TextLabel")
        healthLabel.Size = UDim2.new(1, -4, 0, 20)
        healthLabel.Position = UDim2.new(0, 2, 0, 22)
        healthLabel.BackgroundTransparency = 1
        healthLabel.TextScaled = true
        healthLabel.TextColor3 = Color3.fromRGB(0,255,0)
        healthLabel.Text = "Health: 100%"
        healthLabel.Parent = frame

        local distanceLabel = Instance.new("TextLabel")
        distanceLabel.Size = UDim2.new(1, -4, 0, 18)
        distanceLabel.Position = UDim2.new(0, 2, 0, 44)
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.TextScaled = true
        distanceLabel.TextColor3 = Color3.fromRGB(255,255,0)
        distanceLabel.Text = "Dist: 0"
        distanceLabel.Parent = frame

        bg.Parent = ESPFolder
        tag = bg
    end

    local humanoidRoot = root
    local dist = (humanoidRoot.Position - Camera.CFrame.Position).Magnitude
    local frame = tag:FindFirstChildWhichIsA("Frame")
    if frame then
        local labels = frame:GetChildren()
        for _, lbl in pairs(labels) do
            if lbl:IsA("TextLabel") then
                if lbl.Text:match("Health") then
                    -- ダミーで100%表示
                    lbl.Text = string.format("Health: %d%%", 100)
                elseif lbl.Text:match("Dist") then
                    lbl.Text = string.format("Dist: %.1fm", dist)
                    -- 距離で色変化
                    lbl.TextColor3 = dist < 50 and Color3.fromRGB(0,255,0) or (dist < 150 and Color3.fromRGB(255,255,0) or Color3.fromRGB(255,0,0))
                end
            end
        end
    end
    tag.Enabled = CONFIG.ESPEnabled and dist <= CONFIG.MaxDetectDistance
end

-- ===== UI: ドラッグ可能、最小化可能 =====
local function createUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local screen = Instance.new("ScreenGui")
    screen.Name = "SharpLearningUI"
    screen.ResetOnSpawn = false
    screen.Parent = playerGui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 300, 0, 160)
    main.Position = UDim2.new(0, 20, 0, 20)
    main.BackgroundColor3 = Color3.fromRGB(50,50,50)
    main.BackgroundTransparency = 0.1
    main.BorderSizePixel = 0
    main.Parent = screen

    -- ドラッグ機能
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    -- ボタンなどは前のコードをベースに作る
    -- 最小化ボタン
    local miniBtn = Instance.new("TextButton")
    miniBtn.Size = UDim2.new(0, 24, 0, 24)
    miniBtn.Position = UDim2.new(1, -28, 0, 2)
    miniBtn.Text = "-"
    miniBtn.Parent = main

    local minimized = false
    miniBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        main.Size = minimized and UDim2.new(0, 120, 0, 32) or UDim2.new(0, 300, 0, 160)
    end)

    return screen
end

-- ===== 投擲軌道を物理ベースでシミュレーション（学習用） =====
local function simulateThrow(target)
    if not target or not target:FindFirstChild("HumanoidRootPart") then return end
    local knife = Instance.new("Part")
    knife.Size = Vector3.new(0.2,0.2,1)
    knife.Position = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0,2,0) or Camera.CFrame.Position
    knife.CanCollide = false
    knife.Anchored = false
    knife.Material = Enum.Material.SmoothPlastic
    knife.Transparency = 0.3
    knife.Parent = workspace

    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = (target.HumanoidRootPart.Position - knife.Position).Unit * 120
    bodyVelocity.MaxForce = Vector3.new(400000,400000,400000)
    bodyVelocity.Parent = knife

    game.Debris:AddItem(knife, 1.5)
end

-- ===== メインループ =====
local ui = createUI()
RunService.RenderStepped:Connect(function()
    local enemies = gatherEnemies()
    for _, e in pairs(enemies) do
        if e and e:FindFirstChild("HumanoidRootPart") then
            if CONFIG.TeamCheckEnabled and sameTeamCheck(e) then
                local tag = ESPFolder:FindFirstChild(e.Name)
                if tag then tag.Enabled = false end
            else
                if CONFIG.WallCheckEnabled then
                    local res = hasLineOfSight(Camera.CFrame.Position, e.HumanoidRootPart.Position, {LocalPlayer.Character})
                    if res and res.Instance and not res.Instance:IsDescendantOf(e) then
                        local tag = ESPFolder:FindFirstChild(e.Name)
                        if tag then tag.Enabled = false end
                    else
                        createOrUpdateESP(e)
                    end
                else
                    createOrUpdateESP(e)
                end
            end
        end
    end
end)

print("Sharp learning script (improved) loaded")
