-- Responsive.luau  (en ModuleScript -- en "delefil")
-- Gør et UI-panel responsivt: lægger en UIScale på det og skalerer efter
-- skærmstørrelsen. Skalaen er ALDRIG over 1.0 -> på desktop ser alt præcis
-- ud som før; på mindre skærme (mobil/tablet) skrumper panelet proportionalt,
-- så det ikke klipper af skærmen. Rører ingen logik -- kun størrelse.
--
-- Brug:  local Responsive = require(ReplicatedStorage:WaitForChild("Responsive"))
--        Responsive(mitPanel)

-- Reference-skærm: ved denne størrelse (og større) er skalaen 1.0 = uændret desktop.
local REFERENCE = Vector2.new(1000, 700)
local GULV = 0.4   -- gå aldrig mindre end 40% (så tekst/knapper ikke bliver ulæselige)

local function apply(element)
	local camera = workspace.CurrentCamera
	if not camera then return end

	-- Genbrug ikke en eksisterende UIScale (fx knap-animationens) -- lav vores egen.
	local scale = element:FindFirstChild("ResponsiveScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "ResponsiveScale"
		scale.Parent = element
	end

	local function opdater()
		local vp = camera.ViewportSize
		if vp.X < 1 or vp.Y < 1 then return end
		-- Tag den mindste af bredde-/højde-forholdet, så panelet passer i BEGGE retninger
		local s = math.min(vp.X / REFERENCE.X, vp.Y / REFERENCE.Y, 1)
		scale.Scale = math.max(s, GULV)
	end

	opdater()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(opdater)
end

return apply
