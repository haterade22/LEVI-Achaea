--- test_bash_class_cure.lua -- the class active cure at 3 afflictions, while bashing (v4.7.484)
--
-- User, 2026-11-09: "we should be using our class active cures if we have 3 or more afflictions on
-- us especially if we have miracle boon." The user chose: bashing only, and 3 with or without the boon.
--
-- These tests run the real can(x)/003 and the real basher/001 round, and read the real pool of
-- afflictions that a random cure can take.

require("mock_mudlet")
local mock = require("mock_mudlet")

local clock = 1000
function getEpoch() return clock end

function ataxiaEcho(...) end
function get_Battlerage() end
function ataxia_saveSettings(...) end
function ataxiaBasher_canShield() return true end
function ataxia_paused() return ataxia.settings.paused == true end
function tAttack() return "bash 1" end
function table.contains(t, v)
  if type(t) ~= "table" then return false end
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

-- The real contract of affed (004_Aff_gains_losses): a cured stack sits at 0.
function affed(what)
  local v = ataxia.afflictions[what:lower()]
  if v == nil or v == false then return false end
  if type(v) == "number" then return v > 0 end
  return true
end

ataxia = { settings = { separator = ";" }, vitals = {}, afflictions = {}, defences = {} }
ataxiaBasher = {}
ataxiaTemp = {}
ataxiaTables = {}
battleRage_Timers = {}
target = 1
gmcp = {
  Room = { Info = { area = "" } },
  Char = { Status = { class = "Serpent", level = "80 " } },
  IRE = { Target = { Info = {} } },
}

for _, f in ipairs({
  "src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/can(x)/003_Lock_breakers.lua",
}) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

-- The real pool, cut out of 008: the rest of that file needs the whole tracker.
do
  local fh = assert(io.open("src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua", "r"))
  local src = fh:read("*a")
  fh:close()
  assert(loadstring(assert(src:match("(treeCurableAffsV3 = %b{})"))))()
end

ataxiaBasher_bashingFuncs = setmetatable({}, { __index = function() return "tAttack" end })

local THREE = { slickness = true, clumsiness = true, nausea = true }

local function copy(t)
  local out = {}
  for k, v in pairs(t) do out[k] = v end
  return out
end

local function with(extra)
  local out = copy(THREE)
  for k, v in pairs(extra) do out[k] = v end
  return out
end

local function reset(class, affs)
  mock.reset()
  clock = 1000
  ataxia.afflictions = affs or copy(THREE)
  ataxia.vitals = { bal = true, eq = true, mp = 5000, hpp = 100 }
  ataxia.settings = { separator = ";" }
  ataxia.defences = {}
  ataxia.mnemosyne = nil
  ataxiaTemp = { class = class }
  ataxiaTables = {}
  ataxiaBasher.enabled = true
  ataxiaBasher.paused = nil
  ataxiaBasher.dwAgeCap = nil
  attemptedLockBreak = nil
  attemptedPreLock = nil
  gmcp.Char.Status.class = class
end

local function round()
  mock.sent_commands = {}
  ataxiaBasher_assembleAttack()
  return table.concat(mock.sent_commands, ";")
end

local CURE_ROUND = "queue addclearfull freestand stand;shrugging"
local ATTACK_ROUND = "queue addclearfull freestand stand;bash 1"

