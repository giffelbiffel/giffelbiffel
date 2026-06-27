-- Shop.client.luau
-- Shop-menu + placering. Køb i menuen, klik så på plottet for at placere fiskeren.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local spiller = Players.LocalPlayer
local mus = spiller:GetMouse()                 -- musen -- ved hvor jeg peger i 3D-verdenen

-- De to walkie-talkier fra serveren
local buyFisher = ReplicatedStorage:WaitForChild("BuyFisher")
local placeFisher = ReplicatedStorage:WaitForChild("PlaceFisher")

local venterPaaPlacering = false               -- er jeg lige nu i gang med at placere?

-- === Byg skærm-laget ===
local skaerm = Instance.new("ScreenGui")
skaerm.Name = "ShopMenu"
skaerm.ResetOnSpawn = false
skaerm.Parent = spiller:WaitForChild("PlayerGui")

-- Selve menu-vinduet (kan skjules/vises)
local vindue = Instance.new("Frame")
vindue.Size = UDim2.new(0, 300, 0, 220)
vindue.Position = UDim2.new(0.5, -150, 0.5, -110)
vindue.BackgroundColor3 = Color3.fromRGB(25, 35, 55)
vindue.Visible = false                          -- skjult fra start
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

-- Besked-linje inde i menuen (fx "Not enough fish")
local besked = Instance.new("TextLabel")
besked.Size = UDim2.new(1, -40, 0, 30)
besked.Position = UDim2.new(0, 20, 0, 175)
besked.BackgroundTransparency = 1
besked.Text = ""
besked.Font = Enum.Font.Gotham
besked.TextScaled = true
besked.Parent = vindue

-- Hjælpe-tekst i toppen, der vises mens jeg skal til at placere
local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(0, 400, 0, 40)
hint.Position = UDim2.new(0.5, -200, 0, 90)
hint.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
hint.BackgroundTransparency = 0.3
hint.Text = ""
hint.TextColor3 = Color3.fromRGB(255, 255, 255)
hint.Font = Enum.Font.GothamBold
hint.TextScaled = true
hint.Visible = false
hint.Parent = skaerm
Instance.new("UICorner").Parent = hint


-- === Åbn menuen når jeg rører shop-kassen ===
local shop = workspace:WaitForChild("Shop")
shop.Touched:Connect(function(andetObjekt)
	if andetObjekt.Parent == spiller.Character then
		besked.Text = ""
		vindue.Visible = true
	end
end)

-- Luk-knappen skjuler menuen
lukKnap.MouseButton1Click:Connect(function()
	vindue.Visible = false
end)

-- Køb-knappen beder serveren om at købe
koebKnap.MouseButton1Click:Connect(function()
	buyFisher:FireServer()
end)

-- Serveren svarer på købet
buyFisher.OnClientEvent:Connect(function(lykkedes, tekst)
	if lykkedes then
		vindue.Visible = false             -- luk menuen, så jeg kan klikke på verdenen
		hint.Text = tekst                  -- "Click on your plot to place the fisher"
		hint.Visible = true
		venterPaaPlacering = true          -- næste klik placerer fiskeren
	else
		besked.Text = tekst                -- "Not enough fish"
		besked.TextColor3 = Color3.fromRGB(240, 90, 90)
	end
end)

-- === Placering: næste klik i verdenen sætter fiskeren ===
mus.Button1Down:Connect(function()
	if venterPaaPlacering then
		venterPaaPlacering = false                 -- kun ét klik ad gangen
		hint.Visible = false
		placeFisher:FireServer(mus.Hit.Position)   -- send klik-stedet til serveren
	end
end)
