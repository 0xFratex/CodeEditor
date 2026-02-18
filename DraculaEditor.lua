--[[
	Dracula Code Editor - Main Module
]]

local DraculaEditor = {}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Get modules from global storage
local function getModule(name)
	local editor = _G.DraculaEditor
	if editor then
		return editor[name]
	end
	return nil
end

local function getTheme()
	return getModule("Theme")
end

local function getFileSystem()
	return getModule("FileSystem")
end

local function getIntellisense()
	return getModule("Intellisense")
end

local function getEditorGUI()
	return getModule("EditorGUI")
end

local function getCodeRunner()
	return getModule("CodeRunner")
end

-- Configuration
DraculaEditor.Config = {
	Name = "Dracula Code Editor",
	Version = "1.0.0",
	AutoSave = true,
	AutoSaveInterval = 30,
	ShowWelcomeMessage = true,
}

-- Editor state
DraculaEditor.State = {
	IsInitialized = false,
	IsVisible = false,
	OpenFiles = {},
	ActiveFile = nil,
	IntellisenseVisible = false,
	IntellisenseIndex = 0,
	IntellisenseItems = {},
}

-- UI References
DraculaEditor.UI = {}

-- Initialize the editor
function DraculaEditor.Initialize(parent)
	if DraculaEditor.State.IsInitialized then
		return DraculaEditor
	end
	
	local Theme = getTheme()
	local EditorGUI = getEditorGUI()
	
	if not Theme or not EditorGUI then
		error("Required modules not loaded!")
		return nil
	end
	
	parent = parent or Players.LocalPlayer:WaitForChild("PlayerGui")
	
	-- Create main frame
	DraculaEditor.UI.MainFrame = EditorGUI.CreateMainFrame(parent)
	
	-- Create sidebar
	DraculaEditor.UI.Sidebar = EditorGUI.CreateSidebar(DraculaEditor.UI.MainFrame)
	
	-- Create editor area
	DraculaEditor.UI.EditorArea = EditorGUI.CreateEditorArea(DraculaEditor.UI.MainFrame)
	
	-- Create output panel
	DraculaEditor.UI.OutputPanel = EditorGUI.CreateOutputPanel(DraculaEditor.UI.MainFrame)
	
	-- Get references to key components
	DraculaEditor.UI.CodeEditor = DraculaEditor.UI.EditorArea:FindFirstChild("CodeContainer", true)
	if DraculaEditor.UI.CodeEditor then
		DraculaEditor.UI.CodeEditor = DraculaEditor.UI.CodeEditor:FindFirstChild("CodeEditor", true)
	end
	
	DraculaEditor.UI.LineNumbers = DraculaEditor.UI.EditorArea:FindFirstChild("CodeContainer", true)
	if DraculaEditor.UI.LineNumbers then
		DraculaEditor.UI.LineNumbers = DraculaEditor.UI.LineNumbers:FindFirstChild("LineNumbers", true)
		if DraculaEditor.UI.LineNumbers then
			DraculaEditor.UI.LineNumbers = DraculaEditor.UI.LineNumbers:FindFirstChild("Numbers", true)
		end
	end
	
	DraculaEditor.UI.Intellisense = DraculaEditor.UI.EditorArea:FindFirstChild("CodeContainer", true)
	if DraculaEditor.UI.Intellisense then
		DraculaEditor.UI.Intellisense = DraculaEditor.UI.Intellisense:FindFirstChild("Intellisense", true)
	end
	
	-- Setup event handlers
	DraculaEditor.SetupEventHandlers()
	
	-- Load existing files
	local FileSystem = getFileSystem()
	if FileSystem then
		local files = FileSystem.ListFiles()
		if #files == 0 then
			DraculaEditor.CreateNewFile("main.lua", "-- Welcome to Dracula Code Editor!\n-- Start coding here...\n\nprint('Hello, Dracula!')\n")
		end
		DraculaEditor.RefreshFileList()
	end
	
	DraculaEditor.State.IsInitialized = true
	
	if DraculaEditor.Config.ShowWelcomeMessage then
		DraculaEditor.LogOutput("🦇 Dracula Code Editor v" .. DraculaEditor.Config.Version, "Info")
		DraculaEditor.LogOutput("Press F5 to run code, Ctrl+S to save", "Info")
	end
	
	return DraculaEditor
