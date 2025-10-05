-- TPS Aim & Attack Support 完全版
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ===== 設定 =====
local MAX_HIGHLIGHT_DISTANCE = 300
local AIM_RADIUS_PIXELS = 80

-- ===== ScreenGui =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TPS_AimAttack_Full"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- ===== UIコンテナ =====
local uiContainer = Instance.new("Frame")
uiContainer.Name = "UIContainer"
uiContainer.Size = UDim2.new(0,360,0,180)
uiContainer.Position = UDim2.new(0.5,-180,0.04,0)
uiContainer.AnchorPoint = Vector2.new(0.5,0)
uiContainer.BackgroundTransparency = 1
uiContainer.Parent = screenGui
uiContainer.Active = true

-- 背景パネル
local panel = Instance.new("Frame", uiContainer)
panel.Size = UDim2.new(0,220,0,140)
panel.Position = UDim2.new(0,8,0,8)
panel.BackgroundColor3 = Color3.fromRGB(25,25,25)
panel.BorderSizePixel = 0
panel.ZIndex = 10

local title = Instance.new("TextLabel", panel)
title.Size = UDim2.new(1,0,0,28)
title.Position = UDim2.new(0,0,0,4)
title.BackgroundTransparency = 1
title.Text = "Aim & Attack Support"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.ZIndex = 11

-- ===== 閉じる・最小化ボタン =====
local function makeButton(name,posX,color)
	local btn = Instance.new("TextButton", uiContainer)
	btn.Size = UDim2.new(0,28,0,28)
	btn.Position = posX
	btn.Text = name
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 18
	btn.BackgroundColor3 = color
	btn.TextColor3 = Color3.new(1,1,1)
	btn.ZIndex = 12
	return btn
end

local btnClose = makeButton("❌", UDim2.new(1,-36,0,6), Color3.fromRGB(190,60,60))
local btnMin = makeButton("—", UDim2.new(1,-72,0,6), Color3.fromRGB(130,130,130))

local miniOpenBtn
local function createMiniOpen()
	if miniOpenBtn and miniOpenBtn.Parent then return end
	miniOpenBtn = Instance.new("TextButton", screenGui)
	miniOpenBtn.Size = UDim2.new(0,60,0,30)
	miniOpenBtn.Position = UDim2.new(0.5,-30,0,6)
	miniOpenBtn.AnchorPoint = Vector2.new(0.5,0)
	miniOpenBtn.Text = "開く"
	miniOpenBtn.Font = Enum.Font.Gotham
	miniOpenBtn.TextSize = 14
	miniOpenBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
	miniOpenBtn.TextColor3 = Color3.new(1,1,1)
	miniOpenBtn.ZIndex = 13
	miniOpenBtn.Activated:Connect(function()
		miniOpenBtn:Destroy()
		miniOpenBtn = nil
		uiContainer.Visible = true
	end)
end

btnClose.Activated:Connect(function() screenGui:Destroy() end)
btnMin.Activated:Connect(function()
	uiContainer.Visible = false
	createMiniOpen()
end)

-- ===== ドラッグ対応 =====
local dragging=false
local dragStart, startPos
uiContainer.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
		dragging=true
		dragStart=input.Position
		startPos=uiContainer.Position
		input.Changed:Connect(function()
			if input.UserInputState==Enum.UserInputState.End then dragging=false end
		end)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		uiContainer.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

-- ===== クロスヘア & 虹丸 =====
local crossRoot = Instance.new("Frame", screenGui)
crossRoot.Name = "CrossRoot"
crossRoot.Size = UDim2.new(0,0,0,0)
crossRoot.AnchorPoint = Vector2.new(0.5,0.5)
crossRoot.Position = UDim2.new(0.5,0,0.5,0)
crossRoot.BackgroundTransparency = 1
crossRoot.ZIndex = 1
crossRoot.Active = false
crossRoot.Selectable = false
crossRoot.InputTransparent = true

local rainbow = Instance.new("Frame", crossRoot)
rainbow.Name = "RainbowCircle"
rainbow.Size = UDim2.new(0,160,0,160)
rainbow.AnchorPoint = Vector2.new(0.5,0.5)
rainbow.Position = UDim2.new(0.5,0,0.5,0)
rainbow.BackgroundTransparency = 1
rainbow.InputTransparent = true
rainbow.ZIndex = 1
local rcCorner = Instance.new("UICorner", rainbow)
rcCorner.CornerRadius = UDim.new(1,0)
local rcStroke = Instance.new("UIStroke", rainbow)
rcStroke.Thickness = 5

local cross = Instance.new("Frame", crossRoot)
cross.Size = UDim2.new(0,18,0,18)
cross.AnchorPoint = Vector2.new(0.5,0.5)
cross.Position = UDim2.new(0.5,0,0.5,0)
cross.BackgroundTransparency = 1
cross.InputTransparent = true
cross.ZIndex = 1
local barH = Instance.new("Frame", cross)
barH.Size = UDim2.new(1.6,0,0,2)
barH.Position = UDim2.new(-0.3,0,0.5,-1)
barH.BackgroundColor3 = Color3.new(1,1,1)
local barV = Instance.new("Frame", cross)
barV.Size = UDim2.new(0,2,1.6,0)
barV.Position = UDim2.new(0.5,-1,-0.3,0)
barV.BackgroundColor3 = Color3.new(1,1,1)

