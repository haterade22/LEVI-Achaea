--- test_lock_and_parry.lua -- canParry() and the lock-breaker (v4.7.275)
--
-- Both gates are here because they failed the same way in the 2026-08-19 Grulk (Sentinel) log,
-- and the shape is worth keeping a test around: each refused precisely when a limb-prep class
-- had done its job, and each refused in silence.
--
--   * canParry() required full bal AND eq (parry spends neither), routed through canStand()
--     (false on ANY leg damage) and blocked on sub-break arm damage. We parried 2 of 44 throws
--     while he walked right leg -> left leg -> left arm -> right leg -> HEAD, then killed us
--     with a haft crush on the broken head for 8,556 unblockable.
--
--   * ataxia_lockBreak() fired only once the lock was ALREADY COMPLETE (asthma AND anorexia AND
--     slickness). FITNESS sat ready and unblocked for 34.8 seconds with asthma repeatedly up and
--     never went out; by the time the lock closed, weariness was back and it was blocked for the
--     rest of the fight.

require("mock_mudlet")
local mock = require("mock_mudlet")

ataxia = { settings = {}, vitals = {}, afflictions = {}, defences = {} }
ataxiaTemp = {}
tAffs = {}

-- Minimal stand-ins for the two globals the gates lean on. `affed` is the real contract:
-- a truthy value in ataxia.afflictions.
function affed(what) return ataxia.afflictions[what] end
function ataxia_paused() return false end

local ok = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/can(x)/001_Various__can_do__stuff.lua")
if not ok then error("Failed to load can(x)/001") end
ok = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/can(x)/003_Lock_breakers.lua")
if not ok then error("Failed to load can(x)/003") end

local function reset(affs)
  ataxia.afflictions = affs or {}
  ataxia.vitals = { bal = true, eq = true, bleed = 0 }
  ataxia.settings = {}
  ataxiaTemp = { class = "Blademaster" }
  attemptedLockBreak = nil
  attemptedPreLock = nil
  gmcp = { Char = { Status = { class = "Blademaster" } } }
end

describe("canParry -- the gate that froze on a limb-prep class", function()
  it("permits a parry on a clean character", function()
    reset()
    expect(canParry()).toBe(true)
  end)

  -- The four regressions, one test each. Each of these was FALSE before v4.7.275.
  it("permits a parry while off balance and equilibrium -- parry spends neither", function()
    reset()
    ataxia.vitals.bal = false
    ataxia.vitals.eq = false
    expect(canParry()).toBe(true)
  end)

  it("permits a parry with a damaged LEG (canStand() is no longer consulted)", function()
    reset({ damagedrightleg = true })
    expect(canParry()).toBe(true)
  end)

  it("permits a parry with a BROKEN leg -- his right-leg prep must not freeze our cover", function()
    reset({ brokenrightleg = true })
    expect(canParry()).toBe(true)
  end)

  it("permits a parry with sub-break arm damage", function()
    reset({ damagedleftarm = true, damagedrightarm = true })
    expect(canParry()).toBe(true)
  end)

  it("permits a parry with ONE arm broken -- you parry with the other", function()
    reset({ brokenleftarm = true })
    expect(canParry()).toBe(true)
  end)

  -- ...and the genuine blockers still block.
  it("refuses when BOTH arms are out", function()
    reset({ brokenleftarm = true, mangledrightarm = true })
    expect(canParry()).toBe(false)
  end)

  it("refuses while prone", function()
    reset({ prone = true })
    expect(canParry()).toBe(false)
  end)

  it("refuses while paralysed", function()
    reset({ paralysis = true })
    expect(canParry()).toBe(false)
  end)

  it("refuses under aeon, sleep and stun", function()
    reset({ aeon = true });  expect(canParry()).toBe(false)
    reset({ sleep = true }); expect(canParry()).toBe(false)
    reset({ stun = true });  expect(canParry()).toBe(false)
  end)
end)

