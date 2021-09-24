local Server = {}
_G.CodesOtaku = {
	FrameworkServer = Server
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local function Find(object, objectName, objectType, parentName)
	if not object then
		error(string.format("[FRAMEWORK]: the '%s' %s is not found in '%s'", objectName, objectType, parentName))
	end
end

local GameFolder = ServerScriptService:FindFirstChild("Game")

Find(GameFolder, "Game", "Folder", "ServerScriptService")

local FrameworkFolder = script.Parent
local ClassFolder = FrameworkFolder:FindFirstChild("Class")

Find(ClassFolder, "Class", "Folder", "FrameworkFolder")

local startedEvent = Instance.new("BindableEvent")

local Classes = {}
local Modules = {}

local SharedFolder = ReplicatedStorage:FindFirstChild("FrameworkShared")

Find(SharedFolder, "FrameworkShared", "Folder", "ReplicatedStorage")

local SharedModule = SharedFolder:FindFirstChild("Shared")

Find(SharedFolder, "Shared", "ModuleScript", "FrameworkShared")

local Shared = require(SharedModule)
local RemotesFolder = Shared.RemotesFolder

local function NotType(type, ...)
	local valid = true
	
	for _, object in pairs({...}) do
		valid = valid and typeof(object) == type
	end
	
	return not valid
end

local function NotStr(...)
	return NotType("string", ...)	
end

local function NotTab(...)
	return NotType("table", ...)	
end

local function Folder(name, parent)
	local folder = Instance.new("Folder")
	if name then
		folder.Name = name
	end
	if parent then
		folder.Parent = parent
	end
	return folder
end

local function RemoteEvent(name, parent, callback)
	local remote = Instance.new("RemoteEvent")
	if name then
		remote.Name = name
	end
	if callback then
		remote.OnServerEvent:Connect(callback)
	end
	if parent then
		remote.Parent = parent
	end
end

local function RemoteFunction(name, parent, callback)
	local remote = Instance.new("RemoteFunction")
	if name then
		remote.Name = name
	end
	if callback then
		remote.OnServerInvoke = callback
	end
	if parent then
		remote.Parent = parent
	end
end

function Server:AddModule(module, class)
	if NotTab(class) then
		error("'class' should be a table")
	end
	
	if NotType("Instance", module) then
		error("'module' should be a ModuleScript")
	end
	
	local moduleName = module.Name
	
	local module = setmetatable(require(module), class)
	
	-- Injected properties
	module._Name = moduleName
	-- END
	
	local remoteEvents = {}
	local remoteFunctions = {}
	
	-- Framework hooks
	module:_Initialize(Server, Modules)
	module:_Remote(remoteEvents, remoteFunctions)
	
	local moduleRemoteFolder = Folder(moduleName)
	
	for remoteEventName, remoteEventCallback in pairs(remoteEvents) do
		RemoteEvent(remoteEventName, moduleRemoteFolder, remoteEventCallback)
	end
	
	for remoteFunctionName, remoteFunctionCallback in pairs(remoteFunctions) do
		RemoteFunction(remoteFunctionName, moduleRemoteFolder, remoteFunctionCallback)
	end
	
	moduleRemoteFolder.Parent = RemotesFolder
	
	startedEvent.Event:Connect(function(...)
		module:_Start(...)
	end)
	
	Modules[moduleName] = module
	return module
end

function Server:GetModule(moduleName)
	if NotStr(moduleName) then
		error("'moduleName' should be a string")
	end
	return Modules[moduleName]
end

function Server:AddClass(module)
	if NotType("Instance", module) then
		error("'module' should be a ModuleScript")
	end 
	local className = module.Name
	local class = require(module):_InitializeClass(Server)
	Classes[className] = class
	return class
end

function Server:GetClass(className)
	if NotStr(className) then
		error("'className' should be a string")
	end
	
	return Classes[className]
end

Shared.CreateBlueprint.OnServerInvoke = function(player, moduleName, remotes, functions)
	if NotStr(moduleName) and NotTab(remotes, functions) then
		return
	end
	
	local moduleRemoteFolder = Folder(moduleName)

	for remoteEventName, _ in pairs(remotes) do
		RemoteEvent(remoteEventName, moduleRemoteFolder)
	end

	for remoteFunctionName, _ in pairs(functions) do
		RemoteFunction(remoteFunctionName, moduleRemoteFolder)
	end

	moduleRemoteFolder.Parent = RemotesFolder
	return moduleRemoteFolder
end

local function Initialize()
	for _, classModule in pairs(ClassFolder:GetChildren()) do
		local className = classModule.Name
		
		if not classModule:IsA("ModuleScript") then
			error(string.format("The class '%s' is not a valid ModuleScript", className))
		end
		
		local class = Server:AddClass(classModule)
		local classFolder = GameFolder:FindFirstChild(className)
		
		if not classFolder then
			warn(string.format("The class '%s' is not used", className))
			continue
		end
		
		for _, module in pairs(classFolder:GetChildren()) do
			local moduleName = module.Name
			if not module:IsA("ModuleScript") then
				error(string.format("The module '%s' that is part of the class '%s' is not a valid ModuleScript", moduleName,className))
			end
			Server:AddModule(module, class)
		end
	end
	
	startedEvent:Fire()
end

Initialize()
return Server
