-- CoinPopup.client.luau
-- Flyvende "+X" popup når man sælger fisk. Ren visuel effekt -- rører ingen logik.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local spiller = Players.LocalPlayer
local FormatNumber = require(ReplicatedStorage:WaitForChild("FormatNumber"))
local sellPopup = ReplicatedStorage:WaitForChild("SellPopup")

-- === STIL (nem at ændre her) ===
local STIL = {
	farve = Color3.fromRGB(90, 230, 120),   -- grøn tekst
	varighed = 1,                            -- sekunder før den er væk
	loeft = 60,                              -- hvor mange pixels den flyver opad
	tekstHoejde = 34,                        -- skriftstørrelse
	startX = 250,                            -- lige til højre for HUD-boksen
	startY = 30,
}

local skaerm = Instance.new("ScreenGui")
skaerm.Name = "CoinPopup"
skaerm.ResetOnSpawn = false
skaerm.Parent = spiller:WaitForChild("PlayerGui")

sellPopup.OnClientEvent:Connect(function(beloeb)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = STIL.tekstHoejde
	label.TextColor3 = STIL.farve
	label.TextStrokeTransparency = 0.6                 -- let mørk kant = lettere at læse
	label.Text = "+" .. FormatNumber(beloeb)           -- samme K/M/B-formatering som resten
	label.Size = UDim2.new(0, 200, 0, 40)
	label.TextXAlignment = Enum.TextXAlignment.Left
	-- lille tilfældig forskydning, så flere hurtige salg ikke ligger præcis oven i hinanden
	label.Position = UDim2.new(0, STIL.startX + math.random(-8, 8), 0, STIL.startY + math.random(-6, 6))
	label.Parent = skaerm

	-- Flyv opad og fade ud på én gang
	local tween = TweenService:Create(
		label,
		TweenInfo.new(STIL.varighed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = label.Position - UDim2.new(0, 0, 0, STIL.loeft),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}
	)
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()                                -- ryd op når den er faldet ud
	end)
end)
