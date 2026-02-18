--[[
	Dracula Code Editor - Example Usage Script
	
	Place this script in StarterPlayerScripts to auto-load the editor.
	This demonstrates how to use the editor programmatically.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Wait for game to load
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local playerGui = player:WaitForChild("PlayerGui")

-- Load Dracula Editor
local DraculaEditor = require(script.Parent:WaitForChild("DraculaEditor"))

-- Initialize the editor
local editor = DraculaEditor.Initialize(playerGui)

-- Create some example files
editor.CreateNewFile("utils.lua", [[
-- Utility Functions
local Utils = {}

function Utils.printTable(t, indent)
	indent = indent or 0
	for k, v in pairs(t) do
		local formatting = string.rep("  ", indent) .. k .. ": "
		if type(v) == "table" then
			print(formatting)
			Utils.printTable(v, indent + 1)
		else
			print(formatting .. tostring(v))
		end
	end
end

function Utils.deepCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = Utils.deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

return Utils
]])

editor.CreateNewFile("demo.lua", [[
-- Dracula Editor Demo
-- This file demonstrates various Lua features and Roblox integration

print("🦇 Welcome to Dracula Code Editor!")

-- Variables
local playerName = "Player1"
local score = 100
local isPlaying = true

-- Table
local player = {
	name = "Hero",
	level = 5,
	health = 100,
	maxHealth = 100,
	inventory = {"Sword", "Shield", "Potion"}
}

-- Function
local function greet(name)
	return "Hello, " .. name .. "!"
end

print(greet(playerName))

-- Loop
print("Inventory:")
for i, item in ipairs(player.inventory) do
	print(i .. ". " .. item)
end

-- Roblox Instance Creation
local part = Instance.new("Part")
part.Name = "DraculaPart"
part.Size = Vector3.new(4, 4, 4)
part.Color = Color3.fromRGB(189, 147, 249) -- Dracula purple!
part.Anchored = true
part.Parent = workspace

print("Created part:", part.Name)

-- Try the smart intellisense:
-- Type: game.Workspace. and see children suggestions
-- Type: game.Workspace:GetChildren() and see all children with their indices
]])

editor.CreateNewFile("tests.lua", [[
-- Test File for Intellisense Features
-- This file helps test the smart intellisense system

-- Test game environment intellisense
-- Try typing: game.
-- You should see services and properties

-- Test workspace children
-- Try typing: workspace.
-- You should see all workspace children

-- Test GetChildren() smart completion
-- Try typing: game.Workspace:GetChildren() 
-- You should see all children with their indices

-- Test method completion
-- Try typing after a part variable: part:
-- You should see all Instance methods

-- Test property completion
-- Try typing after a part variable: part.
-- You should see all Instance properties

local function testIntellisense()
	-- Local variables should appear in intellisense
	local myVariable = 42
	local myTable = {a = 1, b = 2}
	
	-- Try typing: my
	-- You should see myVariable and myTable
	
	print("Test complete!")
end

testIntellisense()

-- Test string methods
-- Try typing: string.
-- You should see all string methods

-- Test math methods  
-- Try typing: math.
-- You should see all math methods including pi and huge

-- Test table methods
-- Try typing: table.
-- You should see all table methods
]])

-- Open the demo file
editor.OpenFile("demo.lua")

-- Show the editor
editor.Show()

-- Log a welcome message
editor.LogOutput("═══════════════════════════════════════", "Info")
editor.LogOutput("  🦇 Dracula Code Editor Loaded!", "Info")
editor.LogOutput("═══════════════════════════════════════", "Info")
editor.LogOutput("", "Info")
editor.LogOutput("Keyboard Shortcuts:", "Info")
editor.LogOutput("  F8  - Toggle Editor", "Info")
editor.LogOutput("  F5  - Run Current Code", "Info")
editor.LogOutput("  Ctrl+S - Save File", "Info")
editor.LogOutput("  Ctrl+N - New File", "Info")
editor.LogOutput("", "Info")
editor.LogOutput("Smart Intellisense Features:", "Info")
editor.LogOutput("  • Type game. to see all services", "Info")
editor.LogOutput("  • Type workspace. to see children", "Info")
editor.LogOutput("  • Type :GetChildren() to see indexed list", "Info")
editor.LogOutput("  • Press Tab or Enter to accept suggestion", "Info")

print("Dracula Editor initialized. Press F8 to toggle visibility.")
