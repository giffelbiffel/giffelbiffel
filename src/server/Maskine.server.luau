-- Maskine.server.luau
-- Fiskeri-tycoon (server). To-lags økonomi: fiskere fanger FISK, fisk sælges til COINS,
-- fiskere købes med COINS. Værdier kommer fra FisherConfig.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FisherConfig = require(ReplicatedStorage:WaitForChild("FisherConfig"))
local FormatNumber = require(ReplicatedStorage:WaitForChild("FormatNumber"))
local PlacementRules = require(ReplicatedStorage:WaitForChild("PlacementRules"))

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

-- Walkie-talkie til coin-popup ved salg (ren visuel besked: "du tjente X")
local sellPopup = Instance.new("RemoteEvent")
sellPopup.Name = "SellPopup"
sellPopup.Parent = ReplicatedStorage

-- Walkie-talkie til at sælge ÉN fisk ad gangen fra sælg-menuen
local sellOne = Instance.new("RemoteEvent")
sellOne.Name = "SellOne"
sellOne.Parent = ReplicatedStorage

-- Walkie-talkie til settings + stats-menuen
local statsEvent = Instance.new("RemoteEvent")
statsEvent.Name = "Stats"
statsEvent.Parent = ReplicatedStorage


-- === GLOBAL FANGST-BESKED (på tværs af ALLE servere via MessagingService) ===
local MessagingService = game:GetService("MessagingService")
local GLOBAL_TOPIC = "UltraRareCatch"
local GLOBAL_TAERSKEL = 1 / 50000   -- 1/50.000 eller sjældnere (chance <= dette tal)

-- server -> alle klienter: vis en besked i den indbyggede chat
local globalCatch = Instance.new("RemoteEvent")
globalCatch.Name = "GlobalCatch"
globalCatch.Parent = ReplicatedStorage

-- Send beskeden ud til ALLE kørende servere (ren visuel besked -- ingen logik)
local function announceUltraRare(spillerNavn, fiskNavn, naevner)
	local tekst = spillerNavn .. " caught a " .. fiskNavn .. "! (1/" .. FormatNumber(naevner) .. ")"
	local ok, err = pcall(function()
		MessagingService:PublishAsync(GLOBAL_TOPIC, tekst)
	end)
	if not ok then
		warn("Global fangst-besked kunne ikke sendes: " .. tostring(err))
	end
end

-- Lyt efter beskeder fra alle servere (også vores egen) -> vis i alles chat
task.spawn(function()
	local ok, err = pcall(function()
		MessagingService:SubscribeAsync(GLOBAL_TOPIC, function(besked)
			globalCatch:FireAllClients(besked.Data)
		end)
	end)
	if not ok then
		warn("Kunne ikke abonnere på globale fangst-beskeder: " .. tostring(err))
	end
end)


-- === FANGST-EFFEKT (visuel -- nem at style om her) ===
local FANGST_EFFEKT = {
	antal = 6,                                  -- partikler per fangst
	farve = Color3.fromRGB(120, 200, 255),      -- lyseblåt "vandsprøjt"
	levetid = 0.5,                              -- sekunder per partikel (kort, under 1 sek)
	fart = 6,                                   -- hvor hurtigt de flyver ud
	stoerrelse = 0.35,                          -- partikel-størrelse
}

-- === EKSTRA effekt ved SJÆLDNE fangster (Basic får ingen -- kun den normale) ===
-- Eskalerer med sjældenhed. Farverne hentes fra FishConfig.colors (samme som sælg-menuen).
local SJAELDEN_EFFEKT = {
	Rare      = { antal = 10, levetid = 0.6, fart = 8,  stoerrelse = 0.4 },   -- lille blåt glimmer
	Epic      = { antal = 18, levetid = 0.8, fart = 10, stoerrelse = 0.5 },   -- lilla burst
	Legendary = { antal = 30, levetid = 1.2, fart = 12, stoerrelse = 0.65 },  -- gyldent lys, lidt længere
}


-- === Sjældenheds-system: fiskene fra FishConfig, oddsene fra hver fisker ===
local FishConfig = require(ReplicatedStorage:WaitForChild("FishConfig"))

-- Bruges hvis en fisker i config'en IKKE har sin egen chances-tabel (så intet crasher)
local DEFAULT_CHANCES = { Basic = "7/10", Rare = "1/5", Epic = "2/25", Legendary = "1/50" }