describe("ataxia_needPreLockCure -- fire one component early, not after the lock closes", function()
  it("is quiet with no asthma", function()
    reset({ slickness = true })
    expect(ataxia_needPreLockCure()).toBe(false)
  end)

  -- Deliberate: the cure has a ~10s cooldown (measured 9.8s and 8.7s in that log) and a bare
  -- asthma is not a lock. Spending it here is how you have none left when the lock lands.
  it("is quiet on a BARE asthma", function()
    reset({ asthma = true })
    expect(ataxia_needPreLockCure()).toBe(false)
  end)

  -- The exact 09:59:33 state: asthma + slickness, one affliction from the lock, cure idle.
  it("fires on asthma + slickness -- one affliction from the lock", function()
    reset({ asthma = true, slickness = true })
    expect(ataxia_needPreLockCure()).toBe(true)
  end)

  it("fires on asthma + impatience, and on asthma + anorexia", function()
    reset({ asthma = true, impatience = true })
    expect(ataxia_needPreLockCure()).toBe(true)
    reset({ asthma = true, anorexia = true })
    expect(ataxia_needPreLockCure()).toBe(true)
  end)

  -- A completed lock belongs to the reactive path, so the pre-emptive check stands down and
  -- does not double-fire alongside it.
  it("stands down once the lock is COMPLETE -- that is the reactive path's job", function()
    reset({ asthma = true, slickness = true, anorexia = true })
    expect(ataxia_needLockBreak()).toBe(true)
    expect(ataxia_needPreLockCure()).toBe(false)
  end)

  it("can be switched off", function()
    reset({ asthma = true, slickness = true })
    ataxia.settings.preLockCure = false
    expect(ataxia_needPreLockCure()).toBe(false)
  end)
end)

describe("ataxia_canActive -- the blocker that produced the deadlock", function()
  it("is true for a clean Blademaster", function()
    reset()
    expect(ataxia_canActive()).toBe(true)
  end)

  -- The whole 2026-08-19 loss in one assertion: weariness up -> no lock-break -> and the BM
  -- dispatch was meanwhile deferring TO that lock-break. See 005_CC_BM_Ice sendAttack.
  it("is false for a Blademaster carrying WEARINESS", function()
    reset({ weariness = true })
    expect(ataxia_canActive()).toBe(false)
    expect(ataxia_activeCureBlocker()).toBe("weariness")
  end)

  it("reports no blocker when the block is the cooldown rather than an affliction", function()
    reset()
    ataxiaTemp.activeCureUsed = true
    expect(ataxia_canActive()).toBe(false)
    expect(ataxia_activeCureBlocker()).toBe(nil)
  end)

  -- Was an unguarded string.find(ataxiaTemp.class, "Dragon") -- a nil class threw and took the
  -- caller with it. A reworded charstat is all it takes.
  it("returns false rather than erroring when the class is unknown", function()
    reset()
    ataxiaTemp.class = nil
    expect(ataxia_canActive()).toBe(false)
  end)
end)

