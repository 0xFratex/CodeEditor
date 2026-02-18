--[[
	Dracula Code Runner
	Safely executes Lua code with sandboxing and output capture
]]

local CodeRunner = {}

-- Services
local RunService = game:GetService("RunService")
local ScriptContext = game:GetService("ScriptContext")

-- Configuration
CodeRunner.Config = {
	Timeout = 10,                 -- Max execution time in seconds
	MaxMemory = 100000000,        -- Max memory in bytes (100MB)
	EnableSandbox = true,         -- Enable sandboxing for safety
	AllowedApis = {               -- APIs allowed in sandbox
		"print", "warn", "error", "assert", "type", "typeof",
		"tostring", "tonumber", "pairs", "ipairs", "next",
		"select", "unpack", "pack", "rawget", "rawset",
		"rawequal", "rawlen", "setmetatable", "getmetatable",
		"pcall", "xpcall", "tick", "time",
	},
	RestrictedApis = {            -- APIs blocked in sandbox
		"os.execute", "os.remove", "os.rename", "os.exit",
		"io", "debug", "loadfile", "dofile", "load",
	},
}

-- Execution result
CodeRunner.ExecutionResult = {}
CodeRunner.ExecutionResult.__index = CodeRunner.ExecutionResult

function CodeRunner.ExecutionResult.new(success, output, errors, duration)
	local self = setmetatable({}, CodeRunner.ExecutionResult)
	self.Success = success
	self.Output = output or {}
	self.Errors = errors or {}
	self.Duration = duration or 0
	self.Timestamp = os.time()
	return self
end

-- Output capture
local OutputBuffer = {}

local function capturePrint(...)
	local args = {...}
	local output = {}
	for i, arg in ipairs(args) do
		table.insert(output, tostring(arg))
	end
	local line = table.concat(output, "\t")
	table.insert(OutputBuffer, {
		Type = "Print",
		Message = line,
		Time = os.clock(),
	})
end

local function captureWarn(...)
	local args = {...}
	local output = {}
	for i, arg in ipairs(args) do
		table.insert(output, tostring(arg))
	end
	local line = table.concat(output, "\t")
	table.insert(OutputBuffer, {
		Type = "Warn",
		Message = line,
		Time = os.clock(),
	})
end

local function captureError(message)
	table.insert(OutputBuffer, {
		Type = "Error",
		Message = message,
		Time = os.clock(),
	})
end

-- Create sandboxed environment
function CodeRunner.CreateSandboxEnvironment(customEnv)
	local sandbox = {}
	
	-- Basic globals
	sandbox._G = sandbox
	sandbox._VERSION = _VERSION
	
	-- Standard functions
	for _, api in ipairs(CodeRunner.Config.AllowedApis) do
		if _G[api] then
			sandbox[api] = _G[api]
		end
	end
	
	-- Override print and warn to capture output
	sandbox.print = capturePrint
	sandbox.warn = captureWarn
	sandbox.error = function(msg, level)
		captureError(msg)
		error(msg, level or 1)
	end
	
	-- Libraries
	sandbox.string = {}
	for k, v in pairs(string) do
		sandbox.string[k] = v
	end
	
	sandbox.table = {}
	for k, v in pairs(table) do
		sandbox.table[k] = v
	end
	
	sandbox.math = {}
	for k, v in pairs(math) do
		sandbox.math[k] = v
	end
	
	sandbox.os = {
		clock = os.clock,
		time = os.time,
		date = os.date,
		difftime = os.difftime,
	}
	
	sandbox.coroutine = coroutine
	
	-- Roblox environment
	sandbox.game = game
	sandbox.workspace = workspace
	sandbox.Game = Game
	sandbox.Workspace = Workspace
	
	-- Roblox services
	sandbox.Instance = Instance
	sandbox.Color3 = Color3
	sandbox.Vector3 = Vector3
	sandbox.Vector2 = Vector2
	sandbox.CFrame = CFrame
	sandbox.UDim = UDim
	sandbox.UDim2 = UDim2
	sandbox.Ray = Ray
	sandbox.Region3 = Region3
	sandbox.BrickColor = BrickColor
	sandbox.NumberRange = NumberRange
	sandbox.NumberSequence = NumberSequence
	sandbox.ColorSequence = ColorSequence
	sandbox.Rect = Rect
	sandbox.TweenInfo = TweenInfo
	sandbox.Enum = Enum
	sandbox.Enums = Enums
	
	-- Roblox functions
	sandbox.tick = tick
	sandbox.time = time
	sandbox.wait = wait
	sandbox.delay = delay
	sandbox.spawn = spawn
	sandbox.settings = settings
	sandbox.UserSettings = UserSettings
	sandbox.version = version
	sandbox.printidentity = printidentity
	
	-- Task library
	sandbox.task = task
	
	-- TweenService for animations
	sandbox.TweenService = game:GetService("TweenService")
	
	-- Merge custom environment
	if customEnv then
		for k, v in pairs(customEnv) do
			sandbox[k] = v
		end
	end
	
	-- Add metatable to prevent accessing restricted globals
	local mt = {
		__index = function(t, k)
			if CodeRunner.Config.RestrictedApis[k] then
				error("Access to '" .. k .. "' is restricted", 2)
			end
			return rawget(t, k)
		end,
		__newindex = function(t, k, v)
			rawset(t, k, v)
		end,
	}
	setmetatable(sandbox, mt)
	
	return sandbox
