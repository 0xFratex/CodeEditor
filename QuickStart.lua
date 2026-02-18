--[[
        Dracula Code Editor - Quick Start Script
        
        This is a single-file version that can be pasted directly into Roblox Studio.
        Just create a LocalScript in StarterPlayerScripts and paste this code.
        
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
        },
        Fonts = {
                Main = Enum.Font.Code,
                UI = Enum.Font.Gotham,
                Title = Enum.Font.GothamBold,
        },
}

-- ============================================
-- INTELLISENSE
-- ============================================

local Keywords = {"and", "break", "do", "else", "elseif", "end", "false", "for", "function", 
        "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while", "continue"}

local Builtins = {"print", "warn", "error", "assert", "type", "typeof", "tostring", "tonumber",
        "pairs", "ipairs", "next", "select", "pcall", "xpcall", "tick", "time", "wait", "spawn", "delay",
        "Instance", "Color3", "Vector3", "Vector2", "CFrame", "UDim", "UDim2", "BrickColor", "Enum"}

local RobloxServices = {"Players", "Lighting", "ReplicatedStorage", "ReplicatedFirst", "ServerStorage",
        "ServerScriptService", "StarterGui", "StarterPack", "StarterPlayer", "TweenService",
        "UserInputService", "RunService", "HttpService", "DataStoreService", "TeleportService"}

local InstanceMethods = {"Clone", "Destroy", "FindFirstChild", "FindFirstChildOfClass", "GetChildren",
        "GetDescendants", "IsA", "WaitForChild", "ClearAllChildren", "GetAttribute", "SetAttribute"}

local function getCompletions(text, cursorPos)
        local prefix = ""
        local context = "general"
        
        -- Get word being typed
        local wordStart = cursorPos
        while wordStart > 1 and string.sub(text, wordStart - 1, wordStart - 1):match("[%w_]") do
                wordStart = wordStart - 1
        end
        prefix = string.sub(text, wordStart, cursorPos - 1):lower()
        
        -- Determine context
        local before = string.sub(text, 1, cursorPos - 1)
        
        if before:match("game%.$") then
                context = "game"
        elseif before:match("workspace%.$") then
                context = "workspace"
        elseif before:match(":%w-$") then
                context = "method"
        elseif before:match("%.$") then
                context = "property"
        elseif before:match(":GetChildren%(%)[%s]*$") then
                context = "getchildren"
        end
        
        local completions = {}
        
        -- GetChildren() special handling
        if context == "getchildren" then
                local expr = before:match("(.+):GetChildren%(%)[%s]*$")
                if expr then
                        local instance = nil
                        if expr == "game" then instance = game
                        elseif expr == "workspace" then instance = workspace
                        elseif expr:match("^game%.(%w+)$") then
                                instance = game:GetService(expr:match("^game%.(%w+)$"))
                        end
                        
                        if instance then
                                local children = instance:GetChildren()
                                for i, child in ipairs(children) do
                                        if i <= 15 then
                                                table.insert(completions, {
                                                        name = child.Name,
                                                        detail = string.format("%s:GetChildren()[%d]", expr, i - 1),
                                                        kind = "Instance",
                                                        index = i - 1,
                                                })
                                        end
                                end
                        end
                end
                return completions, "getchildren"
        end
        
        -- Game services
        if context == "game" then
                for _, service in ipairs(RobloxServices) do
                        if prefix == "" or service:lower():find(prefix, 1, true) then
                                table.insert(completions, {name = service, detail = "Service", kind = "Service"})
                        end
                end
                return completions, context
        end
        
        -- Workspace children
        if context == "workspace" then
                for _, child in ipairs(workspace:GetChildren()) do
                        if prefix == "" or child.Name:lower():find(prefix, 1, true) then
                                table.insert(completions, {name = child.Name, detail = child.ClassName, kind = "Instance"})
                        end
                end
                return completions, context
        end
        
        -- Methods
        if context == "method" then
                for _, method in ipairs(InstanceMethods) do
                        if prefix == "" or method:lower():find(prefix, 1, true) then
                                table.insert(completions, {name = method, detail = "Method", kind = "Method"})
                        end
                end
                return completions, context
        end
        
        -- General completions
        for _, kw in ipairs(Keywords) do
                if prefix == "" or kw:lower():find(prefix, 1, true) then
                        table.insert(completions, {name = kw, detail = "Keyword", kind = "Keyword"})
                end
        end
        
        for _, builtin in ipairs(Builtins) do
                if prefix == "" or builtin:lower():find(prefix, 1, true) then
                        table.insert(completions, {name = builtin, detail = "Built-in", kind = "Builtin"})
                end
        end
        
        table.insert(completions, {name = "game", detail = "The game DataModel", kind = "Global"})
        table.insert(completions, {name = "workspace", detail = "The workspace", kind = "Global"})
        
        return completions, context
