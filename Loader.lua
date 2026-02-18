--[[
	Dracula Code Editor - Quick Start Script
	Features: Syntax Highlighting, Intellisense, Custom Input, Config, File Browser
	
	Press F8 to toggle the editor!
]]

-- Wait for game to load
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local playerGui = player:WaitForChild("PlayerGui")

task.wait(0.5)

-- ============================================
-- FILE SYSTEM (Synapse/Executor Functions)
-- ============================================

local FileSystem = {}

-- Check if file functions are available
FileSystem.enabled = false

function FileSystem.isAvailable()
	return writefile ~= nil and readfile ~= nil and listfiles ~= nil and isfile ~= nil and isfolder ~= nil
end

function FileSystem.writeFile(path, content)
	if writefile then
		local success, err = pcall(function()
			writefile(path, content)
		end)
		return success, err
	end
	return false, "writefile not available"
end

function FileSystem.readFile(path)
	if readfile then
		local success, result = pcall(function()
			return readfile(path)
		end)
		if success then
			return result
		end
	end
	return nil
end

function FileSystem.listFiles(path)
	if listfiles then
		local success, result = pcall(function()
			return listfiles(path or "DraculaEditor")
		end)
		if success then
			return result or {}
		end
	end
	return {}
end

function FileSystem.fileExists(path)
	if isfile then
		local success, result = pcall(function()
			return isfile(path)
		end)
		return success and result
	end
	return false
end

function FileSystem.folderExists(path)
	if isfolder then
		local success, result = pcall(function()
			return isfolder(path)
		end)
		return success and result
	end
	return false
end

function FileSystem.createFolder(path)
	if makefolder then
		local success, err = pcall(function()
			makefolder(path)
		end)
		return success, err
	end
	return false, "makefolder not available"
end

function FileSystem.deleteFile(path)
	if delfile then
		local success, err = pcall(function()
			delfile(path)
		end)
		return success, err
	end
	return false, "delfile not available"
end

function FileSystem.deleteFolder(path)
	if delfolder then
		local success, err = pcall(function()
			delfolder(path)
		end)
		return success, err
	end
	return false, "delfolder not available"
end

-- Initialize folder
if FileSystem.isAvailable() then
	FileSystem.enabled = true
	if not FileSystem.folderExists("DraculaEditor") then
		FileSystem.createFolder("DraculaEditor")
	end
	if not FileSystem.folderExists("DraculaEditor/Scripts") then
		FileSystem.createFolder("DraculaEditor/Scripts")
	end
	if not FileSystem.folderExists("DraculaEditor/Config") then
		FileSystem.createFolder("DraculaEditor/Config")
	end
end

-- ============================================
-- CONFIG SYSTEM
-- ============================================

local Config = {
	theme = "Dracula",
	fontSize = 14,
	autoSave = true,
	autoSaveInterval = 30,
	showLineNumbers = true,
	enableIntellisense = true,
	enableErrorDetection = true,
	recentFiles = {},
	windowX = 0.5,
	windowY = 0.5,
	windowWidth = 900,
	windowHeight = 600,
}

local ConfigManager = {}

function ConfigManager.load()
	if not FileSystem.enabled then return end
	
	local content = FileSystem.readFile("DraculaEditor/Config/settings.json")
	if content then
		local success, data = pcall(function()
			return game:GetService("HttpService"):JSONDecode(content)
		end)
		if success and type(data) == "table" then
			for key, value in pairs(data) do
				Config[key] = value
			end
		end
	end
end

function ConfigManager.save()
	if not FileSystem.enabled then return end
	
	local json = game:GetService("HttpService"):JSONEncode(Config)
	FileSystem.writeFile("DraculaEditor/Config/settings.json", json)
end

function ConfigManager.addRecentFile(path)
	for i, v in ipairs(Config.recentFiles) do
		if v == path then
			table.remove(Config.recentFiles, i)
			break
		end
	end
	table.insert(Config.recentFiles, 1, path)
	if #Config.recentFiles > 10 then
		table.remove(Config.recentFiles)
	end
	ConfigManager.save()
end

ConfigManager.load()

-- ============================================
-- DRACULA THEME
-- ============================================

local Theme = {
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
		Cursor = Color3.fromRGB(248, 248, 242),
		ErrorHighlight = Color3.fromRGB(255, 85, 85),
	},
	Fonts = {
		Main = Enum.Font.Code,
		UI = Enum.Font.Gotham,
		Title = Enum.Font.GothamBold,
	},
}

-- ============================================
-- SYNTAX HIGHLIGHTER
-- ============================================

