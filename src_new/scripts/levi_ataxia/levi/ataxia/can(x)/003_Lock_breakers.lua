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
-- that log -- 9.8s and 8.7s) and asthma alone is not a lock. A SECOND component is the trigger.
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

	attemptedLockBreak = tempTimer(1.5, [[ attemptedLockBreak = nil ]])
	ataxia_breakLock()
end

-- Per-prompt heartbeat (v4.7.275). ataxia_lockBreak previously ran ONLY as a side effect of an
-- affliction changing (004_Aff_gains_losses) or of an attack dispatch. In the Grulk log the
-- prompt was byte-identical for four seconds while we sat locked -- no gains, no losses, no
-- dispatch -- so nothing called it. The cure only went out at 09:59:40 because two unrelated
-- afflictions happened to land and re-trigger the hook. Hold someone locked without applying
-- anything new and the old wiring never fires at all.
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
      if affed("weariness") then
        return true
      else
        return false
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

-- NOTE the `send(cmd, false)` calls below: the `false` suppresses the client echo, which is why
-- FITNESS is invisible in combat logs -- the 2026-08-19 analysis initially concluded it had never
-- been sent, when in fact it fired twice and the server's replies were the only evidence. The
-- explicit [LOCK] echo added in v4.7.275 exists so a log can answer that question directly.
function ataxia_breakLock()
	local lockBreaker = {
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
	local class = ataxiaTemp.class
	if type(class) ~= "string" then return end

	if affed("prone") and not affed("paralysis") then
		send("stand",false)
	end

	local cmd
	if string.find(class, "Dragon") then
		cmd = "dragonheal"
	elseif string.find(class, "Earth") then
		cmd = "terran eruption"
	else
		cmd = lockBreaker[class]
	end

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

  if #lockTable > 0 then
    return "<NavajoWhite> (<orange>Locks: <DimGrey>"..table.concat(lockTable, ", ").."<NavajoWhite>)"
  else
    return ""
  end
end

registerAnonymousEventHandler("aff gained", "ataxia_needLockBreak")