end

-- ============================================
-- GUI CREATION
-- ============================================

local function createEditor()
        -- Create ScreenGui container (required for UI to render)
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "DraculaEditorGui"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexMode = Enum.ZIndexMode.Sibling
        screenGui.Parent = playerGui
        
        -- Main Frame
        local frame = Instance.new("Frame")
        frame.Name = "DraculaEditor"
        frame.Size = UDim2.new(0, 850, 0, 550)
        frame.Position = UDim2.new(0.5, -425, 0.5, -275)
        frame.BackgroundColor3 = Theme.Colors.Background
        frame.BorderSizePixel = 0
        frame.Visible = false
        frame.Parent = screenGui
        
        -- Drag Handle
        local drag = Instance.new("Frame")
        drag.Size = UDim2.new(1, 0, 0, 35)
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
        title.TextSize = 16
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = drag
        
        -- Close Button
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 30, 0, 25)
        closeBtn.Position = UDim2.new(1, -38, 0, 5)
        closeBtn.BackgroundColor3 = Theme.Colors.Error
        closeBtn.Text = "×"
        closeBtn.TextColor3 = Color3.new(1, 1, 1)
        closeBtn.Font = Theme.Fonts.UI
        closeBtn.TextSize = 18
        closeBtn.Parent = drag
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = closeBtn
        
        -- Code Editor
        local editor = Instance.new("TextBox")
        editor.Name = "CodeEditor"
        editor.Size = UDim2.new(1, -20, 1, -100)
        editor.Position = UDim2.new(0, 10, 0, 45)
        editor.BackgroundColor3 = Theme.Colors.BackgroundDark
        editor.TextColor3 = Theme.Colors.Foreground
        editor.Font = Theme.Fonts.Main
        editor.TextSize = 14
        editor.TextXAlignment = Enum.TextXAlignment.Left
        editor.TextYAlignment = Enum.TextYAlignment.Top
        editor.MultiLine = true
        editor.ClearTextOnFocus = false
        editor.Text = "-- Welcome to Dracula Code Editor!\n-- Press F5 to run your code\n\nprint('Hello, Dracula!')\n"
        editor.PlaceholderText = "-- Start coding..."
        editor.PlaceholderColor3 = Theme.Colors.Comment
        editor.Parent = frame
        
        corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = editor
        
        -- Intellisense Dropdown
        local intellisense = Instance.new("ScrollingFrame")
        intellisense.Name = "Intellisense"
        intellisense.Size = UDim2.new(0, 250, 0, 0)
        intellisense.BackgroundColor3 = Theme.Colors.BackgroundLight
        intellisense.BorderSizePixel = 0
        intellisense.Visible = false
        intellisense.ScrollBarThickness = 6
        intellisense.ZIndex = 100
        intellisense.Parent = editor
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Colors.Border
        stroke.Parent = intellisense
        
        corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = intellisense
        
        local listLayout = Instance.new("UIListLayout")
        listLayout.Parent = intellisense
        
        -- Output Panel
        local output = Instance.new("Frame")
        output.Name = "Output"
        output.Size = UDim2.new(1, -20, 0, 45)
        output.Position = UDim2.new(0, 10, 1, -55)
        output.BackgroundColor3 = Theme.Colors.BackgroundDark
        output.Parent = frame
        
        corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = output
        
        local outputText = Instance.new("TextLabel")
        outputText.Size = UDim2.new(1, -100, 1, 0)
        outputText.Position = UDim2.new(0, 10, 0, 0)
        outputText.BackgroundTransparency = 1
        outputText.Text = "[Dracula] Ready to code..."
        outputText.TextColor3 = Theme.Colors.Comment
        outputText.Font = Theme.Fonts.Main
        outputText.TextSize = 13
        outputText.TextXAlignment = Enum.TextXAlignment.Left
        outputText.TextTruncate = Enum.TextTruncate.AtEnd
        outputText.Parent = output
        
        -- Run Button
        local runBtn = Instance.new("TextButton")
        runBtn.Size = UDim2.new(0, 70, 0, 30)
        runBtn.Position = UDim2.new(1, -85, 0.5, -15)
        runBtn.BackgroundColor3 = Theme.Colors.Success
        runBtn.Text = "▶ Run"
        runBtn.TextColor3 = Theme.Colors.Background
        runBtn.Font = Theme.Fonts.UI
        runBtn.TextSize = 14
        runBtn.Parent = output
        
        corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = runBtn
        
        -- Help Label
        local help = Instance.new("TextLabel")
        help.Size = UDim2.new(0, 200, 0, 20)
        help.Position = UDim2.new(0, 10, 1, -20)
        help.BackgroundTransparency = 1
        help.Text = "F8: Toggle | F5: Run | Tab: Accept"
        help.TextColor3 = Theme.Colors.Comment
        help.Font = Theme.Fonts.UI
        help.TextSize = 11
        help.Parent = frame
        
        return frame, editor, intellisense, outputText, runBtn, closeBtn
