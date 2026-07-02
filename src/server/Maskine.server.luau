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

-- Walkie-talkier til sælg-menuen
local openSell = Instance.new("RemoteEvent")
openSell.Name = "OpenSellMenu"
openSell.Parent = ReplicatedStorage

local sellAll = Instance.new("RemoteEvent")
sellAll.Name = "SellAll"
sellAll.Parent = ReplicatedStorage


-- === Sjældenheds-system: fisketyper og chancer fra FishConfig ===
local FishConfig = require(ReplicatedStorage:WaitForChild("FishConfig"))

-- Sortér fisketyper efter sjældenhed, så vi hurtigt kan vælge en tilfældig af en type
local fishByRarity = {}
for _, def in FishConfig.fish do
	fishByRarity[def.rarity] = fishByRarity[def.rarity] or {}
	table.insert(fishByRarity[def.rarity], def)
end

-- Rul en sjældenhed ud fra chance-tabellen (fx Common 70, Rare 20, ...)
local function rollRarity()
	local total = 0
	for _, chance in FishConfig.chances do
		total += chance
	end
	local r = math.random() * total          -- et tilfældigt tal mellem 0 og total
	local cumulative = 0
	for rarity, chance in FishConfig.chances do
		cumulative += chance
		if r <= cumulative then
			return rarity
		end
	end
	return "Common"                          -- sikkerhed
end

