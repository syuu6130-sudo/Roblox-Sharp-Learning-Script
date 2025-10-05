-- TPS Aim Support 完全版（スマホ/PC 両対応・合法表示のみ）
-- LocalScriptとして StarterPlayerScripts または StarterGui -> PlayerGui 内で動かす

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ======= 設定 =======
local MAX_HIGHLIGHT_DISTANCE = 300           -- ハイライト判定距離
local AIM_RADIUS_PIXELS = 80                 -- 画面中心から何ピクセル以内を「狙えてる」と判定するか
local UPDATE_INTERVAL = 0.03                 -- ESP/判定の更新間隔（秒）
local USE_RAYCAST_FOR_VISIBILITY = true      -- 壁越し非表示にしたいなら true（負荷注意）
local HIGHLIGHT_FILL_TRANSPARENCY = 0.75
local HIGHLIGHT_OUTLINE_TRANSPARENCY = 0

-- ======= UI 構築 =======
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TPS_AimSupport_Full"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- メインコンテナ（UIの移動はここを動かす）
local uiContainer = Instance.new("Frame")
uiContainer.Name = "UIContainer"
uiContainer.Size = UDim2.new(0, 360, 0, 180)
uiContainer.Position = UDim2.new(0.5, -180, 0.04, 0)
uiContainer.AnchorPoint = Vector2.new(0.5, 0)
uiContainer.BackgroundTransparency = 1
uiContainer.Parent = screenGui
uiContainer.Active = true

-- 背景パネル（設定等）
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
title.Text = "Aim Support"
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

-- ミニモード用ボタン（最小化時に表示）
local miniOpenBtn
local function createMiniOpen()
	if miniOpenBtn and miniOpenBtn.Parent then return end
	miniOpenBtn = Instance.new("TextButton", screenGui)
	miniOpenBtn.Size = UDim2.new(0, 60, 0, 30)
	miniOpenBtn.Position = UDim2.new(0.5, -30, 0, 6)
	miniOpenBtn.AnchorPoint = Vector2.new(0.5, 0)
	miniOpenBtn.Text = "開く"
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

-- ======= クロスヘア（画面中央固定） =======
-- クロスヘア自体は screenGui 直下に置いて中央に固定する（UIContainerとは別）
local crossRoot = Instance.new("Frame", screenGui)
crossRoot.Name = "CrossRoot"
crossRoot.Size = UDim2.new(0, 0, 0, 0) -- 見た目は子で制御
crossRoot.AnchorPoint = Vector2.new(0.5, 0.5)
crossRoot.Position = UDim2.new(0.5, 0, 0.5, 0)
crossRoot.BackgroundTransparency = 1
crossRoot.ZIndex = 2

-- 外側虹色円
local rainbow = Instance.new("Frame", crossRoot)
rainbow.Name = "RainbowCircle"
rainbow.Size = UDim2.new(0, 160, 0, 160)
rainbow.AnchorPoint = Vector2.new(0.5,0.5)
rainbow.Position = UDim2.new(0.5, 0, 0.5, 0)
rainbow.BackgroundTransparency = 1

local rainbowCorner = Instance.new("UICorner", rainbow)
rainbowCorner.CornerRadius = UDim.new(1,0)

local rainbowStroke = Instance.new("UIStroke", rainbow)
rainbowStroke.Thickness = 5

-- 内側十字
local cross = Instance.new("Frame", crossRoot)
cross.Name = "Cross"
cross.Size = UDim2.new(0, 18, 0, 18)
cross.AnchorPoint = Vector2.new(0.5,0.5)
cross.Position = UDim2.new(0.5,0,0.5,0)
cross.BackgroundTransparency = 1

local barH = Instance.new("Frame", cross)
barH.Size = UDim2.new(1.6, 0, 0, 2)
barH.Position = UDim2.new(-0.3,0,0.5,-1)
barH.BackgroundColor3 = Color3.new(1,1,1)

local barV = Instance.new("Frame", cross)
barV.Size = UDim2.new(0, 2, 1.6, 0)
barV.Position = UDim2.new(0.5,-1,-0.3,0)
barV.BackgroundColor3 = Color3.new(1,1,1)

-- 狙えてるときの外側リング色（ターゲット接近時に色変化）
local aimOn = false

