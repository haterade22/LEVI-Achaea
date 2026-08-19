--- test_bash_curing_profile.lua -- PvE bashing curing profile (ataxia/008)
--
-- The delta table is pure data, so these assert INVARIANTS rather than individual
-- numbers: the numbers are a judgement call and will be tuned from live logs, but the
-- orderings below are the entire point of the profile and must never silently invert.
--
-- Derived from the 2026-07-31 earth-wyrm death log: cracked ribs (prio 9) beat a broken
-- right arm (prio 10) for the salve balance, and six of seven mineral eats went to
-- paranoia/shyness instead of potash. See the header of 008_Bash_Curing_Profile.lua.

require("mock_mudlet")
local mock = require("mock_mudlet")

ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}
ataxia.curingprio = ataxia.curingprio or {}
function ataxiaEcho() end
function ataxia_saveSettings() end

assert(pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua"),
  "Failed to load default curing prios")
assert(pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/ataxia/002_Prio_Management.lua"),
  "Failed to load prio management")
assert(pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/ataxia/008_Bash_Curing_Profile.lua"),
  "Failed to load bash curing profile")

local DEFAULTS = ataxia_defaultCuringPrios()
local BASH = ataxia_bashCuringPrios()
local PARKED = ataxiaBashProfile.PARKED

local LIMBS = {
  "brokenleftarm", "brokenrightarm", "brokenleftleg", "brokenrightleg",
  "damagedleftarm", "damagedrightarm", "damagedleftleg", "damagedrightleg",
  "mangledleftarm", "mangledrightarm", "mangledleftleg", "mangledrightleg",
}
-- Everything here is cured by the SAME salve balance that mending and restoration need.
local SALVE_RIVALS = {
  "crackedribs", "skullfractures", "torntendons", "wristfractures",
  "concussion", "mildtrauma", "serioustrauma", "scalded",
}
local PAIRS = {
  {"brokenleftarm", "brokenrightarm"}, {"brokenleftleg", "brokenrightleg"},
  {"damagedleftarm", "damagedrightarm"}, {"damagedleftleg", "damagedrightleg"},
  {"mangledleftarm", "mangledrightarm"}, {"mangledleftleg", "mangledrightleg"},
}

local function effective(aff) return BASH[aff] or DEFAULTS[aff] end