describe("what counts toward the 3", function()
  it("counts afflictions that a random cure can take", function()
    reset("Serpent")
    expect(ataxia_randomCurableCount()).toBe(3)
  end)

  it("does not count NoRandomCure afflictions: the 2026-11-09 death's prompt holds only 3 that count", function()
    reset("Serpent", {
      laceratedthroat = true, prone = true, -- NoRandomCure
      slashedthroat = true, brokenleftleg = true, brokenleftarm = true,
    })
    expect(ataxia_randomCurableCount()).toBe(3)
  end)

  it("does not count a damaged limb, an unknown name, or a prediction", function()
    reset("Serpent", { damagedleftleg = true, somenewaffix = true, incoming_paralysis = true })
    expect(ataxia_randomCurableCount()).toBe(0)
  end)

  it("does not count a cured stack at 0", function()
    reset("Serpent", { slickness = true, clumsiness = true, unweavingspirit = 0 })
    expect(ataxia_randomCurableCount()).toBe(2)
  end)

  it("returns 0 and does not crash when the pool has not loaded", function()
    reset("Serpent")
    local saved = treeCurableAffsV3
    treeCurableAffsV3 = nil
    expect(ataxia_randomCurableCount()).toBe(0)
    treeCurableAffsV3 = saved
  end)
end)

describe("ataxia_loadCureCommand -- which cure, and when it stays idle", function()
  it("shrugs at 3, as the user asked", function()
    reset("Serpent")
    expect(ataxia_loadCureCommand()).toBe("shrugging")
  end)

  it("stays idle at 2", function()
    reset("Serpent", { slickness = true, clumsiness = true })
    expect(ataxia_loadCureCommand()).toBeNil()
  end)

  it("stays idle while the cure is on cooldown", function()
    reset("Serpent")
    ataxiaTemp.activeCureUsed = true
    expect(ataxia_loadCureCommand()).toBeNil()
  end)

  it("stays idle under the cure's blocker, however many afflictions we hold", function()
    reset("Serpent", with({ weariness = true }))
    expect(ataxia_loadCureCommand()).toBeNil()
  end)

  it("sends FITNESS only with asthma: without it the game still takes 2.8 s of balance", function()
    for _, class in ipairs({ "Blademaster", "Druid", "Infernal", "Monk", "Paladin", "Runewarden", "Sentinel" }) do
      reset(class)
      expect(ataxia_loadCureCommand()).toBeNil()
      reset(class, with({ asthma = true }))
      expect(ataxia_loadCureCommand()).toBe("fitness")
    end
  end)

  it("holds FITNESS and SHRUGGING with equilibrium down, as the user asked", function()
    reset("Serpent")
    ataxia.vitals.eq = false
    expect(ataxia_loadCureCommand()).toBeNil()
    reset("Monk", with({ asthma = true }))
    ataxia.vitals.eq = false
    expect(ataxia_loadCureCommand()).toBeNil()
  end)

  it("does not hold a cure that no probe has tested: an equilibrium attacker needs the round", function()
    reset("Alchemist")
    ataxia.vitals.eq = false
    expect(ataxia_loadCureCommand()).toBe("educe salt")
  end)

  it("boosts the Depthswalker's cure by default", function()
    reset("Depthswalker")
    expect(ataxia_loadCureCommand()).toBe("chrono accelerate boost")
  end)

  it("does not boost while prone: the boost cannot work", function()
    reset("Depthswalker", with({ prone = true }))
    expect(ataxia_loadCureCommand()).toBe("chrono accelerate")
  end)

  it("does not boost above the age cap, and honours a changed cap", function()
    reset("Depthswalker")
    ataxiaTables.depthswalker = { age = 401 }
    expect(ataxia_loadCureCommand()).toBe("chrono accelerate")
    ataxiaBasher.dwAgeCap = 500
    expect(ataxia_loadCureCommand()).toBe("chrono accelerate boost")
  end)

  it("holds the Fool while prone", function()
    reset("Jester", with({ prone = true }))
    expect(ataxia_loadCureCommand()).toBeNil()
    reset("Jester")
    expect(ataxia_loadCureCommand()).toBe("fling fool at me")
  end)

  it("holds a cure that costs mana when the mana is short", function()
    reset("Alchemist")
    ataxia.vitals.mp = 199
    expect(ataxia_loadCureCommand()).toBeNil()
    ataxia.vitals.mp = 200
    expect(ataxia_loadCureCommand()).toBe("educe salt")
  end)

  it("uses dragonheal for any dragon", function()
    reset("Black Dragon")
    expect(ataxia_loadCureCommand()).toBe("dragonheal")
  end)

  it("lets an Earth Lord erupt when not weary, and refuses when weary (the gate was inverted)", function()
    reset("Earth Elemental")
    expect(ataxia_loadCureCommand()).toBe("terran eruption")
    reset("Earth Elemental", with({ weariness = true }))
    expect(ataxia_loadCureCommand()).toBeNil()
  end)
end)

