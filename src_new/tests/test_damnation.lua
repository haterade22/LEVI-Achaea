--- test_damnation.lua -- Paladin Damnation defence (algedonic_defense_1.0/002)
--
-- Damnation is broken head + (two of pyre/guilt/spiritburn, OR burning level 5). Until the
-- 2026-08-19 curing change this file's whole response was unreachable twice over:
--
--   * every priority write targeted the BARE name (`curing priority burning 1`), and the
--     default table carried an explicit entry at every stack level, so the base it wrote was
--     never the value SSC consulted; and
--   * `ataxia.afflictions.burning` was never a number -- the stack decoder tested the
--     second-to-last character of the name -- so `burnLevel` read 0 forever and the burn
--     route could not even be detected.
--
-- Neither failure produced a single line of output. These tests pin both directions.

require("mock_mudlet")
local mock = require("mock_mudlet")

ataxia = ataxia or {}
ataxia.afflictions = {}
ataxia.curingprio = {}
ataxia.settings = ataxia.settings or {}
ataxia.settings.bashcuring = { active = false }
ataxiaTemp = ataxiaTemp or {}
Algedonic = Algedonic or {}
function Algedonic.Echo() end
function ataxia_boxEcho() end
function ataxiaNDB_getClass() return "Paladin" end
target = "somepaladin"

assert(pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua"),
  "Failed to load default curing prios")
assert(pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/ataxia/002_Prio_Management.lua"),
  "Failed to load prio management")
assert(pcall(dofile, "src_new/scripts/levi_ataxia/levi/levi_scripts/algedonic_defense_1.0/002_Damnation_Defence.lua"),
  "Failed to load damnation defence")

local DEFAULTS = ataxia_defaultCuringPrios()

local function reset(affs)
  mock.reset()
  ataxia.afflictions = affs or {}
  ataxia.curingprio = {}
  ataxiaTemp.damnationPrios = nil
  -- Both debounce tables are file-scope globals and would otherwise swallow a write that a
  -- previous test in this file already made for the same affliction.
  prioWaitfor = {}
  prioWaitrestore = {}
  ataxia.prioThrottle.commands = {}
  ataxia.prioThrottle.sentThisSecond = 0
  ataxia.prioThrottle.windowStart = 0
end

-- A full escalation is up to six writes against a 4/sec throttle, so the tail is QUEUED
-- rather than sent in the same instant. Queued is accepted -- ataxia_drainPrioQueue empties
-- it on a 0.25s timer -- so both places count.
local function sentContains(needle)
  for _, c in ipairs(mock.sent_commands) do
    if tostring(c):find(needle, 1, true) then return true end
  end
  for _, e in ipairs(ataxia.prioThrottle.commands or {}) do
    if tostring(e.cmd):find(needle, 1, true) then return true end
  end
  return false
end

-- ...but "nothing happened" must mean nothing was sent AND nothing was queued.
local function nothingSent()
  return #mock.sent_commands == 0 and #(ataxia.prioThrottle.commands or {}) == 0
end

-- ─── the alarm ──────────────────────────────────────────────────────────────

describe("checkDamnationThreat -- the burn route", function()
  it("fires at burning 5 with a broken head", function()
    -- Impossible before the decoder fix: burnLevel was permanently 0.
    reset({ damagedhead = true, burning = 5 })
    local threat, level = checkDamnationThreat()
    expect(threat).toBeTrue()
    expect(level).toBe("critical")
  end)

  it("warns rather than screaming at burning 3", function()
    reset({ damagedhead = true, burning = 3 })
    local threat, level = checkDamnationThreat()
    expect(threat).toBeTrue()
    expect(level).toBe("warning")
  end)

  it("says nothing while the head is whole", function()
    reset({ burning = 5 })
    expect(checkDamnationThreat()).toBeFalse()
  end)
end)

-- ─── the escalation ─────────────────────────────────────────────────────────