describe("ataxia_lockBreak -- what actually goes out", function()
  it("sends the class active cure when the lock is complete and nothing blocks", function()
    reset({ asthma = true, slickness = true, anorexia = true })
    mock.reset()
    ataxia_lockBreak()
    expect(table.concat(mock.sent_commands, "|"):find("fitness") ~= nil).toBe(true)
  end)

  it("sends it PRE-EMPTIVELY at one component away", function()
    reset({ asthma = true, slickness = true })
    mock.reset()
    ataxia_lockBreak()
    expect(table.concat(mock.sent_commands, "|"):find("fitness") ~= nil).toBe(true)
  end)

  it("sends nothing, and does not error, when weariness blocks the cure", function()
    reset({ asthma = true, slickness = true, anorexia = true, weariness = true })
    mock.reset()
    ataxia_lockBreak()
    expect(table.concat(mock.sent_commands, "|"):find("fitness")).toBe(nil)
  end)

  it("does not fire twice inside the attempt throttle", function()
    reset({ asthma = true, slickness = true, anorexia = true })
    mock.reset()
    ataxia_lockBreak()
    local first = #mock.sent_commands
    ataxia_lockBreak()
    expect(#mock.sent_commands).toBe(first)
  end)

  -- The heartbeat is what makes a STATIC lock get attacked at all: in the log the prompt was
  -- byte-identical for four seconds and no aff-gain hook fired.
  it("has a heartbeat that is safe to call every prompt", function()
    reset()
    local ok2 = pcall(ataxia_lockBreakHeartbeat)
    expect(ok2).toBe(true)
  end)
end)

describe("ataxia_promptLocks -- the SKULLBASH conjunction", function()
  -- Sentinel SKULLBASH needs PRONE **and** a BROKEN HEAD together (confirmed 2026-08-19:
  -- 8,556 unblockable from 9,817 HP, one hit). Each half alone is trivial to cure, which is
  -- precisely why the CONJUNCTION needs naming on the prompt -- it is otherwise invisible.
  it("says nothing when only prone", function()
    reset({ prone = true })
    expect(ataxia_promptLocks():find("SKULLBASH")).toBe(nil)
  end)

  it("says nothing when only the head is damaged", function()
    reset({ damagedhead = true })
    expect(ataxia_promptLocks():find("SKULLBASH")).toBe(nil)
  end)

  it("flags SKULLBASH on prone + damaged head", function()
    reset({ prone = true, damagedhead = true })
    expect(ataxia_promptLocks():find("SKULLBASH") ~= nil).toBe(true)
  end)

  it("flags SKULLBASH on prone + mangled head", function()
    reset({ prone = true, mangledhead = true })
    expect(ataxia_promptLocks():find("SKULLBASH") ~= nil).toBe(true)
  end)

  -- It must not displace the venom-lock display it shares a line with.
  it("coexists with the affliction lock ladder", function()
    reset({ prone = true, damagedhead = true,
            asthma = true, slickness = true, anorexia = true, paralysis = true })
    local s = ataxia_promptLocks()
    expect(s:find("soft") ~= nil).toBe(true)
    expect(s:find("venom") ~= nil).toBe(true)
    expect(s:find("SKULLBASH") ~= nil).toBe(true)
  end)
end)

describe("lock PREVENTION -- the plan is to never get locked", function()
  -- Measured from the 2026-08-19 log: FOUR of the five lock components cure on the SAME eat
  -- balance (paralysis/slickness -> magnesium, asthma -> aurum, impatience -> plumbum), and
  -- paralysis alone saturates it -- 27 magnesium, ZERO herbs, in 123 seconds. ANOREXIA is the
  -- only component off that balance (realgar smoke / focus), which is why it is the lever.
  it("counts components before a lock exists", function()
    reset({ asthma = true, slickness = true })
    expect(#ataxia_lockComponents()).toBe(2)
    expect(ataxia_needLockBreak()).toBe(false)
  end)

  it("warns PRE-LOCK 2/3 while it is still preventable", function()
    reset({ asthma = true, slickness = true })
    expect(ataxia_promptLocks():find("PRE%-LOCK 2/3") ~= nil).toBe(true)
  end)

  it("does not cry wolf on a single component", function()
    reset({ asthma = true })
    expect(ataxia_promptLocks():find("PRE%-LOCK")).toBe(nil)
  end)

  -- The self-sealing property: asthma constricts the lungs (no smoke) and impatience blocks
  -- focus -- and those are the only two channels that cure anorexia.
  it("reports the escape channels honestly", function()
    reset()
    local e = ataxia_lockEscapes()
    expect(e.smoke).toBe(true)
    expect(e.focus).toBe(true)
    reset({ asthma = true, impatience = true })
    e = ataxia_lockEscapes()
    expect(e.smoke).toBe(false)
    expect(e.focus).toBe(false)
  end)

  it("flags SEALED when both anorexia channels are shut", function()
    reset({ asthma = true, impatience = true })
    expect(ataxia_promptLocks():find("SEALED") ~= nil).toBe(true)
  end)

  -- ANOREXIA first while a non-eat channel survives: attempt 1 in the log collapsed in 0.3s
  -- precisely because anorexia went first.
  it("escalates ANOREXIA while smoke or focus is still open", function()
    reset({ anorexia = true, slickness = true })
    mock.reset()
    ataxia_preLockEscalate()
    expect(table.concat(mock.sent_commands, "|"):find("prioaff anorexia") ~= nil).toBe(true)
  end)

  -- Both anorexia channels shut -> curing asthma is what re-opens SMOKE.
  it("falls back to ASTHMA when anorexia has no way out", function()
    reset({ anorexia = true, asthma = true, impatience = true })
    mock.reset()
    ataxia_preLockEscalate()
    local sent = table.concat(mock.sent_commands, "|")
    expect(sent:find("prioaff asthma") ~= nil).toBe(true)
  end)

  it("stands down at one component, and once already locked", function()
    reset({ asthma = true })
    mock.reset(); ataxia_preLockEscalate()
    expect(#mock.sent_commands).toBe(0)
    reset({ asthma = true, slickness = true, anorexia = true })
    mock.reset(); ataxia_preLockEscalate()
    expect(#mock.sent_commands).toBe(0)
  end)

  it("throttles so the per-prompt heartbeat cannot spam prioaff", function()
    reset({ anorexia = true, slickness = true })
    mock.reset()
    ataxia_preLockEscalate()
    local n = #mock.sent_commands
    ataxia_preLockEscalate()
    expect(#mock.sent_commands).toBe(n)
  end)
end)

describe("ataxia_tryActiveCure -- FITNESS as free value, not only as a lock-breaker", function()
  -- The gap this closes: the kelp digger used to route through ataxia_lockBreak(), which only
  -- fires when a lock exists or is one component away. A pure kelp stack (asthma + sensitivity,
  -- no lock partner) therefore never reached FITNESS -- even though FITNESS is the one asthma
  -- cure that does not queue behind paralysis on the eat balance.
  it("fires on a bare asthma with no lock forming", function()
    reset({ asthma = true })
    expect(ataxia_needLockBreak()).toBe(false)
    expect(ataxia_needPreLockCure()).toBe(false)
    mock.reset()
    ataxia_tryActiveCure()
    expect(table.concat(mock.sent_commands, "|"):find("fitness") ~= nil).toBe(true)
  end)

  it("does nothing without asthma -- that is what the cure purges", function()
    reset({ sensitivity = true, healthleech = true })
    mock.reset(); ataxia_tryActiveCure()
    expect(table.concat(mock.sent_commands, "|"):find("fitness")).toBe(nil)
  end)

  it("respects the weariness block and the cooldown", function()
    reset({ asthma = true, weariness = true })
    mock.reset(); ataxia_tryActiveCure()
    expect(table.concat(mock.sent_commands, "|"):find("fitness")).toBe(nil)
    reset({ asthma = true })
    ataxiaTemp.activeCureUsed = true
    mock.reset(); ataxia_tryActiveCure()
    expect(table.concat(mock.sent_commands, "|"):find("fitness")).toBe(nil)
  end)

  it("shares the attempt throttle with the lock-breaker", function()
    reset({ asthma = true })
    mock.reset(); ataxia_tryActiveCure()
    local n = #mock.sent_commands
    ataxia_tryActiveCure()
    expect(#mock.sent_commands).toBe(n)
  end)
end)

describe("NO-FITNESS marker -- name the thing holding our lock-breaker", function()
  it("appears when asthma is up and weariness blocks the cure", function()
    reset({ asthma = true, weariness = true })
    expect(ataxia_promptLocks():find("NO%-FITNESS") ~= nil).toBe(true)
  end)

  it("stays quiet when the cure is available", function()
    reset({ asthma = true })
    expect(ataxia_promptLocks():find("NO%-FITNESS")).toBe(nil)
  end)

  -- Cooldown is not an affliction; there is nothing for the player to act on, so no marker.
  it("stays quiet when the only blocker is the cooldown", function()
    reset({ asthma = true })
    ataxiaTemp.activeCureUsed = true
    expect(ataxia_promptLocks():find("NO%-FITNESS")).toBe(nil)
  end)
end)
