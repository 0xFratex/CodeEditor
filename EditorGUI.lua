--[[
	Dracula Editor GUI
	Main graphical user interface for the code editor
]]

local EditorGUI = {}

-- Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

-- Theme
local Theme = require(script.Parent:WaitForChild("DraculaTheme"))

-- Configuration
EditorGUI.Config = {
	WindowName = "Dracula Code Editor",
	Version = "1.0.0",
	DefaultSize = UDim2.new(0, 900, 0, 600),
	MinSize = Vector2.new(600, 400),
	LineHeight = 20,
	CharWidth = 8,
	TabWidth = 4,
	ShowLineNumbers = true,
	WordWrap = false,
	AutoIndent = true,
	AutoCloseBrackets = true,
}

-- Current editor state
EditorGUI.State = {
	OpenFiles = {},
	ActiveFile = nil,
	IsVisible = false,
	CursorPosition = 0,
	SelectionStart = 0,
	UndoStack = {},
	RedoStack = {},
	FindVisible = false,
	FindQuery = "",
	ReplaceQuery = "",
}

-- Create main editor frame
function EditorGUI.CreateMainFrame(parent)
	local frame = Instance.new("Frame")
	frame.Name = "DraculaEditor"
	frame.Size = EditorGUI.Config.DefaultSize
	frame.Position = UDim2.new(0.5, -450, 0.5, -300)
	frame.BackgroundColor3 = Theme.Colors.Background
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = parent
	
	-- Add dragging capability
	local dragHandle = Instance.new("Frame")
	dragHandle.Name = "DragHandle"
	dragHandle.Size = UDim2.new(1, 0, 0, Theme.UI.HeaderHeight)
	dragHandle.BackgroundColor3 = Theme.Colors.BackgroundDark
	dragHandle.BorderSizePixel = 0
	dragHandle.Parent = frame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -100, 1, 0)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🦇 " .. EditorGUI.Config.WindowName .. " v" .. EditorGUI.Config.Version
	title.TextColor3 = Theme.Colors.Foreground
	title.Font = Theme.Fonts.Title
	title.TextSize = Theme.FontSizes.Large
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = dragHandle
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -35, 0, 5)
	closeButton.BackgroundColor3 = Theme.Colors.Error
	closeButton.Text = "×"
	closeButton.TextColor3 = Theme.Colors.White
	closeButton.Font = Theme.Fonts.UI
	closeButton.TextSize = 20
	closeButton.Parent = dragHandle
	Theme.CreateCorner(closeButton, 4)
	
	closeButton.MouseButton1Click:Connect(function()
		EditorGUI.Hide()
	end)
	
	-- Dragging functionality
	local dragging = false
	local dragStart, startPos
	
	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)
	
	dragHandle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
	
	-- Resize handle
	local resizeHandle = Instance.new("TextButton")
	resizeHandle.Name = "ResizeHandle"
	resizeHandle.Size = UDim2.new(0, 20, 0, 20)
	resizeHandle.Position = UDim2.new(1, -20, 1, -20)
	resizeHandle.BackgroundTransparency = 1
	resizeHandle.Text = "⇲"
	resizeHandle.TextColor3 = Theme.Colors.Comment
	resizeHandle.TextSize = 14
	resizeHandle.Parent = frame
	
	local resizing = false
	local resizeStart, startSize
	
	resizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true
			resizeStart = input.Position
			startSize = frame.AbsoluteSize
		end
	end)
	
	resizeHandle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if resizing and input.UserInputType == Enum.UserInputType.MouseButton1 then
			local delta = input.Position - resizeStart
			local newSize = Vector2.new(
				math.max(EditorGUI.Config.MinSize.X, startSize.X + delta.X),
				math.max(EditorGUI.Config.MinSize.Y, startSize.Y + delta.Y)
			)
			frame.Size = UDim2.new(0, newSize.X, 0, newSize.Y)
		end
	end)
	
	return frame
end

