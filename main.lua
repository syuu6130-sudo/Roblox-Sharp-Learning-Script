-- TPS Aim & Attack Support 完全版（シャープ用）
-- LocalScriptとして StarterPlayerScripts または StarterGui -> PlayerGui 内で使用

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ======= 設定 =======
local MAX_HIGHLIGHT_DISTANCE = 300
local AIM_RADIUS_PIXELS = 80
local UPDATE_INTERVAL = 0.03
local USE_RAYCAST_FOR_VISIBILITY = true
local HIGHLIGHT_FILL_TRANSPARENCY = 0.75
local HIGHLIGHT_OUTLINE_TRANSPARENCY = 0

-- ======= UI 構築 =======
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TPS_AimAttack_Full"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- メインコンテナ
local uiContainer = Instance.new("Frame")
uiContainer.Name = "UIContainer"
uiContainer.Size = UDim2.new(0, 360, 0, 180)
uiContainer.Position = UDim2.new(0.5, -180, 0.04, 0)
uiContainer.AnchorPoint = Vector2.new(0.5, 0)
uiContainer.BackgroundTransparency = 1
uiContainer.Parent = screenGui
uiContainer.Active = true

-- 背景パネル
local panel = Instance.new("Frame", uiContainer)
panel.Name = "Panel"
panel.Size = UDim2.new(0, 220, 0, 140)
panel.Position = UDim2.new(0, 8, 0, 8)
panel.BackgroundColor3 = Color3.fromRGB(25,25,25)
panel.BorderSizePixel = 0
panel.Visible = true

local title = Instance.new("TextLabel", panel)
title.Size = UDim2.new(1, 0, 0, 28)
title.Position = UDim2.new(0, 0, 0, 4)
title.BackgroundTransparency = 1
title.Text = "Aim & Attack Support"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16

-- 閉じる・最小化ボタン
local btnClose = Instance.new("TextButton", uiContainer)
btnClose.Size = UDim2.new(0, 28, 0, 28)
btnClose.Position = UDim2.new(1, -36, 0, 6)
btnClose.Text = "❌"
btnClose.Font = Enum.Font.Gotham
btnClose.TextSize = 18
btnClose.BackgroundColor3 = Color3.fromRGB(190,60,60)
btnClose.TextColor3 = Color3.new(1,1,1)

local btnMin = Instance.new("TextButton", uiContainer)
btnMin.Size = UDim2.new(0, 28, 0, 28)
btnMin.Position = UDim2.new(1, -72, 0, 6)
btnMin.Text = "—"
btnMin.Font = Enum.Font.Gotham
btnMin.TextSize = 18
btnMin.BackgroundColor3 = Color3.fromRGB(130,130,130)
btnMin.TextColor3 = Color3.new(1,1,1)

-- ミニモード用ボタン
local miniOpenBtn
local function createMiniOpen()
	if miniOpenBtn and miniOpenBtn.Parent then return end
	miniOpenBtn = Instance.new("TextButton", screenGui)
	miniOpenBtn.Size = UDim2.new(0, 60, 0, 30)
	miniOpenBtn.Position = UDim2.new(0.5, -30, 0, 6)
	miniOpenBtn.AnchorPoint = Vector2.new(0.5, 0)
	miniOpenBtn.Text = "open"
	miniOpenBtn.Font = Enum.Font.Gotham
	miniOpenBtn.TextSize = 14
	miniOpenBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
	miniOpenBtn.TextColor3 = Color3.new(1,1,1)
	miniOpenBtn.Activated:Connect(function()
		miniOpenBtn:Destroy()
		miniOpenBtn = nil
		uiContainer.Visible = true
	end)
end

btnClose.Activated:Connect(function()
	screenGui:Destroy()
end)

btnMin.Activated:Connect(function()
	uiContainer.Visible = false
	createMiniOpen()
end)

-- ======= クロスヘア & 虹丸（完全中央固定） =======
local crossRoot = Instance.new("Frame", screenGui)
crossRoot.Name = "CrossRoot"
crossRoot.Size = UDim2.new(0,0,0,0)
crossRoot.AnchorPoint = Vector2.new(0.5,0.5)
crossRoot.Position = UDim2.new(0.5,0,0.5,0)
crossRoot.BackgroundTransparency = 1
crossRoot.ZIndex = 2

