-- FishConfig.luau  (en ModuleScript -- en "delefil")
-- HER bor selve fiskene, grupperet efter sjældenhed. Ret frit.
--
-- Sjældenheds-ODDSENE bor IKKE her -- de bor på hver fisker i FisherConfig.luau,
-- så forskellige fiskere kan have forskellige chancer. Her bestemmer du kun
-- HVILKE fisk der findes i hver sjældenhed, og hvad de er værd.

return {
	-- Rækkefølge sjældenheder vises i sælg-menuen (øverst først).
	rarityOrder = { "Common", "Rare", "Epic", "Legendary" },

	-- Farve pr. sjældenhed (bruges i sælg-menuen).
	colors = {
		Common = Color3.fromRGB(200, 200, 200),      -- grå
		Rare = Color3.fromRGB(80, 140, 255),         -- blå
		Epic = Color3.fromRGB(180, 90, 240),         -- lilla
		Legendary = Color3.fromRGB(255, 200, 60),    -- guld
	},

	-- Alle fisk, samlet under deres sjældenhed.
	--   name  = navnet (vises i menuen) -- SKRIV PÅ ENGELSK
	--   value = hvor mange coins fisken giver, når den sælges
	-- Tilføj/fjern frit -- antallet i hver gruppe er bare hvor mange du skriver.
	fish = {
		Common = {
			{ name = "Anchovy",  value = 1 },
			{ name = "Mackerel", value = 2 },
			{ name = "Cod",      value = 3 },
		},
		Rare = {
			{ name = "Salmon", value = 6 },
			{ name = "Tuna",   value = 10 },
		},
		Epic = {
			{ name = "Swordfish", value = 25 },
			{ name = "Manta Ray", value = 35 },
		},
		Legendary = {
			{ name = "Golden Koi", value = 120 },
		},
	},
}
