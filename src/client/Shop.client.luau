-- Shop.client.luau
-- Shop-menu + placering. Menuen bygges automatisk ud fra FisherConfig.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local spiller = Players.LocalPlayer
local mus = spiller:GetMouse()

-- Læs den SAMME config som serveren
local FisherConfig = require(ReplicatedStorage:WaitForChild("FisherConfig"))

local buyFisher = ReplicatedStorage:WaitForChild("BuyFisher")
local placeFisher = ReplicatedStorage:WaitForChild("PlaceFisher")

local venterPaaPlacering = false

-- === Skærm-lag ===
local skaerm = Instance.new("ScreenGui")
skaerm.Name = "ShopMenu"
skaerm.ResetOnSpawn = false
skaerm.Parent = spiller:WaitForChild("PlayerGui")

-- Menu-vinduet -- vokser selv i højden alt efter antal fiskere
local vindue = Instance.new("Frame")
vindue.AnchorPoint = Vector2.new(0.5, 0.5)
vindue.Position = UDim2.new(0.5, 0, 0.5, 0)        -- altid centreret
vindue.Size = UDim2.new(0, 340, 0, 0)
vindue.AutomaticSize = Enum.AutomaticSize.Y         -- højden tilpasser sig indholdet
vindue.BackgroundColor3 = Color3.fromRGB(25, 35, 55)
vindue.Visible = false
vindue.Parent = skaerm
Instance.new("UICorner").Parent = vindue

-- Stabler indholdet pænt lodret
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = vindue

local polstring = Instance.new("UIPadding")
polstring.PaddingTop = UDim.new(0, 12)
polstring.PaddingBottom = UDim.new(0, 12)
polstring.Parent = vindue

-- Titel
local titel = Instance.new("TextLabel")
titel.LayoutOrder = 0
titel.Size = UDim2.new(0, 300, 0, 40)
titel.BackgroundTransparency = 1
titel.Text = "SHOP"
titel.TextColor3 = Color3.fromRGB(255, 255, 255)
titel.Font = Enum.Font.GothamBold
titel.TextScaled = true
titel.Parent = vindue

-- === En købsknap PER fisker i config'en ===
for index, fisker in FisherConfig.fishers do
	local knap = Instance.new("TextButton")
	knap.LayoutOrder = index
	knap.Size = UDim2.new(0, 300, 0, 44)
	knap.BackgroundColor3 = Color3.fromRGB(60, 200, 90)
	knap.TextColor3 = Color3.fromRGB(255, 255, 255)
	knap.Font = Enum.Font.GothamBold
	knap.TextScaled = true
	knap.Text = "Buy " .. fisker.name .. " - " .. fisker.price .. " coins"
	knap.Parent = vindue
	Instance.new("UICorner").Parent = knap

	-- Klik = bed serveren om at købe netop DENNE fisker (send "fisher" + nummer)
	knap.MouseButton1Click:Connect(function()
		buyFisher:FireServer("fisher", index)
	end)
end

-- === Købsknap til spanden (auto-collector) ===
local spandKnap = Instance.new("TextButton")
spandKnap.LayoutOrder = 500                     -- efter fiskerne, før besked/luk
spandKnap.Size = UDim2.new(0, 300, 0, 44)
spandKnap.BackgroundColor3 = Color3.fromRGB(230, 200, 60)   -- gul som spanden
spandKnap.TextColor3 = Color3.fromRGB(40, 40, 40)
spandKnap.Font = Enum.Font.GothamBold
spandKnap.TextScaled = true
spandKnap.Text = "Buy " .. FisherConfig.bucket.name .. " - " .. FisherConfig.bucket.price .. " coins"
spandKnap.Parent = vindue
Instance.new("UICorner").Parent = spandKnap

spandKnap.MouseButton1Click:Connect(function()
	buyFisher:FireServer("bucket")
end)

-- Besked-linje (fx "Not enough fish")
local besked = Instance.new("TextLabel")
besked.LayoutOrder = 998
besked.Size = UDim2.new(0, 300, 0, 28)
besked.BackgroundTransparency = 1
besked.Text = ""
besked.Font = Enum.Font.Gotham
besked.TextScaled = true
besked.Parent = vindue

-- Luk-knap
local lukKnap = Instance.new("TextButton")
lukKnap.LayoutOrder = 999
lukKnap.Size = UDim2.new(0, 300, 0, 40)
lukKnap.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
lukKnap.Text = "Close"
lukKnap.TextColor3 = Color3.fromRGB(255, 255, 255)
lukKnap.Font = Enum.Font.GothamBold
lukKnap.TextScaled = true
lukKnap.Parent = vindue
Instance.new("UICorner").Parent = lukKnap

-- Hjælpe-tekst i toppen mens jeg placerer
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


-- === Åbn menuen ved at røre shop-kassen ===
local shop = workspace:WaitForChild("Shop")
shop.Touched:Connect(function(andetObjekt)
	if andetObjekt.Parent == spiller.Character then
		besked.Text = ""
		vindue.Visible = true
	end
end)

lukKnap.MouseButton1Click:Connect(function()
	vindue.Visible = false
end)

-- Serverens svar på et køb
buyFisher.OnClientEvent:Connect(function(lykkedes, tekst)
	if lykkedes then
		vindue.Visible = false
		hint.Text = tekst
		hint.Visible = true
		venterPaaPlacering = true
	else
		besked.Text = tekst
		besked.TextColor3 = Color3.fromRGB(240, 90, 90)
	end
end)

-- Placering: næste klik sætter fiskeren
mus.Button1Down:Connect(function()
	if venterPaaPlacering then
		venterPaaPlacering = false
		hint.Visible = false
		placeFisher:FireServer(mus.Hit.Position)
	end
end)