local Keywords = {
	["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
	["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
	["function"] = true, ["if"] = true, ["in"] = true, ["local"] = true,
	["nil"] = true, ["not"] = true, ["or"] = true, ["repeat"] = true,
	["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true,
	["while"] = true, ["continue"] = true,
}

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
	["game"] = true, ["workspace"] = true, ["script"] = true,
	["loadstring"] = true, ["newproxy"] = true, ["gcinfo"] = true,
	["collectgarbage"] = true, ["coroutine"] = true, ["debug"] = true,
}

local function escapeXml(text)
	text = string.gsub(text, "&", "&amp;")
	text = string.gsub(text, "<", "&lt;")
	text = string.gsub(text, ">", "&gt;")
	return text
end

local function colorToHex(color)
	return string.format("#%02X%02X%02X",
		math.floor(color.R * 255),
		math.floor(color.G * 255),
		math.floor(color.B * 255)
	)
end

local function highlightCode(code, errorLine)
	local result = {}
	local pos = 1
	local len = #code
	local currentLine = 1
	
	local function peek(offset)
		return string.sub(code, pos + (offset or 0), pos + (offset or 0))
	end
	
	while pos <= len do
		local char = peek()
		
		-- Track line numbers
		if char == "\n" then
			currentLine = currentLine + 1
			table.insert(result, "\n")
			pos = pos + 1
		-- Whitespace
		elseif char:match("%s") then
			local ws = ""
			while pos <= len and peek():match("%s") and peek() ~= "\n" do
				ws = ws .. string.sub(code, pos, pos)
				pos = pos + 1
			end
			table.insert(result, ws)
		
		-- Comments
		elseif char == "-" and peek(1) == "-" then
			local comment = ""
			while pos <= len and peek() ~= "\n" do
				comment = comment .. string.sub(code, pos, pos)
				pos = pos + 1
			end
			table.insert(result, '<font color="' .. colorToHex(Theme.Colors.Comment) .. '">' .. escapeXml(comment) .. '</font>')
		
		-- Strings (double quote)
		elseif char == '"' then
			local str = string.sub(code, pos, pos)
			pos = pos + 1
			while pos <= len do
				local c = peek()
				if c == "\\" then
					str = str .. string.sub(code, pos, pos + 1)
					pos = pos + 2
				elseif c == '"' then
					str = str .. string.sub(code, pos, pos)
					pos = pos + 1
					break
				elseif c == "\n" then
					break
				else
					str = str .. string.sub(code, pos, pos)
					pos = pos + 1
				end
			end
			table.insert(result, '<font color="' .. colorToHex(Theme.Colors.String) .. '">' .. escapeXml(str) .. '</font>')
		
		-- Strings (single quote)
		elseif char == "'" then
			local str = string.sub(code, pos, pos)
			pos = pos + 1
			while pos <= len do
				local c = peek()
				if c == "\\" then
					str = str .. string.sub(code, pos, pos + 1)
					pos = pos + 2
				elseif c == "'" then
					str = str .. string.sub(code, pos, pos)
					pos = pos + 1
					break
				elseif c == "\n" then
					break
				else
					str = str .. string.sub(code, pos, pos)
					pos = pos + 1
				end
			end
			table.insert(result, '<font color="' .. colorToHex(Theme.Colors.String) .. '">' .. escapeXml(str) .. '</font>')
		
		-- Multi-line strings [[ ]]
		elseif char == "[" and (peek(1) == "[" or peek(1) == "=") then
			local str = string.sub(code, pos, pos)
			pos = pos + 1
			while pos <= len and peek() == "=" do
				str = str .. string.sub(code, pos, pos)
				pos = pos + 1
			end
			if peek() == "[" then
				str = str .. string.sub(code, pos, pos)
				pos = pos + 1
				-- Find closing
				while pos <= len do
					if peek() == "]" then
						local temp = str
						str = str .. string.sub(code, pos, pos)
						pos = pos + 1
						while pos <= len and peek() == "=" do
							str = str .. string.sub(code, pos, pos)
							pos = pos + 1
						end
						if peek() == "]" then
							str = str .. string.sub(code, pos, pos)
							pos = pos + 1
							break
						end
					else
						str = str .. string.sub(code, pos, pos)
						pos = pos + 1
					end
				end
			end
			table.insert(result, '<font color="' .. colorToHex(Theme.Colors.String) .. '">' .. escapeXml(str) .. '</font>')
		
		-- Numbers
		elseif char:match("%d") or (char == "." and peek(1):match("%d")) then
			local num = ""
			if char == "." then
				num = "."
				pos = pos + 1
			end
			while pos <= len and peek():match("[%d%.xXa-fA-F]") do
				num = num .. string.sub(code, pos, pos)
				pos = pos + 1
			end
			table.insert(result, '<font color="' .. colorToHex(Theme.Colors.Number) .. '">' .. escapeXml(num) .. '</font>')
		
		-- Identifiers and keywords
		elseif char:match("[%a_]") then
			local id = ""
			while pos <= len and peek():match("[%w_]") do
				id = id .. string.sub(code, pos, pos)
				pos = pos + 1
			end
			
			if Keywords[id] then
				table.insert(result, '<font color="' .. colorToHex(Theme.Colors.Keyword) .. '">' .. id .. '</font>')
			elseif Builtins[id] then
				table.insert(result, '<font color="' .. colorToHex(Theme.Colors.BuiltIn) .. '">' .. id .. '</font>')
			else
				table.insert(result, escapeXml(id))
			end
		
		-- Operators and punctuation
		else
			table.insert(result, escapeXml(char))
			pos = pos + 1
		end
	end
	
	return table.concat(result)
end

-- ============================================
-- ERROR DETECTION
-- ============================================

local function detectErrors(code)
	local errors = {}
	
	-- Try to parse the code
	local fn, err = loadstring(code)
	if not fn and err then
		-- Extract line number from error
		local lineNum = err:match(":(%d+):") or err:match("line (%d+)")
		if lineNum then
			lineNum = tonumber(lineNum)
			local errorMsg = err:match(":%d+:%s*(.+)") or err
			table.insert(errors, {line = lineNum, message = errorMsg})
		else
			table.insert(errors, {line = 1, message = err})
		end
	end
	
	-- Check for common issues
	local lineNum = 1
	local bracketStack = {}
	local braceStack = {}
	local parenStack = {}
	
	for i = 1, #code do
		local char = code:sub(i, i)
		if char == "\n" then
			lineNum = lineNum + 1
		elseif char == "{" then
			table.insert(braceStack, lineNum)
		elseif char == "}" then
			if #braceStack > 0 then
				table.remove(braceStack)
			end
		elseif char == "[" then
			table.insert(bracketStack, lineNum)
		elseif char == "]" then
			if #bracketStack > 0 then
				table.remove(bracketStack)
			end
		elseif char == "(" then
			table.insert(parenStack, lineNum)
		elseif char == ")" then
			if #parenStack > 0 then
				table.remove(parenStack)
			end
		end
	end
	
	-- Report unclosed brackets
	if #braceStack > 0 then
		table.insert(errors, {line = braceStack[1], message = "Unclosed {", type = "warning"})
	end
	if #bracketStack > 0 then
		table.insert(errors, {line = bracketStack[1], message = "Unclosed [", type = "warning"})
	end
	if #parenStack > 0 then
		table.insert(errors, {line = parenStack[1], message = "Unclosed (", type = "warning"})
	end
	
	return errors
end

-- ============================================
-- INTELLISENSE
-- ============================================

local IntellisenseData = {
	Keywords = {"and", "break", "do", "else", "elseif", "end", "false", "for", "function",
		"if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while", "continue"},
	Builtins = {"print", "warn", "error", "assert", "type", "typeof", "tostring", "tonumber",
		"pairs", "ipairs", "next", "select", "pcall", "xpcall", "tick", "time", "wait", "spawn", "delay",
		"Instance", "Color3", "Vector3", "Vector2", "CFrame", "UDim", "UDim2", "BrickColor", "Enum",
		"task", "string", "table", "math", "os", "loadstring", "coroutine", "debug"},
	Services = {"Players", "Lighting", "ReplicatedStorage", "ReplicatedFirst", "ServerStorage",
		"ServerScriptService", "StarterGui", "StarterPack", "StarterPlayer", "TweenService",
		"UserInputService", "RunService", "HttpService", "DataStoreService", "TeleportService",
		"Workspace", "SoundService", "Chat", "Teams", "MarketplaceService", "BadgeService"},
	Methods = {"Clone", "Destroy", "FindFirstChild", "FindFirstChildOfClass", "GetChildren",
		"GetDescendants", "IsA", "WaitForChild", "ClearAllChildren", "GetAttribute", "SetAttribute",
		"GetService", "FindService", "new"},
}

-- Check if cursor is inside a comment
local function isInComment(text, cursorPos)
	local textBefore = string.sub(text, 1, cursorPos - 1)
	-- Find if there's a -- that's not inside a string
	local inString = false
	local stringChar = nil
	local i = 1
	while i <= #textBefore do
		local char = string.sub(textBefore, i, i)
		
		if not inString then
			if char == '"' or char == "'" then
				inString = true
				stringChar = char
			elseif char == "-" and string.sub(textBefore, i + 1, i + 1) == "-" then
				-- Found comment start
				return true
			elseif char == "[" and string.sub(textBefore, i + 1, i + 1) == "[" then
				-- Multi-line string start
				inString = true
				stringChar = "]]"
			end
		else
			if stringChar == "]]" then
				if char == "]" and string.sub(textBefore, i + 1, i + 1) == "]" then
					inString = false
					i = i + 1
				end
			elseif char == "\\" then
				i = i + 1 -- Skip next char
			elseif char == stringChar then
				inString = false
			end
		end
		i = i + 1
	end
	
	return false
end

-- Check if cursor is inside a string
local function isInString(text, cursorPos)
	local textBefore = string.sub(text, 1, cursorPos - 1)
	local inString = false
	local stringChar = nil
	local i = 1
	while i <= #textBefore do
		local char = string.sub(textBefore, i, i)
		
		if not inString then
			if char == '"' or char == "'" then
				inString = true
				stringChar = char
			elseif char == "[" and string.sub(textBefore, i + 1, i + 1) == "[" then
				inString = true
				stringChar = "]]"
			end
		else
			if stringChar == "]]" then
				if char == "]" and string.sub(textBefore, i + 1, i + 1) == "]" then
					inString = false
					i = i + 1
				end
			elseif char == "\\" then
				i = i + 1
			elseif char == stringChar then
				inString = false
			end
		end
		i = i + 1
	end
	
	return inString
end

local function getCompletions(text, cursorPos)
	local completions = {}
	local context = "general"
	
	-- Don't show completions in comments
	if isInComment(text, cursorPos) then
		return completions, context, cursorPos
	end
	
	-- Get word being typed
	local wordStart = cursorPos
	while wordStart > 1 and string.sub(text, wordStart - 1, wordStart - 1):match("[%w_]") do
		wordStart = wordStart - 1
	end
	local prefix = string.sub(text, wordStart, cursorPos - 1):lower()
	
	-- Determine context
	local before = string.sub(text, 1, cursorPos - 1)
	
	if before:match("game%.$") then
		context = "game"
		for _, service in ipairs(IntellisenseData.Services) do
			table.insert(completions, {name = service, kind = "Service", insertText = service})
		end
		return completions, context, wordStart
	elseif before:match("workspace%.$") then
		context = "workspace"
		local success, children = pcall(function() return workspace:GetChildren() end)
		if success then
			for _, child in ipairs(children) do
				table.insert(completions, {name = child.Name, kind = "Instance", insertText = child.Name, detail = child.ClassName})
			end
		end
		return completions, context, wordStart
	elseif before:match(":%w-$") or before:match(":%w*$") then
		context = "method"
		for _, method in ipairs(IntellisenseData.Methods) do
			if prefix == "" or method:lower():find(prefix, 1, true) then
				table.insert(completions, {name = method, kind = "Method", insertText = method .. "()"})
			end
		end
		return completions, context, wordStart
	elseif before:match("%.$") then
		context = "property"
		return completions, context, wordStart
	elseif before:match(":GetChildren%(%)[%s]*$") then
		context = "getchildren"
		local expr = before:match("(.+):GetChildren%(%)[%s]*$")
		if expr then
			local instance = nil
			if expr == "game" then instance = game
			elseif expr == "workspace" then instance = workspace
			elseif expr:match("^game%.(%w+)$") then
				local serviceName = expr:match("^game%.(%w+)$")
				pcall(function() instance = game:GetService(serviceName) end)
			end
			
			if instance then
				local success, children = pcall(function() return instance:GetChildren() end)
				if success then
					for i, child in ipairs(children) do
						if i <= 20 then
							table.insert(completions, {
								name = child.Name,
								kind = "Instance",
								insertText = "[" .. (i - 1) .. "]",
								detail = child.ClassName,
								fullInsert = expr .. ":GetChildren()[" .. (i - 1) .. "]"
							})
						end
					end
				end
			end
		end
		return completions, context, wordStart
	end
	
	-- General completions - only show if typing
	if #prefix >= 1 then
		for _, kw in ipairs(IntellisenseData.Keywords) do
			if kw:lower():find(prefix, 1, true) then
				table.insert(completions, {name = kw, kind = "Keyword", insertText = kw})
			end
		end
		
		for _, builtin in ipairs(IntellisenseData.Builtins) do
			if builtin:lower():find(prefix, 1, true) then
				table.insert(completions, {name = builtin, kind = "Builtin", insertText = builtin .. "()"})
			end
		end
		
		table.insert(completions, {name = "game", kind = "Global", insertText = "game"})
		table.insert(completions, {name = "workspace", kind = "Global", insertText = "workspace"})
	end
	
	return completions, context, wordStart
end

-- ============================================
-- GUI CREATION
-- ============================================

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 4)
	corner.Parent = parent
	return corner
end

local function createEditor()
	-- Create ScreenGui container
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DraculaEditorGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Main Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "DraculaEditor"
	mainFrame.Size = UDim2.new(0, Config.windowWidth, 0, Config.windowHeight)
	mainFrame.Position = UDim2.new(Config.windowX, -Config.windowWidth/2, Config.windowY, -Config.windowHeight/2)
	mainFrame.BackgroundColor3 = Theme.Colors.Background
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui
	
	-- Sidebar (File Browser)
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 200, 1, -36)
	sidebar.Position = UDim2.new(0, 0, 0, 36)
	sidebar.BackgroundColor3 = Theme.Colors.BackgroundDark
	sidebar.BorderSizePixel = 0
	sidebar.Visible = false
	sidebar.Parent = mainFrame
	
	-- Sidebar Header
	local sidebarHeader = Instance.new("Frame")
	sidebarHeader.Size = UDim2.new(1, 0, 0, 32)
	sidebarHeader.BackgroundColor3 = Theme.Colors.BackgroundLight
	sidebarHeader.BorderSizePixel = 0
	sidebarHeader.Parent = sidebar
	
	local sidebarTitle = Instance.new("TextLabel")
	sidebarTitle.Size = UDim2.new(1, -60, 1, 0)
	sidebarTitle.Position = UDim2.new(0, 8, 0, 0)
	sidebarTitle.BackgroundTransparency = 1
	sidebarTitle.Text = "📁 Files"
	sidebarTitle.TextColor3 = Theme.Colors.Comment
	sidebarTitle.Font = Theme.Fonts.UI
	sidebarTitle.TextSize = 12
	sidebarTitle.TextXAlignment = Enum.TextXAlignment.Left
	sidebarTitle.Parent = sidebarHeader
	
	-- New File Button
	local newFileBtn = Instance.new("TextButton")
	newFileBtn.Size = UDim2.new(0, 24, 0, 24)
	newFileBtn.Position = UDim2.new(1, -56, 0, 4)
	newFileBtn.BackgroundColor3 = Theme.Colors.Button
	newFileBtn.Text = "+"
	newFileBtn.TextColor3 = Theme.Colors.Foreground
	newFileBtn.Font = Theme.Fonts.UI
	newFileBtn.TextSize = 16
	newFileBtn.Parent = sidebarHeader
	createCorner(newFileBtn, 4)
	
	-- Refresh Button
	local refreshBtn = Instance.new("TextButton")
	refreshBtn.Size = UDim2.new(0, 24, 0, 24)
	refreshBtn.Position = UDim2.new(1, -28, 0, 4)
	refreshBtn.BackgroundColor3 = Theme.Colors.Button
	refreshBtn.Text = "↻"
	refreshBtn.TextColor3 = Theme.Colors.Foreground
	refreshBtn.Font = Theme.Fonts.UI
	refreshBtn.TextSize = 14
	refreshBtn.Parent = sidebarHeader
	createCorner(refreshBtn, 4)
	
	-- File List
	local fileList = Instance.new("ScrollingFrame")
	fileList.Name = "FileList"
	fileList.Size = UDim2.new(1, 0, 1, -32)
	fileList.Position = UDim2.new(0, 0, 0, 32)
	fileList.BackgroundColor3 = Theme.Colors.BackgroundDark
	fileList.BorderSizePixel = 0
	fileList.ScrollBarThickness = 6
	fileList.ScrollBarImageColor3 = Theme.Colors.Scrollbar
	fileList.Parent = sidebar
	
	local fileListLayout = Instance.new("UIListLayout")
	fileListLayout.Parent = fileList
	
	-- Drag Handle
	local dragHandle = Instance.new("Frame")
	dragHandle.Name = "DragHandle"
	dragHandle.Size = UDim2.new(1, 0, 0, 36)
	dragHandle.BackgroundColor3 = Theme.Colors.BackgroundDark
	dragHandle.BorderSizePixel = 0
	dragHandle.Parent = mainFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -280, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🦇 Dracula Code Editor"
	title.TextColor3 = Theme.Colors.Foreground
	title.Font = Theme.Fonts.Title
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = dragHandle
	
	-- Toggle Sidebar Button
	local toggleSidebarBtn = Instance.new("TextButton")
	toggleSidebarBtn.Size = UDim2.new(0, 80, 0, 28)
	toggleSidebarBtn.Position = UDim2.new(1, -210, 0, 4)
	toggleSidebarBtn.BackgroundColor3 = Theme.Colors.Button
	toggleSidebarBtn.Text = "📁 Files"
	toggleSidebarBtn.TextColor3 = Theme.Colors.Foreground
	toggleSidebarBtn.Font = Theme.Fonts.UI
	toggleSidebarBtn.TextSize = 12
	toggleSidebarBtn.Parent = dragHandle
	createCorner(toggleSidebarBtn, 4)
	
	-- Settings Button
	local settingsBtn = Instance.new("TextButton")
	settingsBtn.Size = UDim2.new(0, 70, 0, 28)
	settingsBtn.Position = UDim2.new(1, -300, 0, 4)
	settingsBtn.BackgroundColor3 = Theme.Colors.Button
	settingsBtn.Text = "⚙ Config"
	settingsBtn.TextColor3 = Theme.Colors.Foreground
	settingsBtn.Font = Theme.Fonts.UI
	settingsBtn.TextSize = 12
	settingsBtn.Parent = dragHandle
	createCorner(settingsBtn, 4)
	
	-- Close Button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 32, 0, 28)
	closeBtn.Position = UDim2.new(1, -40, 0, 4)
	closeBtn.BackgroundColor3 = Theme.Colors.Error
	closeBtn.Text = "×"
	closeBtn.TextColor3 = Theme.Colors.White
	closeBtn.Font = Theme.Fonts.UI
	closeBtn.TextSize = 20
	closeBtn.Parent = dragHandle
	createCorner(closeBtn, 4)
	
	-- Code Container
	local codeContainer = Instance.new("Frame")
	codeContainer.Name = "CodeContainer"
	codeContainer.Size = UDim2.new(1, -20, 1, -130)
	codeContainer.Position = UDim2.new(0, 10, 0, 46)
	codeContainer.BackgroundColor3 = Theme.Colors.BackgroundDark
	codeContainer.Parent = mainFrame
	createCorner(codeContainer, 8)
	
	-- Line Numbers Frame
	local lineNumbersFrame = Instance.new("Frame")
	lineNumbersFrame.Name = "LineNumbers"
	lineNumbersFrame.Size = UDim2.new(0, 45, 1, 0)
	lineNumbersFrame.BackgroundColor3 = Theme.Colors.BackgroundDark
	lineNumbersFrame.BorderSizePixel = 0
	lineNumbersFrame.Parent = codeContainer
	
	-- Line Numbers Label
	local lineNumbers = Instance.new("TextLabel")
	lineNumbers.Name = "Numbers"
	lineNumbers.Size = UDim2.new(1, -8, 1, 0)
	lineNumbers.Position = UDim2.new(0, 4, 0, 0)
	lineNumbers.BackgroundTransparency = 1
	lineNumbers.Text = "1"
	lineNumbers.TextColor3 = Theme.Colors.Comment
	lineNumbers.Font = Theme.Fonts.Main
	lineNumbers.TextSize = Config.fontSize
	lineNumbers.TextXAlignment = Enum.TextXAlignment.Right
	lineNumbers.TextYAlignment = Enum.TextYAlignment.Top
	lineNumbers.Parent = lineNumbersFrame
	
	-- Code Display (shows highlighted code)
	local codeDisplay = Instance.new("TextLabel")
	codeDisplay.Name = "CodeDisplay"
	codeDisplay.Size = UDim2.new(1, -55, 1, 0)
	codeDisplay.Position = UDim2.new(0, 48, 0, 0)
	codeDisplay.BackgroundTransparency = 1
	codeDisplay.Text = ""
	codeDisplay.TextColor3 = Theme.Colors.Foreground
	codeDisplay.Font = Theme.Fonts.Main
	codeDisplay.TextSize = Config.fontSize
	codeDisplay.TextXAlignment = Enum.TextXAlignment.Left
	codeDisplay.TextYAlignment = Enum.TextYAlignment.Top
	codeDisplay.RichText = true
	codeDisplay.Parent = codeContainer
	
	-- Cursor (blinking)
	local cursor = Instance.new("Frame")
	cursor.Name = "Cursor"
	cursor.Size = UDim2.new(0, 2, 0, Config.fontSize + 2)
	cursor.BackgroundColor3 = Theme.Colors.Cursor
	cursor.BorderSizePixel = 0
	cursor.Visible = true
	cursor.ZIndex = 50
	cursor.Parent = codeContainer
	
	-- Cursor blink animation
	local cursorBlinking = true
	local function updateCursorBlink()
		while cursorBlinking do
			cursor.Visible = true
			task.wait(0.5)
			cursor.Visible = false
			task.wait(0.5)
		end
	end
	task.spawn(updateCursorBlink)
	
	-- Error display
	local errorDisplay = Instance.new("TextLabel")
	errorDisplay.Name = "ErrorDisplay"
	errorDisplay.Size = UDim2.new(1, -55, 0, 20)
	errorDisplay.Position = UDim2.new(0, 48, 1, -22)
	errorDisplay.BackgroundTransparency = 1
	errorDisplay.Text = ""
	errorDisplay.TextColor3 = Theme.Colors.Error
	errorDisplay.Font = Theme.Fonts.Main
	errorDisplay.TextSize = 12
	errorDisplay.TextXAlignment = Enum.TextXAlignment.Left
	errorDisplay.Visible = false
	errorDisplay.Parent = codeContainer
	
	-- Code Input (transparent, captures keystrokes)
	local codeInput = Instance.new("TextBox")
	codeInput.Name = "CodeInput"
	codeInput.Size = UDim2.new(1, -55, 1, 0)
	codeInput.Position = UDim2.new(0, 48, 0, 0)
	codeInput.BackgroundTransparency = 1
	codeInput.TextColor3 = Color3.new(0, 0, 0)
	codeInput.TextTransparency = 1
	codeInput.Font = Theme.Fonts.Main
	codeInput.TextSize = Config.fontSize
	codeInput.TextXAlignment = Enum.TextXAlignment.Left
	codeInput.TextYAlignment = Enum.TextYAlignment.Top
	codeInput.MultiLine = true
	codeInput.ClearTextOnFocus = false
	codeInput.Text = ""
	codeInput.PlaceholderText = ""
	codeInput.Parent = codeContainer
	
	-- Intellisense Dropdown
	local intellisense = Instance.new("Frame")
	intellisense.Name = "Intellisense"
	intellisense.Size = UDim2.new(0, 280, 0, 0)
	intellisense.BackgroundColor3 = Theme.Colors.BackgroundLight
	intellisense.BorderSizePixel = 0
	intellisense.Visible = false
	intellisense.ZIndex = 100
	intellisense.Parent = codeContainer
	createCorner(intellisense, 6)
	
	local intellisenseStroke = Instance.new("UIStroke")
	intellisenseStroke.Color = Theme.Colors.Border
	intellisenseStroke.Parent = intellisense
	
	local intellisenseList = Instance.new("ScrollingFrame")
	intellisenseList.Name = "List"
	intellisenseList.Size = UDim2.new(1, 0, 1, 0)
	intellisenseList.BackgroundColor3 = Theme.Colors.BackgroundLight
	intellisenseList.BorderSizePixel = 0
	intellisenseList.ScrollBarThickness = 6
	intellisenseList.ScrollBarImageColor3 = Theme.Colors.Scrollbar
	intellisenseList.ZIndex = 101
	intellisenseList.Parent = intellisense
	
	local intellisenseLayout = Instance.new("UIListLayout")
	intellisenseLayout.Parent = intellisenseList
	
	-- Output Panel
	local outputPanel = Instance.new("Frame")
	outputPanel.Name = "OutputPanel"
	outputPanel.Size = UDim2.new(1, -20, 0, 70)
	outputPanel.Position = UDim2.new(0, 10, 1, -80)
	outputPanel.BackgroundColor3 = Theme.Colors.BackgroundDark
	outputPanel.Parent = mainFrame
	createCorner(outputPanel, 6)
	
	local outputHeader = Instance.new("Frame")
	outputHeader.Size = UDim2.new(1, 0, 0, 26)
	outputHeader.BackgroundColor3 = Theme.Colors.BackgroundLight
	outputHeader.BorderSizePixel = 0
	outputHeader.Parent = outputPanel
	createCorner(outputHeader, 6)
	
	local outputTitle = Instance.new("TextLabel")
	outputTitle.Size = UDim2.new(0, 80, 1, 0)
	outputTitle.Position = UDim2.new(0, 10, 0, 0)
	outputTitle.BackgroundTransparency = 1
	outputTitle.Text = "📋 Output"
	outputTitle.TextColor3 = Theme.Colors.Accent
	outputTitle.Font = Theme.Fonts.UI
	outputTitle.TextSize = 12
	outputTitle.TextXAlignment = Enum.TextXAlignment.Left
	outputTitle.Parent = outputHeader
	
	-- Run Button
	local runBtn = Instance.new("TextButton")
	runBtn.Size = UDim2.new(0, 80, 0, 22)
	runBtn.Position = UDim2.new(1, -90, 0, 2)
	runBtn.BackgroundColor3 = Theme.Colors.Success
	runBtn.Text = "▶ Run (F5)"
	runBtn.TextColor3 = Theme.Colors.Background
	runBtn.Font = Theme.Fonts.UI
	runBtn.TextSize = 12
	runBtn.Parent = outputHeader
	createCorner(runBtn, 4)
	
	-- Clear Button
	local clearBtn = Instance.new("TextButton")
	clearBtn.Size = UDim2.new(0, 60, 0, 22)
	clearBtn.Position = UDim2.new(1, -160, 0, 2)
	clearBtn.BackgroundColor3 = Theme.Colors.Button
	clearBtn.Text = "Clear"
	clearBtn.TextColor3 = Theme.Colors.Foreground
	clearBtn.Font = Theme.Fonts.UI
	clearBtn.TextSize = 12
	clearBtn.Parent = outputHeader
	createCorner(clearBtn, 4)
	
	-- Save Button
	local saveBtn = Instance.new("TextButton")
	saveBtn.Size = UDim2.new(0, 70, 0, 22)
	saveBtn.Position = UDim2.new(1, -240, 0, 2)
	saveBtn.BackgroundColor3 = Theme.Colors.Info
	saveBtn.Text = "💾 Save"
	saveBtn.TextColor3 = Theme.Colors.Background
	saveBtn.Font = Theme.Fonts.UI
	saveBtn.TextSize = 12
	saveBtn.Parent = outputHeader
	createCorner(saveBtn, 4)
	
	local outputText = Instance.new("TextLabel")
	outputText.Size = UDim2.new(1, -16, 1, -28)
	outputText.Position = UDim2.new(0, 8, 0, 28)
	outputText.BackgroundTransparency = 1
	outputText.Text = "[Dracula] Ready to code..."
	outputText.TextColor3 = Theme.Colors.Comment
	outputText.Font = Theme.Fonts.Main
	outputText.TextSize = 13
	outputText.TextXAlignment = Enum.TextXAlignment.Left
	outputText.TextYAlignment = Enum.TextYAlignment.Top
	outputText.Parent = outputPanel
	
	-- Current file label
	local currentFileLabel = Instance.new("TextLabel")
	currentFileLabel.Size = UDim2.new(0, 200, 0, 18)
	currentFileLabel.Position = UDim2.new(0, 10, 1, -18)
	currentFileLabel.BackgroundTransparency = 1
	currentFileLabel.Text = "📄 Untitled.lua"
	currentFileLabel.TextColor3 = Theme.Colors.Comment
	currentFileLabel.Font = Theme.Fonts.UI
	currentFileLabel.TextSize = 11
	currentFileLabel.TextXAlignment = Enum.TextXAlignment.Left
	currentFileLabel.Parent = mainFrame
	
	-- Help Label
	local helpLabel = Instance.new("TextLabel")
	helpLabel.Size = UDim2.new(0, 400, 0, 18)
	helpLabel.Position = UDim2.new(1, -410, 1, -18)
	helpLabel.BackgroundTransparency = 1
	helpLabel.Text = "F8: Toggle | F5: Run | Tab/Enter: Accept | ↑↓: Navigate | Esc: Close"
	helpLabel.TextColor3 = Theme.Colors.Comment
	helpLabel.Font = Theme.Fonts.UI
	helpLabel.TextSize = 11
	helpLabel.TextXAlignment = Enum.TextXAlignment.Right
	helpLabel.Parent = mainFrame
	
	-- Settings Panel
	local settingsPanel = Instance.new("Frame")
	settingsPanel.Name = "SettingsPanel"
	settingsPanel.Size = UDim2.new(0, 350, 0, 300)
	settingsPanel.Position = UDim2.new(0.5, -175, 0.5, -150)
	settingsPanel.BackgroundColor3 = Theme.Colors.BackgroundDark
	settingsPanel.BorderSizePixel = 0
	settingsPanel.Visible = false
	settingsPanel.ZIndex = 200
	settingsPanel.Parent = mainFrame
	createCorner(settingsPanel, 8)
	
	local settingsStroke = Instance.new("UIStroke")
	settingsStroke.Color = Theme.Colors.Border
	settingsStroke.Parent = settingsPanel
	
	local settingsHeader = Instance.new("Frame")
	settingsHeader.Size = UDim2.new(1, 0, 0, 36)
	settingsHeader.BackgroundColor3 = Theme.Colors.BackgroundLight
	settingsHeader.BorderSizePixel = 0
	settingsHeader.Parent = settingsPanel
	createCorner(settingsHeader, 8)
	
	local settingsTitle = Instance.new("TextLabel")
	settingsTitle.Size = UDim2.new(1, -50, 1, 0)
	settingsTitle.Position = UDim2.new(0, 12, 0, 0)
	settingsTitle.BackgroundTransparency = 1
	settingsTitle.Text = "⚙ Settings"
	settingsTitle.TextColor3 = Theme.Colors.Foreground
	settingsTitle.Font = Theme.Fonts.Title
	settingsTitle.TextSize = 16
	settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
	settingsTitle.Parent = settingsHeader
	
	local closeSettingsBtn = Instance.new("TextButton")
	closeSettingsBtn.Size = UDim2.new(0, 28, 0, 28)
	closeSettingsBtn.Position = UDim2.new(1, -32, 0, 4)
	closeSettingsBtn.BackgroundColor3 = Theme.Colors.Error
	closeSettingsBtn.Text = "×"
	closeSettingsBtn.TextColor3 = Theme.Colors.White
	closeSettingsBtn.Font = Theme.Fonts.UI
	closeSettingsBtn.TextSize = 16
	closeSettingsBtn.Parent = settingsHeader
	createCorner(closeSettingsBtn, 4)
	
	-- Settings content
	local settingsContent = Instance.new("ScrollingFrame")
	settingsContent.Size = UDim2.new(1, -20, 1, -50)
	settingsContent.Position = UDim2.new(0, 10, 0, 42)
	settingsContent.BackgroundTransparency = 1
	settingsContent.ScrollBarThickness = 4
	settingsContent.Parent = settingsPanel
	
	local settingsLayout = Instance.new("UIListLayout")
	settingsLayout.Padding = UDim.new(0, 8)
	settingsLayout.Parent = settingsContent
	
	-- Font size setting
	local fontSizeFrame = Instance.new("Frame")
	fontSizeFrame.Size = UDim2.new(1, 0, 0, 30)
	fontSizeFrame.BackgroundTransparency = 1
	fontSizeFrame.Parent = settingsContent
	
	local fontSizeLabel = Instance.new("TextLabel")
	fontSizeLabel.Size = UDim2.new(0, 100, 1, 0)
	fontSizeLabel.BackgroundTransparency = 1
	fontSizeLabel.Text = "Font Size:"
	fontSizeLabel.TextColor3 = Theme.Colors.Foreground
	fontSizeLabel.Font = Theme.Fonts.UI
	fontSizeLabel.TextSize = 13
	fontSizeLabel.TextXAlignment = Enum.TextXAlignment.Left
	fontSizeLabel.Parent = fontSizeFrame
	
	local fontSizeInput = Instance.new("TextBox")
	fontSizeInput.Size = UDim2.new(0, 60, 0, 26)
	fontSizeInput.Position = UDim2.new(1, -60, 0, 2)
	fontSizeInput.BackgroundColor3 = Theme.Colors.BackgroundLight
	fontSizeInput.Text = tostring(Config.fontSize)
	fontSizeInput.TextColor3 = Theme.Colors.Foreground
	fontSizeInput.Font = Theme.Fonts.UI
	fontSizeInput.TextSize = 13
	fontSizeInput.Parent = fontSizeFrame
	createCorner(fontSizeInput, 4)
	
	-- Auto save setting
	local autoSaveFrame = Instance.new("Frame")
	autoSaveFrame.Size = UDim2.new(1, 0, 0, 30)
	autoSaveFrame.BackgroundTransparency = 1
	autoSaveFrame.Parent = settingsContent
	
	local autoSaveLabel = Instance.new("TextLabel")
	autoSaveLabel.Size = UDim2.new(0, 150, 1, 0)
	autoSaveLabel.BackgroundTransparency = 1
	autoSaveLabel.Text = "Auto Save:"
	autoSaveLabel.TextColor3 = Theme.Colors.Foreground
	autoSaveLabel.Font = Theme.Fonts.UI
	autoSaveLabel.TextSize = 13
	autoSaveLabel.TextXAlignment = Enum.TextXAlignment.Left
	autoSaveLabel.Parent = autoSaveFrame
	
	local autoSaveBtn = Instance.new("TextButton")
	autoSaveBtn.Size = UDim2.new(0, 60, 0, 26)
	autoSaveBtn.Position = UDim2.new(1, -60, 0, 2)
	autoSaveBtn.BackgroundColor3 = Config.autoSave and Theme.Colors.Success or Theme.Colors.Error
	autoSaveBtn.Text = Config.autoSave and "ON" or "OFF"
	autoSaveBtn.TextColor3 = Theme.Colors.White
	autoSaveBtn.Font = Theme.Fonts.UI
	autoSaveBtn.TextSize = 12
	autoSaveBtn.Parent = autoSaveFrame
	createCorner(autoSaveBtn, 4)
	
	-- Error detection setting
	local errorDetectFrame = Instance.new("Frame")
	errorDetectFrame.Size = UDim2.new(1, 0, 0, 30)
	errorDetectFrame.BackgroundTransparency = 1
	errorDetectFrame.Parent = settingsContent
	
	local errorDetectLabel = Instance.new("TextLabel")
	errorDetectLabel.Size = UDim2.new(0, 150, 1, 0)
	errorDetectLabel.BackgroundTransparency = 1
	errorDetectLabel.Text = "Error Detection:"
	errorDetectLabel.TextColor3 = Theme.Colors.Foreground
	errorDetectLabel.Font = Theme.Fonts.UI
	errorDetectLabel.TextSize = 13
	errorDetectLabel.TextXAlignment = Enum.TextXAlignment.Left
	errorDetectLabel.Parent = errorDetectFrame
	
	local errorDetectBtn = Instance.new("TextButton")
	errorDetectBtn.Size = UDim2.new(0, 60, 0, 26)
	errorDetectBtn.Position = UDim2.new(1, -60, 0, 2)
	errorDetectBtn.BackgroundColor3 = Config.enableErrorDetection and Theme.Colors.Success or Theme.Colors.Error
	errorDetectBtn.Text = Config.enableErrorDetection and "ON" or "OFF"
	errorDetectBtn.TextColor3 = Theme.Colors.White
	errorDetectBtn.Font = Theme.Fonts.UI
	errorDetectBtn.TextSize = 12
	errorDetectBtn.Parent = errorDetectFrame
	createCorner(errorDetectBtn, 4)
	
	-- File system status
	local fsStatusFrame = Instance.new("Frame")
	fsStatusFrame.Size = UDim2.new(1, 0, 0, 30)
	fsStatusFrame.BackgroundTransparency = 1
	fsStatusFrame.Parent = settingsContent
	
	local fsStatusLabel = Instance.new("TextLabel")
	fsStatusLabel.Size = UDim2.new(0, 150, 1, 0)
	fsStatusLabel.BackgroundTransparency = 1
	fsStatusLabel.Text = "File System:"
	fsStatusLabel.TextColor3 = Theme.Colors.Foreground
	fsStatusLabel.Font = Theme.Fonts.UI
	fsStatusLabel.TextSize = 13
	fsStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	fsStatusLabel.Parent = fsStatusFrame
	
	local fsStatusValue = Instance.new("TextLabel")
	fsStatusValue.Size = UDim2.new(0, 120, 1, 0)
	fsStatusValue.Position = UDim2.new(1, -120, 0, 0)
	fsStatusValue.BackgroundTransparency = 1
	fsStatusValue.Text = FileSystem.enabled and "✓ Available" or "✗ Unavailable"
	fsStatusValue.TextColor3 = FileSystem.enabled and Theme.Colors.Success or Theme.Colors.Error
	fsStatusValue.Font = Theme.Fonts.UI
	fsStatusValue.TextSize = 13
	fsStatusValue.TextXAlignment = Enum.TextXAlignment.Right
	fsStatusValue.Parent = fsStatusFrame
	
	return {
		screenGui = screenGui,
		mainFrame = mainFrame,
		dragHandle = dragHandle,
		closeBtn = closeBtn,
		sidebar = sidebar,
		fileList = fileList,
		fileListLayout = fileListLayout,
		toggleSidebarBtn = toggleSidebarBtn,
		settingsBtn = settingsBtn,
		newFileBtn = newFileBtn,
		refreshBtn = refreshBtn,
		codeContainer = codeContainer,
		lineNumbers = lineNumbers,
		codeDisplay = codeDisplay,
		codeInput = codeInput,
		cursor = cursor,
		errorDisplay = errorDisplay,
		intellisense = intellisense,
		intellisenseList = intellisenseList,
		outputPanel = outputPanel,
		outputText = outputText,
		runBtn = runBtn,
		clearBtn = clearBtn,
		saveBtn = saveBtn,
		currentFileLabel = currentFileLabel,
		helpLabel = helpLabel,
		settingsPanel = settingsPanel,
		closeSettingsBtn = closeSettingsBtn,
		fontSizeInput = fontSizeInput,
		autoSaveBtn = autoSaveBtn,
		errorDetectBtn = errorDetectBtn,
	}