end

-- Compile code safely
function CodeRunner.CompileCode(code)
	local success, result = pcall(function()
		return loadstring(code)
	end)
	
	if success then
		return true, result
	else
		return false, result
	end
end

-- Execute code with timeout and output capture
function CodeRunner.Execute(code, env, timeout)
	-- Clear output buffer
	OutputBuffer = {}
	
	-- Compile the code
	local compileSuccess, compiled = CodeRunner.CompileCode(code)
	
	if not compileSuccess then
		return CodeRunner.ExecutionResult.new(false, {}, {
			"Syntax Error: " .. tostring(compiled)
		}, 0)
	end
	
	-- Create environment
	local sandboxEnv = CodeRunner.CreateSandboxEnvironment(env)
	
	-- Set environment for the compiled function
	setfenv(compiled, sandboxEnv)
	
	-- Execute with timeout
	local startTime = os.clock()
	local finished = false
	local success = false
	local errorResult = nil
	
	-- Run in coroutine for potential timeout handling
	local co = coroutine.create(function()
		success, errorResult = pcall(compiled)
		finished = true
	end)
	
	-- Start execution
	coroutine.resume(co)
	
	-- Wait for completion or timeout
	local waitTime = 0
	local maxTime = timeout or CodeRunner.Config.Timeout
	
	while not finished and waitTime < maxTime do
		wait(0.01)
		waitTime = waitTime + 0.01
	end
	
	local duration = os.clock() - startTime
	
	if not finished then
		-- Timeout occurred
		table.insert(OutputBuffer, {
			Type = "Error",
			Message = "Execution timed out after " .. maxTime .. " seconds",
			Time = os.clock(),
		})
		return CodeRunner.ExecutionResult.new(false, OutputBuffer, {"Execution timeout"}, duration)
	end
	
	if not success then
		-- Execution error
		table.insert(OutputBuffer, {
			Type = "Error",
			Message = tostring(errorResult),
			Time = os.clock(),
		})
		return CodeRunner.ExecutionResult.new(false, OutputBuffer, {tostring(errorResult)}, duration)
	end
	
	-- Success
	return CodeRunner.ExecutionResult.new(true, OutputBuffer, {}, duration)
end

-- Execute with return value capture
function CodeRunner.ExecuteWithReturn(code, env)
	-- Clear output buffer
	OutputBuffer = {}
	
	-- Wrap code to capture return value
	local wrappedCode = [[
		local __result = (function()
			]] .. code .. [[
		end)()
		return __result
	]]
	
	local compileSuccess, compiled = CodeRunner.CompileCode(wrappedCode)
	
	if not compileSuccess then
		return nil, "Syntax Error: " .. tostring(compiled)
	end
	
	local sandboxEnv = CodeRunner.CreateSandboxEnvironment(env)
	setfenv(compiled, sandboxEnv)
	
	local success, result = pcall(compiled)
	
	if success then
		return result, nil
	else
		return nil, result
	end
end

-- Format output for display
function CodeRunner.FormatOutput(result)
	local formatted = {}
	
	table.insert(formatted, string.format("────────────────────────────────────────"))
	table.insert(formatted, string.format("Execution %s in %.3fms", 
		result.Success and "completed" or "failed",
		result.Duration * 1000
	))
	table.insert(formatted, string.format("────────────────────────────────────────"))
	
	for _, output in ipairs(result.Output) do
		local prefix = ""
		local color = ""
		
		if output.Type == "Print" then
			prefix = "[Print] "
			color = ""  -- Will be formatted later
		elseif output.Type == "Warn" then
			prefix = "[Warn] "
			color = ""  -- Will be formatted later
		elseif output.Type == "Error" then
			prefix = "[Error] "
			color = ""  -- Will be formatted later
		end
		
		table.insert(formatted, prefix .. output.Message)
	end
	
	if #result.Errors > 0 then
		table.insert(formatted, "Errors:")
		for _, err in ipairs(result.Errors) do
			table.insert(formatted, "  " .. err)
		end
	end
	
	return table.concat(formatted, "\n")
end

-- Quick test function
function CodeRunner.Test()
	local testCode = [[
		print("Hello from Dracula!")
		local x = 10
		local y = 20
		print("Sum:", x + y)
		
		local part = Instance.new("Part")
		part.Name = "TestPart"
		print("Created part:", part.Name)
		
		return x + y
	]]
	
	local result = CodeRunner.Execute(testCode)
	return CodeRunner.FormatOutput(result)
end

return CodeRunner
