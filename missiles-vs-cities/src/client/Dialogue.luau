-- NPC dialogue box: typewriter text with blip sounds, Next/Bye buttons,
-- and an action button on the last line (open shop, view quests, ...).

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NPCDefs = require(Shared.NPCDefs)
local SoundBook = require(Shared.SoundBook)
local UILib = require(script.Parent.UILib)

local Dialogue = {}

local ctx
local gui
local nameLabel
local textLabel
local nextButton
local actionButton

local currentNpc = nil
local lineIndex = 1
local typing = false
local typeToken = 0

local function typeLine(text)
	typeToken += 1
	local token = typeToken
	typing = true
	textLabel.Text = ""
	task.spawn(function()
		for i = 1, #text do
			if token ~= typeToken then
				return
			end
			-- Never split a UTF-8 character (emoji are multi-byte).
			local safe = text:sub(1, i)
			local lastOk = utf8.len(safe)
			if lastOk then
				textLabel.Text = safe
				if i % 3 == 0 then
					SoundBook.play("Blip", UILib.playerGui())
				end
			end
			task.wait(0.018)
		end
		if token == typeToken then
			textLabel.Text = text
			typing = false
		end
	end)
end

local function showLine()
	local def = currentNpc
	if not def then
		return
	end
	local isLast = lineIndex >= #def.lines
	typeLine(def.lines[lineIndex])
	nextButton.Text = isLast and "Bye!" or "Next \u{25B6}"
	actionButton.Visible = isLast and def.action ~= nil
	if isLast and def.action then
		actionButton.Text = def.actionLabel or "Okay"
	end
end

function Dialogue.close()
	currentNpc = nil
	gui.Enabled = false
end

function Dialogue.open(npcId)
	local def = NPCDefs.ById[npcId]
	if not def then
		return
	end
	currentNpc = def
	lineIndex = 1
	nameLabel.Text = def.emoji .. " " .. def.name
	gui.Enabled = true
	SoundBook.play("PanelOpen", UILib.playerGui())
	showLine()
end

local function doAction()
	local def = currentNpc
	Dialogue.close()
	if not def then
		return
	end
	if def.action == "shop" then
		ctx.ShopToggle()
	elseif def.action == "charshop" then
		ctx.CharShop.toggle()
	elseif def.action == "quest" then
		ctx.QuestUI.toggle()
	end
end

function Dialogue.init(context)
	ctx = context

	gui = UILib.screen("MVC_Dialogue", 25)
	gui.Enabled = false

	local box = UILib.frame({
		Size = UDim2.new(0, 560, 0, 170),
		Position = UDim2.new(0.5, 0, 1, -30),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 0.05,
	}, gui)

	local header = UILib.frame({
		Size = UDim2.new(0, 320, 0, 40),
		Position = UDim2.new(0, 14, 0, -20),
		BackgroundColor3 = UILib.Colors.Blue,
	}, box)
	nameLabel = UILib.text({
		Size = UDim2.new(1, -12, 1, -8),
		Position = UDim2.new(0, 6, 0, 4),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header)

	textLabel = UILib.text({
		Size = UDim2.new(1, -28, 0, 74),
		Position = UDim2.new(0, 14, 0, 28),
		Text = "",
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextScaled = false,
		TextSize = 22,
	}, box)

	nextButton = UILib.button({
		Size = UDim2.new(0, 130, 0, 42),
		Position = UDim2.new(1, -144, 1, -54),
		Text = "Next \u{25B6}",
		BackgroundColor3 = UILib.Colors.Green,
	}, box, function()
		if not currentNpc then
			return
		end
		if typing then
			typeToken += 1
			typing = false
			textLabel.Text = currentNpc.lines[lineIndex]
			return
		end
		if lineIndex >= #currentNpc.lines then
			Dialogue.close()
		else
			lineIndex += 1
			showLine()
		end
	end)

	actionButton = UILib.button({
		Size = UDim2.new(0, 220, 0, 42),
		Position = UDim2.new(0, 14, 1, -54),
		Text = "",
		BackgroundColor3 = UILib.Colors.Purple,
		Visible = false,
	}, box, doAction)

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local id = prompt.Name:match("^TalkPrompt_(.+)$")
		if id then
			Dialogue.open(id)
		end
	end)
end

return Dialogue
