--[[
	Dracula Editor Utilities
	Additional helper functions and developer tools
	
	Uses _G.DraculaTheme (loaded by Loader.lua)
]]

local Utilities = {}

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Get Theme from _G (loaded by Loader.lua)
local Theme = _G.DraculaTheme

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

-- Get auto-indent for new line
function Utilities.GetAutoIndent(text, cursorPosition)
	local lineText = Utilities.GetLineAtPosition(text, cursorPosition)
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
	
	return string.rep("    ", math.floor(indent / 4))
end

-- ============================================
-- Code Analysis
-- ============================================

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
	
	return variables
end

-- ============================================
-- Code Templates
-- ============================================

Utilities.Templates = {
	Function = "function name(params)\n\t-- body\nend\n",
	LocalFunction = "local function name(params)\n\t-- body\nend\n",
	Module = "local Module = {}\n\nfunction Module:Method()\n\t\nend\n\nreturn Module\n",
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

return Utilities
