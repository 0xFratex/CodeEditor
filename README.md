# 🦇 Dracula Code Editor for Roblox

A sophisticated, feature-rich code editor built entirely within Roblox, featuring a beautiful dark Dracula theme, smart intellisense, syntax highlighting, error detection, and local file persistence.

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

**One-line setup:** Just paste into your executor and press **F8** to toggle!

## ✨ Features

### 🎨 Beautiful Dracula Theme
- Carefully crafted dark color scheme
- Real-time syntax highlighting with RichText
- Smooth animations and transitions
- Professional UI with proper spacing
- Visible cursor with blink animation

### 🧠 Smart Intellisense

#### Standard Completions
- All Lua keywords (`if`, `for`, `while`, `function`, etc.)
- Built-in functions (`print`, `warn`, `pairs`, `ipairs`, etc.)
- String, Table, Math, OS, and Task library methods
- Roblox globals (`game`, `workspace`, etc.)

#### Context-Aware Completions
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
```

#### Smart Comment Detection
- Intellisense won't trigger inside comments (`--`)
- Intellisense won't trigger inside strings

### 🎯 Syntax Highlighting
- Keywords (pink)
- Strings (yellow)
- Numbers (purple)
- Comments (gray)
- Built-in functions (cyan)
- Real-time highlighting as you type

### ⚠️ Error Detection
- Real-time syntax error detection
- Unclosed bracket detection
- Error line display
- Toggleable in settings

### 📁 File Management
- Create, open, save, and delete files
- Folder organization
- Auto-save functionality
- Persistent storage using executor file functions
- File browser sidebar

### ⚙️ Configuration
- Font size adjustment
- Auto-save toggle
- Error detection toggle
- Settings persist locally
- Uses `writefile`/`readfile` functions

### ▶️ Code Execution
- Run Lua code directly in the editor
- Output capture (print, warn, error)
- Timeout protection

## 🎹 Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| F8 | Toggle Editor |
| F5 | Run Code |
| Ctrl+S | Save File |
| Ctrl+O | Toggle File Browser |
| Tab/Enter | Accept Suggestion |
| ↑/↓ | Navigate Suggestions |
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

## 📁 File System Support

The editor uses built-in executor functions for file persistence:

| Function | Purpose |
|----------|---------|
| `writefile(path, content)` | Save file |
| `readfile(path)` | Load file |
| `listfiles(folder)` | List files in folder |
| `isfile(path)` | Check if file exists |
| `isfolder(path)` | Check if folder exists |
| `makefolder(path)` | Create folder |
| `delfile(path)` | Delete file |
| `delfolder(path)` | Delete folder |

**Folder Structure:**
```
DraculaEditor/
├── Config/
│   └── settings.json
└── Scripts/
    └── your_scripts.lua
```

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

## 🆕 Recent Updates

### v2.0.0
- ✅ Added visible cursor with blink animation
- ✅ Added configuration page with local saving
- ✅ Fixed intellisense not triggering in comments
- ✅ Fixed syntax highlighting for partial matches
- ✅ Added real-time error detection
- ✅ Added file browser with folder support
- ✅ Added script loading/saving functionality
- ✅ Improved UI layout and styling

## 🔮 Coming Soon

- [ ] Find and Replace
- [ ] Code folding
- [ ] Multiple selection
- [ ] Custom themes
- [ ] Plugin system
- [ ] Multi-file tabs

## 📝 License

MIT License - Feel free to use and modify!

---

**Repository:** https://github.com/0xFratex/CodeEditor

Made with 🦇 by the Dracula Editor Team
