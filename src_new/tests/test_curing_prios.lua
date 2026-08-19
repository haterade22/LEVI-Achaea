--- test_curing_prios.lua -- the priority-WRITE layer (v4.7.276)
--
-- The v4.7.274 review found that every runtime writer of a stacking-affliction priority had
-- been inert for as long as it had existed, and that none of them had a single test. A
-- priority write fails SILENTLY in Achaea -- no error, no echo, and trigger 719 simply never
-- confirms -- so these are the only place a regression here can surface.

require("mock_mudlet")
local mock = require("mock_mudlet")

ataxia = ataxia or {}
ataxia.afflictions = {}
ataxia.curingprio = {}
ataxia.settings = ataxia.settings or {}
ataxia.settings.bashcuring = { active = false }
ataxia.prioritySwaps = nil
ataxiaTemp = ataxiaTemp or {}
Algedonic = Algedonic or {}
target = "someone"

function ataxiaEcho() end
function ataxia_boxEcho() end
function ataxiaNDB_getClass() return "Magi" end
function ataxiaNDB_Exists() return true end
function ataxia_resetSwaps()
  ataxia.prioritySwaps = { magi = { active = true } }
end
function ataxia_tryVultureTalon() end

assert(pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua"),
  "Failed to load default curing prios")
assert(pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/ataxia/002_Prio_Management.lua"),
  "Failed to load prio management")
assert(pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/004_Aff_gains_losses.lua"),
  "Failed to load aff gains/losses")

local DEFAULTS = ataxia_defaultCuringPrios()

local function reset(affs)
  mock.reset()
  ataxia.afflictions = affs or {}
  ataxia.curingprio = {}
  prioWaitfor = {}
  prioWaitrestore = {}
  ataxia.prioThrottle.commands = {}
  ataxia.prioThrottle.sentThisSecond = 0
  ataxia.prioThrottle.windowStart = 0
  ataxia.settings.bashcuring = { active = false }
end

