-- GlobalCatchChat.client.luau
-- Viser den globale ekstrem-fangst-besked i den INDBYGGEDE Roblox-chat (mørkerød).
-- Beskeden kommer fra serveren, som fik den fra MessagingService (alle servere).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")

local globalCatch = ReplicatedStorage:WaitForChild("GlobalCatch")

local FARVE_RIG = "rgb(150, 0, 0)"                 -- mørkerød (ny TextChatService)
local FARVE_LEGACY = Color3.fromRGB(150, 0, 0)     -- mørkerød (gammel chat)

-- Find den generelle chat-kanal, hvis spillet bruger den nye TextChatService
local generelKanal = nil
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
	local kanaler = TextChatService:WaitForChild("TextChannels", 10)
	if kanaler then
		generelKanal = kanaler:WaitForChild("RBXGeneral", 10)
	end
end

local function visIChat(tekst)
	if generelKanal then
		-- Ny chat: system-besked med rich-text farve
		generelKanal:DisplaySystemMessage("<font color='" .. FARVE_RIG .. "'>" .. tekst .. "</font>")
	else
		-- Gammel chat (fallback): system-besked med Color3
		pcall(function()
			StarterGui:SetCore("ChatMakeSystemMessage", {
				Text = tekst,
				Color = FARVE_LEGACY,
				Font = Enum.Font.GothamBold,
			})
		end)
	end
end

globalCatch.OnClientEvent:Connect(visIChat)
