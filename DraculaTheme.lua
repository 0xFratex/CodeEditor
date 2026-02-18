--[[
	Dracula Theme for Dracula Code Editor
	A dark, vibrant color scheme inspired by Dracula
]]

local DraculaTheme = {}

-- Main color palette
DraculaTheme.Colors = {
	-- Background colors
	Background = Color3.fromRGB(40, 42, 54),        -- Main background
	BackgroundLight = Color3.fromRGB(68, 71, 90),   -- Lighter background for panels
	BackgroundDark = Color3.fromRGB(33, 34, 44),    -- Darker background
	
	-- Selection and highlight
	Selection = Color3.fromRGB(68, 71, 90),
	Highlight = Color3.fromRGB(98, 114, 164),
	CurrentLine = Color3.fromRGB(60, 62, 75),
	
	-- Text colors
	Foreground = Color3.fromRGB(248, 248, 242),     -- Main text
	Comment = Color3.fromRGB(98, 114, 164),         -- Comments
	White = Color3.fromRGB(255, 255, 255),
	
	-- Syntax colors
	Keyword = Color3.fromRGB(255, 121, 198),        -- Pink for keywords
	String = Color3.fromRGB(241, 250, 140),         -- Yellow for strings
	Number = Color3.fromRGB(189, 147, 249),         -- Purple for numbers
	Operator = Color3.fromRGB(255, 121, 198),       -- Pink for operators
	Function = Color3.fromRGB(80, 250, 123),        -- Green for functions
	Variable = Color3.fromRGB(248, 248, 242),       -- White for variables
	BuiltIn = Color3.fromRGB(139, 233, 253),        -- Cyan for built-in
	Property = Color3.fromRGB(255, 184, 108),       -- Orange for properties
	Method = Color3.fromRGB(80, 250, 123),          -- Green for methods
	Class = Color3.fromRGB(255, 121, 198),          -- Pink for classes/ROBLOX types
	
	-- UI Colors
	Border = Color3.fromRGB(98, 114, 164),
	Button = Color3.fromRGB(98, 114, 164),
	ButtonHover = Color3.fromRGB(139, 233, 253),
	ButtonActive = Color3.fromRGB(80, 250, 123),
	Scrollbar = Color3.fromRGB(68, 71, 90),
	ScrollbarHover = Color3.fromRGB(98, 114, 164),
	
	-- Status colors
	Success = Color3.fromRGB(80, 250, 123),
	Warning = Color3.fromRGB(255, 184, 108),
	Error = Color3.fromRGB(255, 85, 85),
	Info = Color3.fromRGB(139, 233, 253),
	
	-- Accent colors
	Accent = Color3.fromRGB(189, 147, 249),         -- Purple accent
	AccentLight = Color3.fromRGB(255, 121, 198),    -- Pink accent
}

-- Font settings
DraculaTheme.Fonts = {
	Main = Enum.Font.Code,
	UI = Enum.Font.Gotham,
	Mono = Enum.Font.Code,
	Title = Enum.Font.GothamBold,
}

-- Font sizes
DraculaTheme.FontSizes = {
	Small = 12,
	Normal = 14,
	Large = 16,
	Title = 20,
	Code = 14,
}

-- UI spacing and sizing
DraculaTheme.UI = {
	Padding = 8,
	Margin = 4,
	ButtonHeight = 28,
	TabHeight = 32,
	HeaderHeight = 40,
	SidebarWidth = 220,
	MinWidth = 600,
	MinHeight = 400,
	IntellisenseWidth = 300,
	IntellisenseMaxHeight = 250,
}

-- Syntax highlighting rules
DraculaTheme.SyntaxRules = {
	Keywords = {
		"and", "break", "do", "else", "elseif", "end", "false", "for", 
		"function", "if", "in", "local", "nil", "not", "or", "repeat", 
		"return", "then", "true", "until", "while", "continue", "type",
		"typeof", "export", "type"
	},
	
	BuiltInFunctions = {
		"print", "warn", "error", "assert", "type", "typeof", "tostring",
		"tonumber", "pairs", "ipairs", "next", "select", "unpack", "pack",
		"rawget", "rawset", "rawequal", "rawlen", "setmetatable", "getmetatable",
		"pcall", "xpcall", "coroutine", "string", "table", "math", "os",
		"debug", "task", "tick", "time", "wait", "delay", "spawn",
		"Instance", "Color3", "Vector3", "Vector2", "CFrame", "UDim", "UDim2",
		"Ray", "Region3", "Region3int16", "Vector3int16", "BrickColor",
		"NumberRange", "NumberSequence", "ColorSequence", "Rect", "Enums"
	},
	
	RobloxGlobals = {
		"game", "workspace", "script", "Game", "Workspace", "plugin",
		"settings", "UserSettings", "version", "printidentity"
	},
	
	StringPatterns = {
		{ pattern = '"[^"]*"', type = "String" },
		{ pattern = "'[^']*'", type = "String" },
		{ pattern = '%[%[.*%]%]', type = "String" },
		{ pattern = '%-%-.*$', type = "Comment" },
		{ pattern = '%-%-%[%[.*%]%]', type = "Comment" },
		{ pattern = '%d+%.?%d*', type = "Number" },
		{ pattern = '0x[%x]+', type = "Number" },
	},
}

-- Create gradient for buttons
function DraculaTheme.CreateButtonGradient(parent, isHover)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, isHover and DraculaTheme.Colors.ButtonHover or DraculaTheme.Colors.Button),
		ColorSequenceKeypoint.new(1, DraculaTheme.Colors.BackgroundLight)
	})
	gradient.Rotation = 45
	gradient.Parent = parent
	return gradient
end

-- Create corner radius
function DraculaTheme.CreateCorner(parent, radius)
	radius = radius or 4
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

-- Create stroke
function DraculaTheme.CreateStroke(parent, color, thickness)
	color = color or DraculaTheme.Colors.Border
	thickness = thickness or 1
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Parent = parent
	return stroke
end

-- Create padding
function DraculaTheme.CreatePadding(parent, padding)
	padding = padding or DraculaTheme.UI.Padding
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, padding)
	pad.PaddingRight = UDim.new(0, padding)
	pad.PaddingTop = UDim.new(0, padding)
	pad.PaddingBottom = UDim.new(0, padding)
	pad.Parent = parent
	return pad
end

return DraculaTheme