-- Læs én chance-værdi fra config: en brøk-streng som "1/1000" (eller et rent tal).
-- Kan den ikke læses, advarer vi i Output og bruger 0 -- spillet crasher aldrig.
local function parseChance(vaerdi, rarity)
	if typeof(vaerdi) == "number" then
		return vaerdi                                  -- rå tal virker stadig
	end
	if typeof(vaerdi) == "string" then
		local a, b = string.match(vaerdi, "^%s*(%d+%.?%d*)%s*/%s*(%d+%.?%d*)%s*$")
		if a and b then
			local naevner = tonumber(b)
			if naevner and naevner > 0 then
				return tonumber(a) / naevner           -- "1/1000" -> 0.001
			end
		end
	end
	warn("FisherConfig: kunne ikke læse chancen '" .. tostring(vaerdi)
		.. "' for '" .. tostring(rarity) .. "' -- skriv en brøk som \"1/100\". Bruger 0.")
	return 0
end

-- Oversæt en hel chances-tabel (brøk-strenge) til rene tal, som rulningen bruger
local function normaliserChances(chances)
	local ud = {}
	for rarity, vaerdi in chances do
		ud[rarity] = parseChance(vaerdi, rarity)
	end
	return ud
end

-- Hvor sjælden er en sjældenhed? (plads i rarityOrder -- højere = sjældnere)
local function rarityRang(rarity)
	for i, r in FishConfig.rarityOrder do
		if r == rarity then
			return i
		end
	end
	return 0
end

