-- PlacementRules.luau  (en ModuleScript -- en "delefil")
-- ÉT fælles sæt placeringsregler, brugt af BÅDE serveren (den rigtige placering)
-- og klienten (spøgelsets grøn/rød farve). Én sandhed, ét sted -- så kan
-- spøgelset og serveren aldrig være uenige.

local PlacementRules = {}

-- Er denne position gyldig at placere på?
-- Reglen (for nu): punktet skal ligge PÅ plottet (inden for den grønne plade).
-- Nye regler tilføjes HER -- så følger både spøgelse og server automatisk med.
function PlacementRules.erGyldig(position)
	local plot = workspace:FindFirstChild("Plot")
	if not plot then
		return false
	end

	local dx = math.abs(position.X - plot.Position.X)   -- afstand fra plottets midte
	local dz = math.abs(position.Z - plot.Position.Z)
	return dx <= plot.Size.X / 2 and dz <= plot.Size.Z / 2
end

return PlacementRules
