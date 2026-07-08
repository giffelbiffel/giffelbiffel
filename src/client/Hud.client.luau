-- Hud.client.luau
-- Fase 5: Vis MIN samlede fisk i hjørnet af skærmen. Opdateres live.
-- Dette er et CLIENT-script: det kører på min egen skærm, ikke på serveren.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local spiller = Players.LocalPlayer            -- "mig" på min egen skærm
local FormatNumber = require(ReplicatedStorage:WaitForChild("FormatNumber"))

-- 1. Lav selve skærm-laget, som teksten skal ligge på
local skaerm = Instance.new("ScreenGui")
skaerm.Name = "FiskHud"
skaerm.ResetOnSpawn = false                    -- Forsvinder ikke, når jeg dør/respawner
skaerm.Parent = spiller:WaitForChild("PlayerGui")  -- PlayerGui = min personlige skærm

-- 2. Lav en pæn boks i hjørnet
local boks = Instance.new("TextLabel")
boks.Size = UDim2.new(0, 220, 0, 80)           -- 220 bred, 80 høj (plads til to linjer)
boks.Position = UDim2.new(0, 20, 0, 20)        -- 20 fra venstre, 20 fra toppen
boks.BackgroundColor3 = Color3.fromRGB(20, 30, 50)  -- mørkeblå baggrund
boks.BackgroundTransparency = 0.3              -- en anelse gennemsigtig
boks.TextColor3 = Color3.fromRGB(255, 255, 255)     -- hvid skrift
boks.Font = Enum.Font.GothamBold
boks.TextScaled = true
boks.Parent = skaerm

-- Runde hjørner, så boksen ser pæn ud
local hjoerne = Instance.new("UICorner")
hjoerne.CornerRadius = UDim.new(0, 12)
hjoerne.Parent = boks

-- 3. Opskrift: skriv mine coins og fisk i boksen (to linjer)
local function opdaterHud()
	local coins = spiller:GetAttribute("Coins") or 0   -- min valuta
	local fisk = spiller:GetAttribute("Fisk") or 0     -- fisk fanget i alt
	boks.Text = "Coins: " .. FormatNumber(coins) .. "\nFish: " .. FormatNumber(fisk)   -- \n = ny linje
end

opdaterHud()                                   -- Vis det med det samme

-- 4. Kør opskriften igen, hver gang Coins ELLER Fisk ændrer sig
spiller:GetAttributeChangedSignal("Coins"):Connect(opdaterHud)
spiller:GetAttributeChangedSignal("Fisk"):Connect(opdaterHud)
