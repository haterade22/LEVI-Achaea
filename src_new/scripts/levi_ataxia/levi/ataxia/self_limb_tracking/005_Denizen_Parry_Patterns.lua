--[[mudlet
type: script
name: Denizen Parry Patterns
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Self Limb Tracking
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- Predictive parry vs denizens with FIXED swing cycles (observed in combat logs).
-- Some mobs telegraph their whole rotation -- e.g. the Mnemosyne axe-wielding revenant
-- swings right leg x2 -> left leg x2 -> torso x2 and repeats. Damage-weighted parry only
-- reacts AFTER damage lands; here we parry the limb the NEXT swing will hit.
--
-- Model: on each observed hit (fed from ataxia_raiseLimbDamage, so it rides the same
-- "dealt N% damage to your <limb>" perceive lines SLC already parses) we track
-- (mob, limb, consecutive-swing count). Two perceive lines land per swing, so hits on the
-- same limb within 1s are ONE swing. Prediction: fewer than hitsPer swings seen on the
-- current limb -> the next swing repeats it; hitsPer (or more) -> the cycle advances.
-- The attacker is taken to be the basher's current mob (secondTarget) -- patterns key off
-- the NAME, and the whole layer is basher-gated so it can never touch PvP parry.

selfLimbDamage = selfLimbDamage or {}

-- name -> { cycle = ordered limb list, hitsPer = swings per limb before advancing }
--      or { fixed = limb } for mobs with exactly one parryable attack: park the parry
--      there permanently and accept everything else (no observation needed).
selfLimbDamage.denizenPatterns = selfLimbDamage.denizenPatterns or {}
selfLimbDamage.denizenPatterns["an axe-wielding revenant"] = {
	cycle = { "right leg", "left leg", "torso" }, hitsPer = 2,
}
-- Death Knights' parryable attack is the knee-snap; always cover the left leg and
-- accept the torso/head/arm hits (user-confirmed tactic, 2026-07-25 log).
selfLimbDamage.denizenPatterns["a steel-encased Death Knight"] = { fixed = "left leg" }
-- The ravager's only limb-targeted attack is the torso cleave (perceive: "dealt 30.0%
-- damage to your torso" x2 per swing); her dive names no limb and the shoulder-charge
-- impale is unblockable, so torso cover is free value (2026-07-25 swamp log).
selfLimbDamage.denizenPatterns["a ravager of the Infernal Legion"] = { fixed = "torso" }

local state = { mob = nil, limb = nil, count = 0, at = 0 }
local SAME_SWING_WINDOW = 1.0  -- two perceive lines of one swing land inside this
local STALE_AFTER = 12         -- no hits this long -> mob dead/left; drop the prediction

local function _now()
	return (getEpoch and getEpoch()) or os.time()
end

local function _nextInCycle(cycle, limb)
	for i, l in ipairs(cycle) do
		if l == limb then return cycle[(i % #cycle) + 1] end
	end
	return nil
end

-- Fed from ataxia_raiseLimbDamage (perceive lines) and ataxia_parrySuccess (parried
-- swings emit no perceive line) on every incoming limb hit.
function ataxia_denizenParryObserve(limb)
	if not (ataxiaBasher and ataxiaBasher.enabled) then return end
	local mob = secondTarget
	local pat = mob and selfLimbDamage.denizenPatterns[mob]
	if not pat or pat.fixed then return end
	local now = _now()
	if state.mob == mob and state.limb == limb and (now - state.at) < SAME_SWING_WINDOW then
		state.at = now -- second perceive line of the SAME swing -- don't double-count
		return
	end
	-- A stale streak belongs to a PREVIOUS engagement (same-named mobs respawn constantly):
	-- restart the count instead of inflating it, or the re-engage opener gets mispredicted.
	if state.mob == mob and state.limb == limb and (now - state.at) <= STALE_AFTER then
		state.count = state.count + 1
	else
		state.mob, state.limb, state.count = mob, limb, 1
	end
	state.at = now
end

-- The limb the NEXT swing should hit, or nil when no pattern applies (callers fall back
-- to the normal weighted parry). An unobserved patterned mob predicts the cycle opener.
function ataxia_denizenParryPredict()
	if not (ataxiaBasher and ataxiaBasher.enabled) then return nil end
	local mob = secondTarget
	local pat = mob and selfLimbDamage.denizenPatterns[mob]
	if not pat then return nil end
	-- Fixed-parry mob: one parryable attack, park the cover there unconditionally
	-- (even mid-break -- the parry still fires on a just-broken limb).
	if pat.fixed then return pat.fixed end
	if state.mob ~= mob or not state.limb then return pat.cycle[1] end
	if (_now() - state.at) > STALE_AFTER then return pat.cycle[1] end
	if state.count < (pat.hitsPer or 2) then return state.limb end
	return _nextInCycle(pat.cycle, state.limb) or state.limb
end
