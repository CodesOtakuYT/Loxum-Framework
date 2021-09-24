local Client = {}
_G.CodesOtaku = {
	FrameworkClient = Client
}

local ReplicatedFirst = script.Parent.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameFolder = ReplicatedFirst.Game
local ClassFolder = script.Parent.Class

local startedEvent = Instance.new("BindableEvent")

local Classes = {}
local Modules = {}

function Client:AddModule(module, class)
	local moduleName = module.Name

	local module = setmetatable(require(module), class)
	
	-- Injected properties
	module._Name = moduleName
	-- END
	
	local remoteEvents = {}
	local remoteFunctions = {}

	module:_Initialize(Client, Modules)
	
	local SharedModule = ReplicatedStorage:WaitForChild("FrameworkShared"):WaitForChild("Shared")
	local Shared = require(SharedModule)
	local RemotesFolder = Shared.RemotesFolder
	
	module:_Remote(remoteEvents, remoteFunctions)
	local remoteEventsBlueprint = {}
	local remoteFunctionsBlueprint = {}
	
	for i,v in pairs(remoteEvents) do
		remoteEventsBlueprint[i] = true
	end
	
	for i,v in pairs(remoteFunctions) do
		remoteFunctionsBlueprint[i] = true
	end
	
	local blueprint = Shared.CreateBlueprint:InvokeServer(moduleName, remoteEventsBlueprint, remoteFunctionsBlueprint)
	
	for remoteEventName, remoteEventCallback in pairs(remoteEvents) do
		local remoteEvent = blueprint:FindFirstChild(remoteEventName)
		remoteEvent.OnClientEvent:Connect(remoteEventCallback)
	end

	for remoteFunctionName, remoteFunctionCallback in pairs(remoteFunctions) do
		warn(string.format("Client Remote Functions are notoriously dangerous and should'nt be used (%s)", remoteFunctionName))
		local remoteFunction = blueprint:FindFirstChild(remoteFunctionName)
		remoteFunction.OnClientInvoke = remoteFunctionCallback
	end
	
	startedEvent.Event:Connect(function(...)
		module:_Start(...)
	end)

	Modules[moduleName] = module
	return module
end

function Client:GetModule(moduleName)
	return Modules[moduleName]
end

function Client:AddClass(module)
	local class = require(module):_InitializeClass(Client)
	Classes[module.Name] = class
	return class
end

function Client:GetClass(className)
	return Classes[className]
end

local function Initialize()
	for _, classModule in pairs(ClassFolder:GetChildren()) do
		local class = Client:AddClass(classModule)
		local classFolder = GameFolder:FindFirstChild(classModule.Name)

		if not ClassFolder then
			continue
		end

		for _, module in pairs(classFolder:GetChildren()) do
			Client:AddModule(module, class)
		end
	end

	startedEvent:Fire()
end

Initialize()
return Client