-- ======= ドラッグ機能（UIContainer と クロスを動かすオプション） =======
local draggable = true
do
	local dragging = false
	local dragTarget -- frame to drag (uiContainer or crossRoot)
	local dragStartPos
	local dragStartMouse

	-- 汎用開始/更新/終了
	local function onInputBegan(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local mousePos = input.Position
			-- UIContainer上をクリックでコンテナ移動、クロス直下（領域）をドラッグでクロス移動
			local absPos = uiContainer.AbsolutePosition
			local absSize = uiContainer.AbsoluteSize
			local crossPos = crossRoot.AbsolutePosition
			local crossSize = crossRoot.AbsoluteSize

			-- 判定：押下位置がクロス近辺（半径200px以内）ならクロスをドラッグ、そうでなければパネルをドラッグ
			local centerScreen = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
			local distToCenter = (Vector2.new(mousePos.X, mousePos.Y) - centerScreen).Magnitude

			if draggable then
				dragging = true
				dragStartMouse = mousePos
				if distToCenter <= 220 then
					dragTarget = "cross"
					dragStartPos = crossRoot.Position
				else
					dragTarget = "panel"
					dragStartPos = uiContainer.Position
				end
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end
	end

	local function onInputChanged(input)
		if not dragging or not dragTarget then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStartMouse
			if dragTarget == "panel" then
				uiContainer.Position = UDim2.new(
					dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X,
					dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y
				)
			elseif dragTarget == "cross" then
				-- クロスは画面上の絶対座標で位置をずらす（pxベース）
				local newX = Camera.ViewportSize.X * 0.5 + delta.X
				local newY = Camera.ViewportSize.Y * 0.5 + delta.Y
				crossRoot.Position = UDim2.new(0, newX, 0, newY)
				crossRoot.AnchorPoint = Vector2.new(0,0) -- 絶対位置扱いにする
			end
		end
	end

	uiContainer.InputBegan:Connect(onInputBegan)
	crossRoot.InputBegan:Connect(onInputBegan)
	UserInputService.InputChanged:Connect(onInputChanged)
end

-- ======= トグルスイッチ群 =======
local function makeToggle(parent, text, init, posY)
	local btn = Instance.new("TextButton", parent)
	btn.Size = UDim2.new(0, 96, 0, 28)
	btn.Position = UDim2.new(0, 8 + (posY or 0), 0, 34 + (posY or 0))
	btn.Text = (init and "ON " or "OFF ") .. text
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 14
	btn.TextColor3 = Color3.new(1,1,1)
	btn.BackgroundColor3 = init and Color3.fromRGB(50,160,50) or Color3.fromRGB(90,90,90)
	return btn
end

local espEnabled = true
local crossEnabled = true
local rainbowEnabled = true
local guideEnabled = true

local espBtn = makeToggle(panel, "ESP", espEnabled, 0)
local crossBtn = makeToggle(panel, "十字", crossEnabled, 36)
local rainbowBtn = makeToggle(panel, "虹丸", rainbowEnabled, 72)
local guideBtn = makeToggle(panel, "ガイド表示", guideEnabled, 108)

espBtn.Activated:Connect(function()
	espEnabled = not espEnabled
	espBtn.Text = (espEnabled and "ON " or "OFF ") .. "ESP"
	espBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(50,160,50) or Color3.fromRGB(90,90,90)
end)
crossBtn.Activated:Connect(function()
	crossEnabled = not crossEnabled
	crossBtn.Text = (crossEnabled and "ON " or "OFF ") .. "十字"
	crossBtn.BackgroundColor3 = crossEnabled and Color3.fromRGB(50,160,50) or Color3.fromRGB(90,90,90)
	cross.Visible = crossEnabled
end)
rainbowBtn.Activated:Connect(function()
	rainbowEnabled = not rainbowEnabled
	rainbowBtn.Text = (rainbowEnabled and "ON " or "OFF ") .. "虹丸"
	rainbowBtn.BackgroundColor3 = rainbowEnabled and Color3.fromRGB(50,160,50) or Color3.fromRGB(90,90,90)
	rainbow.Visible = rainbowEnabled
end)
guideBtn.Activated:Connect(function()
	guideEnabled = not guideEnabled
	guideBtn.Text = (guideEnabled and "ON " or "OFF ") .. "ガイド表示"
	guideBtn.BackgroundColor3 = guideEnabled and Color3.fromRGB(50,160,50) or Color3.fromRGB(90,90,90)
end)

-- ======= ハイライト管理 =======
local activeHighlights = {}

local function clearHighlight(pl)
	local h = activeHighlights[pl]
	if h and h.Parent then
		h:Destroy()
	end
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
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl.Team and pl.Team.Name ~= "" then
			return true
		end
	end
	return false
end

local function isEnemy(pl)
	if not hasTeams() then
		return true
	end
	if not pl.Team or not LocalPlayer.Team then
		return true
	end
	return pl.Team ~= LocalPlayer.Team
end

-- ======= 画面中心との距離を使った「狙えてる」判定 =======
local function getClosestToCenter()
	local cam = Camera
	if not cam then return nil end
	local vs = cam.ViewportSize
	local center = Vector2.new(vs.X/2, vs.Y/2)

	local best = nil
	local bestDist = math.huge
	local bestOnScreen = false
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= LocalPlayer and pl.Character and pl.Character.Parent then
			local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
			local humanoid = pl.Character:FindFirstChildOfClass("Humanoid")
			if hrp and humanoid and humanoid.Health > 0 then
				local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
				local screenV = Vector2.new(screenPos.X, screenPos.Y)
				local dist = (screenV - center).Magnitude
				-- 距離制限
				local worldDist = (hrp.Position - cam.CFrame.Position).Magnitude
				if worldDist <= MAX_HIGHLIGHT_DISTANCE then
					-- 可視性チェック（任意）
					local visible = true
					if USE_RAYCAST_FOR_VISIBILITY then
						local ray = Ray.new(cam.CFrame.Position, (hrp.Position - cam.CFrame.Position).Unit * math.min(1000, worldDist))
						local hitPart = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character}, false, true)
						if hitPart and not hitPart:IsDescendantOf(pl.Character) then
							visible = false
						end
					end

					if onScreen and visible then
						if dist < bestDist then
							bestDist = dist
							best = {player = pl, distPixels = dist, worldDist = worldDist, screenPos = screenV}
						end
					end
				end
			end
		end
	end
	return best