-- Stack overrides that sit at <= 2 in the PvP table because of a KILL CONDITION (broken
-- head + burning 5 = the Paladin's Damnation), NOT because they stop us acting. A denizen
-- cannot perform Damnation, so PvE deliberately flattens them back to the family base.
-- Keep this list minimal: every name in it is one the "never demoted" invariant stops
-- guarding.
local PVP_KILL_ESCALATION = { burning4 = true, burning5 = true, pyre3 = true }

describe("bash curing profile -- delta table integrity", function()
  it("every delta names an affliction the default table knows", function()
    -- Guards the crippled*/broken*/damaged* naming split the codebase is genuinely
    -- inconsistent about: a typo here would be a priority written for an aff that
    -- never fires, and nothing in-game would say so.
    for aff in pairs(BASH) do
      if DEFAULTS[aff] == nil then error("unknown affliction in bash table: " .. aff) end
    end
  end)

  it("no delta repeats the default value", function()
    -- A no-op delta is a mistake, not a decision -- it costs an install command and
    -- reads as an intentional PvE choice when it is not.
    for aff, val in pairs(BASH) do
      if DEFAULTS[aff] == val then
        error(aff .. " is " .. val .. " in both tables -- drop it from the delta")
      end
    end
  end)

  it("every priority is a positive integer", function()
    for aff, val in pairs(BASH) do
      if type(val) ~= "number" or val < 1 or val % 1 ~= 0 then
        error(aff .. " has a non-integer priority: " .. tostring(val))
      end
    end
  end)
end)

describe("bash curing profile -- the orderings that ARE the profile", function()
  it("every limb outranks every salve competitor", function()
    -- THE headline invariant. In the death log crackedribs(9) beat brokenrightarm(10)
    -- for the salve while the arm was refusing every attack.
    for _, limb in ipairs(LIMBS) do
      for _, rival in ipairs(SALVE_RIVALS) do
        if not (effective(limb) < effective(rival)) then
          error(limb .. " (" .. effective(limb) .. ") must outrank " ..
            rival .. " (" .. effective(rival) .. ")")
        end
      end
    end
  end)

  it("left and right limbs are symmetric", function()
    -- The PvP table has damagedleftarm at 11 and damagedrightarm at 13 for no reason.
    -- Restoration always heals the LEFT limb of a pair first, so an asymmetric priority
    -- just makes the second cure arrive later than it needs to.
    for _, p in ipairs(PAIRS) do
      if effective(p[1]) ~= effective(p[2]) then
        error(p[1] .. " (" .. effective(p[1]) .. ") /= " .. p[2] .. " (" .. effective(p[2]) .. ")")
      end
    end
  end)

  it("no limb is parked", function()
    for _, limb in ipairs(LIMBS) do
      expect(effective(limb) < PARKED).toBeTrue()
    end
  end)

  it("the junk mental spray is parked", function()
    -- These are what the earth wyrm actually applies, and each cure costs a potash.
    for _, aff in ipairs({"paranoia", "shyness", "depression", "masochism", "claustrophobia"}) do
      expect(BASH[aff] ~= nil).toBeTrue()
      expect(BASH[aff] >= PARKED).toBeTrue()
    end
  end)

  it("nothing that stops us acting is ever demoted", function()
    -- Anything the PvP table put at 2 or better is a total-incapacitation or ticking-
    -- death aff (aeon, prone, the writhe band, heartseed). PvE does not change that.
    for aff, val in pairs(DEFAULTS) do
      if val <= 2 and BASH[aff] and BASH[aff] > val and not PVP_KILL_ESCALATION[aff] then
        error(aff .. " demoted from " .. val .. " to " .. BASH[aff] .. " -- it blocks all action")
      end
    end
  end)

  it("keeps the affs that gate our cure channels ahead of the limbs", function()
    -- anorexia blocks eating (no potash); slickness blocks salves (no mending);
    -- paralysis blocks tree. A limb cure is worthless if the channel is shut.
    for _, blocker in ipairs({"anorexia", "slickness", "paralysis"}) do
      for _, limb in ipairs(LIMBS) do
        expect(effective(blocker) < effective(limb)).toBeTrue()
      end
    end
  end)

  it("no burn level outbids a limb for the salve balance in PvE", function()
    -- This is what the burning4/burning5 deltas buy. Burning is salve-cured, so inheriting
    -- the PvP escalation (burning5 = 2) would put a DoT ahead of a broken arm that is
    -- refusing every attack -- the exact failure this profile was written to fix.
    for _, aff in ipairs({"burning", "burning4", "burning5"}) do
      for _, limb in ipairs(LIMBS) do
        if not (effective(limb) < effective(aff)) then
          error(aff .. " (" .. effective(aff) .. ") must not outrank " ..
            limb .. " (" .. effective(limb) .. ")")
        end
      end
    end
  end)

  it("leaves the Mnemosyne truelock affs alone", function()
    -- The Seasone phial truelock is asthma + anorexia, and the counter in mnemosyne/004
    -- re-touches tree only while BOTH persist. Demoting asthma would lengthen it.
    expect(BASH["asthma"]).toBeNil()
  end)
end)

describe("stacking afflictions -- base and override", function()
  -- Achaea (2026-08-19): a BARE `curing priority <aff> <n>` is the BASE for every stack
  -- count with no entry of its own; `<aff><N> <n>` overrides at exactly N. These pin the
  -- invariants that new rule creates.
  local STACK_AFFS = {
    horror = true, pyre = true, unweavingspirit = true, unweavingmind = true,
    unweavingbody = true, temperedsanguine = true, temperedcholeric = true,
    temperedmelancholic = true, temperedphlegmatic = true, pressure = true,
    crackedribs = true, torntendons = true, skullfractures = true,
    wristfractures = true, burning = true, crescendo = true,
  }

  local function overrides(tbl)
    local out = {}
    for aff, val in pairs(tbl) do
      local base, n = aff:match("^(%a+)(%d+)$")
      if base then out[#out + 1] = { aff = aff, base = base, n = tonumber(n), val = val } end
    end
    table.sort(out, function(a, b) return a.aff < b.aff end)
    return out
  end

  it("every stack override has a BASE entry to fall back to", function()
    -- THE invariant the new semantics create. Deleting a base out from under its overrides
    -- silently hands every unenumerated level back to the server's own default.
    for _, o in ipairs(overrides(DEFAULTS)) do
      if DEFAULTS[o.base] == nil then
        error(o.aff .. " overrides a base (" .. o.base .. ") that is not in the table")
      end
    end
  end)

  it("every stack override names an affliction we model as stacking", function()
    -- Catches `burnings5` and friends. Nothing parses a REJECTED curing priority, so a
    -- typo here is invisible in game.
    for _, o in ipairs(overrides(DEFAULTS)) do
      if not STACK_AFFS[o.base] then
        error(o.aff .. " is not a known stacking affliction")
      end
    end
  end)

  it("no override repeats its own base", function()
    -- The direct analogue of "no delta repeats the default": an override equal to the base
    -- is dead weight, and dead weight at every level is what made the bases unreachable.
    for _, o in ipairs(overrides(DEFAULTS)) do
      if DEFAULTS[o.base] == o.val then
        error(o.aff .. " is " .. o.val .. ", the same as its base -- drop it")
      end
    end
  end)

  it("escalation is monotone -- more stacks is never LESS urgent", function()
    -- Encodes "it gets worse as it stacks" as a machine check. Would have caught the old
    -- shape, where a base of 19 sat above five levels at 9.
    local byBase = {}
    for _, o in ipairs(overrides(DEFAULTS)) do
      byBase[o.base] = byBase[o.base] or {}
      table.insert(byBase[o.base], o)
    end
    for base, list in pairs(byBase) do
      table.sort(list, function(a, b) return a.n < b.n end)
      local prev = DEFAULTS[base]
      for _, o in ipairs(list) do
        if o.val > prev then
          error(base .. o.n .. " (" .. o.val .. ") is LESS urgent than the level below it (" ..
            prev .. ")")
        end
        prev = o.val
      end
    end
  end)

  it("resolves a level with no override of its own to the base", function()
    -- burning3 has no entry; the effective priority is the base, and that is what
    -- ataxia_restorePrio must write rather than concatenating nil.
    expect(ataxia_defaultPrioAff("burning3")).toBe(DEFAULTS["burning"])
    expect(ataxia_defaultPrioAff("burning5")).toBe(DEFAULTS["burning5"])
    expect(ataxia_defaultPrioAff("nosuchaff9")).toBeNil()
    expect(ataxia_defaultPrioAff(nil)).toBeNil()
  end)

  it("ataxia_restorePrio survives a name the table does not know", function()
    local ok = pcall(ataxia_restorePrio, "brokenhead")
    expect(ok).toBeTrue()
    ok = pcall(ataxia_restorePrio, "burning3")
    expect(ok).toBeTrue()
  end)
end)

describe("bash curing profile -- switching", function()
  local function reset()
    mock.reset()
    ataxia.settings.bashcuring = {
      enabled = true, installed = true, setname = "bash", restoreTo = "normal", active = false,
    }
    classDetect = nil
  end

  local function lastSent()
    return mock.sent_commands[#mock.sent_commands]
  end

  it("switches to the bash set on enable and back on disable", function()
    reset()
    ataxia_bashProfileOn()
    expect(lastSent()).toBe("curingset switch bash")
    expect(ataxia_bashProfileActive()).toBeTrue()
    ataxia_bashProfileOff()
    expect(lastSent()).toBe("curingset switch normal")
    expect(ataxia_bashProfileActive()).toBeFalse()
  end)

  it("is idempotent -- a second enable sends nothing", function()
    -- "basher enabled" is raised from six different places; a duplicate switch would
    -- also overwrite restoreTo with the bash set's own name.
    reset()
    ataxia_bashProfileOn()
    local n = #mock.sent_commands
    ataxia_bashProfileOn()
    expect(#mock.sent_commands).toBe(n)
  end)

  it("does nothing until installed", function()
    reset()
    ataxia.settings.bashcuring.installed = false
    ataxia_bashProfileOn()
    expect(#mock.sent_commands).toBe(0)
    expect(ataxia_bashProfileActive()).toBeFalse()
  end)

  it("restores the set classDetect had chosen, not a hardcoded normal", function()
    reset()
    classDetect = { state = { currentCuringset = "knights" } }
    ataxia_bashProfileOn()
    ataxia_bashProfileOff()
    expect(lastSent()).toBe("curingset switch knights")
  end)

  it("never records the bash set as its own restore target", function()
    -- A reload mid-bash can leave classDetect reporting `bash` as current; restoring to
    -- it would strand us on the PvE table for the next PvP fight.
    reset()
    classDetect = { state = { currentCuringset = "bash" } }
    ataxia_bashProfileOn()
    expect(ataxia.settings.bashcuring.restoreTo).toBe("normal")
  end)
end)

describe("bash curing profile -- held for the whole Mnemosyne wade", function()
  local function reset(inTower)
    mock.reset()
    ataxia.settings.bashcuring = {
      enabled = true, installed = true, setname = "bash", restoreTo = "normal", active = false,
    }
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = inTower and true or false
    classDetect = nil
  end
  local function lastSent() return mock.sent_commands[#mock.sent_commands] end

  it("holds the set when the basher is disabled inside the tower", function()
    -- The whole point. A tower DEATH raises "basher disabled" (twice: onDeath plus the
    -- explorer's stop) while we are still standing in a hostile ripple -- flipping back to the
    -- PvP table there is the worst possible timing, since we re-engage at low HP with limbs
    -- broken. Seen live in the 2026-07-31 death log.
    reset(true)
    ataxia_bashProfileOn()
    expect(lastSent()).toBe("curingset switch bash")
    local n = #mock.sent_commands
    ataxia_bashProfileOnBasherDisabled()
    expect(#mock.sent_commands).toBe(n)          -- nothing sent
    expect(ataxia_bashProfileActive()).toBeTrue() -- still on the PvE table
  end)

  it("survives the repeated disables a tower death actually produces", function()
    reset(true)
    ataxia_bashProfileOn()
    local n = #mock.sent_commands
    ataxia_bashProfileOnBasherDisabled()
    ataxia_bashProfileOnBasherDisabled()
    ataxia_bashProfileOnBasherDisabled()
    expect(#mock.sent_commands).toBe(n)
    expect(ataxia_bashProfileActive()).toBeTrue()
  end)

  it("releases only when we actually leave the tower", function()
    reset(true)
    ataxia_bashProfileOn()
    ataxia_bashProfileOnBasherDisabled()
    expect(ataxia_bashProfileActive()).toBeTrue()
    ataxiaBasher.inMnemosyne = false  -- ataxiaBasher_mnemLeft would have done this
    ataxia_bashProfileOff()           -- ...and raised "mnemosyne left"
    expect(lastSent()).toBe("curingset switch normal")
    expect(ataxia_bashProfileActive()).toBeFalse()
  end)

  it("arms on tower entry even with the basher off", function()
    -- "mnemosyne entered" fires from the wade-start line, wade status, the boon screen or
    -- SURVEY -- none of which imply the basher is running yet.
    reset(true)
    ataxiaBasher.enabled = false
    ataxia_bashProfileOn()
    expect(lastSent()).toBe("curingset switch bash")
    expect(ataxia_bashProfileActive()).toBeTrue()
  end)

  it("still switches off on a normal out-of-tower basher stop", function()
    reset(false)
    ataxia_bashProfileOn()
    ataxia_bashProfileOnBasherDisabled()
    expect(lastSent()).toBe("curingset switch normal")
    expect(ataxia_bashProfileActive()).toBeFalse()
  end)

  it("lets an explicit `aconfig bashcuring off` win even inside the tower", function()
    -- Only the EVENT is suppressed, never the function -- an explicit user command and the
    -- ataxia_sendDefaultPrios bail-out must both still be able to leave the set.
    reset(true)
    ataxia_bashProfileOn()
    ataxia_bashProfileToggle("off")
    expect(lastSent()).toBe("curingset switch normal")
    expect(ataxia_bashProfileActive()).toBeFalse()
  end)
end)

describe("bash curing profile -- stored-priority write guard", function()
  local function armed(on)
    mock.reset()
    -- The 4/sec throttle carries `sentThisSecond` across tests, and the mock clock does not
    -- advance -- so without this the window never rolls and a later test in the file starts
    -- with the budget already spent, queueing its sends instead of making them.
    ataxia.prioThrottle.commands = {}
    ataxia.prioThrottle.sentThisSecond = 0
    ataxia.prioThrottle.windowStart = 0
    ataxia.settings.bashcuring = {
      enabled = true, installed = true, setname = "bash", restoreTo = "normal", active = on,
    }
  end

  it("drops stored affliction priorities while the bash set is active", function()
    -- Otherwise a PvP swap permanently mutates the bash set, and ataxia_restorePrio
    -- then writes the PVP default back into it -- the profile rots one aff at a time.
    armed(true)
    ataxia_sendCuringPriority("curing priority paralysis 25", false)
    expect(#mock.sent_commands).toBe(0)
  end)

  it("drops a batched write if ANY sub-command is a stored priority", function()
    armed(true)
    ataxia_sendCuringPriority("curing priority slickness 25;curing priority paralysis 25", false)
    expect(#mock.sent_commands).toBe(0)
  end)

  it("still allows defence priorities and the health/mana sip toggle", function()
    armed(true)
    ataxia_sendCuringPriority("curing priority defence rebounding 25", false)
    ataxia_sendCuringPriority("curing priority health", false)
    expect(#mock.sent_commands).toBe(2)
  end)

  it("drops a STACK-SUFFIXED priority while the bash set is active", function()
    -- The headline hole: the pattern was letters-only, so `burning5` did not match and the
    -- write sailed into whichever curingset was active. Reachable from the UI, since
    -- trigger 717 makes `burning5` its own row in ataxia_showPrios.
    armed(true)
    ataxia_sendCuringPriority("curing priority burning5 2", false)
    expect(#mock.sent_commands).toBe(0)
  end)

  it("drops a batch mixing a base and an override", function()
    armed(true)
    ataxia_sendCuringPriority("curing priority burning 9;curing priority burning5 2", false)
    expect(#mock.sent_commands).toBe(0)
  end)

  it("passes everything through when the bash set is not active", function()
    armed(false)
    ataxia_sendCuringPriority("curing priority paralysis 25", false)
    ataxia_sendCuringPriority("curing priority burning5 2", false)
    expect(#mock.sent_commands).toBe(2)
  end)
end)

-- Leave the shared Lua state clean: test files run in one interpreter, and an active
-- profile would silently arm the write guard for every test file sorted after this one.
ataxia.settings.bashcuring.active = false
classDetect = nil
if ataxiaBasher then ataxiaBasher.inMnemosyne = false end
