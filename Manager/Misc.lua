--[[
	LuxyHub — Misc Manager (Universal)
	Repository: https://github.com/Anonimusluxydev404/LuxyHub

	Plug-and-play misc/utility module for any LuxyHub script.
	Usage:

		local Misc = loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/Anonimusluxydev404/LuxyHub/refs/heads/main/Manager/Misc.lua"
		))()
		local MiscTab = Window:AddTab("Misc", "menu")
		Misc:Setup(Library, MiscTab)
]]

-- ====================================================================
-- Services
-- ====================================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ====================================================================
-- Misc Module
-- ====================================================================
local Misc = {}

-- State
local S = {
	ESP = false,
	ESPConn = nil,
	ESPLeaveConn = nil,
	ESPDrawings = {},
	ESPBoxColor = Color3.fromRGB(0, 255, 0),
	ESPLineColor = Color3.fromRGB(255, 255, 255),

	Fly = false,
	FlyConn = nil,
	FlyParts = {},
	FlySpeed = 50,

	InfJump = false,
	InfJumpConn = nil,

	AntiAFK = false,
	AntiAFKIdledConn = nil,
	AntiAFKHeartConn = nil,

	FPSBoost = false,
	FPSOld = {},
	FPSDisabledFX = {},
	FPSConn = nil,

	RTXMode = false,
	RTXOld = {},

	BlackScreen = false,
	BScreenObj = nil,

	WhiteScreen = false,
	WScreenObj = nil,
}

-- ====================================================================
-- Feature: ESP
-- ====================================================================
local function ClearESP()
	for _, d in next, S.ESPDrawings do
		pcall(d.Box.Remove, d.Box)
		pcall(d.Text.Remove, d.Text)
		pcall(d.Line.Remove, d.Line)
	end
	S.ESPDrawings = {}
end

local function ToggleESP(on)
	if on then
		if S.ESP then return end
		S.ESP = true
		ClearESP()

		-- Player leave -> hapus drawing-nya LANGSUNG (anti ngarang/ghost)
		S.ESPLeaveConn = Players.PlayerRemoving:Connect(function(plr)
			local d = S.ESPDrawings[plr]
			if d then
				pcall(d.Box.Remove, d.Box)
				pcall(d.Text.Remove, d.Text)
				pcall(d.Line.Remove, d.Line)
				S.ESPDrawings[plr] = nil
			end
		end)

		S.ESPConn = RunService.RenderStepped:Connect(function()
			if not Camera then
				Camera = Workspace.CurrentCamera
				if not Camera then return end
			end
			local vpSize = Camera.ViewportSize

			for _, plr in Players:GetPlayers() do
				if plr == LocalPlayer then continue end
				local char = plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local drawings = S.ESPDrawings[plr]

				-- Ga punya char/HRP (leave/respawn) -> sembunyiin, jangan beku
				if not hrp then
					if drawings then
						drawings.Box.Visible = false
						drawings.Text.Visible = false
						drawings.Line.Visible = false
					end
					continue
				end

				local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
				-- Off-screen ATAU di belakang kamera -> sembunyiin (anti posisi aneh)
				if not onScreen or pos.Z < 0 then
					if drawings then
						drawings.Box.Visible = false
						drawings.Text.Visible = false
						drawings.Line.Visible = false
					end
					continue
				end

				if not drawings then
					local box = Drawing.new("Square")
					box.Thickness = 1
					box.Filled = false
					box.Color = S.ESPBoxColor
					box.Transparency = 0.75

					local txt = Drawing.new("Text")
					txt.Center = true
					txt.Outline = true
					txt.Size = 13
					txt.Color = S.ESPBoxColor

					local line = Drawing.new("Line")
					line.Thickness = 1
					line.Color = S.ESPLineColor
					line.Transparency = 0.3

					drawings = { Box = box, Text = txt, Line = line }
					S.ESPDrawings[plr] = drawings
				end

				local scale = hrp.Size.Y * 4
				local boxSize = Vector2.new(scale, scale * 1.5)
				local boxPos = Vector2.new(pos.X - boxSize.X / 2, pos.Y - boxSize.Y / 2)

				drawings.Box.Visible = true
				drawings.Box.Size = boxSize
				drawings.Box.Position = boxPos
				drawings.Box.Color = S.ESPBoxColor

				drawings.Text.Visible = true
				drawings.Text.Position = Vector2.new(pos.X, boxPos.Y - 15)
				drawings.Text.Text = plr.Name .. " [" .. math.floor((Camera.CFrame.Position - hrp.Position).Magnitude) .. "m]"
				drawings.Text.Color = S.ESPBoxColor

				drawings.Line.Visible = true
				drawings.Line.From = Vector2.new(vpSize.X / 2, vpSize.Y)
				drawings.Line.To = Vector2.new(pos.X, pos.Y)
				drawings.Line.Color = S.ESPLineColor
			end
		end)
	else
		if S.ESPConn then
			S.ESPConn:Disconnect()
			S.ESPConn = nil
		end
		if S.ESPLeaveConn then
			S.ESPLeaveConn:Disconnect()
			S.ESPLeaveConn = nil
		end
		ClearESP()
		S.ESP = false
	end
