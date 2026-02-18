--[[
	Dracula Code Editor - GitHub Loader
	
	Loads the editor directly from GitHub using loadstring and game:HttpGet.
	This is the main entry point for the Dracula Code Editor.
	
	Repository: https://github.com/0xFratex/CodeEditor
	Raw URL: https://raw.githubusercontent.com/0xFratex/CodeEditor/main/
	
	Usage:
		loadstring(game:HttpGet("https://raw.githubusercontent.com/0xFratex/CodeEditor/main/Loader.lua"))()
]]

-- Configuration
local GITHUB_RAW = "https://raw.githubusercontent.com/0xFratex/CodeEditor/main/"
local FILES = {
	"DraculaTheme.lua",
	"FileSystem.lua",
	"Intellisense.lua",
	"EditorGUI.lua",
	"CodeRunner.lua",
	"SyntaxHighlighter.lua",
	"EditorUtilities.lua",
	"DraculaEditor.lua",
}

-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Cache for loaded modules
local ModuleCache = {}

-- Safe HTTP GET with retry
local function safeHttpGet(url, retries)
	retries = retries or 3
	
	for i = 1, retries do
		local success, result = pcall(function()
			return game:HttpGet(url)
		end)
		
		if success then
			return result
		end
		
		if i < retries then
			task.wait(1)
		end
	end
	
	return nil
end

-- Load module from GitHub
local function loadModule(moduleName)
	-- Check cache first
	if ModuleCache[moduleName] then
		return ModuleCache[moduleName]
	end
	
	local url = GITHUB_RAW .. moduleName
	local source = safeHttpGet(url)
	
	if not source then
		error("Failed to load module: " .. moduleName)
	end
	
	local success, result = pcall(function()
		local fn = loadstring(source)
		if not fn then
			error("Failed to compile module: " .. moduleName)
		end
		return fn()
	end)
	
	if not success then
		error("Failed to execute module: " .. moduleName .. " - " .. tostring(result))
	end
	
	ModuleCache[moduleName] = result
	return result
end

-- Create a virtual require function
local function createRequire()
	local modules = {}
	
	-- Preload all modules
	for _, moduleName in ipairs(FILES) do
		modules[moduleName] = loadModule(moduleName)
	end
	
	return function(modulePath)
		-- Extract module name from path
		local moduleName = modulePath:match("([^/]+)%.lua$") or modulePath
		
		-- Check if module name ends with .lua, if not add it
		if not moduleName:match("%.lua$") then
			moduleName = moduleName .. ".lua"
		end
		
		if modules[moduleName] then
			return modules[moduleName]
		end
		
		-- Try to load dynamically
		return loadModule(moduleName)
	end
end

-- Main loader function
local function main()
	-- Wait for game to load
	local player = Players.LocalPlayer
	if not player then
		Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
		player = Players.LocalPlayer
	end
	
	local playerGui = player:WaitForChild("PlayerGui")
	task.wait(0.5)
	
	print("🦇 Dracula Code Editor - Loading from GitHub...")
	
	-- Create require function and set up module environment
	local require = createRequire()
	
	-- Store require globally for modules to use
	_G.DraculaRequire = require
	
	-- Load and initialize the editor
	local DraculaEditor = require("DraculaEditor.lua")
	
	-- Override the default require in the editor to use our loader
	local originalRequire = require
	
	-- Initialize the editor
	DraculaEditor.Initialize(playerGui)
	
	print("🦇 Dracula Code Editor loaded successfully!")
	print("   Press F8 to toggle the editor")
	
	return DraculaEditor
end

-- Run the loader
local success, result = pcall(main)

if not success then
	warn("🦇 Failed to load Dracula Code Editor:", result)
	
	-- Try to load the quick start version as fallback
	local quickStartUrl = GITHUB_RAW .. "QuickStart.lua"
	local quickStartSource = safeHttpGet(quickStartUrl)
	
	if quickStartSource then
		print("🦇 Loading fallback QuickStart version...")
		local fn = loadstring(quickStartSource)
		if fn then
			fn()
		end
	end
else
	return result
end
