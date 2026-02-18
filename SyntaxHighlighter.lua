--[[
	Dracula Syntax Highlighter
	Provides syntax highlighting for Lua code with Dracula theme colors
]]

local SyntaxHighlighter = {}

-- Get Theme from global storage
local function getTheme()
	local editor = _G.DraculaEditor
	if editor and editor.Theme then
		return editor.Theme
	end
	return {
		Colors = {
			Keyword = Color3.fromRGB(255, 121, 198),
			String = Color3.fromRGB(241, 250, 140),
			Number = Color3.fromRGB(189, 147, 249),
			Comment = Color3.fromRGB(98, 114, 164),
			Operator = Color3.fromRGB(255, 121, 198),
			Function = Color3.fromRGB(80, 250, 123),
			BuiltIn = Color3.fromRGB(139, 233, 253),
			Property = Color3.fromRGB(255, 184, 108),
			Method = Color3.fromRGB(80, 250, 123),
			Foreground = Color3.fromRGB(248, 248, 242),
		}
	}
end

-- Token types
local TokenType = {
	Keyword = "Keyword", String = "String", Number = "Number",
	Comment = "Comment", Operator = "Operator", Identifier = "Identifier",
	Builtin = "Builtin", Property = "Property", Method = "Method",
	Function = "Function", Punctuation = "Punctuation", Whitespace = "Whitespace",
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

-- Built-in functions
local Builtins = {
	["print"] = true, ["warn"] = true, ["error"] = true, ["assert"] = true,
	["type"] = true, ["typeof"] = true, ["tostring"] = true, ["tonumber"] = true,
	["pairs"] = true, ["ipairs"] = true, ["next"] = true, ["select"] = true,
	["unpack"] = true, ["pack"] = true, ["rawget"] = true, ["rawset"] = true,
	["pcall"] = true, ["xpcall"] = true, ["tick"] = true, ["time"] = true,
	["wait"] = true, ["delay"] = true, ["spawn"] = true, ["Instance"] = true,
	["Color3"] = true, ["Vector3"] = true, ["Vector2"] = true, ["CFrame"] = true,
	["UDim"] = true, ["UDim2"] = true, ["Enum"] = true, ["task"] = true,
	["string"] = true, ["table"] = true, ["math"] = true, ["os"] = true,
}

-- Roblox globals
local RobloxGlobals = {
	["game"] = true, ["workspace"] = true, ["Game"] = true, ["Workspace"] = true,
	["script"] = true, ["plugin"] = true,
}

-- Operators
local Operators = {
	["+"] = true, ["-"] = true, ["*"] = true, ["/"] = true, ["%"] = true,
	["^"] = true, ["#"] = true, ["=="] = true, ["~="] = true, ["<="] = true,
	[">="] = true, ["<"] = true, [">"] = true, ["="] = true, [".."] = true,
	["..."] = true,
}

-- Tokenize Lua code
function SyntaxHighlighter.Tokenize(code)
	local tokens = {}
	local pos = 1
	local len = #code
	
	local function peek(offset)
		return string.sub(code, pos + (offset or 0), pos + (offset or 0))
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
			table.insert(tokens, {Type = TokenType.Whitespace, Value = whitespace})
		
		-- Comments
		elseif char == "-" and peek(1) == "-" then
			local comment = consume() .. consume()
			if peek() == "[" and peek(1) == "[" then
				consume() consume()
				comment = comment .. "[["
				while pos <= len do
					if peek() == "]" and peek(1) == "]" then
						consume() consume()
						comment = comment .. "]]"
						break
					end
					comment = comment .. consume()
				end
			else
				while pos <= len and peek() ~= "\n" do
					comment = comment .. consume()
				end
			end
			table.insert(tokens, {Type = TokenType.Comment, Value = comment})
		
		-- Multi-line strings
		elseif char == "[" and (peek(1) == "[" or peek(1) == "=") then
			local str = consume()
			while peek() == "=" do str = str .. consume() end
			if peek() == "[" then
				str = str .. consume()
				while pos <= len do
					if peek() == "]" then
						local temp = str
						str = str .. consume()
						while peek() == "=" do str = str .. consume() end
						if peek() == "]" then
							str = str .. consume()
							break
						end
					else
						str = str .. consume()
					end
				end
			end
			table.insert(tokens, {Type = TokenType.String, Value = str})
		
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
				else
					str = str .. consume()
				end
			end
			table.insert(tokens, {Type = TokenType.String, Value = str})
		
		-- Numbers
		elseif char:match("%d") then
			local num = ""
			if char == "0" and peek(1):lower() == "x" then
				num = consume() .. consume()
				while pos <= len and peek():match("[%x]") do
					num = num .. consume()
				end
			else
				while pos <= len and peek():match("%d") do
					num = num .. consume()
				end
				if pos <= len and peek() == "." then
					num = num .. consume()
					while pos <= len and peek():match("%d") do
						num = num .. consume()
					end
				end
			end
			table.insert(tokens, {Type = TokenType.Number, Value = num})
		
		-- Identifiers and keywords
		elseif char:match("[%a_]") then
			local id = ""
			while pos <= len and peek():match("[%w_]") do
				id = id .. consume()
			end
			
			if Keywords[id] then
				table.insert(tokens, {Type = TokenType.Keyword, Value = id})
			elseif Builtins[id] or RobloxGlobals[id] then
				table.insert(tokens, {Type = TokenType.Builtin, Value = id})
			else
				table.insert(tokens, {Type = TokenType.Identifier, Value = id})
			end
		
		-- Operators
		elseif Operators[char] or Operators[char .. peek(1)] then
			local op = consume()
			if Operators[op .. peek()] then
				op = op .. consume()
			end
			table.insert(tokens, {Type = TokenType.Operator, Value = op})
		
		-- Punctuation
		elseif char:match("[%(%){}%[%],;%.:]") then
			table.insert(tokens, {Type = TokenType.Punctuation, Value = consume()})
		
		-- Unknown
		else
			table.insert(tokens, {Type = TokenType.Identifier, Value = consume()})
		end
	end
	
	return tokens
end

-- Get color for token type
function SyntaxHighlighter.GetTokenColor(token)
	local Theme = getTheme()
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

-- RGB to hex
local function rgbToHex(color3)
	return string.format("#%02X%02X%02X",
		math.floor(color3.R * 255),
		math.floor(color3.G * 255),
		math.floor(color3.B * 255)
	)
end

-- Escape HTML
local function escapeHtml(text)
	text = string.gsub(text, "&", "&amp;")
	text = string.gsub(text, "<", "&lt;")
	text = string.gsub(text, ">", "&gt;")
	return text
end

-- Highlight code
function SyntaxHighlighter.Highlight(code)
	local tokens = SyntaxHighlighter.Tokenize(code)
	local highlighted = {}
	
	for _, token in ipairs(tokens) do
		if token.Type == TokenType.Whitespace then
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

-- Extract variables from code
function SyntaxHighlighter.ExtractVariables(code, cursorPosition)
	local variables = {}
	local textBeforeCursor = string.sub(code, 1, cursorPosition)
	
	for varName in string.gmatch(textBeforeCursor, "local%s+([%w_]+)%s*=") do
		variables[varName] = { doc = "Local variable" }
	end
	
	for params in string.gmatch(textBeforeCursor, "function%s+[%w_.:]+%(([^)]*)%)") do
		for param in string.gmatch(params, "([%w_]+)") do
			if param ~= "" then
				variables[param] = { doc = "Function parameter" }
			end
		end
	end
	
	return variables
end

return SyntaxHighlighter
