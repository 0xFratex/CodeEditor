--[[
	Dracula Editor Utilities
	Additional helper functions and developer tools
]]

local Utilities = {}

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Theme
local Theme = require(script.Parent:WaitForChild("DraculaTheme"))

-- ============================================
-- Text Processing Utilities
-- ============================================

-- Get word at position
function Utilities.GetWordAtPosition(text, position)
	local wordStart = position
	local wordEnd = position
	
	-- Find word start
	while wordStart > 1 do
		local char = string.sub(text, wordStart - 1, wordStart - 1)
		if not char:match("[%w_]") then
			break
		end
		wordStart = wordStart - 1
	end
	
	-- Find word end
	while wordEnd <= #text do
		local char = string.sub(text, wordEnd, wordEnd)
		if not char:match("[%w_]") then
			break
		end
		wordEnd = wordEnd + 1
	end
	
	return string.sub(text, wordStart, wordEnd - 1), wordStart, wordEnd - 1
end

-- Get line at position
function Utilities.GetLineAtPosition(text, position)
	local lineStart = position
	local lineEnd = position
	
	-- Find line start
	while lineStart > 1 do
		local char = string.sub(text, lineStart - 1, lineStart - 1)
		if char == "\n" then
			break
		end
		lineStart = lineStart - 1
	end
	
	-- Find line end
	while lineEnd <= #text do
		local char = string.sub(text, lineEnd, lineEnd)
		if char == "\n" then
			break
		end
		lineEnd = lineEnd + 1
	end
	
	return string.sub(text, lineStart, lineEnd - 1), lineStart, lineEnd - 1
end

-- Get line number from position
function Utilities.GetLineNumber(text, position)
	local count = 1
	for i = 1, position - 1 do
		if string.sub(text, i, i) == "\n" then
			count = count + 1
		end
	end
	return count
end

-- Get position from line and column
function Utilities.GetPositionFromLineColumn(text, line, column)
	local currentLine = 1
	local currentColumn = 1
	
	for i = 1, #text do
		if currentLine == line and currentColumn == column then
			return i
		end
		
		local char = string.sub(text, i, i)
		if char == "\n" then
			currentLine = currentLine + 1
			currentColumn = 1
		else
			currentColumn = currentColumn + 1
		end
	end
	
	return #text
end

-- Count indentation
function Utilities.CountIndentation(line)
	local count = 0
	for i = 1, #line do
		local char = string.sub(line, i, i)
		if char == " " then
			count = count + 1
		elseif char == "\t" then
			count = count + 4
		else
			break
		end
	end
	return count
end

-- Auto-close brackets
function Utilities.GetClosingBracket(openBracket)
	local brackets = {
		["("] = ")",
		["["] = "]",
		["{"] = "}",
		['"'] = '"',
		["'"] = "'",
	}
	return brackets[openBracket]
end

-- Check if should auto-close
function Utilities.ShouldAutoClose(char, textBefore, textAfter)
	if not Utilities.GetClosingBracket(char) then
		return false
	end
	
	-- Don't auto-close if we're in a string
	local inString = false
	local stringChar = nil
	for i = 1, #textBefore do
		local c = string.sub(textBefore, i, i)
		if inString then
			if c == stringChar and string.sub(textBefore, i - 1, i - 1) ~= "\\" then
				inString = false
			end
		else
			if c == '"' or c == "'" then
				inString = true
				stringChar = c
			end
		end
	end
	
	return not inString
end

-- ============================================
-- Bracket Matching
-- ============================================

-- Find matching bracket
function Utilities.FindMatchingBracket(text, position)
	local char = string.sub(text, position, position)
	
	local openBrackets = { ["("] = ")", ["["] = "]", ["{"] = "}" }
	local closeBrackets = { [")"] = "(", ["]"] = "[", ["}"] = "{" }
	
	if openBrackets[char] then
		return Utilities.FindClosingBracket(text, position, char, openBrackets[char])
	elseif closeBrackets[char] then
		return Utilities.FindOpeningBracket(text, position, char, closeBrackets[char])
	end
	
	return nil
end

function Utilities.FindClosingBracket(text, start, openBracket, closeBracket)
	local count = 1
	local pos = start + 1
	local inString = false
	local stringChar = nil
	
	while pos <= #text and count > 0 do
		local char = string.sub(text, pos, pos)
		
		if inString then
			if char == stringChar and string.sub(text, pos - 1, pos - 1) ~= "\\" then
				inString = false
			end
		else
			if char == '"' or char == "'" then
				inString = true
				stringChar = char
			elseif char == openBracket then
				count = count + 1
			elseif char == closeBracket then
				count = count - 1
			end
		end
		
		pos = pos + 1
	end
	
	return count == 0 and pos - 1 or nil
end

