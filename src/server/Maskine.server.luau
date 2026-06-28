-- Maskine.server.luau
-- Fiskeri-tycoon (server). Fiskernes værdier kommer nu fra FisherConfig.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Læs config-filen (delefilen med alle fiskernes værdier)
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

-- === Tildel plottet til en spiller ===
local function tildelPlot(spiller)
	plot:SetAttribute("Owner", spiller.UserId)
	plot.Skilt.Navn.Text = spiller.Name .. "'s plot"
end
for _, spiller in Players:GetPlayers() do
	tildelPlot(spiller)
end
Players.PlayerAdded:Connect(tildelPlot)


-- === Hvor skal næste fisker stå PÅ plottet? ===
local fiskerNr = 0
local function naestePosition()
	local lokalX = -12 + fiskerNr * 8
	fiskerNr = fiskerNr + 1
	return Vector3.new(PLOT_POSITION.X + lokalX, 3, PLOT_POSITION.Z)
end


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

	-- Fang fisk over tid (egen tråd) -- bruger config-værdierne
	task.spawn(function()
		while true do
			task.wait(def.catchEvery)
			local indhold = fisker:GetAttribute("Indhold")
			if indhold < def.capacity then
				-- læg fishPerCatch til, men aldrig over kapacitet
				local nyt = math.min(indhold + def.fishPerCatch, def.capacity)
				fisker:SetAttribute("Indhold", nyt)
				opdaterSkilt()
			end
		end
	end)
end


-- === Start-fiskere: én af hver type i config'en ===
for _, def in FisherConfig do
	lavFisker(def, naestePosition())
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


-- === KØB (sker på serveren) ===
-- Client sender hvilken fisker (et nummer = pladsen i config-listen).
buyFisher.OnServerEvent:Connect(function(spiller, index)
	local def = FisherConfig[index]
	if not def then return end                         -- ugyldigt nummer -- ignorér

	local mineFisk = spiller:GetAttribute("Fisk") or 0
	if mineFisk >= def.price then
		spiller:SetAttribute("Fisk", mineFisk - def.price)
		spiller:SetAttribute("PendingFisher", index)   -- husk hvilken type jeg skal placere
		buyFisher:FireClient(spiller, true, "Click on your plot to place the fisher")
	else
		buyFisher:FireClient(spiller, false, "Not enough fish")
	end
end)

-- === PLACERING (sker på serveren) ===
placeFisher.OnServerEvent:Connect(function(spiller, klikPosition)
	local index = spiller:GetAttribute("PendingFisher") or 0
	local def = FisherConfig[index]
	if def then
		spiller:SetAttribute("PendingFisher", 0)        -- brugt op
		local placering = Vector3.new(klikPosition.X, klikPosition.Y + 2, klikPosition.Z)
		lavFisker(def, placering)
	end
end)

print("Fiskeri-tycoon klar (config-styret).")