-- Create sidebar (file explorer)
function EditorGUI.CreateSidebar(parent)
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, Theme.UI.SidebarWidth, 1, -Theme.UI.HeaderHeight)
	sidebar.Position = UDim2.new(0, 0, 0, Theme.UI.HeaderHeight)
	sidebar.BackgroundColor3 = Theme.Colors.BackgroundDark
	sidebar.BorderSizePixel = 0
	sidebar.Parent = parent
	
	-- Sidebar header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 36)
	header.BackgroundColor3 = Theme.Colors.BackgroundLight
	header.BorderSizePixel = 0
	header.Parent = sidebar
	
	local headerTitle = Instance.new("TextLabel")
	headerTitle.Name = "Title"
	headerTitle.Size = UDim2.new(1, -80, 1, 0)
	headerTitle.Position = UDim2.new(0, 10, 0, 0)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Text = "📁 EXPLORER"
	headerTitle.TextColor3 = Theme.Colors.Comment
	headerTitle.Font = Theme.Fonts.UI
	headerTitle.TextSize = Theme.FontSizes.Small
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.Parent = header
	
	-- New file button
	local newFileBtn = Instance.new("TextButton")
	newFileBtn.Name = "NewFileButton"
	newFileBtn.Size = UDim2.new(0, 30, 0, 26)
	newFileBtn.Position = UDim2.new(1, -70, 0, 5)
	newFileBtn.BackgroundColor3 = Theme.Colors.Button
	newFileBtn.Text = "+"
	newFileBtn.TextColor3 = Theme.Colors.Foreground
	newFileBtn.Font = Theme.Fonts.UI
	newFileBtn.TextSize = 16
	newFileBtn.Parent = header
	Theme.CreateCorner(newFileBtn, 4)
	
	-- New folder button
	local newFolderBtn = Instance.new("TextButton")
	newFolderBtn.Name = "NewFolderButton"
	newFolderBtn.Size = UDim2.new(0, 30, 0, 26)
	newFolderBtn.Position = UDim2.new(1, -35, 0, 5)
	newFolderBtn.BackgroundColor3 = Theme.Colors.Button
	newFolderBtn.Text = "📁"
	newFolderBtn.TextColor3 = Theme.Colors.Foreground
	newFolderBtn.Font = Theme.Fonts.UI
	newFolderBtn.TextSize = 14
	newFolderBtn.Parent = header
	Theme.CreateCorner(newFolderBtn, 4)
	
	-- File list
	local fileList = Instance.new("ScrollingFrame")
	fileList.Name = "FileList"
	fileList.Size = UDim2.new(1, 0, 1, -40)
	fileList.Position = UDim2.new(0, 0, 0, 38)
	fileList.BackgroundColor3 = Theme.Colors.BackgroundDark
	fileList.BorderSizePixel = 0
	fileList.ScrollBarThickness = 8
	fileList.ScrollBarImageColor3 = Theme.Colors.Scrollbar
	fileList.CanvasSize = UDim2.new(0, 0, 0, 0)
	fileList.Parent = sidebar
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Name = "ListLayout"
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = fileList
	
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		fileList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
	end)
	
	return sidebar
end

