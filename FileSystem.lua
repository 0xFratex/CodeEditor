--[[
	Dracula File System
	Handles file creation, saving, loading, and organization using DataStore
]]

local FileSystem = {}

-- Services
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- Configuration
FileSystem.Config = {
	DataStoreName = "DraculaEditorFiles",
	MaxFileSize = 100000,        -- Max characters per file
	MaxFilesPerFolder = 100,
	MaxFolders = 50,
	AutoSaveInterval = 30,       -- Auto-save every 30 seconds
	MaxRecentFiles = 10,
}

-- File system structure
FileSystem.RootFolder = "DraculaProjects"
FileSystem.CurrentProject = "DefaultProject"

-- File class
local File = {}
File.__index = File

function File.new(name, content, folder)
	local self = setmetatable({}, File)
	self.Name = name or "Untitled"
	self.Content = content or ""
	self.Folder = folder or "Root"
	self.CreatedAt = os.time()
	self.ModifiedAt = os.time()
	self.IsModified = false
	self.LineCount = 0
	self.Language = "Lua"
	return self
end

function File:UpdateContent(content)
	self.Content = content
	self.ModifiedAt = os.time()
	self.IsModified = true
	self.LineCount = select(2, string.gsub(content, "\n", ""))
end

function File:GetExtension()
	return string.match(self.Name, "%.(%w+)$") or "lua"
end

function File:Clone()
	local newFile = File.new(self.Name, self.Content, self.Folder)
	newFile.CreatedAt = self.CreatedAt
	newFile.ModifiedAt = self.ModifiedAt
	return newFile
end

FileSystem.File = File

-- Folder class
local Folder = {}
Folder.__index = Folder

function Folder.new(name, parent)
	local self = setmetatable({}, Folder)
	self.Name = name or "NewFolder"
	self.Parent = parent or nil
	self.Files = {}
	self.SubFolders = {}
	self.CreatedAt = os.time()
	return self
end

function Folder:AddFile(file)
	file.Folder = self.Name
	table.insert(self.Files, file)
	return file
end

function Folder:RemoveFile(fileName)
	for i, file in ipairs(self.Files) do
		if file.Name == fileName then
			table.remove(self.Files, i)
			return true
		end
	end
	return false
end

function Folder:GetFile(fileName)
	for _, file in ipairs(self.Files) do
		if file.Name == fileName then
			return file
		end
	end
	return nil
end

function Folder:AddSubFolder(folder)
	folder.Parent = self
	table.insert(self.SubFolders, folder)
	return folder
end

function Folder:RemoveSubFolder(folderName)
	for i, folder in ipairs(self.SubFolders) do
		if folder.Name == folderName then
			table.remove(self.SubFolders, i)
			return true
		end
	end
	return false
end

function Folder:GetSubFolder(folderName)
	for _, folder in ipairs(self.SubFolders) do
		if folder.Name == folderName then
			return folder
		end
	end
	return nil
end

function Folder:GetAllFiles()
	local allFiles = {}
	
	for _, file in ipairs(self.Files) do
		table.insert(allFiles, file)
	end
	
	for _, subFolder in ipairs(self.SubFolders) do
		local subFiles = subFolder:GetAllFiles()
		for _, file in ipairs(subFiles) do
			table.insert(allFiles, file)
		end
	end
	
	return allFiles
end

FileSystem.Folder = Folder

-- DataStore operations
local DataStore = nil

local function getDataStore()
	if not DataStore then
		local success, result = pcall(function()
			return DataStoreService:GetDataStore(FileSystem.Config.DataStoreName)
		end)
		if success then
			DataStore = result
		end
	end
	return DataStore
end

-- Check if we're in Studio or running game
local function canUseDataStore()
	return RunService:IsStudio() or RunService:IsRunning()
end

