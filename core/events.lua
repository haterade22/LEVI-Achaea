--- LEVI Event Management System
-- Provides a publish-subscribe event system for inter-module communication
-- @module core.events

local events = {}

-- Event registry
local event_handlers = {}
local event_history = {}
local max_history = 100

--- Register an event handler
-- @param event_name The name of the event to listen for
-- @param handler Function to call when event is raised
-- @param priority Optional priority (higher = called first), defaults to 0
-- @return handler_id for unregistering
function events.register(event_name, handler, priority)
  priority = priority or 0
  
  if not event_handlers[event_name] then
    event_handlers[event_name] = {}
  end
  
  local handler_id = #event_handlers[event_name] + 1
  table.insert(event_handlers[event_name], {
    id = handler_id,
    handler = handler,
    priority = priority
  })
  
  -- Sort by priority (highest first)
  table.sort(event_handlers[event_name], function(a, b)
    return a.priority > b.priority
  end)
  
  return handler_id
end

--- Unregister an event handler
-- @param event_name The name of the event
-- @param handler_id The ID returned from register
function events.unregister(event_name, handler_id)
  if not event_handlers[event_name] then
    return
  end
  
  for i, handler_info in ipairs(event_handlers[event_name]) do
    if handler_info.id == handler_id then
      table.remove(event_handlers[event_name], i)
      break
    end
  end
end

--- Raise an event
-- @param event_name The name of the event to raise
-- @param data Optional data to pass to handlers
function events.raise(event_name, data)
  -- Store in history
  table.insert(event_history, {
    name = event_name,
    data = data,
    timestamp = os.time()
  })
  
  -- Limit history size
  if #event_history > max_history then
    table.remove(event_history, 1)
  end
  
  -- Call all registered handlers
  if event_handlers[event_name] then
    for _, handler_info in ipairs(event_handlers[event_name]) do
      local success, err = pcall(handler_info.handler, data)
      if not success then
        print(string.format("Error in event handler for %s: %s", event_name, tostring(err)))
      end
    end
  end
end

--- Get event history
-- @param count Optional number of recent events to return
-- @return Array of recent events
function events.get_history(count)
  count = count or max_history
  local history = {}
  local start = math.max(1, #event_history - count + 1)
  
  for i = start, #event_history do
    table.insert(history, event_history[i])
  end
  
  return history
end

--- Clear event history
function events.clear_history()
  event_history = {}
end

--- Initialize the events module
function events.init()
  -- Nothing to initialize
end

--- Cleanup the events module
function events.cleanup()
  event_handlers = {}
  event_history = {}
end

--- Reset the events module
function events.reset()
  events.clear_history()
end

return events
