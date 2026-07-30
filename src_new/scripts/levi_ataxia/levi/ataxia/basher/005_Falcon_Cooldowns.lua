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

-- Function to handle hyena attack cooldown.
--
-- The reset is normally line-driven (trigger 368, "You may command your hyena to maul
-- your foes once more."), but a missed line would strand hyenaMaulReady = false FOREVER
-- and we would silently never maul again. So arm a safety timer as well, mirroring the
-- falcon.
--
-- DAEMON JAWS (Mnemosyne boon): "The cooldown for commanding your hyena to maul a denizen
-- is reduced by 66%." The game sends its own ready-line sooner, so the boon needs no help
-- in the normal path -- but the SAFETY timer must shrink to match, or it would be the
-- thing gating us at 30s while the real cooldown is ~10s.
ataxiaBasher.hyenaMaulCooldownSec = ataxiaBasher.hyenaMaulCooldownSec or 30

function ataxiaBasher_hyenaMaulCooldown()
	ataxiaBasher.hyenaMaulReady = false
	local secs = ataxiaBasher.hyenaMaulCooldownSec or 30
	if infDaemonJaws then secs = secs * 0.34 end -- -66%
	if ataxiaBasher_hyenaMaulTimer then killTimer(ataxiaBasher_hyenaMaulTimer) end
	ataxiaBasher_hyenaMaulTimer = tempTimer(secs, [[ataxiaBasher_hyenaMaulReady()]])
end

-- Function to handle hyena cooldown reset
function ataxiaBasher_hyenaMaulReady()
	ataxiaBasher.hyenaMaulReady = true
	if ataxiaBasher_hyenaMaulTimer then
		killTimer(ataxiaBasher_hyenaMaulTimer)
		ataxiaBasher_hyenaMaulTimer = nil
	end
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

-- FALCONER'S TACTICS (Mnemosyne boon): "The cooldown for commanding your falcon to rake a
-- denizen is reduced by 66%." The Runewarden twin of Daemon Jaws -- the game's own ready
-- line arrives sooner, so the boon needs no help there, but this safety timer must shrink
-- to match or IT becomes the thing gating us at 30s while the real cooldown is ~10s.
-- (AB Rake 3264 confirms the base: "Works on/against: Denizens", "Every 30 seconds".)
function ataxiaBasher_falconRakeCooldown()
	ataxiaBasher.falconRakeReady = false
	local secs = ataxiaBasher.falconRakeCooldownSec or 30
	if mnemFalconersTactics then secs = secs * 0.34 end -- -66%
	if ataxiaBasher_falconRakeTimer then killTimer(ataxiaBasher_falconRakeTimer) end
	ataxiaBasher_falconRakeTimer = tempTimer(secs, [[ataxiaBasher_falconRakeReady()]])
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
