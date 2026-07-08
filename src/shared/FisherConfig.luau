-- FisherConfig.luau  (en ModuleScript -- en "delefil")
-- HER bor spillets økonomi-værdier. Ret tallene her for at ændre spillet.
--
-- fishToCoins = hvor mange coins du får for 1 fisk, når du tømmer en fisker.
--               (1 = 1 fisk giver 1 coin. Sæt fx 2 for at gøre fisk dobbelt så meget værd.)
--
-- Hver fisker i "fishers" har:
--   name         = navnet (vises i shoppen) -- SKRIV PÅ ENGELSK
--   price        = hvad den koster i COINS i shoppen
--   fishPerCatch = hvor mange fisk den fanger hver gang
--   catchEvery   = hvor ofte den fanger (i sekunder)
--   capacity     = hvor mange fisk den kan rumme før den er fuld
--   chances      = DENNE fiskers egne odds for sjældenhed (tal = vægt/procent).
--                  Dyrere fiskere kan have bedre odds for sjældne fisk.
--                  Udelader du chances, bruger spillet en fornuftig standard.

return {
	fishToCoins = 1,   -- 1 fisk = 1 coin (juster denne for at ændre hele økonomien)

	-- Spanden (auto-collector): fiskerne sender deres fisk hertil.
	bucket = {
		name = "Bucket",
		price = 300,        -- hvad spanden koster i COINS
		capacity = 1000,    -- hvor mange fisk spanden kan rumme
	},

	fishers = {
		{
			name = "Basic Fisher",
			price = 50,
			fishPerCatch = 1,
			catchEvery = 1.5,
			capacity = 20,
			chances = { Common = 80, Rare = 15, Epic = 4, Legendary = 1 },
		},
		{
			name = "Better Fisher",
			price = 100,
			fishPerCatch = 2,
			catchEvery = 1.5,
			capacity = 50,
			chances = { Basic = 65, Rare = 25, Epic = 8, Legendary = 2 },
		},
		{
			name = "Top Fisher",
			price = 200,
			fishPerCatch = 5,
			catchEvery = 2,
			capacity = 200,
			chances = { Basic = 45, Rare = 30, Epic = 18, Legendary = 7 },
		},
	},
}