describe("the bash round", function()
  it("replaces the attack with the cure at 3 afflictions", function()
    reset("Serpent")
    expect(round()).toBe(CURE_ROUND)
  end)

  it("attacks normally at 2", function()
    reset("Serpent", { slickness = true, clumsiness = true })
    expect(round()).toBe(ATTACK_ROUND)
  end)

  it("sends the same command on each re-queue, so addclearfull does not lose it", function()
    reset("Serpent")
    expect(round()).toBe(CURE_ROUND)
    clock = clock + 0.3
    expect(round()).toBe(CURE_ROUND)
    clock = clock + 0.3
    expect(round()).toBe(CURE_ROUND)
  end)

  it("goes back to attacking when the game's use line arrives", function()
    reset("Serpent")
    expect(round()).toBe(CURE_ROUND)
    ataxiaTemp.activeCureUsed = true
    clock = clock + 0.3
    expect(round()).toBe(ATTACK_ROUND)
  end)

  it("sends the cure again when the ready line arrives", function()
    reset("Serpent")
    ataxiaTemp.activeCureUsed = true
    expect(round()).toBe(ATTACK_ROUND)
    ataxiaTemp.activeCureUsed = nil
    clock = clock + 10
    expect(round()).toBe(CURE_ROUND)
  end)

  it("does not use up a pending swarm pull: the cure round has no swing", function()
    reset("Serpent")
    local decorated = 0
    ataxia.mnemosyne = { swarm = { decorate = function(c) decorated = decorated + 1; return c end } }
    expect(round()).toBe(CURE_ROUND)
    expect(decorated).toBe(0)
    ataxiaTemp.activeCureUsed = true
    clock = clock + 0.3
    expect(round()).toBe(ATTACK_ROUND)
    expect(decorated).toBe(1)
  end)

  it("sends no cure round while paralysed: the free queue could not run it", function()
    reset("Serpent", with({ paralysis = true }))
    expect(round()).toBe("")
  end)

  it("leaves the Magi's round to magiBashing, so that the battlerage rides", function()
    reset("Magi")
    expect(ataxia_loadCureRound()).toBe("")
  end)

  it("still attacks if the rule raises an error", function()
    reset("Serpent")
    local saved = ataxia_loadCureRound
    ataxia_loadCureRound = function() error("boom") end
    expect(round()).toBe(ATTACK_ROUND)
    ataxia_loadCureRound = saved
  end)
end)

describe("a cure the game refuses must not stop the attacks", function()
  it("attacks again after 6 s with no use line, then waits 20 s", function()
    reset("Serpent")
    expect(round()).toBe(CURE_ROUND)
    for _ = 1, 3 do
      clock = clock + 1.9
      expect(round()).toBe(CURE_ROUND)
    end
    clock = clock + 0.4 -- 6.1 s after the first offer
    expect(round()).toBe(ATTACK_ROUND)
    clock = clock + 19
    expect(round()).toBe(ATTACK_ROUND)
    clock = clock + 2
    expect(round()).toBe(CURE_ROUND)
  end)

  it("does not read a pause in the offers as a refusal", function()
    reset("Serpent")
    expect(round()).toBe(CURE_ROUND)
    clock = clock + 8 -- a gate held us: no round ran
    expect(round()).toBe(CURE_ROUND)
    expect(ataxiaTemp.loadCureBackoffUntil).toBeNil()
  end)

  it("forgets the wait when the load falls below 3", function()
    reset("Serpent")
    expect(round()).toBe(CURE_ROUND)
    clock = clock + 2
    ataxia.afflictions.nausea = nil
    expect(round()).toBe(ATTACK_ROUND)
    expect(ataxiaTemp.loadCureSince).toBeNil()
  end)
end)

