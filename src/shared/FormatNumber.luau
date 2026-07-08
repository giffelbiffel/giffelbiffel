-- FormatNumber.luau  (en ModuleScript -- en "delefil")
-- Forkorter store tal til visning: 850 -> "850", 1500 -> "1.5K",
-- 45000 -> "45K", 5000000 -> "5M", 1200000000 -> "1.2B".
-- Bruges ALLE steder tal vises. Ændrer ALDRIG selve tallene -- kun teksten.

local TRIN = {
	{ 1e9, "B" },   -- milliarder
	{ 1e6, "M" },   -- millioner
	{ 1e3, "K" },   -- tusinder
}

local function formatNumber(n)
	n = math.floor(n)

	for _, trin in TRIN do
		local graense, bogstav = trin[1], trin[2]
		if n >= graense then
			-- Én decimal, skåret af (ikke rundet op), så vi aldrig viser for meget
			local vaerdi = math.floor(n / graense * 10) / 10
			if vaerdi == math.floor(vaerdi) then
				return math.floor(vaerdi) .. bogstav      -- "5M", ikke "5.0M"
			end
			return string.format("%.1f", vaerdi) .. bogstav   -- "1.5K"
		end
	end

	return tostring(n)   -- under 1000: vis som det er
end

return formatNumber
