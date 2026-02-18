--[[
	Dracula Code Editor - Main Loader
	
	This is the entry point for the Dracula Code Editor.
	Place this script in StarterPlayerScripts or require it from any LocalScript.
	
	Usage:
		local DraculaEditor = require(script.Parent.DraculaEditor)
		DraculaEditor.Initialize()
		DraculaEditor.Show()
	
	Keyboard Shortcuts:
		F8  - Toggle Editor
		F5  - Run Code
		Ctrl+S - Save File
		Ctrl+N - New File
		Ctrl+F - Find
		Escape - Close Intellisense
]]

local DraculaEditor = {}

-- Wait for game to load
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Module loader
function DraculaEditor.Load()
	local success, result = pcall(function()
		return require(script:WaitForChild("DraculaEditor"))
	end)
	
	if success then
		return result
	else
		warn("Failed to load DraculaEditor:", result)
		return nil
	end
end

-- Quick start function
function DraculaEditor.QuickStart()
	local editor = DraculaEditor.Load()
	if editor then
		editor.Initialize()
		editor.Show()
		return editor
	end
	return nil
end

-- Auto-initialize for quick testing
local function autoInit()
	-- Wait for player
	local player = Players.LocalPlayer
	if not player then
		Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
		player = Players.LocalPlayer
	end
	
	-- Wait for PlayerGui
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Small delay to ensure everything is loaded
	task.wait(0.5)
	
	-- Initialize editor
	local editor = DraculaEditor.Load()
	if editor then
		editor.Initialize(playerGui)
		print("🦇 Dracula Code Editor loaded! Press F8 to toggle.")
	end
end

-- Run auto-initialization in a new thread
if RunService:IsClient() then
	task.spawn(autoInit)
end

return DraculaEditor