end

-- ====================================================================
-- Feature: Fly
-- ====================================================================
local function ToggleFly(on)
	if on then
		if S.Fly then return end
		local char = LocalPlayer.Character
		if not char then
			repeat task.wait() char = LocalPlayer.Character until char
		end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local bp = Instance.new("BodyPosition")
		bp.Position = hrp.Position
		bp.MaxForce = Vector3.new(1, 1, 1) * math.huge
		bp.P = 1000
		bp.D = 100
		bp.Parent = hrp

		local bg = Instance.new("BodyGyro")
		bg.MaxTorque = Vector3.new(1, 1, 1) * math.huge
		bg.P = 10000
		bg.D = 1000
		bg.CFrame = hrp.CFrame
		bg.Parent = hrp

		S.FlyParts = { bp, bg }
		S.Fly = true

		S.FlyConn = RunService.RenderStepped:Connect(function()
			if not hrp or not hrp.Parent then
				ToggleFly(false)
				return
			end
			if not Camera then Camera = Workspace.CurrentCamera end

			local move = Vector3.new()
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then
				move = move + Camera.CFrame.LookVector * Vector3.new(1, 0, 1)
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then
				move = move - Camera.CFrame.LookVector * Vector3.new(1, 0, 1)
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then
				move = move - Camera.CFrame.RightVector * Vector3.new(1, 0, 1)
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
				move = move + Camera.CFrame.RightVector * Vector3.new(1, 0, 1)
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				move = move + Vector3.new(0, 1, 0)
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
				or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
				move = move + Vector3.new(0, -1, 0)
			end

			if move.Magnitude > 0 then
				move = move.Unit * S.FlySpeed
			end

			bp.Position = hrp.Position + move * 0.1
			bg.CFrame = Camera.CFrame
		end)
	else
		if S.FlyConn then
			S.FlyConn:Disconnect()
			S.FlyConn = nil
		end
		for _, p in S.FlyParts do
			pcall(p.Destroy, p)
		end
		S.FlyParts = {}
		S.Fly = false
	end
end

-- ====================================================================
-- Feature: Infinite Jump
-- ====================================================================
local function ToggleInfJump(on)
	if on then
		if S.InfJump then return end
		S.InfJump = true
		S.InfJumpConn = UserInputService.JumpRequest:Connect(function()
			local char = LocalPlayer.Character
			if not char then return end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.Velocity = Vector3.new(hrp.Velocity.X, 50, hrp.Velocity.Z)
			end
		end)
	else
		if S.InfJumpConn then
			S.InfJumpConn:Disconnect()
			S.InfJumpConn = nil
		end
		S.InfJump = false
	end
end

