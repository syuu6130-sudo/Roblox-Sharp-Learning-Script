-- 三人称向けエイムサポートUI（スマホ / PC 両対応・合法）
-- Place this file as a LocalScript under StarterPlayerScripts or StarterGui (LocalScript)
-- 何もしない自動射撃等は含まれていません。UI表示＆ハイライトのみ。

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 設定（必要ならここを編集）
local HIGHLIGHT_FILL_TRANSPARENCY = 0.7
local HIGHLIGHT_OUTLINE_TRANSPARENCY = 0
local MAX_HIGHLIGHT_DISTANCE = 200  -- ハイライトする最大距離（stud）
local SHOW_DISTANCE_TEXT = false    -- 名前の横に距離を表示するか

-- UI 作成
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TPS_AimSupport_UI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- メインフレーム（ドラッグ可能）
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 1, 0, 1) -- 最小化用の invisible holder（位置は個別要素で管理）
mainFrame.Position = UDim2.new(0.5, -200, 0.03, 0) -- 初期位置（画面上部中央）
mainFrame.BackgroundTransparency = 1
mainFrame.Active = true
mainFrame.Parent = screenGui

-- クロスヘア用フォルダ（中央に表示）
local crossFolder = Instance.new("Frame")
crossFolder.Name = "CrossFolder"
crossFolder.Size = UDim2.new(0, 0, 0, 0)
crossFolder.Position = UDim2.new(0.5, 0, 0.5, 0)
crossFolder.AnchorPoint = Vector2.new(0.5, 0.5)
crossFolder.BackgroundTransparency = 1
crossFolder.Parent = mainFrame

-- 外側の虹色呼吸円
local circle = Instance.new("Frame")
circle.Name = "RainbowCircle"
circle.Size = UDim2.new(0, 120, 0, 120) -- スマホは後で補正
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Position = UDim2.new(0.5, 0, 0.5, 0)
circle.BackgroundTransparency = 1
circle.Parent = crossFolder

local circleUICorner = Instance.new("UICorner", circle)
circleUICorner.CornerRadius = UDim.new(1, 0)

local circleStroke = Instance.new("UIStroke", circle)
circleStroke.Thickness = 4

-- 内側の白十字（小）
local crossCenter = Instance.new("Frame")
crossCenter.Name = "CrossCenter"
crossCenter.Size = UDim2.new(0, 12, 0, 12)
crossCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
crossCenter.AnchorPoint = Vector2.new(0.5, 0.5)
crossCenter.BackgroundColor3 = Color3.new(1,1,1)
crossCenter.Parent = circle

local crossThinH = Instance.new("Frame", crossCenter)
crossThinH.Name = "H"
crossThinH.Size = UDim2.new(1.6, 0, 0, 2)
crossThinH.Position = UDim2.new(-0.3, 0, 0.5, -1)
crossThinH.BackgroundColor3 = Color3.new(1,1,1)

local crossThinV = Instance.new("Frame", crossCenter)
crossThinV.Name = "V"
crossThinV.Size = UDim2.new(0, 2, 1.6, 0)
crossThinV.Position = UDim2.new(0.5, -1, -0.3, 0)
crossThinV.BackgroundColor3 = Color3.new(1,1,1)

-- 設定パネル（最小限のトグル）
local panel = Instance.new("Frame")
panel.Name = "ControlPanel"
panel.Size = UDim2.new(0, 220, 0, 140)
panel.Position = UDim2.new(-0.5, -110, 0, -80) -- mainFrameの基準からオフセット
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.BackgroundColor3 = Color3.fromRGB(28,28,28)
panel.BorderSizePixel = 0
panel.Parent = mainFrame

local panelTitle = Instance.new("TextLabel")
panelTitle.Parent = panel
panelTitle.Size = UDim2.new(1, 0, 0, 28)
panelTitle.BackgroundTransparency = 1
panelTitle.Text = "Aim Support"
panelTitle.TextColor3 = Color3.new(1,1,1)
panelTitle.Font = Enum.Font.GothamBold
panelTitle.TextSize = 16
panelTitle.Position = UDim2.new(0,0,0,6)

-- トグル作成ヘルパー
local function makeToggle(labelText, initial, yOffset)
	local btn = Instance.new("TextButton")
	btn.Parent = panel
	btn.Size = UDim2.new(0, 100, 0, 28)
	btn.Position = UDim2.new(0, 10 + (yOffset or 0), 0, 30 + (yOffset or 0))
	btn.Text = (initial and "ON " or "OFF ") .. labelText
	btn.BackgroundColor3 = initial and Color3.fromRGB(45,150,45) or Color3.fromRGB(80,80,80)
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.SourceSans
	btn.TextSize = 14

	return btn