-- Rul en hel fisk: først sjældenhed, så en tilfældig fisketype af den sjældenhed
local function rollFish()
	local rarity = rollRarity()
	local liste = fishByRarity[rarity]
	if not liste or #liste == 0 then
		return FishConfig.fish[math.random(#FishConfig.fish)]   -- hvis en sjældenhed er tom
	end
	return liste[math.random(#liste)]
end


-- === Spillerens fangede fisk (individuelle fisk, ikke bare ét tal) ===
local playerFish = {}   -- spiller -> liste af fisk (hver er en FishConfig-blok: name/rarity/value)

local function opdaterFiskAntal(spiller)
	spiller:SetAttribute("Fisk", #(playerFish[spiller] or {}))   -- HUD viser antallet
end

-- Læg en liste af fisk over i spillerens beholdning
local function giveFisk(spiller, fiskListe)
	local mine = playerFish[spiller]
	if not mine then return end
	for _, fiskDef in fiskListe do
		table.insert(mine, fiskDef)
	end
	opdaterFiskAntal(spiller)
end


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
	playerFish[spiller] = {}                       -- tom fisk-beholdning (individuelle fisk)
	spiller:SetAttribute("Fisk", 0)               -- HUD-tal: antal fisk jeg har
	plot:SetAttribute("Owner", spiller.UserId)
	plot.Skilt.Navn.Text = spiller.Name .. "'s plot"
end

for _, spiller in Players:GetPlayers() do        -- dem der allerede er her (Play Solo)
	spillerJoinede(spiller)
end
Players.PlayerAdded:Connect(spillerJoinede)      -- og alle der joiner senere
Players.PlayerRemoving:Connect(function(spiller)
	playerFish[spiller] = nil                    -- ryd op når spilleren forlader
end)


-- Plottets spand (auto-collector). Er nil indtil man placerer en spand.
-- Fiskerne fylder DENNE spand, hvis den findes og har plads.
local plotBucket = nil

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

	local fisherList = {}   -- de individuelle fisk denne fisker holder lige nu

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

	-- Tøm fiskeren ved berøring -- de individuelle fisk lægges til min beholdning
	fisker.Touched:Connect(function(andetObjekt)
		local spiller = Players:GetPlayerFromCharacter(andetObjekt.Parent)
		if spiller and #fisherList > 0 then
			giveFisk(spiller, fisherList)          -- flyt fiskene til spilleren
			table.clear(fisherList)
			fisker:SetAttribute("Indhold", 0)      -- tallet på skiltet
			opdaterSkilt()
		end
	end)

	-- Fang fisk over tid (egen tråd)
	task.spawn(function()
		while true do
			task.wait(def.catchEvery)

			for _ = 1, def.fishPerCatch do
				local fisk = rollFish()            -- rul type + sjældenhed

				if plotBucket and plotBucket.part.Parent and #plotBucket.list < plotBucket.capacity then
					-- der er en spand med plads -> fisken flyder derhen
					table.insert(plotBucket.list, fisk)
					plotBucket.part:SetAttribute("Indhold", #plotBucket.list)
				elseif #fisherList < def.capacity then
					-- ellers beholder fiskeren fisken selv (hvis der er plads)
					table.insert(fisherList, fisk)
					fisker:SetAttribute("Indhold", #fisherList)
					opdaterSkilt()
				end
				-- er både spand og fisker fulde: der fanges ikke mere (som før)
			end
		end
	end)
end


-- === OPSKRIFT: lav en spand (auto-collector) ===
local function lavBucket(position)
	local kapacitet = FisherConfig.bucket.capacity

	local bucket = Instance.new("Part")
	bucket.Name = "Bucket"
	bucket.Size = Vector3.new(6, 6, 6)
	bucket.Position = position
	bucket.Anchored = true
	bucket.BrickColor = BrickColor.new("Bright yellow")   -- gul, så den skiller sig ud
	bucket.Parent = workspace
	bucket:SetAttribute("Indhold", 0)

	local bucketList = {}   -- de individuelle fisk i spanden

	local skilt = Instance.new("BillboardGui")
	skilt.Size = UDim2.new(0, 200, 0, 50)
	skilt.StudsOffset = Vector3.new(0, 4, 0)
	skilt.AlwaysOnTop = true
	skilt.Parent = bucket

	local tekst = Instance.new("TextLabel")
	tekst.Size = UDim2.new(1, 0, 1, 0)
	tekst.BackgroundTransparency = 1
	tekst.Font = Enum.Font.GothamBold
	tekst.TextScaled = true
	tekst.Parent = skilt

	local function opdaterSkilt()
		local indhold = bucket:GetAttribute("Indhold")
		if indhold >= kapacitet then
			tekst.Text = "FULL"
			tekst.TextColor3 = Color3.fromRGB(230, 50, 50)
		else
			tekst.Text = indhold .. " / " .. kapacitet
			tekst.TextColor3 = Color3.fromRGB(60, 220, 90)
		end
	end
	opdaterSkilt()

	-- Skiltet opdaterer sig selv, hver gang spandens Indhold ændrer sig
	-- (også når FISKERNE fylder den udefra).
	bucket:GetAttributeChangedSignal("Indhold"):Connect(opdaterSkilt)

	-- Tøm spanden ved berøring -> de individuelle fisk til min beholdning
	bucket.Touched:Connect(function(andetObjekt)
		local spiller = Players:GetPlayerFromCharacter(andetObjekt.Parent)
		if spiller and #bucketList > 0 then
			giveFisk(spiller, bucketList)
			table.clear(bucketList)
			bucket:SetAttribute("Indhold", 0)   -- skiltet opdaterer sig selv via changed-signal
		end
	end)

	-- Fra nu af fylder fiskerne DENNE spand (lille objekt: del + liste + kapacitet)
	plotBucket = { part = bucket, list = bucketList, capacity = kapacitet }
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

-- (SELL-stedet åbner nu en sælg-menu på client i stedet for at sælge med det samme.
--  Selve salget sker via "Sell All"-knappen i menuen -- se sælg-menu-håndteringen nederst.)


-- === KØB (med COINS, sker på serveren) ===
-- kind = "fisher" eller "bucket". index = hvilken fisker (kun for fiskere).
buyFisher.OnServerEvent:Connect(function(spiller, kind, index)
	-- Find prisen alt efter hvad jeg køber
	local price
	if kind == "fisher" then
		local def = FisherConfig.fishers[index]
		if not def then return end
		price = def.price
	elseif kind == "bucket" then
		price = FisherConfig.bucket.price
	else
		return                                         -- ukendt -> ignorér
	end

	local coins = spiller:GetAttribute("Coins") or 0
	if coins >= price then
		spiller:SetAttribute("Coins", coins - price)
		spiller:SetAttribute("PendingKind", kind)      -- husk HVAD jeg skal placere
		spiller:SetAttribute("PendingIndex", index or 0)
		buyFisher:FireClient(spiller, true, "Click on your plot to place it")
	else
		buyFisher:FireClient(spiller, false, "Not enough coins")
	end
end)

-- === PLACERING (sker på serveren) ===
placeFisher.OnServerEvent:Connect(function(spiller, klikPosition)
	local kind = spiller:GetAttribute("PendingKind") or ""

	if kind == "fisher" then
		local def = FisherConfig.fishers[spiller:GetAttribute("PendingIndex")]
		if def then
			spiller:SetAttribute("PendingKind", "")
			local placering = Vector3.new(klikPosition.X, klikPosition.Y + 2, klikPosition.Z)
			lavFisker(def, placering)
		end
	elseif kind == "bucket" then
		spiller:SetAttribute("PendingKind", "")
		local placering = Vector3.new(klikPosition.X, klikPosition.Y + 3, klikPosition.Z)  -- spand er 6 høj
		lavBucket(placering)
	end
end)

-- === SÆLG-MENU (server-siden) ===
-- Lav en oversigt over spillerens fisk, grupperet efter type
local function lavSummary(spiller)
	local fiskListe = playerFish[spiller] or {}
	local grupper = {}       -- navn -> {name, rarity, value, count}
	local raekkefoelge = {}  -- selve listen vi sender til client
	for _, def in fiskListe do
		local g = grupper[def.name]
		if not g then
			g = { name = def.name, rarity = def.rarity, value = def.value, count = 0 }
			grupper[def.name] = g
			table.insert(raekkefoelge, g)
		end
		g.count += 1
	end
	return raekkefoelge
end

-- Client beder om at åbne menuen -> vi sender oversigten tilbage
openSell.OnServerEvent:Connect(function(spiller)
	openSell:FireClient(spiller, lavSummary(spiller))
end)

-- Client trykker "Sell All" -> sælg alt ud fra hver fisks værdi i FishConfig
sellAll.OnServerEvent:Connect(function(spiller)
	local fiskListe = playerFish[spiller] or {}
	local total = 0
	for _, def in fiskListe do
		total += def.value
	end
	if total > 0 then
		spiller:SetAttribute("Coins", (spiller:GetAttribute("Coins") or 0) + total)
	end
	playerFish[spiller] = {}                              -- beholdningen er tom nu
	opdaterFiskAntal(spiller)
	openSell:FireClient(spiller, lavSummary(spiller))    -- opdater menuen (nu tom)
end)

print("Fiskeri-tycoon klar (sjældenhed + sælg-menu).")
