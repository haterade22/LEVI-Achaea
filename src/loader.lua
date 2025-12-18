-- Auto-generated loader for LEVI Achaea scripts
-- This file loads all Lua scripts in the correct order

local base_path = "C:/Users/mikew/source/repos/Achaea/LEVI-Achaea/src/"

-- Helper function to load a directory of scripts
local function load_directory(dir_name)
    local dir_path = base_path .. dir_name
    print(string.format("Loading %s scripts...", dir_name))

    -- Get all lua files in directory
    local files = {}
    for _, filename in ipairs(lfs.dir(dir_path) or {}) do
        if filename:match("%.lua$") and filename ~= "init.lua" then
            table.insert(files, filename)
        end
    end

    -- Sort files to ensure consistent load order
    table.sort(files)

    -- Load each file
    for _, filename in ipairs(files) do
        local file_path = dir_path .. "/" .. filename
        local success, err = pcall(dofile, file_path)
        if not success then
            print(string.format("Error loading %s: %s", filename, err))
        end
    end
end

-- Load directories in order
load_directory("mmp")
load_directory("ataxia")
load_directory("ataxiagui")
load_directory("ataxiaNDB")
load_directory("ataxiaBasher")

print("LEVI Achaea scripts loaded successfully!")
