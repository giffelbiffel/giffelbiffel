-- Maskine.server.luau
-- Fiskeri-tycoon (server). To-lags økonomi: fiskere fanger FISK, fisk sælges til COINS,
-- fiskere købes med COINS. Værdier kommer fra FisherConfig.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FisherConfig = require(ReplicatedStorage:WaitForChild("FisherConfig"))
local FormatNumber = require(ReplicatedStorage:WaitForChild("FormatNumber"))

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

-- Walkie-talkie til rebirth (client beder om status / trykker rebirth; server svarer)
local rebirthEvent = Instance.new("RemoteEvent")
rebirthEvent.Name = "Rebirth"
rebirthEvent.Parent = ReplicatedStorage

-- Walkie-talkie til upgrade-menuen
local upgradeEvent = Instance.new("RemoteEvent")
upgradeEvent.Name = "Upgrade"
upgradeEvent.Parent = ReplicatedStorage


-- === Sjældenheds-system: fiskene fra FishConfig, oddsene fra hver fisker ===
local FishConfig = require(ReplicatedStorage:WaitForChild("FishConfig"))

-- Bruges hvis en fisker i config'en IKKE har sin egen chances-tabel (så intet crasher)
local DEFAULT_CHANCES = { Basic = 70, Rare = 20, Epic = 8, Legendary = 2 }

-- Rul en sjældenhed ud fra en GIVEN chance-tabel (fx fiskerens egen)
local function rollRarity(chances)
	local total = 0
	for _, chance in chances do
		total += chance
	end
	if total <= 0 then
		return "Basic"                      -- sikkerhed hvis tabellen er tom/ugyldig
	end
	local r = math.random() * total          -- et tilfældigt tal mellem 0 og total
	local cumulative = 0
	for rarity, chance in chances do
		cumulative += chance
		if r <= cumulative then
			return rarity
		end
	end
	return "Basic"
end

