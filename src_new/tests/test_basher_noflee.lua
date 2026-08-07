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
end)