end

-- Setup event handlers
function DraculaEditor.SetupEventHandlers()
	local codeEditor = DraculaEditor.UI.CodeEditor
	if not codeEditor then return end
	
	-- Keyboard shortcuts
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.F8 then
			DraculaEditor.Toggle()
		end
		
		if not DraculaEditor.State.IsVisible then return end
		
		if input.KeyCode == Enum.KeyCode.F5 then
			DraculaEditor.RunCode()
		end
		
		if input.KeyCode == Enum.KeyCode.S and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			DraculaEditor.SaveCurrentFile()
		end
		
		if input.KeyCode == Enum.KeyCode.N and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			DraculaEditor.CreateNewFile()
		end
		
		if input.KeyCode == Enum.KeyCode.Escape then
			DraculaEditor.HideIntellisense()
		end
		
		-- Intellisense navigation
		if DraculaEditor.State.IntellisenseVisible then
			if input.KeyCode == Enum.KeyCode.Down then
				DraculaEditor.State.IntellisenseIndex = math.min(
					DraculaEditor.State.IntellisenseIndex + 1, 
					#DraculaEditor.State.IntellisenseItems
				)
				DraculaEditor.HighlightIntellisenseItem(DraculaEditor.State.IntellisenseIndex)
			elseif input.KeyCode == Enum.KeyCode.Up then
				DraculaEditor.State.IntellisenseIndex = math.max(DraculaEditor.State.IntellisenseIndex - 1, 1)
				DraculaEditor.HighlightIntellisenseItem(DraculaEditor.State.IntellisenseIndex)
			elseif input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.Return then
				DraculaEditor.ApplyIntellisenseCompletion(DraculaEditor.State.IntellisenseIndex)
			end
		end
	end)
	
	-- Code editor events
	codeEditor:GetPropertyChangedSignal("Text"):Connect(function()
		DraculaEditor.OnTextChanged()
	end)
	
	-- Sidebar buttons
	local sidebar = DraculaEditor.UI.Sidebar
	if sidebar then
		local newFileBtn = sidebar:FindFirstChild("Header", true)
		if newFileBtn then
			newFileBtn = newFileBtn:FindFirstChild("NewFileButton", true)
			if newFileBtn then
				newFileBtn.MouseButton1Click:Connect(function()
					DraculaEditor.CreateNewFile()
				end)
			end
		end
	end
	
	-- Output panel buttons
	local outputPanel = DraculaEditor.UI.OutputPanel
	if outputPanel then
		local header = outputPanel:FindFirstChild("Header", true)
		if header then
			local runBtn = header:FindFirstChild("RunButton", true)
			if runBtn then
				runBtn.MouseButton1Click:Connect(function()
					DraculaEditor.RunCode()
				end)
			end
			
			local clearBtn = header:FindFirstChild("ClearButton", true)
			if clearBtn then
				clearBtn.MouseButton1Click:Connect(function()
					DraculaEditor.ClearOutput()
				end)
			end
		end
	end
end

-- Show/Hide/Toggle
function DraculaEditor.Show()
	if not DraculaEditor.State.IsInitialized then
		DraculaEditor.Initialize()
	end
	
	DraculaEditor.UI.MainFrame.Visible = true
	DraculaEditor.State.IsVisible = true
	
	-- Animate in
	local EditorGUI = getEditorGUI()
	if EditorGUI then
		DraculaEditor.UI.MainFrame.Size = UDim2.new(0, 0, 0, 0)
		local tween = TweenService:Create(
			DraculaEditor.UI.MainFrame,
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = EditorGUI.Config.DefaultSize }
		)
		tween:Play()
	end
end

function DraculaEditor.Hide()
	DraculaEditor.UI.MainFrame.Visible = false
	DraculaEditor.State.IsVisible = false
end

function DraculaEditor.Toggle()
	if DraculaEditor.State.IsVisible then
		DraculaEditor.Hide()
	else
		DraculaEditor.Show()
	end
end

