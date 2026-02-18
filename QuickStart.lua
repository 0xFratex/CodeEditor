--[[
	Dracula Code Editor - Quick Start Script
	Features: Syntax Highlighting, Intellisense, Custom Input
	
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

local function highlightCode(code)
	local result = {}
	local pos = 1
	local len = #code
	
	local function peek(offset)
		return string.sub(code, pos + (offset or 0), pos + (offset or 0))
	end
	
	while pos <= len do
		local char = peek()
		
		-- Whitespace (preserve as-is)
		if char:match("%s") then
			local ws = ""
			while pos <= len and peek():match("%s") do
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
				else
					str = str .. string.sub(code, pos, pos)
					pos = pos + 1
				end
			end
			table.insert(result, '<font color="' .. colorToHex(Theme.Colors.String) .. '">' .. escapeXml(str) .. '</font>')
		
		-- Numbers
		elseif char:match("%d") then
			local num = ""
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
-- INTELLISENSE
-- ============================================

local IntellisenseData = {
	Keywords = {"and", "break", "do", "else", "elseif", "end", "false", "for", "function",
		"if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while", "continue"},
	Builtins = {"print", "warn", "error", "assert", "type", "typeof", "tostring", "tonumber",
		"pairs", "ipairs", "next", "select", "pcall", "xpcall", "tick", "time", "wait", "spawn", "delay",
		"Instance", "Color3", "Vector3", "Vector2", "CFrame", "UDim", "UDim2", "BrickColor", "Enum",
		"task", "string", "table", "math", "os"},
	Services = {"Players", "Lighting", "ReplicatedStorage", "ReplicatedFirst", "ServerStorage",
		"ServerScriptService", "StarterGui", "StarterPack", "StarterPlayer", "TweenService",
		"UserInputService", "RunService", "HttpService", "DataStoreService", "TeleportService"},
	Methods = {"Clone", "Destroy", "FindFirstChild", "FindFirstChildOfClass", "GetChildren",
		"GetDescendants", "IsA", "WaitForChild", "ClearAllChildren", "GetAttribute", "SetAttribute"},
}

local function getCompletions(text, cursorPos)
	local completions = {}
	local context = "general"
	
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
			if prefix == "" or service:lower():find(prefix, 1, true) then
				table.insert(completions, {name = service, kind = "Service", insertText = service})
			end
		end
		return completions, context, wordStart
	elseif before:match("workspace%.$") then
		context = "workspace"
		local success, children = pcall(function() return workspace:GetChildren() end)
		if success then
			for _, child in ipairs(children) do
				if prefix == "" or child.Name:lower():find(prefix, 1, true) then
					table.insert(completions, {name = child.Name, kind = "Instance", insertText = child.Name, detail = child.ClassName})
				end
			end
		end
		return completions, context, wordStart
	elseif before:match(":%w-$") or before:match(":%w*$") then
		context = "method"
		for _, method in ipairs(IntellisenseData.Methods) do
			if prefix == "" or method:lower():find(prefix, 1, true) then
				table.insert(completions, {name = method, kind = "Method", insertText = method .. "()"
				})
			end
		end
		return completions, context, wordStart
	elseif before:match("%.$") then
		context = "property"
		-- Could add property completions here
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
						if i <= 15 then
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
	
	-- General completions
	for _, kw in ipairs(IntellisenseData.Keywords) do
		if prefix == "" or kw:lower():find(prefix, 1, true) then
			table.insert(completions, {name = kw, kind = "Keyword", insertText = kw})
		end
	end
	
	for _, builtin in ipairs(IntellisenseData.Builtins) do
		if prefix == "" or builtin:lower():find(prefix, 1, true) then
			table.insert(completions, {name = builtin, kind = "Builtin", insertText = builtin .. "()"})
		end
	end
	
	table.insert(completions, {name = "game", kind = "Global", insertText = "game"})
	table.insert(completions, {name = "workspace", kind = "Global", insertText = "workspace"})
	
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
	mainFrame.Size = UDim2.new(0, 900, 0, 600)
	mainFrame.Position = UDim2.new(0.5, -450, 0.5, -300)
	mainFrame.BackgroundColor3 = Theme.Colors.Background
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui
	
	-- Drag Handle
	local dragHandle = Instance.new("Frame")
	dragHandle.Name = "DragHandle"
	dragHandle.Size = UDim2.new(1, 0, 0, 36)
	dragHandle.BackgroundColor3 = Theme.Colors.BackgroundDark
	dragHandle.BorderSizePixel = 0
	dragHandle.Parent = mainFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -100, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🦇 Dracula Code Editor"
	title.TextColor3 = Theme.Colors.Foreground
	title.Font = Theme.Fonts.Title
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = dragHandle
	
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
	
	-- Code Container (holds both input and display)
	local codeContainer = Instance.new("Frame")
	codeContainer.Name = "CodeContainer"
	codeContainer.Size = UDim2.new(1, -20, 1, -120)
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
	lineNumbers.TextSize = 14
	lineNumbers.TextXAlignment = Enum.TextXAlignment.Right
	lineNumbers.TextYAlignment = Enum.TextYAlignment.Top
	lineNumbers.Parent = lineNumbersFrame
	
	-- Code Display (shows highlighted code)
	local codeDisplay = Instance.new("TextLabel")
	codeDisplay.Name = "CodeDisplay"
	codeDisplay.Size = UDim2.new(1, -50, 1, 0)
	codeDisplay.Position = UDim2.new(0, 48, 0, 0)
	codeDisplay.BackgroundTransparency = 1
	codeDisplay.Text = ""
	codeDisplay.TextColor3 = Theme.Colors.Foreground
	codeDisplay.Font = Theme.Fonts.Main
	codeDisplay.TextSize = 14
	codeDisplay.TextXAlignment = Enum.TextXAlignment.Left
	codeDisplay.TextYAlignment = Enum.TextYAlignment.Top
	codeDisplay.RichText = true
	codeDisplay.Parent = codeContainer
	
	-- Code Input (transparent, captures keystrokes)
	local codeInput = Instance.new("TextBox")
	codeInput.Name = "CodeInput"
	codeInput.Size = UDim2.new(1, -50, 1, 0)
	codeInput.Position = UDim2.new(0, 48, 0, 0)
	codeInput.BackgroundTransparency = 1
	codeInput.TextColor3 = Color3.new(0, 0, 0) -- Transparent text
	codeInput.TextTransparency = 1
	codeInput.Font = Theme.Fonts.Main
	codeInput.TextSize = 14
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
	outputPanel.Size = UDim2.new(1, -20, 0, 60)
	outputPanel.Position = UDim2.new(0, 10, 1, -70)
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
	
	-- Output Text
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
	
	-- Help Label
	local helpLabel = Instance.new("TextLabel")
	helpLabel.Size = UDim2.new(0, 300, 0, 18)
	helpLabel.Position = UDim2.new(0, 10, 1, -18)
	helpLabel.BackgroundTransparency = 1
	helpLabel.Text = "F8: Toggle | F5: Run | Tab/Enter: Accept | ↑↓: Navigate"
	helpLabel.TextColor3 = Theme.Colors.Comment
	helpLabel.Font = Theme.Fonts.UI
	helpLabel.TextSize = 11
	helpLabel.Parent = mainFrame
	
	return {
		screenGui = screenGui,
		mainFrame = mainFrame,
		dragHandle = dragHandle,
		closeBtn = closeBtn,
		codeContainer = codeContainer,
		lineNumbers = lineNumbers,
		codeDisplay = codeDisplay,
		codeInput = codeInput,
		intellisense = intellisense,
		intellisenseList = intellisenseList,
		outputPanel = outputPanel,
		outputText = outputText,
		runBtn = runBtn,
		clearBtn = clearBtn,
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
local cursorPosition = 1

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

-- Get cursor position in pixels (approximate)
local function getCursorPixelPosition()
	local text = UI.codeInput.Text
	local cursorPos = UI.codeInput.CursorPosition
	
	-- Count lines and columns
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
	
	-- Approximate character width (14px font size, monospace)
	local charWidth = 8.4
	local lineHeight = 18
	
	local x = (colNum - 1) * charWidth + 48
	local y = (lineNum - 1) * lineHeight
	
	return x, y
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
			
			-- Find word start
			local wordStart = cursorPos
			while wordStart > 1 and string.sub(text, wordStart - 1, wordStart - 1):match("[%w_]") do
				wordStart = wordStart - 1
			end
			
			local before = string.sub(text, 1, wordStart - 1)
			local after = string.sub(text, cursorPos)
			
			local insertText = completion.insertText or completion.name
			
			-- Handle GetChildren results
			if completion.fullInsert then
				-- For GetChildren completions, replace the whole expression
				local exprMatch = string.match(text:sub(1, wordStart - 1), "(.-):GetChildren%(%)[%s]*$")
				if exprMatch then
					before = string.sub(text, 1, #text - #string.match(text:sub(wordStart), ".*$"))
					before = text:sub(1, wordStart - 1)
					insertText = completion.fullInsert
				end
			end
			
			UI.codeInput.Text = before .. insertText .. after
			UI.codeInput.CursorPosition = #before + #insertText + 1
			
			UI.intellisense.Visible = false
			intellisenseVisible = false
			
			updateHighlight()
			updateLineNumbers()
		end)
	end
	
	-- Size and position
	local height = math.min(#completions * 24, 200)
	UI.intellisense.Size = UDim2.new(0, 280, 0, height)
	
	local cursorX, cursorY = getCursorPixelPosition()
	UI.intellisense.Position = UDim2.new(0, math.min(cursorX, UI.codeContainer.AbsoluteSize.X - 290), 0, math.min(cursorY + 20, UI.codeContainer.AbsoluteSize.Y - height - 10))
	
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
	
	-- Find word start
	local wordStart = cursorPos
	while wordStart > 1 and string.sub(text, wordStart - 1, wordStart - 1):match("[%w_]") do
		wordStart = wordStart - 1
	end
	
	local before = string.sub(text, 1, wordStart - 1)
	local after = string.sub(text, cursorPos)
	
	local insertText = completion.insertText or completion.name
	
	-- Handle GetChildren results
	if completion.fullInsert then
		insertText = completion.fullInsert
	end
	
	UI.codeInput.Text = before .. insertText .. after
	UI.codeInput.CursorPosition = #before + #insertText + 1
	
	hideIntellisense()
	updateHighlight()
	updateLineNumbers()
end

-- Trigger intellisense
local lastTriggerTime = 0
local function triggerIntellisense()
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

-- Run code
local function runCode()
	local code = UI.codeInput.Text
	UI.outputText.Text = "[Running...]"
	
	local success, result = pcall(function()
		local fn, err = loadstring(code)
		if not fn then
			UI.outputText.Text = "[✗] Syntax Error: " .. tostring(err):sub(1, 150)
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
			UI.outputText.Text = "[✗] Error: " .. tostring(execResult):sub(1, 150)
		elseif #outputs > 0 then
			UI.outputText.Text = table.concat(outputs, "\n"):sub(1, 300)
		else
			UI.outputText.Text = "[✓] Code executed successfully"
		end
	end)
	
	if not success then
		UI.outputText.Text = "[✗] Error: " .. tostring(result):sub(1, 150)
	end
end

-- Toggle editor
local function toggle()
	isVisible = not isVisible
	UI.mainFrame.Visible = isVisible
	if isVisible then
		UI.codeInput:CaptureFocus()
	end
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

-- Text changed
UI.codeInput:GetPropertyChangedSignal("Text"):Connect(function()
	updateHighlight()
	updateLineNumbers()
	
	-- Debounce intellisense trigger
	task.delay(0.05, function()
		if UI.codeInput.Text ~= "" then
			triggerIntellisense()
		end
	end)
end)

-- Cursor position changed - for intellisense repositioning
UI.codeInput:GetPropertyChangedSignal("CursorPosition"):Connect(function()
	if intellisenseVisible then
		triggerIntellisense()
	end
end)

-- Keyboard input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.F8 then
		toggle()
	end
	
	if not isVisible then return end
	
	-- Run with F5
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
end)

-- Button clicks
UI.runBtn.MouseButton1Click:Connect(runCode)
UI.clearBtn.MouseButton1Click:Connect(function()
	UI.outputText.Text = ""
end)
UI.closeBtn.MouseButton1Click:Connect(toggle)

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
UI.codeInput.Text = "-- Welcome to Dracula Code Editor!\n-- Press F5 to run your code\n\nprint('Hello, Dracula!')\n"
updateHighlight()
updateLineNumbers()

print("🦇 Dracula Code Editor loaded! Press F8 to toggle.")
