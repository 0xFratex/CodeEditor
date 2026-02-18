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
FileSystem.enabled = false

function FileSystem.isAvailable()
        return writefile ~= nil and readfile ~= nil and isfile ~= nil and isfolder ~= nil
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
                if success then return result end
        end
        return nil
end

function FileSystem.listFiles(path)
        if listfiles then
                local success, result = pcall(function()
                        return listfiles(path or "")
                end)
                if success then return result or {} end
        end
        return {}
end

function FileSystem.fileExists(path)
        if isfile then
                local success, result = pcall(function() return isfile(path) end)
                return success and result
        end
        return false
end

function FileSystem.folderExists(path)
        if isfolder then
                local success, result = pcall(function() return isfolder(path) end)
                return success and result
        end
        return false
end

function FileSystem.createFolder(path)
        if makefolder then
                local success, err = pcall(function() makefolder(path) end)
                return success, err
        end
        return false, "makefolder not available"
end

function FileSystem.deleteFile(path)
        if delfile then
                local success, err = pcall(function() delfile(path) end)
                return success, err
        end
        return false, "delfile not available"
end

function FileSystem.deleteFolder(path)
        if delfolder then
                local success, err = pcall(function() delfolder(path) end)
                return success, err
        end
        return false, "delfolder not available"
end

-- Initialize folders
if FileSystem.isAvailable() then
        FileSystem.enabled = true
        if not FileSystem.folderExists("DraculaEditor") then
                FileSystem.createFolder("DraculaEditor")
        end
        if not FileSystem.folderExists("DraculaEditor/Scripts") then
                FileSystem.createFolder("DraculaEditor/Scripts")
        end
end

-- ============================================
-- CONFIG SYSTEM
-- ============================================

local Config = {
        fontSize = 14,
        autoSave = true,
        enableIntellisense = true,
        enableErrorDetection = true,
        recentFiles = {},
}

local ConfigManager = {}

function ConfigManager.load()
        if not FileSystem.enabled then return end
        local content = FileSystem.readFile("DraculaEditor/config.json")
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
        FileSystem.writeFile("DraculaEditor/config.json", json)
end

ConfigManager.load()

-- ============================================
-- THEME
-- ============================================