-- ====================================================================
-- Feature: Anti AFK (100% work, safe — no click spam, no ESP break)
-- ====================================================================
local function ToggleAntiAFK(on)
	if on then
		if S.AntiAFK then return end
		S.AntiAFK = true

		-- Method 1: Hook Idled (fires only when Roblox detects you idle)
		-- No heartbeat click spam so it never interferes with ESP/render.
		S.AntiAFKIdledConn = LocalPlayer.Idled:Connect(function()
			task.spawn(function()
				task.wait(0.1)
				VirtualUser:CaptureController()
				VirtualUser:ClickButton1(Vector2.new())
			end)
		end)

		-- Method 2: Gentle pose reset (no clicks)
		S.AntiAFKHeartConn = RunService.Heartbeat:Connect(function()
			local char = LocalPlayer.Character
			if not char then return end
			local hum = char:FindFirstChild("Humanoid")
			if hum then
				if hum.PlatformStand then hum.PlatformStand = false end
				if hum.Sit then hum.Sit = false end
			end
		end)
	else
		S.AntiAFK = false
		if S.AntiAFKIdledConn then
			S.AntiAFKIdledConn:Disconnect()
			S.AntiAFKIdledConn = nil
		end
		if S.AntiAFKHeartConn then
			S.AntiAFKHeartConn:Disconnect()
			S.AntiAFKHeartConn = nil
		end
	end
end

-- ====================================================================
-- Feature: FPS Boost (BRUTAL — like Grow A Garden 2 / Kalb)
-- Plastic everything, no decals, no textures, no lights, no particles
-- ====================================================================
local function ApplyBrutalFPS()
	for _, v in Workspace:GetDescendants() do
		pcall(function()
			if v:IsA("BasePart") then
				v.Material = Enum.Material.SmoothPlastic
				v.CastShadow = false
				v.Reflectance = 0
				if v:IsA("MeshPart") then
					v.TextureID = ""
				end
			elseif v:IsA("Decal") or v:IsA("Texture") then
				v.Transparency = 1
			elseif v:IsA("SpecialMesh") then
				v.TextureId = ""
			elseif v:IsA("ParticleEmitter") or v:IsA("Sparkles") or v:IsA("Smoke") or v:IsA("Fire") then
				v.Enabled = false
			elseif v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then
				v:Destroy()
			elseif v:IsA("Light") then
				v.Enabled = false
			end
		end)
	end
end

local function ToggleFPSBoost(on)
	if on then
		if S.FPSBoost then return end
		S.FPSBoost = true

		-- Save lighting
		S.FPSOld = {
			GlobalShadows = Lighting.GlobalShadows,
			FogEnd = Lighting.FogEnd,
			FogStart = Lighting.FogStart,
			Ambient = Lighting.Ambient,
			Brightness = Lighting.Brightness,
			Technology = Lighting.Technology,
		}

		-- Disable all post effects (bloom, sunrays, color correction, blur, dof)
		S.FPSDisabledFX = {}
		for _, v in Lighting:GetChildren() do
			if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("SunRaysEffect")
				or v:IsA("ColorCorrectionEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") then
				if v.Enabled then
					table.insert(S.FPSDisabledFX, v)
					v.Enabled = false
				end
			end
		end

		-- Kill visuals
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 9e9
		Lighting.FogStart = 9e9
		Lighting.Brightness = 0
		Lighting.Ambient = Color3.new(1, 1, 1)
		pcall(function() Lighting.Technology = Enum.Technology.Compat end)

		-- Lowest graphics quality
		pcall(function()
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		end)
		pcall(function()
			local rs = game:GetService("RenderSettings")
			rs.MaterialQualityLevel = Enum.MaterialQuality.Low
		end)

		-- Decal lifetime
		pcall(function() Workspace.DecalLifetime = 0 end)

		-- Brutal pass
		ApplyBrutalFPS()

		-- Keep new parts plastic
		S.FPSConn = Workspace.DescendantAdded:Connect(function(v)
			task.spawn(function()
				task.wait(0.1)
				pcall(function()
					if v:IsA("BasePart") then
						v.Material = Enum.Material.SmoothPlastic
						v.CastShadow = false
						v.Reflectance = 0
						if v:IsA("MeshPart") then v.TextureID = "" end
					elseif v:IsA("Decal") or v:IsA("Texture") then
						v.Transparency = 1
					elseif v:IsA("SpecialMesh") then
						v.TextureId = ""
					elseif v:IsA("ParticleEmitter") or v:IsA("Sparkles") or v:IsA("Smoke") or v:IsA("Fire") then
						v.Enabled = false
					elseif v:IsA("Light") then
						v.Enabled = false
					end
				end)
			end)
		end)
	else
		-- Restore lighting
		for k, v in next, S.FPSOld do
			pcall(function() Lighting[k] = v end)
		end
		S.FPSOld = {}

		-- Restore post effects
		for _, fx in S.FPSDisabledFX do
			pcall(function() fx.Enabled = true end)
		end
		S.FPSDisabledFX = {}

		if S.FPSConn then
			S.FPSConn:Disconnect()
			S.FPSConn = nil
		end

		-- Restore graphics
		pcall(function()
			settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
		end)

		S.FPSBoost = false
	end
