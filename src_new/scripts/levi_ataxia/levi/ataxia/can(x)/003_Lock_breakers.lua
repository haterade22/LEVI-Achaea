--[[mudlet
type: script
name: Lock breakers
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Curing Stuff
- Can(x)
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--Will return true if venom locked.
function ataxia_needLockBreak()
	if affed("asthma") and affed("anorexia") and (affed("slickness") or affed("bloodfire")) and gmcp.Char.Status.class ~= "Psion" then
		return true
  elseif affed("asthma") and affed("anorexia") and (affed("slickness") or affed("bloodfire")) and affed("impatience") and gmcp.Char.Status.class == "Psion" then
		return true
	elseif affed("whisperingmadness") then
  return true
  	elseif affed("slime") then
  return true
  else
		return false
	end
end

--------------------------------------------------------------------------------
-- PRE-EMPTIVE LOCK CURE (v4.7.275)
--
-- From the 2026-08-19 Grulk (Sentinel) log: FITNESS sat ready and unblocked for a 34.8-second
-- stretch (09:59:01.221 -> 09:59:35.990) with asthma repeatedly up, and never fired -- because
-- its only caller gated on ataxia_needLockBreak(), which requires the lock to be ALREADY
-- COMPLETE (asthma AND anorexia AND slickness).
--
-- At 09:59:33 we held asthma + slickness: one affliction from the lock, cure idle. Anorexia
-- landed 2.9s later, the lock snapped shut, and by the time it did WEARINESS was back -- so the
-- cure was blocked for the remaining 17.8 seconds, through the true lock, to the death.
--
-- Waiting for the completed triad means only ever reaching for the cure at the moment it is
-- hardest to use. Fire instead when the lock is ONE component away.
--
-- Deliberately NOT on a bare asthma: the active cure has a ~10s cooldown (measured twice in
-- that log: 9.81 s, rows 1130-1306, and 9.06 s, rows 2105-2328) and asthma alone is not a lock.
-- A SECOND component is the trigger.
--------------------------------------------------------------------------------

local PRE_LOCK_PARTNERS = {"slickness", "bloodfire", "anorexia", "impatience", "sandfever"}

function ataxia_needPreLockCure()
	if ataxia.settings and ataxia.settings.preLockCure == false then return false end
	if not affed("asthma") then return false end
	-- A completed lock belongs to the reactive path below; this is only about denying the setup.
	if ataxia_needLockBreak() then return false end
	for _, aff in ipairs(PRE_LOCK_PARTNERS) do
		if affed(aff) then return true end
	end
	return false
end

-- Which affliction is blocking our class's active cure right now, or nil.
function ataxia_activeCureBlocker()
	local mine = ataxia_activeCureBlockers()[ataxiaTemp.class]
	if mine and affed(mine[1]) then return mine[1] end
	return nil
end

local LOCK_BREAKERS = {
	Alchemist = "educe salt",
	Blademaster = "fitness",
	Depthswalker = "chrono accelerate boost",
	Druid = "fitness",
	Infernal = "fitness",
	Jester = "fling fool at me",
	Magi = "cast bloodboil",
	Monk = "fitness",
	Occultist = "fling fool at me",
	Paladin = "fitness",
	Psion = "psi expunge",
	Runewarden = "fitness",
	Sentinel = "fitness",
	Serpent = "shrugging",
	Shaman = "invoke purification",
	Unnamable = "fitness",
}

--------------------------------------------------------------------------------
-- FITNESS AND SHRUGGING WAIT FOR EQUILIBRIUM (2026-11-01, shrugging 2026-11-08).
--
-- FITNESS. User: "fitness needs balance and eq", "It shouldnt fitness without EQ". The wiki lists
-- balance only. Live probe (kb/raw/live/probes_2026-11-01.txt): `touch shield;fitness` ran FITNESS
-- 3.3 s later, when equilibrium returned. So a send with equilibrium down does not fail; the game's
-- auto-queue holds it. That is the danger: a held FITNESS still fires after the asthma has gone,
-- and "You are already quite fit." costs 2.8 s of balance.
--
-- SHRUGGING spends equilibrium. The user's paste, 2026-11-08: "Focusing inward, you purge your body
-- of afflictions." then "Equilibrium used: 1.36s." The user approved this hold ("shrugging yes").
-- No probe has shown how the game treats a shrug sent with equilibrium down.
--
-- Unknown is not down: only an explicit false holds it, because a lock-breaker fails open. Only
-- these two cures are held. No probe has tested the other classes' cures.
--
-- Callers test this BEFORE they arm attemptedLockBreak. Otherwise the 1.5 s throttle could delay
-- the cure after equilibrium returns. The prompt heartbeat retries it on the recovery prompt.
--------------------------------------------------------------------------------
local EQ_HELD_CURES = { fitness = true, shrugging = true }

function ataxia_activeCureHeldForEq()
	local v = ataxia.vitals
	if not v or v.eq ~= false then return false end
	return EQ_HELD_CURES[LOCK_BREAKERS[ataxiaTemp.class]] == true
end

-- Debounced: the per-prompt heartbeat would otherwise spam this every 0.5s.
function ataxia_lockBreakBlockedEcho()
	local now = (getEpoch and getEpoch()) or os.time()
	if ataxiaTemp.lockBreakEchoAt and (now - ataxiaTemp.lockBreakEchoAt) < 3 then return end
	ataxiaTemp.lockBreakEchoAt = now
	local blocker = ataxia_activeCureBlocker()
	if blocker then
		cecho("\n<red>[LOCK]<reset> Active cure BLOCKED by <yellow>" .. blocker .. "<reset> -- cure it or run.")
	elseif ataxiaTemp.activeCureUsed then
		cecho("\n<red>[LOCK]<reset> Active cure on COOLDOWN.")
	elseif ataxia_activeCureHeldForEq() then
		cecho("\n<yellow>[LOCK]<reset> " .. LOCK_BREAKERS[ataxiaTemp.class]:upper() .. " waits for <yellow>equilibrium<reset>.")
	else
		cecho("\n<red>[LOCK]<reset> Active cure unavailable (no lock-breaker for this class).")
	end
end

--If we can break the venom lock, then do so. Requires eq/bal.
-- FREE-VALUE ACTIVE CURE (v4.7.277). Distinct from lock-breaking on purpose.
--
-- ataxia_lockBreak only fires when a lock exists or is one component away. But FITNESS costs
-- nothing except its own cooldown and it removes ASTHMA **off the contended eat balance** --
-- so whenever asthma is up alongside a kelp/aurum stack it is worth taking regardless of
-- whether a lock is forming. Routing the kelp digger through ataxia_lockBreak() meant a pure
-- stack (asthma + sensitivity, no lock partner) never fired it at all.
--
-- Gated on asthma because that is what the FITNESS family purges; classes whose active cure
-- does more (Depthswalker, Magi, Shaman) simply take this path less often -- the conservative
-- failure.
function ataxia_tryActiveCure()
	if not affed("asthma") then return end
	if ataxiaTemp.activeCureUsed then return end
	if attemptedLockBreak then return end
	if not ataxia_canActive() then return end
	if ataxia_activeCureHeldForEq() then return end
	attemptedLockBreak = tempTimer(1.5, [[ attemptedLockBreak = nil ]])
	ataxia_breakLock()
end

function ataxia_lockBreak()
	if not (ataxia_needLockBreak() or ataxia_needPreLockCure()) then return end
	if attemptedLockBreak then return end
	if ataxiaTemp.activeCureUsed then return end

	if not ataxia_canActive() then
		-- This branch was SILENT before v4.7.275, and the whole 2026-08-19 loss turns on it:
		-- Blademaster's blocker is WEARINESS, the Sentinel held it up for the last 19 seconds,
		-- so the lock-break never even attempted -- while blademaster.sendAttack was
		-- simultaneously refusing to attack BECAUSE a lock-break was supposedly happening.
		-- Neither side did anything and nothing said so. See 005_CC_BM_Ice.lua sendAttack.
		ataxia_lockBreakBlockedEcho()
		return
	end

	if ataxia_activeCureHeldForEq() then
		ataxia_lockBreakBlockedEcho()
		return
	end

	attemptedLockBreak = tempTimer(1.5, [[ attemptedLockBreak = nil ]])
	ataxia_breakLock()
end

-- Per-prompt heartbeat (v4.7.275). ataxia_lockBreak previously ran ONLY as a side effect of an
-- affliction changing (004_Aff_gains_losses) or of an attack dispatch. Hold someone locked without
-- applying anything new and that wiring never fires at all.
--
-- The Grulk log does not show this gap. FITNESS fired at 09:59:40.576 because equilibrium returned
-- then: the shield spent it at 09:59:37 (rows 2040-2041), and it came back at row 2097, just before
-- the fire at row 2105. FITNESS needs equilibrium (kb/raw/live/probes_2026-11-01.txt). The
-- heartbeat is still the retry that sends a held FITNESS on the prompt where equilibrium returns.
--
-- Cheap by construction: the needs-checks are a handful of table lookups and `attemptedLockBreak`
-- already throttles the send to one per 1.5s.
function ataxia_lockBreakHeartbeat()
	if not ataxia or not ataxia.afflictions then return end
	local ok, err = pcall(ataxia_lockBreak)
	if not ok then cecho("\n<red>[LOCK] heartbeat error: " .. tostring(err)) end
	-- Prevention runs ALONGSIDE the break, not instead of it. By the time ataxia_lockBreak has
	-- something to do the cheap outs are already gone -- the whole plan is to never get there.
	local ok2, err2 = pcall(ataxia_preLockEscalate)
	if not ok2 then cecho("\n<red>[LOCK] pre-lock error: " .. tostring(err2)) end
	-- After the lock checks, so a lock-break owns the 1.5 s throttle on that prompt.
	local ok3, err3 = pcall(ataxia_loadCureHeartbeat)
	if not ok3 then cecho("\n<red>[CURE] heartbeat error: " .. tostring(err3)) end
	local ok4, err4 = pcall(ataxia_lockPartyCall)
	if not ok4 then cecho("\n<red>[LOCK] party call error: " .. tostring(err4)) end
end

--------------------------------------------------------------------------------
-- SELF-LOCK PARTY CALL (2026-11-11, the user: "Add in telling the party when we are being
-- locked"). In the 2026-11-11 Serpent group log we stayed truelocked for 94 s and told no one:
-- the only call was a `say`, which the party does not hear. One `pt` line goes out each time the
-- lock gets WORSE, by these stages (the same tests as the prompt's Locks labels, ataxia_promptLocks):
--   1 two of asthma / slickness (or bloodfire) / anorexia   "LOCKING ME (2/3)"
--   2 all three                                              "SOFTLOCKED"
--   3 and impatience (or sandfever)                          "HARDLOCKED"
--   4 and paralysis, with our lock-breaker blocked           "TRUELOCKED"
-- The line names our lock afflictions, so a healer knows what to take. Below stage 1 the stage
-- resets, so the next lock is called again. A stage given back within LOCK_CALL_GAP of its last
-- call (cured and re-applied) is not called again. Off with `ataxia.settings.lockPartyCall = false`
-- and with the party relay off (`partyrelay`, the switch of the target calls). Never while the
-- basher runs, and never under aeon (a command costs a whole aeon turn there).
--------------------------------------------------------------------------------
local LOCK_CALL_GAP = 4
local LOCK_CALL_NAMES = { "LOCKING ME (2/3)", "SOFTLOCKED", "HARDLOCKED", "TRUELOCKED" }
local LOCK_CALL_AFFS = { "asthma", "slickness", "bloodfire", "anorexia", "impatience", "sandfever",
	"paralysis", "weariness", "prone" }

function ataxia_lockStage()
	local comps = ataxia_lockComponents()
	if #comps < 2 then return 0 end
	if #comps == 2 then return 1 end
	if not (affed("impatience") or affed("sandfever")) then return 2 end
	if affed("paralysis") and not ataxia_canActive() then return 4 end
	return 3
end

function ataxia_lockPartyCall()
	if ataxia.settings and ataxia.settings.lockPartyCall == false then return end
	if partyrelay == false then return end
	if ataxiaBasher and ataxiaBasher.enabled then return end
	ataxiaTemp = ataxiaTemp or {}
	local stage = ataxia_lockStage()
	local last = ataxiaTemp.lockCallStage or 0
	if stage == 0 then ataxiaTemp.lockCallStage = 0; return end
	if stage <= last then return end
	if affed("aeon") then return end
	ataxiaTemp.lockCallStage = stage
	local now = getEpoch()
	local at = ataxiaTemp.lockCallAt or {}
	ataxiaTemp.lockCallAt = at
	if at[stage] and now - at[stage] < LOCK_CALL_GAP then return end
	at[stage] = now
	local have = {}
	for _, a in ipairs(LOCK_CALL_AFFS) do
		if affed(a) then have[#have + 1] = a end
	end
	send("pt " .. LOCK_CALL_NAMES[stage] .. ": " .. table.concat(have, ", "), false)
end


-- Shared by ataxia_canActive and ataxia_activeCureBlocker so the diagnostic can never
-- disagree with the gate.
--
-- MODULE-LEVEL, deliberately not rebuilt per call (v4.7.277). ataxia_canActive() sits on the
-- PROMPT hot path now that ataxia_lockEscapes() calls it every prompt, and CLAUDE.md is
-- explicit: "Minimize table creation in hot paths (balance/prompt triggers)". Rebuilding a
-- 14-entry table two or three times per prompt is exactly what that warns against.
local ACTIVE_CURE_BLOCKERS = {
		Alchemist = {"stupidity"},
		Blademaster = {"weariness"},
		Depthswalker = {"recklessness"},
		Druid = {"weariness"},
		Infernal = {"weariness"},
		Jester = {"paralysis"},
		Magi = {"haemophilia"},
		Monk = {"weariness"},
		Occultist = {"paralysis"},
		Paladin = {"weariness"},
		Runewarden = {"weariness"},
		Sentinel = {"weariness"},
		Serpent = {"weariness"},
		Shaman = {"selarnia"},
}

function ataxia_activeCureBlockers()
	return ACTIVE_CURE_BLOCKERS
end

function ataxia_canActive()
	if ataxiaTemp.activeCureUsed then return false end
	if type(ataxiaTemp.class) ~= "string" then return false end

	local blockers = ataxia_activeCureBlockers()
	if affed("brokenleftarm") and affed("brokenrightarm") and blockers[ataxiaTemp.class] and blockers[ataxiaTemp.class][1] ~= "weariness" then
		return false
	elseif not blockers[ataxiaTemp.class] then
		if string.find(ataxiaTemp.class, "Dragon") then
			if affed("weariness") and affed("recklessness") then
				return false
			else
				return true
			end
    elseif string.find(ataxiaTemp.class, "Elemental") then
      -- Weariness BLOCKS the cure (kb/afflictions/class-cures.md). This test was inverted until
      -- v4.7.484, so an Earth Lord could send ERUPTION only while weariness refused it.
      if affed("weariness") then
        return false
      else
        return true
      end
		else
			return false
		end
	elseif affed( blockers[ataxiaTemp.class][1] ) then
		return false
	else
		return true
	end
end

--------------------------------------------------------------------------------
-- LOCK-BREAKER, THEN SHIELD (the user, 2026-11-09, kb/CONFLICTS.md #77).
--
-- Both spend equilibrium: the shield tattoo costs 3.40 s on our seat (the base 4.00 s through the Aldar
-- Diadem, ataxia_eqFactor in misc_scripts/033; 2.89 s in Rain), and the `cq all` sent in front
-- of it clears a lock-breaker the game holds. So an automatic shield waits while ataxia_lockBreak
-- would still act. A cure held for equilibrium counts as due. A blocked cure and one on cooldown do
-- not, because the shield would then wait for nothing.
--
-- The wait ends after SHIELD_WAIT_MAX seconds. ataxia_lockBreak re-sends every 1.5 s until a line
-- says the cure was used, so a cure the game keeps refusing would otherwise hold the shield off
-- for the whole fight. 4 s covers one full equilibrium recovery of up to 4.00 s, which holds for a
-- player with no artefact. An Aldar Diadem (ataxia_eqFactor) makes the recovery shorter, never
-- longer, so the same 4 s is kept for every player.
--
-- Not gated: the instant-kill shield (myinstantcath) and the limb reaction shield. Those answer a
-- blow that lands now.
--------------------------------------------------------------------------------
local SHIELD_WAIT_MAX = 4

function ataxia_lockBreakDue()
	if ataxiaTemp.activeCureUsed then return false end
	if not (ataxia_needLockBreak() or ataxia_needPreLockCure()) then return false end
	return ataxia_canActive()
end

function ataxia_shieldWaitsForLockBreak()
	if not ataxia_lockBreakDue() then
		ataxiaTemp.shieldWaitSince = nil
		return false
	end
	local now = (getEpoch and getEpoch()) or os.time()
	if not ataxiaTemp.shieldWaitSince then ataxiaTemp.shieldWaitSince = now end
	return (now - ataxiaTemp.shieldWaitSince) < SHIELD_WAIT_MAX
end

-- NOTE the `send(cmd, false)` calls below: the `false` suppresses the client echo, which is why
-- FITNESS is invisible in combat logs -- the 2026-08-19 analysis initially concluded it had never
-- been sent, when in fact it fired twice and the server's replies were the only evidence. The
-- explicit [LOCK] echo added in v4.7.275 exists so a log can answer that question directly.
function ataxia_activeCureCommand(class)
	if string.find(class, "Dragon") then
		return "dragonheal"
	elseif string.find(class, "Earth") then
		return "terran eruption"
	elseif class == "Depthswalker" and affed("prone") and affed("paralysis") then
		-- "being prone will make boosting the process impossible" (kb/raw/wiki/Aeonics.wiki:106).
		-- Prone and paralysed we cannot stand first (ataxia_breakLock), so this sent, every 1.5 s, a
		-- boost the wiki says cannot work. The plain acceleration cures one affliction.
		return "chrono accelerate"
	end
	return LOCK_BREAKERS[class]
end

function ataxia_breakLock()
	local class = ataxiaTemp.class
	if type(class) ~= "string" then return end

	if affed("prone") and not affed("paralysis") then
		send("stand",false)
	end

	local cmd = ataxia_activeCureCommand(class)

	-- v4.7.275: was `send(lockBreaker[ataxiaTemp.class], false)` unguarded -- an unmapped class
	-- (or a reworded charstat) reached send(nil), which errors and takes the whole prompt handler
	-- with it. Silence is the failure mode this file has already cost us once; say it instead.
	if not cmd then
		cecho("\n<red>[LOCK]<reset> No lock-breaker defined for class <yellow>" .. class .. "<reset>.")
		return
	end

	cecho("\n<yellow>[LOCK]<reset> Breaking lock: <white>" .. cmd)
	send(cmd, false)
end

--------------------------------------------------------------------------------
-- CLASS CURE AT 3 AFFLICTIONS, WHILE BASHING (v4.7.484, the user, 2026-11-09).
--
-- User: "we should be using our class active cures if we have 3 or more afflictions on us".
-- The lock-breaker above fires only for a lock or a forming lock. In a crowded ripple we hold many
-- afflictions and no lock, so the cure sat ready and unused.
--
-- BASHING ONLY (the user's choice). In PvP, 3 afflictions is the normal state, so the rule would
-- spend the cure on nearly every cooldown and delay the offence. PvP keeps the lock-only rule.
--
-- THE MIRACLE BOON NEEDS NO CODE. The user chose one threshold with or without it. The game cures
-- the extra affliction, and GMCP reports the removal.
--
-- WHAT COUNTS. A random cure cannot take a NoRandomCure affliction (prone, laceratedthroat, a
-- damaged limb), so those do not count. treeCurableAffsV3 is the list of what a random cure takes
-- (kb/afflictions/database.md). An affliction that is not in it does not count, which leaves the
-- cure idle rather than spent on nothing.
--
-- TWO PATHS, because the game's queue decides who gets equilibrium:
--   1. THE ROUND (ataxia_loadCureRound, called from ataxiaBasher_assembleAttack). A queued attack
--      takes equilibrium the moment it returns, before any prompt can show it free, so a class
--      whose attack spends equilibrium would never see it up. The cure replaces the round. It takes
--      the whole round because a round must have one equilibrium spender (the v4.7.193 rule). A
--      once-per-room rider that the game refused would still stamp its guard.
--   2. THE PROMPT (ataxia_loadCureHeartbeat). Attacks are held during a recovery, so no round runs.
--      It needs balance AND equilibrium up on the prompt, and then anything queued has already run.
--------------------------------------------------------------------------------
local LOAD_CURE_MIN = 3
-- With no use line for this long, the cure was refused. It covers a full equilibrium recovery.
local LOAD_CURE_WAIT = 6
-- A longer silence between two offers means a gate held us, so the wait starts again.
local LOAD_CURE_GAP = 3
local LOAD_CURE_BACKOFF = 20
-- From the ability pages. The other cures have no mana cost in the kb.
local LOAD_CURE_MANA = { Alchemist = 200, Magi = 75 }

-- How many of our afflictions a random cure can take.
function ataxia_randomCurableCount()
	local pool = treeCurableAffsV3
	if type(pool) ~= "table" then return 0 end
	local n = 0
	for i = 1, #pool do
		if affed(pool[i]) then n = n + 1 end
	end
	return n
end

-- The command to use for this load of afflictions, or nil.
function ataxia_loadCureCommand()
	local class = ataxiaTemp and ataxiaTemp.class
	if type(class) ~= "string" then return nil end
	if not ataxia_canActive() then return nil end
	-- User, for FITNESS: "It shouldnt fitness without EQ". SHRUGGING is held the same way. The round
	-- attacks meanwhile, and the next re-queue with equilibrium up carries the cure.
	if ataxia_activeCureHeldForEq() then return nil end
	if ataxia_randomCurableCount() < LOAD_CURE_MIN then return nil end

	local cmd = ataxia_activeCureCommand(class)
	if not cmd then return nil end

	-- FITNESS cures asthma and nothing else. With no asthma it prints "You are already quite fit."
	-- and still costs 2.8 s of balance (kb/afflictions/class-cures.md).
	if cmd == "fitness" and not affed("asthma") then return nil end
	-- Prone blocks the Fool (HELP). The round's stand comes first, and the next round sends it.
	if cmd == "fling fool at me" and affed("prone") then return nil end

	local mana = LOAD_CURE_MANA[class]
	if mana and (tonumber(ataxia.vitals and ataxia.vitals.mp) or 0) < mana then return nil end

	if class == "Depthswalker" then
		-- A boost ages us by 340 years (kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt
		-- :2094). Bashing must not price out the chrono kit, so it obeys the cap that blur obeys.
		local dw = ataxiaTables and ataxiaTables.depthswalker
		local age = tonumber(dw and dw.age) or 0
		local cap = tonumber(ataxiaBasher and ataxiaBasher.dwAgeCap) or 400
		if affed("prone") or age > cap then return "chrono accelerate" end
	end
	return cmd
end

-- The command to send now, or nil. A cure with no fire line never sets activeCureUsed, so without
-- this limit a refused cure would replace every round and stop the attacks.
function ataxia_loadCureReady()
	local cmd = ataxia_loadCureCommand()
	if not cmd then
		ataxiaTemp.loadCureSince = nil
		return nil
	end

	local now = (getEpoch and getEpoch()) or os.time()
	if ataxiaTemp.loadCureBackoffUntil then
		if now < ataxiaTemp.loadCureBackoffUntil then return nil end
		ataxiaTemp.loadCureBackoffUntil = nil
	end

	local last = ataxiaTemp.loadCureLastAt
	ataxiaTemp.loadCureLastAt = now
	if ataxiaTemp.loadCureSince and last and (now - last) >= LOAD_CURE_GAP then
		ataxiaTemp.loadCureSince = nil
	end

	local since = ataxiaTemp.loadCureSince
	if not since then
		ataxiaTemp.loadCureSince = now
		cecho("\n<yellow>[CURE]<reset> " .. ataxia_randomCurableCount() .. " afflictions: <white>" .. cmd)
		return cmd
	end
	if (now - since) >= LOAD_CURE_WAIT then
		ataxiaTemp.loadCureSince = nil
		ataxiaTemp.loadCureBackoffUntil = now + LOAD_CURE_BACKOFF
		cecho("\n<red>[CURE]<reset> No answer to <white>" .. cmd .. "<reset>: attacking, retry in " .. LOAD_CURE_BACKOFF .. " s.")
		return nil
	end
	return cmd
end

-- The round's command, or "". magiBashing owns the Magi's, so that its battlerage still rides.
function ataxia_loadCureRound()
	if ataxiaTemp and ataxiaTemp.class == "Magi" then return "" end
	return ataxia_loadCureReady() or ""
end

-- True while a cure now could delay a move or a command we are waiting on.
local function loadCureWouldDelay()
	local T = ataxiaTemp
	if T.escapeMode or T.phialHold or T.dissectHold then return true end
	local S = ataxia.mnemosyne and ataxia.mnemosyne.swarm
	if S and S.moveLocked and S.moveLocked() then return true end
	-- A panic tumble waits in the queue while the state already reads "recovering".
	if S and S._retreatInFlight and S._retreatInFlight() then return true end
	return T.swarmHold and not (S and S.state == "recovering") and true or false
end

function ataxia_loadCureHeartbeat()
	if not (ataxiaBasher and ataxiaBasher.enabled) or ataxiaBasher.paused then return end
	if ataxia_paused and ataxia_paused() then return end
	if attemptedLockBreak then return end
	local v = ataxia.vitals
	if not v or not v.bal or not v.eq then return end
	if loadCureWouldDelay() then return end

	local cmd = ataxia_loadCureReady()
	if not cmd then return end
	attemptedLockBreak = tempTimer(1.5, [[ attemptedLockBreak = nil ]])
	if affed("prone") and not affed("paralysis") then send("stand", false) end
	send(cmd, false)
end

-- LOCK PREVENTION (v4.7.277) -- the whole plan is to never reach a soft lock, so this reports
-- PROGRESS toward one, not merely its arrival. The old display named the lock only once it had
-- already closed, which is exactly backwards: by then the cheap outs are gone.
--
-- WHY IT CLOSES, measured from the 2026-08-19 Grulk log -- FOUR of the five components were
-- cured on the SAME contended EAT balance:
--     paralysis  -> magnesium  (EAT)   x24 cures -- this alone saturates the balance
--     slickness  -> magnesium  (EAT)   x3
--     asthma     -> aurum      (EAT)   x3   ... or FITNESS, the only non-eat route
--     impatience -> plumbum    (EAT)   x2
--     anorexia   -> realgar SMOKE or FOCUS  -- THE ONLY COMPONENT OFF THE EAT BALANCE
--
-- So you cannot out-cure a Sentinel lock on the eat balance; he re-applies paralysis faster
-- than the queue drains. The outs that work are the ones paralysis cannot reach: FOCUS/SMOKE
-- for anorexia, FITNESS for asthma.
--
-- AND THE LOCK IS SELF-SEALING: asthma blocks SMOKING ("Your lungs are much too constricted to
-- smoke") and impatience blocks FOCUS -- which are precisely the two channels that cure
-- anorexia. Once asthma AND impatience are both up, anorexia has no cheap out at all, and
-- weariness (blocking FITNESS) closes the last one. That is what "true" really means here.
function ataxia_lockComponents()
  local c = {}
  if affed("asthma") then c[#c+1] = "ast" end
  if affed("slickness") or affed("bloodfire") then c[#c+1] = "sli" end
  if affed("anorexia") then c[#c+1] = "ano" end
  return c
end

-- Which escape channels are still open. Nil-safe and cheap; called once per prompt.
function ataxia_lockEscapes()
  return {
    smoke   = not affed("asthma"),      -- asthma constricts the lungs
    focus   = not affed("impatience"),  -- impatience blocks focus
    fitness = ataxia_canActive(),       -- weariness blocks it for most classes
  }
end

-- PRE-LOCK ESCALATION (v4.7.277). Class-agnostic: any locking opponent works this way.
--
-- At TWO of three components the third is the most dangerous affliction on the board, and
-- curing ANY of the three prevents the lock outright. The mistake is to fight for whichever one
-- sits highest in the static table -- because asthma, slickness and impatience all cure on the
-- EAT balance, which a paralysis-spamming opponent has already saturated (24 paralysis cures
-- and ZERO herbs eaten across 123 seconds in the 2026-08-19 log).
--
-- Spend on a channel that is still OPEN instead:
--   1. FITNESS for asthma -- the only non-eat asthma cure (ataxia_needPreLockCure fires it).
--   2. ANOREXIA while smoke or focus survives -- the only component never on the eat balance.
--      Lock attempt 1 in that log collapsed in 0.3s precisely because anorexia went first.
--   3. ASTHMA otherwise -- curing it re-opens SMOKE, which is anorexia's other way out.
--
-- Throttled: `curing prioaff` writes no stored priority (safe against the curingset write
-- hazard) but the per-prompt heartbeat would still spam the server.
function ataxia_preLockEscalate()
  if ataxia_needLockBreak() then return end   -- already locked: ataxia_lockBreak owns it
  local comps = ataxia_lockComponents()
  if #comps < 2 then return end

  if attemptedPreLock then return end
  attemptedPreLock = tempTimer(1.5, [[ attemptedPreLock = nil ]])

  local esc = ataxia_lockEscapes()
  if affed("anorexia") and (esc.smoke or esc.focus) then
    send("curing prioaff anorexia")
  elseif affed("asthma") then
    send("curing prioaff asthma")
  elseif affed("slickness") then
    send("curing prioaff slickness")
  end
end

function ataxia_promptLocks()
  local lockTable = {}

  -- Progress, before the lock exists. Two of three is the moment to act, not three.
  local comps = ataxia_lockComponents()
  if #comps == 2 then
    lockTable[#lockTable + 1] = "PRE-LOCK 2/3"
  end

  -- Both anorexia channels shut. This is the point of no return and it can be true BEFORE
  -- any lock is assembled -- which is the entire reason it is on the prompt.
  local esc = ataxia_lockEscapes()
  if not esc.smoke and not esc.focus then
    lockTable[#lockTable + 1] = "SEALED(no smoke/focus)"
  end

  -- Our own lock-breaker taken away while asthma is live. The most actionable line on the
  -- prompt: curing the named blocker hands FITNESS straight back, and FITNESS is the only
  -- asthma cure that does not queue behind paralysis on the eat balance.
  if affed("asthma") and not esc.fitness then
    local blocker = ataxia_activeCureBlocker()
    if blocker then
      lockTable[#lockTable + 1] = "NO-FITNESS(" .. blocker .. ")"
    end
  end
  if affed("asthma") and (affed("slickness") or affed("bloodfire")) and affed("anorexia") then
    table.insert(lockTable, "soft")
    if affed("paralysis") then
      table.insert(lockTable, "venom")
    end
    if affed("impatience") or affed("sandfever") then
      table.insert(lockTable, "hard")
      if not ataxia_canActive() and affed("paralysis") then
        table.insert(lockTable, "true")
      end
    end
  end
  
  if affed("asthma") and (affed("bloodfire") or affed("slickness")) and (affed("damagedrightarm") or affed("mangledrightarm")) and (affed("damagedleftarm") or affed("mangledleftarm")) then
    table.insert(lockTable, "rift")
  end  

  -- SKULLBASH RANGE (v4.7.276). Sentinel Skirmishing SKULLBASH needs PRONE **and** a BROKEN HEAD
  -- simultaneously -- confirmed 2026-08-19, where it did 8,556 unblockable from 9,817 HP and
  -- ended the fight in one hit. Both conditions are individually trivial to cure, which is
  -- exactly why it belongs on the prompt: the danger is the CONJUNCTION, and it is invisible
  -- unless something names it. Counter either half -- stand, or restore the head.
  if affed("prone") and (affed("damagedhead") or affed("mangledhead")) then
    table.insert(lockTable, "SKULLBASH")
  end

  -- A Depthswalker holds our shadow (levi_scripts/class_detect/002). Display only.
  local shadow = dwWatch and dwWatch.promptLabel and dwWatch.promptLabel()
  if shadow then table.insert(lockTable, shadow) end

  if #lockTable > 0 then
    return "<NavajoWhite> (<orange>Locks: <DimGrey>"..table.concat(lockTable, ", ").."<NavajoWhite>)"
  else
    return ""
  end
end

registerAnonymousEventHandler("aff gained", "ataxia_needLockBreak")