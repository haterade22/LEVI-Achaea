--- LEVI Offense Queuing
-- Manages the queue of offensive actions
-- @module offense.queuing

local queuing = {}

-- Action queue
local action_queue = {}
local max_queue_size = 10
local auto_execute = false

--- Add an action to the queue
-- @param action Action table with ability and args
-- @param priority Optional priority (higher = executed first)
-- @return Boolean indicating if action was added
function queuing.add(action, priority)
  if #action_queue >= max_queue_size then
    return false
  end
  
  table.insert(action_queue, {
    ability = action.ability,
    args = action.args or {},
    priority = priority or 0,
    queued_at = os.time()
  })
  
  -- Sort by priority
  table.sort(action_queue, function(a, b)
    return a.priority > b.priority
  end)
  
  local events = require("core.events")
  events.raise("action_queued", action)
  
  -- Auto-execute if enabled
  if auto_execute then
    queuing.execute_next()
  end
  
  return true
end

--- Get the next action from the queue
-- @return Action table or nil
function queuing.get_next()
  if #action_queue > 0 then
    return action_queue[1]
  end
  return nil
end

--- Remove and return the next action
-- @return Action table or nil
function queuing.pop()
  if #action_queue > 0 then
    return table.remove(action_queue, 1)
  end
  return nil
end

--- Execute the next action in the queue
-- @return Boolean indicating if action was executed
function queuing.execute_next()
  local action = queuing.pop()
  if not action then
    return false
  end
  
  local abilities = require("offense.abilities")
  return abilities.execute(action.ability, action.args)
end

--- Clear the action queue
function queuing.clear()
  action_queue = {}
  
  local events = require("core.events")
  events.raise("queue_cleared", {})
end

--- Get the current queue
-- @return Copy of the action queue
function queuing.get_queue()
  local queue_copy = {}
  for _, action in ipairs(action_queue) do
    table.insert(queue_copy, action)
  end
  return queue_copy
end

--- Get queue size
-- @return Number of actions in queue
function queuing.size()
  return #action_queue
end

--- Set maximum queue size
-- @param size Maximum size
function queuing.set_max_size(size)
  max_queue_size = size
end

--- Enable or disable auto-execution
-- @param enabled Boolean
function queuing.set_auto_execute(enabled)
  auto_execute = enabled
end

--- Initialize the queuing module
function queuing.init()
  action_queue = {}
  
  -- Register for balance events to auto-execute
  local events = require("core.events")
  events.register("balance_gained", function(data)
    if auto_execute and data.type == "balance" then
      queuing.execute_next()
    end
  end, 5)
  
  -- Load config
  local config = require("config.loader")
  if config and config.get then
    local cfg = config.get()
    if cfg.offense and cfg.offense.queue then
      max_queue_size = cfg.offense.queue.max_size or max_queue_size
      auto_execute = cfg.offense.queue.auto_execute or auto_execute
    end
  end
end

--- Reset the queuing module
function queuing.reset()
  queuing.clear()
end

return queuing
