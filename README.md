# 🦇 Dracula Code Editor for Roblox

A sophisticated, feature-rich code editor built entirely within Roblox, featuring a beautiful dark Dracula theme, smart intellisense that adapts to your game environment, local file persistence, and code execution capabilities.

## ✨ Features

### 🎨 Beautiful Dracula Theme
- Carefully crafted dark color scheme based on the popular Dracula theme
- Syntax highlighting for Lua code
- Smooth animations and transitions
- Professional UI with proper spacing and typography

### 🧠 Smart Intellisense
The standout feature of Dracula Editor - context-aware code completion:

#### Standard Completions
- All Lua keywords (`if`, `for`, `while`, `function`, etc.)
- Built-in functions (`print`, `warn`, `pairs`, `ipairs`, etc.)
- String, Table, Math, OS, and Task library methods
- Roblox globals (`game`, `workspace`, etc.)

#### Environment-Aware Completions
```lua
-- Type: game.
-- Shows: Players, Lighting, ReplicatedStorage, etc.

-- Type: workspace.
-- Shows: All actual children in your workspace!
```

#### Revolutionary GetChildren() Completion
```lua
-- Traditional editors show nothing after GetChildren()
-- Dracula Editor shows all children with their indices!

-- Type: game.Workspace:GetChildren()
-- Shows dropdown with:
--   Part [0] (Class: Part)
--   Part1 [1] (Class: Part)  
--   PistolGun [2] (Class: Model)
--   ...

-- Clicking "Part1" inserts:
-- game.Workspace:GetChildren()[1]
```

### 📁 File Management
- Create, open, save, and delete files
- Folder organization
- Auto-save functionality
- Recent files tracking
- Persistent storage using DataStore

### ▶️ Code Execution
- Run Lua code directly in the editor
- Output capture (print, warn, error)
- Timeout protection
- Sandbox security for safe execution

### 🎮 Developer Tools
- Output panel with timestamped logs
- Console for interactive commands
- Line numbers
- Multiple file tabs
- Find and Replace (coming soon)

## 📦 Installation

### Option 1: Direct Import
1. Download the `DraculaEditor` folder
2. Place it in `ReplicatedStorage` or `StarterPlayerScripts`
3. Create a LocalScript to initialize:

```lua
local DraculaEditor = require(game.ReplicatedStorage.DraculaEditor)
DraculaEditor.Initialize()
DraculaEditor.Show()
```

### Option 2: Quick Start
1. Place `ExampleScript.lua` in `StarterPlayerScripts`
2. The editor will auto-load when you play

## 🎹 Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| F8 | Toggle Editor Visibility |
| F5 | Run Current Code |
| Ctrl+S | Save File |
| Ctrl+N | New File |
| Ctrl+F | Find/Replace |
| Escape | Close Intellisense |
| Tab/Enter | Accept Suggestion |

## 📖 API Reference

### Initialization
```lua
local DraculaEditor = require(path.to.DraculaEditor)

-- Initialize with parent (optional, defaults to PlayerGui)
DraculaEditor.Initialize(parent)

-- Show the editor
DraculaEditor.Show()

-- Hide the editor
DraculaEditor.Hide()

-- Toggle visibility
DraculaEditor.Toggle()
```

### File Operations
```lua
-- Create a new file
DraculaEditor.CreateNewFile(name, content)

-- Open an existing file
DraculaEditor.OpenFile(fileName)

-- Save current file
DraculaEditor.SaveCurrentFile()

-- Delete a file
DraculaEditor.DeleteFile(fileName)
```

### Code Execution
```lua
-- Run the current code
DraculaEditor.RunCode()

-- Log to output
DraculaEditor.LogOutput(message, messageType)
-- messageType: "Info", "Success", "Warning", "Error"
```

### Utility Functions
```lua
-- Refresh file list sidebar
DraculaEditor.RefreshFileList()

-- Update line numbers
DraculaEditor.UpdateLineNumbers()

-- Get current state
local activeFile = DraculaEditor.State.ActiveFile
local openFiles = DraculaEditor.State.OpenFiles
```

## 🔧 Module Structure

```
DraculaEditor/
├── init.lua              -- Main loader
├── DraculaEditor.lua     -- Main controller
├── DraculaTheme.lua      -- Color scheme & UI constants
├── FileSystem.lua        -- File management & DataStore
├── Intellisense.lua      -- Smart code completion
├── EditorGUI.lua         -- GUI components
├── CodeRunner.lua        -- Code execution engine
├── SyntaxHighlighter.lua -- Syntax highlighting
├── ExampleScript.lua     -- Usage example
└── README.md             -- Documentation
```

## 🎯 Intellisense Deep Dive

### How It Works

1. **Context Parsing**: Analyzes the code before the cursor to determine what kind of completion is needed
2. **Expression Evaluation**: For `game.` or `workspace.`, evaluates the actual game instance
3. **Live Scanning**: Scans the actual game hierarchy for children
4. **Smart Caching**: Caches results with 5-second TTL for performance

### Completion Types

```lua
-- Type: game.Workspace.     -> Shows children of Workspace
-- Type: game.Players.        -> Shows children of Players service
-- Type: part:                -> Shows Instance methods
-- Type: part.                -> Shows properties and children
-- Type: string.              -> Shows string library functions
-- Type: math.                -> Shows math functions and constants
-- Type: local myVar = ...    -> myVar appears in completions
```

### GetChildren() Magic

When you type `:GetChildren()`, the editor:
1. Identifies the expression before the colon
2. Evaluates it to get the actual instance
3. Calls GetChildren() on that instance
4. Displays results with names, classes, and indices
5. Inserts the correct index on selection

```lua
-- If workspace contains: Part[0], Model1[1], Script2[2]
-- game.Workspace:GetChildren() shows:
--   Part (Index: 0, Class: Part)
--   Model1 (Index: 1, Class: Model)
--   Script2 (Index: 2, Class: Script)
```

## 🛡️ Security

The code runner includes sandbox protection:
- Restricted access to dangerous APIs
- Timeout protection (default 10 seconds)
- Error capture and display
- Safe environment for code execution

## 🔮 Coming Soon

- [ ] Find and Replace functionality
- [ ] Code folding
- [ ] Multiple selection
- [ ] Git integration (for team projects)
- [ ] Custom themes
- [ ] Plugin system
- [ ] Debugger integration

## 📝 License

MIT License - Feel free to use and modify for your Roblox projects!

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests

---

Made with 🦇 by the Dracula Editor Team
