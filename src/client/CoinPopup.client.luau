-- CoinPopup.client.luau
-- Flyvende "+X" popups når man sælger fisk. Ren visuel effekt -- rører ingen logik.
-- Ved "Sell All" deles beløbet i 2-3 popups, der TILSAMMEN giver det rigtige beløb.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local spiller = Players.LocalPlayer
local FormatNumber = require(ReplicatedStorage:WaitForChild("FormatNumber"))
local sellPopup = ReplicatedStorage:WaitForChild("SellPopup")

-- === STIL (nem at ændre her) ===
local STIL = {
	farve = Color3.fromRGB(90, 230, 120),   -- grøn tekst
	varighed = 1.25,                         -- sekunder (forlænget fra 1)
	loeft = 60,                              -- pixels den flyver opad
	tekstHoejde = 34,                        -- skriftstørrelse
	-- Spawn-OMRÅDE (tilfældig placering i denne firkant, nær HUD'en):
	xMin = 240, xMax = 430,
	yMin = 30,  yMax = 160,
	forsinkelse = 0.12,                      -- sekunder mellem popups ved Sell All
}

local skaerm = Instance.new("ScreenGui")
skaerm.Name = "CoinPopup"
skaerm.ResetOnSpawn = false
skaerm.Parent = spiller:WaitForChild("PlayerGui")

-- Lav ÉN popup med et beløb, på et tilfældigt sted i området
local function lavPopup(beloeb)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = STIL.tekstHoejde
	label.TextColor3 = STIL.farve
	label.TextStrokeTransparency = 0.6
	label.Text = "+" .. FormatNumber(beloeb)
	label.Size = UDim2.new(0, 200, 0, 40)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Position = UDim2.new(0, math.random(STIL.xMin, STIL.xMax), 0, math.random(STIL.yMin, STIL.yMax))
	label.Parent = skaerm

	local tween = TweenService:Create(
		label,
		TweenInfo.new(STIL.varighed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = label.Position - UDim2.new(0, 0, 0, STIL.loeft),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}
	)
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)
end

-- Serveren sender (beløb, antal popups). Enkelt-salg = 1, Sell All = op til 3.
sellPopup.OnClientEvent:Connect(function(beloeb, antal)
	antal = math.max(antal or 1, 1)
	antal = math.min(antal, beloeb)          -- aldrig flere popups end der er coins til

	-- Del beløbet i "antal" dele, der summer PRÆCIS til beløbet.
	-- Hver del er cirka en ligelig andel med lidt tilfældig variation.
	local dele = {}
	local rest = beloeb
	for i = 1, antal do
		local del
		if i == antal then
			del = rest                        -- sidste del tager resten -> summen passer altid
		else
			local andel = rest / (antal - i + 1)
			del = math.floor(andel * (0.7 + math.random() * 0.6))   -- 70-130% af ligelig andel
			del = math.max(del, 1)
			del = math.min(del, rest - (antal - i))   -- efterlad mindst 1 til hver af de næste
		end
		table.insert(dele, del)
		rest -= del
	end

	-- Vis dem med en lille forskydning i tid, så det føles som en byge
	for i, del in dele do
		task.delay((i - 1) * STIL.forsinkelse, lavPopup, del)
	end
end)