-- Create editor area
function EditorGUI.CreateEditorArea(parent)
	local editorArea = Instance.new("Frame")
	editorArea.Name = "EditorArea"
	editorArea.Size = UDim2.new(1, -Theme.UI.SidebarWidth, 1, -Theme.UI.HeaderHeight - 150)
	editorArea.Position = UDim2.new(0, Theme.UI.SidebarWidth, 0, Theme.UI.HeaderHeight)
	editorArea.BackgroundColor3 = Theme.Colors.Background
	editorArea.BorderSizePixel = 0
	editorArea.Parent = parent
	
	-- Tab bar
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, 0, 0, Theme.UI.TabHeight)
	tabBar.BackgroundColor3 = Theme.Colors.BackgroundDark
	tabBar.BorderSizePixel = 0
	tabBar.Parent = editorArea
	
	local tabList = Instance.new("ScrollingFrame")
	tabList.Name = "TabList"
	tabList.Size = UDim2.new(1, -60, 1, 0)
	tabList.BackgroundColor3 = Theme.Colors.BackgroundDark
	tabList.BorderSizePixel = 0
	tabList.ScrollBarThickness = 0
	tabList.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabList.Parent = tabBar
	
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.Name = "TabLayout"
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabList
	
	-- Code container
	local codeContainer = Instance.new("Frame")
	codeContainer.Name = "CodeContainer"
	codeContainer.Size = UDim2.new(1, 0, 1, -Theme.UI.TabHeight)
	codeContainer.Position = UDim2.new(0, 0, 0, Theme.UI.TabHeight)
	codeContainer.BackgroundColor3 = Theme.Colors.Background
	codeContainer.BorderSizePixel = 0
	codeContainer.Parent = editorArea
	
	-- Line numbers
	local lineNumbers = Instance.new("Frame")
	lineNumbers.Name = "LineNumbers"
	lineNumbers.Size = UDim2.new(0, 50, 1, 0)
	lineNumbers.BackgroundColor3 = Theme.Colors.BackgroundDark
	lineNumbers.BorderSizePixel = 0
	lineNumbers.Parent = codeContainer
	
	local lineNumberLabel = Instance.new("TextLabel")
	lineNumberLabel.Name = "Numbers"
	lineNumberLabel.Size = UDim2.new(1, -5, 1, 0)
	lineNumberLabel.Position = UDim2.new(0, 5, 0, 0)
	lineNumberLabel.BackgroundTransparency = 1
	lineNumberLabel.Text = "1"
	lineNumberLabel.TextColor3 = Theme.Colors.Comment
	lineNumberLabel.Font = Theme.Fonts.Mono
	lineNumberLabel.TextSize = Theme.FontSizes.Code
	lineNumberLabel.TextXAlignment = Enum.TextXAlignment.Right
	lineNumberLabel.TextYAlignment = Enum.TextYAlignment.Top
	lineNumberLabel.Parent = lineNumbers
	
	-- Code editor (TextBox)
	local codeEditor = Instance.new("TextBox")
	codeEditor.Name = "CodeEditor"
	codeEditor.Size = UDim2.new(1, -55, 1, 0)
	codeEditor.Position = UDim2.new(0, 55, 0, 0)
	codeEditor.BackgroundColor3 = Theme.Colors.Background
	codeEditor.BackgroundTransparency = 1
	codeEditor.TextColor3 = Theme.Colors.Foreground
	codeEditor.Font = Theme.Fonts.Mono
	codeEditor.TextSize = Theme.FontSizes.Code
	codeEditor.TextXAlignment = Enum.TextXAlignment.Left
	codeEditor.TextYAlignment = Enum.TextYAlignment.Top
	codeEditor.MultiLine = true
	codeEditor.ClearTextOnFocus = false
	codeEditor.Text = ""
	codeEditor.PlaceholderText = "-- Start coding in Dracula..."
	codeEditor.PlaceholderColor3 = Theme.Colors.Comment
	codeEditor.Parent = codeContainer
	
	-- Syntax highlighting overlay (RichText display)
	local syntaxHighlight = Instance.new("TextLabel")
	syntaxHighlight.Name = "SyntaxHighlight"
	syntaxHighlight.Size = UDim2.new(1, -10, 1, 0)
	syntaxHighlight.Position = UDim2.new(0, 55, 0, 0)
	syntaxHighlight.BackgroundTransparency = 1
	syntaxHighlight.TextColor3 = Theme.Colors.Foreground
	syntaxHighlight.Font = Theme.Fonts.Mono
	syntaxHighlight.TextSize = Theme.FontSizes.Code
	syntaxHighlight.TextXAlignment = Enum.TextXAlignment.Left
	syntaxHighlight.TextYAlignment = Enum.TextYAlignment.Top
	syntaxHighlight.RichText = true
	syntaxHighlight.Text = ""
	syntaxHighlight.Visible = false
	syntaxHighlight.Parent = codeContainer
	
	-- Intellisense dropdown
	local intellisense = Instance.new("Frame")
	intellisense.Name = "Intellisense"
	intellisense.Size = UDim2.new(0, Theme.UI.IntellisenseWidth, 0, 0)
	intellisense.BackgroundColor3 = Theme.Colors.BackgroundLight
	intellisense.BorderSizePixel = 0
	intellisense.Visible = false
	intellisense.ZIndex = 100
	intellisense.Parent = codeContainer
	Theme.CreateStroke(intellisense, Theme.Colors.Border)
	Theme.CreateCorner(intellisense, 4)
	
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
	intellisenseLayout.Name = "Layout"
	intellisenseLayout.Parent = intellisenseList
	
	intellisenseLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local height = math.min(intellisenseLayout.AbsoluteContentSize.Y, Theme.UI.IntellisenseMaxHeight)
		intellisense.Size = UDim2.new(0, Theme.UI.IntellisenseWidth, 0, height)
		intellisenseList.CanvasSize = UDim2.new(0, 0, 0, intellisenseLayout.AbsoluteContentSize.Y)
	end)
	
	-- Intellisense detail panel
	local intellisenseDetail = Instance.new("TextLabel")
	intellisenseDetail.Name = "Detail"
	intellisenseDetail.Size = UDim2.new(1, -16, 0, 40)
	intellisenseDetail.Position = UDim2.new(0, 8, 1, -48)
	intellisenseDetail.BackgroundColor3 = Theme.Colors.BackgroundDark
	intellisenseDetail.BackgroundTransparency = 0.5
	intellisenseDetail.TextColor3 = Theme.Colors.Comment
	intellisenseDetail.Font = Theme.Fonts.UI
	intellisenseDetail.TextSize = Theme.FontSizes.Small
	intellisenseDetail.TextWrapped = true
	intellisenseDetail.TextXAlignment = Enum.TextXAlignment.Left
	intellisenseDetail.TextYAlignment = Enum.TextYAlignment.Top
	intellisenseDetail.ZIndex = 102
	intellisenseDetail.Visible = false
	intellisenseDetail.Parent = intellisense
	
	return editorArea