local Theme = {
        Colors = {
                Background = Color3.fromRGB(30, 31, 40),
                BackgroundLight = Color3.fromRGB(55, 58, 72),
                BackgroundDark = Color3.fromRGB(24, 25, 32),
                Selection = Color3.fromRGB(65, 68, 85),
                Foreground = Color3.fromRGB(248, 248, 242),
                Comment = Color3.fromRGB(98, 114, 164),
                Keyword = Color3.fromRGB(255, 121, 198),
                String = Color3.fromRGB(241, 250, 140),
                Number = Color3.fromRGB(189, 147, 249),
                Function = Color3.fromRGB(80, 250, 123),
                BuiltIn = Color3.fromRGB(139, 233, 253),
                Property = Color3.fromRGB(255, 184, 108),
                Border = Color3.fromRGB(70, 74, 92),
                Success = Color3.fromRGB(80, 250, 123),
                Warning = Color3.fromRGB(255, 184, 108),
                Error = Color3.fromRGB(255, 85, 85),
                Info = Color3.fromRGB(139, 233, 253),
                Accent = Color3.fromRGB(189, 147, 249),
                Button = Color3.fromRGB(75, 78, 95),
                Scrollbar = Color3.fromRGB(55, 58, 72),
                Cursor = Color3.fromRGB(248, 248, 242),
                White = Color3.fromRGB(255, 255, 255),
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
        ["pcall"] = true, ["xpcall"] = true, ["tick"] = true, ["time"] = true,
        ["wait"] = true, ["delay"] = true, ["spawn"] = true, ["Instance"] = true,
        ["Color3"] = true, ["Vector3"] = true, ["Vector2"] = true, ["CFrame"] = true,
        ["UDim"] = true, ["UDim2"] = true, ["Enum"] = true, ["task"] = true,
        ["string"] = true, ["table"] = true, ["math"] = true, ["os"] = true,
        ["game"] = true, ["workspace"] = true, ["script"] = true, ["loadstring"] = true,
}

local function escapeXml(text)
        text = text:gsub("&", "&amp;")
        text = text:gsub("<", "&lt;")
        text = text:gsub(">", "&gt;")
        return text
end

local function colorToHex(color)
        return string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
end

local function highlightCode(code)
        local result = {}
        local pos = 1
        local len = #code
        
        local function peek(offset)
                return code:sub(pos + (offset or 0), pos + (offset or 0))
        end
        
        while pos <= len do
                local char = peek()
                
                if char == "\n" then
                        table.insert(result, "\n")
                        pos = pos + 1
                elseif char:match("%s") then
                        local ws = ""
                        while pos <= len and peek():match("%s") and peek() ~= "\n" do
                                ws = ws .. code:sub(pos, pos)
                                pos = pos + 1
                        end
                        table.insert(result, ws)
                elseif char == "-" and peek(1) == "-" then
                        local comment = ""
                        while pos <= len and peek() ~= "\n" do
                                comment = comment .. code:sub(pos, pos)
                                pos = pos + 1
                        end
                        table.insert(result, '<font color="' .. colorToHex(Theme.Colors.Comment) .. '">' .. escapeXml(comment) .. '</font>')
                elseif char == '"' then
                        local str = '"'
                        pos = pos + 1
                        while pos <= len do
                                local c = peek()
                                if c == "\\" then
                                        str = str .. code:sub(pos, pos + 1)
                                        pos = pos + 2
                                elseif c == '"' or c == "\n" then
                                        if c == '"' then
                                                str = str .. '"'
                                                pos = pos + 1
                                        end
                                        break
                                else
                                        str = str .. code:sub(pos, pos)
                                        pos = pos + 1
                                end
                        end
                        table.insert(result, '<font color="' .. colorToHex(Theme.Colors.String) .. '">' .. escapeXml(str) .. '</font>')
                elseif char == "'" then
                        local str = "'"
                        pos = pos + 1
                        while pos <= len do
                                local c = peek()
                                if c == "\\" then
                                        str = str .. code:sub(pos, pos + 1)
                                        pos = pos + 2
                                elseif c == "'" or c == "\n" then
                                        if c == "'" then
                                                str = str .. "'"
                                                pos = pos + 1
                                        end
                                        break
                                else
                                        str = str .. code:sub(pos, pos)
                                        pos = pos + 1
                                end
                        end
                        table.insert(result, '<font color="' .. colorToHex(Theme.Colors.String) .. '">' .. escapeXml(str) .. '</font>')
                elseif char:match("%d") then
                        local num = ""
                        while pos <= len and peek():match("[%d%.xXa-fA-F]") do
                                num = num .. code:sub(pos, pos)
                                pos = pos + 1
                        end
                        table.insert(result, '<font color="' .. colorToHex(Theme.Colors.Number) .. '">' .. escapeXml(num) .. '</font>')
                elseif char:match("[%a_]") then
                        local id = ""
                        while pos <= len and peek():match("[%w_]") do
                                id = id .. code:sub(pos, pos)
                                pos = pos + 1
                        end
                        if Keywords[id] then
                                table.insert(result, '<font color="' .. colorToHex(Theme.Colors.Keyword) .. '">' .. id .. '</font>')
                        elseif Builtins[id] then
                                table.insert(result, '<font color="' .. colorToHex(Theme.Colors.BuiltIn) .. '">' .. id .. '</font>')
                        else
                                table.insert(result, escapeXml(id))
                        end
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
        if #code < 1 then return {} end
        local errors = {}
        local fn, err = loadstring(code)
        if not fn and err then
                local lineNum = err:match(":(%d+):") or err:match("line (%d+)") or "1"
                local errorMsg = err:match(":%d+:%s*(.+)") or err
                table.insert(errors, {line = tonumber(lineNum) or 1, message = errorMsg})
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
                "Instance", "Color3", "Vector3", "Vector2", "CFrame", "UDim", "UDim2", "Enum", "task"},
        Services = {"Players", "Lighting", "ReplicatedStorage", "ReplicatedFirst", "ServerStorage",
                "ServerScriptService", "StarterGui", "StarterPack", "StarterPlayer", "TweenService",
                "UserInputService", "RunService", "HttpService", "DataStoreService", "TeleportService"},
        Methods = {"Clone", "Destroy", "FindFirstChild", "GetChildren", "GetDescendants", "IsA", "WaitForChild"},
}

local function isInComment(text, cursorPos)
        local textBefore = text:sub(1, cursorPos - 1)
        local inString = false
        local stringChar = nil
        local i = 1
        while i <= #textBefore do
                local char = textBefore:sub(i, i)
                if not inString then
                        if char == '"' or char == "'" then
                                inString = true
                                stringChar = char
                        elseif char == "-" and textBefore:sub(i + 1, i + 1) == "-" then
                                return true
                        end
                else
                        if char == "\\" then
                                i = i + 1
                        elseif char == stringChar then
                                inString = false
                        end
                end
                i = i + 1
        end
        return false
end

