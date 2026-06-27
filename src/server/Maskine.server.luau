-- Maskine.server.luau
-- Fiskeri-tycoon. Nu med TRE typer fiskere.
-- Vi laver én opskrift "lavFisker" og kalder den tre gange med forskellige værdier.

local Players = game:GetService("Players")

-- === OPSKRIFT: lav én fisker med sine egne værdier ===
-- navn           = hvad fiskeren hedder
-- position       = hvor i verdenen den står
-- kapacitet      = hvor mange fisk den kan rumme (maks)
-- sekunderPrFisk = hvor lang tid mellem hver fisk
local function lavFisker(navn, position, kapacitet, sekunderPrFisk)

	-- 1. Selve den grå kasse
	local fisker = Instance.new("Part")
	fisker.Name = navn
	fisker.Size = Vector3.new(4, 4, 4)
	fisker.Position = position
	fisker.Anchored = true
	fisker.BrickColor = BrickColor.new("Medium stone grey")
	fisker.Parent = workspace
	fisker:SetAttribute("Indhold", 0)          -- starter tom

	-- 2. Svævende skilt over fiskeren
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

	-- Opskrift til at opdatere DENNE fiskers skilt (grøn/rød)
	local function opdaterSkilt()
		local indhold = fisker:GetAttribute("Indhold")
		if indhold >= kapacitet then
			tekst.Text = "INVENTORY FULL"
			tekst.TextColor3 = Color3.fromRGB(230, 50, 50)   -- rød
		else
			tekst.Text = indhold .. " / " .. kapacitet
			tekst.TextColor3 = Color3.fromRGB(60, 220, 90)   -- grøn
		end
	end
	opdaterSkilt()                             -- vis "0 / X" fra start

	-- 3. Tøm fiskeren ved berøring
	fisker.Touched:Connect(function(andetObjekt)
		local spiller = Players:GetPlayerFromCharacter(andetObjekt.Parent)
		if spiller then
			local fiskIFiskeren = fisker:GetAttribute("Indhold")
			if fiskIFiskeren > 0 then
				local mineFisk = (spiller:GetAttribute("Fisk") or 0) + fiskIFiskeren
				spiller:SetAttribute("Fisk", mineFisk)     -- læg til min konto
				fisker:SetAttribute("Indhold", 0)          -- tøm fiskeren
				opdaterSkilt()                             -- skiltet bliver grønt igen
				print("Dine fisk: " .. mineFisk)
			end
		end
	end)

	-- 4. Fang fisk over tid -- i sin EGEN tråd, så flere fiskere kan køre samtidig
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

-- === Lav de tre fiskere ===
--          navn            position                kapacitet   sekunder
lavFisker("Basisfisker",  Vector3.new(0, 2, 0),     50,         3)
lavFisker("Bedrefisker",  Vector3.new(8, 2, 0),     100,        2)
lavFisker("Topfisker",    Vector3.new(16, 2, 0),    200,        1)

print("Tre fiskere er placeret!")