describe("Algedonic.AntiPaladin -- escalates the LEVEL, never the base", function()
  it("raises burning4 and burning5 on a broken head with burns", function()
    reset({ damagedhead = true, burning = 3 })
    Algedonic.AntiPaladin()
    expect(sentContains("curing priority burning4 1")).toBeTrue()
    expect(sentContains("curing priority burning5 1")).toBeTrue()
  end)

  it("NEVER writes a bare burning priority", function()
    -- A bare write sets the BASE, which is exactly what burning4/burning5 override -- so the
    -- old `curing priority burning 1` could not take effect at the levels it was written for.
    reset({ damagedhead = true, burning = 4 })
    Algedonic.AntiPaladin()
    for _, c in ipairs(mock.sent_commands) do
      if tostring(c):match("curing priority burning%s+%d") then
        error("wrote the BASE burning priority: " .. tostring(c))
      end
    end
  end)

  it("raises pyre3, not bare pyre, at pyre 3 with a broken head", function()
    reset({ damagedhead = true, pyre = 3 })
    Algedonic.AntiPaladin()
    expect(sentContains("curing priority pyre3 1")).toBeTrue()
    for _, c in ipairs(mock.sent_commands) do
      if tostring(c):match("curing priority pyre%s+%d") then
        error("wrote the BASE pyre priority: " .. tostring(c))
      end
    end
  end)

  it("writes no priority at pyre 3 while the head is whole", function()
    -- The static pyre3 = 2 already outranks the 3 this used to write.
    reset({ pyre = 3 })
    Algedonic.AntiPaladin()
    expect(sentContains("curing priority pyre")).toBeFalse()
  end)

  it("still reaches guilt and the disembowel check at pyre 3 without a head break", function()
    -- That branch used to `return`, so both were skipped in a routine state.
    reset({ pyre = 3, guilt = true })
    Algedonic.AntiPaladin()
    expect(sentContains("curing priority guilt 3")).toBeTrue()
  end)

  it("drops brokenhead -- a name the default table cannot restore", function()
    reset({ damagedhead = true, burning = 3 })
    Algedonic.AntiPaladin()
    expect(sentContains("brokenhead")).toBeFalse()
  end)

  it("escalates the COMPONENT route -- head + guilt + pyre, the most common kill", function()
    -- Two of pyre/guilt/spiritburn with a broken head IS the kill, and nothing used to
    -- escalate any of its members: the old chain returned out of the head branch before the
    -- guilt write could run, so guilt was raised only when the head was WHOLE.
    reset({ damagedhead = true, guilt = true, pyre = 1 })
    Algedonic.AntiPaladin()
    expect(sentContains("curing priority guilt 2")).toBeTrue()
    expect(sentContains("curing priority pyre 3")).toBeTrue()
    expect(sentContains("curing priority damagedhead 2")).toBeTrue()
  end)

  it("escalates spiritburn on the component route too", function()
    reset({ damagedhead = true, spiritburn = true, guilt = true })
    Algedonic.AntiPaladin()
    expect(sentContains("curing priority spiritburn 2")).toBeTrue()
    expect(sentContains("curing priority guilt 2")).toBeTrue()
  end)

  it("STILL raises the head cure on the pyre-3 branch", function()
    -- That branch used to return before reaching the head cure -- in the single most
    -- dangerous state the function models.
    reset({ damagedhead = true, pyre = 3 })
    Algedonic.AntiPaladin()
    expect(sentContains("curing priority pyre3 1")).toBeTrue()
    expect(sentContains("curing priority damagedhead 2")).toBeTrue()
    expect(sentContains("curing priority mangledhead 2")).toBeTrue()
  end)

  it("answers BOTH routes at once when both are live", function()
    reset({ damagedhead = true, pyre = 3, burning = 5 })
    Algedonic.AntiPaladin()
    expect(sentContains("curing priority pyre3 1")).toBeTrue()
    expect(sentContains("curing priority burning5 1")).toBeTrue()
    expect(sentContains("curing priority damagedhead 2")).toBeTrue()
  end)

  it("is inert against a non-Paladin", function()
    reset({ damagedhead = true, burning = 5 })
    local saved = ataxiaNDB_getClass
    ataxiaNDB_getClass = function() return "Serpent" end
    Algedonic.AntiPaladin()
    ataxiaNDB_getClass = saved
    expect(nothingSent()).toBeTrue()
  end)
end)

-- ─── the restore ────────────────────────────────────────────────────────────