-- 虹丸
local rainbow = Instance.new("Frame", crossRoot)
rainbow.Name = "RainbowCircle"
rainbow.Size = UDim2.new(0,160,0,160)
rainbow.AnchorPoint = Vector2.new(0.5,0.5)
rainbow.Position = UDim2.new(0.5,0,0.5,0)
rainbow.BackgroundTransparency = 1

local rainbowCorner = Instance.new("UICorner", rainbow)
rainbowCorner.CornerRadius = UDim.new(1,0)

local rainbowStroke = Instance.new("UIStroke", rainbow)
rainbowStroke.Thickness = 5

-- 内側十字
local cross = Instance.new("Frame", crossRoot)
cross.Name = "Cross"
cross.Size = UDim2.new(0,18,0,18)
cross.AnchorPoint = Vector2.new(0.5,0.5)
cross.Position = UDim2.new(0.5,0,0.5,0)
cross.BackgroundTransparency = 1

local barH = Instance.new("Frame", cross)
barH.Size = UDim2.new(1.6,0,0,2)
barH.Position = UDim2.new(-0.3,0,0.5,-1)
barH.BackgroundColor3 = Color3.new(1,1,1)

local barV = Instance.new("Frame", cross)
barV.Size = UDim2.new(0,2,1.6,0)
barV.Position = UDim2.new(0.5,-1,-0.3,0)
barV.BackgroundColor3 = Color3.new(1,1,1)

-- ======= 攻撃ボタン =======
local attackButton
if UserInputService.TouchEnabled then
	attackButton = Instance.new("TextButton", screenGui)
	attackButton.Size = UDim2.new(0, 80, 0, 80)
	attackButton.Position = UDim2.new(0.5, -40, 0.85, 0)
	attackButton.AnchorPoint = Vector2.new(0.5,0)
	attackButton.BackgroundColor3 = Color3.fromRGB(200,60,60)
	attackButton.Text = "攻撃"
	attackButton.Font = Enum.Font.GothamBold
	attackButton.TextSize = 22
	attackButton.TextColor3 = Color3.new(1,1,1)
	attackButton.AutoButtonColor = true
end

-- ======= ハイライト管理 =======
local activeHighlights = {}
local function clearHighlight(pl)
	local h = activeHighlights[pl]
	if h and h.Parent then h:Destroy() end
	activeHighlights[pl] = nil
end
local function ensureHighlight(char, color)
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
		h.FillTransparency = HIGHLIGHT_FILL_TRANSPARENCY
		h.OutlineTransparency = HIGHLIGHT_OUTLINE_TRANSPARENCY
		h.Parent = char
		return h
	end
end
local function hasTeams()
	for _,pl in ipairs(Players:GetPlayers()) do
		if pl.Team and pl.Team.Name ~= "" then return true end
	end
	return false
end
local function isEnemy(pl)
	if not hasTeams() then return true end
	if not pl.Team or not LocalPlayer.Team then return true end
	return pl.Team ~= LocalPlayer.Team
end

-- ======= 中央距離判定 =======
local function getClosestToCenter()
	local cam = Camera
	if not cam then return nil end
	local vs = cam.ViewportSize
	local center = Vector2.new(vs.X/2, vs.Y/2)
	local best = nil
	local bestDist = math.huge
	local bestOnScreen = false
	for _,pl in ipairs(Players:GetPlayers()) do
		if pl ~= LocalPlayer and pl.Character and pl.Character.Parent then
			local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
			local humanoid = pl.Character:FindFirstChildOfClass("Humanoid")
			if hrp and humanoid and humanoid.Health>0 then
				local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
				local screenV = Vector2.new(screenPos.X, screenPos.Y)
				local dist = (screenV - center).Magnitude
				local worldDist = (hrp.Position - cam.CFrame.Position).Magnitude
				if worldDist <= MAX_HIGHLIGHT_DISTANCE then
					local visible = true
					if USE_RAYCAST_FOR_VISIBILITY then
						local ray = Ray.new(cam.CFrame.Position,(hrp.Position-cam.CFrame.Position).Unit*math.min(1000,worldDist))
						local hitPart = workspace:FindPartOnRayWithIgnoreList(ray,{LocalPlayer.Character},false,true)
						if hitPart and not hitPart:IsDescendantOf(pl.Character) then
							visible = false
						end
					end
					if onScreen and visible and dist<bestDist then
						bestDist = dist
						best = {player=pl,distPixels=dist,worldDist=worldDist,screenPos=screenV}
					end
				end
			end
		end
	end
	return best
