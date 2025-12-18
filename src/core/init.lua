-- Core initialization
-- Sets up namespaces and shared utilities

-- Initialize namespaces (preserve existing data if reloading)
ataxia = ataxia or {}
ataxiagui = ataxiagui or {}
ataxiaNDB = ataxiaNDB or {}
ataxiaTemp = ataxiaTemp or {}
ataxiaTables = ataxiaTables or {}
ataxiaBasher = ataxiaBasher or {}

-- Version info
ataxia.version = "1.0.0"
ataxia.loaded = true

-- Utility: Safe table access
function ataxia.safeGet(tbl, ...)
	local value = tbl
	for _, key in ipairs({...}) do
		if type(value) ~= "table" then
			return nil
		end
		value = value[key]
	end
	return value
end

-- Utility: Get charstat by name (safer than index)
function ataxia.getCharstat(name)
	local charstats = ataxia.safeGet(gmcp, "Char", "Vitals", "charstats")
	if not charstats then return 0 end

	for _, stat in ipairs(charstats) do
		local value = stat:match(name .. ": (%d+)")
		if value then return tonumber(value) end
	end
	return 0
end

-- Utility: Deep copy a table
function ataxia.deepcopy(orig)
	local copy
	if type(orig) == "table" then
		copy = {}
		for k, v in next, orig, nil do
			copy[ataxia.deepcopy(k)] = ataxia.deepcopy(v)
		end
		setmetatable(copy, ataxia.deepcopy(getmetatable(orig)))
	else
		copy = orig
	end
	return copy
end

-- Utility: Check if table contains value
function ataxia.contains(tbl, val)
	for _, v in ipairs(tbl) do
		if v == val then return true end
	end
	return false
end

-- Utility: Count table entries
function ataxia.tableCount(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end