describe("the prompt path, for when no round runs", function()
  local function beat()
    mock.sent_commands = {}
    ataxia_loadCureHeartbeat()
    return table.concat(mock.sent_commands, ";")
  end

  it("sends the cure when balance and equilibrium are up", function()
    reset("Serpent")
    expect(beat()).toBe("shrugging")
  end)

  it("does nothing outside bashing: PvP keeps the lock-only rule", function()
    reset("Serpent")
    ataxiaBasher.enabled = false
    expect(beat()).toBe("")
  end)

  it("does nothing with equilibrium or balance down", function()
    -- An Alchemist: a Serpent's shrug has its own equilibrium hold, which would hide this gate.
    reset("Alchemist")
    ataxia.vitals.eq = false
    expect(beat()).toBe("")
    reset("Alchemist")
    ataxia.vitals.bal = false
    expect(beat()).toBe("")
  end)

  it("runs from the per-prompt heartbeat when there is no lock", function()
    reset("Serpent")
    mock.sent_commands = {}
    ataxia_lockBreakHeartbeat()
    expect(table.concat(mock.sent_commands, ";")).toBe("shrugging")
  end)

  it("does nothing while the basher or the system is paused", function()
    reset("Serpent")
    ataxiaBasher.paused = true
    expect(beat()).toBe("")
    reset("Serpent")
    ataxia.settings.paused = true
    expect(beat()).toBe("")
  end)

  it("sends once per 1.5 s", function()
    reset("Serpent")
    expect(beat()).toBe("shrugging")
    expect(beat()).toBe("")
  end)

  it("stands first when prone", function()
    reset("Serpent", with({ prone = true }))
    expect(beat()).toBe("stand;shrugging")
  end)

  it("waits while we are escaping, or for a phial or dissect queue", function()
    for _, hold in ipairs({ "escapeMode", "phialHold", "dissectHold" }) do
      reset("Serpent")
      ataxiaTemp[hold] = true
      expect(beat()).toBe("")
    end
  end)

  it("does not spend a resource while a tumble is in the air or still queued", function()
    reset("Serpent")
    ataxia.mnemosyne = { swarm = { moveLocked = function() return true end } }
    expect(beat()).toBe("")
    reset("Serpent")
    ataxia.mnemosyne = { swarm = { _retreatInFlight = function() return true end, state = "recovering" } }
    expect(beat()).toBe("")
  end)

  it("cures during a recovery, whose hold is only there to stop attacks", function()
    reset("Serpent")
    ataxiaTemp.swarmHold = true
    ataxia.mnemosyne = { swarm = { state = "recovering" } }
    expect(beat()).toBe("shrugging")
  end)

  it("waits for a pull or other hold outside a recovery", function()
    reset("Serpent")
    ataxiaTemp.swarmHold = true
    ataxia.mnemosyne = { swarm = { state = "pulling" } }
    expect(beat()).toBe("")
  end)
end)

describe("the lock-breaker keeps its place", function()
  it("sends one cure on a lock prompt, from the lock path", function()
    reset("Serpent", with({ asthma = true, anorexia = true }))
    mock.sent_commands = {}
    ataxia_lockBreakHeartbeat()
    local n = 0
    for _, c in ipairs(mock.sent_commands) do
      if c == "shrugging" then n = n + 1 end
    end
    expect(n).toBe(1)
    expect(ataxiaTemp.loadCureSince).toBeNil() -- the load path did not run
  end)

  it("the shield does not wait for a load cure: only a lock makes it due", function()
    reset("Serpent")
    expect(ataxia_lockBreakDue()).toBe(false)
  end)
end)
