-- Quest chains: counters advance on gameplay events, stat quests are
-- evaluated against live values every economy tick. Completions pay out
-- automatically with a fanfare; repeatable end-quests loop forever.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local QuestDefs = require(Shared.QuestDefs)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)

local QuestService = {}

local ctx

local STAT_KINDS = { cash = true, worth = true, rocket_level = true, buildings = true }

local function notify(player, msg, kind)
	Remotes.Events.Notify:FireClient(player, { msg = msg, kind = kind or "info" })
end

local function chainState(profile, chainId)
	profile.quests = profile.quests or {}
	local state = profile.quests[chainId]
	if not state then
		state = { index = 1, progress = 0, loops = 0 }
		profile.quests[chainId] = state
	end
	return state
end

local function currentQuest(chainId, state)
	local chain = QuestDefs.Chains[chainId]
	return chain.quests[state.index]
end

local function grantReward(player, reward)
	local profile = ctx.Data.get(player)
	local bits = {}
	if reward.cash then
		profile.cash += reward.cash
		bits[#bits + 1] = "\u{1F4B5} " .. NumberFormat.abbrev(reward.cash)
	end
	if reward.cashMinutes then
		local amount = math.max(5000, ctx.Economy.getIncomePerSec(player) * 60 * reward.cashMinutes)
		profile.cash += amount
		bits[#bits + 1] = "\u{1F4B5} " .. NumberFormat.abbrev(amount)
	end
	if reward.gems then
		profile.gems += reward.gems
		bits[#bits + 1] = "\u{1F48E} " .. reward.gems
	end
	if reward.shield then
		profile.shields += reward.shield
		bits[#bits + 1] = "\u{1F6E1}\u{FE0F} Shield"
	end
	if reward.barrage then
		profile.barrage += reward.barrage
		bits[#bits + 1] = "\u{1F680}x3 Barrage"
	end
	return table.concat(bits, " + ")
end

local function tryComplete(player, chainId, state, statValue)
	local quest = currentQuest(chainId, state)
	if not quest then
		return
	end
	local progress = statValue or state.progress
	if progress < quest.goal then
		return
	end

	local rewardText = grantReward(player, quest.reward)
	notify(player, "\u{1F4DC} QUEST COMPLETE: " .. quest.name .. "! Reward: " .. rewardText, "victory")

	if quest.repeatable then
		state.loops += 1
		state.progress = 0
	else
		state.index += 1
		state.progress = 0
	end
end

-- Counter events: upgrade, destroy, missile_launch, nuke.
function QuestService.onEvent(player, kind, amount)
	local profile = ctx.Data.get(player)
	if not profile then
		return
	end
	for chainId in pairs(QuestDefs.Chains) do
		local state = chainState(profile, chainId)
		local quest = currentQuest(chainId, state)
		if quest and quest.kind == kind then
			state.progress += amount
			tryComplete(player, chainId, state)
		end
	end
end

-- Stat evaluation, called from the economy tick.
-- stats = { cash =, worth =, rocket_level =, buildings = }
function QuestService.evaluate(player, stats)
	local profile = ctx.Data.get(player)
	if not profile then
		return
	end
	for chainId in pairs(QuestDefs.Chains) do
		local state = chainState(profile, chainId)
		local quest = currentQuest(chainId, state)
		if quest and STAT_KINDS[quest.kind] then
			tryComplete(player, chainId, state, stats[quest.kind] or 0)
		end
	end
end

-- Compact summary for the client (state push).
function QuestService.getSummary(player, stats)
	local profile = ctx.Data.get(player)
	if not profile then
		return nil
	end
	local summary = {}
	for chainId, chain in pairs(QuestDefs.Chains) do
		local state = chainState(profile, chainId)
		local quest = currentQuest(chainId, state)
		if quest then
			local progress = state.progress
			if STAT_KINDS[quest.kind] and stats then
				progress = stats[quest.kind] or 0
			end
			summary[chainId] = {
				title = chain.title,
				name = quest.name,
				desc = quest.desc,
				progress = math.min(progress, quest.goal),
				goal = quest.goal,
				number = state.index,
				total = #chain.quests,
				repeatable = quest.repeatable or false,
			}
		else
			summary[chainId] = { title = chain.title, done = true, total = #chain.quests }
		end
	end
	return summary
end

function QuestService.init(context)
	ctx = context
end

return QuestService
