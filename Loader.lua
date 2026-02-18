--[[
	Dracula Code Editor - GitHub Loader
	
	Loads the editor directly from GitHub using loadstring and game:HttpGet.
	
	Usage:
		loadstring(game:HttpGet("https://raw.githubusercontent.com/0xFratex/CodeEditor/main/Loader.lua"))()
]]

local GITHUB_RAW = "https://raw.githubusercontent.com/0xFratex/CodeEditor/main/"

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Wait for player
local player = Players.LocalPlayer
if not player then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	player = Players.LocalPlayer
end

local playerGui = player:WaitForChild("PlayerGui")

-- Module cache
local ModuleCache = {}

-- Safe HTTP GET with retry
local function httpGet(url, retries)
	retries = retries or 3
	
	for i = 1, retries do
		local success, result = pcall(function()
			return game:HttpGet(url)
		end)
		
		if success and result and #result > 0 then
			return result
		end
		
		task.wait(1)
	end
	
	return nil
end

-- Load module from GitHub
local function loadFromGitHub(moduleName)
	-- Check cache
	if ModuleCache[moduleName] then
		return ModuleCache[moduleName]
	end
	
	local url = GITHUB_RAW .. moduleName
	print("🦇 Loading:", moduleName)
	
	local source = httpGet(url)
	
	if not source then
		warn("🦇 Failed to load:", moduleName)
		return nil
	end
	
	local success, result = pcall(function()
		local fn, err = loadstring(source)
		if not fn then
			warn("🦇 Compile error in", moduleName, ":", tostring(err))
			return nil
		end
		return fn()
	end)
	
	if not success then
		warn("🦇 Execute error in", moduleName, ":", tostring(result))
		return nil
	end
	
	ModuleCache[moduleName] = result
	return result
end

-- ============================================
-- Initialize global storage
-- ============================================

_G.DraculaEditor = _G.DraculaEditor or {}
_G.DraculaEditor.Modules = _G.DraculaEditor.Modules or {}

print("🦇 Dracula Code Editor - Loading from GitHub...")

-- Load Theme first (no dependencies)
local Theme = loadFromGitHub("DraculaTheme.lua")
if not Theme then
	-- Fallback theme if loading fails
	Theme = {
		Colors = {
			Background = Color3.fromRGB(40, 42, 54),
			BackgroundLight = Color3.fromRGB(68, 71, 90),
			BackgroundDark = Color3.fromRGB(33, 34, 44),
			Selection = Color3.fromRGB(68, 71, 90),
			Foreground = Color3.fromRGB(248, 248, 242),
			Comment = Color3.fromRGB(98, 114, 164),
			Keyword = Color3.fromRGB(255, 121, 198),
			String = Color3.fromRGB(241, 250, 140),
			Number = Color3.fromRGB(189, 147, 249),
			Function = Color3.fromRGB(80, 250, 123),
			BuiltIn = Color3.fromRGB(139, 233, 253),
			Property = Color3.fromRGB(255, 184, 108),
			Border = Color3.fromRGB(98, 114, 164),
			Success = Color3.fromRGB(80, 250, 123),
			Warning = Color3.fromRGB(255, 184, 108),
			Error = Color3.fromRGB(255, 85, 85),
			Info = Color3.fromRGB(139, 233, 253),
			Accent = Color3.fromRGB(189, 147, 249),
			White = Color3.fromRGB(255, 255, 255),
			Button = Color3.fromRGB(98, 114, 164),
			Scrollbar = Color3.fromRGB(68, 71, 90),
		},
		Fonts = {
			Main = Enum.Font.Code,
			UI = Enum.Font.Gotham,
			Mono = Enum.Font.Code,
			Title = Enum.Font.GothamBold,
		},
		FontSizes = {
			Small = 12,
			Normal = 14,
			Large = 16,
			Title = 20,
			Code = 14,
		},
		UI = {
			Padding = 8,
			Margin = 4,
			ButtonHeight = 28,
			TabHeight = 32,
			HeaderHeight = 40,
			SidebarWidth = 220,
			IntellisenseWidth = 300,
			IntellisenseMaxHeight = 250,
		},
		CreateCorner = function(parent, radius)
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, radius or 4)
			corner.Parent = parent
			return corner
		end,
		CreateStroke = function(parent, color, thickness)
			local stroke = Instance.new("UIStroke")
			stroke.Color = color or Theme.Colors.Border
			stroke.Thickness = thickness or 1
			stroke.Parent = parent
			return stroke
		end,
	}
end
_G.DraculaEditor.Theme = Theme

-- Load FileSystem (no dependencies)
local FileSystem = loadFromGitHub("FileSystem.lua")
if FileSystem then
	_G.DraculaEditor.FileSystem = FileSystem
end

-- Load Intellisense (no dependencies)
local Intellisense = loadFromGitHub("Intellisense.lua")
if Intellisense then
	_G.DraculaEditor.Intellisense = Intellisense
end

-- Load CodeRunner (no dependencies)
local CodeRunner = loadFromGitHub("CodeRunner.lua")
if CodeRunner then
	_G.DraculaEditor.CodeRunner = CodeRunner
end

-- Load SyntaxHighlighter (needs Theme)
local SyntaxHighlighter = loadFromGitHub("SyntaxHighlighter.lua")
if SyntaxHighlighter then
	_G.DraculaEditor.SyntaxHighlighter = SyntaxHighlighter
end

-- Load EditorGUI (needs Theme)
local EditorGUI = loadFromGitHub("EditorGUI.lua")
if EditorGUI then
	_G.DraculaEditor.EditorGUI = EditorGUI
end

-- Load EditorUtilities (needs Theme)
local EditorUtilities = loadFromGitHub("EditorUtilities.lua")
if EditorUtilities then
	_G.DraculaEditor.EditorUtilities = EditorUtilities
end

-- Load main DraculaEditor (needs all above)
local DraculaEditor = loadFromGitHub("DraculaEditor.lua")
if DraculaEditor then
	_G.DraculaEditor.Main = DraculaEditor
end

-- ============================================
-- Initialize
-- ============================================

task.wait(0.5)

-- Check if we have the minimum required modules
if DraculaEditor and EditorGUI and Theme then
	-- Initialize the editor
	local success, err = pcall(function()
		DraculaEditor.Initialize(playerGui)
	end)
	
	if success then
		print("🦇 Dracula Code Editor loaded successfully!")
		print("   Press F8 to toggle the editor")
	else
		warn("🦇 Failed to initialize:", err)
	end
else
	warn("🦇 Failed to load required modules, falling back to QuickStart...")
	
	-- Try QuickStart as fallback
	local quickStartSource = httpGet(GITHUB_RAW .. "QuickStart.lua")
	if quickStartSource then
		local fn = loadstring(quickStartSource)
		if fn then
			fn()
		end
	end
end

return DraculaEditor