end

-- Create output/console panel
function EditorGUI.CreateOutputPanel(parent)
	local output = Instance.new("Frame")
	output.Name = "OutputPanel"
	output.Size = UDim2.new(1, -Theme.UI.SidebarWidth, 0, 145)
	output.Position = UDim2.new(0, Theme.UI.SidebarWidth, 1, -145)
	output.BackgroundColor3 = Theme.Colors.BackgroundDark
	output.BorderSizePixel = 0
	output.Parent = parent
	
	-- Output header with tabs
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 28)
	header.BackgroundColor3 = Theme.Colors.BackgroundLight
	header.BorderSizePixel = 0
	header.Parent = output
	
	-- Output tab
	local outputTab = Instance.new("TextButton")
	outputTab.Name = "OutputTab"
	outputTab.Size = UDim2.new(0, 80, 1, 0)
	outputTab.BackgroundColor3 = Theme.Colors.Accent
	outputTab.Text = "📋 Output"
	outputTab.TextColor3 = Theme.Colors.White
	outputTab.Font = Theme.Fonts.UI
	outputTab.TextSize = Theme.FontSizes.Small
	outputTab.BorderSizePixel = 0
	outputTab.Parent = header
	
	-- Console tab
	local consoleTab = Instance.new("TextButton")
	consoleTab.Name = "ConsoleTab"
	consoleTab.Size = UDim2.new(0, 80, 1, 0)
	consoleTab.Position = UDim2.new(0, 80, 0, 0)
	consoleTab.BackgroundColor3 = Theme.Colors.BackgroundLight
	consoleTab.Text = "💻 Console"
	consoleTab.TextColor3 = Theme.Colors.Comment
	consoleTab.Font = Theme.Fonts.UI
	consoleTab.TextSize = Theme.FontSizes.Small
	consoleTab.BorderSizePixel = 0
	consoleTab.Parent = header
	
	-- Run button
	local runBtn = Instance.new("TextButton")
	runBtn.Name = "RunButton"
	runBtn.Size = UDim2.new(0, 80, 0, 22)
	runBtn.Position = UDim2.new(1, -90, 0, 3)
	runBtn.BackgroundColor3 = Theme.Colors.Success
	runBtn.Text = "▶ Run"
	runBtn.TextColor3 = Theme.Colors.Background
	runBtn.Font = Theme.Fonts.UI
	runBtn.TextSize = Theme.FontSizes.Small
	runBtn.Parent = header
	Theme.CreateCorner(runBtn, 4)
	
	-- Clear button
	local clearBtn = Instance.new("TextButton")
	clearBtn.Name = "ClearButton"
	clearBtn.Size = UDim2.new(0, 60, 0, 22)
	clearBtn.Position = UDim2.new(1, -160, 0, 3)
	clearBtn.BackgroundColor3 = Theme.Colors.Button
	clearBtn.Text = "Clear"
	clearBtn.TextColor3 = Theme.Colors.Foreground
	clearBtn.Font = Theme.Fonts.UI
	clearBtn.TextSize = Theme.FontSizes.Small
	clearBtn.Parent = header
	Theme.CreateCorner(clearBtn, 4)
	
	-- Output text
	local outputText = Instance.new("ScrollingFrame")
	outputText.Name = "OutputText"
	outputText.Size = UDim2.new(1, 0, 1, -28)
	outputText.Position = UDim2.new(0, 0, 0, 28)
	outputText.BackgroundColor3 = Theme.Colors.BackgroundDark
	outputText.BorderSizePixel = 0
	outputText.ScrollBarThickness = 6
	outputText.ScrollBarImageColor3 = Theme.Colors.Scrollbar
	outputText.Parent = output
	
	local outputLabel = Instance.new("TextLabel")
	outputLabel.Name = "Text"
	outputLabel.Size = UDim2.new(1, -16, 1, 0)
	outputLabel.Position = UDim2.new(0, 8, 0, 0)
	outputLabel.BackgroundTransparency = 1
	outputLabel.Text = "[Dracula] Ready to code..."
	outputLabel.TextColor3 = Theme.Colors.Comment
	outputLabel.Font = Theme.Fonts.Mono
	outputLabel.TextSize = Theme.FontSizes.Code
	outputLabel.TextXAlignment = Enum.TextXAlignment.Left
	outputLabel.TextYAlignment = Enum.TextYAlignment.Top
	outputLabel.RichText = true
	outputLabel.Parent = outputText
	
	-- Console input
	local consoleInput = Instance.new("TextBox")
	consoleInput.Name = "ConsoleInput"
	consoleInput.Size = UDim2.new(1, -16, 0, 24)
	consoleInput.Position = UDim2.new(0, 8, 1, -28)
	consoleInput.BackgroundColor3 = Theme.Colors.BackgroundLight
	consoleInput.Text = ""
	consoleInput.PlaceholderText = "> Enter Lua command..."
	consoleInput.PlaceholderColor3 = Theme.Colors.Comment
	consoleInput.TextColor3 = Theme.Colors.Foreground
	consoleInput.Font = Theme.Fonts.Mono
	consoleInput.TextSize = Theme.FontSizes.Code
	consoleInput.Visible = false
	consoleInput.Parent = outputText
	Theme.CreateCorner(consoleInput, 4)
	
	return output
