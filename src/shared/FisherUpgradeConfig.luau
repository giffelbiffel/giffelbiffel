-- FisherUpgradeConfig.luau  (en ModuleScript -- en "delefil")
-- HER bor upgrade-sporene for hver fisker-type. Ret alle tal frit.
--
-- Hver fisker-type har op til tre spor:
--   speed       = fanger hurtigere
--   capacity    = kan rumme flere fisk
--   catchChance = bedre odds for sjældne fisk (valgfrit spor)
--
-- Hvert spor er en LISTE af niveauer. Hvert niveau har:
--   price = hvad niveauet koster i coins
--   bonus = hvor mange PROCENT ekstra netop dét niveau lægger til
--           (bonusser LÆGGES SAMMEN: 3 niveauer af +5% = +15% i alt)
--
-- MAX-NIVEAU = antallet af linjer i sporet. Vil du have flere niveauer,
-- tilføjer du bare flere linjer. Færre = slet linjer. Kan variere frit
-- per fisker-type og per spor.

return {
	["Basic Fisher"] = {
		speed = {
			{ price = 100,  bonus = 5 },
			{ price = 250,  bonus = 5 },
			{ price = 600,  bonus = 5 },
			{ price = 1500, bonus = 5 },
		},
		capacity = {
			{ price = 150,  bonus = 10 },
			{ price = 400,  bonus = 10 },
			{ price = 1000, bonus = 10 },
		},
		catchChance = {
			{ price = 500,  bonus = 10 },
			{ price = 2000, bonus = 10 },
		},
	},

	["Better Fisher"] = {
		speed = {
			{ price = 300,  bonus = 6 },
			{ price = 800,  bonus = 6 },
			{ price = 2000, bonus = 6 },
			{ price = 5000, bonus = 6 },
		},
		capacity = {
			{ price = 400,  bonus = 12 },
			{ price = 1200, bonus = 12 },
			{ price = 3000, bonus = 12 },
		},
		catchChance = {
			{ price = 1500, bonus = 12 },
			{ price = 5000, bonus = 12 },
		},
	},

	["Top Fisher"] = {
		speed = {
			{ price = 1000,  bonus = 8 },
			{ price = 3000,  bonus = 8 },
			{ price = 8000,  bonus = 8 },
			{ price = 20000, bonus = 8 },
		},
		capacity = {
			{ price = 1500,  bonus = 15 },
			{ price = 4000,  bonus = 15 },
			{ price = 10000, bonus = 15 },
		},
		catchChance = {
			{ price = 5000,  bonus = 15 },
			{ price = 15000, bonus = 15 },
			{ price = 50000, bonus = 15 },
		},
	},
}