local function getCompletions(text, cursorPos)
        local completions = {}
        
        if isInComment(text, cursorPos) then
                return completions, cursorPos
        end
        
        local wordStart = cursorPos
        while wordStart > 1 and text:sub(wordStart - 1, wordStart - 1):match("[%w_]") do
                wordStart = wordStart - 1
        end
        local prefix = text:sub(wordStart, cursorPos - 1):lower()
        local before = text:sub(1, cursorPos - 1)
        
        -- Context-based completions
        if before:match("game%.$") then
                for _, service in ipairs(IntellisenseData.Services) do
                        table.insert(completions, {name = service, kind = "Service", insertText = service})
                end
                return completions, wordStart
        elseif before:match("workspace%.$") then
                local success, children = pcall(function() return workspace:GetChildren() end)
                if success then
                        for _, child in ipairs(children) do
                                table.insert(completions, {name = child.Name, kind = "Instance", insertText = child.Name, detail = child.ClassName})
                        end
                end
                return completions, wordStart
        elseif before:match(":%w-$") then
                for _, method in ipairs(IntellisenseData.Methods) do
                        if prefix == "" or method:lower():find(prefix, 1, true) then
                                table.insert(completions, {name = method, kind = "Method", insertText = method .. "()"})
                        end
                end
                return completions, wordStart
        elseif before:match(":GetChildren%(%)[%s]*$") then
                local expr = before:match("(.+):GetChildren%(%)[%s]*$")
                if expr then
                        local instance = nil
                        if expr == "game" then instance = game
                        elseif expr == "workspace" then instance = workspace
                        elseif expr:match("^game%.(%w+)$") then
                                pcall(function() instance = game:GetService(expr:match("^game%.(%w+)$")) end)
                        end
                        if instance then
                                local success, children = pcall(function() return instance:GetChildren() end)
                                if success then
                                        for i, child in ipairs(children) do
                                                if i <= 15 then
                                                        table.insert(completions, {
                                                                name = child.Name .. " [" .. (i-1) .. "]",
                                                                kind = "Instance",
                                                                insertText = "[" .. (i-1) .. "]",
                                                                detail = child.ClassName
                                                        })
                                                end
                                        end
                                end
                        end
                end
                return completions, wordStart
        end
        
        -- General completions (only if typing)
        if #prefix >= 1 then
                for _, kw in ipairs(IntellisenseData.Keywords) do
                        if kw:lower():find(prefix, 1, true) then
                                table.insert(completions, {name = kw, kind = "Keyword", insertText = kw})
                        end
                end
                for _, builtin in ipairs(IntellisenseData.Builtins) do
                        if builtin:lower():find(prefix, 1, true) then
                                table.insert(completions, {name = builtin, kind = "Function", insertText = builtin .. "()"})
                        end
                end
                if ("game"):lower():find(prefix, 1, true) then
                        table.insert(completions, {name = "game", kind = "Global", insertText = "game"})
                end
                if ("workspace"):lower():find(prefix, 1, true) then
                        table.insert(completions, {name = "workspace", kind = "Global", insertText = "workspace"})
                end
        end
        
        return completions, wordStart
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
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "DraculaEditorGui"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = playerGui
        
        -- Main Frame
        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "DraculaEditor"
        mainFrame.Size = UDim2.new(0, 850, 0, 550)
        mainFrame.Position = UDim2.new(0.5, -425, 0.5, -275)
        mainFrame.BackgroundColor3 = Theme.Colors.Background
        mainFrame.BorderSizePixel = 0
        mainFrame.Visible = false
        mainFrame.Parent = screenGui
        
        -- Header Bar
        local header = Instance.new("Frame")
        header.Name = "Header"
        header.Size = UDim2.new(1, 0, 0, 32)
        header.BackgroundColor3 = Theme.Colors.BackgroundDark
        header.BorderSizePixel = 0
        header.Parent = mainFrame
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0, 200, 1, 0)
        title.Position = UDim2.new(0, 10, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = "🦇 Dracula Editor"
        title.TextColor3 = Theme.Colors.Foreground
        title.Font = Theme.Fonts.Title
        title.TextSize = 14
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = header
        
        -- File Name Label
        local fileNameLabel = Instance.new("TextLabel")
        fileNameLabel.Name = "FileName"
        fileNameLabel.Size = UDim2.new(0, 150, 1, 0)
        fileNameLabel.Position = UDim2.new(0, 200, 0, 0)
        fileNameLabel.BackgroundTransparency = 1
        fileNameLabel.Text = "untitled.lua"
        fileNameLabel.TextColor3 = Theme.Colors.Comment
        fileNameLabel.Font = Theme.Fonts.UI
        fileNameLabel.TextSize = 12
        fileNameLabel.TextXAlignment = Enum.TextXAlignment.Left
        fileNameLabel.Parent = header
        
        -- Buttons container
        local btnContainer = Instance.new("Frame")
        btnContainer.Size = UDim2.new(0, 220, 1, 0)
        btnContainer.Position = UDim2.new(1, -250, 0, 0)
        btnContainer.BackgroundTransparency = 1
        btnContainer.Parent = header
        
        -- Toggle Files Button
        local toggleFilesBtn = Instance.new("TextButton")
        toggleFilesBtn.Size = UDim2.new(0, 50, 0, 24)
        toggleFilesBtn.Position = UDim2.new(0, 0, 0.5, -12)
        toggleFilesBtn.BackgroundColor3 = Theme.Colors.Button
        toggleFilesBtn.Text = "📁"
        toggleFilesBtn.TextColor3 = Theme.Colors.Foreground
        toggleFilesBtn.Font = Theme.Fonts.UI
        toggleFilesBtn.TextSize = 14
        toggleFilesBtn.Parent = btnContainer
        createCorner(toggleFilesBtn, 4)
        
        -- Save Button
        local saveBtn = Instance.new("TextButton")
        saveBtn.Size = UDim2.new(0, 50, 0, 24)
        saveBtn.Position = UDim2.new(0, 55, 0.5, -12)
        saveBtn.BackgroundColor3 = Theme.Colors.Info
        saveBtn.Text = "💾"
        saveBtn.TextColor3 = Theme.Colors.Background
        saveBtn.Font = Theme.Fonts.UI
        saveBtn.TextSize = 14
        saveBtn.Parent = btnContainer
        createCorner(saveBtn, 4)
        
        -- Run Button
        local runBtn = Instance.new("TextButton")
        runBtn.Size = UDim2.new(0, 70, 0, 24)
        runBtn.Position = UDim2.new(0, 110, 0.5, -12)
        runBtn.BackgroundColor3 = Theme.Colors.Success
        runBtn.Text = "▶ Run"
        runBtn.TextColor3 = Theme.Colors.Background
        runBtn.Font = Theme.Fonts.UI
        runBtn.TextSize = 12
        runBtn.Parent = btnContainer
        createCorner(runBtn, 4)
        
        -- Close Button
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 28, 0, 24)
        closeBtn.Position = UDim2.new(1, -35, 0.5, -12)
        closeBtn.BackgroundColor3 = Theme.Colors.Error
        closeBtn.Text = "×"
        closeBtn.TextColor3 = Theme.Colors.White
        closeBtn.Font = Theme.Fonts.UI
        closeBtn.TextSize = 16
        closeBtn.Parent = header
        createCorner(closeBtn, 4)
        
        -- Sidebar (File Browser)
        local sidebar = Instance.new("Frame")
        sidebar.Name = "Sidebar"
        sidebar.Size = UDim2.new(0, 180, 1, -32)
        sidebar.Position = UDim2.new(0, 0, 0, 32)
        sidebar.BackgroundColor3 = Theme.Colors.BackgroundDark
        sidebar.BorderSizePixel = 0
        sidebar.Visible = false
        sidebar.Parent = mainFrame
        
        -- Sidebar Header
        local sidebarHeader = Instance.new("Frame")
        sidebarHeader.Size = UDim2.new(1, 0, 0, 28)
        sidebarHeader.BackgroundColor3 = Theme.Colors.BackgroundLight
        sidebarHeader.BorderSizePixel = 0
        sidebarHeader.Parent = sidebar
        
        local sidebarTitle = Instance.new("TextLabel")
        sidebarTitle.Size = UDim2.new(1, -70, 1, 0)
        sidebarTitle.Position = UDim2.new(0, 8, 0, 0)
        sidebarTitle.BackgroundTransparency = 1
        sidebarTitle.Text = "Files"
        sidebarTitle.TextColor3 = Theme.Colors.Comment
        sidebarTitle.Font = Theme.Fonts.UI
        sidebarTitle.TextSize = 11
        sidebarTitle.TextXAlignment = Enum.TextXAlignment.Left
        sidebarTitle.Parent = sidebarHeader
        
        -- New File Button
        local newFileBtn = Instance.new("TextButton")
        newFileBtn.Size = UDim2.new(0, 22, 0, 22)
        newFileBtn.Position = UDim2.new(1, -55, 0.5, -11)
        newFileBtn.BackgroundColor3 = Theme.Colors.Button
        newFileBtn.Text = "+"
        newFileBtn.TextColor3 = Theme.Colors.Foreground
        newFileBtn.Font = Theme.Fonts.UI
        newFileBtn.TextSize = 14
        newFileBtn.Parent = sidebarHeader
        createCorner(newFileBtn, 4)
        
        -- New Folder Button
        local newFolderBtn = Instance.new("TextButton")
        newFolderBtn.Size = UDim2.new(0, 22, 0, 22)
        newFolderBtn.Position = UDim2.new(1, -28, 0.5, -11)
        newFolderBtn.BackgroundColor3 = Theme.Colors.Button
        newFolderBtn.Text = "📁"
        newFolderBtn.TextColor3 = Theme.Colors.Foreground
        newFolderBtn.Font = Theme.Fonts.UI
        newFolderBtn.TextSize = 12
        newFolderBtn.Parent = sidebarHeader
        createCorner(newFolderBtn, 4)
        
        -- Close Sidebar Button
        local closeSidebarBtn = Instance.new("TextButton")
        closeSidebarBtn.Size = UDim2.new(0, 22, 0, 22)
        closeSidebarBtn.Position = UDim2.new(1, -82, 0.5, -11)
        closeSidebarBtn.BackgroundColor3 = Theme.Colors.Button
        closeSidebarBtn.Text = "◀"
        closeSidebarBtn.TextColor3 = Theme.Colors.Foreground
        closeSidebarBtn.Font = Theme.Fonts.UI
        closeSidebarBtn.TextSize = 10
        closeSidebarBtn.Parent = sidebarHeader
        createCorner(closeSidebarBtn, 4)
        
        -- File List
        local fileList = Instance.new("ScrollingFrame")
        fileList.Name = "FileList"
        fileList.Size = UDim2.new(1, 0, 1, -28)
        fileList.Position = UDim2.new(0, 0, 0, 28)
        fileList.BackgroundColor3 = Theme.Colors.BackgroundDark
        fileList.BorderSizePixel = 0
        fileList.ScrollBarThickness = 4
        fileList.ScrollBarImageColor3 = Theme.Colors.Scrollbar
        fileList.Parent = sidebar
        
        local fileListLayout = Instance.new("UIListLayout")
        fileListLayout.Parent = fileList
        
        -- Code Container
        local codeContainer = Instance.new("Frame")
        codeContainer.Name = "CodeContainer"
        codeContainer.Size = UDim2.new(1, -16, 1, -80)
        codeContainer.Position = UDim2.new(0, 8, 0, 38)
        codeContainer.BackgroundColor3 = Theme.Colors.BackgroundDark
        codeContainer.Parent = mainFrame
        createCorner(codeContainer, 6)
        
        -- Line Numbers
        local lineNumbers = Instance.new("TextLabel")
        lineNumbers.Name = "LineNumbers"
        lineNumbers.Size = UDim2.new(0, 40, 1, 0)
        lineNumbers.BackgroundColor3 = Theme.Colors.BackgroundDark
        lineNumbers.BackgroundTransparency = 1
        lineNumbers.Text = "1"
        lineNumbers.TextColor3 = Theme.Colors.Comment
        lineNumbers.Font = Theme.Fonts.Main
        lineNumbers.TextSize = Config.fontSize
        lineNumbers.TextXAlignment = Enum.TextXAlignment.Right
        lineNumbers.TextYAlignment = Enum.TextYAlignment.Top
        lineNumbers.Parent = codeContainer
        
        -- Code Display (highlighted)
        local codeDisplay = Instance.new("TextLabel")
        codeDisplay.Name = "CodeDisplay"
        codeDisplay.Size = UDim2.new(1, -48, 1, 0)
        codeDisplay.Position = UDim2.new(0, 44, 0, 0)
        codeDisplay.BackgroundTransparency = 1
        codeDisplay.Text = ""
        codeDisplay.TextColor3 = Theme.Colors.Foreground
        codeDisplay.Font = Theme.Fonts.Main
        codeDisplay.TextSize = Config.fontSize
        codeDisplay.TextXAlignment = Enum.TextXAlignment.Left
        codeDisplay.TextYAlignment = Enum.TextYAlignment.Top
        codeDisplay.RichText = true
        codeDisplay.Parent = codeContainer
        
        -- Cursor
        local cursor = Instance.new("Frame")
        cursor.Name = "Cursor"
        cursor.Size = UDim2.new(0, 2, 0, Config.fontSize + 2)
        cursor.BackgroundColor3 = Theme.Colors.Cursor
        cursor.BorderSizePixel = 0
        cursor.Visible = true
        cursor.ZIndex = 50
        cursor.Parent = codeContainer
        
        -- Code Input (transparent)
        local codeInput = Instance.new("TextBox")
        codeInput.Name = "CodeInput"
        codeInput.Size = UDim2.new(1, -48, 1, 0)
        codeInput.Position = UDim2.new(0, 44, 0, 0)
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
        codeInput.Parent = codeContainer
        
        -- Intellisense
        local intellisense = Instance.new("Frame")
        intellisense.Name = "Intellisense"
        intellisense.Size = UDim2.new(0, 220, 0, 0)
        intellisense.BackgroundColor3 = Theme.Colors.BackgroundLight
        intellisense.BorderSizePixel = 0
        intellisense.Visible = false
        intellisense.ZIndex = 100
        intellisense.Parent = codeContainer
        createCorner(intellisense, 6)
        
        local intellisenseList = Instance.new("ScrollingFrame")
        intellisenseList.Size = UDim2.new(1, 0, 1, 0)
        intellisenseList.BackgroundColor3 = Theme.Colors.BackgroundLight
        intellisenseList.BorderSizePixel = 0
        intellisenseList.ScrollBarThickness = 4
        intellisenseList.ScrollBarImageColor3 = Theme.Colors.Scrollbar
        intellisenseList.ZIndex = 101
        intellisenseList.Parent = intellisense
        
        local intellisenseLayout = Instance.new("UIListLayout")
        intellisenseLayout.Parent = intellisenseList
        
        -- Output Panel
        local outputPanel = Instance.new("Frame")
        outputPanel.Name = "OutputPanel"
        outputPanel.Size = UDim2.new(1, -16, 0, 36)
        outputPanel.Position = UDim2.new(0, 8, 1, -44)
        outputPanel.BackgroundColor3 = Theme.Colors.BackgroundDark
        outputPanel.Parent = mainFrame
        createCorner(outputPanel, 6)
        
        local outputText = Instance.new("TextLabel")
        outputText.Size = UDim2.new(1, -16, 1, 0)
        outputText.Position = UDim2.new(0, 8, 0, 0)
        outputText.BackgroundTransparency = 1
        outputText.Text = "Ready"
        outputText.TextColor3 = Theme.Colors.Comment
        outputText.Font = Theme.Fonts.Main
        outputText.TextSize = 12
        outputText.TextXAlignment = Enum.TextXAlignment.Left
        outputText.TextTruncate = Enum.TextTruncate.AtEnd
        outputText.Parent = outputPanel
        
        return {
                screenGui = screenGui,
                mainFrame = mainFrame,
                header = header,
                closeBtn = closeBtn,
                toggleFilesBtn = toggleFilesBtn,
                saveBtn = saveBtn,
                runBtn = runBtn,
                fileNameLabel = fileNameLabel,
                sidebar = sidebar,
                fileList = fileList,
                fileListLayout = fileListLayout,
                newFileBtn = newFileBtn,
                newFolderBtn = newFolderBtn,
                closeSidebarBtn = closeSidebarBtn,
                codeContainer = codeContainer,
                lineNumbers = lineNumbers,
                codeDisplay = codeDisplay,
                codeInput = codeInput,
                cursor = cursor,
                intellisense = intellisense,
                intellisenseList = intellisenseList,
                outputText = outputText,
        }