-- File operations
function DraculaEditor.CreateNewFile(name, content)
	name = name or "untitled_" .. os.time() .. ".lua"
	content = content or ""
	
	local FileSystem = getFileSystem()
	if FileSystem then
		local file = FileSystem.File.new(name, content)
		table.insert(DraculaEditor.State.OpenFiles, file)
		DraculaEditor.OpenFile(name)
		DraculaEditor.RefreshFileList()
		return file
	else
		-- Fallback without FileSystem
		local file = { Name = name, Content = content, IsModified = false }
		file.UpdateContent = function(self, c) self.Content = c; self.IsModified = true end
		table.insert(DraculaEditor.State.OpenFiles, file)
		DraculaEditor.State.ActiveFile = file
		if DraculaEditor.UI.CodeEditor then
			DraculaEditor.UI.CodeEditor.Text = content
		end
		return file
	end
end

function DraculaEditor.OpenFile(fileName)
	local file = nil
	
	for _, f in ipairs(DraculaEditor.State.OpenFiles) do
		if f.Name == fileName then
			file = f
			break
		end
	end
	
	if not file then
		local FileSystem = getFileSystem()
		if FileSystem then
			file = FileSystem.GetFile(fileName)
			if file then
				table.insert(DraculaEditor.State.OpenFiles, file)
			end
		end
	end
	
	if not file then
		DraculaEditor.LogOutput("File not found: " .. fileName, "Error")
		return
	end
	
	DraculaEditor.State.ActiveFile = file
	
	if DraculaEditor.UI.CodeEditor then
		DraculaEditor.UI.CodeEditor.Text = file.Content or ""
	end
	
	DraculaEditor.UpdateLineNumbers()
	DraculaEditor.UpdateTabs()
end

function DraculaEditor.CloseFile(fileName)
	for i, file in ipairs(DraculaEditor.State.OpenFiles) do
		if file.Name == fileName then
			table.remove(DraculaEditor.State.OpenFiles, i)
			
			if DraculaEditor.State.ActiveFile and DraculaEditor.State.ActiveFile.Name == fileName then
				if #DraculaEditor.State.OpenFiles > 0 then
					DraculaEditor.OpenFile(DraculaEditor.State.OpenFiles[1].Name)
				else
					DraculaEditor.State.ActiveFile = nil
					if DraculaEditor.UI.CodeEditor then
						DraculaEditor.UI.CodeEditor.Text = ""
					end
				end
			end
			
			DraculaEditor.UpdateTabs()
			DraculaEditor.RefreshFileList()
			break
		end
	end
end

function DraculaEditor.SaveCurrentFile()
	if DraculaEditor.State.ActiveFile then
		DraculaEditor.SaveFile(DraculaEditor.State.ActiveFile)
	end
end

function DraculaEditor.SaveFile(file)
	if DraculaEditor.UI.CodeEditor then
		if file.UpdateContent then
			file:UpdateContent(DraculaEditor.UI.CodeEditor.Text)
		else
			file.Content = DraculaEditor.UI.CodeEditor.Text
			file.IsModified = true
		end
	end
	
	local FileSystem = getFileSystem()
	if FileSystem then
		FileSystem.SaveFile(file)
	end
	
	DraculaEditor.LogOutput("Saved: " .. file.Name, "Success")
	DraculaEditor.UpdateTabs()
end

-- Run code
function DraculaEditor.RunCode()
	if not DraculaEditor.State.ActiveFile then
		DraculaEditor.LogOutput("No file to run", "Error")
		return
	end
	
	local code = DraculaEditor.UI.CodeEditor and DraculaEditor.UI.CodeEditor.Text or ""
	
	DraculaEditor.LogOutput("────────────────────────────────────────", "Info")
	DraculaEditor.LogOutput("Running: " .. DraculaEditor.State.ActiveFile.Name, "Info")
	
	local CodeRunner = getCodeRunner()
	if CodeRunner then
		local result = CodeRunner.Execute(code)
		
		for _, output in ipairs(result.Output) do
			DraculaEditor.LogOutput(output.Message, output.Type)
		end
		
		if result.Success then
			DraculaEditor.LogOutput(string.format("✓ Completed in %.3fms", result.Duration * 1000), "Success")
		else
			DraculaEditor.LogOutput("✗ Execution failed", "Error")
		end
	else
		-- Fallback execution
		local fn, err = loadstring(code)
		if fn then
			local success, result = pcall(fn)
			if success then
				DraculaEditor.LogOutput("✓ Code executed", "Success")
			else
				DraculaEditor.LogOutput("✗ Error: " .. tostring(result), "Error")
			end
		else
			DraculaEditor.LogOutput("✗ Syntax Error: " .. tostring(err), "Error")
		end
	end
