-- SettingsMenu.client.luau
-- Settings + stats-menu, åbnes med en fast skærm-knap (tandhjul-placeholder).
-- Viser livstids-stats fra serveren og en musik-toggle (klar til musik senere).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local spiller = Players.LocalPlayer
local FormatNumber = require(ReplicatedStorage:WaitForChild("FormatNumber"))
local AnimerKnap = require(ReplicatedStorage:WaitForChild("ButtonAnimation"))
local FishConfig = require(ReplicatedStorage:WaitForChild("FishConfig"))
local statsEvent = ReplicatedStorage:WaitForChild("Stats")

local musikTil = true   -- musik-tilstand (gemmes også på serveren)

-- Spilletid som pæn tekst: 4530 sek -> "1h 15m 30s"
local function formatTid(sek)
	local t = math.floor(sek)
	local timer = math.floor(t / 3600)
	local minutter = math.floor((t % 3600) / 60)
	local sekunder = t % 60
	if timer > 0 then
		return timer .. "h " .. minutter .. "m " .. sekunder .. "s"
	elseif minutter > 0 then
		return minutter .. "m " .. sekunder .. "s"
	end
	return sekunder .. "s"
end

-- === Skærm-lag ===
local skaerm = Instance.new("ScreenGui")
skaerm.Name = "SettingsMenu"
skaerm.ResetOnSpawn = false
skaerm.Parent = spiller:WaitForChild("PlayerGui")

-- Fast åbn-knap i øverste højre hjørne (tandhjuls-placeholder)
local aabnKnap = Instance.new("TextButton")
aabnKnap.AnchorPoint = Vector2.new(1, 0)
aabnKnap.Position = UDim2.new(1, -20, 0, 20)
aabnKnap.Size = UDim2.new(0, 120, 0, 44)
aabnKnap.BackgroundColor3 = Color3.fromRGB(70, 70, 78)
aabnKnap.Text = "Settings"
aabnKnap.TextColor3 = Color3.fromRGB(255, 255, 255)
aabnKnap.Font = Enum.Font.GothamBold
aabnKnap.TextScaled = true
aabnKnap.Parent = skaerm
Instance.new("UICorner").Parent = aabnKnap
AnimerKnap(aabnKnap)

-- Menu-vinduet (skjult fra start)
local vindue = Instance.new("Frame")
vindue.AnchorPoint = Vector2.new(0.5, 0.5)
vindue.Position = UDim2.new(0.5, 0, 0.5, 0)
vindue.Size = UDim2.new(0, 340, 0, 0)
vindue.AutomaticSize = Enum.AutomaticSize.Y
vindue.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
vindue.Visible = false
vindue.Parent = skaerm
Instance.new("UICorner").Parent = vindue

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = vindue

local polstring = Instance.new("UIPadding")
polstring.PaddingTop = UDim.new(0, 12)
polstring.PaddingBottom = UDim.new(0, 12)
polstring.Parent = vindue

local titel = Instance.new("TextLabel")
titel.LayoutOrder = 0
titel.Size = UDim2.new(0, 300, 0, 34)
titel.BackgroundTransparency = 1
titel.Text = "SETTINGS"
titel.TextColor3 = Color3.fromRGB(255, 255, 255)
titel.Font = Enum.Font.GothamBold
titel.TextScaled = true
titel.Parent = vindue

-- Musik-toggle
local musikKnap = Instance.new("TextButton")
musikKnap.LayoutOrder = 1
musikKnap.Size = UDim2.new(0, 300, 0, 40)
musikKnap.TextColor3 = Color3.fromRGB(255, 255, 255)
musikKnap.Font = Enum.Font.GothamBold
musikKnap.TextScaled = true
musikKnap.Parent = vindue
Instance.new("UICorner").Parent = musikKnap
AnimerKnap(musikKnap)

