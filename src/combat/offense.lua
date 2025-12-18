-- Offense module
-- Combat targeting and attack management

ataxia.combat = ataxia.combat or {}

-- Current target
ataxia.combat.target = nil
ataxia.combat.targetHP = nil

-- Set the current combat target
function ataxia.setTarget(name)
	if name and name ~= "" then
		ataxia.combat.target = name:lower()
		cecho("\n<yellow>Target set: <white>" .. name)
		ataxia.events.raise("target set", ataxia.combat.target)
	end
end

-- Clear the current target
function ataxia.clearTarget()
	local oldTarget = ataxia.combat.target
	ataxia.combat.target = nil
	ataxia.combat.targetHP = nil
	if oldTarget then
		cecho("\n<yellow>Target cleared")
		ataxia.events.raise("target cleared", oldTarget)
	end
end

-- Get current target
function ataxia.getTarget()
	return ataxia.combat.target
end

-- Check if we have a target
function ataxia.hasTarget()
	return ataxia.combat.target ~= nil
end

-- Queue a command with target substitution
-- Usage: ataxia.queueAttack("kill $tar")
function ataxia.queueAttack(cmd)
	if not ataxia.combat.target then
		cecho("\n<red>No target set!")
		return false
	end

	local expanded = cmd:gsub("%$tar", ataxia.combat.target)
	send("queue add eqbal " .. expanded)
	return true
end

-- Simple attack (no queue)
function ataxia.attack(cmd)
	if not ataxia.combat.target then
		cecho("\n<red>No target set!")
		return false
	end

	local expanded = cmd:gsub("%$tar", ataxia.combat.target)
	send(expanded)
	return true
end

-- Alias: tar <name>
-- Create this alias in Mudlet: ^tar (.+)$
-- Code: ataxia.setTarget(matches[2])
