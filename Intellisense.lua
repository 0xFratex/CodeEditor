--[[
	Dracula Intellisense System
	Smart code completion that adapts to the Roblox game environment
]]

local Intellisense = {}

-- Services
local Players = game:GetService("Players")

-- Configuration
Intellisense.Config = {
	MaxSuggestions = 15,
	MaxChildrenScan = 50,
	MaxDepthScan = 3,
	DebounceTime = 0.1,
	CacheLifetime = 5,
	EnableEnvironmentScan = true,
}

-- Cache
Intellisense.Cache = {
	LastUpdate = 0,
	GameStructure = {},
}

-- Completion item class
local CompletionItem = {}
CompletionItem.__index = CompletionItem

function CompletionItem.new(name, kind, documentation, insertText, priority)
	local self = setmetatable({}, CompletionItem)
	self.Name = name
	self.Kind = kind or "Text"
	self.Documentation = documentation or ""
	self.InsertText = insertText or name
	self.Priority = priority or 0
	self.Detail = ""
	return self
end

Intellisense.CompletionItem = CompletionItem

-- Kinds
Intellisense.CompletionKind = {
	Keyword = "Keyword", Function = "Function", Method = "Method",
	Property = "Property", Variable = "Variable", Class = "Class",
	Constant = "Constant", String = "String", Number = "Number",
	Boolean = "Boolean", Event = "Event", Enum = "Enum",
	Field = "Field", File = "File", Folder = "Folder",
	Module = "Module", Instance = "Instance", Builtin = "Builtin",
	Service = "Service",
}

-- Lua keywords
Intellisense.LuaKeywords = {
	{ name = "and", kind = "Keyword", doc = "Logical AND" },
	{ name = "break", kind = "Keyword", doc = "Exit loop" },
	{ name = "do", kind = "Keyword", doc = "Start block" },
	{ name = "else", kind = "Keyword", doc = "Else branch" },
	{ name = "elseif", kind = "Keyword", doc = "Elseif branch" },
	{ name = "end", kind = "Keyword", doc = "Close block" },
	{ name = "false", kind = "Keyword", doc = "Boolean false" },
	{ name = "for", kind = "Keyword", doc = "For loop" },
	{ name = "function", kind = "Keyword", doc = "Define function" },
	{ name = "if", kind = "Keyword", doc = "If statement" },
	{ name = "in", kind = "Keyword", doc = "In loop" },
	{ name = "local", kind = "Keyword", doc = "Local variable" },
	{ name = "nil", kind = "Keyword", doc = "Null value" },
	{ name = "not", kind = "Keyword", doc = "Logical NOT" },
	{ name = "or", kind = "Keyword", doc = "Logical OR" },
	{ name = "repeat", kind = "Keyword", doc = "Repeat loop" },
	{ name = "return", kind = "Keyword", doc = "Return value" },
	{ name = "then", kind = "Keyword", doc = "Then clause" },
	{ name = "true", kind = "Keyword", doc = "Boolean true" },
	{ name = "until", kind = "Keyword", doc = "Until condition" },
	{ name = "while", kind = "Keyword", doc = "While loop" },
	{ name = "continue", kind = "Keyword", doc = "Continue loop" },
}

-- Lua builtins
Intellisense.LuaBuiltins = {
	{ name = "print", kind = "Function", doc = "Print to output" },
	{ name = "warn", kind = "Function", doc = "Print warning" },
	{ name = "error", kind = "Function", doc = "Raise error" },
	{ name = "assert", kind = "Function", doc = "Assert condition" },
	{ name = "type", kind = "Function", doc = "Get type" },
	{ name = "typeof", kind = "Function", doc = "Get Roblox type" },
	{ name = "tostring", kind = "Function", doc = "Convert to string" },
	{ name = "tonumber", kind = "Function", doc = "Convert to number" },
	{ name = "pairs", kind = "Function", doc = "Table iterator" },
	{ name = "ipairs", kind = "Function", doc = "Array iterator" },
	{ name = "next", kind = "Function", doc = "Next item" },
	{ name = "select", kind = "Function", doc = "Select args" },
	{ name = "pcall", kind = "Function", doc = "Protected call" },
	{ name = "xpcall", kind = "Function", doc = "Extended pcall" },
	{ name = "tick", kind = "Function", doc = "Get tick count" },
	{ name = "time", kind = "Function", doc = "Get time" },
	{ name = "wait", kind = "Function", doc = "Wait seconds" },
	{ name = "delay", kind = "Function", doc = "Delay execution" },
	{ name = "spawn", kind = "Function", doc = "Spawn function" },
}

