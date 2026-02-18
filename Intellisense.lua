--[[
	Dracula Intellisense System
	Smart code completion that adapts to the Roblox game environment
]]

local Intellisense = {}

-- Services
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Configuration
Intellisense.Config = {
	MaxSuggestions = 15,
	MaxChildrenScan = 50,         -- Max children to scan for GetChildren
	MaxDepthScan = 3,             -- Max depth for recursive scanning
	DebounceTime = 0.1,           -- Debounce for typing
	CacheLifetime = 5,            -- Cache lifetime in seconds
	EnableEnvironmentScan = true, -- Scan actual game environment
	EnableMethodIntellisense = true,
}

-- Cache for expensive operations
Intellisense.Cache = {
	LastUpdate = 0,
	GameStructure = {},
	InstanceChildren = {},
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
	self.SortText = string.format("%04d%s", 9999 - priority, name)
	return self
end

Intellisense.CompletionItem = CompletionItem

-- Kinds of completions
Intellisense.CompletionKind = {
	Keyword = "Keyword",
	Function = "Function",
	Method = "Method",
	Property = "Property",
	Variable = "Variable",
	Class = "Class",
	Constant = "Constant",
	String = "String",
	Number = "Number",
	Boolean = "Boolean",
	Event = "Event",
	Enum = "Enum",
	Field = "Field",
	File = "File",
	Folder = "Folder",
	Module = "Module",
	Instance = "Instance",
	Builtin = "Builtin",
}

-- Lua keywords
Intellisense.LuaKeywords = {
	{ name = "and", kind = "Keyword", doc = "Logical AND operator" },
	{ name = "break", kind = "Keyword", doc = "Exit a loop" },
	{ name = "do", kind = "Keyword", doc = "Start a block" },
	{ name = "else", kind = "Keyword", doc = "Alternative branch in if statement" },
	{ name = "elseif", kind = "Keyword", doc = "Additional condition in if statement" },
	{ name = "end", kind = "Keyword", doc = "Close a block" },
	{ name = "false", kind = "Keyword", doc = "Boolean false value" },
	{ name = "for", kind = "Keyword", doc = "For loop" },
	{ name = "function", kind = "Keyword", doc = "Define a function" },
	{ name = "if", kind = "Keyword", doc = "Conditional statement" },
	{ name = "in", kind = "Keyword", doc = "Used in generic for loop" },
	{ name = "local", kind = "Keyword", doc = "Declare local variable" },
	{ name = "nil", kind = "Keyword", doc = "Null value" },
	{ name = "not", kind = "Keyword", doc = "Logical NOT operator" },
	{ name = "or", kind = "Keyword", doc = "Logical OR operator" },
	{ name = "repeat", kind = "Keyword", doc = "Repeat-until loop" },
	{ name = "return", kind = "Keyword", doc = "Return from function" },
	{ name = "then", kind = "Keyword", doc = "Part of if statement" },
	{ name = "true", kind = "Keyword", doc = "Boolean true value" },
	{ name = "until", kind = "Keyword", doc = "End condition for repeat loop" },
	{ name = "while", kind = "Keyword", doc = "While loop" },
	{ name = "continue", kind = "Keyword", doc = "Skip to next iteration (Roblox extension)" },
	{ name = "type", kind = "Keyword", doc = "Type definition" },
	{ name = "export", kind = "Keyword", doc = "Export type" },
}

-- Lua built-in functions
Intellisense.LuaBuiltins = {
	{ name = "print", kind = "Function", doc = "Print to output", args = "..." },
	{ name = "warn", kind = "Function", doc = "Print warning to output", args = "..." },
	{ name = "error", kind = "Function", doc = "Raise an error", args = "message, level" },
	{ name = "assert", kind = "Function", doc = "Assert condition is true", args = "condition, message" },
	{ name = "type", kind = "Function", doc = "Get type of value", args = "value" },
	{ name = "typeof", kind = "Function", doc = "Get Roblox type of value", args = "value" },
	{ name = "tostring", kind = "Function", doc = "Convert to string", args = "value" },
	{ name = "tonumber", kind = "Function", doc = "Convert to number", args = "value, base" },
	{ name = "pairs", kind = "Function", doc = "Iterator for tables", args = "table" },
	{ name = "ipairs", kind = "Function", doc = "Iterator for arrays", args = "table" },
	{ name = "next", kind = "Function", doc = "Get next key-value pair", args = "table, key" },
	{ name = "select", kind = "Function", doc = "Select arguments", args = "index, ..." },
	{ name = "unpack", kind = "Function", doc = "Unpack table to values", args = "table, i, j" },
	{ name = "pack", kind = "Function", doc = "Pack values to table", args = "..." },
	{ name = "rawget", kind = "Function", doc = "Get without metatable", args = "table, key" },
	{ name = "rawset", kind = "Function", doc = "Set without metatable", args = "table, key, value" },
	{ name = "rawequal", kind = "Function", doc = "Compare without metatable", args = "a, b" },
	{ name = "rawlen", kind = "Function", doc = "Length without metatable", args = "table" },
	{ name = "setmetatable", kind = "Function", doc = "Set metatable", args = "table, metatable" },
	{ name = "getmetatable", kind = "Function", doc = "Get metatable", args = "table" },
	{ name = "pcall", kind = "Function", doc = "Protected call", args = "func, ..." },
	{ name = "xpcall", kind = "Function", doc = "Extended protected call", args = "func, errhandler, ..." },
	{ name = "tick", kind = "Function", doc = "Get current tick count", args = "" },
	{ name = "time", kind = "Function", doc = "Get game time", args = "" },
	{ name = "wait", kind = "Function", doc = "Wait for seconds", args = "seconds" },
	{ name = "delay", kind = "Function", doc = "Delayed execution", args = "seconds, func" },
	{ name = "spawn", kind = "Function", doc = "Spawn function", args = "func" },
}

-- String library
Intellisense.StringMethods = {
	{ name = "byte", kind = "Method", doc = "Get byte value of character" },
	{ name = "char", kind = "Method", doc = "Convert byte to character" },
	{ name = "find", kind = "Method", doc = "Find pattern in string" },
	{ name = "format", kind = "Method", doc = "Format string" },
	{ name = "gmatch", kind = "Method", doc = "Iterator for pattern matches" },
	{ name = "gsub", kind = "Method", doc = "Global substitution" },
	{ name = "len", kind = "Method", doc = "String length" },
	{ name = "lower", kind = "Method", doc = "Convert to lowercase" },
	{ name = "upper", kind = "Method", doc = "Convert to uppercase" },
	{ name = "match", kind = "Method", doc = "Match pattern" },
	{ name = "pack", kind = "Method", doc = "Pack values to string" },
	{ name = "packsize", kind = "Method", doc = "Get packed size" },
	{ name = "rep", kind = "Method", doc = "Repeat string" },
	{ name = "reverse", kind = "Method", doc = "Reverse string" },
	{ name = "split", kind = "Method", doc = "Split string" },
	{ name = "sub", kind = "Method", doc = "Substring" },
	{ name = "unpack", kind = "Method", doc = "Unpack string" },
}

-- Table library
Intellisense.TableMethods = {
	{ name = "concat", kind = "Method", doc = "Concatenate table" },
	{ name = "create", kind = "Method", doc = "Create table with size" },
	{ name = "find", kind = "Method", doc = "Find element in table" },
	{ name = "clear", kind = "Method", doc = "Clear table" },
	{ name = "freeze", kind = "Method", doc = "Freeze table" },
	{ name = "isfrozen", kind = "Method", doc = "Check if frozen" },
	{ name = "insert", kind = "Method", doc = "Insert element" },
	{ name = "move", kind = "Method", doc = "Move elements" },
	{ name = "pack", kind = "Method", doc = "Pack values" },
	{ name = "remove", kind = "Method", doc = "Remove element" },
	{ name = "sort", kind = "Method", doc = "Sort table" },
	{ name = "unpack", kind = "Method", doc = "Unpack table" },
}

-- Math library
Intellisense.MathMethods = {
	{ name = "abs", kind = "Method", doc = "Absolute value" },
	{ name = "acos", kind = "Method", doc = "Arc cosine" },
	{ name = "asin", kind = "Method", doc = "Arc sine" },
	{ name = "atan", kind = "Method", doc = "Arc tangent" },
	{ name = "atan2", kind = "Method", doc = "Arc tangent 2" },
	{ name = "ceil", kind = "Method", doc = "Ceiling" },
	{ name = "clamp", kind = "Method", doc = "Clamp value" },
	{ name = "cos", kind = "Method", doc = "Cosine" },
	{ name = "cosh", kind = "Method", doc = "Hyperbolic cosine" },
	{ name = "deg", kind = "Method", doc = "Degrees from radians" },
	{ name = "exp", kind = "Method", doc = "Exponential" },
	{ name = "floor", kind = "Method", doc = "Floor" },
	{ name = "fmod", kind = "Method", doc = "Modulo" },
	{ name = "frexp", kind = "Method", doc = "Mantissa and exponent" },
	{ name = "ldexp", kind = "Method", doc = "Load exponent" },
	{ name = "log", kind = "Method", doc = "Logarithm" },
	{ name = "log10", kind = "Method", doc = "Base 10 logarithm" },
	{ name = "max", kind = "Method", doc = "Maximum" },
	{ name = "min", kind = "Method", doc = "Minimum" },
	{ name = "modf", kind = "Method", doc = "Integer and fraction" },
	{ name = "noise", kind = "Method", doc = "Perlin noise" },
	{ name = "pow", kind = "Method", doc = "Power" },
	{ name = "rad", kind = "Method", doc = "Radians from degrees" },
	{ name = "random", kind = "Method", doc = "Random number" },
	{ name = "round", kind = "Method", doc = "Round" },
	{ name = "sign", kind = "Method", doc = "Sign of number" },
	{ name = "sin", kind = "Method", doc = "Sine" },
	{ name = "sinh", kind = "Method", doc = "Hyperbolic sine" },
	{ name = "sqrt", kind = "Method", doc = "Square root" },
	{ name = "tan", kind = "Method", doc = "Tangent" },
	{ name = "tanh", kind = "Method", doc = "Hyperbolic tangent" },
	{ name = "pi", kind = "Constant", doc = "Pi constant", value = math.pi },
	{ name = "huge", kind = "Constant", doc = "Infinity", value = math.huge },
}

-- OS library
Intellisense.OSMethods = {
	{ name = "clock", kind = "Method", doc = "CPU time" },
	{ name = "date", kind = "Method", doc = "Formatted date" },
	{ name = "difftime", kind = "Method", doc = "Time difference" },
	{ name = "time", kind = "Method", doc = "Current time" },
}

-- Task library
Intellisense.TaskMethods = {
	{ name = "cancel", kind = "Method", doc = "Cancel a task" },
	{ name = "defer", kind = "Method", doc = "Defer execution" },
	{ name = "delay", kind = "Method", doc = "Delay execution" },
	{ name = "desynchronize", kind = "Method", doc = "Desynchronize" },
	{ name = "spawn", kind = "Method", doc = "Spawn task" },
	{ name = "synchronize", kind = "Method", doc = "Synchronize" },
	{ name = "wait", kind = "Method", doc = "Wait" },
}

-- Roblox globals
Intellisense.RobloxGlobals = {
	{ name = "game", kind = "Variable", doc = "The game DataModel" },
	{ name = "workspace", kind = "Variable", doc = "The workspace" },
	{ name = "Game", kind = "Class", doc = "Game class" },
	{ name = "Workspace", kind = "Class", doc = "Workspace class" },
	{ name = "script", kind = "Variable", doc = "Current script" },
	{ name = "plugin", kind = "Variable", doc = "Current plugin (if applicable)" },
	{ name = "settings", kind = "Function", doc = "Get settings" },
	{ name = "UserSettings", kind = "Class", doc = "User settings" },
	{ name = "version", kind = "Function", doc = "Get Roblox version" },
	{ name = "printidentity", kind = "Function", doc = "Print identity" },
}

-- Roblox services (common ones)
Intellisense.RobloxServices = {
	{ name = "Players", kind = "Class", doc = "Player management service" },
	{ name = "Lighting", kind = "Class", doc = "Lighting service" },
	{ name = "ReplicatedStorage", kind = "Class", doc = "Shared storage" },
	{ name = "ReplicatedFirst", kind = "Class", doc = "First replicated content" },
	{ name = "ServerStorage", kind = "Class", doc = "Server-side storage" },
	{ name = "ServerScriptService", kind = "Class", doc = "Server scripts location" },
	{ name = "StarterGui", kind = "Class", doc = "Initial GUI for players" },
	{ name = "StarterPack", kind = "Class", doc = "Initial backpack items" },
	{ name = "StarterPlayer", kind = "Class", doc = "Player starter settings" },
	{ name = "TweenService", kind = "Class", doc = "Animation service" },
	{ name = "UserInputService", kind = "Class", doc = "Input handling" },
	{ name = "RunService", kind = "Class", doc = "Frame update service" },
	{ name = "HttpService", kind = "Class", doc = "HTTP requests" },
	{ name = "DataStoreService", kind = "Class", doc = "Data persistence" },
	{ name = "MessagingService", kind = "Class", doc = "Cross-server messaging" },
	{ name = "TeleportService", kind = "Class", doc = "Server teleportation" },
	{ name = "PhysicsService", kind = "Class", doc = "Physics management" },
	{ name = "SoundService", kind = "Class", doc = "Sound management" },
	{ name = "Chat", kind = "Class", doc = "Chat system" },
	{ name = "PathfindingService", kind = "Class", doc = "Pathfinding" },
}

-- Common Roblox Instance methods
Intellisense.InstanceMethods = {
	{ name = "Clone", kind = "Method", doc = "Clone the instance", insert = "Clone()" },
	{ name = "Destroy", kind = "Method", doc = "Destroy the instance", insert = "Destroy()" },
	{ name = "FindFirstChild", kind = "Method", doc = "Find child by name", insert = "FindFirstChild($1)" },
	{ name = "FindFirstChildOfClass", kind = "Method", doc = "Find child by class", insert = "FindFirstChildOfClass($1)" },
	{ name = "FindFirstChildWhichIsA", kind = "Method", doc = "Find child that is a class", insert = "FindFirstChildWhichIsA($1)" },
	{ name = "FindFirstAncestor", kind = "Method", doc = "Find ancestor by name", insert = "FindFirstAncestor($1)" },
	{ name = "FindFirstAncestorOfClass", kind = "Method", doc = "Find ancestor by class", insert = "FindFirstAncestorOfClass($1)" },
	{ name = "FindFirstAncestorWhichIsA", kind = "Method", doc = "Find ancestor that is a class", insert = "FindFirstAncestorWhichIsA($1)" },
	{ name = "FindFirstDescendant", kind = "Method", doc = "Find descendant by name", insert = "FindFirstDescendant($1)" },
	{ name = "GetChildren", kind = "Method", doc = "Get all children", insert = "GetChildren()" },
	{ name = "GetDescendants", kind = "Method", doc = "Get all descendants", insert = "GetDescendants()" },
	{ name = "GetParent", kind = "Method", doc = "Get parent", insert = "GetParent()" },
	{ name = "IsA", kind = "Method", doc = "Check if instance is a class", insert = "IsA($1)" },
	{ name = "IsAncestorOf", kind = "Method", doc = "Check if ancestor", insert = "IsAncestorOf($1)" },
	{ name = "IsDescendantOf", kind = "Method", doc = "Check if descendant", insert = "IsDescendantOf($1)" },
	{ name = "WaitForChild", kind = "Method", doc = "Wait for child", insert = "WaitForChild($1)" },
	{ name = "ClearAllChildren", kind = "Method", doc = "Clear all children", insert = "ClearAllChildren()" },
	{ name = "GetAttribute", kind = "Method", doc = "Get attribute", insert = "GetAttribute($1)" },
	{ name = "SetAttribute", kind = "Method", doc = "Set attribute", insert = "SetAttribute($1, $2)" },
	{ name = "GetAttributes", kind = "Method", doc = "Get all attributes", insert = "GetAttributes()" },
	{ name = "GetPropertyChangedSignal", kind = "Method", doc = "Get property change signal", insert = "GetPropertyChangedSignal($1)" },
}

-- Common Roblox Instance properties
Intellisense.InstanceProperties = {
	{ name = "Name", kind = "Property", doc = "Instance name" },
	{ name = "ClassName", kind = "Property", doc = "Instance class name" },
	{ name = "Parent", kind = "Property", doc = "Parent instance" },
	{ name = "Children", kind = "Property", doc = "Children (read-only)" },
}

-- Part-specific properties
Intellisense.PartProperties = {
	{ name = "Position", kind = "Property", doc = "World position" },
	{ name = "Rotation", kind = "Property", doc = "Rotation in degrees" },
	{ name = "Size", kind = "Property", doc = "Part size" },
	{ name = "Color", kind = "Property", doc = "Part color" },
	{ name = "Transparency", kind = "Property", doc = "Transparency (0-1)" },
	{ name = "Anchored", kind = "Property", doc = "Is anchored" },
	{ name = "CanCollide", kind = "Property", doc = "Can collide" },
	{ name = "CanTouch", kind = "Property", doc = "Can touch" },
	{ name = "Massless", kind = "Property", doc = "Is massless" },
	{ name = "Material", kind = "Property", doc = "Material type" },
	{ name = "BrickColor", kind = "Property", doc = "Brick color" },
	{ name = "CFrame", kind = "Property", doc = "Coordinate frame" },
	{ name = "Velocity", kind = "Property", doc = "Velocity vector" },
	{ name = "RotVelocity", kind = "Property", doc = "Rotational velocity" },
}

-- Instance creation (Instance.new)
Intellisense.InstanceTypes = {
	"Part", "Script", "LocalScript", "ModuleScript", "Frame", "TextButton",
	"ImageButton", "TextBox", "TextLabel", "ImageLabel", "ScrollingFrame",
	"ScreenGui", "Folder", "Model", "UnionOperation", "MeshPart", "TrussPart",
	"CornerWedgePart", "WedgePart", "SpawnLocation", "Seat", "VehicleSeat",
	"Sky", "SunRaysEffect", "ColorCorrectionEffect", "BlurEffect", "BloomEffect",
	"DepthOfFieldEffect", "Atmosphere", "Beam", "Trail", "ParticleEmitter",
	"Fire", "Smoke", "Sparkles", "PointLight", "SpotLight", "SurfaceLight",
	"ClickDetector", "Sound", "Animation", "AnimationController", "Animator",
	"Humanoid", "Camera", "Workspace", "Terrain", "Tool", "HopperBin",
	"RemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction",
	"StringValue", "NumberValue", "BoolValue", "ObjectValue", "Vector3Value",
	"Color3Value", "BrickColorValue", "CFrameValue", "IntValue", "FloatValue",
	"RayValue", "RectValue", "UDimValue", "UDim2Value", "NumberRange",
}

-- Scan game environment for children
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
		
		-- Recursively scan children
		if currentDepth < maxDepth then
			local subChildren = Intellisense.ScanInstanceChildren(child, maxDepth, currentDepth + 1)
			for _, subChild in ipairs(subChildren) do
				table.insert(children, subChild)
			end
		end
	end
	
	return children
end

-- Get cached game structure
function Intellisense.GetGameStructure()
	local now = tick()
	if now - Intellisense.Cache.LastUpdate > Intellisense.Config.CacheLifetime then
		Intellisense.Cache.GameStructure = Intellisense.ScanInstanceChildren(game, 2, 0)
		Intellisense.Cache.LastUpdate = now
	end
	return Intellisense.Cache.GameStructure
end

-- Parse code context to determine completion type
function Intellisense.ParseContext(code, cursorPosition)
	-- Get text before cursor
	local textBeforeCursor = string.sub(code, 1, cursorPosition)
	
	-- Determine context type
	local context = {
		Type = "General",
		Prefix = "",
		BaseExpression = "",
		NeedsDot = false,
		NeedsColon = false,
		NeedsIndex = false,
		MethodName = "",
	}
	
	-- Check for method call pattern: expr:method( -> GetChildren()
	local methodCallMatch = string.match(textBeforeCursor, "([%w%.%[%]\":]+):(%w+)%(%s*$")
	if methodCallMatch then
		context.Type = "MethodResult"
		context.BaseExpression = string.match(textBeforeCursor, "(.-):(%w+)%(%s*$") or ""
		context.MethodName = methodCallMatch
		return context
	end
	
	-- Check for property/index access: expr. or expr: or expr[
	local dotMatch = string.match(textBeforeCursor, "([%w%.%[%]\":]+)%.([%w_]*)$")
	if dotMatch then
		context.Type = "Property"
		context.BaseExpression = dotMatch
		context.Prefix = string.match(textBeforeCursor, "%.([%w_]*)$") or ""
		context.NeedsDot = true
		return context
	end
	
	local colonMatch = string.match(textBeforeCursor, "([%w%.%[%]\":]+):([%w_]*)$")
	if colonMatch then
		context.Type = "Method"
		context.BaseExpression = colonMatch
		context.Prefix = string.match(textBeforeCursor, ":([%w_]*)$") or ""
		context.NeedsColon = true
		return context
	end
	
	local indexMatch = string.match(textBeforeCursor, "([%w%.%[%]\":]+)%[[\"']([%w_]*)$")
	if indexMatch then
		context.Type = "Index"
		context.BaseExpression = indexMatch
		context.Prefix = string.match(textBeforeCursor, "%[[\"']([%w_]*)$") or ""
		context.NeedsIndex = true
		return context
	end
	
	-- Check for string literal completion
	local stringMatch = string.match(textBeforeCursor, "[\"']([%w_]*)$")
	if stringMatch then
		context.Type = "StringIndex"
		context.Prefix = stringMatch
		return context
	end
	
	-- General completion - just get the word being typed
	local wordMatch = string.match(textBeforeCursor, "([%w_]+)$")
	if wordMatch then
		context.Type = "General"
		context.Prefix = wordMatch
	end
	
	return context
end

-- Evaluate expression to get instance
function Intellisense.EvaluateExpression(expression)
	-- Simple expression evaluation
	-- Handle: game, workspace, game.Workspace, etc.
	
	-- Direct globals
	if expression == "game" then
		return game
	elseif expression == "workspace" then
		return workspace
	elseif expression == "script" then
		return script
	end
	
	-- Handle game.ServiceName
	local serviceMatch = string.match(expression, "^game%.(%w+)$")
	if serviceMatch then
		local success, service = pcall(function()
			return game:GetService(serviceMatch)
		end)
		if success then return service end
	end
	
	-- Handle game:GetService("ServiceName")
	local getServiceMatch = string.match(expression, 'game:GetService%([\"\''](%w+)[\"\'']%)')
	if getServiceMatch then
		local success, service = pcall(function()
			return game:GetService(getServiceMatch)
		end)
		if success then return service end
	end
	
	-- Handle workspace.ChildName
	local workspaceMatch = string.match(expression, "^workspace%.(.+)$")
	if workspaceMatch then
		local success, child = pcall(function()
			return workspace:FindFirstChild(workspaceMatch, true)
		end)
		if success then return child end
	end
	
	-- Handle game.Workspace.ChildName
	local gameWorkspaceMatch = string.match(expression, "^game%.Workspace%.(.+)$")
	if gameWorkspaceMatch then
		local success, child = pcall(function()
			return workspace:FindFirstChild(gameWorkspaceMatch, true)
		end)
		if success then return child end
	end
	
	-- Handle game.ServiceName.ChildName
	local serviceChildMatch = string.match(expression, "^game%.(%w+)%.(.+)$")
	if serviceChildMatch then
		local serviceName, childPath = serviceChildMatch, ""
		serviceName, childPath = string.match(expression, "^game%.(%w+)%.(.+)$")
		if serviceName then
			local success, result = pcall(function()
				local service = game:GetService(serviceName)
				return service:FindFirstChild(childPath, true)
			end)
			if success then return result end
		end
	end
	
	-- Handle Players.LocalPlayer
	if expression == "Players.LocalPlayer" or expression == "game.Players.LocalPlayer" then
		local player = Players.LocalPlayer
		if player then return player end
	end
	
	return nil
end

-- Get completions for method result (e.g., GetChildren())
function Intellisense.GetMethodResultCompletions(baseExpression, methodName)
	local completions = {}
	
	local instance = Intellisense.EvaluateExpression(baseExpression)
	if not instance then return completions end
	
	-- Handle GetChildren()
	if methodName == "GetChildren" then
		local success, children = pcall(function()
			return instance:GetChildren()
		end)
		
		if success and type(children) == "table" then
			local count = 0
			local maxItems = Intellisense.Config.MaxChildrenScan
			
			-- Sort by name for consistent ordering
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
				item.Detail = string.format('Click to insert: %s:GetChildren()[%d]', baseExpression, i - 1)
				item.Index = i - 1
				table.insert(completions, item)
				count = count + 1
			end
		end
	end
	
	-- Handle GetDescendants()
	if methodName == "GetDescendants" then
		local success, descendants = pcall(function()
			return instance:GetDescendants()
		end)
		
		if success and type(descendants) == "table" then
			local count = 0
			local maxItems = Intellisense.Config.MaxChildrenScan
			
			for i, descendant in ipairs(descendants) do
				if count >= maxItems then break end
				
				local item = CompletionItem.new(
					descendant.Name,
					Intellisense.CompletionKind.Instance,
					string.format("%s (Class: %s)", descendant.Name, descendant.ClassName),
					string.format("[%d]", i - 1),
					100 - count
				)
				item.Detail = string.format('Click to insert: %s:GetDescendants()[%d]', baseExpression, i - 1)
				item.Index = i - 1
				table.insert(completions, item)
				count = count + 1
			end
		end
	end
	
	return completions
end

-- Get completions for instance properties/children
function Intellisense.GetInstanceCompletions(instance, prefix, needsMethod)
	local completions = {}
	
	if not instance then return completions end
	
	local lowerPrefix = string.lower(prefix or "")
	
	-- Add instance methods if colon
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
				item.Detail = method.doc
				table.insert(completions, item)
			end
		end
		
		-- Add instance-specific methods based on class
		if instance:IsA("BasePart") then
			for _, prop in ipairs(Intellisense.PartProperties) do
				if lowerPrefix == "" or string.find(string.lower(prop.name), lowerPrefix, 1, true) then
					table.insert(completions, CompletionItem.new(
						prop.name,
						Intellisense.CompletionKind.Property,
						prop.doc,
						prop.name,
						90
					))
				end
			end
		end
	else
		-- Add children as completions
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
	
	-- Method result completions (e.g., after GetChildren())
	if context.Type == "MethodResult" then
		local methodCompletions = Intellisense.GetMethodResultCompletions(context.BaseExpression, context.MethodName)
		for _, item in ipairs(methodCompletions) do
			table.insert(completions, item)
		end
		return completions, context
	end
	
	-- Property/Method completions
	if context.Type == "Property" or context.Type == "Method" then
		local instance = Intellisense.EvaluateExpression(context.BaseExpression)
		if instance then
			local instanceCompletions = Intellisense.GetInstanceCompletions(
				instance,
				context.Prefix,
				context.NeedsColon
			)
			for _, item in ipairs(instanceCompletions) do
				table.insert(completions, item)
			end
		end
		return completions, context
	end
	
	-- String index completions
	if context.Type == "StringIndex" or context.Type == "Index" then
		-- Try to get children of the base expression
		local baseExpr = context.BaseExpression
		if baseExpr and baseExpr ~= "" then
			local instance = Intellisense.EvaluateExpression(baseExpr)
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
		end
		return completions, context
	end
	
	-- General completions
	local lowerPrefix = string.lower(context.Prefix)
	
	-- Add keywords
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
	
	-- Add builtins
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
	
	-- Add Roblox globals
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
	
	-- Add Roblox services
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
	
	-- Add environment variables (from user's code)
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
	
	-- Add string methods
	if lowerPrefix ~= "" then
		for _, method in ipairs(Intellisense.StringMethods) do
			if string.find(string.lower(method.name), lowerPrefix, 1, true) then
				table.insert(completions, CompletionItem.new(
					"string." .. method.name,
					Intellisense.CompletionKind.Method,
					method.doc,
					"string." .. method.name .. "()",
					70
				))
			end
		end
	end
	
	-- Sort by priority and name
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

-- Extract variables from code (for local variable intellisense)
function Intellisense.ExtractVariables(code, cursorPosition)
	local variables = {}
	local textBeforeCursor = string.sub(code, 1, cursorPosition)
	
	-- Find local variable declarations
	for varName in string.gmatch(textBeforeCursor, "local%s+([%w_]+)%s*=") do
		variables[varName] = { doc = "Local variable" }
	end
	
	-- Find function parameters
	for params in string.gmatch(textBeforeCursor, "function%s+[%w_.:]+%(([^)]*)%)") do
		for param in string.gmatch(params, "([%w_]+)") do
			if param ~= "" then
				variables[param] = { doc = "Function parameter" }
			end
		end
	end
	
	-- Find for loop variables
	for varName in string.gmatch(textBeforeCursor, "for%s+([%w_]+)%s*=") do
		variables[varName] = { doc = "Loop variable" }
	end
	
	for varName in string.gmatch(textBeforeCursor, "for%s+([%w_]+),%s*([%w_]+)%s+in") do
		variables[varName] = { doc = "Loop variable" }
	end
	
	return variables
end

return Intellisense