function Utilities.FindOpeningBracket(text, start, closeBracket, openBracket)
	local count = 1
	local pos = start - 1
	local inString = false
	local stringChar = nil
	
	while pos >= 1 and count > 0 do
		local char = string.sub(text, pos, pos)
		
		if inString then
			if char == stringChar and (pos == 1 or string.sub(text, pos - 1, pos - 1) ~= "\\") then
				inString = false
			end
		else
			if char == '"' or char == "'" then
				inString = true
				stringChar = char
			elseif char == closeBracket then
				count = count + 1
			elseif char == openBracket then
				count = count - 1
			end
		end
		
		pos = pos - 1
	end
	
	return count == 0 and pos + 1 or nil
end

-- ============================================
-- Code Formatting
-- ============================================

-- Format code with proper indentation
function Utilities.FormatCode(code)
	local lines = {}
	local indentLevel = 0
	local tabWidth = 4
	
	for line in string.gmatch(code .. "\n", "([^\n]*)\n") do
		-- Strip existing indentation
		local stripped = line:match("^%s*(.*)") or ""
		
		-- Decrease indent for closing keywords
		if stripped:match("^end") or 
		   stripped:match("^else") or 
		   stripped:match("^elseif") or 
		   stripped:match("^until") or
		   stripped:match("^}") then
			indentLevel = math.max(0, indentLevel - 1)
		end
		
		-- Add proper indentation
		local newLine = string.rep("    ", indentLevel) .. stripped
		table.insert(lines, newLine)
		
		-- Increase indent for opening keywords
		if stripped:match("then%s*$") or 
		   stripped:match("do%s*$") or 
		   stripped:match("else%s*$") or 
		   stripped:match("function%s*%(") or
		   stripped:match("{%s*$") then
			indentLevel = indentLevel + 1
		end
	end
	
	return table.concat(lines, "\n")
end

-- Get auto-indent for new line
function Utilities.GetAutoIndent(text, cursorPosition)
	local lineText, lineStart = Utilities.GetLineAtPosition(text, cursorPosition)
	local stripped = lineText:match("^%s*(.*)") or ""
	
	-- Count current indentation
	local indent = 0
	for i = 1, #lineText do
		local char = string.sub(lineText, i, i)
		if char == " " then
			indent = indent + 1
		elseif char == "\t" then
			indent = indent + 4
		else
			break
		end
	end
	
	-- Check if we need more indentation
	if stripped:match("then%s*$") or 
	   stripped:match("do%s*$") or 
	   stripped:match("else%s*$") or 
	   stripped:match("function%s*%(") or
	   stripped:match("{%s*$") then
		indent = indent + 4
	end
	
	-- Check if we need less indentation
	if stripped:match("^end") or 
	   stripped:match("^else") or 
	   stripped:match("^elseif") or 
	   stripped:match("^until") or
	   stripped:match("^}") then
		indent = math.max(0, indent - 4)
	end
	
	return string.rep("    ", math.floor(indent / 4))
end

-- ============================================
-- Code Analysis
-- ============================================

-- Find all function definitions
function Utilities.FindFunctions(code)
	local functions = {}
	
	for name, params in code:gmatch("function%s+([%w_.:]+)%s*%(([^)]*)%)") do
		table.insert(functions, {
			name = name,
			params = params,
			type = "global"
		})
	end
	
	for name, params in code:gmatch("local%s+function%s+([%w_]+)%s*%(([^)]*)%)") do
		table.insert(functions, {
			name = name,
			params = params,
			type = "local"
		})
	end
	
	return functions
end

-- Find all variables
function Utilities.FindVariables(code)
	local variables = {}
	
	-- Local variables
	for name in code:gmatch("local%s+([%w_]+)%s*=") do
		variables[name] = "local"
	end
	
	-- Function parameters
	for params in code:gmatch("function%s+[%w_.:]+%s*%(([^)]*)%)") do
		for param in params:gmatch("([%w_]+)") do
			variables[param] = "parameter"
		end
	end
	
	-- For loop variables
	for var in code:gmatch("for%s+([%w_]+)%s*=") do
		variables[var] = "loop"
	end
	
	for var in code:gmatch("for%s+([%w_]+)%s*,%s*([%w_]+)%s+in") do
		variables[var] = "loop"
	end
	
	return variables
end

-- Find all require statements
function Utilities.FindRequires(code)
	local requires = {}
	
	for modulePath in code:gmatch("require%s*%(([^)]+)%)") do
		table.insert(requires, modulePath)
	end
	
	return requires
end

-- ============================================
-- Code Templates
-- ============================================