end

-- Text changed handler
function DraculaEditor.OnTextChanged()
	if not DraculaEditor.UI.CodeEditor then return end
	
	local text = DraculaEditor.UI.CodeEditor.Text
	
	if DraculaEditor.State.ActiveFile then
		if DraculaEditor.State.ActiveFile.UpdateContent then
			DraculaEditor.State.ActiveFile:UpdateContent(text)
		else
			DraculaEditor.State.ActiveFile.Content = text
		end
		DraculaEditor.UpdateTabs()
	end
	
	DraculaEditor.UpdateLineNumbers()
	DraculaEditor.TriggerIntellisense()
end

-- Update line numbers
function DraculaEditor.UpdateLineNumbers()
	if not DraculaEditor.UI.CodeEditor or not DraculaEditor.UI.LineNumbers then return end
	
	local text = DraculaEditor.UI.CodeEditor.Text
	local lines = {}
	local count = 0
	
	for _ in string.gmatch(text .. "\n", "\n") do
		count = count + 1
		table.insert(lines, tostring(count))
	end
	
	DraculaEditor.UI.LineNumbers.Text = table.concat(lines, "\n")
end

-- Update tabs
function DraculaEditor.UpdateTabs()
	local tabList = DraculaEditor.UI.EditorArea
	if tabList then
		tabList = tabList:FindFirstChild("TabBar", true)
		if tabList then
			tabList = tabList:FindFirstChild("TabList", true)
		end
	end
	
	if not tabList then return end
	
	-- Clear existing tabs
	for _, child in ipairs(tabList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	local Theme = getTheme()
	local EditorGUI = getEditorGUI()
	
	if not EditorGUI or not Theme then return end
	
	-- Create tabs
	for _, file in ipairs(DraculaEditor.State.OpenFiles) do
		local tab = EditorGUI.CreateTab(tabList, file)
		
		if DraculaEditor.State.ActiveFile and DraculaEditor.State.ActiveFile.Name == file.Name then
			tab.BackgroundColor3 = Theme.Colors.Background
		else
			tab.BackgroundColor3 = Theme.Colors.BackgroundDark
		end
		
		tab.MouseButton1Click:Connect(function()
			DraculaEditor.OpenFile(file.Name)
		end)
		
		local closeBtn = tab:FindFirstChild("Close")
		if closeBtn then
			closeBtn.MouseButton1Click:Connect(function()
				DraculaEditor.CloseFile(file.Name)
			end)
		end
	end
end

-- Refresh file list
function DraculaEditor.RefreshFileList()
	local fileList = DraculaEditor.UI.Sidebar
	if fileList then
		fileList = fileList:FindFirstChild("FileList", true)
	end
	if not fileList then return end
	
	-- Clear existing
	for _, child in ipairs(fileList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	local FileSystem = getFileSystem()
	local EditorGUI = getEditorGUI()
	
	if not FileSystem or not EditorGUI then return end
	
	local files = FileSystem.ListFiles()
	for i, file in ipairs(files) do
		local item = EditorGUI.CreateFileItem(fileList, file, i)
		item.MouseButton1Click:Connect(function()
			DraculaEditor.OpenFile(file.Name)
		end)
	end
	
	local layout = fileList:FindFirstChild("ListLayout")
	if layout then
		fileList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
	end
end

-- Intellisense
function DraculaEditor.TriggerIntellisense()
	if not DraculaEditor.UI.CodeEditor then return end
	
	local cursorPos = DraculaEditor.UI.CodeEditor.CursorPosition
	local text = DraculaEditor.UI.CodeEditor.Text
	
	local Intellisense = getIntellisense()
	if not Intellisense then return end
	
	local variables = Intellisense.ExtractVariables(text, cursorPos)
	local completions, context = Intellisense.GetCompletions(text, cursorPos, variables)
	
	if #completions > 0 then
		DraculaEditor.ShowIntellisense(completions, context)
	else
		DraculaEditor.HideIntellisense()
	end
end

function DraculaEditor.ShowIntellisense(completions, context)
	if not DraculaEditor.UI.Intellisense then return end
	
	local intellisense = DraculaEditor.UI.Intellisense
	local list = intellisense:FindFirstChild("List")
	if not list then return end
	
	-- Clear existing
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	DraculaEditor.State.IntellisenseItems = completions
	DraculaEditor.State.IntellisenseIndex = 1
	
	local EditorGUI = getEditorGUI()
	if not EditorGUI then return end
	
	for i, completion in ipairs(completions) do
		local item = EditorGUI.CreateIntellisenseItem(list, completion, i == 1)
		item.MouseButton1Click:Connect(function()
			DraculaEditor.ApplyIntellisenseCompletion(i)
		end)
	end
	
	intellisense.Position = UDim2.new(0, 100, 0, 200)
	intellisense.Visible = true
	DraculaEditor.State.IntellisenseVisible = true
end

function DraculaEditor.HideIntellisense()
	if DraculaEditor.UI.Intellisense then
		DraculaEditor.UI.Intellisense.Visible = false
	end
	DraculaEditor.State.IntellisenseVisible = false
end

function DraculaEditor.HighlightIntellisenseItem(index)
	local list = DraculaEditor.UI.Intellisense
	if list then list = list:FindFirstChild("List") end
	if not list then return end
	
	local Theme = getTheme()
	if not Theme then return end
	
	local items = {}
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(items, child)
		end
	end
	
	for i, item in ipairs(items) do
		item.BackgroundColor3 = (i == index) and Theme.Colors.Selection or Theme.Colors.BackgroundLight
	end
	
	DraculaEditor.State.IntellisenseIndex = index
end

function DraculaEditor.ApplyIntellisenseCompletion(index)
	local completion = DraculaEditor.State.IntellisenseItems[index]
	if not completion then return end
	
	local codeEditor = DraculaEditor.UI.CodeEditor
	if not codeEditor then return end
	
	local text = codeEditor.Text
	local cursorPos = codeEditor.CursorPosition
	
	-- Find word start
	local wordStart = cursorPos
	while wordStart > 1 and string.sub(text, wordStart - 1, wordStart - 1):match("[%w_]") do
		wordStart = wordStart - 1
	end
	
	local before = string.sub(text, 1, wordStart - 1)
	local after = string.sub(text, cursorPos + 1)
	
	local insertText = completion.InsertText or completion.Name
	
	-- Handle GetChildren results
	if completion.Detail and string.find(completion.Detail, "GetChildren") then
		local expr = string.match(completion.Detail, "insert: (.+)")
		if expr then
			insertText = expr
		end
	end
	
	codeEditor.Text = before .. insertText .. after
	codeEditor.CursorPosition = #before + #insertText + 1
	
	DraculaEditor.HideIntellisense()
end

-- Output
function DraculaEditor.LogOutput(message, messageType)
	local outputText = DraculaEditor.UI.OutputPanel
	if outputText then
		outputText = outputText:FindFirstChild("OutputText", true)
	end
	if not outputText then return end
	
	local textLabel = outputText:FindFirstChild("Text")
	if not textLabel then return end
	
	local Theme = getTheme()
	local prefix = ""
	
	if messageType == "Success" then prefix = "✓ "
	elseif messageType == "Error" then prefix = "✗ "
	elseif messageType == "Warning" then prefix = "⚠ "
	elseif messageType == "Info" then prefix = "ℹ "
	end
	
	local timestamp = os.date("%H:%M:%S")
	local newLine = string.format("[%s] %s%s", timestamp, prefix, message)
	
	if textLabel.Text == "" or textLabel.Text == "[Dracula] Ready to code..." then
		textLabel.Text = newLine
	else
		textLabel.Text = textLabel.Text .. "\n" .. newLine
	end
end

function DraculaEditor.ClearOutput()
	local outputText = DraculaEditor.UI.OutputPanel
	if outputText then
		outputText = outputText:FindFirstChild("OutputText", true)
	end
	if outputText then
		local textLabel = outputText:FindFirstChild("Text")
		if textLabel then
			textLabel.Text = ""
		end
	end
end

return DraculaEditor
