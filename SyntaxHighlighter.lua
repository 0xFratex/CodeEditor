--[[
	Dracula Syntax Highlighter
	Provides syntax highlighting for Lua code with Dracula theme colors
	
	Uses _G.DraculaTheme (loaded by Loader.lua)
]]

local SyntaxHighlighter = {}

-- Get Theme from _G (loaded by Loader.lua)
local Theme = _G.DraculaTheme

-- Token types
local TokenType = {
	Keyword = "Keyword",
	String = "String",
	Number = "Number",
	Comment = "Comment",
	Operator = "Operator",
	Identifier = "Identifier",
	Builtin = "Builtin",
	Property = "Property",
	Method = "Method",
	Function = "Function",
	Punctuation = "Punctuation",
	Whitespace = "Whitespace",
}

-- Lua keywords
local Keywords = {
	["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
	["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
	["function"] = true, ["if"] = true, ["in"] = true, ["local"] = true,
	["nil"] = true, ["not"] = true, ["or"] = true, ["repeat"] = true,
	["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true,
	["while"] = true, ["continue"] = true, ["type"] = true, ["export"] = true,
}

-- Lua built-in functions
local Builtins = {
	["print"] = true, ["warn"] = true, ["error"] = true, ["assert"] = true,
	["type"] = true, ["typeof"] = true, ["tostring"] = true, ["tonumber"] = true,
	["pairs"] = true, ["ipairs"] = true, ["next"] = true, ["select"] = true,
	["unpack"] = true, ["pack"] = true, ["rawget"] = true, ["rawset"] = true,
	["rawequal"] = true, ["rawlen"] = true, ["setmetatable"] = true,
	["getmetatable"] = true, ["pcall"] = true, ["xpcall"] = true,
	["tick"] = true, ["time"] = true, ["wait"] = true, ["delay"] = true,
	["spawn"] = true, ["coroutine"] = true, ["string"] = true, ["table"] = true,
	["math"] = true, ["os"] = true, ["debug"] = true, ["task"] = true,
	["Instance"] = true, ["Color3"] = true, ["Vector3"] = true, ["Vector2"] = true,
	["CFrame"] = true, ["UDim"] = true, ["UDim2"] = true, ["Ray"] = true,
	["Region3"] = true, ["BrickColor"] = true, ["NumberRange"] = true,
	["NumberSequence"] = true, ["ColorSequence"] = true, ["Rect"] = true,
	["TweenInfo"] = true, ["Enum"] = true, ["Enums"] = true,
}

-- Roblox globals
local RobloxGlobals = {
	["game"] = true, ["workspace"] = true, ["Game"] = true, ["Workspace"] = true,
	["script"] = true, ["plugin"] = true, ["settings"] = true,
	["UserSettings"] = true, ["version"] = true, ["printidentity"] = true,
}

-- Operators
local Operators = {
	["+"] = true, ["-"] = true, ["*"] = true, ["/"] = true, ["%"] = true,
	["^"] = true, ["#"] = true, ["=="] = true, ["~="] = true, ["<="] = true,
	[">="] = true, ["<"] = true, [">"] = true, ["="] = true, [".."] = true,
	["..."] = true, ["::"] = true,
}

-- Token class
local Token = {}
Token.__index = Token

function Token.new(type, value, start, finish)
	local self = setmetatable({}, Token)
	self.Type = type
	self.Value = value
	self.Start = start or 0
	self.Finish = finish or 0
	return self
end

SyntaxHighlighter.Token = Token

-- Lexer: tokenize Lua code
function SyntaxHighlighter.Tokenize(code)
	local tokens = {}
	local pos = 1
	local len = #code
	
	local function peek(offset)
		offset = offset or 0
		return string.sub(code, pos + offset, pos + offset)
	end
	
	local function consume()
		local char = string.sub(code, pos, pos)
		pos = pos + 1
		return char
	end
	
	while pos <= len do
		local startPos = pos
		local char = peek()
		
		-- Whitespace
		if char:match("%s") then
			local whitespace = ""
			while pos <= len and peek():match("%s") do
				whitespace = whitespace .. consume()
			end
			table.insert(tokens, Token.new(TokenType.Whitespace, whitespace, startPos, pos - 1))
		
		-- Comments
		elseif char == "-" and peek(1) == "-" then
			local comment = ""
			consume() consume() -- consume --
			
			-- Check for multi-line comment
			if peek() == "[" and peek(1) == "[" then
				consume() consume() -- consume [[
				comment = "--[["
				while pos <= len do
					if peek() == "]" and peek(1) == "]" then
						consume() consume()
						comment = comment .. "]]"
						break
					end
					comment = comment .. consume()
				end
			else
				-- Single line comment
				while pos <= len and peek() ~= "\n" do
					comment = comment .. consume()
				end
			end
			table.insert(tokens, Token.new(TokenType.Comment, comment, startPos, pos - 1))
		
		-- Multi-line strings
		elseif char == "[" and (peek(1) == "[" or peek(1) == "=") then
			local str = ""
			consume() -- consume first [
			
			-- Find the closing bracket pattern
			local equals = ""
			while peek() == "=" do
				equals = equals .. consume()
			end
			if peek() == "[" then
				consume() -- consume second [
				str = "[" .. equals .. "["
				
				-- Read until closing bracket
				while pos <= len do
					if peek() == "]" then
						-- Check if it matches
						local nextEquals = ""
						local tempPos = pos + 1
						while string.sub(code, tempPos, tempPos) == "=" do
							nextEquals = nextEquals .. string.sub(code, tempPos, tempPos)
							tempPos = tempPos + 1
						end
						if nextEquals == equals and string.sub(code, tempPos, tempPos) == "]" then
							-- Found closing
							str = str .. consume() -- ]
							for _ = 1, #equals do
								str = str .. consume()
							end
							str = str .. consume() -- ]
							break
						end
					end
					str = str .. consume()
				end
			end
			table.insert(tokens, Token.new(TokenType.String, str, startPos, pos - 1))
		
		-- Strings
		elseif char == '"' or char == "'" then
			local quote = consume()
			local str = quote
			local escaped = false
			
			while pos <= len do
				local c = peek()
				if escaped then
					str = str .. consume()
					escaped = false
				elseif c == "\\" then
					str = str .. consume()
					escaped = true
				elseif c == quote then
					str = str .. consume()
					break
				elseif c == "\n" then
					break
				else
					str = str .. consume()
				end
			end
			table.insert(tokens, Token.new(TokenType.String, str, startPos, pos - 1))
		
		-- Numbers
		elseif char:match("%d") then
			local num = ""
			
			-- Hexadecimal
			if char == "0" and peek(1):lower() == "x" then
				num = consume() .. consume()
				while pos <= len and peek():match("[%x]") do
					num = num .. consume()
				end
			else
				-- Decimal
				while pos <= len and peek():match("%d") do
					num = num .. consume()
				end
				if pos <= len and peek() == "." and peek(1):match("%d") then
					num = num .. consume()
					while pos <= len and peek():match("%d") do
						num = num .. consume()
					end
				end
				if pos <= len and peek():lower() == "e" then
					num = num .. consume()
					if pos <= len and (peek() == "+" or peek() == "-") then
						num = num .. consume()
					end
					while pos <= len and peek():match("%d") do
						num = num .. consume()
					end
				end
			end
			table.insert(tokens, Token.new(TokenType.Number, num, startPos, pos - 1))
		
		-- Identifiers and keywords
		elseif char:match("[%a_]") then
			local id = ""
			while pos <= len and peek():match("[%w_]") do
				id = id .. consume()
			end
			
			if Keywords[id] then
				table.insert(tokens, Token.new(TokenType.Keyword, id, startPos, pos - 1))
			elseif Builtins[id] or RobloxGlobals[id] then
				table.insert(tokens, Token.new(TokenType.Builtin, id, startPos, pos - 1))
			else
				-- Check if it's a function call
				local tempPos = pos
				while tempPos <= len and string.sub(code, tempPos, tempPos):match("%s") do
					tempPos = tempPos + 1
				end
				if string.sub(code, tempPos, tempPos) == "(" then
					table.insert(tokens, Token.new(TokenType.Function, id, startPos, pos - 1))
				else
					table.insert(tokens, Token.new(TokenType.Identifier, id, startPos, pos - 1))
				end
			end
		
		-- Operators
		elseif Operators[char] or Operators[char .. peek(1)] or Operators[char .. peek(1) .. peek(2)] then
			local op = consume()
			if Operators[op .. peek()] then
				op = op .. consume()
				if Operators[op .. peek()] then
					op = op .. consume()
				end
			end
			table.insert(tokens, Token.new(TokenType.Operator, op, startPos, pos - 1))
		
		-- Punctuation
		elseif char:match("[%(%){}%[%],;%.:]") then
			table.insert(tokens, Token.new(TokenType.Punctuation, consume(), startPos, pos - 1))
		
		-- Unknown
		else
			table.insert(tokens, Token.new(TokenType.Identifier, consume(), startPos, pos - 1))
		end
	end
	
	return tokens
end

-- Get color for token type
function SyntaxHighlighter.GetTokenColor(token)
	local colors = {
		[TokenType.Keyword] = Theme.Colors.Keyword,
		[TokenType.String] = Theme.Colors.String,
		[TokenType.Number] = Theme.Colors.Number,
		[TokenType.Comment] = Theme.Colors.Comment,
		[TokenType.Operator] = Theme.Colors.Operator,
		[TokenType.Builtin] = Theme.Colors.BuiltIn,
		[TokenType.Function] = Theme.Colors.Function,
		[TokenType.Method] = Theme.Colors.Method,
		[TokenType.Property] = Theme.Colors.Property,
		[TokenType.Identifier] = Theme.Colors.Foreground,
		[TokenType.Punctuation] = Theme.Colors.Foreground,
		[TokenType.Whitespace] = Theme.Colors.Foreground,
	}
	return colors[token.Type] or Theme.Colors.Foreground
end

-- Convert RGB to hex for RichText
local function rgbToHex(color3)
	return string.format("#%02X%02X%02X",
		math.floor(color3.R * 255),
		math.floor(color3.G * 255),
		math.floor(color3.B * 255)
	)
end

-- Escape HTML special characters
local function escapeHtml(text)
	text = string.gsub(text, "&", "&amp;")
	text = string.gsub(text, "<", "&lt;")
	text = string.gsub(text, ">", "&gt;")
	text = string.gsub(text, "\"", "&quot;")
	text = string.gsub(text, "'", "&#39;")
	return text
end

-- Highlight code as RichText
function SyntaxHighlighter.Highlight(code)
	local tokens = SyntaxHighlighter.Tokenize(code)
	local highlighted = {}
	
	for _, token in ipairs(tokens) do
		if token.Type == TokenType.Whitespace then
			-- Preserve whitespace but don't color it
			table.insert(highlighted, token.Value)
		else
			local color = SyntaxHighlighter.GetTokenColor(token)
			local hexColor = rgbToHex(color)
			local escapedValue = escapeHtml(token.Value)
			table.insert(highlighted, string.format('<font color="%s">%s</font>', hexColor, escapedValue))
		end
	end
	
	return table.concat(highlighted)
end

-- Highlight with line numbers
function SyntaxHighlighter.HighlightWithLineNumbers(code)
	local lines = {}
	local lineCount = 0
	
	for line in string.gmatch(code .. "\n", "([^\n]*)\n") do
		lineCount = lineCount + 1
		table.insert(lines, {
			number = lineCount,
			content = line,
		})
	end
	
	local result = {
		lineNumbers = {},
		highlighted = {},
	}
	
	for _, line in ipairs(lines) do
		table.insert(result.lineNumbers, line.number)
		table.insert(result.highlighted, SyntaxHighlighter.Highlight(line.content))
	end
	
	return result
end

return SyntaxHighlighter