end

-- トグル変数
local espEnabled = true
local crossEnabled = true
local circleEnabled = true
local draggableEnabled = true

local espToggle = makeToggle("ESP", espEnabled, 0)
local crossToggle = makeToggle("十字", crossEnabled, 38)
local circleToggle = makeToggle("虹丸", circleEnabled, 76)

espToggle.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	espToggle.Text = (espEnabled and "ON " or "OFF ") .. "ESP"
	espToggle.BackgroundColor3 = espEnabled and Color3.fromRGB(45,150,45) or Color3.fromRGB(80,80,80)
end)

crossToggle.MouseButton1Click:Connect(function()
	crossEnabled = not crossEnabled
	crossToggle.Text = (crossEnabled and "ON " or "OFF ") .. "十字"
	crossToggle.BackgroundColor3 = crossEnabled and Color3.fromRGB(45,150,45) or Color3.fromRGB(80,80,80)
	crossCenter.Visible = crossEnabled
end)

circleToggle.MouseButton1Click:Connect(function()
	circleEnabled = not circleEnabled
	circleToggle.Text = (circleEnabled and "ON " or "OFF ") .. "虹丸"
	circleToggle.BackgroundColor3 = circleEnabled and Color3.fromRGB(45,150,45) or Color3.fromRGB(80,80,80)
	circle.Visible = circleEnabled
end)

-- スマホ判定＆サイズ補正
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
if isMobile then
	-- スマホは円を少し小さめにして画面上に寄せる
	circle.Size = UDim2.new(0, 100, 0, 100)
	mainFrame.Position = UDim2.new(0.5, -110, 0.45, -50)
	panel.Position = UDim2.new(-0.5, -110, 0, -110)
else
	-- PC向け
	circle.Size = UDim2.new(0, 140, 0, 140)
	mainFrame.Position = UDim2.new(0.5, -200, 0.03, 0)
end