end

-- ======= 攻撃関数（中央方向に攻撃） =======
local function attackCentral()
	local char = LocalPlayer.Character
	if not char then return end
	local tool = char:FindFirstChildWhichIsA("Tool")
	if tool and tool:FindFirstChild("Activate") then
		tool:Activate()
	end
end

if attackButton then
	attackButton.Activated:Connect(attackCentral)
end

-- PC 左クリックで中央攻撃
UserInputService.InputBegan:Connect(function(input,gp)
	if not gp and input.UserInputType==Enum.UserInputType.MouseButton1 then
		attackCentral()
	end
end)

-- ======= 更新ループ =======
local lastUpdate = 0
local aimOn = false
RunService.RenderStepped:Connect(function(dt)
	-- 虹丸アニメ
	if rainbowStroke then
		local hue = (tick()*0.12)%1
		rainbowStroke.Color = Color3.fromHSV(hue,1,1)
		local base = UserInputService.TouchEnabled and 100 or 160
		local scale = 1 + 0.05*math.sin(tick()*2)
		local size = math.clamp(base*scale,60,240)
		rainbow.Size = UDim2.new(0,size,0,size)
	end

	lastUpdate = lastUpdate+dt
	if lastUpdate<UPDATE_INTERVAL then return end
	lastUpdate=0

	-- ESP更新
	local seen = {}
	for _,pl in ipairs(Players:GetPlayers()) do
		if pl~=LocalPlayer and pl.Character and pl.Character.Parent then
			local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
			local humanoid = pl.Character:FindFirstChildOfClass("Humanoid")
			if hrp and humanoid and humanoid.Health>0 then
				local worldDist = (hrp.Position - Camera.CFrame.Position).Magnitude
				if worldDist<=MAX_HIGHLIGHT_DISTANCE then
					local color = isEnemy(pl) and Color3.new(1,0,0) or Color3.new(0,1,0)
					local h = ensureHighlight(pl.Character,color)
					activeHighlights[pl]=h
					seen[pl]=true
				end
			end
		end
	end
	for pl,_ in pairs(activeHighlights) do
		if not seen[pl] then
			if activeHighlights[pl] and activeHighlights[pl].Parent then
				activeHighlights[pl]:Destroy()
			end
			activeHighlights[pl]=nil
		end
	end

	-- クロスヘア反応
	local best = getClosestToCenter()
	if best and best.distPixels<=AIM_RADIUS_PIXELS then
		if not aimOn then aimOn=true end
		rainbowStroke.Color = Color3.new(1,0.35,0.35)
		title.Text = ("Aim & Attack — 対象: %s (%.0f)"):format(best.player.Name,best.worldDist)
	else
		if aimOn then aimOn=false end
		title.Text = "Aim & Attack Support"
	end
end)

-- クリーンアップ
Players.PlayerRemoving:Connect(function(pl)
	if activeHighlights[pl] then
		activeHighlights[pl]:Destroy()
		activeHighlights[pl]=nil
	end
end)
LocalPlayer.CharacterAdded:Connect(function()
	for pl,_ in pairs(activeHighlights) do
		if activeHighlights[pl] then activeHighlights[pl]:Destroy() end
		activeHighlights[pl]=nil
	end
end)
game:BindToClose(function()
	for pl,_ in pairs(activeHighlights) do
		if activeHighlights[pl] then activeHighlights[pl]:Destroy() end
	end
	if screenGui and screenGui.Parent then screenGui:Destroy() end
end)