end

-- ====================================================================
-- Feature: RTX Mode (PC Dewa — max realistic)
-- ====================================================================
local function ToggleRTXMode(on)
	if on then
		if S.RTXMode then return end
		S.RTXMode = true

		S.RTXOld = {
			GlobalShadows = Lighting.GlobalShadows,
			FogEnd = Lighting.FogEnd,
			FogStart = Lighting.FogStart,
			Ambient = Lighting.Ambient,
			Brightness = Lighting.Brightness,
			ColorShift_Top = Lighting.ColorShift_Top,
			ColorShift_Bottom = Lighting.ColorShift_Bottom,
			Technology = Lighting.Technology,
			OutdoorAmbient = Lighting.OutdoorAmbient,
			ClockTime = Lighting.ClockTime,
			GeographicLatitude = Lighting.GeographicLatitude,
			ExposureCompensation = Lighting.ExposureCompensation,
			EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
			EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
		}

		-- Future lighting
		pcall(function() Lighting.Technology = Enum.Technology.Future end)
		Lighting.GlobalShadows = true
		Lighting.Ambient = Color3.fromRGB(60, 60, 70)
		Lighting.Brightness = 1.8
		Lighting.OutdoorAmbient = Color3.fromRGB(130, 140, 160)
		Lighting.FogEnd = 1e10
		Lighting.FogStart = 0
		Lighting.ClockTime = 14.5
		Lighting.GeographicLatitude = 41.9
		Lighting.ExposureCompensation = 0.5
		Lighting.EnvironmentDiffuseScale = 1.2
		Lighting.EnvironmentSpecularScale = 1.5

		-- Max graphics quality
		pcall(function()
			local rs = game:GetService("RenderSettings")
			rs.QualityLevel = 21
			rs.MaterialQualityLevel = Enum.MaterialQuality.High
		end)

		-- Force high-quality materials on all parts
		task.spawn(function()
			while S.RTXMode do
				task.wait(0.5)
				for _, v in Workspace:GetDescendants() do
					if v:IsA("BasePart") and not v:IsA("Terrain") then
						pcall(function()
							if v.Material == Enum.Material.Plastic then
								v.Material = Enum.Material.SmoothPlastic
							end
							v.CastShadow = true
						end)
					end
				end
			end
		end)
	else
		for k, v in next, S.RTXOld do
			pcall(function() Lighting[k] = v end)
		end
		S.RTXOld = {}
		S.RTXMode = false
	end
end

-- ====================================================================
-- Feature: Screen Overlay (Black / White fullscreen + logo + title)
-- ====================================================================
local LOGO_ID = "rbxassetid://119236006737744"

local function BuildScreen(color, name, on, titleColor)
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 999

	-- Fullscreen frame
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 0
	frame.BorderSizePixel = 0
	frame.ZIndex = 1
	frame.Parent = gui

	-- Center container
	local center = Instance.new("Frame")
	center.AnchorPoint = Vector2.new(0.5, 0.5)
	center.BackgroundTransparency = 1
	center.Position = UDim2.fromScale(0.5, 0.5)
	center.Size = UDim2.fromOffset(400, 200)
	center.ZIndex = 2
	center.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 12)
	layout.Parent = center

	-- Logo
	local logo = Instance.new("ImageLabel")
	logo.AnchorPoint = Vector2.new(0.5, 0.5)
	logo.BackgroundTransparency = 1
	logo.Position = UDim2.fromScale(0.5, 0.5)
	logo.Size = UDim2.fromOffset(120, 120)
	logo.Image = LOGO_ID
	logo.ZIndex = 3
	logo.Parent = center

	-- Title
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Text = "LuxyHub"
	title.TextColor3 = titleColor or Color3.fromRGB(255, 255, 255)
	title.TextSize = 34
	title.ZIndex = 3
	title.Parent = center

	local parent = CoreGui
	if not parent then parent = LocalPlayer:FindFirstChild("PlayerGui") end
	if parent then
		gui.Parent = parent
		if on then S.BScreenObj = gui else S.WScreenObj = gui end
	end
