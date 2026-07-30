--[[
	LuxyHub — Misc Manager (Universal)
	Repository: https://github.com/Anonimusluxydev404/LuxyHub

	A plug-and-play misc/utility module for any LuxyHub script.
	Simply load and setup:

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
	ESPDrawings = {},

	Fly = false,
	FlyConn = nil,
	FlyParts = {},
	FlySpeed = 50,

	InfJump = false,
	InfJumpConn = nil,

	AntiAFK = false,
	AntiAFKConn = nil,

	FPSBoost = false,
	FPSOld = {},

	RTXMode = false,
	RTXOld = {},

	BlackScreen = false,
	BScreenObj = nil,
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
		ClearESP()

		S.ESPConn = RunService.RenderStepped:Connect(function()
			if not Camera then
				Camera = Workspace.CurrentCamera
			end
			local vpSize = Camera.ViewportSize

			for _, plr in Players:GetPlayers() do
				if plr == LocalPlayer then
					continue
				end
				local char = plr.Character
				if not char then
					continue
				end
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if not hrp then
					continue
				end

				local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
				if not onScreen then
					if S.ESPDrawings[plr] then
						S.ESPDrawings[plr].Box.Visible = false
						S.ESPDrawings[plr].Text.Visible = false
						S.ESPDrawings[plr].Line.Visible = false
					end
					continue
				end

				if not S.ESPDrawings[plr] then
					local color = Color3.fromRGB(0, 255, 0)
					if plr.TeamColor and LocalPlayer.TeamColor then
						if plr.TeamColor ~= LocalPlayer.TeamColor then
							color = Color3.fromRGB(255, 80, 80)
						end
					end

					local box = Drawing.new("Square")
					box.Thickness = 1
					box.Filled = false
					box.Color = color
					box.Transparency = 0.75

					local txt = Drawing.new("Text")
					txt.Center = true
					txt.Outline = true
					txt.Size = 13
					txt.Color = color

					local line = Drawing.new("Line")
					line.Thickness = 1
					line.Color = Color3.fromRGB(255, 255, 255)
					line.Transparency = 0.3

					S.ESPDrawings[plr] = { Box = box, Text = txt, Line = line }
				end

				local drawings = S.ESPDrawings[plr]
				local scale = hrp.Size.Y * 4
				local boxSize = Vector2.new(scale, scale * 1.5)
				local boxPos = Vector2.new(pos.X - boxSize.X / 2, pos.Y - boxSize.Y / 2)

				drawings.Box.Visible = true
				drawings.Box.Size = boxSize
				drawings.Box.Position = boxPos

				drawings.Text.Visible = true
				drawings.Text.Position = Vector2.new(pos.X, boxPos.Y - 15)
				drawings.Text.Text = plr.Name
					.. " ["
					.. math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)
					.. "m]"

				drawings.Line.Visible = true
				drawings.Line.From = Vector2.new(vpSize.X / 2, vpSize.Y)
				drawings.Line.To = Vector2.new(pos.X, pos.Y)
			end
		end)
	else
		if S.ESPConn then
			S.ESPConn:Disconnect()
			S.ESPConn = nil
		end
		ClearESP()
	end
end

-- ====================================================================
-- Feature: Fly
-- ====================================================================
local function ToggleFly(on)
	if on then
		local char = LocalPlayer.Character
		if not char then
			repeat
				task.wait()
				char = LocalPlayer.Character
			until char
		end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end

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

		S.FlyConn = RunService.RenderStepped:Connect(function()
			if not hrp or not hrp.Parent then
				ToggleFly(false)
				return
			end

			if not Camera then
				Camera = Workspace.CurrentCamera
			end

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
			if
				UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
				or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
			then
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
	end
end

-- ====================================================================
-- Feature: Infinite Jump
-- ====================================================================
local function ToggleInfJump(on)
	if on then
		S.InfJumpConn = UserInputService.JumpRequest:Connect(function()
			local char = LocalPlayer.Character
			if not char then
				return
			end
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
	end
end

-- ====================================================================
-- Feature: Anti AFK (VirtualUser)
-- ====================================================================
local function ToggleAntiAFK(on)
	if on then
		LocalPlayer.Idled:Connect(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton1(Vector2.new())
		end)

		S.AntiAFKConn = RunService.Stepped:Connect(function()
			local char = LocalPlayer.Character
			if not char then
				return
			end
			local hum = char:FindFirstChild("Humanoid")
			if hum then
				if hum.PlatformStand then
					hum.PlatformStand = false
				end
				if hum.Sit then
					hum.Sit = false
				end
			end
		end)
	else
		if S.AntiAFKConn then
			S.AntiAFKConn:Disconnect()
			S.AntiAFKConn = nil
		end
	end
end

-- ====================================================================
-- Feature: FPS Boost
-- ====================================================================
local function ToggleFPSBoost(on)
	if on then
		S.FPSOld = {
			GlobalShadows = Lighting.GlobalShadows,
			FogEnd = Lighting.FogEnd,
			Ambient = Lighting.Ambient,
			Brightness = Lighting.Brightness,
			ColorShift_Top = Lighting.ColorShift_Top,
			ColorShift_Bottom = Lighting.ColorShift_Bottom,
		}

		Lighting.GlobalShadows = false
		Lighting.FogEnd = 1e10
		Lighting.Brightness = 1.5

		-- Disable terrain decorations
		Workspace.DecalLifetime = 0

		-- Lower graphics
		pcall(function()
			local rs = game:GetService("RenderSettings")
			rs.QualityLevel = 1
			rs.MaterialQualityLevel = Enum.MaterialQuality.Low
		end)
	else
		for k, v in next, S.FPSOld do
			pcall(function()
				Lighting[k] = v
			end)
		end
		S.FPSOld = {}
	end
end

-- ====================================================================
-- Feature: RTX Mode
-- ====================================================================
local function ToggleRTXMode(on)
	if on then
		S.RTXOld = {
			GlobalShadows = Lighting.GlobalShadows,
			Ambient = Lighting.Ambient,
			Brightness = Lighting.Brightness,
			FogEnd = Lighting.FogEnd,
			ColorShift_Top = Lighting.ColorShift_Top,
			ColorShift_Bottom = Lighting.ColorShift_Bottom,
			Technology = Lighting.Technology,
			OutdoorAmbient = Lighting.OutdoorAmbient,
		}

		Lighting.GlobalShadows = true
		Lighting.Ambient = Color3.fromRGB(80, 80, 80)
		Lighting.Brightness = 2
		Lighting.FogEnd = 1e10
		pcall(function()
			Lighting.Technology = Enum.Technology.Future
		end)

		-- Max graphics
		pcall(function()
			local rs = game:GetService("RenderSettings")
			rs.QualityLevel = 21
			rs.MaterialQualityLevel = Enum.MaterialQuality.High
		end)

		-- Better ambient
		pcall(function()
			Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
		end)
	else
		for k, v in next, S.RTXOld do
			pcall(function()
				Lighting[k] = v
			end)
		end
		S.RTXOld = {}
	end
end

-- ====================================================================
-- Feature: Black Screen
-- ====================================================================
local function ToggleBlackScreen(on)
	if on then
		local gui = Instance.new("ScreenGui")
		gui.Name = "LuxyBlackScreen"
		gui.ResetOnSpawn = false
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.new(0, 0, 0)
		frame.BackgroundTransparency = 0
		frame.BorderSizePixel = 0
		frame.Parent = gui

		local parent = CoreGui
		if not parent then
			parent = LocalPlayer:FindFirstChild("PlayerGui")
		end
		if parent then
			gui.Parent = parent
			S.BScreenObj = gui
		end
	else
		if S.BScreenObj then
			pcall(S.BScreenObj.Destroy, S.BScreenObj)
			S.BScreenObj = nil
		end
	end
end

-- ====================================================================
-- Setup: Builds the Misc tab UI and wires features
-- ====================================================================
function Misc:Setup(Library, Tab)
	-- General controls (left side)
	local General = Tab:AddLeftGroupbox("General", "user")

	General:AddToggle("Misc_ESP", {
		Text = "ESP",
		Tooltip = "Show player ESP boxes with distance",
		Callback = function(v)
			ToggleESP(v)
		end,
	})

	General:AddToggle("Misc_Fly", {
		Text = "Fly",
		Tooltip = "Flight mode (WASD move, Space up, Shift down)",
		Callback = function(v)
			ToggleFly(v)
		end,
	})

	General:AddToggle("Misc_InfJump", {
		Text = "Infinite Jump",
		Tooltip = "Hold Space to jump infinitely",
		Callback = function(v)
			ToggleInfJump(v)
		end,
	})

	General:AddToggle("Misc_AntiAFK", {
		Text = "Anti AFK",
		Tooltip = "Prevent being kicked for being idle",
		Callback = function(v)
			ToggleAntiAFK(v)
		end,
	})

	General:AddDivider()
	General:AddLabel("Controls: WASD to move, Space up, Shift down")

	-- Performance controls (right side)
	local Perf = Tab:AddRightGroupbox("Performance", "zap")

	Perf:AddToggle("Misc_FPSBoost", {
		Text = "FPS Boost",
		Tooltip = "Disable shadows & effects for higher FPS",
		Callback = function(v)
			ToggleFPSBoost(v)
		end,
	})

	Perf:AddToggle("Misc_RTXMode", {
		Text = "RTX Mode",
		Tooltip = "Max out graphics quality",
		Callback = function(v)
			ToggleRTXMode(v)
		end,
	})

	Perf:AddToggle("Misc_BlackScreen", {
		Text = "Black Screen",
		Tooltip = "Cover the screen with a black overlay",
		Callback = function(v)
			ToggleBlackScreen(v)
		end,
	})

	Perf:AddDivider()
	Perf:AddLabel("Note: FPS Boost & RTX Mode are mutually exclusive.")
end

return Misc
