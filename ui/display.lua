--- LEVI UI Display
-- Main UI display management
-- @module ui.display

local display = {}

local enabled = true
local windows = {}

--- Create a simple text display
-- @param name Display name
-- @param x X position
-- @param y Y position
-- @param width Width
-- @param height Height
function display.create_window(name, x, y, width, height)
  windows[name] = {
    x = x,
    y = y,
    width = width,
    height = height,
    visible = true
  }
  
  -- TODO: Implement actual window creation using Mudlet's GUI API
  -- This would use createLabel, createGauge, etc.
end

--- Update a display window with content
-- @param name Display name
-- @param content Content to display
function display.update_window(name, content)
  if not windows[name] or not windows[name].visible then
    return
  end
  
  -- TODO: Implement actual window update
end

--- Show a window
-- @param name Display name
function display.show_window(name)
  if windows[name] then
    windows[name].visible = true
  end
end

--- Hide a window
-- @param name Display name
function display.hide_window(name)
  if windows[name] then
    windows[name].visible = false
  end
end

--- Update affliction display
function display.update_afflictions()
  local afflictions = require("tracking.afflictions")
  local player_affs = afflictions.get_player()
  
  local content = "=== Afflictions ===\n"
  local count = 0
  
  for aff_name, aff_data in pairs(player_affs) do
    content = content .. string.format("- %s\n", aff_name)
    count = count + 1
  end
  
  if count == 0 then
    content = content .. "None\n"
  end
  
  display.update_window("afflictions", content)
end

--- Update balance display
function display.update_balances()
  local balances = require("tracking.balances")
  local bal_state = balances.get_all()
  
  local content = "=== Balances ===\n"
  content = content .. string.format("Balance: %s\n", bal_state.balance and "YES" or "NO")
  content = content .. string.format("Equilibrium: %s\n", bal_state.equilibrium and "YES" or "NO")
  
  display.update_window("balances", content)
end

--- Update target display
function display.update_target()
  local state = require("core.state")
  local target = state.get_target()
  
  local content = "=== Target ===\n"
  if target then
    content = content .. string.format("Current: %s\n", target)
    
    -- Show target afflictions if available
    local afflictions = require("tracking.afflictions")
    local target_affs = afflictions.get_enemy(target)
    
    content = content .. "Afflictions:\n"
    local count = 0
    for aff_name, _ in pairs(target_affs) do
      content = content .. string.format("  - %s\n", aff_name)
      count = count + 1
    end
    
    if count == 0 then
      content = content .. "  None\n"
    end
  else
    content = content .. "None\n"
  end
  
  display.update_window("target", content)
end

--- Refresh all displays
function display.refresh_all()
  if not enabled then
    return
  end
  
  display.update_afflictions()
  display.update_balances()
  display.update_target()
end

--- Enable or disable UI
-- @param state Boolean
function display.set_enabled(state)
  enabled = state
  
  if enabled then
    display.refresh_all()
  end
end

--- Initialize the display module
function display.init()
  -- Create default windows
  display.create_window("afflictions", 0, 300, 300, 200)
  display.create_window("balances", 0, 500, 300, 100)
  display.create_window("target", 400, 0, 300, 200)
  
  -- Register for update events
  local events = require("core.events")
  events.register("affliction_gained", function()
    display.update_afflictions()
  end)
  events.register("affliction_cured", function()
    display.update_afflictions()
  end)
  events.register("balance_gained", function()
    display.update_balances()
  end)
  events.register("balance_lost", function()
    display.update_balances()
  end)
  events.register("target_changed", function()
    display.update_target()
  end)
  
  -- Initial refresh
  display.refresh_all()
end

--- Cleanup the display module
function display.cleanup()
  -- TODO: Destroy all windows
  windows = {}
end

return display