local function opdaterMusikKnap()
	if musikTil then
		musikKnap.Text = "Music: ON"
		musikKnap.BackgroundColor3 = Color3.fromRGB(60, 200, 90)
	else
		musikKnap.Text = "Music: OFF"
		musikKnap.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
	end
	-- Klar til senere: findes der baggrundsmusik, styrer toggle'en den.
	local musik = SoundService:FindFirstChild("BackgroundMusic")
	if musik and musik:IsA("Sound") then
		musik.Playing = musikTil
	end
end
opdaterMusikKnap()

musikKnap.MouseButton1Click:Connect(function()
	musikTil = not musikTil
	opdaterMusikKnap()
	statsEvent:FireServer("music", musikTil)   -- gem tilstanden på serveren
end)

-- Stats-overskrift
local statsTitel = Instance.new("TextLabel")
statsTitel.LayoutOrder = 2
statsTitel.Size = UDim2.new(0, 300, 0, 30)
statsTitel.BackgroundTransparency = 1
statsTitel.Text = "STATS"
statsTitel.TextColor3 = Color3.fromRGB(255, 255, 255)
statsTitel.Font = Enum.Font.GothamBold
statsTitel.TextScaled = true
statsTitel.Parent = vindue

-- Luk-knap (nederst via LayoutOrder)
local lukKnap = Instance.new("TextButton")
lukKnap.LayoutOrder = 999
lukKnap.Size = UDim2.new(0, 300, 0, 40)
lukKnap.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
lukKnap.Text = "Close"
lukKnap.TextColor3 = Color3.fromRGB(255, 255, 255)
lukKnap.Font = Enum.Font.GothamBold
lukKnap.TextScaled = true
lukKnap.Parent = vindue
Instance.new("UICorner").Parent = lukKnap
AnimerKnap(lukKnap)

-- === Tegn stats-linjerne ud fra serverens tal ===
local function lavLinje(orden, tekst, farve)
	local linje = Instance.new("TextLabel")
	linje.Name = "StatLinje"
	linje.LayoutOrder = orden
	linje.Size = UDim2.new(0, 300, 0, 24)
	linje.BackgroundTransparency = 1
	linje.Font = Enum.Font.Gotham
	linje.TextScaled = true
	linje.TextXAlignment = Enum.TextXAlignment.Left
	linje.TextColor3 = farve or Color3.fromRGB(230, 230, 235)
	linje.Text = tekst
	linje.Parent = vindue
end

local function visStats(stats)
	for _, barn in vindue:GetChildren() do
		if barn.Name == "StatLinje" then
			barn:Destroy()
		end
	end

	local rebirths = spiller:GetAttribute("Rebirths") or 0

	lavLinje(10, "Coins earned (ever): " .. FormatNumber(stats.coinsEarned))
	lavLinje(11, "Fish caught (ever): " .. FormatNumber(stats.fishCaught))
	lavLinje(12, "Rebirths: " .. rebirths)
	lavLinje(13, "Playtime: " .. formatTid(stats.playSeconds))

	-- Fangster per sjældenhed (livstid), i config'ens rækkefølge og farver
	for i, rarity in FishConfig.rarityOrder do
		local antal = stats.byRarity[rarity] or 0
		lavLinje(20 + i, rarity .. ": " .. FormatNumber(antal), FishConfig.colors[rarity])
	end
end

-- Serveren sender stats -> tegn dem (og synk musik-tilstanden første gang)
statsEvent.OnClientEvent:Connect(function(stats)
	if stats.musikTil ~= nil and stats.musikTil ~= musikTil then
		musikTil = stats.musikTil
		opdaterMusikKnap()
	end
	visStats(stats)
end)

-- Åbn/luk
aabnKnap.MouseButton1Click:Connect(function()
	vindue.Visible = not vindue.Visible
	if vindue.Visible then
		statsEvent:FireServer("get")     -- friske tal ved åbning
	end
end)

lukKnap.MouseButton1Click:Connect(function()
	vindue.Visible = false
end)

-- Genopfrisk tallene hvert 2. sekund, mens menuen er åben (så spilletiden tikker)
task.spawn(function()
	while true do
		task.wait(2)
		if vindue.Visible then
			statsEvent:FireServer("get")
		end
	end
end)