end

-- ============================================
-- MAIN LOGIC
-- ============================================

local UI = createEditor()
local State = {
        isVisible = false,
        sidebarVisible = false,
        intellisenseVisible = false,
        currentCompletions = {},
        selectedIndex = 1,
        currentFilePath = nil,
}

-- Text bounds calculation using TextService
local TextService = game:GetService("TextService")

local function getTextBounds(text, fontSize)
        local bounds = TextService:GetTextSize(text, fontSize, Enum.Font.Code, Vector2.new(10000, 10000))
        return bounds.X, bounds.Y
end

local function getCharWidth()
        -- Measure actual character width for Code font
        local width = TextService:GetTextSize("W", Config.fontSize, Enum.Font.Code, Vector2.new(100, 100)).X
        return width
end

local function getLineHeight()
        -- Measure actual line height for Code font
        local height = TextService:GetTextSize("W", Config.fontSize, Enum.Font.Code, Vector2.new(100, 100)).Y
        return height
end

-- Update line numbers
local function updateLineNumbers()
        local text = UI.codeInput.Text
        local lines = 1
        for _ in text:gmatch("\n") do
                lines = lines + 1
        end
        local nums = {}
        for i = 1, lines do
                table.insert(nums, tostring(i))
        end
        UI.lineNumbers.Text = table.concat(nums, "\n")
