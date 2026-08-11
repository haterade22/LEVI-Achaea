--- test_basher_noflee.lua — Unit tests for no-flee area handling (Mnemosyne / World Tree)
-- Loads the real basher functions file and exercises ataxiaBasher_isNoFleeArea()
-- and ataxiaBasher_dangerLevel() to confirm no-flee areas shield instead of flee,
-- while normal areas still flee (regression).

local mock = require("mock_mudlet")

-- ----------------------------------------------------------------------------
-- Stub project globals the basher functions file expects
-- ----------------------------------------------------------------------------
function ataxiaEcho(...) end
function get_Battlerage() end
function ataxiaBasher_canShield() return true end
function table.contains(t, v)
  if type(t) ~= "table" then return false end
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

ataxia = ataxia or {}
ataxia.settings = ataxia.settings or { separator = "::" }
ataxia.vitals = { hpp = 100, maxhp = 5000, rage = 0 }
ataxia.afflictions = {}
ataxia.defences = {}

ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = ataxiaTemp or {}
gmcp = { Room = { Info = { area = "" } } }

local function setArea(a) gmcp.Room.Info.area = a end

-- Load the real basher functions (defines the functions under test)
local basher_file = "src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua"
local ok, err = pcall(dofile, basher_file)
if not ok then error("Failed to load basher functions file: " .. tostring(err)) end

-- Reset per-test state to a calm baseline
local function baseline()
  ataxia.vitals = { hpp = 100, maxhp = 5000, rage = 0 }
  ataxia.afflictions = {}
  ataxia.defences = {}
  ataxiaTemp.bashFlee = false
  ataxiaTemp.mnemLeftTimer = nil
  ataxiaBasher.inMnemosyne = false
  ataxiaBasher.fleeThresholdPct = 25
  ataxiaBasher.shieldThresholdPct = 40
  ataxiaBasher_dmgSamples = {}
  setArea("Test Bashing Area")
end

local function spikeDamage()
  -- Two samples well above the 60%-of-maxhp threshold (3000 for maxhp 5000)
  ataxiaBasher_dmgSamples = { { getEpoch(), 2000 }, { getEpoch(), 2000 } }
end

-- ----------------------------------------------------------------------------
describe("ataxiaBasher_isNoFleeArea", function()

  it("returns true for the World Tree", function()
    baseline()
    expect(ataxiaBasher_isNoFleeArea("the Fathomless Expanse of the World Tree")).toBeTrue()
  end)

  it("returns true when the Mnemosyne flag is set (empty area)", function()
    baseline()
    ataxiaBasher.inMnemosyne = true
    expect(ataxiaBasher_isNoFleeArea("")).toBeTrue()
  end)

  it("returns false for a normal area with the flag off", function()
    baseline()
    expect(ataxiaBasher_isNoFleeArea("Test Bashing Area")).toBeFalse()
  end)

end)

describe("ataxiaBasher_dangerLevel — no-flee behavior", function()

  it("normal area: low HP flees (regression)", function()
    baseline()
    ataxia.vitals.hpp = 20
    expect(ataxiaBasher_dangerLevel()).toBe("flee")
  end)

  it("normal area: extreme damage flees (regression)", function()
    baseline()
    ataxia.vitals.hpp = 80
    spikeDamage()
    expect(ataxiaBasher_dangerLevel()).toBe("flee")
  end)

  it("Mnemosyne: low HP shields instead of fleeing", function()
    baseline()
    ataxiaBasher.inMnemosyne = true
    setArea("")
    ataxia.vitals.hpp = 20
    expect(ataxiaBasher_dangerLevel()).toBe("shield")
  end)

  it("Mnemosyne: extreme damage shields instead of fleeing", function()
    baseline()
    ataxiaBasher.inMnemosyne = true
    setArea("")
    ataxia.vitals.hpp = 80
    spikeDamage()
    expect(ataxiaBasher_dangerLevel()).toBe("shield")
  end)

  it("Mnemosyne: healthy with no spike still attacks", function()
    baseline()
    ataxiaBasher.inMnemosyne = true
    setArea("")
    ataxia.vitals.hpp = 90
    expect(ataxiaBasher_dangerLevel()).toBe("attack")
  end)

end)