describe("Algedonic.RestorePaladin -- the half that never existed", function()
  it("puts every escalated name back to its table value once the head heals", function()
    -- Without this, one Damnation scare left burning ahead of paralysis in the active
    -- curingset permanently -- and the writes only became permanent when they started landing.
    reset({})
    ataxiaTemp.damnationPrios = true
    ataxia.curingprio = {
      pyre3 = 1, burning4 = 1, burning5 = 1, damagedhead = 2, mangledhead = 2,
    }
    Algedonic.RestorePaladin()
    expect(sentContains("curing priority burning4 " .. DEFAULTS.burning4)).toBeTrue()
    expect(sentContains("curing priority burning5 " .. DEFAULTS.burning5)).toBeTrue()
    expect(sentContains("curing priority pyre3 " .. DEFAULTS.pyre3)).toBeTrue()
    expect(ataxiaTemp.damnationPrios).toBeNil()
  end)

  it("holds while the head is still broken", function()
    reset({ damagedhead = true })
    ataxiaTemp.damnationPrios = true
    ataxia.curingprio = { burning5 = 1 }
    Algedonic.RestorePaladin()
    expect(nothingSent()).toBeTrue()
    expect(ataxiaTemp.damnationPrios).toBeTrue()
  end)

  it("does nothing when nothing diverges from the table", function()
    reset({})
    ataxia.curingprio = { burning5 = DEFAULTS.burning5, pyre3 = DEFAULTS.pyre3 }
    Algedonic.RestorePaladin()
    expect(nothingSent()).toBeTrue()
  end)

  it("recovers an escalation that outlived a reload", function()
    -- The ataxiaTemp latch does not survive a relog, and ataxia_resetOnLogin -- long cited
    -- as the backstop -- has no callers. ataxia.curingprio DOES survive (saved to disk,
    -- refilled by trigger 719), so a recorded value that disagrees with the table is proof
    -- of an escalation nothing is left to undo.
    reset({})
    ataxiaTemp.damnationPrios = nil
    ataxia.curingprio = { burning5 = 1 }
    Algedonic.RestorePaladin()
    expect(sentContains("curing priority burning5 " .. DEFAULTS.burning5)).toBeTrue()
  end)

  it("ignores a recorded 0 -- that is 'never confirmed', not 'escalated'", function()
    -- ataxia_getPrio answers 0 for a name the server never echoed back, so a fresh profile
    -- must not read as permanently escalated.
    reset({})
    ataxia.curingprio = { burning5 = 0, pyre3 = 0, guilt = 0 }
    Algedonic.RestorePaladin()
    expect(nothingSent()).toBeTrue()
  end)

  it("HOLDS the latch while the bash set is active, instead of stranding the escalation", function()
    -- ataxia_restorePrio routes through ataxia_sendCuringPriority, which drops stored
    -- affliction writes on the bash set. Clearing the latch anyway left the escalation in
    -- the PvP set forever the moment a Damnation scare was followed by a bashing session.
    reset({})
    ataxiaTemp.damnationPrios = true
    ataxia.settings.bashcuring = { active = true }
    local saved = ataxia_bashProfileActive
    ataxia_bashProfileActive = function() return true end
    Algedonic.RestorePaladin()
    ataxia_bashProfileActive = saved
    ataxia.settings.bashcuring = { active = false }
    expect(nothingSent()).toBeTrue()
    expect(ataxiaTemp.damnationPrios).toBeTrue()
  end)

  it("is wired into RestoreSwaps ahead of its prioritySwaps guard", function()
    -- A source-level pin, because that call site IS the feature: AntiPaladin is a class
    -- handler rather than a toggleable swap, so nothing else would ever undo its writes.
    -- Loading 001_Anti_Priorities here would drag in most of the combat system, and the
    -- failure being guarded is someone deleting one line.
    local f = io.open("src_new/scripts/levi_ataxia/levi/levi_scripts/algedonic_defense_1.0/001_Anti_Priorities.lua")
    local body = f:read("*a"); f:close()
    expect(body:find("Algedonic.RestorePaladin()", 1, true) ~= nil).toBeTrue()
    -- ...and before the early return, or it only runs when the swap table happens to exist.
    local callAt = body:find("Algedonic.RestorePaladin()", 1, true)
    local guardAt = body:find("if not ataxia.prioritySwaps then return end", 1, true)
    expect(callAt < guardAt).toBeTrue()
  end)
end)

-- Leave shared state clean: test files run in one interpreter.
ataxia.afflictions = {}
ataxia.curingprio = {}
ataxiaTemp.damnationPrios = nil
target = nil
