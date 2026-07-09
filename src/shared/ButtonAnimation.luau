-- ButtonAnimation.luau  (en ModuleScript -- en "delefil")
-- Genbrugelig knap-tryk-animation: et hurtigt "squish" (kort ned i størrelse
-- og tilbage igen) ved hvert klik. Ren visuel feedback -- den kører UANSET
-- om handlingen bag knappen lykkes eller fejler.
--
-- Brug i enhver menu:
--   local AnimerKnap = require(ReplicatedStorage:WaitForChild("ButtonAnimation"))
--   AnimerKnap(minKnap)   -- så er knappen koblet på

local TweenService = game:GetService("TweenService")

-- === STIL (nem at ændre her) ===
local STIL = {
	skala = 0.92,     -- hvor lille knappen bliver (92% af normal størrelse)
	tidNed = 0.06,    -- sekunder ned...
	tidOp = 0.09,     -- ...og tilbage op (i alt ~0.15 sek)
}

local function animerKnap(knap)
	-- En UIScale skalerer knappen visuelt uden at ændre dens rigtige størrelse
	local scale = Instance.new("UIScale")
	scale.Parent = knap

	knap.MouseButton1Down:Connect(function()   -- Down = reagerer i samme øjeblik man trykker
		local ned = TweenService:Create(scale,
			TweenInfo.new(STIL.tidNed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Scale = STIL.skala })
		local op = TweenService:Create(scale,
			TweenInfo.new(STIL.tidOp, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 })
		ned:Play()
		ned.Completed:Once(function()
			op:Play()                            -- lille "Back"-easing = blødt hop tilbage
		end)
	end)
end

return animerKnap