end

-- ============================================
-- MAIN LOGIC
-- ============================================

local UI = createEditor()
local isVisible = false
local intellisenseVisible = false
local currentCompletions = {}
local selectedIndex = 1
local currentFilePath = nil
local sidebarVisible = false
local settingsVisible = false

-- Update line numbers
local function updateLineNumbers()
	local text = UI.codeInput.Text
	local lines = {}
	local count = 0
	for _ in text:gmatch("[^\n]*") do
		count = count + 1
		table.insert(lines, tostring(count))
	end
	UI.lineNumbers.Text = table.concat(lines, "\n")
end

-- Update syntax highlighting
local function updateHighlight()
	local text = UI.codeInput.Text
	if text == "" then
		UI.codeDisplay.Text = ""
	else
		UI.codeDisplay.Text = highlightCode(text)
	end
end

-- Update error display
local function updateErrors()
	if not Config.enableErrorDetection then
		UI.errorDisplay.Visible = false
		return
	end
	
	local text = UI.codeInput.Text
	if #text > 0 then
		local errors = detectErrors(text)
		if #errors > 0 then
			local err = errors[1]
			UI.errorDisplay.Text = "Line " .. err.line .. ": " .. err.message
			UI.errorDisplay.TextColor3 = err.type == "warning" and Theme.Colors.Warning or Theme.Colors.Error
			UI.errorDisplay.Visible = true
		else
			UI.errorDisplay.Visible = false
		end
	else
		UI.errorDisplay.Visible = false
	end