end

-- ======= 定期更新 =======
local lastUpdate = 0
RunService.RenderStepped:Connect(function(dt)
	-- 虹色アニメ
	if rainbowEnabled and rainbow and rainbowStroke then
		local hue = (tick() * 0.12) % 1
		rainbowStroke.Color = Color3.fromHSV(hue, 1, 1)
		local base = UserInputService.TouchEnabled and 100 or 160
		local scale = 1 + 0.05 * math.sin(tick() * 2)
		local size = math.clamp(base * scale, 60, 240)
		rainbow.Size = UDim2.new(0, size, 0, size)
		-- もし crossRoot が anchor(0,0) になってたら位置補正しないとズレるが、通常は中央
	end

	lastUpdate = lastUpdate + dt
	if lastUpdate < UPDATE_INTERVAL then return end
	lastUpdate = 0

	-- ESP 更新
	if espEnabled then
		-- 既存を維持しつつ更新
		local seen = {}
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= LocalPlayer and pl.Character and pl.Character.Parent then
				local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
				local humanoid = pl.Character:FindFirstChildOfClass("Humanoid")
				if hrp and humanoid and humanoid.Health > 0 then
					local worldDist = (hrp.Position - Camera.CFrame.Position).Magnitude
					if worldDist <= MAX_HIGHLIGHT_DISTANCE then
						-- チーム判定
						local color = isEnemy(pl) and Color3.new(1,0,0) or Color3.new(0,1,0)
						local h = ensureHighlight(pl.Character, color)
						activeHighlights[pl] = h
						seen[pl] = true
					end
				end
			end
		end
		-- 使われてないハイライトを削除
		for pl, _ in pairs(activeHighlights) do
			if not seen[pl] then clearHighlight(pl) end
		end
	else
		-- ESP無効なら全部消す
		for pl,_ in pairs(activeHighlights) do clearHighlight(pl) end
	end

	-- 中央に近い敵を検出してクロスヘアを反応させる（AIMサポート表示）
	local best = getClosestToCenter()
	if best and best.distPixels <= AIM_RADIUS_PIXELS and guideEnabled then
		-- 狙えている：クロスの色を赤にして小さなテキストを表示（攻撃はしない）
		if not aimOn then
			aimOn = true
		end
		-- 色変化（例：赤）
		rainbowStroke.Color = Color3.new(1,0.35,0.35)
		-- パネルに情報表示（ターゲット名・距離）
		title.Text = ("Aim Support  — 対象: %s (%.0f)"):format(best.player.Name, best.worldDist)
	else
		if aimOn then aimOn = false end
		-- 元に戻す
		title.Text = "Aim Support"
	end
end)

-- 初期表示ヒント（数秒）
do
	local hint = Instance.new("TextLabel", uiContainer)
	hint.Size = UDim2.new(0, 260, 0, 26)
	hint.Position = UDim2.new(0, 8, 0, 156)
	hint.BackgroundTransparency = 0.6
	hint.BackgroundColor3 = Color3.fromRGB(0,0,0)
	hint.TextColor3 = Color3.new(1,1,1)
	hint.Text = "表示のみ — 自動射撃・自動照準は含まれません"
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 14
	delay(4, function()
		if hint and hint.Parent then hint:Destroy() end
	end)
end

-- クリーンアップ（プレイヤーが離れたらHighlight除去）
Players.PlayerRemoving:Connect(function(pl)
	if activeHighlights[pl] then clearHighlight(pl) end
end)

-- キャラ切替時に古いハイライトをクリア
LocalPlayer.CharacterAdded:Connect(function()
	for pl,_ in pairs(activeHighlights) do clearHighlight(pl) end
end)

-- 終了時の削除バインド
game:BindToClose(function()
	for pl,_ in pairs(activeHighlights) do clearHighlight(pl) end
	if screenGui and screenGui.Parent then screenGui:Destroy() end
end)

-- 最後に注意：
-- - このスクリプトは視覚補助（UI/Highlight/狙えてるかの判定）だけで、自動発砲や自動ターゲット操作は一切行いません。
-- - 一部ゲームでは Highlight の作成を禁止していたり、サーバ側でブロックされることがあります（その場合は Billboards を代替で用意可能）。
-- - 必要なら 「壁越しでも色を薄くする」「HUDを小型化する」「Billboard代替」を追加するよ。要るもの教えて。