local function allSent()
  local out = {}
  for _, c in ipairs(mock.sent_commands) do out[#out + 1] = tostring(c) end
  for _, e in ipairs(ataxia.prioThrottle.commands or {}) do out[#out + 1] = tostring(e.cmd) end
  return out
end

local function sentContains(needle)
  for _, c in ipairs(allSent()) do
    if c:find(needle, 1, true) then return true end
  end
  return false
end

-- ─── the base/override contract ─────────────────────────────────────────────

describe("stacking priorities -- every family is complete", function()
  it("every affliction we model as stacking has a BASE entry", function()
    -- The INVERSE of the "every override has a base" check in test_bash_curing_profile.
    -- unweavingspirit and crescendo sat in ataxia_stackAffs() with no entry at all until
    -- v4.7.276, so they ran on the server's own default while their siblings were tuned --
    -- and unweavingspirit is one of the three components of the Psion kill.
    for _, aff in ipairs(ataxia_stackAffs()) do
      if DEFAULTS[aff] == nil then
        error(aff .. " is a stacking affliction with no priority entry")
      end
    end
  end)

  it("keeps the three unweaving families symmetric", function()
    -- psion.md: the kill is ANY TWO unweaves at level 3+. Pricing two of three leaves the
    -- third as the cheap way through, and spirit is cured on a different balance (smoke).
    for _, fam in ipairs({ "unweavingbody", "unweavingmind", "unweavingspirit" }) do
      expect(DEFAULTS[fam]).toBe(25)
      for lvl = 3, 5 do expect(DEFAULTS[fam .. lvl]).toBe(2) end
    end
  end)
end)

-- ─── the balance a priority actually competes on ────────────────────────────

describe("stacking priorities -- the balance they contend for", function()
  it("no EAT-cured stack outranks the lock core", function()
    -- pyre is bellwort/cuprum, an EAT -- not the salve its old comment claimed. Pricing
    -- pyre3 at 2 put it above paralysis (3), whose own comment reads "Bloodroot has NO herb
    -- competition". A priority only means something beside the others on its own balance.
    local lockCore = { "paralysis", "slickness", "scytherus", "pacified" }
    for _, eat in ipairs({ "pyre", "pyre3" }) do
      for _, core in ipairs(lockCore) do
        if not (DEFAULTS[core] < DEFAULTS[eat]) then
          error(eat .. " (" .. DEFAULTS[eat] .. ") must not outrank " ..
            core .. " (" .. DEFAULTS[core] .. ") -- both are eaten")
        end
      end
    end
  end)

  it("no SALVE-cured burn level outbids anorexia for the salve", function()
    -- Burning is mending-body; anorexia is the softlock core and blocks eating outright.
    -- A burn is only lethal with a broken head, which the DYNAMIC layer answers, so the
    -- static value must not buy that at the cost of every fire fight.
    --
    -- Deliberately NOT asserted against the limbs: PvP ranks limbs low on purpose (see
    -- memory/curing.md), which is the whole reason the PvE profile exists. The limb
    -- invariant is tested there, against the EFFECTIVE PvE table.
    for _, burn in ipairs({ "burning", "burning4", "burning5" }) do
      if not (DEFAULTS.anorexia <= DEFAULTS[burn]) then
        error(burn .. " (" .. DEFAULTS[burn] .. ") outbids anorexia (" ..
          DEFAULTS.anorexia .. ") for the salve balance")
      end
    end
  end)

  it("keeps every stack override out of the total-incapacitation band", function()
    -- Priority 2 is aeon / prone / heartseed / the writhe family -- things that stop us
    -- acting at all. A kill-condition escalation belongs BELOW them, and the dynamic layer
    -- has the reserved slot 1 for the moment one actually becomes lethal.
    for aff, val in pairs(DEFAULTS) do
      local base = aff:match("^(%a+)%d+$")
      if base and DEFAULTS[base] and val <= 2 and base ~= "unweavingbody"
         and base ~= "unweavingmind" and base ~= "unweavingspirit" then
        error(aff .. " sits at " .. val .. ", inside the total-incapacitation band")
      end
    end
  end)
end)

-- ─── ataxia_sendDefaultPrios ordering ───────────────────────────────────────

describe("ataxia_sendDefaultPrios", function()
  it("emits a family BASE before its overrides", function()
    -- An explicit correctness claim with nothing asserting it: switching the sort to key on
    -- affliction name, or dropping it, breaks the ordering invisibly.
    reset({})
    local prios, e = ataxia_defaultCuringPrios(), {}
    for a, v in pairs(prios) do e[#e + 1] = "curing priority " .. a .. " " .. v end
    table.sort(e)
    local seenBase = {}
    for _, cmd in ipairs(e) do
      local name = cmd:match("^curing priority (%S+)")
      local base, lvl = name:match("^(%a+)(%d+)$")
      if base and prios[base] then
        if not seenBase[base] then
          error(base .. lvl .. " is emitted before its base " .. base)
        end
      else
        seenBase[name] = true
      end
    end
  end)

  it("leaves the bash set before rewriting the whole table", function()
    reset({})
    local left = false
    ataxia_bashProfileActive = function() return true end
    ataxia_bashProfileOff = function() left = true end
    ataxia_sendDefaultPrios()
    ataxia_bashProfileActive, ataxia_bashProfileOff = nil, nil
    expect(left).toBeTrue()
  end)
end)

-- ─── the throttle counts COMMANDS, not calls ────────────────────────────────

describe("ataxia.prioThrottle", function()
  it("charges a semicolon batch for every command in it", function()
    -- The server cap is 5 COMMANDS a second. Several call sites batch three at a time, and
    -- each used to cost one slot -- so a batch overlapping a `reset prios` could put 7+
    -- commands into one second. Overflow is dropped server-side with no signal.
    reset({})
    ataxia_sendCuringPriority("curing priority a 1;curing priority b 2;curing priority c 3", false)
    expect(ataxia.prioThrottle.sentThisSecond).toBe(3)
  end)

  it("queues rather than exceeding the cap", function()
    reset({})
    ataxia_sendCuringPriority("curing priority a 1;curing priority b 2", false)
    ataxia_sendCuringPriority("curing priority c 3;curing priority d 4", false)
    ataxia_sendCuringPriority("curing priority e 5", false)
    expect(#mock.sent_commands).toBe(2)
    expect(#ataxia.prioThrottle.commands).toBe(1)
  end)

  it("lets an oversized batch through rather than queueing it forever", function()
    -- It cannot be split here, so holding it would be worse than one second slightly over.
    reset({})
    ataxia_sendCuringPriority(
      "curing priority a 1;curing priority b 2;curing priority c 3;" ..
      "curing priority d 4;curing priority e 5;curing priority f 6", false)
    expect(#mock.sent_commands).toBe(1)
  end)
end)

-- ─── ataxia_defaultPrioAff / restorePrio ────────────────────────────────────

describe("ataxia_defaultPrioAff", function()
  it("falls back to the family base for a level with no entry", function()
    expect(ataxia_defaultPrioAff("burning3")).toBe(DEFAULTS.burning)
    expect(ataxia_defaultPrioAff("burning5")).toBe(DEFAULTS.burning5)
  end)

  it("is case-insensitive, matching ataxia_stackAff", function()
    -- Trigger 717 writes ataxia.curingprio keys from server tokens; two writers of one
    -- table with different casing split the key silently.
    expect(ataxia_defaultPrioAff("Burning5")).toBe(DEFAULTS.burning5)
    expect(ataxia_defaultPrioAff("BURNING3")).toBe(DEFAULTS.burning)
  end)

  it("returns nil for a name the table does not know", function()
    expect(ataxia_defaultPrioAff("brokenhead")).toBeNil()
    expect(ataxia_defaultPrioAff("nosuchaff9")).toBeNil()
    expect(ataxia_defaultPrioAff(nil)).toBeNil()
  end)

  it("restorePrio never builds a command with a nil priority", function()
    reset({})
    expect(pcall(ataxia_restorePrio, "brokenhead")).toBeTrue()
    expect(sentContains("nil")).toBeFalse()
  end)
end)

-- ─── the write guard ────────────────────────────────────────────────────────

describe("writesStoredAffPrio via ataxia_sendCuringPriority", function()
  local function armed(on)
    reset({})
    ataxia.settings.bashcuring = { active = on }
    ataxia_bashProfileActive = function() return on end
  end

  it("drops a stack-suffixed write on the bash set", function()
    armed(true)
    ataxia_sendCuringPriority("curing priority burning5 2", false)
    expect(#mock.sent_commands).toBe(0)
    ataxia_bashProfileActive = nil
  end)

  it("still passes defence writes and the sip toggle", function()
    armed(true)
    ataxia_sendCuringPriority("curing priority defence blindness reset", false)
    ataxia_sendCuringPriority("curing priority health", false)
    expect(#mock.sent_commands).toBe(2)
    ataxia_bashProfileActive = nil
  end)
end)

-- ─── the anti-Magi burn swap ────────────────────────────────────────────────

describe("Algedonic ApplySwaps/RestoreSwaps -- the burn family", function()
  -- Second-largest behaviour change in the release and it had no coverage: its file is the
  -- one test_damnation deliberately refuses to load. Loading it here with the stubs above.
  local loaded = pcall(dofile,
    "src_new/scripts/levi_ataxia/levi/levi_scripts/algedonic_defense_1.0/001_Anti_Priorities.lua")

  it("loads", function() expect(loaded).toBeTrue() end)

  it("raises the WHOLE burn family, never just the base", function()
    -- A bare write sets the BASE, which burning4/burning5 override -- so raising only the
    -- base leaves the two most dangerous levels LESS urgent than the three below them.
    if not loaded then return end
    reset({ dehydrated = true, burning = 2 })
    ataxia.prioritySwaps = { magi = { active = true } }
    ataxia.curingprio = { dehydrated = 9 }
    Algedonic.ApplySwaps("dehydrated")
    expect(sentContains("curing priority burning 1")).toBeTrue()
    expect(sentContains("curing priority burning4 1")).toBeTrue()
    expect(sentContains("curing priority burning5 1")).toBeTrue()
  end)

  it("restores every name it raised", function()
    if not loaded then return end
    reset({})
    ataxia.prioritySwaps = { magi = { active = true } }
    ataxia.curingprio = { burning = 1, burning4 = 1, burning5 = 1 }
    Algedonic.RestoreSwaps("dehydrated")
    expect(sentContains("curing priority burning " .. DEFAULTS.burning)).toBeTrue()
    expect(sentContains("curing priority burning4 " .. DEFAULTS.burning4)).toBeTrue()
    expect(sentContains("curing priority burning5 " .. DEFAULTS.burning5)).toBeTrue()
  end)

  it("no longer forces our burn level to 1 on restore", function()
    -- The old restore wrote `ataxia.afflictions.burning = 1` -- a client-state lie, harmless
    -- only while the decoder never produced a real level, and now the Damnation alarm's
    -- only input.
    if not loaded then return end
    reset({ burning = 4 })
    ataxia.prioritySwaps = { magi = { active = true } }
    ataxia.curingprio = { burning = 1 }
    Algedonic.RestoreSwaps("dehydrated")
    expect(ataxia.afflictions.burning).toBe(4)
  end)

  it("splits the frozen/shivering write into real commands", function()
    -- Was `curing priority frozen 2 shivering 2` -- two afflictions in one command, which
    -- is not a syntax the game accepts, and rejection here is silent.
    if not loaded then return end
    reset({ frozen = true })
    ataxia.prioritySwaps = { magi = { active = true } }
    ataxia.curingprio = { frozen = 15 }
    Algedonic.ApplySwaps("hypothermia")
    expect(sentContains("curing priority frozen 2;curing priority shivering 2")).toBeTrue()
    expect(sentContains("frozen 2 shivering")).toBeFalse()
  end)

  it("Stack_My_Affs survives a herb with no counter, and floors at zero", function()
    -- whatcures carries ["pear"] = {"pressure"}; mystack had no pear key, so passing BASE
    -- names made this throw on every pressure gain. And the decrement path only went live
    -- in v4.7.274, so unmatched cures could walk the counters negative.
    if not loaded then return end
    -- whatcures/mystack are bootstrapped by the inline init in _groups.yaml, which the test
    -- harness does not run. Mirrored here with the SAME divergence the real pair had.
    Algedonic.whatcures = { kelp = { "asthma" }, pear = { "pressure" } }
    Algedonic.mystack = { kelp = 0 }
    expect(pcall(Algedonic.Stack_My_Affs, true, "pressure")).toBeTrue()
    Algedonic.Stack_My_Affs(false, "pressure")
    Algedonic.Stack_My_Affs(false, "pressure")
    expect(Algedonic.mystack.pear).toBe(0)
  end)

  it("guards the humour and crescendo compares the decoder made reachable", function()
    -- `temperedphlegmatic >= 6` and `crescendo >= 4` had no nil guard, so they threw
    -- whenever the affliction was absent -- which is most of the time.
    if not loaded then return end
    reset({})
    expect(pcall(Algedonic.AntiAlchemist)).toBeTrue()
    expect(pcall(Algedonic.AntiBard)).toBeTrue()
  end)

  it("prioaffs horror by the server's own token, not a parenthesised guess", function()
    -- Was `curing prioaff horror (5)` -- parenthesised, with a space, a form nothing else
    -- in the game accepts. Doubly dead before, since horror was never a number either.
    if not loaded then return end
    reset({ damagedhead = true, horror = 5 })
    Algedonic.AntiUnnameable()
    expect(sentContains("curing prioaff horror5")).toBeTrue()
    expect(sentContains("(5)")).toBeFalse()
  end)
end)

-- Leave shared state clean: test files run in one interpreter.
ataxia.afflictions = {}
ataxia.curingprio = {}
ataxia.settings.bashcuring = { active = false }
ataxia_bashProfileActive = nil
ataxia_bashProfileOff = nil
target = nil