-- Rul en hel fisk: først sjældenhed (fra fiskerens tabel), så en tilfældig fisk
-- af den sjældenhed fra FishConfig. Returnerer {name, value, rarity} eller nil.
local function rollFish(chances)
	local rarity = rollRarity(chances)
	local liste = FishConfig.fish[rarity]

	-- Hvis den valgte sjældenhed ikke har nogen fisk defineret: find en der har
	if not liste or #liste == 0 then
		for _, r in FishConfig.rarityOrder do
			local kandidat = FishConfig.fish[r]
			if kandidat and #kandidat > 0 then
				rarity = r
				liste = kandidat
				break
			end
		end
	end
	if not liste or #liste == 0 then
		return nil                           -- der findes slet ingen fisk i config'en
	end

	local f = liste[math.random(#liste)]
	return { name = f.name, value = f.value, rarity = rarity }
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


-- === REBIRTH-data (i hukommelsen for nu) ===
local RebirthConfig = require(ReplicatedStorage:WaitForChild("RebirthConfig"))

-- Hvilke fisker-typer spilleren EJER (har købt) -> bruges til fisker-krav.
local ownedFishers = {}   -- spiller -> { [fiskerNavn] = true }

-- De ting spilleren har PLACERET på plottet (fiskere + spande), så rebirth kan rydde dem.
-- Hver post: { part = Instance, robux = false }. robux=true undtages fra rydning (til senere).
local placedItems = {}    -- spiller -> liste af { part, robux }


-- === UPGRADE-system: niveauer per fisker-TYPE, per spiller (i hukommelsen for nu) ===
local FisherUpgradeConfig = require(ReplicatedStorage:WaitForChild("FisherUpgradeConfig"))

local upgradeLevels = {}   -- spiller -> { [fiskerNavn] = { speed = 0, capacity = 0, catchChance = 0 } }

-- Hent (eller opret) spillerens niveauer for en fisker-type
local function getNiveauer(spiller, fiskerNavn)
	local mine = upgradeLevels[spiller]
	if not mine then
		return { speed = 0, capacity = 0, catchChance = 0 }   -- spiller væk -> ingen bonus
	end
	if not mine[fiskerNavn] then
		mine[fiskerNavn] = { speed = 0, capacity = 0, catchChance = 0 }
	end
	return mine[fiskerNavn]
end

-- Læg bonusserne sammen for alle nåede niveauer i et spor (fx 3 x +5% = 15)
local function totalBonusPct(sporListe, niveau)
	local sum = 0
	if sporListe then
		for i = 1, math.min(niveau, #sporListe) do
			sum += sporListe[i].bonus
		end
	end
	return sum
end

-- catchChance-bonus: gang vægtene op for alle sjældenheder UNDTAGEN den mest
-- almindelige (den første i rarityOrder). Så vokser chancen for sjældne fisk,
-- mens grundværdierne i config aldrig røres.
local function justeretChances(chances, bonusPct)
	if bonusPct <= 0 then
		return chances
	end
	local mestAlmindelig = FishConfig.rarityOrder[1]
	local ny = {}
	for rarity, vaegt in chances do
		if rarity == mestAlmindelig then
			ny[rarity] = vaegt
		else
			ny[rarity] = vaegt * (1 + bonusPct / 100)
		end
	end
	return ny
end

-- Byg en status til upgrade-menuen for én fisker-type og send den til spilleren
local SPOR_NAVNE = { "speed", "capacity", "catchChance" }

local function sendUpgradeStatus(spiller, fiskerNavn)
	local spor = FisherUpgradeConfig[fiskerNavn]
	if not spor then return end

	local niveauer = getNiveauer(spiller, fiskerNavn)
	local status = { fisher = fiskerNavn, tracks = {} }

	for _, sporNavn in SPOR_NAVNE do
		local liste = spor[sporNavn]
		if liste and #liste > 0 then                     -- kun spor der findes i config'en
			local niveau = niveauer[sporNavn] or 0
			local t = {
				track = sporNavn,
				level = niveau,
				maxLevel = #liste,                        -- max = antal linjer i config
				totalBonus = totalBonusPct(liste, niveau),
			}
			if niveau < #liste then
				t.nextPrice = liste[niveau + 1].price
				t.nextBonus = liste[niveau + 1].bonus
			end
			table.insert(status.tracks, t)
		end
	end

	upgradeEvent:FireClient(spiller, status)
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
	spiller:SetAttribute("Rebirths", 0)           -- antal rebirths (HUD)
	spiller:SetAttribute("Multiplier", 1)         -- salgsmultiplier (1 = ingen endnu)
	ownedFishers[spiller] = {}                     -- endnu ejet ingen fiskere
	placedItems[spiller] = {}                      -- endnu placeret intet
	upgradeLevels[spiller] = {}                    -- ingen upgrades endnu
	plot:SetAttribute("Owner", spiller.UserId)
	plot.Skilt.Navn.Text = spiller.Name .. "'s plot"
end

for _, spiller in Players:GetPlayers() do        -- dem der allerede er her (Play Solo)
	spillerJoinede(spiller)
end
Players.PlayerAdded:Connect(spillerJoinede)      -- og alle der joiner senere
Players.PlayerRemoving:Connect(function(spiller)
	playerFish[spiller] = nil                    -- ryd op når spilleren forlader
	ownedFishers[spiller] = nil
	placedItems[spiller] = nil
	upgradeLevels[spiller] = nil
end)


-- Plottets spande (auto-collector), i den rækkefølge de blev placeret.
-- Spand 1 er først, spand 2 er næste, osv.
local plotBuckets = {}
local bucketCount = 0   -- tæller, så hver spand får et placerings-nummer

-- Find den FØRSTE spand (laveste placerings-nummer) der har plads.
-- Fordi listen er i placerings-rækkefølge, fyldes spand 1 før spand 2 osv.
local function foersteLedigeSpand()
	for _, b in plotBuckets do
		if b.part.Parent and #b.list < b.capacity then
			return b
		end
	end
	return nil
end

-- === OPSKRIFT: lav én fisker ud fra en config-blok ===
local function lavFisker(def, position, ejer)
	local fisker = Instance.new("Part")
	fisker.Name = def.name
	fisker.Size = Vector3.new(4, 4, 4)
	fisker.Position = position
	fisker.Anchored = true
	fisker.BrickColor = BrickColor.new("Medium stone grey")
	fisker.Parent = workspace
	fisker:SetAttribute("Indhold", 0)

	local fisherList = {}   -- de individuelle fisk denne fisker holder lige nu

	-- Effektive værdier = grundværdi fra config GANGET med ejerens upgrade-bonus.
	-- Beregnes LIVE hver gang, så en ny upgrade virker med det samme på alle placerede.
	local spor = FisherUpgradeConfig[def.name]

	local function effektivVentetid()
		local pct = totalBonusPct(spor and spor.speed, ejer and getNiveauer(ejer, def.name).speed or 0)
		return def.catchEvery / (1 + pct / 100)     -- +50% speed = fanger 1.5x så tit
	end

	local function effektivKapacitet()
		local pct = totalBonusPct(spor and spor.capacity, ejer and getNiveauer(ejer, def.name).capacity or 0)
		return math.floor(def.capacity * (1 + pct / 100))
	end

	local function effektiveChances()
		local pct = totalBonusPct(spor and spor.catchChance, ejer and getNiveauer(ejer, def.name).catchChance or 0)
		return justeretChances(def.chances or DEFAULT_CHANCES, pct)
	end

	-- Klik på fiskeren -> åbn upgrade-menuen for dens TYPE (hos den der klikkede)
	local klik = Instance.new("ClickDetector")
	klik.MaxActivationDistance = 40
	klik.Parent = fisker
	klik.MouseClick:Connect(function(spiller)
		sendUpgradeStatus(spiller, def.name)
	end)

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
		local kapacitet = effektivKapacitet()
		if indhold >= kapacitet then
			tekst.Text = "INVENTORY FULL"
			tekst.TextColor3 = Color3.fromRGB(230, 50, 50)
		else
			tekst.Text = FormatNumber(indhold) .. " / " .. FormatNumber(kapacitet)
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
			task.wait(effektivVentetid())            -- speed-upgrade = kortere ventetid
			if not fisker.Parent then break end   -- fiskeren er fjernet (fx ved rebirth) -> stop

			for _ = 1, def.fishPerCatch do
				-- rul en fisk med catchChance-justerede odds
				local fisk = rollFish(effektiveChances())

				if fisk then
					local spand = foersteLedigeSpand()   -- laveste ikke-fulde spand
					if spand then
						-- der er en spand med plads -> fisken flyder derhen
						table.insert(spand.list, fisk)
						spand.part:SetAttribute("Indhold", #spand.list)
					elseif #fisherList < effektivKapacitet() then
						-- FØRST når ALLE spande er fulde: fiskeren beholder fisken selv
						table.insert(fisherList, fisk)
						fisker:SetAttribute("Indhold", #fisherList)
						opdaterSkilt()
					end
					-- er alle spande OG fiskeren fulde: der fanges ikke mere (som før)
				end
			end
		end
	end)

	return fisker
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
			tekst.Text = FormatNumber(indhold) .. " / " .. FormatNumber(kapacitet)
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

	-- Registrér spanden bagerst i listen -> den får det næste placerings-nummer
	bucketCount += 1
	bucket:SetAttribute("Order", bucketCount)   -- spanden husker sin rækkefølge
	table.insert(plotBuckets, { part = bucket, list = bucketList, capacity = kapacitet, order = bucketCount })

	return bucket
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

		if kind == "fisher" then
			local koebtDef = FisherConfig.fishers[index]

			-- REBIRTH: husk at spilleren EJER denne fisker-type
			-- (køb tæller som ejerskab, uanset om den er placeret eller ligger i backpacken)
			if koebtDef and ownedFishers[spiller] then
				ownedFishers[spiller][koebtDef.name] = true
			end

			-- Læg fiskeren i backpacken som et Tool -> vises i hotbaren (tast 1-9)
			local tool = Instance.new("Tool")
			tool.Name = koebtDef.name                 -- navnet fra config vises i hotbaren
			tool.RequiresHandle = false               -- ingen 3D-model endnu (placeholder)
			tool.CanBeDropped = false                 -- kan ikke smides på jorden
			tool.ToolTip = "Click on your plot to place"
			tool:SetAttribute("FisherIndex", index)   -- hvilken fisker-type tool'et er
			tool:SetAttribute("Robux", false)         -- robux-købte undtages ved rebirth (senere)
			tool.Parent = spiller:FindFirstChildOfClass("Backpack") or spiller:WaitForChild("Backpack")

			buyFisher:FireClient(spiller, true, "Added to your hotbar - press a number key", "fisher")
		else
			-- SPAND: læg den i backpacken som et Tool (ligesom fiskerne)
			local tool = Instance.new("Tool")
			tool.Name = FisherConfig.bucket.name
			tool.RequiresHandle = false               -- ingen 3D-model endnu (placeholder)
			tool.CanBeDropped = false
			tool.ToolTip = "Click on your plot to place"
			tool:SetAttribute("IsBucket", true)       -- markerer tool'et som en spand
			tool:SetAttribute("Robux", false)         -- robux-købte undtages ved rebirth (senere)
			tool.Parent = spiller:FindFirstChildOfClass("Backpack") or spiller:WaitForChild("Backpack")

			buyFisher:FireClient(spiller, true, "Added to your hotbar - press a number key", "bucket")
		end
	else
		buyFisher:FireClient(spiller, false, "Not enough coins")
	end
end)

-- === PLACERING (sker på serveren) ===
-- Både fiskere og spande placeres via et equipped Tool fra hotbaren.
placeFisher.OnServerEvent:Connect(function(spiller, klikPosition, tool)
	-- Serveren tjekker selv: er det et ægte tool, og holder spilleren det?
	if typeof(tool) ~= "Instance" or not tool:IsA("Tool") then return end
	if not (spiller.Character and tool:IsDescendantOf(spiller.Character)) then return end

	if tool:GetAttribute("FisherIndex") then
		-- FISKER
		local def = FisherConfig.fishers[tool:GetAttribute("FisherIndex")]
		if def then
			-- PRÆCIS samme placeringsregler som før (løft 2 op, ingen andre regler)
			local placering = Vector3.new(klikPosition.X, klikPosition.Y + 2, klikPosition.Z)
			local part = lavFisker(def, placering, spiller)   -- ejer = til upgrade-bonusser
			-- REBIRTH: husk denne placering (robux-flag følger tool'et)
			if placedItems[spiller] then
				table.insert(placedItems[spiller], { part = part, robux = tool:GetAttribute("Robux") or false })
			end
			tool:Destroy()   -- fjern tool'et fra hotbaren efter placering
		end
	elseif tool:GetAttribute("IsBucket") then
		-- SPAND (samme placeringsregel som før: løft 3 op, spanden er 6 høj)
		local placering = Vector3.new(klikPosition.X, klikPosition.Y + 3, klikPosition.Z)
		local part = lavBucket(placering)
		if placedItems[spiller] then
			table.insert(placedItems[spiller], { part = part, robux = tool:GetAttribute("Robux") or false })
		end
		tool:Destroy()
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
		local mult = spiller:GetAttribute("Multiplier") or 1   -- rebirth-multiplier
		local tjent = math.floor(total * mult)                 -- gang oveni -- rør ikke grundværdien
		spiller:SetAttribute("Coins", (spiller:GetAttribute("Coins") or 0) + tjent)
	end
	playerFish[spiller] = {}                              -- beholdningen er tom nu
	opdaterFiskAntal(spiller)
	openSell:FireClient(spiller, lavSummary(spiller))    -- opdater menuen (nu tom)
end)

-- === REBIRTH ===

-- (Rebirth åbnes nu via en permanent skærm-knap i Rebirth.client.luau --
--  der er ingen fysisk kasse i verdenen længere.)

-- Hvilket niveau er det NÆSTE for denne spiller? (nil = max nået)
local function naesteNiveau(spiller)
	local rebirths = spiller:GetAttribute("Rebirths") or 0
	return RebirthConfig[rebirths + 1]
end

-- Ejer spilleren alle de krævede fiskere til dette niveau?
local function ejerAlleFiskere(spiller, niveau)
	local ejet = ownedFishers[spiller] or {}
	for _, navn in niveau.requiredFishers do
		if not ejet[navn] then
			return false
		end
	end
	return true
end

-- Lav og send status til klienten (til menuen + HUD)
local function sendRebirthStatus(spiller)
	local niveau = naesteNiveau(spiller)
	local status
	if not niveau then
		status = {
			isMax = true,
			rebirths = spiller:GetAttribute("Rebirths") or 0,
			currentMultiplier = spiller:GetAttribute("Multiplier") or 1,
		}
	else
		status = {
			isMax = false,
			levelNumber = (spiller:GetAttribute("Rebirths") or 0) + 1,
			requiredCoins = niveau.requiredCoins,
			requiredFishers = niveau.requiredFishers,
			ownsAllFishers = ejerAlleFiskere(spiller, niveau),
			nextMultiplier = niveau.multiplier,               -- multiplieren man FÅR
			rebirths = spiller:GetAttribute("Rebirths") or 0,
			currentMultiplier = spiller:GetAttribute("Multiplier") or 1,
		}
	end
	rebirthEvent:FireClient(spiller, status)
end

-- Ryd plottet: fjern alle placerede fiskere/spande UNDTAGEN robux-købte
local function ryddPlot(spiller)
	local beholdt = {}
	for _, post in placedItems[spiller] or {} do
		if post.robux then
			table.insert(beholdt, post)             -- robux-ting overlever rebirth (til senere)
		elseif post.part then
			post.part:Destroy()                     -- fjern fra plottet
		end
	end
	placedItems[spiller] = beholdt
end

-- Ryd UPLACEREDE fiskere OG spande i backpacken/hånden ved rebirth (robux-markerede undtages)
local function ryddBackpackFiskere(spiller)
	local steder = { spiller:FindFirstChildOfClass("Backpack"), spiller.Character }
	for _, sted in steder do
		if sted then
			for _, ting in sted:GetChildren() do
				if ting:IsA("Tool")
					and (ting:GetAttribute("FisherIndex") or ting:GetAttribute("IsBucket"))
					and not ting:GetAttribute("Robux") then
					ting:Destroy()
				end
			end
		end
	end
end

-- Client sender "do" (udfør rebirth) eller andet (bare giv mig status)
rebirthEvent.OnServerEvent:Connect(function(spiller, handling)
	if handling == "do" then
		local niveau = naesteNiveau(spiller)
		if niveau then
			local coins = spiller:GetAttribute("Coins") or 0
			-- Serveren tjekker ALTID kravene selv (kan ikke snydes fra client)
			if coins >= niveau.requiredCoins and ejerAlleFiskere(spiller, niveau) then
				spiller:SetAttribute("Coins", niveau.startingCoins or STARTKAPITAL)   -- start-coins efter rebirth
				ryddPlot(spiller)                                      -- ryd plottet (ikke robux)
				ryddBackpackFiskere(spiller)                           -- ryd uplacerede fiskere i hotbaren
				playerFish[spiller] = {}                               -- ryd fangede (usolgte) fisk
				opdaterFiskAntal(spiller)                              -- opdater HUD-tallet til 0
				ownedFishers[spiller] = {}                             -- ejerskab nulstilles
				upgradeLevels[spiller] = {}                            -- alle upgrades til niveau 0
				spiller:SetAttribute("Rebirths", (spiller:GetAttribute("Rebirths") or 0) + 1)
				spiller:SetAttribute("Multiplier", niveau.multiplier)  -- ny TOTAL multiplier
			end
		end
	end
	sendRebirthStatus(spiller)   -- send altid opdateret status tilbage
end)

-- === UPGRADE-KØB (sker på serveren) ===
upgradeEvent.OnServerEvent:Connect(function(spiller, handling, fiskerNavn, sporNavn)
	if handling == "buy" then
		local spor = FisherUpgradeConfig[fiskerNavn]
		local liste = spor and spor[sporNavn]
		if liste then
			local niveauer = getNiveauer(spiller, fiskerNavn)
			local niveau = niveauer[sporNavn] or 0
			if niveau < #liste then                           -- ikke max endnu
				local pris = liste[niveau + 1].price
				local coins = spiller:GetAttribute("Coins") or 0
				if coins >= pris then                          -- serveren tjekker råd selv
					spiller:SetAttribute("Coins", coins - pris)
					niveauer[sporNavn] = niveau + 1
					-- Placerede fiskere læser niveauet live -> bonussen virker med det samme
				end
			end
		end
	end
	sendUpgradeStatus(spiller, fiskerNavn)   -- send altid frisk status (menuen opdaterer sig)
end)

print("Fiskeri-tycoon klar (sjældenhed + sælg-menu + rebirth + upgrades).")
