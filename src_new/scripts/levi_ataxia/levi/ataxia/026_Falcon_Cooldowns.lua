--[[mudlet
type: script
name: Falcon Cooldowns
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

-- Infernal Hyena Maul PVE Trigger
-- Tracks the 30-second cooldown for hyena maul attack in PVE bashing

-- Initialize the cooldown variable if not already set
if ataxiaBasher and ataxiaBasher.hyenaMaulReady == nil then
	ataxiaBasher.hyenaMaulReady = true
end

-- Function to handle hyena attack cooldown
function ataxiaBasher_hyenaMaulCooldown()
	ataxiaBasher.hyenaMaulReady = false
end

-- Function to handle hyena cooldown reset
function ataxiaBasher_hyenaMaulReady()
	ataxiaBasher.hyenaMaulReady = true
end

-- Trigger for hyena attack detection (sets cooldown)
-- Pattern: "A daemonic hyena snarls as she hurls herself at"
if exists("Infernal Hyena Maul Cooldown", "trigger") == 0 then
	permRegexTrigger("Infernal Hyena Maul Cooldown", "", {[[^A daemonic hyena snarls as she hurls herself at]]}, [[ataxiaBasher_hyenaMaulCooldown()]])
end

-- Trigger for hyena cooldown reset
-- Pattern: "You may command your hyena to maul your foes once more."
if exists("Infernal Hyena Maul Ready", "trigger") == 0 then
	permRegexTrigger("Infernal Hyena Maul Ready", "", {[[^You may command your hyena to maul your foes once more\.$]]}, [[ataxiaBasher_hyenaMaulReady()]])
end

-- Trigger for hyena on cooldown (safety check)
-- Pattern: "You cannot yet order your hyena to maul another foe."
if exists("Infernal Hyena Maul On Cooldown", "trigger") == 0 then
	permRegexTrigger("Infernal Hyena Maul On Cooldown", "", {[[^You cannot yet order your hyena to maul another foe\.$]]}, [[ataxiaBasher_hyenaMaulCooldown()]])
end
