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
        -- Create ScreenGui container (required for UI to render)
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "DraculaEditorGui"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexMode = Enum.ZIndexMode.Sibling
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
        
        -- Code editor
        local editor = Instance.new("TextBox")
        editor.Name = "CodeEditor"
        editor.Size = UDim2.new(1, -20, 1, -100)
        editor.Position = UDim2.new(0, 10, 0, 50)
        editor.BackgroundColor3 = Theme.Colors.BackgroundDark
        editor.TextColor3 = Theme.Colors.Foreground
        editor.Font = Theme.Fonts.Mono
        editor.TextSize = Theme.FontSizes.Code
        editor.TextXAlignment = Enum.TextXAlignment.Left
        editor.TextYAlignment = Enum.TextYAlignment.Top
        editor.MultiLine = true
        editor.ClearTextOnFocus = false
        editor.Text = "-- Welcome to Dracula Code Editor!\n-- Press F5 to run your code\n\nprint('Hello, Dracula!')\n"
        editor.PlaceholderText = "-- Start coding..."
        editor.PlaceholderColor3 = Theme.Colors.Comment
        editor.Parent = frame
        Theme.CreateCorner(editor, 6)
        
        -- Output
        local output = Instance.new("TextLabel")
        output.Name = "Output"
        output.Size = UDim2.new(1, -20, 0, 40)
        output.Position = UDim2.new(0, 10, 1, -50)
        output.BackgroundColor3 = Theme.Colors.BackgroundDark
        output.TextColor3 = Theme.Colors.Comment
        output.Font = Theme.Fonts.Mono
        output.TextSize = 12
        output.TextXAlignment = Enum.TextXAlignment.Left
        output.Text = "[Dracula] Ready to code..."
        output.Parent = frame
        Theme.CreateCorner(output, 6)
        
        -- Run button
        local runBtn = Instance.new("TextButton")
        runBtn.Name = "RunButton"
        runBtn.Size = UDim2.new(0, 80, 0, 32)
        runBtn.Position = UDim2.new(1, -100, 1, -46)
        runBtn.BackgroundColor3 = Theme.Colors.Success
        runBtn.Text = "▶ Run"
        runBtn.TextColor3 = Theme.Colors.Background
        runBtn.Font = Theme.Fonts.UI
        runBtn.TextSize = Theme.FontSizes.Normal
        runBtn.Parent = frame
        Theme.CreateCorner(runBtn, 4)
        
        -- Run button click
        runBtn.MouseButton1Click:Connect(function()
                Editor.RunCode()
        end)
        
        Editor.ScreenGui = screenGui
        Editor.Frame = frame
        Editor.Editor = editor
        Editor.Output = output
        
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
        
        local fn, err = loadstring(code)
        if fn then
                local success, result = pcall(fn)
                if success then
                        Editor.Output.Text = "[✓] Code executed successfully"
                else
                        Editor.Output.Text = "[✗] Error: " .. tostring(result):sub(1, 100)
                end
        else
                Editor.Output.Text = "[✗] Syntax Error: " .. tostring(err):sub(1, 100)
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
        
        if Editor.State.IsVisible then
                if input.KeyCode == Enum.KeyCode.F5 then
                        Editor.RunCode()
                end
        end
end)

_G.DraculaEditor.Main = Editor

print("🦇 Dracula Code Editor loaded!")
print("   Press F8 to toggle the editor")

return Editor
