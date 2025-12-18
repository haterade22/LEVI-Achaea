--- LEVI Configuration Loader
-- Loads and manages configuration
-- @module config.loader

local loader = {}

local current_config = nil

--- Get default configuration
-- @return Default config table
local function get_default_config()
  return {
    general = {
      enabled = true,
      debug = false,
      auto_start = true
    },
    curing = {
      enabled = true,
      priorities = {}
    },
    offense = {
      enabled = false,
      mode = "manual"
    },
    tracking = {
      track_self = true,
      track_enemy = true
    },
    ui = {
      enabled = true,
      theme = "dark"
    }
  }
end

--- Merge two configuration tables
-- @param base Base configuration
-- @param override Override configuration
-- @return Merged configuration
local function merge_config(base, override)
  local result = {}
  
  -- Copy base
  for k, v in pairs(base) do
    if type(v) == "table" then
      result[k] = merge_config(v, {})
    else
      result[k] = v
    end
  end
  
  -- Apply overrides
  for k, v in pairs(override) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = merge_config(result[k], v)
    else
      result[k] = v
    end
  end
  
  return result
end

--- Load user configuration
-- @return User config table or nil
local function load_user_config()
  local success, user_config = pcall(require, "config.user_config")
  if success then
    return user_config
  end
  return nil
end

--- Load example configuration
-- @return Example config table or nil
local function load_example_config()
  local success, example_config = pcall(require, "config.example")
  if success then
    return example_config
  end
  return nil
end

--- Load configuration
-- Priority: user_config.lua > example.lua > defaults
function loader.load()
  local config = get_default_config()
  
  -- Try to load example config
  local example = load_example_config()
  if example then
    config = merge_config(config, example)
  end
  
  -- Try to load user config (highest priority)
  local user = load_user_config()
  if user then
    config = merge_config(config, user)
  end
  
  current_config = config
  return config
end

--- Get current configuration
-- @return Current config table
function loader.get()
  if not current_config then
    loader.load()
  end
  return current_config
end

--- Get a specific config value
-- @param path Dot-separated path (e.g., "curing.enabled")
-- @return Value or nil
function loader.get_value(path)
  local config = loader.get()
  local parts = {}
  for part in string.gmatch(path, "[^%.]+") do
    table.insert(parts, part)
  end
  
  local value = config
  for _, part in ipairs(parts) do
    if type(value) ~= "table" then
      return nil
    end
    value = value[part]
  end
  
  return value
end

--- Set a config value
-- @param path Dot-separated path
-- @param value Value to set
function loader.set_value(path, value)
  local config = loader.get()
  local parts = {}
  for part in string.gmatch(path, "[^%.]+") do
    table.insert(parts, part)
  end
  
  local current = config
  for i = 1, #parts - 1 do
    local part = parts[i]
    if type(current[part]) ~= "table" then
      current[part] = {}
    end
    current = current[part]
  end
  
  current[parts[#parts]] = value
end

--- Reload configuration
function loader.reload()
  current_config = nil
  loader.load()
  
  local events = require("core.events")
  events.raise("config_reloaded", {})
end

--- Initialize the loader module
function loader.init()
  loader.load()
end

return loader
