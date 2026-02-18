--[[
	Dracula Editor Utilities
	Additional helper functions
]]

local Utilities = {}

-- Services
local TweenService = game:GetService("TweenService")

-- Get Theme from global storage
local function getTheme()
	local editor = _G.DraculaEditor
	if editor and editor.Theme then
		return editor.Theme
	end
	return {
		Colors = {
			Selection = Color3.fromRGB(68, 71, 90),
			BackgroundLight = Color3.fromRGB(68, 71, 90),
		}
	}
end

-- Get word at position
function Utilities.GetWordAtPosition(text, position)
	local wordStart = position
	local wordEnd = position
	
	while wordStart > 1 and string.sub(text, wordStart - 1, wordStart - 1):match("[%w_]") do
		wordStart = wordStart - 1
	end
	
	while wordEnd <= #text and string.sub(text, wordEnd, wordEnd):match("[%w_]") do
		wordEnd = wordEnd + 1
	end
	
	return string.sub(text, wordStart, wordEnd - 1), wordStart, wordEnd - 1
end

-- Get line at position
function Utilities.GetLineAtPosition(text, position)
	local lineStart = position
	local lineEnd = position
	
	while lineStart > 1 and string.sub(text, lineStart - 1, lineStart - 1) ~= "\n" do
		lineStart = lineStart - 1
	end
	
	while lineEnd <= #text and string.sub(text, lineEnd, lineEnd) ~= "\n" do
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

-- Get auto-indent for new line
function Utilities.GetAutoIndent(text, cursorPosition)
	local lineText = Utilities.GetLineAtPosition(text, cursorPosition)
	
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
	
	local stripped = lineText:match("^%s*(.*)") or ""
	
	if stripped:match("then%s*$") or stripped:match("do%s*$") or 
	   stripped:match("else%s*$") or stripped:match("function%s*%(") or
	   stripped:match("{%s*$") then
		indent = indent + 4
	end
	
	return string.rep("    ", math.floor(indent / 4))
end

-- Bracket matching
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
	
	while pos <= #text and count > 0 do
		local char = string.sub(text, pos, pos)
		if char == openBracket then count = count + 1
		elseif char == closeBracket then count = count - 1
		end
		pos = pos + 1
	end
	
	return count == 0 and pos - 1 or nil
end

function Utilities.FindOpeningBracket(text, start, closeBracket, openBracket)
	local count = 1
	local pos = start - 1
	
	while pos >= 1 and count > 0 do
		local char = string.sub(text, pos, pos)
		if char == closeBracket then count = count + 1
		elseif char == openBracket then count = count - 1
		end
		pos = pos - 1
	end
	
	return count == 0 and pos + 1 or nil
end

-- Debounce
function Utilities.Debounce(func, delay)
	local lastCall = 0
	return function(...)
		local now = tick()
		if now - lastCall >= delay then
			lastCall = now
			return func(...)
		end
	end
end

-- Throttle
function Utilities.Throttle(func, delay)
	local lastCall = 0
	return function(...)
		local now = tick()
		if now - lastCall >= delay then
			lastCall = now
			return func(...)
		end
	end
end

-- Tween
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