end

-- ============================================
-- MAIN LOGIC
-- ============================================

local mainFrame, codeEditor, intellisenseFrame, outputLabel, runButton, closeButton = createEditor()
local isVisible = false
local intellisenseVisible = false
local currentCompletions = {}
local selectedIndex = 1

-- Show/Hide
local function toggle()
        isVisible = not isVisible
        mainFrame.Visible = isVisible
        if isVisible then
                codeEditor:CaptureFocus()
        end
end

-- Show intellisense
local function showIntellisense(completions)
        currentCompletions = completions
        selectedIndex = 1
        
        -- Clear existing
        for _, child in ipairs(intellisenseFrame:GetChildren()) do
                if child:IsA("TextButton") then
                        child:Destroy()
                end
        end
        
        if #completions == 0 then
                intellisenseFrame.Visible = false
                intellisenseVisible = false
                return
        end
        
        -- Add items
        for i, completion in ipairs(completions) do
                local item = Instance.new("TextButton")
                item.Size = UDim2.new(1, 0, 0, 22)
                item.BackgroundColor3 = i == 1 and Theme.Colors.Selection or Theme.Colors.BackgroundLight
                item.Text = "  " .. completion.name
                item.TextColor3 = Theme.Colors.Foreground
                item.Font = Theme.Fonts.Main
                item.TextSize = 13
                item.TextXAlignment = Enum.TextXAlignment.Left
                item.ZIndex = 101
                item.Parent = intellisenseFrame
                
                item.MouseButton1Click:Connect(function()
                        -- Apply completion
                        local cursorPos = codeEditor.CursorPosition
                        local text = codeEditor.Text
                        
                        -- Find word start
                        local wordStart = cursorPos
                        while wordStart > 1 and string.sub(text, wordStart - 1, wordStart - 1):match("[%w_]") do
                                wordStart = wordStart - 1
                        end
                        
                        local before = string.sub(text, 1, wordStart - 1)
                        local after = string.sub(text, cursorPos)
                        
                        -- Special handling for GetChildren results
                        if completion.detail:find("GetChildren") then
                                codeEditor.Text = before .. completion.detail .. after
                                codeEditor.CursorPosition = #before + #completion.detail + 1
                        else
                                codeEditor.Text = before .. completion.name .. after
                                codeEditor.CursorPosition = #before + #completion.name + 1
                        end
                        
                        intellisenseFrame.Visible = false
                        intellisenseVisible = false
                end)
        end
        
        -- Size and position
        local height = math.min(#completions * 22, 200)
        intellisenseFrame.Size = UDim2.new(0, 250, 0, height)
        intellisenseFrame.Position = UDim2.new(0, 20, 0, 50)
        intellisenseFrame.CanvasSize = UDim2.new(0, 0, 0, #completions * 22)
        intellisenseFrame.Visible = true
        intellisenseVisible = true
end

-- Run code
local function runCode()
        local code = codeEditor.Text
        outputLabel.Text = "[Running...]"
        
        local success, result = pcall(function()
                local fn = loadstring(code)
                if fn then
                        -- Capture print output
                        local outputs = {}
                        local oldPrint = print
                        _G.print = function(...)
                                local args = {...}
                                local str = ""
                                for i, arg in ipairs(args) do
                                        str = str .. tostring(arg) .. (i < #args and "\t" or "")
                                end
                                table.insert(outputs, str)
                        end
                        
                        fn()
                        
                        _G.print = oldPrint
                        
                        if #outputs > 0 then
                                outputLabel.Text = table.concat(outputs, " | ")
                        else
                                outputLabel.Text = "[✓] Code executed successfully"
                        end
                end
        end)
        
        if not success then
                outputLabel.Text = "[✗] Error: " .. tostring(result):sub(1, 80)
        end
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

-- Toggle with F8
UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.F8 then
                toggle()
        end
        
        if not isVisible then return end
        
        -- Run with F5
        if input.KeyCode == Enum.KeyCode.F5 then
                runCode()
        end
        
        -- Navigate intellisense
        if intellisenseVisible then
                if input.KeyCode == Enum.KeyCode.Down then
                        selectedIndex = math.min(selectedIndex + 1, #currentCompletions)
                elseif input.KeyCode == Enum.KeyCode.Up then
                        selectedIndex = math.max(selectedIndex - 1, 1)
                elseif input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.Return then
                        if currentCompletions[selectedIndex] then
                                local cursorPos = codeEditor.CursorPosition
                                local text = codeEditor.Text
                                
                                local wordStart = cursorPos
                                while wordStart > 1 and string.sub(text, wordStart - 1, wordStart - 1):match("[%w_]") do
                                        wordStart = wordStart - 1
                                end
                                
                                local before = string.sub(text, 1, wordStart - 1)
                                local after = string.sub(text, cursorPos)
                                
                                local completion = currentCompletions[selectedIndex]
                                if completion.detail:find("GetChildren") then
                                        codeEditor.Text = before .. completion.detail .. after
                                        codeEditor.CursorPosition = #before + #completion.detail + 1
                                else
                                        codeEditor.Text = before .. completion.name .. after
                                        codeEditor.CursorPosition = #before + #completion.name + 1
                                end
                                
                                intellisenseFrame.Visible = false
                                intellisenseVisible = false
                        end
                elseif input.KeyCode == Enum.KeyCode.Escape then
                        intellisenseFrame.Visible = false
                        intellisenseVisible = false
                end
        end
end)

-- Text changed - trigger intellisense
codeEditor:GetPropertyChangedSignal("Text"):Connect(function()
        local cursorPos = codeEditor.CursorPosition
        local text = codeEditor.Text
        
        -- Debounce
        task.wait(0.05)
        
        if cursorPos ~= codeEditor.CursorPosition then return end
        
        local completions, context = getCompletions(text, cursorPos)
        
        if #completions > 0 and (context == "general" or context == "game" or context == "workspace" or 
                context == "method" or context == "getchildren") then
                showIntellisense(completions)
        else
                intellisenseFrame.Visible = false
                intellisenseVisible = false
        end
end)

-- Button clicks
runButton.MouseButton1Click:Connect(runCode)
closeButton.MouseButton1Click:Connect(toggle)

-- Dragging
local dragging = false
local dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and 
           input.Position.Y < mainFrame.AbsolutePosition.Y + 35 then
                dragging = true
                dragStart = input.Position
                startPos = mainFrame.Position
        end
end)

mainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
        end
end)

UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                mainFrame.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
        end
end)

print("🦇 Dracula Code Editor loaded! Press F8 to toggle.")