Utilities.Templates = {
	-- Function template
	Function = [[
function name(params)
	-- body
end
]],
	
	-- Local function template
	LocalFunction = [[
local function name(params)
	-- body
end
]],
	
	-- Module template
	Module = [[
local Module = {}

-- Private variables
local privateVar = nil

-- Public methods
function Module:Method()
	
end

return Module
]],
	
	-- Class template (OOP pattern)
	Class = [[
local ClassName = {}
ClassName.__index = ClassName

function ClassName.new(...)
	local self = setmetatable({}, ClassName)
	self:constructor(...)
	return self
end

function ClassName:constructor()
	
end

return ClassName
]],
	
	-- Event handler template
	EventHandler = [[
local function onEvent()
	
end

event:Connect(onEvent)
]],
	
	-- Remote event template
	RemoteEvent = [[
local RemoteEvent = game.ReplicatedStorage:WaitForChild("RemoteEvent")

-- Fire from client
RemoteEvent:FireServer(args)

-- Or handle on server
RemoteEvent.OnServerEvent:Connect(function(player, ...)
	
end)
]],
	
	-- Remote function template
	RemoteFunction = [[
local RemoteFunction = game.ReplicatedStorage:WaitForChild("RemoteFunction")

-- Invoke from client
local result = RemoteFunction:InvokeServer(args)

-- Or handle on server
RemoteFunction.OnServerInvoke = function(player, ...)
	
end
]],
}

-- ============================================
-- Snippets
-- ============================================

Utilities.Snippets = {
	-- Print with timestamp
	tprint = {
		trigger = "tprint",
		body = 'print(string.format("[%s] %s", os.date("%H:%M:%S"), ${1:message}))',
		description = "Print with timestamp"
	},
	
	-- For pairs loop
	pairs = {
		trigger = "pairs",
		body = "for ${1:key}, ${2:value} in pairs(${3:table}) do\n\t${0}\nend",
		description = "For pairs loop"
	},
	
	-- For ipairs loop
	ipairs = {
		trigger = "ipairs",
		body = "for ${1:i}, ${2:value} in ipairs(${3:table}) do\n\t${0}\nend",
		description = "For ipairs loop"
	},
	
	-- Try-catch pattern
	try = {
		trigger = "try",
		body = "local success, result = pcall(function()\n\t${0}\nend)\nif not success then\n\twarn(result)\nend",
		description = "Pcall try-catch pattern"
	},
	
	-- Instance.new
	instance = {
		trigger = "instance",
		body = 'local ${1:name} = Instance.new("${2:Part}")\n${1:name}.Parent = ${3:workspace}',
		description = "Create new Instance"
	},
	
	-- Wait for child
	wait = {
		trigger = "wfc",
		body = 'local ${1:child} = ${2:parent}:WaitForChild("${3:ChildName}")',
		description = "WaitForChild"
	},
	
	-- Find child
	find = {
		trigger = "ffc",
		body = 'local ${1:child} = ${2:parent}:FindFirstChild("${3:ChildName}")',
		description = "FindFirstChild"
	},
}

-- ============================================
-- Performance Utilities
-- ============================================

-- Debounce function
function Utilities.Debounce(func, delay)
	local lastCall = 0
	local scheduled = nil
	
	return function(...)
		local args = {...}
		local now = tick()
		
		if now - lastCall < delay then
			if scheduled then
				scheduled:Cancel()
			end
			
			scheduled = task.delay(delay - (now - lastCall), function()
				lastCall = tick()
				func(unpack(args))
			end)
		else
			lastCall = now
			func(unpack(args))
		end
	end
end

-- Throttle function
function Utilities.Throttle(func, delay)
	local lastCall = 0
	
	return function(...)
		local now = tick()
		
		if now - lastCall >= delay then
			lastCall = now
			return func(...)
		end
		
		return nil
	end
end

-- ============================================
-- UI Helpers
-- ============================================

-- Animate frame
function Utilities.Tween(frame, properties, duration, easingStyle, easingDirection)
	duration = duration or 0.3
	easingStyle = easingStyle or Enum.EasingStyle.Quad
	easingDirection = easingDirection or Enum.EasingDirection.Out
	
	local tween = TweenService:Create(
		frame,
		TweenInfo.new(duration, easingStyle, easingDirection),
		properties
	)
	tween:Play()
	return tween
end

-- Fade in
function Utilities.FadeIn(frame, duration)
	frame.BackgroundTransparency = 1
	return Utilities.Tween(frame, { BackgroundTransparency = 0 }, duration)
end

-- Fade out
function Utilities.FadeOut(frame, duration)
	return Utilities.Tween(frame, { BackgroundTransparency = 1 }, duration)
end

-- Slide in
function Utilities.SlideIn(frame, direction, duration)
	local startPos
	
	if direction == "left" then
		startPos = UDim2.new(-1, 0, frame.Position.Y.Scale, frame.Position.Y.Offset)
	elseif direction == "right" then
		startPos = UDim2.new(1, 0, frame.Position.Y.Scale, frame.Position.Y.Offset)
	elseif direction == "top" then
		startPos = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, -1, 0)
	elseif direction == "bottom" then
		startPos = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, 1, 0)
	end
	
	frame.Position = startPos
	return Utilities.Tween(frame, { Position = frame.Position }, duration)
end

return Utilities