-- In-memory file storage (fallback when DataStore isn't available)
local MemoryStorage = {
	Projects = {},
	Settings = {},
	RecentFiles = {},
}

-- Initialize memory storage with default project
MemoryStorage.Projects["DefaultProject"] = Folder.new("DefaultProject")

-- Save project to storage
function FileSystem.SaveProject(projectName, folder)
	projectName = projectName or FileSystem.CurrentProject
	
	local data = {
		Name = folder.Name,
		Files = {},
		SubFolders = {},
		CreatedAt = folder.CreatedAt,
	}
	
	-- Serialize files
	for _, file in ipairs(folder.Files) do
		table.insert(data.Files, {
			Name = file.Name,
			Content = file.Content,
			Folder = file.Folder,
			CreatedAt = file.CreatedAt,
			ModifiedAt = file.ModifiedAt,
		})
	end
	
	-- Serialize subfolders recursively
	local function serializeFolder(subFolder)
		local serialized = {
			Name = subFolder.Name,
			Files = {},
			SubFolders = {},
		}
		for _, file in ipairs(subFolder.Files) do
			table.insert(serialized.Files, {
				Name = file.Name,
				Content = file.Content,
				Folder = file.Folder,
				CreatedAt = file.CreatedAt,
				ModifiedAt = file.ModifiedAt,
			})
		end
		for _, sf in ipairs(subFolder.SubFolders) do
			table.insert(serialized.SubFolders, serializeFolder(sf))
		end
		return serialized
	end
	
	for _, subFolder in ipairs(folder.SubFolders) do
		table.insert(data.SubFolders, serializeFolder(subFolder))
	end
	
	-- Save to memory storage
	MemoryStorage.Projects[projectName] = data
	
	-- Try to save to DataStore
	if canUseDataStore() then
		local ds = getDataStore()
		if ds then
			local success, err = pcall(function()
				ds:SetAsync("project_" .. projectName, data)
			end)
			if not success then
				warn("Failed to save project to DataStore:", err)
			end
		end
	end
	
	return true
end

-- Load project from storage
function FileSystem.LoadProject(projectName)
	projectName = projectName or FileSystem.CurrentProject
	
	-- Try DataStore first
	if canUseDataStore() then
		local ds = getDataStore()
		if ds then
			local success, data = pcall(function()
				return ds:GetAsync("project_" .. projectName)
			end)
			if success and data then
				return FileSystem.DeserializeProject(data)
			end
		end
	end
	
	-- Fall back to memory storage
	local data = MemoryStorage.Projects[projectName]
	if data then
		if getmetatable(data) == Folder then
			return data
		end
		return FileSystem.DeserializeProject(data)
	end
	
	-- Create new project if not found
	local newProject = Folder.new(projectName)
	MemoryStorage.Projects[projectName] = newProject
	return newProject
end

-- Deserialize project data
function FileSystem.DeserializeProject(data)
	local folder = Folder.new(data.Name)
	folder.CreatedAt = data.CreatedAt or os.time()
	
	-- Deserialize files
	for _, fileData in ipairs(data.Files or {}) do
		local file = File.new(fileData.Name, fileData.Content, fileData.Folder)
		file.CreatedAt = fileData.CreatedAt or os.time()
		file.ModifiedAt = fileData.ModifiedAt or os.time()
		table.insert(folder.Files, file)
	end
	
	-- Deserialize subfolders recursively
	local function deserializeSubFolder(folderData, parentFolder)
		local subFolder = Folder.new(folderData.Name)
		subFolder.Parent = parentFolder
		
		for _, fileData in ipairs(folderData.Files or {}) do
			local file = File.new(fileData.Name, fileData.Content, fileData.Folder)
			file.CreatedAt = fileData.CreatedAt or os.time()
			file.ModifiedAt = fileData.ModifiedAt or os.time()
			table.insert(subFolder.Files, file)
		end
		
		for _, sfData in ipairs(folderData.SubFolders or {}) do
			deserializeSubFolder(sfData, subFolder)
		end
		
		return subFolder
	end
	
	for _, subFolderData in ipairs(data.SubFolders or {}) do
		local subFolder = deserializeSubFolder(subFolderData, folder)
		table.insert(folder.SubFolders, subFolder)
	end
	
	return folder
end

-- Create new file
function FileSystem.CreateFile(name, content, projectName)
	projectName = projectName or FileSystem.CurrentProject
	local project = FileSystem.LoadProject(projectName)
	
	if not project then
		project = Folder.new(projectName)
		MemoryStorage.Projects[projectName] = project
	end
	
	local file = File.new(name, content)
	table.insert(project.Files, file)
	
	FileSystem.SaveProject(projectName, project)
	
	return file
end

-- Get file from project
function FileSystem.GetFile(fileName, projectName)
	projectName = projectName or FileSystem.CurrentProject
	local project = FileSystem.LoadProject(projectName)
	
	if not project then return nil end
	
	-- Search in root files
	for _, file in ipairs(project.Files) do
		if file.Name == fileName then
			return file
		end
	end
	
	-- Search in subfolders
	for _, subFolder in ipairs(project.SubFolders) do
		local allFiles = subFolder:GetAllFiles()
		for _, file in ipairs(allFiles) do
			if file.Name == fileName then
				return file
			end
		end
	end
	
	return nil
end

-- Save file
function FileSystem.SaveFile(file, projectName)
	projectName = projectName or FileSystem.CurrentProject
	local project = FileSystem.LoadProject(projectName)
	
	if not project then return false end
	
	-- Find and update file
	for i, existingFile in ipairs(project.Files) do
		if existingFile.Name == file.Name then
			project.Files[i] = file
			file.IsModified = false
			FileSystem.SaveProject(projectName, project)
			return true
		end
	end
	
	-- If not found, add it
	table.insert(project.Files, file)
	file.IsModified = false
	FileSystem.SaveProject(projectName, project)
	return true
end

-- Delete file
function FileSystem.DeleteFile(fileName, projectName)
	projectName = projectName or FileSystem.CurrentProject
	local project = FileSystem.LoadProject(projectName)
	
	if not project then return false end
	
	-- Remove from root files
	if project:RemoveFile(fileName) then
		FileSystem.SaveProject(projectName, project)
		return true
	end
	
	-- Try to remove from subfolders
	for _, subFolder in ipairs(project.SubFolders) do
		if subFolder:RemoveFile(fileName) then
			FileSystem.SaveProject(projectName, project)
			return true
		end
	end
	
	return false
end

-- Rename file
function FileSystem.RenameFile(oldName, newName, projectName)
	projectName = projectName or FileSystem.CurrentProject
	local file = FileSystem.GetFile(oldName, projectName)
	
	if not file then return false end
	
	file.Name = newName
	file.ModifiedAt = os.time()
	file.IsModified = true
	
	FileSystem.SaveFile(file, projectName)
	return true
end

-- Create folder
function FileSystem.CreateFolder(folderName, parentPath, projectName)
	projectName = projectName or FileSystem.CurrentProject
	local project = FileSystem.LoadProject(projectName)
	
	if not project then return nil end
	
	local newFolder = Folder.new(folderName)
	
	if parentPath and parentPath ~= "" then
		-- Find parent folder
		local parent = project
		for part in string.gmatch(parentPath, "[^/]+") do
			parent = parent:GetSubFolder(part)
			if not parent then return nil end
		end
		parent:AddSubFolder(newFolder)
	else
		project:AddSubFolder(newFolder)
	end
	
	FileSystem.SaveProject(projectName, project)
	return newFolder
end

-- Delete folder
function FileSystem.DeleteFolder(folderName, projectName)
	projectName = projectName or FileSystem.CurrentProject
	local project = FileSystem.LoadProject(projectName)
	
	if not project then return false end
	
	if project:RemoveSubFolder(folderName) then
		FileSystem.SaveProject(projectName, project)
		return true
	end
	
	return false
end

-- List all projects
function FileSystem.ListProjects()
	local projects = {}
	
	-- Get from memory storage
	for name, _ in pairs(MemoryStorage.Projects) do
		table.insert(projects, name)
	end
	
	return projects
end

-- List files in project
function FileSystem.ListFiles(projectName)
	projectName = projectName or FileSystem.CurrentProject
	local project = FileSystem.LoadProject(projectName)
	
	if not project then return {} end
	
	return project.Files
end

-- Get recent files
function FileSystem.GetRecentFiles()
	return MemoryStorage.RecentFiles or {}
end

-- Add to recent files
function FileSystem.AddRecentFile(file)
	table.insert(MemoryStorage.RecentFiles, 1, {
		Name = file.Name,
		Path = file.Folder,
		ModifiedAt = file.ModifiedAt,
	})
	
	-- Keep only last N files
	while #MemoryStorage.RecentFiles > FileSystem.Config.MaxRecentFiles do
		table.remove(MemoryStorage.RecentFiles)
	end
end

-- Export project as string (for sharing)
function FileSystem.ExportProject(projectName)
	projectName = projectName or FileSystem.CurrentProject
	local project = FileSystem.LoadProject(projectName)
	
	if not project then return nil end
	
	local exported = "-- Dracula Editor Project Export\n"
	exported = exported .. "-- Project: " .. projectName .. "\n"
	exported = exported .. "-- Exported: " .. os.date() .. "\n\n"
	
	for _, file in ipairs(project.Files) do
		exported = exported .. "--[[ FILE: " .. file.Name .. " ]]\n"
		exported = exported .. file.Content .. "\n\n"
	end
	
	return exported
end

-- Settings management
function FileSystem.GetSetting(key, default)
	if MemoryStorage.Settings[key] ~= nil then
		return MemoryStorage.Settings[key]
	end
	return default
end

function FileSystem.SetSetting(key, value)
	MemoryStorage.Settings[key] = value
end

return FileSystem
