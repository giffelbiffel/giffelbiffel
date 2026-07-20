-- Rebirth.client.luau
-- Rebirth-menu åbnet fra en PERMANENT skærm-knap (ikke længere en fysisk kasse).
-- Rører ikke rebirth-logikken -- kun HVORDAN menuen åbnes/ses.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local spiller = Players.LocalPlayer

local rebirthEvent = ReplicatedStorage:WaitForChild("Rebirth")

local senesteStatus = nil   -- den seneste status serveren sendte

-- Fælles tal-formatering (5000000 -> "5M")
local FormatNumber = require(ReplicatedStorage:WaitForChild("FormatNumber"))
local AnimerKnap = require(ReplicatedStorage:WaitForChild("ButtonAnimation"))
local RebirthConfig = require(ReplicatedStorage:WaitForChild("RebirthConfig"))
local Responsive = require(ReplicatedStorage:WaitForChild("Responsive"))

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
Responsive(hud)   -- skalér rebirth-HUD-linjen på små skærme
Instance.new("UICorner").Parent = hud

local function opdaterHud()
	local rebirths = spiller:GetAttribute("Rebirths") or 0
	local mult = spiller:GetAttribute("Multiplier") or 1
	hud.Text = "Rebirths: " .. rebirths .. "   Mult: " .. mult .. "x"
end
opdaterHud()
spiller:GetAttributeChangedSignal("Rebirths"):Connect(opdaterHud)
spiller:GetAttributeChangedSignal("Multiplier"):Connect(opdaterHud)

-- --- Permanent ÅBN-knap i hjørnet (altid synlig) ---
local aabnKnap = Instance.new("TextButton")
aabnKnap.Name = "OpenRebirth"
aabnKnap.AnchorPoint = Vector2.new(0, 1)
aabnKnap.Position = UDim2.new(0, 20, 1, -20)      -- nederste venstre hjørne
aabnKnap.Size = UDim2.new(0, 150, 0, 44)
aabnKnap.BackgroundColor3 = Color3.fromRGB(70, 70, 78)
aabnKnap.Text = "REBIRTH"
aabnKnap.TextColor3 = Color3.fromRGB(255, 255, 255)
aabnKnap.Font = Enum.Font.GothamBold
aabnKnap.TextScaled = true
aabnKnap.Parent = skaerm
Instance.new("UICorner").Parent = aabnKnap
AnimerKnap(aabnKnap)

-- --- Progress-bar LIGE OVER rebirth-knappen (altid synlig) ---
local barBoks = Instance.new("Frame")
barBoks.AnchorPoint = Vector2.new(0, 1)
barBoks.Position = UDim2.new(0, 20, 1, -70)       -- 6 px over REBIRTH-knappen
barBoks.Size = UDim2.new(0, 150, 0, 40)
barBoks.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
barBoks.BackgroundTransparency = 0.3
barBoks.Parent = skaerm
Instance.new("UICorner").Parent = barBoks
Responsive(barBoks)   -- skalér progress-baren på små skærme

local barTekst = Instance.new("TextLabel")         -- "3.2M / 5M"
barTekst.Size = UDim2.new(1, -8, 0, 18)
barTekst.Position = UDim2.new(0, 4, 0, 2)
barTekst.BackgroundTransparency = 1
barTekst.Font = Enum.Font.GothamBold
barTekst.TextScaled = true
barTekst.TextColor3 = Color3.fromRGB(255, 255, 255)
barTekst.Parent = barBoks

local barBund = Instance.new("Frame")              -- den grå bund-bar
barBund.Position = UDim2.new(0, 4, 0, 24)
barBund.Size = UDim2.new(1, -8, 0, 10)
barBund.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
barBund.Parent = barBoks
Instance.new("UICorner").Parent = barBund

local barFyld = Instance.new("Frame")              -- den grønne fyld-del
barFyld.Size = UDim2.new(0, 0, 1, 0)               -- bredde sættes af opdaterBar
barFyld.BackgroundColor3 = Color3.fromRGB(60, 220, 90)
barFyld.Parent = barBund
Instance.new("UICorner").Parent = barFyld

-- Lille ✓/✗-status for fisker-kravet (ja/nej -- ikke en gradvis bar)
local fiskerIkon = Instance.new("TextLabel")
fiskerIkon.AnchorPoint = Vector2.new(0, 1)
fiskerIkon.Position = UDim2.new(0, 176, 1, -70)    -- til højre for baren
fiskerIkon.Size = UDim2.new(0, 40, 0, 40)
fiskerIkon.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
fiskerIkon.BackgroundTransparency = 0.3
fiskerIkon.Font = Enum.Font.GothamBold
fiskerIkon.TextScaled = true
fiskerIkon.Visible = false
fiskerIkon.Parent = skaerm
Instance.new("UICorner").Parent = fiskerIkon
Responsive(fiskerIkon)   -- skalér fisker-krav-ikonet på små skærme

