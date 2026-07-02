-- FishConfig.luau  (en ModuleScript -- en "delefil")
-- HER bor fisketyperne og sjældenheds-oddsene. Ret frit for at ændre spillet.

return {
	-- Chance for hver sjældenhed. Behøver ikke summe til 100 --
	-- vi regner selv forholdet ud, så du kan skrive hvilke tal du vil.
	chances = {
		Common = 70,
		Rare = 20,
		Epic = 8,
		Legendary = 2,
	},

	-- Rækkefølge sjældenheder vises i sælg-menuen (øverst først).
	rarityOrder = { "Common", "Rare", "Epic", "Legendary" },

	-- Farve pr. sjældenhed (bruges i sælg-menuen).
	colors = {
		Common = Color3.fromRGB(200, 200, 200),      -- grå
		Rare = Color3.fromRGB(80, 140, 255),         -- blå
		Epic = Color3.fromRGB(180, 90, 240),         -- lilla
		Legendary = Color3.fromRGB(255, 200, 60),    -- guld
	},

	-- Fisketyper.
	--   name   = navnet (vises i menuen) -- SKRIV PÅ ENGELSK
	--   rarity = sjældenhed (skal matche en af dem i "chances" ovenfor)
	--   value  = hvor mange coins fisken giver, når den sælges
	fish = {
		{ name = "Anchovy",    rarity = "Common",    value = 1 },
		{ name = "Mackerel",   rarity = "Common",    value = 2 },
		{ name = "Cod",        rarity = "Common",    value = 3 },
		{ name = "Salmon",     rarity = "Rare",      value = 6 },
		{ name = "Tuna",       rarity = "Rare",      value = 10 },
		{ name = "Swordfish",  rarity = "Epic",      value = 25 },
		{ name = "Manta Ray",  rarity = "Epic",      value = 35 },
		{ name = "Golden Koi", rarity = "Legendary", value = 120 },
	},
}
