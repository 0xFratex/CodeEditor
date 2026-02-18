# 🦇 Dracula Code Editor for Roblox

A sophisticated, feature-rich code editor built entirely within Roblox, featuring a beautiful dark Dracula theme, smart intellisense that adapts to your game environment, local file persistence, and code execution capabilities.

**All modules are loaded via `loadstring(game:HttpGet())` from GitHub raw URLs - no local file installation needed!**

## 🚀 Quick Start

### Method 1: Full Editor (Recommended)
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/0xFratex/CodeEditor/main/Loader.lua"))()
```

### Method 2: QuickStart (Single File)
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/0xFratex/CodeEditor/main/QuickStart.lua"))()
```

**One-line setup:** Just paste into a LocalScript in `StarterPlayerScripts` and press **F8** to toggle!

## ✨ Features

### 🎨 Beautiful Dracula Theme
- Carefully crafted dark color scheme
- Syntax highlighting for Lua code
- Smooth animations and transitions
- Professional UI with proper spacing

### 🧠 Smart Intellisense

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
-- Type: game.Workspace:GetChildren()
-- Shows dropdown with actual children:
--   Part [0] (Class: Part)
--   Part1 [1] (Class: Part)  
--   PistolGun [2] (Class: Model)

-- Clicking "Part1" inserts:
-- game.Workspace:GetChildren()[1]
```

### 📁 File Management
- Create, open, save, and delete files
- Folder organization
- Auto-save functionality
- Persistent storage using DataStore

### ▶️ Code Execution
- Run Lua code directly in the editor
- Output capture (print, warn, error)
- Timeout protection
- Sandbox security

## 🎹 Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| F8 | Toggle Editor |
| F5 | Run Code |
| Ctrl+S | Save File |
| Ctrl+N | New File |
| Tab/Enter | Accept Suggestion |
| Escape | Close Intellisense |

## 📦 How It Works

The editor loads all modules dynamically from GitHub using:

```lua
local function loadFromGitHub(moduleName)
    local url = "https://raw.githubusercontent.com/0xFratex/CodeEditor/main/" .. moduleName
    local source = game:HttpGet(url)
    local fn = loadstring(source)
    return fn()
end
```

Modules are cached and shared via `_G` for cross-module communication:
- `_G.DraculaTheme` - Theme colors and settings
- `_G.FileSystem` - File management
- `_G.Intellisense` - Code completion
- `_G.EditorGUI` - GUI components
- `_G.CodeRunner` - Code execution
- `_G.SyntaxHighlighter` - Syntax highlighting
- `_G.EditorUtilities` - Helper functions

## 📖 Module Structure

```
CodeEditor/
├── Loader.lua            -- Main loader (loadstring entry point)
├── QuickStart.lua        -- Single-file standalone version
├── DraculaEditor.lua     -- Main controller
├── DraculaTheme.lua      -- Color scheme
├── FileSystem.lua        -- File management
├── Intellisense.lua      -- Smart completion
├── EditorGUI.lua         -- GUI components
├── CodeRunner.lua        -- Code execution
├── SyntaxHighlighter.lua -- Syntax highlighting
├── EditorUtilities.lua   -- Helper utilities
└── README.md             -- Documentation
```

## 🔗 Raw URLs

Use these URLs with `loadstring(game:HttpGet())`:

| Module | URL |
|--------|-----|
| Loader | `https://raw.githubusercontent.com/0xFratex/CodeEditor/main/Loader.lua` |
| QuickStart | `https://raw.githubusercontent.com/0xFratex/CodeEditor/main/QuickStart.lua` |

## 🔮 Coming Soon

- [ ] Find and Replace
- [ ] Code folding
- [ ] Multiple selection
- [ ] Custom themes
- [ ] Plugin system

## 📝 License

MIT License - Feel free to use and modify!

---

**Repository:** https://github.com/0xFratex/CodeEditor

Made with 🦇 by the Dracula Editor Team
