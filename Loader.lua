--[[
	Dracula Code Editor - GitHub Loader
	
	Loads the editor directly from GitHub using loadstring and game:HttpGet.
	This is the main entry point for the Dracula Code Editor.
	
	Repository: https://github.com/0xFratex/CodeEditor
	
	Usage:
		loadstring(game:HttpGet("https://raw.githubusercontent.com/0xFratex/CodeEditor/main/Loader.lua"))()
]]

-- Configuration
local GITHUB_RAW = "https://raw.githubusercontent.com/0xFratex/CodeEditor/main/"

-- Services
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
		
		if success and result then
			return result
		end
		
		if i < retries then
			task.wait(1)
		end
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
		error("Failed to load module: " .. moduleName)
	end
	
	local success, result = pcall(function()
		local fn, err = loadstring(source)
		if not fn then
			error("Failed to compile " .. moduleName .. ": " .. tostring(err))
		end
		return fn()
	end)
	
	if not success then
		error("Failed to execute " .. moduleName .. ": " .. tostring(result))
	end
	
	ModuleCache[moduleName] = result
	return result
end

-- ============================================
-- Load all modules in correct order
-- ============================================

print("🦇 Dracula Code Editor - Loading from GitHub...")

-- 1. Load Theme first (no dependencies)
local Theme = loadFromGitHub("DraculaTheme.lua")

-- 2. Load FileSystem (no dependencies)
local FileSystem = loadFromGitHub("FileSystem.lua")

-- 3. Load SyntaxHighlighter (depends on Theme)
_G.DraculaTheme = Theme
local SyntaxHighlighter = loadFromGitHub("SyntaxHighlighter.lua")

-- 4. Load Intellisense (no dependencies)
local Intellisense = loadFromGitHub("Intellisense.lua")

-- 5. Load CodeRunner (no dependencies)
local CodeRunner = loadFromGitHub("CodeRunner.lua")

-- 6. Load EditorGUI (depends on Theme)
local EditorGUI = loadFromGitHub("EditorGUI.lua")

-- 7. Load EditorUtilities (depends on Theme)
local EditorUtilities = loadFromGitHub("EditorUtilities.lua")

-- 8. Load main DraculaEditor (depends on all above)
local DraculaEditor = loadFromGitHub("DraculaEditor.lua")

-- ============================================
-- Initialize
-- ============================================

task.wait(0.5)

-- Initialize the editor
DraculaEditor.Initialize(playerGui)

print("🦇 Dracula Code Editor loaded successfully!")
print("   Press F8 to toggle the editor")

return DraculaEditor
