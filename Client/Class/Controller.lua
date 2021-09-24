local Controller = {}
Controller.__index = Controller

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared, RemotesFolder = nil, nil

function Controller:_Initialize()
	print(self._Name, "initialized")
end

function Controller:_Start()
	print(self._Name, "started")
end

function Controller:_Remote(event, func)

end

function Controller:_Fire(serverModuleName, remoteName, ...)
	if not Shared then
		local SharedModule = ReplicatedStorage:WaitForChild("FrameworkShared"):WaitForChild("Shared")
		local Shared = require(SharedModule)
		RemotesFolder = Shared.RemotesFolder
	end
	
	local event = RemotesFolder:FindFirstChild(serverModuleName):FindFirstChild(remoteName)
	
	if event:IsA("RemoteEvent") then
		event:FireServer(...)
	elseif event:IsA("RemoteFunction") then
		return event:InvokeServer(...)
	else
		error(string.format("the remote '%s' that belong to '%s' is not a valid RemoteEvent or RemoteFunction", remoteName, serverModuleName))
	end
end

function Controller:_InitializeClass(client)
	self._FW = client
	
	return self
end

return Controller
