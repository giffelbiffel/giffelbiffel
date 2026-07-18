-- DataStore.luau  (en ModuleScript i ServerScriptService)
-- LAV-NIVEAU lag: håndterer KUN selve DataStore-kaldene med pcall + genforsøg.
-- Ved IKKE noget om spillets data -- den får bare en tabel og gemmer/henter den.
-- (Serialisering af spillets tilstand ligger i Maskine.server.luau.)

local DataStoreService = game:GetService("DataStoreService")

-- Skift dette suffiks (fx _v2) for at "nulstille" ALLE spilleres data under udvikling.
local STORE_NAVN = "PlayerData_v1"
local store = DataStoreService:GetDataStore(STORE_NAVN)

local FORSOEG = 4          -- hvor mange gange vi prøver før vi giver op
local PAUSE = 2            -- sekunder mellem forsøg (stiger pr. forsøg)

local M = {}

local function noegle(userId)
	return "Player_" .. userId
end

-- Hent data. Returnerer (ok, data).
--   ok = true, data = tabel   -> data hentet
--   ok = true, data = nil     -> HELT NY spiller (ingen tidligere data)
--   ok = false                -> DataStore FEJLEDE (kald må IKKE tolkes som "ny spiller")
function M.load(userId)
	for forsoeg = 1, FORSOEG do
		local ok, resultat = pcall(function()
			return store:GetAsync(noegle(userId))
		end)
		if ok then
			return true, resultat
		end
		warn("[DataStore] Load-fejl (userId " .. userId .. ", forsøg " .. forsoeg .. "): " .. tostring(resultat))
		task.wait(PAUSE * forsoeg)
	end
	return false, nil
end

-- Gem data. UpdateAsync er atomisk (læs-ret-skriv) og sikrere end SetAsync.
-- Returnerer true hvis det lykkedes.
function M.save(userId, data)
	for forsoeg = 1, FORSOEG do
		local ok, err = pcall(function()
			store:UpdateAsync(noegle(userId), function(_gammel)
				return data
			end)
		end)
		if ok then
			return true
		end
		warn("[DataStore] Save-fejl (userId " .. userId .. ", forsøg " .. forsoeg .. "): " .. tostring(err))
		task.wait(PAUSE * forsoeg)
	end
	return false
end

return M
