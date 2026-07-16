-- ButtonAnimation.luau  (en ModuleScript -- en "delefil")
-- Genbrugelig knap-feedback, som ALLE knapper allerede bruger:
--   HOVER = musen er over  -> knappen bliver lidt større (105%)
--   KLIK  = der blev trykket -> hurtigt "squish" (ned og op igen)
-- De to er ADSKILTE effekter, men deler ÉN UIScale, så de spiller sammen
-- (Roblox respekterer kun én UIScale pr. knap -- derfor samme scale til begge).
--
-- Brug i enhver menu (uændret fra før):
--   local AnimerKnap = require(ReplicatedStorage:WaitForChild("ButtonAnimation"))
--   AnimerKnap(minKnap)

local TweenService = game:GetService("TweenService")

-- === STIL (nem at ændre her) ===
local STIL = {
	hoverSkala = 1.05,   -- hvor stor knappen bliver, når musen holdes over
	klikSkala = 0.92,    -- squish ved klik (ganges på den nuværende størrelse)
	hoverTid = 0.12,     -- overgang ind/ud af hover
	klikNedTid = 0.06,   -- squish ned...
	klikOpTid = 0.09,    -- ...og tilbage op igen
}

local function tween(scale, maal, tid, style)
	local t = TweenService:Create(scale,
		TweenInfo.new(tid, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Scale = maal })
	t:Play()
	return t
end

local function animerKnap(knap)
	local scale = Instance.new("UIScale")
	scale.Parent = knap

	local hovered = false   -- er musen over lige nu?

	-- HOVER: musen ind -> lidt større, musen ud -> normal
	knap.MouseEnter:Connect(function()
		hovered = true
		tween(scale, STIL.hoverSkala, STIL.hoverTid)
	end)
	knap.MouseLeave:Connect(function()
		hovered = false
		tween(scale, 1, STIL.hoverTid)
	end)

	-- KLIK: hurtig squish, og tilbage til den TILSTAND musen er i bagefter
	knap.MouseButton1Down:Connect(function()
		local base = hovered and STIL.hoverSkala or 1
		local ned = tween(scale, base * STIL.klikSkala, STIL.klikNedTid)
		ned.Completed:Once(function()
			local retur = hovered and STIL.hoverSkala or 1   -- måske forlod musen mens vi klikkede
			tween(scale, retur, STIL.klikOpTid, Enum.EasingStyle.Back)
		end)
	end)
end

return animerKnap