-- Returnér den sjældneste af to (bruges til at vælge tick'ets kraftigste effekt)
local function bedsteRarity(a, b)
	if not SJAELDEN_EFFEKT[b] then return a end     -- b har ingen ekstra effekt (Basic)
	if not a then return b end
	return rarityRang(b) > rarityRang(a) and b or a
end

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


-- === LIVSTIDS-STATS (i hukommelsen for nu -- DataStore kommer senere) ===
-- VIGTIGT: denne tabel er HELT ADSKILT fra spillerens aktive coins/fisk.
-- Rebirth-rydningen rører den ALDRIG -- tallene stiger for evigt.
local lifetimeStats = {}   -- spiller -> { coinsEarned, fishCaught, byRarity, joinTid, musikTil }

-- +1 fangst (og +1 for fiskens sjældenhed) -- kaldes KUN når en fisk faktisk fanges
local function statsTilfoejFangst(ejer, fisk)
	local s = ejer and lifetimeStats[ejer]
	if s then
		s.fishCaught += 1
		s.byRarity[fisk.rarity] = (s.byRarity[fisk.rarity] or 0) + 1
	end
end

-- +coins tjent (kaldes ved salg -- livstids-total, adskilt fra saldoen)
local function statsTilfoejCoins(spiller, beloeb)
	local s = lifetimeStats[spiller]
	if s then
		s.coinsEarned += beloeb
	end
end

-- Client beder om stats ("get") eller gemmer musik-tilstand ("music", true/false)
statsEvent.OnServerEvent:Connect(function(spiller, handling, vaerdi)
	local s = lifetimeStats[spiller]
	if not s then return end

	if handling == "music" then
		s.musikTil = vaerdi and true or false   -- gemmes, klar til DataStore senere
		return
	end

	statsEvent:FireClient(spiller, {
		coinsEarned = s.coinsEarned,
		fishCaught = s.fishCaught,
		byRarity = s.byRarity,
		playSeconds = os.time() - s.joinTid,    -- spilletid DENNE session
		musikTil = s.musikTil,
	})
end)


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
	lifetimeStats[spiller] = {                     -- livstids-stats (roeres ALDRIG af rebirth)
		coinsEarned = 0,
		fishCaught = 0,
		byRarity = {},
		joinTid = os.time(),
		musikTil = true,
	}
	plot:SetAttribute("Owner", spiller.UserId)
	plot.Skilt.Navn.Text = spiller.Name .. "'s plot"
end

-- (Join/leave håndteres i DATASTORE-sektionen nederst -- spilleren får standard-
--  værdier via spillerJoinede() og får derefter sin GEMTE fremgang lagt ovenpå.
--  Det gøres til sidst, så load/apply kan genskabe placerede fiskere/spande.)


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

	-- Partikel-effekt ved fangst (indbyggede Roblox-partikler, ingen teksturer).
	-- Enabled = false -> den kører IKKE hele tiden; vi kalder :Emit() per fangst.
	local effekt = Instance.new("ParticleEmitter")
	effekt.Enabled = false
	effekt.Color = ColorSequence.new(FANGST_EFFEKT.farve)
	effekt.Lifetime = NumberRange.new(FANGST_EFFEKT.levetid)
	effekt.Speed = NumberRange.new(FANGST_EFFEKT.fart)
	effekt.SpreadAngle = Vector2.new(180, 180)     -- sprøjt i alle retninger
	effekt.Size = NumberSequence.new(FANGST_EFFEKT.stoerrelse)
	effekt.Parent = fisker

	-- Ekstra emitters til sjældne fangster: én per sjældenhed, farve fra FishConfig
	-- (samme farver som sælg-menuen). Enabled=false -> fyres kun med :Emit().
	local sjaeldenEmitters = {}
	for rarity, indstilling in SJAELDEN_EFFEKT do
		local e = Instance.new("ParticleEmitter")
		e.Enabled = false
		e.Color = ColorSequence.new(FishConfig.colors[rarity] or Color3.fromRGB(255, 255, 255))
		e.Lifetime = NumberRange.new(indstilling.levetid)
		e.Speed = NumberRange.new(indstilling.fart)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Size = NumberSequence.new(indstilling.stoerrelse)
		e.LightEmission = rarity == "Legendary" and 1 or 0.4   -- Legendary "gløder"
		e.Parent = fisker
		sjaeldenEmitters[rarity] = e
	end

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

	-- Oversæt config'ens brøker til tal ÉN gang per fisker (fejl vises kun én gang)
	local grundChances = normaliserChances(def.chances or DEFAULT_CHANCES)

	-- Global besked hvis fangstens sjældenhed er 1/50.000 eller sjældnere
	local function maaskeGlobalBesked(fisk)
		local chance = grundChances[fisk.rarity]
		if ejer and chance and chance > 0 and chance <= GLOBAL_TAERSKEL then
			announceUltraRare(ejer.Name, fisk.name, math.floor(1 / chance + 0.5))
		end
	end

	local function effektiveChances()
		local pct = totalBonusPct(spor and spor.catchChance, ejer and getNiveauer(ejer, def.name).catchChance or 0)
		return justeretChances(grundChances, pct)
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

			local fangetNoget = false
			local bedsteSjaelden = nil    -- tick'ets sjældneste fangst (Rare/Epic/Legendary)

			for _ = 1, def.fishPerCatch do
				-- rul en fisk med catchChance-justerede odds
				local fisk = rollFish(effektiveChances())

				if fisk then
					local spand = foersteLedigeSpand()   -- laveste ikke-fulde spand
					if spand then
						-- der er en spand med plads -> fisken flyder derhen
						table.insert(spand.list, fisk)
						spand.part:SetAttribute("Indhold", #spand.list)
						fangetNoget = true
						statsTilfoejFangst(ejer, fisk)   -- livstids-tæller
						bedsteSjaelden = bedsteRarity(bedsteSjaelden, fisk.rarity)
						maaskeGlobalBesked(fisk)
					elseif #fisherList < effektivKapacitet() then
						-- FØRST når ALLE spande er fulde: fiskeren beholder fisken selv
						table.insert(fisherList, fisk)
						fisker:SetAttribute("Indhold", #fisherList)
						opdaterSkilt()
						fangetNoget = true
						statsTilfoejFangst(ejer, fisk)   -- livstids-tæller
						bedsteSjaelden = bedsteRarity(bedsteSjaelden, fisk.rarity)
						maaskeGlobalBesked(fisk)
					end
					-- er alle spande OG fiskeren fulde: der fanges ikke mere (som før)
				end
			end

			if fangetNoget then
				effekt:Emit(FANGST_EFFEKT.antal)   -- kort partikel-burst ved fangst (uændret)
			end
			if bedsteSjaelden then
				-- EKSTRA burst oveni ved sjælden fangst (Rare/Epic/Legendary)
				sjaeldenEmitters[bedsteSjaelden]:Emit(SJAELDEN_EFFEKT[bedsteSjaelden].antal)
			end
		end
	end)

	-- OFFLINE-INDTJENING: et lille interface, så load-simuleringen kan genbruge
	-- DENNE fiskers egne regler (rate, chance-tabel, kapacitet) uden at røre online-løkken.
	local offline = {
		ventetid = effektivVentetid,          -- funktion: fiskerens effektive ventetid
		fishPerCatch = def.fishPerCatch,
		kapacitet = effektivKapacitet,        -- funktion: fiskerens effektive kapacitet
		rul = function()
			return rollFish(effektiveChances())   -- samme rul som online
		end,
		laegISelv = function(fisk)                -- læg i fiskerens egen liste hvis plads
			if #fisherList < effektivKapacitet() then
				table.insert(fisherList, fisk)
				fisker:SetAttribute("Indhold", #fisherList)
				opdaterSkilt()
				return true
			end
			return false
		end,
	}

	return fisker, offline
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

	-- SAMME regel som spøgelsets grøn/rød (fælles modul) -> rødt klik afvises her
	if not PlacementRules.erGyldig(klikPosition) then return end

	if tool:GetAttribute("FisherIndex") then
		-- FISKER
		local def = FisherConfig.fishers[tool:GetAttribute("FisherIndex")]
		if def then
			-- PRÆCIS samme placeringsregler som før (løft 2 op, ingen andre regler)
			local placering = Vector3.new(klikPosition.X, klikPosition.Y + 2, klikPosition.Z)
			local part = lavFisker(def, placering, spiller)   -- ejer = til upgrade-bonusser
			-- REBIRTH + DATASTORE: husk placeringen med type/navn (robux-flag følger tool'et)
			if placedItems[spiller] then
				table.insert(placedItems[spiller], {
					part = part, robux = tool:GetAttribute("Robux") or false,
					kind = "fisher", name = def.name,
				})
			end
			tool:Destroy()   -- fjern tool'et fra hotbaren efter placering
		end
	elseif tool:GetAttribute("IsBucket") then
		-- SPAND (samme placeringsregel som før: løft 3 op, spanden er 6 høj)
		local placering = Vector3.new(klikPosition.X, klikPosition.Y + 3, klikPosition.Z)
		local part = lavBucket(placering)
		if placedItems[spiller] then
			table.insert(placedItems[spiller], {
				part = part, robux = tool:GetAttribute("Robux") or false,
				kind = "bucket",
			})
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
		statsTilfoejCoins(spiller, tjent)                      -- livstids-total
		sellPopup:FireClient(spiller, tjent, 3)                -- Sælg Alt: op til 3 popups
	end
	playerFish[spiller] = {}                              -- beholdningen er tom nu
	opdaterFiskAntal(spiller)
	openSell:FireClient(spiller, lavSummary(spiller))    -- opdater menuen (nu tom)
end)

-- Client trykker "Sell" på ÉN fisk-gruppe -> sælg én enkelt fisk af den type
sellOne.OnServerEvent:Connect(function(spiller, fiskNavn)
	local fiskListe = playerFish[spiller] or {}
	for i, def in fiskListe do
		if def.name == fiskNavn then
			table.remove(fiskListe, i)                          -- fjern netop den ene fisk
			local mult = spiller:GetAttribute("Multiplier") or 1
			local tjent = math.floor(def.value * mult)          -- samme multiplier som Sælg Alt
			if tjent > 0 then
				spiller:SetAttribute("Coins", (spiller:GetAttribute("Coins") or 0) + tjent)
				statsTilfoejCoins(spiller, tjent)               -- livstids-total
				sellPopup:FireClient(spiller, tjent, 1)         -- enkelt-salg: præcis 1 popup
			end
			opdaterFiskAntal(spiller)
			openSell:FireClient(spiller, lavSummary(spiller))   -- opdater menuen
			return
		end
	end
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

-- Push også frisk status efter et fisker-køb, så progress-barens ✓/✗ følger med live.
-- (Ekstra lytter -- rører ikke selve købs-handleren. task.defer = kør EFTER at
--  købs-handleren har registreret ejerskabet.)
buyFisher.OnServerEvent:Connect(function(spiller, kind)
	if kind == "fisher" then
		task.defer(sendRebirthStatus, spiller)
	end
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

-- ============================================================
-- === DATASTORE: gem og hent spillerens fremgang =============
-- ============================================================
local ServerScriptService = game:GetService("ServerScriptService")
local DataStore = require(ServerScriptService:WaitForChild("DataStore"))

local DATA_VERSION = 1        -- bump hvis et felts BETYDNING ændres (til migrering senere)
local AUTOSAVE_SEK = 240      -- gem hver 4. minut

local dataLoaded = {}         -- spiller -> true når data er hentet SIKKERT (må gemmes)
local dontSave = {}           -- spiller -> true hvis hent FEJLEDE (gem ALDRIG => beskyt data)

-- Standard-data for en helt ny spiller (også "skabelonen" nye felter tilføjes i)
local function standardData()
	return {
		version = DATA_VERSION,
		coins = STARTKAPITAL,
		fish = {},
		owned = {},
		placed = {},
		rebirths = 0,
		multiplier = 1,
		upgrades = {},
		backpack = {},   -- uplacerede tools i hotbaren (fiskere + spande)
		lifetime = { coinsEarned = 0, fishCaught = 0, byRarity = {} },
		settings = { music = true },
		lastLogout = 0,  -- server-tid ved sidste gem (til offline-indtjening)
	}
end

-- Genskab ét uplaceret tool i backpacken ud fra en gemt post (samme slags Tool
-- som købet laver). Client-lytteren kobler selv Activated på via Backpack.ChildAdded.
local function genskabTool(backpack, entry)
	local tool = Instance.new("Tool")
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool.ToolTip = "Click on your plot to place"
	tool:SetAttribute("Robux", entry.robux and true or false)

	if entry.kind == "bucket" then
		tool.Name = FisherConfig.bucket.name
		tool:SetAttribute("IsBucket", true)
	elseif entry.kind == "fisher" then
		local def = FisherConfig.fishers[entry.index]
		if not def then return end          -- ukendt index (config ændret) -> spring over
		tool.Name = def.name
		tool:SetAttribute("FisherIndex", entry.index)
	else
		return
	end

	tool.Parent = backpack
end

-- Saml spillerens NUVÆRENDE tilstand til en gemme-tabel (kun rene tal/tekst -- DataStore-venligt)
local function serialize(spiller)
	local data = standardData()
	data.coins = spiller:GetAttribute("Coins") or STARTKAPITAL
	data.rebirths = spiller:GetAttribute("Rebirths") or 0
	data.multiplier = spiller:GetAttribute("Multiplier") or 1

	for _, f in playerFish[spiller] or {} do
		table.insert(data.fish, { name = f.name, rarity = f.rarity, value = f.value })
	end

	for navn in ownedFishers[spiller] or {} do
		table.insert(data.owned, navn)
	end

	for _, post in placedItems[spiller] or {} do
		local part = post.part
		if part and part.Parent then          -- gem kun ting der stadig står på plottet
			table.insert(data.placed, {
				kind = post.kind,
				name = post.name,             -- kun for fiskere
				x = part.Position.X, y = part.Position.Y, z = part.Position.Z,
				robux = post.robux and true or false,
			})
		end
	end

	for navn, spor in upgradeLevels[spiller] or {} do
		data.upgrades[navn] = {
			speed = spor.speed or 0,
			capacity = spor.capacity or 0,
			catchChance = spor.catchChance or 0,
		}
	end

	-- Uplacerede tools i backpacken/hånden (købt men ikke placeret endnu)
	for _, sted in { spiller:FindFirstChildOfClass("Backpack"), spiller.Character } do
		if sted then
			for _, ting in sted:GetChildren() do
				if ting:IsA("Tool") then
					if ting:GetAttribute("FisherIndex") then
						table.insert(data.backpack, {
							kind = "fisher",
							index = ting:GetAttribute("FisherIndex"),
							robux = ting:GetAttribute("Robux") and true or false,
						})
					elseif ting:GetAttribute("IsBucket") then
						table.insert(data.backpack, {
							kind = "bucket",
							robux = ting:GetAttribute("Robux") and true or false,
						})
					end
				end
			end
		end
	end

	local s = lifetimeStats[spiller]
	if s then
		data.lifetime.coinsEarned = s.coinsEarned
		data.lifetime.fishCaught = s.fishCaught
		for rarity, antal in s.byRarity do
			data.lifetime.byRarity[rarity] = antal
		end
		data.settings.music = s.musikTil and true or false
	end

	data.lastLogout = os.time()   -- gem NUVÆRENDE server-tid (til offline-beregning ved næste join)

	return data
end

-- Anvend gemt data på spillerens tilstand. Hvert felt læses MED fallback,
-- så gamle saves uden et nyt felt bare får standardværdien (ingen crash, intet tab).
local function anvendData(spiller, data)
	spiller:SetAttribute("Coins", data.coins or STARTKAPITAL)
	spiller:SetAttribute("Rebirths", data.rebirths or 0)
	spiller:SetAttribute("Multiplier", data.multiplier or 1)

	playerFish[spiller] = {}
	for _, f in data.fish or {} do
		table.insert(playerFish[spiller], { name = f.name, rarity = f.rarity, value = f.value })
	end
	opdaterFiskAntal(spiller)

	ownedFishers[spiller] = {}
	for _, navn in data.owned or {} do
		ownedFishers[spiller][navn] = true
	end

	upgradeLevels[spiller] = {}
	for navn, spor in data.upgrades or {} do
		upgradeLevels[spiller][navn] = {
			speed = spor.speed or 0,
			capacity = spor.capacity or 0,
			catchChance = spor.catchChance or 0,
		}
	end

	lifetimeStats[spiller] = {
		coinsEarned = (data.lifetime and data.lifetime.coinsEarned) or 0,
		fishCaught = (data.lifetime and data.lifetime.fishCaught) or 0,
		byRarity = {},
		joinTid = os.time(),
		musikTil = not (data.settings and data.settings.music == false),   -- default true
	}
	if data.lifetime and data.lifetime.byRarity then
		for rarity, antal in data.lifetime.byRarity do
			lifetimeStats[spiller].byRarity[rarity] = antal
		end
	end

	-- Genskab placerede fiskere/spande på plottet
	placedItems[spiller] = {}
	for _, p in data.placed or {} do
		local pos = Vector3.new(p.x or 0, p.y or 0, p.z or 0)
		if p.kind == "bucket" then
			local part = lavBucket(pos)
			table.insert(placedItems[spiller], { part = part, robux = p.robux, kind = "bucket" })
		elseif p.kind == "fisher" then
			local def                                     -- find fisker-typen ud fra navnet
			for _, d in FisherConfig.fishers do
				if d.name == p.name then def = d break end
			end
			if def then                                   -- ukendt navn (fjernet fra config?) -> spring over
				local part, offline = lavFisker(def, pos, spiller)
				table.insert(placedItems[spiller], { part = part, robux = p.robux, kind = "fisher", name = p.name, offline = offline })
			end
		end
	end

	-- Genskab UPLACEREDE tools i backpacken (fallback til tom hvis feltet mangler)
	local backpackListe = data.backpack or {}
	if #backpackListe > 0 then
		task.spawn(function()
			-- ÅRSAG TIL FEJLEN: Robloxs egen spawn-proces laver en FRISK Backpack og
			-- rydder den, når Character spawner. Vi tilføjede tools FØR det skete, så de
			-- blev wiped. FIX: vent til Character er fuldt spawnet, hent så den ENDELIGE
			-- Backpack, og læg først tools i der.
			local character = spiller.Character or spiller.CharacterAdded:Wait()
			character:WaitForChild("Humanoid")
			task.wait(1)   -- lad Robloxs spawn-backpack-opsætning blive helt færdig
			local backpack = spiller:FindFirstChildOfClass("Backpack")
			if not backpack then return end
			for _, entry in backpackListe do
				genskabTool(backpack, entry)
			end
		end)
	end
end

-- OFFLINE-INDTJENING: simulér fangst for tiden siden logout, med reduceret hastighed.
-- Bruger SAMME regler som online (per-fisker chance-tabel, sjældenhed, upgrades) og
-- SAMME spand-rækkefølge. Stopper naturligt når alt er fyldt til kapacitets-loftet.
local function simulerOffline(spiller, elapsedSek)
	if elapsedSek <= 0 then return end
	local rate = FisherConfig.offlineRate or 0.35
	local produktivTid = elapsedSek * rate      -- "fange-tid" offline = forløbet tid * rate
	if produktivTid <= 0 then return end

	-- Samlet ledig kapacitet = ØVRE grænse. Sikrer at simuleringen ALTID stopper ved
	-- loftet -- også hvis spilleren har været væk i dagevis (aldrig en uendelig løkke).
	local totalPlads = 0
	for _, b in plotBuckets do
		if b.part.Parent then
			totalPlads += math.max(b.capacity - #b.list, 0)
		end
	end
	for _, post in placedItems[spiller] or {} do
		if post.offline then
			totalPlads += math.max(post.offline.kapacitet(), 0)   -- fisker lige oprettet -> tom
		end
	end
	if totalPlads <= 0 then return end          -- ingen placerede fiskere/spande -> intet at fange

	for _, post in placedItems[spiller] or {} do
		local o = post.offline
		if o then
			local ventetid = o.ventetid()
			if ventetid and ventetid > 0 then
				-- hvor mange fisk DENNE fisker ville have fanget, men aldrig mere end der er plads
				local antalFisk = math.min(math.floor(produktivTid / ventetid) * o.fishPerCatch, totalPlads)
				for _ = 1, antalFisk do
					local fisk = o.rul()
					if fisk then
						-- Fordel som online: første ledige spand (i rækkefølge), ellers fiskeren selv
						local spand = foersteLedigeSpand()
						if spand then
							table.insert(spand.list, fisk)
							spand.part:SetAttribute("Indhold", #spand.list)
						elseif not o.laegISelv(fisk) then
							break   -- alle spande OG denne fisker er fulde -> videre til næste fisker
						end
					end
				end
			end
		end
	end
end

-- HENT ved join: standardværdier først, derefter gemt fremgang ovenpå
local function haandterJoin(spiller)
	spillerJoinede(spiller)   -- standard + tildel plot, så alt findes med det samme

	local ok, gemt = DataStore.load(spiller.UserId)
	if not spiller.Parent then return end   -- spilleren forlod under hentningen

	if not ok then
		-- DataStore FEJLEDE -> vi ved IKKE hvad spilleren ejer. Gem ALDRIG denne
		-- session, så vi ikke overskriver god data med standardværdier.
		dontSave[spiller] = true
		warn("[Data] Kunne ikke hente data for " .. spiller.Name
			.. " -- gemning slået fra denne session for at BESKYTTE eksisterende data.")
		return
	end

	if gemt then
		local okApply = pcall(anvendData, spiller, gemt)
		if not okApply then
			dontSave[spiller] = true          -- uventet/korrupt data -> behold standard, gem ikke
			warn("[Data] Gemt data for " .. spiller.Name .. " kunne ikke læses -- gemning slået fra.")
			return
		end

		-- OFFLINE-INDTJENING: simulér fangst for tiden siden sidste logout (server-side, ved load)
		local elapsed = os.time() - (gemt.lastLogout or os.time())
		pcall(simulerOffline, spiller, elapsed)
	end
	-- ny spiller (gemt == nil) beholder bare standardværdierne
	dataLoaded[spiller] = true
end

-- GEM en spiller (med alle sikkerhedstjek)
local function gemSpiller(spiller)
	if dontSave[spiller] then return end        -- hent fejlede -> overskriv aldrig
	if not dataLoaded[spiller] then return end  -- data nåede ikke at blive hentet -> gem ikke
	DataStore.save(spiller.UserId, serialize(spiller))
end

-- Ryd hukommelse op når spilleren forlader (og GEM først)
local function haandterLeave(spiller)
	gemSpiller(spiller)
	playerFish[spiller] = nil
	ownedFishers[spiller] = nil
	placedItems[spiller] = nil
	upgradeLevels[spiller] = nil
	lifetimeStats[spiller] = nil
	dataLoaded[spiller] = nil
	dontSave[spiller] = nil
end

for _, spiller in Players:GetPlayers() do   -- dem der allerede er her (Play Solo)
	task.spawn(haandterJoin, spiller)
end
Players.PlayerAdded:Connect(haandterJoin)
Players.PlayerRemoving:Connect(haandterLeave)

-- AUTO-GEM: hver 4. minut, spredt ud så vi ikke rammer DataStore rate-limits
task.spawn(function()
	while true do
		task.wait(AUTOSAVE_SEK)
		for _, spiller in Players:GetPlayers() do
			gemSpiller(spiller)
			task.wait(1)                     -- lille pause mellem spillere (rate-limit venligt)
		end
	end
end)

-- Server lukker/genstarter: gem ALLE tilbageværende spillere før nedlukning
game:BindToClose(function()
	for _, spiller in Players:GetPlayers() do
		gemSpiller(spiller)                  -- kører sekventielt -> DataStore når at fuldføre
	end
end)

print("Fiskeri-tycoon klar (sjældenhed + sælg-menu + rebirth + upgrades + DataStore).")
