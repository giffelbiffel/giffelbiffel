-- Maskine.server.luau
-- Fiskeri-tycoon (server). To-lags økonomi: fiskere fanger FISK, fisk sælges til COINS,
-- fiskere købes med COINS. Værdier kommer fra FisherConfig.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FisherConfig = require(ReplicatedStorage:WaitForChild("FisherConfig"))

-- Walkie-talkier mellem client og server
local buyFisher = Instance.new("RemoteEvent")
buyFisher.Name = "BuyFisher"
buyFisher.Parent = ReplicatedStorage

local placeFisher = Instance.new("RemoteEvent")
placeFisher.Name = "PlaceFisher"
placeFisher.Parent = ReplicatedStorage


-- === OPSKRIFT: lav ét plot ===
local function lavPlot(position)
	local plot = Instance.new("Part")
	plot.Name = "Plot"
	plot.Size = Vector3.new(40, 1, 40)
	plot.Position = position
	plot.Anchored = true
	plot.Material = Enum.Material.Grass
	plot.BrickColor = BrickColor.new("Bright green")
	plot.Parent = workspace

	local skilt = Instance.new("BillboardGui")
	skilt.Name = "Skilt"
	skilt.Size = UDim2.new(0, 200, 0, 50)
	skilt.StudsOffset = Vector3.new(0, 6, 0)
	skilt.AlwaysOnTop = true
	skilt.Parent = plot

	local navn = Instance.new("TextLabel")
	navn.Name = "Navn"
	navn.Size = UDim2.new(1, 0, 1, 0)
	navn.BackgroundTransparency = 1
	navn.Font = Enum.Font.GothamBold
	navn.TextScaled = true
	navn.TextColor3 = Color3.fromRGB(255, 255, 255)
	navn.Text = "Empty plot"
	navn.Parent = skilt

	return plot
end

-- === Lav plot 1 ===
local PLOT_POSITION = Vector3.new(0, 0.5, -60)
local plot = lavPlot(PLOT_POSITION)

-- === Klargør en spiller når han joiner: startkapital + tildel plot ===
local STARTKAPITAL = 50   -- coins man spawner med

local function spillerJoinede(spiller)
	spiller:SetAttribute("Coins", STARTKAPITAL)   -- nok til den billigste fisker
	spiller:SetAttribute("Fisk", 0)               -- min fisk-beholdning (endnu ikke solgt)
	plot:SetAttribute("Owner", spiller.UserId)
	plot.Skilt.Navn.Text = spiller.Name .. "'s plot"
end

for _, spiller in Players:GetPlayers() do        -- dem der allerede er her (Play Solo)
	spillerJoinede(spiller)
end
Players.PlayerAdded:Connect(spillerJoinede)      -- og alle der joiner senere


-- === OPSKRIFT: lav én fisker ud fra en config-blok ===
local function lavFisker(def, position)
	local fisker = Instance.new("Part")
	fisker.Name = def.name
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
		if indhold >= def.capacity then
			tekst.Text = "INVENTORY FULL"
			tekst.TextColor3 = Color3.fromRGB(230, 50, 50)
		else
			tekst.Text = indhold .. " / " .. def.capacity
			tekst.TextColor3 = Color3.fromRGB(60, 220, 90)
		end
	end
	opdaterSkilt()

	-- Tøm fiskeren ved berøring -- fiskene lægges til min FISK-beholdning (IKKE coins)
	fisker.Touched:Connect(function(andetObjekt)
		local spiller = Players:GetPlayerFromCharacter(andetObjekt.Parent)
		if spiller then
			local fisk = fisker:GetAttribute("Indhold")
			if fisk > 0 then
				fisker:SetAttribute("Indhold", 0)
				opdaterSkilt()
				spiller:SetAttribute("Fisk", (spiller:GetAttribute("Fisk") or 0) + fisk)
			end
		end
	end)

	-- Fang fisk over tid (egen tråd)
	task.spawn(function()
		while true do
			task.wait(def.catchEvery)
			local indhold = fisker:GetAttribute("Indhold")
			if indhold < def.capacity then
				local nyt = math.min(indhold + def.fishPerCatch, def.capacity)
				fisker:SetAttribute("Indhold", nyt)
				opdaterSkilt()
			end
		end
	end)
end


-- === SHOP-manden (centralt i midten af banen) ===
local shop = Instance.new("Part")
shop.Name = "Shop"
shop.Size = Vector3.new(4, 6, 4)
shop.Position = Vector3.new(0, 3, 0)
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


-- === SELL-stedet (sælg alle mine fisk til coins ved berøring) ===
local sell = Instance.new("Part")
sell.Name = "SellPad"
sell.Size = Vector3.new(4, 6, 4)
sell.Position = Vector3.new(12, 3, 0)          -- centralt, ved siden af shoppen
sell.Anchored = true
sell.BrickColor = BrickColor.new("Medium stone grey")
sell.Parent = workspace

local sellSkilt = Instance.new("BillboardGui")
sellSkilt.Size = UDim2.new(0, 200, 0, 50)
sellSkilt.StudsOffset = Vector3.new(0, 4, 0)
sellSkilt.AlwaysOnTop = true
sellSkilt.Parent = sell

local sellTekst = Instance.new("TextLabel")
sellTekst.Size = UDim2.new(1, 0, 1, 0)
sellTekst.BackgroundTransparency = 1
sellTekst.Font = Enum.Font.GothamBold
sellTekst.TextScaled = true
sellTekst.TextColor3 = Color3.fromRGB(255, 255, 255)
sellTekst.Text = "SELL"
sellTekst.Parent = sellSkilt

sell.Touched:Connect(function(andetObjekt)
	local spiller = Players:GetPlayerFromCharacter(andetObjekt.Parent)
	if spiller then
		local fisk = spiller:GetAttribute("Fisk") or 0
		if fisk > 0 then                                       -- har jeg fisk at sælge?
			local tjente = fisk * FisherConfig.fishToCoins     -- fisk -> coins via kursen
			spiller:SetAttribute("Coins", (spiller:GetAttribute("Coins") or 0) + tjente)
			spiller:SetAttribute("Fisk", 0)                    -- tøm fisk-beholdningen
		end
	end
end)


-- === KØB (med COINS, sker på serveren) ===
buyFisher.OnServerEvent:Connect(function(spiller, index)
	local def = FisherConfig.fishers[index]
	if not def then return end

	local coins = spiller:GetAttribute("Coins") or 0
	if coins >= def.price then
		spiller:SetAttribute("Coins", coins - def.price)
		spiller:SetAttribute("PendingFisher", index)
		buyFisher:FireClient(spiller, true, "Click on your plot to place the fisher")
	else
		buyFisher:FireClient(spiller, false, "Not enough coins")
	end
end)

-- === PLACERING (sker på serveren) ===
placeFisher.OnServerEvent:Connect(function(spiller, klikPosition)
	local index = spiller:GetAttribute("PendingFisher") or 0
	local def = FisherConfig.fishers[index]
	if def then
		spiller:SetAttribute("PendingFisher", 0)
		local placering = Vector3.new(klikPosition.X, klikPosition.Y + 2, klikPosition.Z)
		lavFisker(def, placering)
	end
end)

print("Fiskeri-tycoon klar (coins-økonomi).")
