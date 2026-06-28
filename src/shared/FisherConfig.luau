-- FisherConfig.luau  (en ModuleScript -- en "delefil")
-- HER bor alle fiskernes værdier. Ret tallene her for at ændre spillet.
-- Tilføj en ny fisker ved at kopiere en blok og rette den. Resten sker automatisk.
--
-- Hver fisker har:
--   name         = navnet (vises i shoppen) -- SKRIV PÅ ENGELSK
--   price        = hvad den koster i fisk
--   fishPerCatch = hvor mange fisk den fanger hver gang
--   catchEvery   = hvor ofte den fanger (i sekunder)
--   capacity     = hvor mange fisk den kan rumme før den er fuld

return {
	{
		name = "Basic Fisher",
		price = 50,
		fishPerCatch = 1,
		catchEvery = 3,
		capacity = 50,
	},
	{
		name = "Better Fisher",
		price = 100,
		fishPerCatch = 1,
		catchEvery = 2,
		capacity = 100,
	},
	{
		name = "Top Fisher",
		price = 200,
		fishPerCatch = 1,
		catchEvery = 1,
		capacity = 200,
	},
}
