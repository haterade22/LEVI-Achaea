-- Balance tracking module
-- Tracks balance/equilibrium and other resource states

ataxia.balances = ataxia.balances or {}

-- Balance state
ataxia.balances.bal = true
ataxia.balances.eq = true
ataxia.balances.cd = false  -- class-specific balance
ataxia.balances.sip = true
ataxia.balances.herb = true
ataxia.balances.moss = true
ataxia.balances.salve = true
ataxia.balances.smoke = true
ataxia.balances.writhe = true
ataxia.balances.tree = true
ataxia.balances.focus = true
ataxia.balances.elixir = true

-- Check if we have full combat balance
function ataxia.hasBalance()
	return ataxia.balances.bal and ataxia.balances.eq
end

-- Check specific balance
function ataxia.hasBal(balType)
	if ataxia.balances[balType] ~= nil then
		return ataxia.balances[balType]
	end
	return true  -- Unknown balance type, assume available
end

-- Set a balance state
function ataxia.setBal(balType, state)
	local oldState = ataxia.balances[balType]
	ataxia.balances[balType] = state

	if oldState ~= state then
		if state then
			ataxia.events.raise("balance gained", balType)
		else
			ataxia.events.raise("balance lost", balType)
		end
	end
end

-- GMCP vitals handler
local function onVitals()
	local vitals = gmcp.Char.Vitals

	if vitals then
		-- Core balances
		ataxia.setBal("bal", vitals.bal == "1")
		ataxia.setBal("eq", vitals.eq == "1")

		-- Parse charstats for additional balances if present
		if vitals.charstats then
			for _, stat in ipairs(vitals.charstats) do
				-- Example: "Tree: 1" or "Focus: 0"
				local name, value = stat:match("(%w+): (%d+)")
				if name and value then
					local balName = name:lower()
					if ataxia.balances[balName] ~= nil then
						ataxia.setBal(balName, value == "1")
					end
				end
			end
		end
	end
end

-- Register GMCP handler
ataxia.events.register("gmcp.Char.Vitals", onVitals, "balances_vitals")