-- ドラッグ機能（フレーム全体をドラッグ）
do
	local dragging = false
	local dragStart
	local startPos

	local function beginDrag(input)
		if not draggableEnabled then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end

	local function updateDrag(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement or (input.UserInputType == Enum.UserInputType.Touch and dragging) then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end

	mainFrame.InputBegan:Connect(beginDrag)
	UserInputService.InputChanged:Connect(updateDrag)
end

-- ハイライト管理
local activeHighlights = {} -- player -> highlight instance

local function clearHighlightForPlayer(targetPlayer)
	local h = activeHighlights[targetPlayer]
	if h and h.Parent then
		h:Destroy()
	end
	activeHighlights[targetPlayer] = nil
end

local function ensureHighlightForCharacter(char, color)
	if not char or not char.Parent then return nil end
	local existing = char:FindFirstChild("TPS_Aim_Highlight")
	if existing and existing:IsA("Highlight") then
		existing.FillColor = color
		existing.OutlineColor = color
		return existing
	else
		-- 既存がなければ作る
		if existing then existing:Destroy() end
		local highlight = Instance.new("Highlight")
		highlight.Name = "TPS_Aim_Highlight"
		highlight.FillColor = color
		highlight.OutlineColor = color
		highlight.FillTransparency = HIGHLIGHT_FILL_TRANSPARENCY
		highlight.OutlineTransparency = HIGHLIGHT_OUTLINE_TRANSPARENCY
		highlight.Parent = char
		return highlight
	end
end

-- チーム判定ヘルパー
local function hasTeams()
	-- 単純チェック：プレイヤーいずれかにTeamが非 nil かつチーム数>0
	local anyTeam = false
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl.Team and pl.Team.Name ~= "" then
			anyTeam = true
			break
		end
	end
	return anyTeam
end

local function isEnemy(pl)
	-- チームがない場合は全員敵扱い（FFA）
	if not hasTeams() then
		return true
	end
	-- プレイヤーに Team がなければ敵扱い
	if not pl.Team or not player.Team then
		return true
	end
	return pl.Team ~= player.Team
end

-- プレイヤー一覧を走査してハイライト更新
local function updateESP()
	if not espEnabled then
		-- 全消し
		for pl, _ in pairs(activeHighlights) do
			clearHighlightForPlayer(pl)
		end
		return
	end

	local localChar = player.Character
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame and cam.CFrame.Position or nil

	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= player and pl.Character and pl.Character.Parent then
			local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
			local humanoid = pl.Character:FindFirstChildOfClass("Humanoid")
			if hrp and humanoid and humanoid.Health > 0 then
				-- 距離制限
				local dist = camPos and (hrp.Position - camPos).Magnitude or 0
				if dist <= MAX_HIGHLIGHT_DISTANCE then
					-- 壁越しでも見えるようにするかどうかはオプションだが今回は単純に距離基準のみ
					local color = isEnemy(pl) and Color3.new(1,0,0) or Color3.new(0,1,0)
					local h = ensureHighlightForCharacter(pl.Character, color)
					activeHighlights[pl] = h

					-- 名前表示（任意）
					if SHOW_DISTANCE_TEXT then
						local bill = pl.Character:FindFirstChild("TPS_Aim_NameBillboard")
						if not bill then
							local bb = Instance.new("BillboardGui")
							bb.Name = "TPS_Aim_NameBillboard"
							bb.Adornee = hrp
							bb.Size = UDim2.new(0, 120, 0, 30)
							bb.AlwaysOnTop = true
							bb.Parent = pl.Character

							local lbl = Instance.new("TextLabel", bb)
							lbl.Size = UDim2.new(1, 1, 1, 0)
							lbl.BackgroundTransparency = 1
							lbl.TextColor3 = Color3.new(1,1,1)
							lbl.Font = Enum.Font.Gotham
							lbl.TextSize = 14
						end
						local bb = pl.Character:FindFirstChild("TPS_Aim_NameBillboard")
						if bb and bb:FindFirstChildOfClass("TextLabel") then
							bb.TextLabel.Text = pl.Name .. " <" .. math.floor(dist) .. ">"
						end
					end
				else
					clearHighlightForPlayer(pl)
					local bill = pl.Character:FindFirstChild("TPS_Aim_NameBillboard")
					if bill then bill:Destroy() end
				end
			else
				clearHighlightForPlayer(pl)
				local bill = pl.Character and pl.Character:FindFirstChild("TPS_Aim_NameBillboard")
				if bill then bill:Destroy() end
			end
		else
			-- 自分 or 無効キャラ
			if activeHighlights[pl] then clearHighlightForPlayer(pl) end
		end
	end
end

-- プレイヤー離脱・キャラ消滅時のクリーンアップ
Players.PlayerRemoving:Connect(function(pl)
	clearHighlightForPlayer(pl)
end)

Players.PlayerAdded:Connect(function(pl)
	-- 新しいプレイヤーのための初期化は特に不要（updateESP が対応）
end)

-- レンダーステップで虹色＆呼吸アニメ・ESP 更新
local startTick = tick()
RunService.RenderStepped:Connect(function()
	-- 虹色円のアニメーション（HSV -> RGB）
	if circleEnabled and circle.Visible then
		local hue = (tick() * 0.15) % 1
		local r,g,b = Color3.fromHSV(hue, 1, 1):ToRGB()
		-- UIStroke は Color3 を受け取るので直接代入
		circleStroke.Color = Color3.fromRGB(math.floor(r*255), math.floor(g*255), math.floor(b*255))
		-- 呼吸（拡大縮小）
		local scale = 1 + 0.05 * math.sin(tick() * 2)
		local baseSize = isMobile and 100 or 140
		local s = math.clamp(baseSize * scale, 60, 200)
		circle.Size = UDim2.new(0, s, 0, s)
	end

	-- ESP 更新（毎フレームだと重いなら間引きも検討）
	updateESP()
end)

-- スクリプト終了時にクリーンアップする関数
local function cleanupAll()
	for pl,_ in pairs(activeHighlights) do
		clearHighlightForPlayer(pl)
	end
	-- UI は PlayerGui にあるので破棄しておく
	if screenGui and screenGui.Parent then
		screenGui:Destroy()
	end
end

-- プレイヤーのキャラがリスポーンしたら何らかの調整が必要ならここで
player.CharacterAdded:Connect(function(char)
	-- 前のハイライトが残ってたらクリア
	for pl,_ in pairs(activeHighlights) do
		clearHighlightForPlayer(pl)
	end
end)

-- 終了ハンドラ（ゲーム終了時等）
game:BindToClose(function()
	cleanupAll()
end)

-- 最低限の注意書き表示（最初のみ）
do
	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.Size = UDim2.new(0, 200, 0, 28)
	hint.Position = UDim2.new(0, 10, 1, -38)
	hint.BackgroundTransparency = 0.5
	hint.BackgroundColor3 = Color3.fromRGB(0,0,0)
	hint.TextColor3 = Color3.fromRGB(255,255,255)
	hint.Text = "Aim Support UI loaded (表示のみ)"
	hint.Font = Enum.Font.SourceSans
	hint.TextSize = 14
	hint.Parent = mainFrame
	delay(3, function()
		if hint and hint.Parent then hint:Destroy() end
	end)
end
