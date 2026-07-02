-- SellMenu.client.luau
-- Sælg-menu. Åbner ved det fysiske SELL-sted. Viser mine fisk pr. sjældenhed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local spiller = Players.LocalPlayer

local FishConfig = require(ReplicatedStorage:WaitForChild("FishConfig"))
local openSell = ReplicatedStorage:WaitForChild("OpenSellMenu")
local sellAll = ReplicatedStorage:WaitForChild("SellAll")

-- === Byg menuen (skjult fra start) ===
local skaerm = Instance.new("ScreenGui")
skaerm.Name = "SellMenu"
skaerm.ResetOnSpawn = false
skaerm.Parent = spiller:WaitForChild("PlayerGui")

local vindue = Instance.new("Frame")
vindue.AnchorPoint = Vector2.new(0.5, 0.5)
vindue.Position = UDim2.new(0.5, 0, 0.5, 0)
vindue.Size = UDim2.new(0, 380, 0, 420)
vindue.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
vindue.Visible = false
vindue.Parent = skaerm
Instance.new("UICorner").Parent = vindue

-- Titel
local titel = Instance.new("TextLabel")
titel.Size = UDim2.new(1, -20, 0, 40)
titel.Position = UDim2.new(0, 10, 0, 8)
titel.BackgroundTransparency = 1
titel.Text = "SELL FISH"
titel.TextColor3 = Color3.fromRGB(255, 255, 255)
titel.Font = Enum.Font.GothamBold
titel.TextScaled = true
titel.Parent = vindue

-- Rullbar liste (scrollbar)
local liste = Instance.new("ScrollingFrame")
liste.Size = UDim2.new(1, -20, 1, -110)
liste.Position = UDim2.new(0, 10, 0, 52)
liste.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
liste.BorderSizePixel = 0
liste.ScrollBarThickness = 8
liste.CanvasSize = UDim2.new(0, 0, 0, 0)
liste.AutomaticCanvasSize = Enum.AutomaticSize.Y     -- vokser med indholdet
liste.Parent = vindue
Instance.new("UICorner").Parent = liste

local listeLayout = Instance.new("UIListLayout")
listeLayout.Padding = UDim.new(0, 4)
listeLayout.SortOrder = Enum.SortOrder.LayoutOrder
listeLayout.Parent = liste

local listePadding = Instance.new("UIPadding")
listePadding.PaddingTop = UDim.new(0, 6)
listePadding.PaddingBottom = UDim.new(0, 6)
listePadding.PaddingLeft = UDim.new(0, 8)
listePadding.PaddingRight = UDim.new(0, 8)
listePadding.Parent = liste

-- "Sell All"-knap
local sellKnap = Instance.new("TextButton")
sellKnap.Size = UDim2.new(0, 175, 0, 40)
sellKnap.Position = UDim2.new(0, 10, 1, -48)
sellKnap.BackgroundColor3 = Color3.fromRGB(60, 200, 90)
sellKnap.Text = "Sell All"
sellKnap.TextColor3 = Color3.fromRGB(255, 255, 255)
sellKnap.Font = Enum.Font.GothamBold
sellKnap.TextScaled = true
sellKnap.Parent = vindue
Instance.new("UICorner").Parent = sellKnap

-- Luk-knap
local lukKnap = Instance.new("TextButton")
lukKnap.Size = UDim2.new(0, 175, 0, 40)
lukKnap.Position = UDim2.new(1, -185, 1, -48)
lukKnap.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
lukKnap.Text = "Close"
lukKnap.TextColor3 = Color3.fromRGB(255, 255, 255)
lukKnap.Font = Enum.Font.GothamBold
lukKnap.TextScaled = true
lukKnap.Parent = vindue
Instance.new("UICorner").Parent = lukKnap


-- === Byg rækkerne ud fra serverens oversigt ===
local function visListe(summary)
	-- ryd gamle rækker
	for _, barn in liste:GetChildren() do
		if barn:IsA("TextLabel") then
			barn:Destroy()
		end
	end

	-- sortér efter sjældenheds-rækkefølgen fra config
	local function rang(rarity)
		for i, r in FishConfig.rarityOrder do
			if r == rarity then return i end
		end
		return 99
	end
	table.sort(summary, function(a, b)
		if rang(a.rarity) ~= rang(b.rarity) then
			return rang(a.rarity) < rang(b.rarity)
		end
		return a.name < b.name
	end)

	if #summary == 0 then
		local tom = Instance.new("TextLabel")
		tom.Size = UDim2.new(1, 0, 0, 30)
		tom.BackgroundTransparency = 1
		tom.Text = "No fish to sell"
		tom.TextColor3 = Color3.fromRGB(200, 200, 200)
		tom.Font = Enum.Font.Gotham
		tom.TextScaled = true
		tom.Parent = liste
		return
	end

	for i, gruppe in summary do
		local raekke = Instance.new("TextLabel")
		raekke.LayoutOrder = i
		raekke.Size = UDim2.new(1, 0, 0, 30)
		raekke.BackgroundTransparency = 1
		raekke.Font = Enum.Font.GothamMedium
		raekke.TextScaled = true
		raekke.TextXAlignment = Enum.TextXAlignment.Left
		raekke.TextColor3 = FishConfig.colors[gruppe.rarity] or Color3.fromRGB(255, 255, 255)
		raekke.Text = "x" .. gruppe.count .. "   " .. gruppe.name
			.. "  [" .. gruppe.rarity .. "]   " .. gruppe.value .. "c each"
		raekke.Parent = liste
	end
end


-- === Åbn menuen ved SELL-stedet ===
local sell = workspace:WaitForChild("SellPad")
sell.Touched:Connect(function(andetObjekt)
	if andetObjekt.Parent == spiller.Character and not vindue.Visible then
		openSell:FireServer()      -- bed serveren om min fisk-oversigt
	end
end)

-- Serveren sender oversigten (ved åbning OG efter salg)
openSell.OnClientEvent:Connect(function(summary)
	visListe(summary)
	vindue.Visible = true
end)

sellKnap.MouseButton1Click:Connect(function()
	sellAll:FireServer()
end)

lukKnap.MouseButton1Click:Connect(function()
	vindue.Visible = false
end)