end

-- Create intellisense item
function EditorGUI.CreateIntellisenseItem(parent, completionItem, isSelected)
	local item = Instance.new("Frame")
	item.Name = "Item"
	item.Size = UDim2.new(1, 0, 0, 24)
	item.BackgroundColor3 = isSelected and Theme.Colors.Selection or Theme.Colors.BackgroundLight
	item.BorderSizePixel = 0
	item.ZIndex = 103
	item.Parent = parent
	
	-- Kind icon
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 24, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = EditorGUI.GetKindIcon(completionItem.Kind)
	icon.TextColor3 = EditorGUI.GetKindColor(completionItem.Kind)
	icon.Font = Theme.Fonts.UI
	icon.TextSize = Theme.FontSizes.Small
	icon.Parent = item
	
	-- Name
	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.Size = UDim2.new(1, -100, 1, 0)
	name.Position = UDim2.new(0, 24, 0, 0)
	name.BackgroundTransparency = 1
	name.Text = completionItem.Name
	name.TextColor3 = isSelected and Theme.Colors.White or Theme.Colors.Foreground
	name.Font = Theme.Fonts.Mono
	name.TextSize = Theme.FontSizes.Code
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = item
	
	-- Kind label
	local kindLabel = Instance.new("TextLabel")
	kindLabel.Name = "Kind"
	kindLabel.Size = UDim2.new(0, 70, 1, 0)
	kindLabel.Position = UDim2.new(1, -75, 0, 0)
	kindLabel.BackgroundTransparency = 1
	kindLabel.Text = completionItem.Kind
	kindLabel.TextColor3 = Theme.Colors.Comment
	kindLabel.Font = Theme.Fonts.UI
	kindLabel.TextSize = Theme.FontSizes.Small - 2
	kindLabel.TextXAlignment = Enum.TextXAlignment.Right
	kindLabel.Parent = item
	
	return item