-- ===== 攻撃ボタン =====
local attackButton
if UserInputService.TouchEnabled then
	attackButton = Instance.new("TextButton", screenGui)
	attackButton.Size = UDim2.new(0,80,0,80)
	attackButton.Position = UDim2.new(0.5,-40,0.85,0)
	attackButton.AnchorPoint = Vector2.new(0.5,0)
	attackButton.BackgroundColor3 = Color3.fromRGB(200,60,60)
	attackButton.Text = "攻撃"
	attackButton.Font = Enum.Font.GothamBold
	attackButton.TextSize = 22
	attackButton.TextColor3 = Color3.new(1,1,1)
	attackButton.ZIndex = 15
end

-- ===== ハイライト管理 =====
local activeHighlights = {}
local function ensureHighlight(char,color)
	if not char or not char.Parent then return nil end
	local existing = char:FindFirstChild("TPS_Aim_Highlight")
	if existing and existing:IsA("Highlight") then
		existing.FillColor = color
		existing.OutlineColor = color
		return existing
	else
		if existing then existing:Destroy() end
		local h = Instance.new("Highlight")
		h.Name = "TPS_Aim_Highlight"
		h.FillColor = color
		h.OutlineColor = color
		h.FillTransparency = 0.75
		h.OutlineTransparency = 0
		h.Parent = char
		return h
	end
end
local function hasTeams()
	for _,pl in ipairs(Players:GetPlayers()) do
		if pl.Team and pl.Team.Name~="" then return true end
	end
	return false
end
local function isEnemy(pl)
	if not hasTeams() then return true end
	if not pl.Team or not LocalPlayer.Team then return true end
	return pl.Team ~= LocalPlayer.Team
end

-- ===== 中央に近い敵取得 =====
local function getClosestToCenter()
	local cam = Camera
	local vs = cam.ViewportSize
	local center = Vector2.new(vs.X/2,vs.Y/2)
	local best=nil
	local bestDist=math.huge
	for _,pl in ipairs(Players:GetPlayers()) do
		if pl~=LocalPlayer and pl.Character and pl.Character.Parent then
			local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
			local humanoid = pl.Character:FindFirstChildOfClass("Humanoid")
			if hrp and humanoid and humanoid.Health>0 then
				local screenPos,onScreen = cam:WorldToViewportPoint(hrp.Position)
				local screenV = Vector2.new(screenPos.X,screenPos.Y)
				local dist = (screenV-center).Magnitude
				local worldDist = (hrp.Position-cam.CFrame.Position).Magnitude
				if onScreen and dist<bestDist and worldDist<=MAX_HIGHLIGHT_DISTANCE then
					bestDist=dist
					best={player=pl,distPixels=dist,worldDist=worldDist}
				end
			end
		end
	end
	return best
end

-- ===== 攻撃 =====
local function attackCentral()
	local char = LocalPlayer.Character
	if not char then return end
	local tool = char:FindFirstChildWhichIsA("Tool")
	if tool then tool:Activate() end
end
if attackButton then attackButton.Activated:Connect(attackCentral) end
UserInputService.InputBegan:Connect(function(input,gp)
	if not gp and input.UserInputType==Enum.UserInputType.MouseButton1 then
		attackCentral()
	end
end)

-- ===== 更新ループ =====
RunService.RenderStepped:Connect(function()
	-- 虹丸アニメ
	local hue = (tick()*0.12)%1
	rcStroke.Color = Color3.fromHSV(hue,1,1)
	local base = UserInputService.TouchEnabled and 100 or 160
	local scale = 1 + 0.05*math.sin(tick()*2)
	local size = math.clamp(base*scale,60,240)
	rainbow.Size = UDim2.new(0,size,0,size)

	-- ESP更新
	local seen={}
	for _,pl in ipairs(Players:GetPlayers()) do
		if pl~=LocalPlayer and pl.Character and pl.Character.Parent then
			local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
			local humanoid = pl.Character:FindFirstChildOfClass("Humanoid")
			if hrp and humanoid and humanoid.Health>0 then
				local color = isEnemy(pl) and Color3.new(1,0,0) or Color3.new(0,1,0)
				local h = ensureHighlight(pl.Character,color)
				activeHighlights[pl]=h
				seen[pl]=true
			end
		end
	end
	for pl,_ in pairs(activeHighlights) do
		if not seen[pl] then
			if activeHighlights[pl] then activeHighlights[pl]:Destroy() en
			activeHighlights[pl]=nil
		end
	end

	-- クロスヘア反応
	local best=getClosestToCenter()
	if best and best.distPixels<=AIM_RADIUS_PIXELS then
		title.Text = ("Aim & Attack — 対象: %s (%.0f)"):format(best.player.Name,best.worldDist)
	else
		title.Text = "Aim & Attack Support"
	end
end)
