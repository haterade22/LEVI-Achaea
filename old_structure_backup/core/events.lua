-- Event handling utilities
-- Provides helpers for working with Mudlet's event system

ataxia.events = ataxia.events or {}

-- Store registered event handlers for cleanup
ataxia.events.handlers = ataxia.events.handlers or {}

-- Register an event handler with tracking for cleanup
function ataxia.events.register(event, callback, handlerName)
	handlerName = handlerName or (event .. "_" .. tostring(callback))

	-- Kill existing handler if re-registering
	if ataxia.events.handlers[handlerName] then
		killAnonymousEventHandler(ataxia.events.handlers[handlerName])
	end

	-- Register new handler
	local id = registerAnonymousEventHandler(event, callback)
	ataxia.events.handlers[handlerName] = id

	return id
end

-- Unregister a specific handler
function ataxia.events.unregister(handlerName)
	if ataxia.events.handlers[handlerName] then
		killAnonymousEventHandler(ataxia.events.handlers[handlerName])
		ataxia.events.handlers[handlerName] = nil
		return true
	end
	return false
end

-- Unregister all tracked handlers
function ataxia.events.unregisterAll()
	for name, id in pairs(ataxia.events.handlers) do
		killAnonymousEventHandler(id)
	end
	ataxia.events.handlers = {}
end

-- Raise an event with optional arguments
function ataxia.events.raise(event, ...)
	raiseEvent(event, ...)
end
