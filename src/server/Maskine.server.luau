-- Maskine.server.luau
-- Fiskeri-tycoon (server). Nu med ÉT plot: fiskerne står på min grund,
-- og shoppen står centralt i midten af banen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Walkie-talkien mellem client og server
local buyFisher = Instance.new("RemoteEvent")
buyFisher.Name = "BuyFisher"
buyFisher.Parent = ReplicatedStorage

-- Walkie-talkie til at sende mit klik-sted (hvor fiskeren skal placeres)
local placeFisher = Instance.new("RemoteEvent")
placeFisher.Name = "PlaceFisher"
placeFisher.Parent = ReplicatedStorage


-- === PLOT 1 (min grund) ===
-- Plottets centrum. Senere kan plot 2, 3, ... stå ved siden af i +X retning.
local PLOT_POSITION = Vector3.new(0, 0.5, -60)

local plot = Instance.new("Part")
plot.Name = "Plot1"
plot.Size = Vector3.new(40, 1, 40)             -- stor, flad plade (40x40)
plot.Position = PLOT_POSITION
plot.Anchored = true
plot.Material = Enum.Material.Grass
plot.BrickColor = BrickColor.new("Bright green")
plot.Parent = workspace

-- Skilt "PLOT 1" over pladen
local plotSkilt = Instance.new("BillboardGui")
plotSkilt.Size = UDim2.new(0, 200, 0, 50)
plotSkilt.StudsOffset = Vector3.new(0, 6, 0)
plotSkilt.AlwaysOnTop = true
plotSkilt.Parent = plot

local plotTekst = Instance.new("TextLabel")
plotTekst.Size = UDim2.new(1, 0, 1, 0)
plotTekst.BackgroundTransparency = 1
plotTekst.Font = Enum.Font.GothamBold
plotTekst.TextScaled = true
plotTekst.TextColor3 = Color3.fromRGB(255, 255, 255)
plotTekst.Text = "PLOT 1"
plotTekst.Parent = plotSkilt


-- === Hvor skal næste fisker stå PÅ plottet? ===
-- Vi placerer fiskerne i en række oven på pladen, fra venstre mod højre.
local fiskerNr = 0
local function naestePosition()
	local lokalX = -12 + fiskerNr * 8          -- -12, -4, 4, 12, ... hen over pladen
	fiskerNr = fiskerNr + 1
	return Vector3.new(PLOT_POSITION.X + lokalX, 3, PLOT_POSITION.Z)  -- y=3 = oven på pladen
end


-- === OPSKRIFT: lav én fisker ===
local function lavFisker(navn, position, kapacitet, sekunderPrFisk)
	local fisker = Instance.new("Part")
	fisker.Name = navn
	fisker.Size = Vector3.new(4, 4, 4)
	fisker.Position = position
	fisker.Anchored = true
	fisker.BrickColor = BrickColor.new("Medium stone grey")
	fisker.Parent = workspace
	fisker:SetAttribute("Indhold", 0)

	local skilt = Instance.new("BillboardGui")
	skilt.Size = UDim2.new(0, 200, 0, 50)
	skilt.StudsOffset = Vector3.new(0, 3, 0)
	skilt.AlwaysOnTop = true
	skilt.Parent = fisker

	local tekst = Instance.new("TextLabel")
	tekst.Size = UDim2.new(1, 0, 1, 0)
	tekst.BackgroundTransparency = 1
	tekst.Font = Enum.Font.GothamBold
	tekst.TextScaled = true
	tekst.Parent = skilt

	local function opdaterSkilt()
		local indhold = fisker:GetAttribute("Indhold")
		if indhold >= kapacitet then
			tekst.Text = "INVENTORY FULL"
			tekst.TextColor3 = Color3.fromRGB(230, 50, 50)
		else
			tekst.Text = indhold .. " / " .. kapacitet
			tekst.TextColor3 = Color3.fromRGB(60, 220, 90)
		end
	end
	opdaterSkilt()

	fisker.Touched:Connect(function(andetObjekt)
		local spiller = Players:GetPlayerFromCharacter(andetObjekt.Parent)
		if spiller then
			local fiskIFiskeren = fisker:GetAttribute("Indhold")
			if fiskIFiskeren > 0 then
				local mineFisk = (spiller:GetAttribute("Fisk") or 0) + fiskIFiskeren
				spiller:SetAttribute("Fisk", mineFisk)
				fisker:SetAttribute("Indhold", 0)
				opdaterSkilt()
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(sekunderPrFisk)
			local indhold = fisker:GetAttribute("Indhold")
			if indhold < kapacitet then
				fisker:SetAttribute("Indhold", indhold + 1)
				opdaterSkilt()
			end
		end
	end)
end


-- === De tre start-fiskere (nu placeret PÅ plottet) ===
lavFisker("BasicFisher",  naestePosition(), 50,  3)
lavFisker("BetterFisher", naestePosition(), 100, 2)
lavFisker("TopFisher",    naestePosition(), 200, 1)


-- === SHOP-manden (centralt i midten af banen, IKKE på plottet) ===
local shop = Instance.new("Part")
shop.Name = "Shop"
shop.Size = Vector3.new(4, 6, 4)
shop.Position = Vector3.new(0, 3, 0)           -- midten af banen
shop.Anchored = true
shop.BrickColor = BrickColor.new("Bright blue")
shop.Parent = workspace

local shopSkilt = Instance.new("BillboardGui")
shopSkilt.Size = UDim2.new(0, 200, 0, 50)
shopSkilt.StudsOffset = Vector3.new(0, 4, 0)
shopSkilt.AlwaysOnTop = true
shopSkilt.Parent = shop

local shopTekst = Instance.new("TextLabel")
shopTekst.Size = UDim2.new(1, 0, 1, 0)
shopTekst.BackgroundTransparency = 1
shopTekst.Font = Enum.Font.GothamBold
shopTekst.TextScaled = true
shopTekst.TextColor3 = Color3.fromRGB(255, 255, 255)
shopTekst.Text = "SHOP"
shopTekst.Parent = shopSkilt


-- === KØBET (sker på serveren) ===
local PRIS = 50

buyFisher.OnServerEvent:Connect(function(spiller)
	local mineFisk = spiller:GetAttribute("Fisk") or 0

	if mineFisk >= PRIS then
		spiller:SetAttribute("Fisk", mineFisk - PRIS)
		-- I stedet for at lave fiskeren nu, giver vi spilleren én "ventende" fisker,
		-- som han selv placerer ved at klikke.
		local ventende = (spiller:GetAttribute("PendingFishers") or 0) + 1
		spiller:SetAttribute("PendingFishers", ventende)
		buyFisher:FireClient(spiller, true, "Click on your plot to place the fisher")
	else
		buyFisher:FireClient(spiller, false, "Not enough fish")
	end
end)

-- === PLACERINGEN (sker på serveren) ===
-- Client sender det sted, jeg klikkede. Serveren laver fiskeren dér.
placeFisher.OnServerEvent:Connect(function(spiller, klikPosition)
	local ventende = spiller:GetAttribute("PendingFishers") or 0
	if ventende > 0 then
		spiller:SetAttribute("PendingFishers", ventende - 1)   -- brug én ventende fisker
		-- Løft 2 op, så fiskeren står OVEN på overfladen i stedet for at synke ned i den
		local placering = Vector3.new(klikPosition.X, klikPosition.Y + 2, klikPosition.Z)
		lavFisker("BasicFisher", placering, 50, 3)
	end
end)

print("Fiskeri-tycoon klar: plot 1 + central shop + placering.")