end

-- Update cursor position
local function updateCursorPosition()
	local text = UI.codeInput.Text
	local cursorPos = UI.codeInput.CursorPosition
	if cursorPos <= 0 then cursorPos = 1 end
	
	-- Count lines and columns before cursor
	local lineNum = 1
	local colNum = 1
	for i = 1, math.min(cursorPos - 1, #text) do
		if string.sub(text, i, i) == "\n" then
			lineNum = lineNum + 1
			colNum = 1
		else
			colNum = colNum + 1
		end
	end
	
	-- Approximate character dimensions
	local charWidth = 8.4
	local lineHeight = Config.fontSize + 4
	
	-- Calculate position
	local x = (colNum - 1) * charWidth + 48
	local y = (lineNum - 1) * lineHeight
	
	-- Clamp to container bounds
	local maxX = UI.codeContainer.AbsoluteSize.X - 10
	local maxY = UI.codeContainer.AbsoluteSize.Y - lineHeight - 5
	
	x = math.min(x, maxX)
	y = math.min(y, maxY)
	
	UI.cursor.Position = UDim2.new(0, x, 0, y)
	UI.cursor.Size = UDim2.new(0, 2, 0, Config.fontSize + 2)
end

-- Show intellisense
local function showIntellisense(completions)
	currentCompletions = completions
	selectedIndex = 1
	
	-- Clear existing items
	for _, child in ipairs(UI.intellisenseList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	if #completions == 0 then
		UI.intellisense.Visible = false
		intellisenseVisible = false
		return
	end
	
	-- Create items
	for i, completion in ipairs(completions) do
		local item = Instance.new("TextButton")
		item.Size = UDim2.new(1, 0, 0, 24)
		item.BackgroundColor3 = i == 1 and Theme.Colors.Selection or Theme.Colors.BackgroundLight
		item.Text = "  " .. completion.name .. (completion.detail and ("  [" .. completion.detail .. "]") or "")
		item.TextColor3 = Theme.Colors.Foreground
		item.Font = Theme.Fonts.Main
		item.TextSize = 13
		item.TextXAlignment = Enum.TextXAlignment.Left
		item.ZIndex = 102
		item.Parent = UI.intellisenseList
		
		item.MouseButton1Click:Connect(function()
			-- Apply completion
			local text = UI.codeInput.Text
			local cursorPos = UI.codeInput.CursorPosition
			
			local wordStart = cursorPos
			while wordStart > 1 and string.sub(text, wordStart - 1, wordStart - 1):match("[%w_]") do
				wordStart = wordStart - 1
			end
			
			local before = string.sub(text, 1, wordStart - 1)
			local after = string.sub(text, cursorPos)
			
			local insertText = completion.insertText or completion.name
			if completion.fullInsert then
				insertText = completion.fullInsert
			end
			
			UI.codeInput.Text = before .. insertText .. after
			UI.codeInput.CursorPosition = #before + #insertText + 1
			
			UI.intellisense.Visible = false
			intellisenseVisible = false
			
			updateHighlight()
			updateLineNumbers()
			updateCursorPosition()
		end)
	end
	
	-- Size and position
	local height = math.min(#completions * 24, 200)
	UI.intellisense.Size = UDim2.new(0, 280, 0, height)
	
	-- Position near cursor
	local cursorX = UI.cursor.Position.X.Offset
	local cursorY = UI.cursor.Position.Y.Offset
	UI.intellisense.Position = UDim2.new(0, math.min(cursorX, UI.codeContainer.AbsoluteSize.X - 290), 0, math.min(cursorY + 22, UI.codeContainer.AbsoluteSize.Y - height - 10))
	
	UI.intellisenseList.CanvasSize = UDim2.new(0, 0, 0, #completions * 24)
	UI.intellisense.Visible = true
	intellisenseVisible = true
end

-- Hide intellisense
local function hideIntellisense()
	UI.intellisense.Visible = false
	intellisenseVisible = false
end

-- Highlight selected item
local function highlightSelectedItem()
	local items = {}
	for _, child in ipairs(UI.intellisenseList:GetChildren()) do
		if child:IsA("TextButton") then
			table.insert(items, child)
		end
	end
	
	for i, item in ipairs(items) do
		item.BackgroundColor3 = (i == selectedIndex) and Theme.Colors.Selection or Theme.Colors.BackgroundLight
	end
end

-- Apply intellisense completion
local function applyCompletion(index)
	local completion = currentCompletions[index]
	if not completion then return end
	
	local text = UI.codeInput.Text
	local cursorPos = UI.codeInput.CursorPosition
	
	local wordStart = cursorPos
	while wordStart > 1 and string.sub(text, wordStart - 1, wordStart - 1):match("[%w_]") do
		wordStart = wordStart - 1
	end
	
	local before = string.sub(text, 1, wordStart - 1)
	local after = string.sub(text, cursorPos)
	
	local insertText = completion.insertText or completion.name
	if completion.fullInsert then
		insertText = completion.fullInsert
	end
	
	UI.codeInput.Text = before .. insertText .. after
	UI.codeInput.CursorPosition = #before + #insertText + 1
	
	hideIntellisense()
	updateHighlight()
	updateLineNumbers()
	updateCursorPosition()
end

-- Trigger intellisense
local lastTriggerTime = 0
local function triggerIntellisense()
	if not Config.enableIntellisense then return end
	
	local now = tick()
	if now - lastTriggerTime < 0.05 then return end
	lastTriggerTime = now
	
	local cursorPos = UI.codeInput.CursorPosition
	local text = UI.codeInput.Text
	
	if cursorPos <= 0 then cursorPos = 1 end
	
	local completions, context, wordStart = getCompletions(text, cursorPos)
	
	if #completions > 0 then
		showIntellisense(completions)
	else
		hideIntellisense()
	end
end

-- Refresh file list
local function refreshFileList()
	-- Clear existing
	for _, child in ipairs(UI.fileList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	if not FileSystem.enabled then
		-- Show message
		local msg = Instance.new("TextLabel")
		msg.Size = UDim2.new(1, 0, 0, 40)
		msg.BackgroundTransparency = 1
		msg.Text = "File system unavailable"
		msg.TextColor3 = Theme.Colors.Comment
		msg.Font = Theme.Fonts.UI
		msg.TextSize = 12
		msg.TextWrapped = true
		msg.Parent = UI.fileList
		return
	end
	
	-- Add scripts folder item
	local scriptsFolder = Instance.new("TextButton")
	scriptsFolder.Size = UDim2.new(1, 0, 0, 26)
	scriptsFolder.BackgroundColor3 = Theme.Colors.BackgroundDark
	scriptsFolder.Text = ""
	scriptsFolder.Parent = UI.fileList
	
	local folderIcon = Instance.new("TextLabel")
	folderIcon.Size = UDim2.new(0, 24, 1, 0)
	folderIcon.Position = UDim2.new(0, 4, 0, 0)
	folderIcon.BackgroundTransparency = 1
	folderIcon.Text = "📁"
	folderIcon.TextSize = 12
	folderIcon.Parent = scriptsFolder
	
	local folderName = Instance.new("TextLabel")
	folderName.Size = UDim2.new(1, -30, 1, 0)
	folderName.Position = UDim2.new(0, 24, 0, 0)
	folderName.BackgroundTransparency = 1
	folderName.Text = "Scripts"
	folderName.TextColor3 = Theme.Colors.Foreground
	folderName.Font = Theme.Fonts.UI
	folderName.TextSize = 12
	folderName.TextXAlignment = Enum.TextXAlignment.Left
	folderName.Parent = scriptsFolder
	
	-- List files in Scripts folder
	local files = FileSystem.listFiles("DraculaEditor/Scripts")
	for _, filePath in ipairs(files) do
		local fileName = filePath:match("([^/]+)$") or filePath
		local ext = fileName:match("%.(%w+)$") or ""
		
		local fileBtn = Instance.new("TextButton")
		fileBtn.Size = UDim2.new(1, 0, 0, 26)
		fileBtn.BackgroundColor3 = Theme.Colors.BackgroundDark
		fileBtn.Text = ""
		fileBtn.Parent = UI.fileList
		
		local fileIcon = Instance.new("TextLabel")
		fileIcon.Size = UDim2.new(0, 24, 1, 0)
		fileIcon.Position = UDim2.new(0, 20, 0, 0)
		fileIcon.BackgroundTransparency = 1
		fileIcon.Text = ext == "lua" and "📜" or "📄"
		fileIcon.TextSize = 12
		fileIcon.Parent = fileBtn
		
		local fileNameLabel = Instance.new("TextLabel")
		fileNameLabel.Size = UDim2.new(1, -50, 1, 0)
		fileNameLabel.Position = UDim2.new(0, 42, 0, 0)
		fileNameLabel.BackgroundTransparency = 1
		fileNameLabel.Text = fileName
		fileNameLabel.TextColor3 = Theme.Colors.Foreground
		fileNameLabel.Font = Theme.Fonts.UI
		fileNameLabel.TextSize = 12
		fileNameLabel.TextXAlignment = Enum.TextXAlignment.Left
		fileNameLabel.Parent = fileBtn
		
		fileBtn.MouseButton1Click:Connect(function()
			-- Load file
			local content = FileSystem.readFile(filePath)
			if content then
				UI.codeInput.Text = content
				currentFilePath = filePath
				UI.currentFileLabel.Text = "📄 " .. fileName
				ConfigManager.addRecentFile(filePath)
				updateHighlight()
				updateLineNumbers()
			end
		end)
	end
	
	UI.fileList.CanvasSize = UDim2.new(0, 0, 0, #files * 26 + 26)
end

-- Run code
local function runCode()
	local code = UI.codeInput.Text
	UI.outputText.Text = "[Running...]"
	
	local success, result = pcall(function()
		local fn, err = loadstring(code)
		if not fn then
			UI.outputText.Text = "[✗] Syntax Error: " .. tostring(err):sub(1, 200)
			return
		end
		
		-- Capture print output
		local outputs = {}
		local oldPrint = print
		local oldWarn = warn
		
		_G.print = function(...)
			local args = {...}
			local str = ""
			for i, arg in ipairs(args) do
				str = str .. tostring(arg) .. (i < #args and "\t" or "")
			end
			table.insert(outputs, str)
		end
		
		_G.warn = function(...)
			local args = {...}
			local str = "⚠ "
			for i, arg in ipairs(args) do
				str = str .. tostring(arg) .. (i < #args and "\t" or "")
			end
			table.insert(outputs, str)
		end
		
		local ok, execResult = pcall(fn)
		
		_G.print = oldPrint
		_G.warn = oldWarn
		
		if not ok then
			UI.outputText.Text = "[✗] Error: " .. tostring(execResult):sub(1, 200)
		elseif #outputs > 0 then
			UI.outputText.Text = table.concat(outputs, "\n"):sub(1, 400)
		else
			UI.outputText.Text = "[✓] Code executed successfully"
		end
	end)
	
	if not success then
		UI.outputText.Text = "[✗] Error: " .. tostring(result):sub(1, 200)
	end
end

-- Save file
local function saveCurrentFile()
	if not FileSystem.enabled then
		UI.outputText.Text = "[✗] File system not available"
		return
	end
	
	local fileName = currentFilePath and currentFilePath:match("([^/]+)$") or ("script_" .. os.time() .. ".lua")
	local filePath = currentFilePath or "DraculaEditor/Scripts/" .. fileName
	
	local content = UI.codeInput.Text
	local success, err = FileSystem.writeFile(filePath, content)
	
	if success then
		UI.outputText.Text = "[✓] Saved: " .. fileName
		currentFilePath = filePath
		UI.currentFileLabel.Text = "📄 " .. fileName
		ConfigManager.addRecentFile(filePath)
		refreshFileList()
	else
		UI.outputText.Text = "[✗] Failed to save: " .. tostring(err)
	end
end

-- Toggle editor
local function toggle()
	isVisible = not isVisible
	UI.mainFrame.Visible = isVisible
	if isVisible then
		UI.codeInput:CaptureFocus()
		updateCursorPosition()
	end
end

-- Toggle sidebar
local function toggleSidebar()
	sidebarVisible = not sidebarVisible
	UI.sidebar.Visible = sidebarVisible
	
	if sidebarVisible then
		UI.codeContainer.Size = UDim2.new(1, -220, 1, -130)
		UI.codeContainer.Position = UDim2.new(0, 210, 0, 46)
		refreshFileList()
	else
		UI.codeContainer.Size = UDim2.new(1, -20, 1, -130)
		UI.codeContainer.Position = UDim2.new(0, 10, 0, 46)
	end
end

-- Toggle settings
local function toggleSettings()
	settingsVisible = not settingsVisible
	UI.settingsPanel.Visible = settingsVisible
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

-- Text changed
UI.codeInput:GetPropertyChangedSignal("Text"):Connect(function()
	updateHighlight()
	updateLineNumbers()
	updateCursorPosition()
	
	-- Debounce intellisense and error detection
	task.delay(0.1, function()
		if UI.codeInput.Text ~= "" then
			triggerIntellisense()
			updateErrors()
		end
	end)
end)

-- Cursor position changed
UI.codeInput:GetPropertyChangedSignal("CursorPosition"):Connect(function()
	updateCursorPosition()
	if intellisenseVisible then
		triggerIntellisense()
	end
end)

-- Focus events
UI.codeInput.Focused:Connect(function()
	UI.cursor.Visible = true
end)

UI.codeInput.FocusLost:Connect(function()
	UI.cursor.Visible = false
end)

-- Keyboard input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.F8 then
		toggle()
	end
	
	if not isVisible then return end
	
	if input.KeyCode == Enum.KeyCode.F5 then
		runCode()
	end
	
	-- Intellisense navigation
	if intellisenseVisible then
		if input.KeyCode == Enum.KeyCode.Down then
			selectedIndex = math.min(selectedIndex + 1, #currentCompletions)
			highlightSelectedItem()
		elseif input.KeyCode == Enum.KeyCode.Up then
			selectedIndex = math.max(selectedIndex - 1, 1)
			highlightSelectedItem()
		elseif input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.Return then
			applyCompletion(selectedIndex)
		elseif input.KeyCode == Enum.KeyCode.Escape then
			hideIntellisense()
		end
	end
	
	-- Save with Ctrl+S
	if input.KeyCode == Enum.KeyCode.S and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		saveCurrentFile()
	end
	
	-- Open with Ctrl+O
	if input.KeyCode == Enum.KeyCode.O and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		toggleSidebar()
	end
end)

-- Button clicks
UI.runBtn.MouseButton1Click:Connect(runCode)
UI.clearBtn.MouseButton1Click:Connect(function()
	UI.outputText.Text = ""
end)
UI.closeBtn.MouseButton1Click:Connect(toggle)
UI.saveBtn.MouseButton1Click:Connect(saveCurrentFile)
UI.toggleSidebarBtn.MouseButton1Click:Connect(toggleSidebar)
UI.settingsBtn.MouseButton1Click:Connect(toggleSettings)
UI.closeSettingsBtn.MouseButton1Click:Connect(toggleSettings)
UI.newFileBtn.MouseButton1Click:Connect(function()
	currentFilePath = nil
	UI.codeInput.Text = "-- New Script\n\n"
	UI.currentFileLabel.Text = "📄 Untitled.lua"
end)
UI.refreshBtn.MouseButton1Click:Connect(refreshFileList)

-- Settings handlers
UI.fontSizeInput.FocusLost:Connect(function()
	local newSize = tonumber(UI.fontSizeInput.Text)
	if newSize and newSize >= 8 and newSize <= 32 then
		Config.fontSize = math.floor(newSize)
		UI.codeInput.TextSize = Config.fontSize
		UI.codeDisplay.TextSize = Config.fontSize
		UI.lineNumbers.TextSize = Config.fontSize
		updateHighlight()
		updateCursorPosition()
		ConfigManager.save()
	end
	UI.fontSizeInput.Text = tostring(Config.fontSize)
end)

UI.autoSaveBtn.MouseButton1Click:Connect(function()
	Config.autoSave = not Config.autoSave
	UI.autoSaveBtn.BackgroundColor3 = Config.autoSave and Theme.Colors.Success or Theme.Colors.Error
	UI.autoSaveBtn.Text = Config.autoSave and "ON" or "OFF"
	ConfigManager.save()
end)

UI.errorDetectBtn.MouseButton1Click:Connect(function()
	Config.enableErrorDetection = not Config.enableErrorDetection
	UI.errorDetectBtn.BackgroundColor3 = Config.enableErrorDetection and Theme.Colors.Success or Theme.Colors.Error
	UI.errorDetectBtn.Text = Config.enableErrorDetection and "ON" or "OFF"
	ConfigManager.save()
	if not Config.enableErrorDetection then
		UI.errorDisplay.Visible = false
	else
		updateErrors()
	end
end)

-- Dragging
local dragging = false
local dragStart, startPos

UI.dragHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = UI.mainFrame.Position
	end
end)

UI.dragHandle.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		UI.mainFrame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

-- Set initial code
UI.codeInput.Text = "-- Welcome to Dracula Code Editor!\n-- Press F5 to run your code\n-- Press Ctrl+S to save\n-- Press Ctrl+O to open file browser\n\nprint('Hello, Dracula!')\n"
updateHighlight()
updateLineNumbers()
updateCursorPosition()

print("🦇 Dracula Code Editor loaded! Press F8 to toggle.")
print("   File System: " .. (FileSystem.enabled and "Available" or "Unavailable"))
