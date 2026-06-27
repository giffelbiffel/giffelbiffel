-- Shop.client.luau
-- Shop-menuen på MIN skærm. Åbner når jeg rører shop-kassen.
-- Selve købet sker på serveren -- her sender vi bare en besked afsted.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local spiller = Players.LocalPlayer

-- Find walkie-talkien, som serveren lavede
local buyFisher = ReplicatedStorage:WaitForChild("BuyFisher")

-- === Byg menuen (skjult fra start) ===
local skaerm = Instance.new("ScreenGui")
skaerm.Name = "ShopMenu"
skaerm.ResetOnSpawn = false
skaerm.Enabled = false                          -- usynlig indtil jeg rører shoppen
skaerm.Parent = spiller:WaitForChild("PlayerGui")

-- Selve vinduet (midt på skærmen)
local vindue = Instance.new("Frame")
vindue.Size = UDim2.new(0, 300, 0, 220)
vindue.Position = UDim2.new(0.5, -150, 0.5, -110)   -- centreret
vindue.BackgroundColor3 = Color3.fromRGB(25, 35, 55)
vindue.Parent = skaerm

local vindueHjoerne = Instance.new("UICorner")
vindueHjoerne.CornerRadius = UDim.new(0, 12)
vindueHjoerne.Parent = vindue

-- Titel "SHOP"
local titel = Instance.new("TextLabel")
titel.Size = UDim2.new(1, 0, 0, 40)
titel.Position = UDim2.new(0, 0, 0, 10)
titel.BackgroundTransparency = 1
titel.Text = "SHOP"
titel.TextColor3 = Color3.fromRGB(255, 255, 255)
titel.Font = Enum.Font.GothamBold
titel.TextScaled = true
titel.Parent = vindue

-- Vare-tekst
local vare = Instance.new("TextLabel")
vare.Size = UDim2.new(1, -40, 0, 40)
vare.Position = UDim2.new(0, 20, 0, 60)
vare.BackgroundTransparency = 1
vare.Text = "Basic Fisher - 50 fish"
vare.TextColor3 = Color3.fromRGB(220, 230, 245)
vare.Font = Enum.Font.Gotham
vare.TextScaled = true
vare.Parent = vindue

-- Køb-knap
local koebKnap = Instance.new("TextButton")
koebKnap.Size = UDim2.new(0, 120, 0, 40)
koebKnap.Position = UDim2.new(0, 30, 0, 120)
koebKnap.BackgroundColor3 = Color3.fromRGB(60, 200, 90)
koebKnap.Text = "Buy"
koebKnap.TextColor3 = Color3.fromRGB(255, 255, 255)
koebKnap.Font = Enum.Font.GothamBold
koebKnap.TextScaled = true
koebKnap.Parent = vindue
Instance.new("UICorner").Parent = koebKnap

-- Luk-knap
local lukKnap = Instance.new("TextButton")
lukKnap.Size = UDim2.new(0, 120, 0, 40)
lukKnap.Position = UDim2.new(0, 150, 0, 120)
lukKnap.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
lukKnap.Text = "Close"
lukKnap.TextColor3 = Color3.fromRGB(255, 255, 255)
lukKnap.Font = Enum.Font.GothamBold
lukKnap.TextScaled = true
lukKnap.Parent = vindue
Instance.new("UICorner").Parent = lukKnap

-- Besked-linje (fx "Not enough fish")
local besked = Instance.new("TextLabel")
besked.Size = UDim2.new(1, -40, 0, 30)
besked.Position = UDim2.new(0, 20, 0, 175)
besked.BackgroundTransparency = 1
besked.Text = ""
besked.Font = Enum.Font.Gotham
besked.TextScaled = true
besked.Parent = vindue


-- === Åbn menuen når jeg rører shop-kassen ===
local shop = workspace:WaitForChild("Shop")
shop.Touched:Connect(function(andetObjekt)
	if andetObjekt.Parent == spiller.Character then   -- var det MIG der rørte?
		besked.Text = ""                              -- ryd gammel besked
		skaerm.Enabled = true                         -- vis menuen
	end
end)

-- Luk-knappen skjuler menuen
lukKnap.MouseButton1Click:Connect(function()
	skaerm.Enabled = false
end)

-- Køb-knappen sender en besked til serveren via walkie-talkien
koebKnap.MouseButton1Click:Connect(function()
	buyFisher:FireServer()
end)

-- Serveren svarer tilbage -- vis om købet lykkedes
buyFisher.OnClientEvent:Connect(function(lykkedes, tekst)
	besked.Text = tekst
	if lykkedes then
		besked.TextColor3 = Color3.fromRGB(90, 230, 120)   -- grøn
	else
		besked.TextColor3 = Color3.fromRGB(240, 90, 90)    -- rød
	end
end)
