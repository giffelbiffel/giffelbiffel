-- Maskine.server.luau
-- Fiskeri-tycoon (server). Tre fisker-typer + en shop man kan købe fra.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Walkie-talkien mellem client og server. Vi laver den her, og client finder den.
local buyFisher = Instance.new("RemoteEvent")
buyFisher.Name = "BuyFisher"
buyFisher.Parent = ReplicatedStorage


-- === Hvor skal næste fisker stå? ===
-- Vi rykker 8 til siden for hver ny fisker, så de ikke står oven i hinanden.
local naesteX = 0
local function naestePosition()
	local position = Vector3.new(naesteX, 2, 0)
	naesteX = naesteX + 8
	return position
end


-- === OPSKRIFT: lav én fisker med sine egne værdier ===
local function lavFisker(navn, position, kapacitet, sekunderPrFisk)
	local fisker = Instance.new("Part")
	fisker.Name = navn
	fisker.Size = Vector3.new(4, 4, 4)
	fisker.Position = position
	fisker.Anchored = true
	fisker.BrickColor = BrickColor.new("Medium stone grey")
	fisker.Parent = workspace
	fisker:SetAttribute("Indhold", 0)

	-- Svævende skilt
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

	-- Tøm ved berøring
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

	-- Fang fisk over tid (egen tråd)
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


-- === De tre start-fiskere ===
lavFisker("BasicFisher",  naestePosition(), 50,  3)
lavFisker("BetterFisher", naestePosition(), 100, 2)
lavFisker("TopFisher",    naestePosition(), 200, 1)


-- === SHOP-manden (fysisk objekt i verdenen) ===
local shop = Instance.new("Part")
shop.Name = "Shop"
shop.Size = Vector3.new(4, 6, 4)
shop.Position = Vector3.new(8, 3, 14)          -- står lidt foran fiskerne
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


-- === KØBET (sker på serveren — her bestemmes reglerne) ===
local PRIS = 50

buyFisher.OnServerEvent:Connect(function(spiller)
	local mineFisk = spiller:GetAttribute("Fisk") or 0

	if mineFisk >= PRIS then
		spiller:SetAttribute("Fisk", mineFisk - PRIS)       -- træk prisen
		lavFisker("BasicFisher", naestePosition(), 50, 3)   -- lav en ny basis-fisker
		buyFisher:FireClient(spiller, true, "Bought a Basic Fisher!")
	else
		buyFisher:FireClient(spiller, false, "Not enough fish")
	end
end)

print("Fiskeri-tycoon klar: tre fiskere + shop.")
