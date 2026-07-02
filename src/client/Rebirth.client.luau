-- Rebirth.client.luau
-- Rebirth-menu (åbnes ved REBIRTH-stedet) + en fast HUD-linje med rebirths/multiplier.
-- Rører ikke de andre systemer -- lægger sig kun ovenpå.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local spiller = Players.LocalPlayer

local rebirthEvent = ReplicatedStorage:WaitForChild("Rebirth")

local senesteStatus = nil   -- den seneste status serveren sendte

-- Lille hjælper: skriv store tal pænt, fx 5000000 -> "5,000,000"
local function formatTal(n)
	local s = tostring(math.floor(n))
	local ud = ""
	local count = 0
	for i = #s, 1, -1 do
		ud = s:sub(i, i) .. ud
		count += 1
		if count % 3 == 0 and i > 1 then
			ud = "," .. ud
		end
	end
	return ud
end

-- === Skærm-lag ===
local skaerm = Instance.new("ScreenGui")
skaerm.Name = "RebirthUI"
skaerm.ResetOnSpawn = false
skaerm.Parent = spiller:WaitForChild("PlayerGui")

-- --- Fast HUD-linje (altid synlig, under coins-boksen) ---
local hud = Instance.new("TextLabel")
hud.Size = UDim2.new(0, 220, 0, 30)
hud.Position = UDim2.new(0, 20, 0, 110)
hud.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
hud.BackgroundTransparency = 0.3
hud.TextColor3 = Color3.fromRGB(255, 220, 120)
hud.Font = Enum.Font.GothamBold
hud.TextScaled = true
hud.Parent = skaerm
Instance.new("UICorner").Parent = hud

local function opdaterHud()
	local rebirths = spiller:GetAttribute("Rebirths") or 0
	local mult = spiller:GetAttribute("Multiplier") or 1
	hud.Text = "Rebirths: " .. rebirths .. "   Mult: " .. mult .. "x"
end
opdaterHud()
spiller:GetAttributeChangedSignal("Rebirths"):Connect(opdaterHud)
spiller:GetAttributeChangedSignal("Multiplier"):Connect(opdaterHud)

-- --- Selve menuen (skjult fra start) ---
local vindue = Instance.new("Frame")
vindue.AnchorPoint = Vector2.new(0.5, 0.5)
vindue.Position = UDim2.new(0.5, 0, 0.5, 0)
vindue.Size = UDim2.new(0, 360, 0, 300)
vindue.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
vindue.Visible = false
vindue.Parent = skaerm
Instance.new("UICorner").Parent = vindue

local titel = Instance.new("TextLabel")
titel.Size = UDim2.new(1, -20, 0, 36)
titel.Position = UDim2.new(0, 10, 0, 8)
titel.BackgroundTransparency = 1
titel.Text = "REBIRTH"
titel.TextColor3 = Color3.fromRGB(255, 255, 255)
titel.Font = Enum.Font.GothamBold
titel.TextScaled = true
titel.Parent = vindue

-- Info-tekst (flere linjer)
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -24, 0, 170)
info.Position = UDim2.new(0, 12, 0, 50)
info.BackgroundTransparency = 1
info.TextColor3 = Color3.fromRGB(230, 230, 235)
info.Font = Enum.Font.Gotham
info.TextSize = 18
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.TextWrapped = true
info.Text = ""
info.Parent = vindue

-- Rebirth-knap (grøn når man kan, ellers rød)
local rebirthKnap = Instance.new("TextButton")
rebirthKnap.Size = UDim2.new(0, 170, 0, 40)
rebirthKnap.Position = UDim2.new(0, 12, 1, -50)
rebirthKnap.Text = "Rebirth"
rebirthKnap.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthKnap.Font = Enum.Font.GothamBold
rebirthKnap.TextScaled = true
rebirthKnap.Parent = vindue
Instance.new("UICorner").Parent = rebirthKnap

local lukKnap = Instance.new("TextButton")
lukKnap.Size = UDim2.new(0, 150, 0, 40)
lukKnap.Position = UDim2.new(1, -162, 1, -50)
lukKnap.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
lukKnap.Text = "Close"
lukKnap.TextColor3 = Color3.fromRGB(255, 255, 255)
lukKnap.Font = Enum.Font.GothamBold
lukKnap.TextScaled = true
lukKnap.Parent = vindue
Instance.new("UICorner").Parent = lukKnap


-- === Tegn menuen ud fra seneste status + mine nuværende coins ===
local kanRebirthe = false

local function tegnMenu()
	local s = senesteStatus
	if not s then return end

	if s.isMax then
		info.Text = "Rebirths: " .. s.rebirths
			.. "\nCurrent multiplier: " .. s.currentMultiplier .. "x"
			.. "\n\nMAX REBIRTH REACHED"
		kanRebirthe = false
		rebirthKnap.Text = "Maxed"
		rebirthKnap.BackgroundColor3 = Color3.fromRGB(90, 90, 95)
		return
	end

	local coins = spiller:GetAttribute("Coins") or 0
	local coinsOK = coins >= s.requiredCoins

	-- liste af krævede fiskere (eller "none")
	local fiskereTekst = "none"
	if #s.requiredFishers > 0 then
		fiskereTekst = table.concat(s.requiredFishers, ", ")
	end

	info.Text = "Rebirths: " .. s.rebirths
		.. "\nCurrent multiplier: " .. s.currentMultiplier .. "x"
		.. "\n\nNext (Level " .. s.levelNumber .. "):"
		.. "\n  Coins: " .. formatTal(coins) .. " / " .. formatTal(s.requiredCoins)
			.. (coinsOK and "  OK" or "  X")
		.. "\n  Fishers: " .. fiskereTekst
			.. (s.ownsAllFishers and "  OK" or "  X")
		.. "\n  New multiplier: " .. s.nextMultiplier .. "x"

	kanRebirthe = coinsOK and s.ownsAllFishers
	if kanRebirthe then
		rebirthKnap.Text = "Rebirth"
		rebirthKnap.BackgroundColor3 = Color3.fromRGB(60, 200, 90)    -- grøn
	else
		rebirthKnap.Text = "Not ready"
		rebirthKnap.BackgroundColor3 = Color3.fromRGB(200, 70, 70)    -- rød
	end
end

-- Coins ændrer sig ofte (salg) -> opdatér knappen live mens menuen er åben
spiller:GetAttributeChangedSignal("Coins"):Connect(function()
	if vindue.Visible then
		tegnMenu()
	end
end)


-- === Åbn menuen ved REBIRTH-stedet ===
local pad = workspace:WaitForChild("RebirthPad")
pad.Touched:Connect(function(andetObjekt)
	if andetObjekt.Parent == spiller.Character and not vindue.Visible then
		rebirthEvent:FireServer("status")   -- bed om frisk status
		vindue.Visible = true
	end
end)

-- Serveren sender status (ved åbning OG efter en rebirth)
rebirthEvent.OnClientEvent:Connect(function(status)
	senesteStatus = status
	tegnMenu()
end)

rebirthKnap.MouseButton1Click:Connect(function()
	if kanRebirthe then
		rebirthEvent:FireServer("do")   -- serveren tjekker kravene igen og udfører
	end
end)

lukKnap.MouseButton1Click:Connect(function()
	vindue.Visible = false
end)