-- Roblox globals
Intellisense.RobloxGlobals = {
	{ name = "game", kind = "Variable", doc = "The game DataModel" },
	{ name = "workspace", kind = "Variable", doc = "The workspace" },
	{ name = "Game", kind = "Class", doc = "Game class" },
	{ name = "Workspace", kind = "Class", doc = "Workspace class" },
	{ name = "script", kind = "Variable", doc = "Current script" },
}

-- Roblox services
Intellisense.RobloxServices = {
	{ name = "Players", kind = "Class", doc = "Player service" },
	{ name = "Lighting", kind = "Class", doc = "Lighting service" },
	{ name = "ReplicatedStorage", kind = "Class", doc = "Shared storage" },
	{ name = "ReplicatedFirst", kind = "Class", doc = "First replicated" },
	{ name = "ServerStorage", kind = "Class", doc = "Server storage" },
	{ name = "ServerScriptService", kind = "Class", doc = "Server scripts" },
	{ name = "StarterGui", kind = "Class", doc = "Starter GUI" },
	{ name = "StarterPack", kind = "Class", doc = "Starter items" },
	{ name = "StarterPlayer", kind = "Class", doc = "Starter player" },
	{ name = "TweenService", kind = "Class", doc = "Tween service" },
	{ name = "UserInputService", kind = "Class", doc = "Input service" },
	{ name = "RunService", kind = "Class", doc = "Run service" },
	{ name = "HttpService", kind = "Class", doc = "HTTP service" },
	{ name = "DataStoreService", kind = "Class", doc = "DataStore service" },
	{ name = "TeleportService", kind = "Class", doc = "Teleport service" },
}

-- Instance methods
Intellisense.InstanceMethods = {
	{ name = "Clone", kind = "Method", doc = "Clone instance", insert = "Clone()" },
	{ name = "Destroy", kind = "Method", doc = "Destroy instance", insert = "Destroy()" },
	{ name = "FindFirstChild", kind = "Method", doc = "Find child", insert = "FindFirstChild(name)" },
	{ name = "GetChildren", kind = "Method", doc = "Get all children", insert = "GetChildren()" },
	{ name = "GetDescendants", kind = "Method", doc = "Get all descendants", insert = "GetDescendants()" },
	{ name = "IsA", kind = "Method", doc = "Check class", insert = "IsA(className)" },
	{ name = "WaitForChild", kind = "Method", doc = "Wait for child", insert = "WaitForChild(name)" },
	{ name = "ClearAllChildren", kind = "Method", doc = "Clear children", insert = "ClearAllChildren()" },
	{ name = "GetAttribute", kind = "Method", doc = "Get attribute", insert = "GetAttribute(name)" },
	{ name = "SetAttribute", kind = "Method", doc = "Set attribute", insert = "SetAttribute(name, value)" },
}

-- Instance properties
Intellisense.InstanceProperties = {
	{ name = "Name", kind = "Property", doc = "Instance name" },
	{ name = "ClassName", kind = "Property", doc = "Class name" },
	{ name = "Parent", kind = "Property", doc = "Parent instance" },
}

-- Scan instance children
function Intellisense.ScanInstanceChildren(instance, maxDepth, currentDepth)
	maxDepth = maxDepth or Intellisense.Config.MaxDepthScan
	currentDepth = currentDepth or 0
	
	if currentDepth > maxDepth then return {} end
	
	local children = {}
	local count = 0
	local maxChildren = Intellisense.Config.MaxChildrenScan
	
	for _, child in ipairs(instance:GetChildren()) do
		if count >= maxChildren then break end
		
		table.insert(children, {
			name = child.Name,
			className = child.ClassName,
			instance = child,
		})
		count = count + 1
		
		if currentDepth < maxDepth then
			local subChildren = Intellisense.ScanInstanceChildren(child, maxDepth, currentDepth + 1)
			for _, subChild in ipairs(subChildren) do
				table.insert(children, subChild)
			end
		end
	end
	
	return children
