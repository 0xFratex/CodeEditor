--[[
	Dracula Code Editor - GitHub Loader
	Press F8 to toggle the editor!
	
	Usage:
		loadstring(game:HttpGet("https://raw.githubusercontent.com/0xFratex/CodeEditor/main/Loader.lua"))()
]]

-- Wait for game to load
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Wait for player
local player = Players.LocalPlayer
if not player then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	player = Players.LocalPlayer
end

local playerGui = player:WaitForChild("PlayerGui")
task.wait(0.5)

print("🦇 Dracula Code Editor - Loading...")

-- ============================================
-- Global storage
-- ============================================
_G.DraculaEditor = _G.DraculaEditor or {}

-- ============================================
-- Theme Module (inline)
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
		HeaderHeight = 40,
		SidebarWidth = 220,
		TabHeight = 32,
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
_G.DraculaEditor.Theme = Theme

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
		
		-- Whitespace
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
	
	local wordStart = cursorPos
	while wordStart > 1 and string.sub(text, wordStart - 1, wordStart - 1):match("[%w_]") do
		wordStart = wordStart - 1
	end
	local prefix = string.sub(text, wordStart, cursorPos - 1):lower()
	
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
				table.insert(completions, {name = method, kind = "Method", insertText = method .. "()"})
			end
		end
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
-- Main Editor GUI (inline)
-- ============================================
local Editor = {}
Editor.State = {
	IsVisible = false,
	OpenFiles = {},
	ActiveFile = nil,
}