-- ── Mnemosyne presence is SURVEY-verified, never inferred from the area ──────────────────
-- A non-empty area is only a hint. DEMENTIA hallucinates a real environment/area while we are
-- still in the tower, and believing it drops no-flee mid-climb -- a death in an instance you
-- cannot flee. The flag is also serialized with ataxiaBasher, so it can be stale-ON in the real
-- world (suppressing flee where we want it). A free SURVEY settles both: trigger 351 confirms
-- ("You are in wading the Mnemosyne."), otherwise the window expires and we really did leave.
describe("Mnemosyne presence verification (dementia / stale flag)", function()

  local function armedCount()
    local n = 0
    for _ in pairs(mock.active_timers) do n = n + 1 end
    return n
  end

  it("asks SURVEY rather than clearing the flag on a possibly-hallucinated area", function()
    baseline(); mock.reset()
    ataxiaBasher.inMnemosyne = true
    ataxiaBasher_mnemLeftMaybe()
    expect(table.contains(mock.sent_commands, "survey")).toBeTrue()
    expect(ataxiaBasher.inMnemosyne).toBeTrue()                -- never cleared on a guess
    expect(ataxiaBasher_isNoFleeArea("Forest")).toBeTrue()     -- no-flee HELD during the window
  end)

  it("is a no-op when we are not flagged as in Mnemosyne", function()
    baseline(); mock.reset()
    ataxiaBasher.inMnemosyne = false
    ataxiaBasher_mnemLeftMaybe()
    expect(#mock.sent_commands).toBe(0)
  end)

  it("does not spam SURVEY while a window is already open", function()
    baseline(); mock.reset()
    ataxiaBasher.inMnemosyne = true
    ataxiaBasher_mnemLeftMaybe()
    ataxiaBasher_mnemLeftMaybe()
    ataxiaBasher_mnemLeftMaybe()
    expect(#mock.sent_commands).toBe(1)
  end)

  it("KEEPS the flag when SURVEY confirms the Mnemosyne (the dementia case)", function()
    baseline(); mock.reset()
    ataxiaBasher.inMnemosyne = true
    ataxiaBasher_mnemLeftMaybe()
    expect(armedCount()).toBe(1)
    ataxiaBasher_mnemStillHere()                  -- trigger 351 saw the truth line
    expect(armedCount()).toBe(0)                  -- pending clear cancelled
    expect(ataxiaBasher.inMnemosyne).toBeTrue()
    expect(ataxiaBasher_isNoFleeArea("Forest")).toBeTrue()
  end)

  it("clears the flag when nothing confirms in the window (really left / stale flag)", function()
    baseline(); mock.reset()
    ataxiaBasher.inMnemosyne = true
    ataxiaBasher_mnemLeftMaybe()
    ataxiaBasher_mnemLeftConfirm()                -- window expired, no 351
    expect(ataxiaBasher.inMnemosyne).toBeFalse()
    expect(ataxiaBasher_isNoFleeArea("Test Bashing Area")).toBeFalse()
  end)

  it("can ask again after a window closes", function()
    baseline(); mock.reset()
    ataxiaBasher.inMnemosyne = true
    ataxiaBasher_mnemLeftMaybe()
    ataxiaBasher_mnemLeftConfirm()
    ataxiaBasher.inMnemosyne = true               -- back inside
    ataxiaBasher_mnemLeftMaybe()
    expect(#mock.sent_commands).toBe(2)
  end)

  -- Creville's Legacy (attack 20% faster, INCURABLE dementia) fakes gmcp.Room.Info wholesale,
  -- so only a SURVEY naming a real place may take us out -- trigger 352 -> mnemLeftFor().
  it("SURVEY naming a real place takes us out (trigger 352)", function()
    baseline(); mock.reset()
    ataxiaBasher.inMnemosyne = true
    ataxiaBasher_mnemLeftMaybe()                  -- arms the ask
    ataxiaBasher_mnemLeftFor("the Northern Ithmia")
    expect(ataxiaBasher.inMnemosyne).toBeFalse()
    expect(armedCount()).toBe(0)                  -- definitive answer closes the window
  end)

  -- The blast-radius guard: an unrelated "You are in ..." line must never eject us mid-climb.
  it("ignores a survey answer we did not ask for", function()
    baseline(); mock.reset()
    ataxiaBasher.inMnemosyne = true               -- no mnemLeftMaybe() -> nothing pending
    ataxiaBasher_mnemLeftFor("the Northern Ithmia")
    expect(ataxiaBasher.inMnemosyne).toBeTrue()
    expect(ataxiaBasher_isNoFleeArea("the Northern Ithmia")).toBeTrue()
  end)

  it("consumes the pending ask, so a stale reply cannot eject us later", function()
    baseline(); mock.reset()
    ataxiaBasher.inMnemosyne = true
    ataxiaBasher_mnemLeftMaybe()
    ataxiaBasher_mnemStillHere()                  -- 351 answered: still inside
    ataxiaBasher_mnemLeftFor("the Northern Ithmia") -- a late/duplicate line
    expect(ataxiaBasher.inMnemosyne).toBeTrue()
  end)

end)

-- Any unambiguous Mnemosyne marker (wade start, wade status, boon screen, SURVEY) asserts
-- presence. Creville's Legacy grants INCURABLE dementia, so gmcp is a lie for the whole run --
-- these lines are the only truth, and asserting from all of them self-heals a missed run-start.
describe("ataxiaBasher_mnemHere — lifecycle markers assert presence", function()
  it("asserts presence from any marker, whatever gmcp claims", function()
    baseline(); mock.reset()
    setArea("the Northern Ithmia")          -- dementia's fake area
    ataxiaBasher_mnemHere("wade status")
    expect(ataxiaBasher.inMnemosyne).toBeTrue()
    expect(ataxiaBasher_isNoFleeArea()).toBeTrue()  -- no-flee ON despite the fake area
  end)

  it("cancels a pending 'did we leave?' ask (dementia can't eject us)", function()
    baseline(); mock.reset()
    ataxiaBasher.inMnemosyne = true
    ataxiaBasher_mnemLeftMaybe()            -- fake area opened a window
    ataxiaBasher_mnemHere("boon screen")    -- an authoritative yes lands
    expect(ataxiaBasher.inMnemosyne).toBeTrue()
    ataxiaBasher_mnemLeftFor("the Northern Ithmia") -- a late reply must not eject us
    expect(ataxiaBasher.inMnemosyne).toBeTrue()
  end)

  it("is idempotent (markers repeat every ripple)", function()
    baseline(); mock.reset()
    ataxiaBasher_mnemHere("wade started")
    ataxiaBasher_mnemHere("wade status")
    ataxiaBasher_mnemHere("boon screen")
    expect(ataxiaBasher.inMnemosyne).toBeTrue()
  end)
end)

-- targetList must be keyed on a STABLE key. Creville's Legacy (incurable dementia) makes gmcp
-- report a hallucinated real area for the whole climb, which would both scatter tower denizens
-- into a genuine hunting list AND make search_targets miss the tower's list (= nothing to
-- attack). Pin to "" inside -- the key the tower has always used.
describe("ataxiaBasher_areaKey", function()
  it("returns the real area when not in Mnemosyne", function()
    baseline(); setArea("Test Bashing Area")
    expect(ataxiaBasher_areaKey()).toBe("Test Bashing Area")
  end)

  it("pins to \"\" in Mnemosyne even when dementia fakes a real area", function()
    baseline(); ataxiaBasher.inMnemosyne = true
    setArea("the Northern Ithmia")   -- the hallucination
    expect(ataxiaBasher_areaKey()).toBe("")
  end)

  it("still pins to \"\" for the tower's genuine empty area", function()
    baseline(); ataxiaBasher.inMnemosyne = true
    setArea("")
    expect(ataxiaBasher_areaKey()).toBe("")
  end)
end)

--------------------------------------------------------------------------------
-- The Bard compose hold gates the attack (v4.7.232)
--------------------------------------------------------------------------------
-- User: "this should be done before bashing attack." An attack dispatched mid-compose
-- re-wields the SHIELD into the left hand, pulling the lyre out from under the compose --
-- which then fails with "How are you going to perform a song without your instrument
-- wielded?". The gate lives inside ataxiaBasher_attack rather than only in tryAttack because
-- several triggers call attack() directly.
--
-- Proved by SPYING ON dangerLevel: it is the first thing attack() does after the holds, so if
-- it never runs, the early return happened. Asserting on the gate any other way (reading the
-- source, checking a flag) would pass without the gate actually being wired in -- which is
-- exactly what a first version of this test did.
describe("bard compose hold -- attack refuses while the lyre is in hand", function()
  local danger

  local function spy()
    baseline()
    danger = 0
    ataxiaBasher_dangerLevel = function() danger = danger + 1; return "wait" end
  end

  it("does not reach the attack round while composing", function()
    spy()
    ataxiaTemp.bardComposeHold = true
    ataxiaBasher_attack()
    expect(danger).toBe(0)
    ataxiaTemp.bardComposeHold = nil
  end)

  it("attacks normally once the hold clears", function()
    spy()
    ataxiaTemp.bardComposeHold = nil
    ataxiaBasher_attack()
    expect(danger).toBe(1)
  end)

  -- FULL PHIAL LOCK (v4.7.235). Tree and shield are queued; every attack sends
  -- `queue addclearfull`, which clears the FULL queue -- exactly how the escape was thrown
  -- away in the Seasone death log. Swinging is not what saves us at IMP SLI AST ANO.
  it("does not reach the attack round during a full phial lock", function()
    spy()
    ataxiaTemp.phialHold = true
    ataxiaBasher_attack()
    expect(danger).toBe(0)
    ataxiaTemp.phialHold = nil
  end)

  it("resumes once the phial hold expires", function()
    spy()
    ataxiaTemp.phialHold = nil
    ataxiaBasher_attack()
    expect(danger).toBe(1)
  end)
end)

-- ============================================================================
-- v4.7.243 — escape mode, the TTL danger alarm, and the missing no-flee HP branch
-- ============================================================================

describe("escape mode gates the attack round (v4.7.243)", function()
  local danger
  local function spy()
    baseline()
    danger = 0
    ataxiaBasher_dangerLevel = function() danger = danger + 1; return "wait" end
  end

  -- The death log: three complete attack rounds between the disengage and "pull move lost".
  -- Every one of them sent `queue addclearfull`, which clears the FULL server queue -- so the
  -- swings were not merely wasted, they were actively deleting the escape.
  it("does not reach the attack round while we are leaving", function()
    spy()
    ataxiaTemp.escapeMode = true
    ataxiaBasher_attack()
    expect(danger).toBe(0)
    ataxiaTemp.escapeMode = nil
  end)

  it("swings again the moment escape mode clears", function()
    spy()
    ataxiaTemp.escapeMode = nil
    ataxiaBasher_attack()
    expect(danger).toBe(1)
  end)
end)

describe("the damage watchdog projects TIME TO DEATH (v4.7.243)", function()
  -- The fight that killed us: ~2,150 HP/s against an ~18,700 pool. Under the old test
  -- (net HP delta >= maxhp * 0.6) this could not fire at all.
  local function bigPool()
    baseline()
    ataxia.vitals = { hp = 18700, hpp = 100, maxhp = 18700, rage = 0 }
    ataxiaBasher_dmgSamples = {}
    ataxiaBasher_incSamples = {}
    ataxiaBasher.dangerTTL = 6
  end

  it("trips at ~2150 HP/s while we are still at ~64% health", function()
    bigPool()
    -- 3 seconds of real incoming, gross (what the game printed, before any healing).
    -- 8,600 over 3s = ~2,866 HP/s; at 12,000 HP that is ~4.2s to live, inside the 6s floor.
    -- We died at 1024. This alarm fires roughly eleven thousand HP earlier.
    ataxia.vitals.hp, ataxia.vitals.hpp = 12000, 64
    local t = getEpoch()
    ataxiaBasher_incSamples = { {t - 3, 2150}, {t - 2, 2150}, {t - 1, 2150}, {t, 2150} }
    expect(ataxiaBasher_isDamageRateExtreme()).toBeTrue()
    local ttl = ataxiaBasher_secondsToLive()
    expect(ttl ~= nil and ttl < 10).toBeTrue()
  end)

  it("the OLD absolute test could not have fired on the same fight", function()
    bigPool()
    local t = getEpoch()
    -- 8,600 damage over the window is well short of maxhp * 0.6 = 11,220.
    ataxiaBasher_dmgSamples = { {t - 3, 2150}, {t - 2, 2150}, {t - 1, 2150}, {t, 2150} }
    local total = 0
    for _, s in ipairs(ataxiaBasher_dmgSamples) do total = total + s[2] end
    expect(total < (ataxia.vitals.maxhp * 0.6)).toBeTrue()
  end)

  it("a normal fight does NOT trip it", function()
    bigPool()
    local t = getEpoch()
    ataxiaBasher_incSamples = { {t - 3, 300}, {t - 2, 300}, {t - 1, 300}, {t, 300} }
    expect(ataxiaBasher_isDamageRateExtreme()).toBeFalse()
  end)

  -- The structural flaw in the old feed: it recorded NET HP delta, so a prompt that took 2000
  -- and sipped 1500 recorded 500, and a net-positive prompt recorded nothing at all.
  it("healing no longer masks the incoming rate", function()
    bigPool()
    ataxia.vitals.hp, ataxia.vitals.hpp = 12000, 64
    local t = getEpoch()
    ataxiaBasher_incSamples = { {t - 3, 2150}, {t - 2, 2150}, {t - 1, 2150}, {t, 2150} }
    ataxiaBasher_dmgSamples = { {t - 3, 200}, {t - 2, 0}, {t - 1, 150} } -- what net delta saw
    expect(ataxiaBasher_isDamageRateExtreme()).toBeTrue()
  end)

  it("is silent when nothing is hitting us", function()
    bigPool()
    expect(ataxiaBasher_isDamageRateExtreme()).toBeFalse()
    expect(ataxiaBasher_secondsToLive()).toBe(nil)
  end)

  it("scales with the pool -- the same rate is survivable on a bigger one", function()
    bigPool()
    local t = getEpoch()
    ataxiaBasher_incSamples = { {t - 3, 500}, {t - 2, 500}, {t - 1, 500}, {t, 500} }
    expect(ataxiaBasher_isDamageRateExtreme()).toBeFalse() -- ~37s to live
    ataxia.vitals.hp = 2000
    expect(ataxiaBasher_isDamageRateExtreme()).toBeTrue()  -- ~4s to live
  end)
end)

-- The attack-gate describes above (compose, phial, escape mode) replace
-- ataxiaBasher_dangerLevel with a spy and never put it back -- test files share one Lua state,
-- so everything appended after them would silently be testing the spy instead of the code.
-- Reload the real implementation before testing the function itself.
do
  local okr, errr = pcall(dofile, basher_file)
  if not okr then error("Failed to reload basher functions: " .. tostring(errr)) end
end

describe("no-flee areas finally have an HP branch (v4.7.243)", function()
  -- The bug that let us swing Valafar at 1024 HP of an ~18,700 pool: `hpp <= fleePct` lived
  -- ONLY in the non-no-flee else-arm, so in the tower dangerLevel() returned "attack".
  local function tower()
    baseline()
    ataxiaBasher.inMnemosyne = true
    setArea("")
    ataxia.vitals = { hp = 1024, hpp = 5, maxhp = 18700, rage = 0 }
    ataxiaBasher_dmgSamples = {}
    ataxiaBasher_incSamples = {}
  end

  it("spends the round LEAVING when the swarm can get us out", function()
    tower()
    local asked = 0
    ataxia.mnemosyne = ataxia.mnemosyne or {}
    ataxia.mnemosyne.swarm = { disengage = function() asked = asked + 1; return true end }
    expect(ataxiaBasher_dangerLevel()).toBe("wait")
    expect(asked).toBe(1)
    ataxia.mnemosyne.swarm = nil
  end)

  -- Deliberate: a refusal means no validated route back, and fighting in place is then the best
  -- available answer. Muting the basher there would be lethal.
  it("keeps fighting when the swarm CANNOT get us out", function()
    tower()
    ataxia.mnemosyne = ataxia.mnemosyne or {}
    ataxia.mnemosyne.swarm = { disengage = function() return false end }
    ataxiaBasher_canShield = function() return false end
    expect(ataxiaBasher_dangerLevel()).toBe("attack")
    ataxiaBasher_canShield = function() return true end
    ataxia.mnemosyne.swarm = nil
  end)

  -- canShield() returns false whenever a room denizen is on the area target list -- i.e. every
  -- real tower fight. Gating the ALARM on it made the whole branch unreachable.
  it("the alarm no longer depends on canShield", function()
    tower()
    ataxia.vitals.hpp = 100
    local t = getEpoch()
    ataxiaBasher_incSamples = { {t - 3, 2150}, {t - 2, 2150}, {t - 1, 2150}, {t, 2150} }
    local asked = 0
    ataxia.mnemosyne = ataxia.mnemosyne or {}
    ataxia.mnemosyne.swarm = { disengage = function() asked = asked + 1; return true end }
    ataxiaBasher_canShield = function() return false end
    expect(ataxiaBasher_dangerLevel()).toBe("wait")
    expect(asked).toBe(1) -- the spike alone reached the disengage, at FULL HP
    ataxiaBasher_canShield = function() return true end
    ataxia.mnemosyne.swarm = nil
    ataxiaBasher_incSamples = {}
  end)
end)

-- ============================================================================
-- v4.7.253 -- a burst is not a rate
-- ============================================================================
--
-- v4.7.243 clamped the rate divisor to a MINIMUM of one second so a young fight would read at
-- its true rate. For a burst that extrapolates wildly: three blows inside 0.3s were reported as
-- three times the sustained rate. The live log shows the consequence -- "DYING FAST -- 83% and
-- ~5.7s to live" at 83% health, on essentially every prompt, with the escape ladder thrashing
-- between rooms instead of fighting.
describe("the damage watchdog does not mistake a burst for a rate", function()
  local function bigPool()
    baseline()
    ataxia.vitals = { hp = 12000, hpp = 64, maxhp = 18700, rage = 0 }
    ataxiaBasher_dmgSamples = {}
    ataxiaBasher_incSamples = {}
    ataxiaBasher.dangerTTL = 6
  end

  it("a tight burst does not trip it", function()
    bigPool()
    local t = getEpoch()
    -- Three ~1,000 blows landing together: real, survivable, and utterly normal in a crowd.
    ataxiaBasher_incSamples = { {t, 1000}, {t, 1000}, {t, 1000} }
    expect(ataxiaBasher_isDamageRateExtreme()).toBeFalse()
  end)

  it("...and reports it at the damped rate, not the clustered one", function()
    bigPool()
    local t = getEpoch()
    ataxiaBasher_incSamples = { {t, 1000}, {t, 1000}, {t, 1000} }
    -- 3,000 over the 3s minimum span = 1,000/s, not 3,000/s.
    expect(ataxiaBasher_incomingRate()).toBe(1000)
  end)

  -- The fight this alarm exists for is still caught: its samples genuinely span the window.
  it("sustained damage still trips it", function()
    bigPool()
    local t = getEpoch()
    ataxiaBasher_incSamples = { {t - 3, 2150}, {t - 2, 2150}, {t - 1, 2150}, {t, 2150} }
    expect(ataxiaBasher_isDamageRateExtreme()).toBeTrue()
  end)

  it("the minimum span is configurable", function()
    bigPool()
    local t = getEpoch()
    ataxiaBasher_incSamples = { {t, 3000} }
    expect(ataxiaBasher_incomingRate()).toBe(1000)   -- 3000 / 3
    ataxiaBasher_dmgMinSpan = 6
    expect(ataxiaBasher_incomingRate()).toBe(500)    -- 3000 / 6
    ataxiaBasher_dmgMinSpan = 3
  end)
end)