end

-- Get icon for completion kind
function EditorGUI.GetKindIcon(kind)
	local icons = {
		Keyword = "🔑",
		Function = "⚡",
		Method = "📞",
		Property = "📌",
		Variable = "📝",
		Class = "📦",
		Constant = "🔷",
		String = "📝",
		Number = "🔢",
		Boolean = "✓",
		Event = "🔔",
		Enum = "📋",
		Field = "🔖",
		File = "📄",
		Folder = "📁",
		Module = "📦",
		Instance = "🎮",
		Builtin = "🔧",
	}
	return icons[kind] or "📄"
end

-- Get color for completion kind
function EditorGUI.GetKindColor(kind)
	local colors = {
		Keyword = Theme.Colors.Keyword,
		Function = Theme.Colors.Function,
		Method = Theme.Colors.Method,
		Property = Theme.Colors.Property,
		Variable = Theme.Colors.Variable,
		Class = Theme.Colors.Class,
		Constant = Theme.Colors.Number,
		String = Theme.Colors.String,
		Number = Theme.Colors.Number,
		Boolean = Theme.Colors.BuiltIn,
		Event = Theme.Colors.Warning,
		Enum = Theme.Colors.BuiltIn,
		Field = Theme.Colors.Variable,
		File = Theme.Colors.Foreground,
		Folder = Theme.Colors.Warning,
		Module = Theme.Colors.Class,
		Instance = Theme.Colors.Accent,
		Builtin = Theme.Colors.BuiltIn,
	}
	return colors[kind] or Theme.Colors.Foreground
end

