-- Client-side mirror of the player's server state, with local countdown helpers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local ClientState = {}

ClientState.data = nil
ClientState.changed = Instance.new("BindableEvent")

local receivedAt = 0

Remotes.Events.State.OnClientEvent:Connect(function(snapshot)
	ClientState.data = snapshot
	receivedAt = os.clock()
	ClientState.changed:Fire(snapshot)
end)

function ClientState.get()
	return ClientState.data
end

-- For fields sent as "seconds remaining": returns live remaining seconds.
function ClientState.remaining(field)
	local data = ClientState.data
	if not data or not data[field] then
		return 0
	end
	return math.max(0, data[field] - (os.clock() - receivedAt))
end

function ClientState.start()
	task.spawn(function()
		while not ClientState.data do
			local ok = pcall(function()
				Remotes.Functions.GetSnapshot:InvokeServer()
			end)
			if not ok then
				task.wait(1)
			end
			task.wait(0.5)
		end
	end)
end

return ClientState
