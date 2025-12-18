--- LEVI Core Initialization Module
-- This module handles system initialization and coordinates all other modules
-- @module core.init

local init = {}

-- Module version
init.VERSION = "0.1.0"
init.NAME = "LEVI"
init.FULL_NAME = "Lua Enhanced Virtual Intelligence"

-- Module paths
local BASE_PATH = getMudletHomeDir() .. "/LEVI-Achaea/"

-- Module state
local initialized = false
local modules = {}

--- Print a message with LEVI prefix
-- @param message The message to print
local function log(message)
  cecho(string.format("\n<cyan>[%s]<reset> %s", init.NAME, message))
end

--- Load a module by name
-- @param module_name The name of the module to load
-- @return The loaded module or nil on error
local function load_module(module_name)
  local success, module = pcall(require, module_name)
  if success then
    log(string.format("Loaded module: %s", module_name))
    return module
  else
    log(string.format("<red>Failed to load module: %s<reset>", module_name))
    log(string.format("<red>Error: %s<reset>", tostring(module)))
    return nil
  end
end

--- Initialize the LEVI system
-- @return true if initialization successful, false otherwise
function init.initialize()
  if initialized then
    log("<yellow>System already initialized<reset>")
    return true
  end
  
  log(string.format("Initializing %s v%s...", init.FULL_NAME, init.VERSION))
  
  -- Load core modules
  modules.events = load_module("core.events")
  modules.utils = load_module("core.utils")
  modules.state = load_module("core.state")
  
  -- Load tracking modules
  modules.afflictions = load_module("tracking.afflictions")
  modules.balances = load_module("tracking.balances")
  
  -- Load curing modules
  modules.priorities = load_module("curing.priorities")
  modules.logic = load_module("curing.logic")
  
  -- Load offense modules
  modules.abilities = load_module("offense.abilities")
  modules.queuing = load_module("offense.queuing")
  
  -- Load UI modules
  modules.display = load_module("ui.display")
  
  -- Load configuration
  modules.config = load_module("config.loader")
  
  -- Initialize all loaded modules
  for name, module in pairs(modules) do
    if module and module.init then
      local success, err = pcall(module.init)
      if not success then
        log(string.format("<red>Failed to initialize %s: %s<reset>", name, tostring(err)))
      end
    end
  end
  
  initialized = true
  log("<green>System initialized successfully!<reset>")
  
  -- Raise initialization event
  if modules.events and modules.events.raise then
    modules.events.raise("system_initialized")
  end
  
  return true
end

--- Shutdown the LEVI system
function init.shutdown()
  if not initialized then
    return
  end
  
  log("Shutting down system...")
  
  -- Cleanup all modules
  for name, module in pairs(modules) do
    if module and module.cleanup then
      pcall(module.cleanup)
    end
  end
  
  initialized = false
  log("System shutdown complete")
end

--- Reset the system to initial state
function init.reset()
  log("Resetting system...")
  
  -- Reset all modules
  for name, module in pairs(modules) do
    if module and module.reset then
      pcall(module.reset)
    end
  end
  
  log("System reset complete")
end

--- Get system status
-- @return Table with system status information
function init.get_status()
  return {
    initialized = initialized,
    version = init.VERSION,
    modules_loaded = table.size(modules),
    modules = modules
  }
end

--- Check if system is initialized
-- @return true if initialized, false otherwise
function init.is_initialized()
  return initialized
end

--- Get a loaded module by name
-- @param module_name The name of the module
-- @return The module or nil if not loaded
function init.get_module(module_name)
  return modules[module_name]
end

return init
