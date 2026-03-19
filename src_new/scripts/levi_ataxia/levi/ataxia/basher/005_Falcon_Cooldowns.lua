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

-- One-time cleanup: remove orphaned permRegexTrigger-created triggers
-- (now handled by permanent triggers 367-369). Can be removed after one session.
for _, name in ipairs({
	"Infernal Hyena Maul Cooldown",
	"Infernal Hyena Maul Ready",
	"Infernal Hyena Maul On Cooldown",
	"Pariah Swarm Devour Cooldown",
	"Pariah Swarm Devour Kill Reset",
	"Pariah Swarm Devour On Cooldown",
	"Pariah Swarm Devour Ready Message",
}) do
	if exists(name, "trigger") > 0 then
		killTrigger(name)
	end
end