end

local function ToggleBlackScreen(on)
	if on then
		if S.BScreenObj then return end
		-- Turn off white screen if active
		if S.WScreenObj then
			pcall(S.WScreenObj.Destroy, S.WScreenObj)
			S.WScreenObj = nil
		end
		BuildScreen(Color3.new(0, 0, 0), "LuxyBlackScreen", true, Color3.fromRGB(255, 255, 255))
	else
		if S.BScreenObj then
			pcall(S.BScreenObj.Destroy, S.BScreenObj)
			S.BScreenObj = nil
		end
	end
end

local function ToggleWhiteScreen(on)
	if on then
		if S.WScreenObj then return end
		-- Turn off black screen if active
		if S.BScreenObj then
			pcall(S.BScreenObj.Destroy, S.BScreenObj)
			S.BScreenObj = nil
		end
		BuildScreen(Color3.new(1, 1, 1), "LuxyWhiteScreen", false, Color3.fromRGB(0, 0, 0))
	else
		if S.WScreenObj then
			pcall(S.WScreenObj.Destroy, S.WScreenObj)
			S.WScreenObj = nil
		end
	end
end

-- ====================================================================
-- Setup: Builds the Misc tab UI and wires features
-- ====================================================================
function Misc:Setup(Library, Tab)
	-- ================================================================
	-- GENERAL
	-- ================================================================
	local General = Tab:AddLeftGroupbox("General", "zap")

	General:AddToggle("Misc_ESP", {
		Text = "ESP",
		Callback = function(v) ToggleESP(v) end,
	})

	General:AddToggle("Misc_Fly", {
		Text = "Fly",
		Callback = function(v) ToggleFly(v) end,
	})

	General:AddToggle("Misc_InfJump", {
		Text = "Infinite Jump",
		Callback = function(v) ToggleInfJump(v) end,
	})

	-- Anti AFK: ON by default
	General:AddToggle("Misc_AntiAFK", {
		Text = "Anti AFK",
		Default = true,
		Callback = function(v) ToggleAntiAFK(v) end,
	})

	-- ================================================================
	-- ESP SETTINGS
	-- ================================================================
	local ESPSettings = General:AddLabel("ESP Color")
	ESPSettings:AddColorPicker("Misc_ESP_BoxColor", {
		Default = Color3.fromRGB(0, 255, 0),
		Title = "Box Color",
		Callback = function(v)
			S.ESPBoxColor = v
		end,
	})

	ESPSettings:AddColorPicker("Misc_ESP_LineColor", {
		Default = Color3.fromRGB(255, 255, 255),
		Title = "Tracer Line Color",
		Callback = function(v)
			S.ESPLineColor = v
		end,
	})

	-- ================================================================
	-- PERFORMANCE
	-- ================================================================
	local Perf = Tab:AddRightGroupbox("Performance", "monitor")

	Perf:AddToggle("Misc_FPSBoost", {
		Text = "FPS Boost",
		Callback = function(v)
			if v and S.RTXMode then
				Library:Notify("Turn off RTX Mode first!", 3)
				return
			end
			ToggleFPSBoost(v)
		end,
	})

	Perf:AddToggle("Misc_RTXMode", {
		Text = "RTX Mode",
		Callback = function(v)
			if v and S.FPSBoost then
				Library:Notify("Turn off FPS Boost first!", 3)
				return
			end
			ToggleRTXMode(v)
		end,
	})

	Perf:AddToggle("Misc_BlackScreen", {
		Text = "Black Screen",
		Callback = function(v) ToggleBlackScreen(v) end,
	})

	Perf:AddToggle("Misc_WhiteScreen", {
		Text = "White Screen",
		Callback = function(v) ToggleWhiteScreen(v) end,
	})
end

return Misc