-- Create main frame
function Editor.CreateGUI()
	-- Create ScreenGui container
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DraculaEditorGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	local frame = Instance.new("Frame")
	frame.Name = "DraculaEditor"
	frame.Size = UDim2.new(0, 900, 0, 600)
	frame.Position = UDim2.new(0.5, -450, 0.5, -300)
	frame.BackgroundColor3 = Theme.Colors.Background
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = screenGui
	
	-- Drag handle
	local drag = Instance.new("Frame")
	drag.Size = UDim2.new(1, 0, 0, Theme.UI.HeaderHeight)
	drag.BackgroundColor3 = Theme.Colors.BackgroundDark
	drag.BorderSizePixel = 0
	drag.Parent = frame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -100, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🦇 Dracula Code Editor"
	title.TextColor3 = Theme.Colors.Foreground
	title.Font = Theme.Fonts.Title
	title.TextSize = Theme.FontSizes.Large
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = drag
	
	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundColor3 = Theme.Colors.Error
	closeBtn.Text = "×"
	closeBtn.TextColor3 = Theme.Colors.White
	closeBtn.Font = Theme.Fonts.UI
	closeBtn.TextSize = 20
	closeBtn.Parent = drag
	Theme.CreateCorner(closeBtn, 4)
	closeBtn.MouseButton1Click:Connect(function()
		Editor.Hide()
	end)
	
	-- Dragging
	local dragging, dragStart, startPos = false, nil, nil
	drag.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)
	drag.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	
	-- Code container
	local codeContainer = Instance.new("Frame")
	codeContainer.Name = "CodeContainer"
	codeContainer.Size = UDim2.new(1, -20, 1, -120)
	codeContainer.Position = UDim2.new(0, 10, 0, 50)
	codeContainer.BackgroundColor3 = Theme.Colors.BackgroundDark
	codeContainer.Parent = frame
	Theme.CreateCorner(codeContainer, 8)
	
	-- Line numbers
	local lineNumbersFrame = Instance.new("Frame")
	lineNumbersFrame.Size = UDim2.new(0, 45, 1, 0)
	lineNumbersFrame.BackgroundColor3 = Theme.Colors.BackgroundDark
	lineNumbersFrame.BorderSizePixel = 0
	lineNumbersFrame.Parent = codeContainer
	
	local lineNumbers = Instance.new("TextLabel")
	lineNumbers.Name = "Numbers"
	lineNumbers.Size = UDim2.new(1, -8, 1, 0)
	lineNumbers.Position = UDim2.new(0, 4, 0, 0)
	lineNumbers.BackgroundTransparency = 1
	lineNumbers.Text = "1"
	lineNumbers.TextColor3 = Theme.Colors.Comment
	lineNumbers.Font = Theme.Fonts.Mono
	lineNumbers.TextSize = Theme.FontSizes.Code
	lineNumbers.TextXAlignment = Enum.TextXAlignment.Right
	lineNumbers.TextYAlignment = Enum.TextYAlignment.Top
	lineNumbers.Parent = lineNumbersFrame
	
	-- Code display (syntax highlighted)
	local codeDisplay = Instance.new("TextLabel")
	codeDisplay.Name = "CodeDisplay"
	codeDisplay.Size = UDim2.new(1, -55, 1, 0)
	codeDisplay.Position = UDim2.new(0, 48, 0, 0)
	codeDisplay.BackgroundTransparency = 1
	codeDisplay.Text = ""
	codeDisplay.TextColor3 = Theme.Colors.Foreground
	codeDisplay.Font = Theme.Fonts.Mono
	codeDisplay.TextSize = Theme.FontSizes.Code
	codeDisplay.TextXAlignment = Enum.TextXAlignment.Left
	codeDisplay.TextYAlignment = Enum.TextYAlignment.Top
	codeDisplay.RichText = true
	codeDisplay.Parent = codeContainer
	
	-- Code input (transparent)
	local editor = Instance.new("TextBox")
	editor.Name = "CodeInput"
	editor.Size = UDim2.new(1, -55, 1, 0)
	editor.Position = UDim2.new(0, 48, 0, 0)
	editor.BackgroundTransparency = 1
	editor.TextColor3 = Color3.new(0, 0, 0)
	editor.TextTransparency = 1
	editor.Font = Theme.Fonts.Mono
	editor.TextSize = Theme.FontSizes.Code
	editor.TextXAlignment = Enum.TextXAlignment.Left
	editor.TextYAlignment = Enum.TextYAlignment.Top
	editor.MultiLine = true
	editor.ClearTextOnFocus = false
	editor.Text = "-- Welcome to Dracula Code Editor!\n-- Press F5 to run your code\n\nprint('Hello, Dracula!')\n"
	editor.PlaceholderText = ""
	editor.Parent = codeContainer
	
	-- Intellisense
	local intellisense = Instance.new("Frame")
	intellisense.Name = "Intellisense"
	intellisense.Size = UDim2.new(0, 280, 0, 0)
	intellisense.BackgroundColor3 = Theme.Colors.BackgroundLight
	intellisense.BorderSizePixel = 0
	intellisense.Visible = false
	intellisense.ZIndex = 100
	intellisense.Parent = codeContainer
	Theme.CreateCorner(intellisense, 6)
	Theme.CreateStroke(intellisense, Theme.Colors.Border)
	
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
	
	-- Output
	local output = Instance.new("Frame")
	output.Name = "Output"
	output.Size = UDim2.new(1, -20, 0, 60)
	output.Position = UDim2.new(0, 10, 1, -70)
	output.BackgroundColor3 = Theme.Colors.BackgroundDark
	output.Parent = frame
	Theme.CreateCorner(output, 6)
	
	local outputHeader = Instance.new("Frame")
	outputHeader.Size = UDim2.new(1, 0, 0, 26)
	outputHeader.BackgroundColor3 = Theme.Colors.BackgroundLight
	outputHeader.BorderSizePixel = 0
	outputHeader.Parent = output
	Theme.CreateCorner(outputHeader, 6)
	
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
	
	-- Run button
	local runBtn = Instance.new("TextButton")
	runBtn.Size = UDim2.new(0, 80, 0, 22)
	runBtn.Position = UDim2.new(1, -90, 0, 2)
	runBtn.BackgroundColor3 = Theme.Colors.Success
	runBtn.Text = "▶ Run (F5)"
	runBtn.TextColor3 = Theme.Colors.Background
	runBtn.Font = Theme.Fonts.UI
	runBtn.TextSize = 12
	runBtn.Parent = outputHeader
	Theme.CreateCorner(runBtn, 4)
	
	-- Clear button
	local clearBtn = Instance.new("TextButton")
	clearBtn.Size = UDim2.new(0, 60, 0, 22)
	clearBtn.Position = UDim2.new(1, -160, 0, 2)
	clearBtn.BackgroundColor3 = Theme.Colors.Button
	clearBtn.Text = "Clear"
	clearBtn.TextColor3 = Theme.Colors.Foreground
	clearBtn.Font = Theme.Fonts.UI
	clearBtn.TextSize = 12
	clearBtn.Parent = outputHeader
	Theme.CreateCorner(clearBtn, 4)
	
	local outputText = Instance.new("TextLabel")
	outputText.Size = UDim2.new(1, -16, 1, -28)
	outputText.Position = UDim2.new(0, 8, 0, 28)
	outputText.BackgroundTransparency = 1
	outputText.Text = "[Dracula] Ready to code..."
	outputText.TextColor3 = Theme.Colors.Comment
	outputText.Font = Theme.Fonts.Mono
	outputText.TextSize = 13
	outputText.TextXAlignment = Enum.TextXAlignment.Left
	outputText.TextYAlignment = Enum.TextYAlignment.Top
	outputText.Parent = output
	
	-- Help label
	local help = Instance.new("TextLabel")
	help.Size = UDim2.new(0, 350, 0, 18)
	help.Position = UDim2.new(0, 10, 1, -18)
	help.BackgroundTransparency = 1
	help.Text = "F8: Toggle | F5: Run | Tab/Enter: Accept | ↑↓: Navigate | Esc: Close"
	help.TextColor3 = Theme.Colors.Comment
	help.Font = Theme.Fonts.UI
	help.TextSize = 11
	help.Parent = frame
	
	Editor.ScreenGui = screenGui
	Editor.Frame = frame
	Editor.Editor = editor
	Editor.CodeDisplay = codeDisplay
	Editor.LineNumbers = lineNumbers
	Editor.Intellisense = intellisense
	Editor.IntellisenseList = intellisenseList
	Editor.Output = outputText
	Editor.currentCompletions = {}
	Editor.selectedIndex = 1
	Editor.intellisenseVisible = false
	
	-- Update functions
	Editor.UpdateLineNumbers = function()
		local text = editor.Text
		local lines = {}
		local count = 0
		for _ in text:gmatch("[^\n]*") do
			count = count + 1
			table.insert(lines, tostring(count))
		end
		lineNumbers.Text = table.concat(lines, "\n")
	end
	
	Editor.UpdateHighlight = function()
		local text = editor.Text
		if text == "" then
			codeDisplay.Text = ""
		else
			codeDisplay.Text = highlightCode(text)
		end
	end
	
	Editor.ShowIntellisense = function(completions)
		Editor.currentCompletions = completions
		Editor.selectedIndex = 1
		
		-- Clear existing
		for _, child in ipairs(intellisenseList:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		
		if #completions == 0 then
			intellisense.Visible = false
			Editor.intellisenseVisible = false
			return
		end
		
		-- Create items
		for i, completion in ipairs(completions) do
			local item = Instance.new("TextButton")
			item.Size = UDim2.new(1, 0, 0, 24)
			item.BackgroundColor3 = i == 1 and Theme.Colors.Selection or Theme.Colors.BackgroundLight
			item.Text = "  " .. completion.name .. (completion.detail and ("  [" .. completion.detail .. "]") or "")
			item.TextColor3 = Theme.Colors.Foreground
			item.Font = Theme.Fonts.Mono
			item.TextSize = 13
			item.TextXAlignment = Enum.TextXAlignment.Left
			item.ZIndex = 102
			item.Parent = intellisenseList
			
			item.MouseButton1Click:Connect(function()
				Editor.ApplyCompletion(i)
			end)
		end
		
		local height = math.min(#completions * 24, 200)
		intellisense.Size = UDim2.new(0, 280, 0, height)
		intellisense.Position = UDim2.new(0, 100, 0, 100)
		intellisenseList.CanvasSize = UDim2.new(0, 0, 0, #completions * 24)
		intellisense.Visible = true
		Editor.intellisenseVisible = true
	end
	
	Editor.HideIntellisense = function()
		intellisense.Visible = false
		Editor.intellisenseVisible = false
	end
	
	Editor.HighlightSelectedItem = function()
		local items = {}
		for _, child in ipairs(intellisenseList:GetChildren()) do
			if child:IsA("TextButton") then
				table.insert(items, child)
			end
		end
		for i, item in ipairs(items) do
			item.BackgroundColor3 = (i == Editor.selectedIndex) and Theme.Colors.Selection or Theme.Colors.BackgroundLight
		end
	end
	
	Editor.ApplyCompletion = function(index)
		local completion = Editor.currentCompletions[index]
		if not completion then return end
		
		local text = editor.Text
		local cursorPos = editor.CursorPosition
		
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
		
		editor.Text = before .. insertText .. after
		editor.CursorPosition = #before + #insertText + 1
		
		Editor.HideIntellisense()
		Editor.UpdateHighlight()
		Editor.UpdateLineNumbers()
	end
	
	Editor.TriggerIntellisense = function()
		local cursorPos = editor.CursorPosition
		local text = editor.Text
		if cursorPos <= 0 then cursorPos = 1 end
		
		local completions, context, wordStart = getCompletions(text, cursorPos)
		
		if #completions > 0 then
			Editor.ShowIntellisense(completions)
		else
			Editor.HideIntellisense()
		end
	end
	
	-- Event handlers
	editor:GetPropertyChangedSignal("Text"):Connect(function()
		Editor.UpdateHighlight()
		Editor.UpdateLineNumbers()
		task.delay(0.05, function()
			if editor.Text ~= "" then
				Editor.TriggerIntellisense()
			end
		end)
	end)
	
	editor:GetPropertyChangedSignal("CursorPosition"):Connect(function()
		if Editor.intellisenseVisible then
			Editor.TriggerIntellisense()
		end
	end)
	
	runBtn.MouseButton1Click:Connect(function()
		Editor.RunCode()
	end)
	
	clearBtn.MouseButton1Click:Connect(function()
		outputText.Text = ""
	end)
	
	-- Initial update
	Editor.UpdateHighlight()
	Editor.UpdateLineNumbers()
	
	return frame
end

-- Show editor
function Editor.Show()
	if not Editor.Frame then
		Editor.CreateGUI()
	end
	Editor.Frame.Visible = true
	Editor.State.IsVisible = true
end

-- Hide editor
function Editor.Hide()
	if Editor.Frame then
		Editor.Frame.Visible = false
	end
	Editor.State.IsVisible = false
end

-- Toggle editor
function Editor.Toggle()
	if Editor.State.IsVisible then
		Editor.Hide()
	else
		Editor.Show()
	end
end

-- Run code
function Editor.RunCode()
	if not Editor.Editor then return end
	
	local code = Editor.Editor.Text
	Editor.Output.Text = "[Running...]"
	
	local success, result = pcall(function()
		local fn, err = loadstring(code)
		if not fn then
			Editor.Output.Text = "[✗] Syntax Error: " .. tostring(err):sub(1, 150)
			return
		end
		
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
			Editor.Output.Text = "[✗] Error: " .. tostring(execResult):sub(1, 150)
		elseif #outputs > 0 then
			Editor.Output.Text = table.concat(outputs, "\n"):sub(1, 300)
		else
			Editor.Output.Text = "[✓] Code executed successfully"
		end
	end)
	
	if not success then
		Editor.Output.Text = "[✗] Error: " .. tostring(result):sub(1, 150)
	end
end

-- ============================================
-- Initialize
-- ============================================

-- Create GUI
Editor.CreateGUI()

-- F8 to toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.F8 then
		Editor.Toggle()
	end
	
	if not Editor.State.IsVisible then return end
	
	if input.KeyCode == Enum.KeyCode.F5 then
		Editor.RunCode()
	end
	
	-- Intellisense navigation
	if Editor.intellisenseVisible then
		if input.KeyCode == Enum.KeyCode.Down then
			Editor.selectedIndex = math.min(Editor.selectedIndex + 1, #Editor.currentCompletions)
			Editor.HighlightSelectedItem()
		elseif input.KeyCode == Enum.KeyCode.Up then
			Editor.selectedIndex = math.max(Editor.selectedIndex - 1, 1)
			Editor.HighlightSelectedItem()
		elseif input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.Return then
			Editor.ApplyCompletion(Editor.selectedIndex)
		elseif input.KeyCode == Enum.KeyCode.Escape then
			Editor.HideIntellisense()
		end
	end
end)

_G.DraculaEditor.Main = Editor

print("🦇 Dracula Code Editor loaded!")
print("   Press F8 to toggle the editor")

return Editor
