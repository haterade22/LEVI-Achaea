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

-- Trigger for swarm devour attack detection (sets cooldown)
-- Pattern: "You direct your swarm to devour"
if exists("Pariah Swarm Devour Cooldown", "trigger") == 0 then
	permRegexTrigger("Pariah Swarm Devour Cooldown", "", {[[^You direct your swarm to devour]]}, [[ataxiaBasher_swarmDevourCooldown()]])
end

-- Trigger for swarm devour kill (resets cooldown immediately)
-- Pattern: "With a chorus of chittering mandibles, the swarm rips away from the corpse of..."
if exists("Pariah Swarm Devour Kill Reset", "trigger") == 0 then
	permRegexTrigger("Pariah Swarm Devour Kill Reset", "", {[[^With a chorus of chittering mandibles, the swarm rips away from the corpse of]]}, [[ataxiaBasher_swarmDevourReady()]])
end

-- Trigger for swarm devour on cooldown (safety check)
-- Pattern varies - add if you see a specific cooldown message
if exists("Pariah Swarm Devour On Cooldown", "trigger") == 0 then
	permRegexTrigger("Pariah Swarm Devour On Cooldown", "", {[[^Your swarm is still digesting]]}, [[ataxiaBasher_swarmDevourCooldown()]])
end

-- Trigger for swarm devour ready message (40 second cooldown expired)
if exists("Pariah Swarm Devour Ready Message", "trigger") == 0 then
	permRegexTrigger("Pariah Swarm Devour Ready Message", "", {[[^You may command a swarm to devour another foe\.$]]}, [[ataxiaBasher_swarmDevourReady()]])
end