end

-- Update highlight
local function updateHighlight()
        UI.codeDisplay.Text = highlightCode(UI.codeInput.Text)
end

-- Update cursor position
local function updateCursor()
        local text = UI.codeInput.Text
        local cursorPos = UI.codeInput.CursorPosition
        if cursorPos <= 0 then cursorPos = 1 end
        
        -- Find line number and column
        local lineNum = 1
        local lineStart = 1
        for i = 1, math.min(cursorPos - 1, #text) do
                if text:sub(i, i) == "\n" then
                        lineNum = lineNum + 1
                        lineStart = i + 1
                end
        end
        
        -- Get text before cursor on current line
        local textBeforeCursor = text:sub(lineStart, cursorPos - 1)
        
        -- Measure actual text width for X position
        local textWidth = TextService:GetTextSize(textBeforeCursor, Config.fontSize, Enum.Font.Code, Vector2.new(10000, 100)).X
        local lineHeight = getLineHeight()
        
        -- Position cursor (44 is the left offset for code area)
        local x = textWidth + 44
        local y = (lineNum - 1) * lineHeight
        
        UI.cursor.Position = UDim2.new(0, x, 0, y)
        UI.cursor.Size = UDim2.new(0, 2, 0, lineHeight)
end

-- Position cursor at end
local function positionCursorAtEnd()
        UI.codeInput.CursorPosition = #UI.codeInput.Text + 1
        updateCursor()
end

-- Intellisense functions
local function showIntellisense(completions, wordStart)
        State.currentCompletions = completions
        State.selectedIndex = 1
        
        for _, child in ipairs(UI.intellisenseList:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
        end
        
        if #completions == 0 then
                UI.intellisense.Visible = false
                State.intellisenseVisible = false
                return
        end
        
        for i, completion in ipairs(completions) do
                local item = Instance.new("TextButton")
                item.Size = UDim2.new(1, 0, 0, 22)
                item.BackgroundColor3 = i == 1 and Theme.Colors.Selection or Theme.Colors.BackgroundLight
                item.Text = " " .. completion.name .. (completion.detail and (" (" .. completion.detail .. ")") or "")
                item.TextColor3 = Theme.Colors.Foreground
                item.Font = Theme.Fonts.Main
                item.TextSize = 12
                item.TextXAlignment = Enum.TextXAlignment.Left
                item.ZIndex = 102
                item.Parent = UI.intellisenseList
                
                item.MouseButton1Click:Connect(function()
                        local text = UI.codeInput.Text
                        local cursorPos = UI.codeInput.CursorPosition
                        local before = text:sub(1, wordStart - 1)
                        local after = text:sub(cursorPos)
                        UI.codeInput.Text = before .. completion.insertText .. after
                        UI.codeInput.CursorPosition = #before + #completion.insertText + 1
                        UI.intellisense.Visible = false
                        State.intellisenseVisible = false
                        updateHighlight()
                        updateLineNumbers()
                        updateCursor()
                end)
        end
        
        local height = math.min(#completions * 22, 150)
        UI.intellisense.Size = UDim2.new(0, 220, 0, height)
        
        -- Position intellisense near cursor
        local cursorX = UI.cursor.Position.X.Offset
        local cursorY = UI.cursor.Position.Y.Offset
        local lineHeight = getLineHeight()
        
        -- Make sure intellisense is visible within bounds
        local posX = math.max(0, math.min(cursorX, 400))
        local posY = cursorY + lineHeight + 5
        
        UI.intellisense.Position = UDim2.new(0, posX, 0, posY)
        UI.intellisenseList.CanvasSize = UDim2.new(0, 0, 0, #completions * 22)
        UI.intellisense.Visible = true
        State.intellisenseVisible = true
end

local function hideIntellisense()
        UI.intellisense.Visible = false
        State.intellisenseVisible = false
end

local function highlightIntellisenseItem()
        local items = {}
        for _, child in ipairs(UI.intellisenseList:GetChildren()) do
                if child:IsA("TextButton") then table.insert(items, child) end
        end
        for i, item in ipairs(items) do
                item.BackgroundColor3 = (i == State.selectedIndex) and Theme.Colors.Selection or Theme.Colors.BackgroundLight
        end
end

local function applyCompletion()
        local completion = State.currentCompletions[State.selectedIndex]
        if not completion then return end
        
        local text = UI.codeInput.Text
        local cursorPos = UI.codeInput.CursorPosition
        
        local wordStart = cursorPos
        while wordStart > 1 and text:sub(wordStart - 1, wordStart - 1):match("[%w_]") do
                wordStart = wordStart - 1
        end
        
        local before = text:sub(1, wordStart - 1)
        local after = text:sub(cursorPos)
        
        UI.codeInput.Text = before .. completion.insertText .. after
        UI.codeInput.CursorPosition = #before + #completion.insertText + 1
        
        hideIntellisense()
        updateHighlight()
        updateLineNumbers()
        updateCursor()
end

local function triggerIntellisense()
        if not Config.enableIntellisense then return end
        
        local cursorPos = UI.codeInput.CursorPosition
        local text = UI.codeInput.Text
        if cursorPos <= 0 then cursorPos = 1 end
        
        local completions, wordStart = getCompletions(text, cursorPos)
        
        if #completions > 0 then
                showIntellisense(completions, wordStart)
        else
                hideIntellisense()
        end
end

-- Refresh file list
local function refreshFileList()
        for _, child in ipairs(UI.fileList:GetChildren()) do
                if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
        end
        
        if not FileSystem.enabled then
                local msg = Instance.new("TextLabel")
                msg.Size = UDim2.new(1, 0, 0, 30)
                msg.BackgroundTransparency = 1
                msg.Text = "File system unavailable"
                msg.TextColor3 = Theme.Colors.Comment
                msg.Font = Theme.Fonts.UI
                msg.TextSize = 11
                msg.Parent = UI.fileList
                return
        end
        
        -- List files
        local files = FileSystem.listFiles("DraculaEditor/Scripts")
        
        for _, filePath in ipairs(files) do
                local fileName = filePath:match("([^/]+)$") or filePath
                local isFolder = FileSystem.folderExists(filePath)
                
                local item = Instance.new("TextButton")
                item.Size = UDim2.new(1, 0, 0, 24)
                item.BackgroundColor3 = Theme.Colors.BackgroundDark
                item.Text = ""
                item.Parent = UI.fileList
                
                local icon = Instance.new("TextLabel")
                icon.Size = UDim2.new(0, 20, 1, 0)
                icon.Position = UDim2.new(0, 4, 0, 0)
                icon.BackgroundTransparency = 1
                icon.Text = isFolder and "📁" or "📜"
                icon.TextSize = 11
                icon.Parent = item
                
                local name = Instance.new("TextLabel")
                name.Size = UDim2.new(1, -28, 1, 0)
                name.Position = UDim2.new(0, 22, 0, 0)
                name.BackgroundTransparency = 1
                name.Text = fileName
                name.TextColor3 = Theme.Colors.Foreground
                name.Font = Theme.Fonts.UI
                name.TextSize = 11
                name.TextXAlignment = Enum.TextXAlignment.Left
                name.TextTruncate = Enum.TextTruncate.AtEnd
                name.Parent = item
                
                item.MouseButton1Click:Connect(function()
                        if not isFolder then
                                local content = FileSystem.readFile(filePath)
                                if content then
                                        UI.codeInput.Text = content
                                        State.currentFilePath = filePath
                                        UI.fileNameLabel.Text = fileName
                                        updateHighlight()
                                        updateLineNumbers()
                                        positionCursorAtEnd()
                                end
                        end
                end)
        end
        
        UI.fileList.CanvasSize = UDim2.new(0, 0, 0, #files * 24)
end

-- Toggle sidebar
local function toggleSidebar()
        State.sidebarVisible = not State.sidebarVisible
        UI.sidebar.Visible = State.sidebarVisible
        
        if State.sidebarVisible then
                UI.codeContainer.Size = UDim2.new(1, -196, 1, -80)
                UI.codeContainer.Position = UDim2.new(0, 188, 0, 38)
                refreshFileList()
        else
                UI.codeContainer.Size = UDim2.new(1, -16, 1, -80)
                UI.codeContainer.Position = UDim2.new(0, 8, 0, 38)
        end
end

-- Run code
local function runCode()
        local code = UI.codeInput.Text
        UI.outputText.Text = "Running..."
        UI.outputText.TextColor3 = Theme.Colors.Info
        
        local fn, err = loadstring(code)
        if not fn then
                UI.outputText.Text = "Syntax: " .. (err:match(":%d+:%s*(.+)") or err)
                UI.outputText.TextColor3 = Theme.Colors.Error
                return
        end
        
        local outputs = {}
        local oldPrint, oldWarn = print, warn
        
        _G.print = function(...)
                local args = {...}
                local str = ""
                for i, v in ipairs(args) do str = str .. tostring(v) .. (i < #args and " " or "") end
                table.insert(outputs, str)
        end
        _G.warn = function(...)
                local args = {...}
                local str = "⚠ "
                for i, v in ipairs(args) do str = str .. tostring(v) .. (i < #args and " " or "") end
                table.insert(outputs, str)
        end
        
        local ok, result = pcall(fn)
        
        _G.print = oldPrint
        _G.warn = oldWarn
        
        if not ok then
                UI.outputText.Text = "Error: " .. tostring(result):sub(1, 60)
                UI.outputText.TextColor3 = Theme.Colors.Error
        elseif #outputs > 0 then
                UI.outputText.Text = table.concat(outputs, " | "):sub(1, 100)
                UI.outputText.TextColor3 = Theme.Colors.Foreground
        else
                UI.outputText.Text = "✓ Executed"
                UI.outputText.TextColor3 = Theme.Colors.Success
        end
end

-- Save file
local function saveFile()
        if not FileSystem.enabled then
                UI.outputText.Text = "File system unavailable"
                UI.outputText.TextColor3 = Theme.Colors.Error
                return
        end
        
        local fileName = State.currentFilePath and State.currentFilePath:match("([^/]+)$") or ("script_" .. os.time() .. ".lua")
        local path = State.currentFilePath or "DraculaEditor/Scripts/" .. fileName
        
        local success = FileSystem.writeFile(path, UI.codeInput.Text)
        if success then
                State.currentFilePath = path
                UI.fileNameLabel.Text = fileName
                UI.outputText.Text = "Saved: " .. fileName
                UI.outputText.TextColor3 = Theme.Colors.Success
                refreshFileList()
        else
                UI.outputText.Text = "Save failed"
                UI.outputText.TextColor3 = Theme.Colors.Error
        end
end

-- New file
local function newFile()
        State.currentFilePath = nil
        UI.codeInput.Text = ""
        UI.fileNameLabel.Text = "untitled.lua"
        updateHighlight()
        updateLineNumbers()
        UI.codeInput:CaptureFocus()
end

-- New folder
local function newFolder()
        if not FileSystem.enabled then return end
        
        local folderName = "folder_" .. os.time()
        local path = "DraculaEditor/Scripts/" .. folderName
        FileSystem.createFolder(path)
        refreshFileList()
        UI.outputText.Text = "Created: " .. folderName
        UI.outputText.TextColor3 = Theme.Colors.Success
end

-- Toggle editor
local function toggle()
        State.isVisible = not State.isVisible
        UI.mainFrame.Visible = State.isVisible
        if State.isVisible then
                UI.codeInput:CaptureFocus()
                updateCursor()
        end
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

-- Cursor blink
task.spawn(function()
        while true do
                UI.cursor.Visible = true
                task.wait(0.5)
                UI.cursor.Visible = false
                task.wait(0.5)
        end
end)

-- Text changed
UI.codeInput:GetPropertyChangedSignal("Text"):Connect(function()
        updateHighlight()
        updateLineNumbers()
        updateCursor()
        task.delay(0.05, triggerIntellisense)
end)

-- Cursor position changed
UI.codeInput:GetPropertyChangedSignal("CursorPosition"):Connect(function()
        updateCursor()
        if State.intellisenseVisible then
                triggerIntellisense()
        end
end)

-- Focus
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
        
        if not State.isVisible then return end
        
        if input.KeyCode == Enum.KeyCode.F5 then
                runCode()
        elseif input.KeyCode == Enum.KeyCode.S and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                saveFile()
        end
        
        if State.intellisenseVisible then
                if input.KeyCode == Enum.KeyCode.Down then
                        State.selectedIndex = math.min(State.selectedIndex + 1, #State.currentCompletions)
                        highlightIntellisenseItem()
                elseif input.KeyCode == Enum.KeyCode.Up then
                        State.selectedIndex = math.max(State.selectedIndex - 1, 1)
                        highlightIntellisenseItem()
                elseif input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.Return then
                        applyCompletion()
                elseif input.KeyCode == Enum.KeyCode.Escape then
                        hideIntellisense()
                end
        end
end)

-- Button clicks
UI.closeBtn.MouseButton1Click:Connect(toggle)
UI.toggleFilesBtn.MouseButton1Click:Connect(toggleSidebar)
UI.saveBtn.MouseButton1Click:Connect(saveFile)
UI.runBtn.MouseButton1Click:Connect(runCode)
UI.newFileBtn.MouseButton1Click:Connect(newFile)
UI.newFolderBtn.MouseButton1Click:Connect(newFolder)
UI.closeSidebarBtn.MouseButton1Click:Connect(toggleSidebar)

-- Dragging
local dragging = false
local dragStart, startPos

UI.header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = UI.mainFrame.Position
        end
end)

UI.header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
        end
end)

UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                UI.mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
end)

-- Initialize
UI.codeInput.Text = "-- Dracula Editor\n-- Press F5 to run\n\nprint('Hello!')\n"
updateHighlight()
updateLineNumbers()
positionCursorAtEnd()

print("🦇 Dracula Editor loaded! Press F8 to toggle.")
