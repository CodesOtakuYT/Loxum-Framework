local Driver = {}
Driver.__index = Driver

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared, RemotesFolder = nil, nil

function Driver:_Initialize()
	print(self._Name, "initialized")
end

function Driver:_Start()
	print(self._Name, "started")
end

function Driver:_Remote(event, func)
	
end

function Driver:_Fire(player, clientModuleName, remoteName, ...)
	if not Shared then
		local SharedModule = ReplicatedStorage:WaitForChild("FrameworkShared"):WaitForChild("Shared")
		local Shared = require(SharedModule)
		RemotesFolder = Shared.RemotesFolder
	end
	
	local event = RemotesFolder:FindFirstChild(clientModuleName):FindFirstChild(remoteName)
	
	if player and player:IsA("Player") then
		if event:IsA("RemoteEvent") then
			event:FireClient(player, ...)
		elseif event:IsA("RemoteFunction") then
			return event:InvokeClient(player, ...)
		end
	else
		event:FireAllClients(...)
	end
end

function Driver:_InitializeClass(server)
	self._FW = server
	
	return self
end

return Driver