-- Create file item in sidebar
function EditorGUI.CreateFileItem(parent, file, index, indent)
	indent = indent or 0
	
	local item = Instance.new("TextButton")
	item.Name = "File_" .. file.Name
	item.Size = UDim2.new(1, 0, 0, 26)
	item.BackgroundColor3 = Theme.Colors.BackgroundDark
	item.BorderSizePixel = 0
	item.Text = ""
	item.Parent = parent
	
	-- Highlight for active file
	local highlight = Instance.new("Frame")
	highlight.Name = "Highlight"
	highlight.Size = UDim2.new(1, 0, 1, 0)
	highlight.BackgroundColor3 = Theme.Colors.Selection
	highlight.BackgroundTransparency = 1
	highlight.BorderSizePixel = 0
	highlight.Parent = item
	
	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 24, 1, 0)
	icon.Position = UDim2.new(0, 8 + indent * 16, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Text = "📄"
	icon.TextSize = Theme.FontSizes.Small
	icon.Parent = item
	
	-- Name
	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.Size = UDim2.new(1, -40 - indent * 16, 1, 0)
	name.Position = UDim2.new(0, 32 + indent * 16, 0, 0)
	name.BackgroundTransparency = 1
	name.Text = file.Name
	name.TextColor3 = Theme.Colors.Foreground
	name.Font = Theme.Fonts.UI
	name.TextSize = Theme.FontSizes.Small
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = item
	
	-- Modified indicator
	if file.IsModified then
		local modified = Instance.new("TextLabel")
		modified.Name = "Modified"
		modified.Size = UDim2.new(0, 16, 1, 0)
		modified.Position = UDim2.new(1, -20, 0, 0)
		modified.BackgroundTransparency = 1
		modified.Text = "●"
		modified.TextColor3 = Theme.Colors.Warning
		modified.TextSize = 10
		modified.Parent = item
	end
	
	-- Context menu button
	local contextBtn = Instance.new("TextButton")
	contextBtn.Name = "ContextButton"
	contextBtn.Size = UDim2.new(0, 20, 1, 0)
	contextBtn.Position = UDim2.new(1, -24, 0, 0)
	contextBtn.BackgroundTransparency = 1
	contextBtn.Text = "⋮"
	contextBtn.TextColor3 = Theme.Colors.Comment
	contextBtn.TextSize = 14
	contextBtn.Visible = false
	contextBtn.Parent = item
	
	item.MouseEnter:Connect(function()
		contextBtn.Visible = true
		highlight.BackgroundTransparency = 0.8
	end)
	
	item.MouseLeave:Connect(function()
		contextBtn.Visible = false
		highlight.BackgroundTransparency = 1
	end)
	
	return item
end

-- Create folder item in sidebar
function EditorGUI.CreateFolderItem(parent, folder, indent)
	indent = indent or 0
	
	local item = Instance.new("TextButton")
	item.Name = "Folder_" .. folder.Name
	item.Size = UDim2.new(1, 0, 0, 26)
	item.BackgroundColor3 = Theme.Colors.BackgroundDark
	item.BorderSizePixel = 0
	item.Text = ""
	item.Parent = parent
	
	-- Expand icon
	local expandIcon = Instance.new("TextLabel")
	expandIcon.Name = "ExpandIcon"
	expandIcon.Size = UDim2.new(0, 20, 1, 0)
	expandIcon.Position = UDim2.new(0, indent * 16, 0, 0)
	expandIcon.BackgroundTransparency = 1
	expandIcon.Text = "▶"
	expandIcon.TextColor3 = Theme.Colors.Comment
	expandIcon.TextSize = 10
	expandIcon.Parent = item
	
	-- Folder icon
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 20, 1, 0)
	icon.Position = UDim2.new(0, 16 + indent * 16, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Text = "📁"
	icon.TextSize = Theme.FontSizes.Small
	icon.Parent = item
	
	-- Name
	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.Size = UDim2.new(1, -48 - indent * 16, 1, 0)
	name.Position = UDim2.new(0, 36 + indent * 16, 0, 0)
	name.BackgroundTransparency = 1
	name.Text = folder.Name
	name.TextColor3 = Theme.Colors.Foreground
	name.Font = Theme.Fonts.UI
	name.TextSize = Theme.FontSizes.Small
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = item
	
	return item
end

-- Create tab for open file
function EditorGUI.CreateTab(parent, file)
	local tab = Instance.new("TextButton")
	tab.Name = "Tab_" .. file.Name
	tab.Size = UDim2.new(0, 120, 1, 0)
	tab.BackgroundColor3 = Theme.Colors.Background
	tab.Text = ""
	tab.BorderSizePixel = 0
	tab.Parent = parent
	
	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.Size = UDim2.new(0, 18, 0, 18)
	closeBtn.Position = UDim2.new(1, -22, 0.5, -9)
	closeBtn.BackgroundColor3 = Theme.Colors.Error
	closeBtn.Text = "×"
	closeBtn.TextColor3 = Theme.Colors.White
	closeBtn.TextSize = 12
	closeBtn.Visible = false
	closeBtn.Parent = tab
	Theme.CreateCorner(closeBtn, 4)
	
	-- Modified indicator
	local modified = Instance.new("TextLabel")
	modified.Name = "Modified"
	modified.Size = UDim2.new(0, 8, 0, 8)
	modified.Position = UDim2.new(0, 6, 0.5, -4)
	modified.BackgroundColor3 = Theme.Colors.Warning
	modified.BackgroundTransparency = file.IsModified and 0 or 1
	modified.Text = ""
	modified.Parent = tab
	Theme.CreateCorner(modified, 4)
	
	-- Tab name
	local tabName = Instance.new("TextLabel")
	tabName.Name = "Name"
	tabName.Size = UDim2.new(1, -30, 1, 0)
	tabName.Position = UDim2.new(0, 16, 0, 0)
	tabName.BackgroundTransparency = 1
	tabName.Text = file.Name
	tabName.TextColor3 = Theme.Colors.Foreground
	tabName.Font = Theme.Fonts.UI
	tabName.TextSize = Theme.FontSizes.Small
	tabName.TextXAlignment = Enum.TextXAlignment.Left
	tabName.TextTruncate = Enum.TextTruncate.AtEnd
	tabName.Parent = tab
	
	tab.MouseEnter:Connect(function()
		closeBtn.Visible = true
	end)
	
	tab.MouseLeave:Connect(function()
		closeBtn.Visible = false
	end)
	
	return tab
end

return EditorGUI
