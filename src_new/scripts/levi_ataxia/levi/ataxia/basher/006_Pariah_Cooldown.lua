--[[mudlet
type: script
name: Pariah Cooldown
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[mudlet
type: script
name: Pariah Cooldowns
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- Pariah Swarm Devour Flushings PVE Trigger
-- Tracks the 40-second cooldown for swarm devour attack in PVE bashing
-- Cooldown resets immediately if the attack kills the target

-- Initialize the cooldown variable if not already set
if ataxiaBasher and ataxiaBasher.swarmDevourReady == nil then
	ataxiaBasher.swarmDevourReady = true
end

-- Timer ID storage for cancellation on kill reset
ataxiaBasher.swarmDevourTimerId = nil

-- Function to handle swarm devour cooldown (40 seconds)
function ataxiaBasher_swarmDevourCooldown()
	ataxiaBasher.swarmDevourReady = false

	-- Cancel any existing timer
	if ataxiaBasher.swarmDevourTimerId then
		killTimer(ataxiaBasher.swarmDevourTimerId)
	end

	-- Start 40 second cooldown timer
	ataxiaBasher.swarmDevourTimerId = tempTimer(40, [[ataxiaBasher_swarmDevourReady()]])
end

-- Function to handle swarm devour cooldown reset (kill or timer expiry)
function ataxiaBasher_swarmDevourReady()
	ataxiaBasher.swarmDevourReady = true

	-- Cancel any pending timer since we're ready now
	if ataxiaBasher.swarmDevourTimerId then
		killTimer(ataxiaBasher.swarmDevourTimerId)
		ataxiaBasher.swarmDevourTimerId = nil
	end
end

-- Triggers for swarm devour are now permanent triggers (370-373)
-- Orphaned permRegexTrigger cleanup is handled in 005_Falcon_Cooldowns.lua
