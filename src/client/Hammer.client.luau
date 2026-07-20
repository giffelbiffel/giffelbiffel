-- Hammer.client.luau
-- Hammer/fjern-værktøj: klik med hammeren equipped på en placeret fisker/spand for
-- at fjerne den. Viser en RØD preview på det, der KAN fjernes (samme teknik som den
-- grønne placerings-spøgelse, bare omvendt logik + rød farve).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local spiller = Players.LocalPlayer
local mus = spiller:GetMouse()
local FisherConfig = require(ReplicatedStorage:WaitForChild("FisherConfig"))
local removeEvent = ReplicatedStorage:WaitForChild("RemovePlaced")

-- Navne på ting der KAN fjernes: alle fisker-typer + spanden
local fjernbareNavne = { [FisherConfig.bucket.name] = true }
for _, f in FisherConfig.fishers do
	fjernbareNavne[f.name] = true
end

-- Er den ramte del en placeret fisker/spand? (Shop/Sell/Plot matcher ikke -> ingen preview)
local function erFjernbar(part)
	return part ~= nil and part:IsA("BasePart") and fjernbareNavne[part.Name] == true
end

-- === Rød markering (SelectionBox med rød tint) ===
local markering = Instance.new("SelectionBox")
markering.Name = "RemoveHighlight"
markering.Color3 = Color3.fromRGB(230, 60, 60)           -- rød ramme
markering.SurfaceColor3 = Color3.fromRGB(230, 60, 60)    -- rød flade-tint
markering.SurfaceTransparency = 0.7                       -- gennemsigtig
markering.LineThickness = 0.08
markering.Adornee = nil
markering.Parent = workspace.CurrentCamera

local hammerEquipped = false

-- Vis rød preview hvert billede, mens hammeren er equipped og musen peger på noget fjernbart
RunService.RenderStepped:Connect(function()
	if hammerEquipped and erFjernbar(mus.Target) then
		markering.Adornee = mus.Target
	else
		markering.Adornee = nil
	end
end)

-- === Hook hammer-tool'et (Equipped/Unequipped/Activated) ===
local function hookHammer(tool)
	if tool:IsA("Tool") and tool:GetAttribute("IsHammer") then
		tool.Equipped:Connect(function() hammerEquipped = true end)
		tool.Unequipped:Connect(function()
			hammerEquipped = false
			markering.Adornee = nil
		end)
		tool.Activated:Connect(function()
			local ramt = mus.Target
			if erFjernbar(ramt) then
				removeEvent:FireServer(ramt)   -- serveren validerer ejerskab og fjerner
			end
		end)
	end
end

-- Hammeren kommer fra StarterGear -> ny instans i backpacken ved hvert spawn. Hook dem alle.
local function overvaag(container)
	for _, barn in container:GetChildren() do
		hookHammer(barn)
	end
	container.ChildAdded:Connect(hookHammer)
end

overvaag(spiller:WaitForChild("Backpack"))
spiller.ChildAdded:Connect(function(barn)
	if barn:IsA("Backpack") then
		overvaag(barn)   -- ny backpack ved respawn
	end
end)
