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

-- Runewarden Falcon Rake PVE cooldown (mirror of the hyena maul above)
-- 'falcon rake <target>' is a free pet attack on a ~30s cooldown. Set false when it
-- fires (or is rejected as still on CD) via trigger 370, reset by the game's
-- "ready again" line via trigger 371. The falconRakeCooldownSec timer is a safety net
-- in case that line is ever missed. Adjust ataxiaBasher.falconRakeCooldownSec to tune.
if ataxiaBasher and ataxiaBasher.falconRakeReady == nil then
	ataxiaBasher.falconRakeReady = true
end
ataxiaBasher.falconRakeCooldownSec = ataxiaBasher.falconRakeCooldownSec or 30

function ataxiaBasher_falconRakeCooldown()
	ataxiaBasher.falconRakeReady = false
	if ataxiaBasher_falconRakeTimer then killTimer(ataxiaBasher_falconRakeTimer) end
	ataxiaBasher_falconRakeTimer = tempTimer(ataxiaBasher.falconRakeCooldownSec, [[ataxiaBasher_falconRakeReady()]])
end

function ataxiaBasher_falconRakeReady()
	ataxiaBasher.falconRakeReady = true
	if ataxiaBasher_falconRakeTimer then killTimer(ataxiaBasher_falconRakeTimer); ataxiaBasher_falconRakeTimer = nil end
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