local ejerAlleFiskereNu = false    -- opdateres fra serverens status

local function opdaterBar()
	local rebirths = spiller:GetAttribute("Rebirths") or 0
	local niveau = RebirthConfig[rebirths + 1]     -- næste niveau (samme config som serveren)

	if not niveau then                             -- max rebirth nået
		barTekst.Text = "MAX"
		barFyld.Size = UDim2.new(1, 0, 1, 0)
		fiskerIkon.Visible = false
		return
	end

	local coins = spiller:GetAttribute("Coins") or 0
	local andel = math.min(coins / niveau.requiredCoins, 1)   -- cap ved 100%
	barFyld.Size = UDim2.new(andel, 0, 1, 0)
	barTekst.Text = FormatNumber(coins) .. " / " .. FormatNumber(niveau.requiredCoins)

	if #niveau.requiredFishers > 0 then            -- kun hvis niveauet HAR et fisker-krav
		fiskerIkon.Visible = true
		if ejerAlleFiskereNu then
			fiskerIkon.Text = "OK"
			fiskerIkon.TextColor3 = Color3.fromRGB(60, 220, 90)   -- grøn: ejer alle
		else
			fiskerIkon.Text = "X"
			fiskerIkon.TextColor3 = Color3.fromRGB(230, 60, 60)   -- rød: mangler nogen
		end
	else
		fiskerIkon.Visible = false
	end
end

opdaterBar()
spiller:GetAttributeChangedSignal("Coins"):Connect(opdaterBar)      -- live mens man spiller
spiller:GetAttributeChangedSignal("Rebirths"):Connect(opdaterBar)   -- nyt niveau = nyt krav

-- --- Baggrund bag menuen (klik udenfor for at lukke) ---
local baggrund = Instance.new("TextButton")
baggrund.Name = "Backdrop"
baggrund.Size = UDim2.new(1, 0, 1, 0)
baggrund.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
baggrund.BackgroundTransparency = 0.5
baggrund.Text = ""
baggrund.AutoButtonColor = false
baggrund.Visible = false
baggrund.Parent = skaerm

-- --- Selve menu-vinduet (oven på baggrunden) ---
local vindue = Instance.new("Frame")
vindue.AnchorPoint = Vector2.new(0.5, 0.5)
vindue.Position = UDim2.new(0.5, 0, 0.5, 0)
vindue.Size = UDim2.new(0, 360, 0, 300)
vindue.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
vindue.Visible = false
vindue.Parent = skaerm
Instance.new("UICorner").Parent = vindue
Responsive(vindue)   -- skalér hele rebirth-menuen på små skærme

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
AnimerKnap(rebirthKnap)

-- X/Luk-knap
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
AnimerKnap(lukKnap)


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

	local fiskereTekst = "none"
	if #s.requiredFishers > 0 then
		fiskereTekst = table.concat(s.requiredFishers, ", ")
	end

	info.Text = "Rebirths: " .. s.rebirths
		.. "\nCurrent multiplier: " .. s.currentMultiplier .. "x"
		.. "\n\nNext (Level " .. s.levelNumber .. "):"
		.. "\n  Coins: " .. FormatNumber(coins) .. " / " .. FormatNumber(s.requiredCoins)
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

-- Åbn/luk menuen
local function saetMenu(aaben)
	baggrund.Visible = aaben
	vindue.Visible = aaben
	if aaben then
		rebirthEvent:FireServer("status")   -- bed om frisk status hver gang den åbnes
	end
end

-- Coins ændrer sig ofte (salg) -> opdatér knappen live mens menuen er åben
spiller:GetAttributeChangedSignal("Coins"):Connect(function()
	if vindue.Visible then
		tegnMenu()
	end
end)


-- === Knapper ===
aabnKnap.MouseButton1Click:Connect(function()
	saetMenu(true)
end)

baggrund.MouseButton1Click:Connect(function()
	saetMenu(false)   -- klik udenfor lukker
end)

lukKnap.MouseButton1Click:Connect(function()
	saetMenu(false)
end)

rebirthKnap.MouseButton1Click:Connect(function()
	if kanRebirthe then
		rebirthEvent:FireServer("do")   -- serveren tjekker kravene igen og udfører
	end
end)

-- Serveren sender status (ved åbning, efter en rebirth og efter fisker-køb)
rebirthEvent.OnClientEvent:Connect(function(status)
	senesteStatus = status
	ejerAlleFiskereNu = status.isMax or status.ownsAllFishers   -- til barens ✓/✗
	tegnMenu()
	opdaterBar()
end)

-- Bed om status med det samme, så barens ✓/✗ er korrekt fra start
rebirthEvent:FireServer("status")
