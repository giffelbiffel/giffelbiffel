-- RebirthConfig.luau  (en ModuleScript -- en "delefil")
-- HER bor rebirth-niveauerne. Ret frit: tilføj niveauer, ændr krav og multiplier.
--
-- Niveau 1 er den FØRSTE rebirth (fra 0 rebirths). Niveau 2 er den næste, osv.
-- Hvert niveau har:
--   requiredCoins   = hvor mange coins du skal have for at kunne rebirthe hertil
--   multiplier      = din nye TOTALE salgsmultiplier efter dette niveau
--                     (ikke lagt oveni -- den ERSTATTER den gamle)
--   requiredFishers = liste af fisker-navne du skal EJE for at kunne rebirthe hertil
--                     (tom {} = intet fisker-krav). Navnene skal matche FisherConfig.

return {
	{
		requiredCoins = 5000000,        -- 5.000.000
		multiplier = 2.5,
		requiredFishers = {},
	},
	{
		requiredCoins = 50000000,       -- 50.000.000
		multiplier = 5,
		requiredFishers = { "Top Fisher" },
	},
	{
		requiredCoins = 500000000,      -- 500.000.000
		multiplier = 10,
		requiredFishers = { "Top Fisher", "Better Fisher" },
	},
}
