-- Maskine.server.luau
-- Fase 1: Lav ÉN grå kasse (en "maskine"), der bliver sat på baseplaten,
-- når spillet starter. Ikke andet endnu. Vi bygger videre senere.

local maskine = Instance.new("Part")        -- 1. Lav en ny kasse
maskine.Name = "Maskine"                     -- 2. Giv den navnet "Maskine"
maskine.Size = Vector3.new(4, 4, 4)          -- 3. Gør den 4x4x4 stor
maskine.Position = Vector3.new(0, 2, 0)      -- 4. Placér den midt på baseplaten
maskine.Anchored = true                      -- 5. Lås den fast, så den ikke falder
maskine.BrickColor = BrickColor.new("Medium stone grey")  -- 6. Gør den grå
maskine.Parent = workspace                   -- 7. Sæt den ind i spillet

print("Maskinen er placeret på baseplaten!")  -- 8. Skriv en besked i Output


-- === FASE 2: Maskinen tjener penge ===

local kapacitet = 50                      -- Maks hvor meget maskinen kan rumme
maskine:SetAttribute("Indhold", 0)        -- Maskinen starter tom (0 penge inde i sig)


-- === FASE 3: Tøm fiskeren ved at røre ham ===

local Players = game:GetService("Players")   -- Giver os adgang til spillerne i spillet

maskine.Touched:Connect(function(andetObjekt)
	local figur = andetObjekt.Parent          -- Det, der rørte fiskeren, hører til en "figur"
	local spiller = Players:GetPlayerFromCharacter(figur)  -- Er den figur en spiller?

	if spiller then                           -- Ja, det var en rigtig spiller
		local fiskIFiskeren = maskine:GetAttribute("Indhold")  -- Hvor mange fisk har han?

		if fiskIFiskeren > 0 then             -- Er der overhovedet noget at hente?
			local mineFisk = spiller:GetAttribute("Fisk") or 0  -- Mine fisk indtil nu (0 hvis tom)
			mineFisk = mineFisk + fiskIFiskeren                 -- Læg fiskerens fisk til mine
			spiller:SetAttribute("Fisk", mineFisk)             -- Gem totalen på mig (spilleren)

			maskine:SetAttribute("Indhold", 0)                 -- Tøm fiskeren, så han kan fange igen

			print("Dine fisk: " .. mineFisk)                   -- Vis min samlede total
		end
	end
end)


while true do                             -- Gentag for evigt...
	task.wait(1)                          -- ...vent 1 sekund mellem hver gang

	local indhold = maskine:GetAttribute("Indhold")  -- Hent hvor meget der er inde nu

	if indhold < kapacitet then           -- Er der plads til mere? (under 50)
		indhold = indhold + 1             -- Læg 1 penge til
		maskine:SetAttribute("Indhold", indhold)     -- Gem det nye tal inde i maskinen
		print("Maskine: " .. indhold .. "/" .. kapacitet)  -- Vis fx "Maskine: 1/50"

		if indhold == kapacitet then      -- Lige blevet fuld? (ramte 50)
			print("inventory full")       -- Skriv beskeden og stop med at tjene
		end
	end
end
