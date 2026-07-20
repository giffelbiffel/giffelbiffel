-- UpgradeMenu.client.luau
-- Upgrade-menu for fisker-typer. Åbnes ved at KLIKKE på en placeret fisker.
-- Serveren sender status (spor, niveauer, priser) -- vi tegner den bare.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local spiller = Players.LocalPlayer

local upgradeEvent = ReplicatedStorage:WaitForChild("Upgrade")
local FormatNumber = require(ReplicatedStorage:WaitForChild("FormatNumber"))
local AnimerKnap = require(ReplicatedStorage:WaitForChild("ButtonAnimation"))
local Responsive = require(ReplicatedStorage:WaitForChild("Responsive"))

local senesteStatus = nil

-- Pæne navne til sporene
local SPOR_TEKST = {
	speed = "Speed",
	capacity = "Capacity",
	catchChance = "Catch Chance",
}

-- === Skærm-lag ===
local skaerm = Instance.new("ScreenGui")
skaerm.Name = "UpgradeMenu"
skaerm.ResetOnSpawn = false
skaerm.Parent = spiller:WaitForChild("PlayerGui")

local vindue = Instance.new("Frame")
vindue.AnchorPoint = Vector2.new(0.5, 0.5)
vindue.Position = UDim2.new(0.5, 0, 0.5, 0)
vindue.Size = UDim2.new(0, 400, 0, 0)
vindue.AutomaticSize = Enum.AutomaticSize.Y      -- højden følger indholdet
vindue.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
vindue.Visible = false
vindue.Parent = skaerm
Instance.new("UICorner").Parent = vindue
Responsive(vindue)   -- skalér hele upgrade-menuen på små skærme

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = vindue

local polstring = Instance.new("UIPadding")
polstring.PaddingTop = UDim.new(0, 12)
polstring.PaddingBottom = UDim.new(0, 12)
polstring.Parent = vindue

local titel = Instance.new("TextLabel")
titel.LayoutOrder = 0
titel.Size = UDim2.new(0, 360, 0, 36)
titel.BackgroundTransparency = 1
titel.Text = "UPGRADE"
titel.TextColor3 = Color3.fromRGB(255, 255, 255)
titel.Font = Enum.Font.GothamBold
titel.TextScaled = true
titel.Parent = vindue

-- Luk-knap (fast nederst via LayoutOrder)
local lukKnap = Instance.new("TextButton")
lukKnap.LayoutOrder = 999
lukKnap.Size = UDim2.new(0, 360, 0, 40)
lukKnap.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
lukKnap.Text = "Close"
lukKnap.TextColor3 = Color3.fromRGB(255, 255, 255)
lukKnap.Font = Enum.Font.GothamBold
lukKnap.TextScaled = true
lukKnap.Parent = vindue
Instance.new("UICorner").Parent = lukKnap
AnimerKnap(lukKnap)

lukKnap.MouseButton1Click:Connect(function()
	vindue.Visible = false
end)


-- === Tegn menuen ud fra serverens status ===
local function tegnMenu()
	local s = senesteStatus
	if not s then return end

	titel.Text = "UPGRADE - " .. s.fisher

	-- Ryd gamle spor-rækker (alt med navnet "SporRaekke")
	for _, barn in vindue:GetChildren() do
		if barn.Name == "SporRaekke" then
			barn:Destroy()
		end
	end

	local coins = spiller:GetAttribute("Coins") or 0

	for i, t in s.tracks do
		local raekke = Instance.new("Frame")
		raekke.Name = "SporRaekke"
		raekke.LayoutOrder = i
		raekke.Size = UDim2.new(0, 360, 0, 64)
		raekke.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
		raekke.Parent = vindue
		Instance.new("UICorner").Parent = raekke

		-- Info-tekst til venstre: navn, niveau, samlet bonus
		local info = Instance.new("TextLabel")
		info.Size = UDim2.new(0, 210, 1, -12)
		info.Position = UDim2.new(0, 10, 0, 6)
		info.BackgroundTransparency = 1
		info.TextColor3 = Color3.fromRGB(230, 230, 235)
		info.Font = Enum.Font.Gotham
		info.TextScaled = true
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.Text = SPOR_TEKST[t.track] .. "  Lv " .. t.level .. "/" .. t.maxLevel
			.. "\nBonus: +" .. t.totalBonus .. "%"
		info.Parent = raekke

		-- Køb-knap til højre
		local knap = Instance.new("TextButton")
		knap.Size = UDim2.new(0, 120, 0, 44)
		knap.Position = UDim2.new(1, -130, 0.5, -22)
		knap.TextColor3 = Color3.fromRGB(255, 255, 255)
		knap.Font = Enum.Font.GothamBold
		knap.TextScaled = true
		knap.Parent = raekke
		Instance.new("UICorner").Parent = knap
		AnimerKnap(knap)

		if t.nextPrice then
			knap.Text = FormatNumber(t.nextPrice) .. "c  (+" .. t.nextBonus .. "%)"
			if coins >= t.nextPrice then
				knap.BackgroundColor3 = Color3.fromRGB(60, 200, 90)    -- grøn: har råd
				knap.MouseButton1Click:Connect(function()
					upgradeEvent:FireServer("buy", s.fisher, t.track)
				end)
			else
				knap.BackgroundColor3 = Color3.fromRGB(200, 70, 70)    -- rød: for dyrt
			end
		else
			knap.Text = "MAX"
			knap.BackgroundColor3 = Color3.fromRGB(90, 90, 95)         -- grå: max niveau
		end
	end
end

-- Serveren sender status: ved klik på en fisker OG efter hvert køb
upgradeEvent.OnClientEvent:Connect(function(status)
	senesteStatus = status
	tegnMenu()
	vindue.Visible = true
end)

-- Coins ændrer sig (fx salg) -> gentegn knappernes farver, mens menuen er åben
spiller:GetAttributeChangedSignal("Coins"):Connect(function()
	if vindue.Visible then
		tegnMenu()
	end
end)
