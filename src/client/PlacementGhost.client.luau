-- PlacementGhost.client.luau
-- Visuelt "spøgelse" under placering: en gennemsigtig boks med farvet ramme
-- (som en SelectionBox), der følger musen, mens et fisker/spand-tool er equipped.
-- GRØN = gyldig position, RØD = ugyldig. Reglerne kommer fra PlacementRules
-- (samme modul som serveren bruger), så farven matcher altid virkeligheden.
-- Rører IKKE placeringslogikken -- ren visuel feedback.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local spiller = Players.LocalPlayer
local mus = spiller:GetMouse()
local PlacementRules = require(ReplicatedStorage:WaitForChild("PlacementRules"))

local GROEN = Color3.fromRGB(60, 220, 90)
local ROED = Color3.fromRGB(230, 60, 60)

local ghost = nil      -- selve spøgelse-boksen (nil = intet tool equipped)
local ramme = nil      -- den farvede kant omkring boksen
local loeft = 2        -- hvor højt boksen løftes over klik-punktet

local function fjernGhost()
	if ghost then
		ghost:Destroy()   -- rammen er barn af boksen og ryger med
		ghost = nil
		ramme = nil
	end
	mus.TargetFilter = nil
end

local function visGhost(tool)
	fjernGhost()

	-- Størrelse matcher det, serveren bygger: fisker 4x4x4 (løft 2), spand 6x6x6 (løft 3)
	local stoerrelse
	if tool:GetAttribute("IsBucket") then
		stoerrelse = Vector3.new(6, 6, 6)
		loeft = 3
	else
		stoerrelse = Vector3.new(4, 4, 4)
		loeft = 2
	end

	ghost = Instance.new("Part")
	ghost.Name = "PlacementGhost"
	ghost.Size = stoerrelse
	ghost.Anchored = true
	ghost.CanCollide = false     -- man kan gå igennem det
	ghost.CanQuery = false       -- musen "ser" det ikke (ellers flimrer det)
	ghost.CanTouch = false       -- udløser ikke Touched (tøm/åbn-menuer)
	ghost.Transparency = 0.6     -- gennemsigtigt spøgelse
	ghost.Parent = workspace

	-- Den farvede ramme omkring boksen (stilen fra billedet)
	ramme = Instance.new("SelectionBox")
	ramme.Adornee = ghost
	ramme.LineThickness = 0.08
	ramme.Parent = ghost

	mus.TargetFilter = ghost     -- ekstra sikkerhed: musen ignorerer spøgelset
end

-- Hvert billede (frame): flyt spøgelset til musen og farv grøn/rød
RunService.RenderStepped:Connect(function()
	if not ghost then
		return
	end
	local pos = mus.Hit.Position
	ghost.Position = Vector3.new(pos.X, pos.Y + loeft, pos.Z)

	-- SAMME regel som serveren bruger ved placering
	local farve = PlacementRules.erGyldig(pos) and GROEN or ROED
	ghost.Color = farve
	ramme.Color3 = farve
end)

-- Vis/fjern spøgelset når tools equippes/un-equippes.
-- Et equipped tool ligger i CHARACTER; i backpacken er det ikke equipped.
local function hookCharacter(karakter)
	karakter.ChildAdded:Connect(function(barn)
		if barn:IsA("Tool") and (barn:GetAttribute("FisherIndex") or barn:GetAttribute("IsBucket")) then
			visGhost(barn)
		end
	end)
	karakter.ChildRemoved:Connect(function(barn)
		-- Un-equip ELLER placeret (tool'et destroyes) -> spøgelset væk
		if barn:IsA("Tool") then
			fjernGhost()
		end
	end)
end

if spiller.Character then
	hookCharacter(spiller.Character)
end
spiller.CharacterAdded:Connect(function(karakter)
	fjernGhost()               -- ryd op efter død/respawn
	hookCharacter(karakter)
end)