end

-- Parse code context
function Intellisense.ParseContext(code, cursorPosition)
	local textBeforeCursor = string.sub(code, 1, cursorPosition)
	
	local context = {
		Type = "General",
		Prefix = "",
		BaseExpression = "",
		NeedsDot = false,
		NeedsColon = false,
		MethodName = "",
	}
	
	-- Check for method call: expr:method(
	local methodMatch = string.match(textBeforeCursor, "([%w%.%_:]+):(%w+)%(%s*$")
	if methodMatch then
		context.Type = "MethodResult"
		context.BaseExpression = string.match(textBeforeCursor, "(.-):(%w+)%(%s*$") or ""
		context.MethodName = methodMatch
		return context
	end
	
	-- Check for property access: expr.
	local dotMatch = string.match(textBeforeCursor, "([%w%.%_:]+)%.([%w_]*)$")
	if dotMatch then
		context.Type = "Property"
		context.BaseExpression = dotMatch
		context.Prefix = string.match(textBeforeCursor, "%.([%w_]*)$") or ""
		context.NeedsDot = true
		return context
	end
	
	-- Check for method: expr:
	local colonMatch = string.match(textBeforeCursor, "([%w%.%_:]+):([%w_]*)$")
	if colonMatch then
		context.Type = "Method"
		context.BaseExpression = colonMatch
		context.Prefix = string.match(textBeforeCursor, ":([%w_]*)$") or ""
		context.NeedsColon = true
		return context
	end
	
	-- Check for index: expr[""] - using double quotes only to avoid escape issues
	local indexMatch = string.match(textBeforeCursor, '([%w%.%_:]+)%["([%w_]*)$')
	if indexMatch then
		context.Type = "Index"
		context.BaseExpression = indexMatch
		context.Prefix = string.match(textBeforeCursor, '%["([%w_]*)$') or ""
		return context
	end
	
	-- Check for single quote index
	local indexMatch2 = string.match(textBeforeCursor, "([%w%.%_:]+)%'([%w_]*)$")
	if indexMatch2 then
		context.Type = "Index"
		context.BaseExpression = indexMatch2
		context.Prefix = string.match(textBeforeCursor, "%'([%w_]*)$") or ""
		return context
	end
	
	-- Check for string literal
	local stringMatch = string.match(textBeforeCursor, '"([%w_]*)$')
	if stringMatch then
		context.Type = "StringIndex"
		context.Prefix = stringMatch
		return context
	end
	
	local stringMatch2 = string.match(textBeforeCursor, "'([%w_]*)$")
	if stringMatch2 then
		context.Type = "StringIndex"
		context.Prefix = stringMatch2
		return context
	end
	
	-- General - get word being typed
	local wordMatch = string.match(textBeforeCursor, "([%w_]+)$")
	if wordMatch then
		context.Type = "General"
		context.Prefix = wordMatch
	end
	
	return context
end

-- Evaluate expression
function Intellisense.EvaluateExpression(expression)
	if not expression or expression == "" then
		return nil
	end
	
	if expression == "game" then
		return game
	elseif expression == "workspace" then
		return workspace
	elseif expression == "script" then
		return script
	end
	
	-- game.ServiceName
	local serviceMatch = string.match(expression, "^game%.(%w+)$")
	if serviceMatch then
		local success, service = pcall(function()
			return game:GetService(serviceMatch)
		end)
		if success then return service end
	end
	
	-- game:GetService("ServiceName") - with double quotes
	local getServiceMatch = string.match(expression, 'game:GetService%("(%w+)"%)')
	if getServiceMatch then
		local success, service = pcall(function()
			return game:GetService(getServiceMatch)
		end)
		if success then return service end
	end
	
	-- game:GetService('ServiceName') - with single quotes
	local getServiceMatch2 = string.match(expression, "game:GetService%('(%w+)'%)")
	if getServiceMatch2 then
		local success, service = pcall(function()
			return game:GetService(getServiceMatch2)
		end)
		if success then return service end
	end
	
	-- workspace.ChildName
	local workspaceMatch = string.match(expression, "^workspace%.(.+)$")
	if workspaceMatch then
		local success, child = pcall(function()
			return workspace:FindFirstChild(workspaceMatch, true)
		end)
		if success then return child end
	end
	
	-- game.Workspace.ChildName
	local gameWorkspaceMatch = string.match(expression, "^game%.Workspace%.(.+)$")
	if gameWorkspaceMatch then
		local success, child = pcall(function()
			return workspace:FindFirstChild(gameWorkspaceMatch, true)
		end)
		if success then return child end
	end
	
	return nil
end

-- Get completions for method result (GetChildren, etc.)
function Intellisense.GetMethodResultCompletions(baseExpression, methodName)
	local completions = {}
	
	local instance = Intellisense.EvaluateExpression(baseExpression)
	if not instance then return completions end
	
	if methodName == "GetChildren" then
		local success, children = pcall(function()
			return instance:GetChildren()
		end)
		
		if success and type(children) == "table" then
			local count = 0
			local maxItems = Intellisense.Config.MaxChildrenScan
			
			table.sort(children, function(a, b)
				return a.Name < b.Name
			end)
			
			for i, child in ipairs(children) do
				if count >= maxItems then break end
				
				local item = CompletionItem.new(
					child.Name,
					Intellisense.CompletionKind.Instance,
					string.format("%s (Index: %d, Class: %s)", child.Name, i - 1, child.ClassName),
					string.format("[%d]", i - 1),
					100 - count
				)
				item.Detail = string.format("%s:GetChildren()[%d]", baseExpression, i - 1)
				table.insert(completions, item)
				count = count + 1
			end
		end
	end
	
	return completions
end

-- Get instance completions
function Intellisense.GetInstanceCompletions(instance, prefix, needsMethod)
	local completions = {}
	if not instance then return completions end
	
	local lowerPrefix = string.lower(prefix or "")
	
	if needsMethod then
		for _, method in ipairs(Intellisense.InstanceMethods) do
			if lowerPrefix == "" or string.find(string.lower(method.name), lowerPrefix, 1, true) then
				local item = CompletionItem.new(
					method.name,
					Intellisense.CompletionKind.Method,
					method.doc,
					method.insert or (method.name .. "()"),
					100
				)
				table.insert(completions, item)
			end
		end
	else
		-- Add children
		local success, children = pcall(function()
			return instance:GetChildren()
		end)
		
		if success then
			for _, child in ipairs(children) do
				if lowerPrefix == "" or string.find(string.lower(child.Name), lowerPrefix, 1, true) then
					table.insert(completions, CompletionItem.new(
						child.Name,
						Intellisense.CompletionKind.Instance,
						string.format("Instance: %s", child.ClassName),
						child.Name,
						80
					))
				end
			end
		end
		
		-- Add properties
		for _, prop in ipairs(Intellisense.InstanceProperties) do
			if lowerPrefix == "" or string.find(string.lower(prop.name), lowerPrefix, 1, true) then
				table.insert(completions, CompletionItem.new(
					prop.name,
					Intellisense.CompletionKind.Property,
					prop.doc,
					prop.name,
					70
				))
			end
		end
		
		-- Add methods
		for _, method in ipairs(Intellisense.InstanceMethods) do
			if lowerPrefix == "" or string.find(string.lower(method.name), lowerPrefix, 1, true) then
				table.insert(completions, CompletionItem.new(
					method.name,
					Intellisense.CompletionKind.Method,
					method.doc,
					method.name .. "()",
					60
				))
			end
		end
	end
	
	return completions
end

-- Main get completions function
function Intellisense.GetCompletions(code, cursorPosition, environmentVariables)
	local completions = {}
	local context = Intellisense.ParseContext(code, cursorPosition)
	
	-- Method result (GetChildren, etc.)
	if context.Type == "MethodResult" then
		return Intellisense.GetMethodResultCompletions(context.BaseExpression, context.MethodName), context
	end
	
	-- Property/Method completions
	if context.Type == "Property" or context.Type == "Method" then
		local instance = Intellisense.EvaluateExpression(context.BaseExpression)
		if instance then
			return Intellisense.GetInstanceCompletions(instance, context.Prefix, context.NeedsColon), context
		end
		return completions, context
	end
	
	-- String index
	if context.Type == "StringIndex" or context.Type == "Index" then
		local instance = Intellisense.EvaluateExpression(context.BaseExpression)
		if instance then
			local success, children = pcall(function()
				return instance:GetChildren()
			end)
			if success then
				for _, child in ipairs(children) do
					if string.find(string.lower(child.Name), string.lower(context.Prefix), 1, true) then
						table.insert(completions, CompletionItem.new(
							child.Name,
							Intellisense.CompletionKind.Instance,
							string.format("Instance: %s", child.ClassName),
							child.Name,
							100
						))
					end
				end
			end
		end
		return completions, context
	end
	
	-- General completions
	local lowerPrefix = string.lower(context.Prefix)
	
	-- Keywords
	for _, keyword in ipairs(Intellisense.LuaKeywords) do
		if lowerPrefix == "" or string.find(string.lower(keyword.name), lowerPrefix, 1, true) then
			table.insert(completions, CompletionItem.new(
				keyword.name,
				Intellisense.CompletionKind.Keyword,
				keyword.doc,
				keyword.name,
				100
			))
		end
	end
	
	-- Builtins
	for _, builtin in ipairs(Intellisense.LuaBuiltins) do
		if lowerPrefix == "" or string.find(string.lower(builtin.name), lowerPrefix, 1, true) then
			table.insert(completions, CompletionItem.new(
				builtin.name,
				Intellisense.CompletionKind.Function,
				builtin.doc,
				builtin.name .. "()",
				90
			))
		end
	end
	
	-- Roblox globals
	for _, global in ipairs(Intellisense.RobloxGlobals) do
		if lowerPrefix == "" or string.find(string.lower(global.name), lowerPrefix, 1, true) then
			table.insert(completions, CompletionItem.new(
				global.name,
				Intellisense.CompletionKind[global.kind] or Intellisense.CompletionKind.Variable,
				global.doc,
				global.name,
				85
			))
		end
	end
	
	-- Roblox services
	for _, service in ipairs(Intellisense.RobloxServices) do
		if lowerPrefix == "" or string.find(string.lower(service.name), lowerPrefix, 1, true) then
			table.insert(completions, CompletionItem.new(
				service.name,
				Intellisense.CompletionKind.Class,
				service.doc,
				service.name,
				80
			))
		end
	end
	
	-- Environment variables
	if environmentVariables then
		for name, var in pairs(environmentVariables) do
			if lowerPrefix == "" or string.find(string.lower(name), lowerPrefix, 1, true) then
				table.insert(completions, CompletionItem.new(
					name,
					Intellisense.CompletionKind.Variable,
					var.doc or "Local variable",
					name,
					95
				))
			end
		end
	end
	
	-- Sort by priority
	table.sort(completions, function(a, b)
		if a.Priority ~= b.Priority then
			return a.Priority > b.Priority
		end
		return a.Name < b.Name
	end)
	
	-- Limit results
	while #completions > Intellisense.Config.MaxSuggestions do
		table.remove(completions)
	end
	
	return completions, context
end

-- Extract variables from code
function Intellisense.ExtractVariables(code, cursorPosition)
	local variables = {}
	local textBeforeCursor = string.sub(code, 1, cursorPosition)
	
	for varName in string.gmatch(textBeforeCursor, "local%s+([%w_]+)%s*=") do
		variables[varName] = { doc = "Local variable" }
	end
	
	for params in string.gmatch(textBeforeCursor, "function%s+[%w_.:]+%(([^)]*)%)") do
		for param in string.gmatch(params, "([%w_]+)") do
			if param ~= "" then
				variables[param] = { doc = "Parameter" }
			end
		end
	end
	
	return variables
end

return Intellisense
