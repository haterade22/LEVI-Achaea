--- test_facing_class.lua -- the two decisions of 2026-11-09 (kb/CONFLICTS.md #75 and #77)
--
-- #75: the anti-class defences and the curing set follow whoever hits us. Our target's class is
--      used only while no one has hit us.
-- #77: "Lock breaker and then shield": an automatic shield waits while a lock-breaker is due.
--
-- The REAL engine, NDB API, class helpers, anti-priorities, lock-breakers and combatQueue run here.
-- Every global this file changes is restored at the end.

local mock = require("mock_mudlet")

local before = {}
for k, v in pairs(_G) do before[k] = v end
local tableSave, tableLoad, ioExists, tableContains = table.save, table.load, io.exists, table.contains

local LEVI = "src_new/scripts/levi_ataxia/levi/"
local MONK = "src_new/triggers/levi_ataxia/for_levi/leviticus/determine_class/006_Monk_Class_Grab.lua"
local HIT = "Agathon quickly pricks you with his dirk."
local OTHER = "Agathon forms a lash of fire and strikes Saibel."

local now, handled
local function fresh()
  mock.reset()
  now = 1000
  handled = {}
  ataxia = { settings = { separator = ";" }, playersHere = {}, afflictions = {}, defences = {},
             vitals = { bal = true, eq = true }, channels = {}, curingprio = {} }
  ataxiaTemp = { class = "Alchemist" }
  classDetect, Algedonic = nil, {}
  pariah = {}
  ataxiaNDB = { players = {} }
  gmcp = { Char = { Status = { class = "Alchemist" } } }
  jestercheese, myaeon, preventriftlock, stoplatency, tdeliverance, havebomb = nil, nil, nil, nil, nil, nil
  mnemRimewrought, attemptedLockBreak, attemptedPreLock = nil, nil, nil
  cecho, ataxiaEcho, ataxia_boxEcho = function() end, function() end, function() end
  getEpoch = function() return now end
  raiseEvent = function() end
  registerAnonymousEventHandler = function() return 1 end
  killAnonymousEventHandler = function() end
  table.save, table.load = function() end, function() end
  io.exists = function() return false end
  table.contains = table.contains or function(t, v)
    for _, x in pairs(t) do if x == v then return true end end
    return false
  end
  affed = function(a) return ataxia.afflictions[a] end
  dofile(LEVI .. "ataxia/ataxia_ndb/003_ataxiaNDB_API.lua")
  dofile(LEVI .. "ataxia/ataxia/007_Pariah_things.lua")
  dofile(LEVI .. "levi_scripts/class_detect/001_Class_Detect_Engine.lua")
  dofile(LEVI .. "levi_scripts/algedonic_defense_1.0/001_Anti_Priorities.lua")
  dofile(LEVI .. "ataxia/can(x)/003_Lock_breakers.lua")
  dofile(LEVI .. "ataxia/ataxia/003_Queueing_Related.lua")
  ataxia_switchCuringsetSend = function(name) send("curingset switch " .. name, false) end
  ataxia_sendCuringPriority = function() end
  ataxia_bashProfileActive = function() return false end
  isDefenceForCurrentClass = function() return true end
  ataxia_defenceTakesPriority = function() return true end
  classDetect.config.apiLookupEnabled = false
  classDetect.config.echoSwitches = false
  target = "Saibel"
  ataxiaNDB.players.Saibel = { class = "Magi" }
  line = HIT
end

local function hit(name, class, text)
  line = text or (name .. " quickly pricks you with his dirk.")
  classDetect.setAttackerClass(name, class)
end

local function sent(cmd) return mock.was_sent(cmd) end

local ok, err = pcall(function()

describe("the class we are facing", function()
  it("is our target's class while no one has hit us", function()
    fresh()
    expect(ataxia_facingClass()).toBe("Magi")
  end)

  it("is the attacker's class once someone hits us, whoever we target", function()
    fresh()
    hit("Agathon", "Serpent")
    expect(ataxia_facingClass()).toBe("Serpent")
    expect(ataxia_targetClass()).toBe("magi")
  end)

  it("is the newest attacker's with two attackers; the set stays on normal", function()
    fresh()
    hit("Agathon", "Serpent")
    now = 1001
    hit("Froedine", "Monk")
    expect(ataxia_facingClass()).toBe("Monk")
    expect(classDetect.state.attackerClass).toBeNil()
    expect(classDetect.state.currentCuringset).toBe("normal")
    now = 1002
    hit("Agathon", "Serpent")
    expect(ataxia_facingClass()).toBe("Serpent")
  end)

  it("orders two hits of one packet, which read the same clock", function()
    fresh()
    hit("Agathon", "Serpent")
    hit("Froedine", "Monk")
    expect(ataxia_facingClass()).toBe("Monk")
  end)

  it("counts no line that does not name us", function()
    fresh()
    hit("Agathon", "Magi", OTHER)
    expect(classDetect.facingClass()).toBeNil()
    expect(ataxia_facingClass()).toBe("Magi")
    hit("Agathon", "Serpent", "Agathon fixes his gaze to yours and hisses a sharp command.")
    expect(classDetect.facingClass()).toBe("Serpent")
  end)

  it("does not take 'young' for 'you'", function()
    fresh()
    hit("Agathon", "Serpent", "Agathon pricks a young rat with his dirk.")
    expect(classDetect.facingClass()).toBeNil()
  end)

  it("falls back when an attacker leaves the room", function()
    fresh()
    hit("Agathon", "Serpent")
    now = 1001
    hit("Froedine", "Monk")
    gmcp.Room = { RemovePlayer = "Froedine" }
    classDetect.onPlayerLeft()
    expect(ataxia_facingClass()).toBe("Serpent")
    gmcp.Room = { RemovePlayer = "Agathon" }
    classDetect.onPlayerLeft()
    expect(ataxia_facingClass()).toBe("Magi")
  end)

  it("falls back when the combat ends", function()
    fresh()
    hit("Agathon", "Serpent")
    classDetect.resetToNormal()
    expect(classDetect.facingClass()).toBeNil()
    expect(ataxia_facingClass()).toBe("Magi")
  end)

  it("works after a reload kept a state table with no hits field", function()
    fresh()
    classDetect.state.hits = nil
    dofile(LEVI .. "levi_scripts/class_detect/001_Class_Detect_Engine.lua")
    hit("Agathon", "Serpent")
    expect(classDetect.facingClass()).toBe("Serpent")
  end)

  it("a known Shikudo's kick counts as a hit (trigger 006)", function()
    fresh()
    hit("Agathon", "Shikudo", "Agathon whips a staff at the side of your neck.")
    now = 1001
    hit("Froedine", "Bard")
    expect(ataxia_facingClass()).toBe("Bard")
    now = 1002
    matches = { "", "Agathon" }
    line = "Agathon lashes out with a high kick at your left leg."
    local src = assert(io.open(MONK)):read("*a")
    assert((loadstring or load)(src:match("%]%]%-%-\r?\n(.*)$"), MONK))()
    expect(ataxia_facingClass()).toBe("Shikudo")
  end)
end)

describe("a known Shikudo's kick, one attacker", function()
  it("counts as a hit, so the class stays after we change target", function()
    fresh()
    target = "Agathon"
    ataxiaNDB.players.Agathon = { class = "Shikudo" }
    classDetect.onTargetChanged()
    expect(classDetect.state.attackerClass).toBe("Shikudo")
    matches = { "", "Agathon" }
    line = "Agathon lashes out with a high kick at your left leg."
    local src = assert(io.open(MONK)):read("*a")
    assert((loadstring or load)(src:match("%]%]%-%-\r?\n(.*)$"), MONK))()
    target = "Saibel"
    expect(ataxia_facingClass()).toBe("Shikudo")
  end)
end)

describe("changing target", function()
  it("with no attacker still picks the target's set", function()
    fresh()
    classDetect.validCuringsets.magi = true
    classDetect.onTargetChanged()
    expect(sent("curingset switch magi")).toBeTrue()
    expect(classDetect.state.attackerName).toBe("Saibel")
  end)

  it("with an attacker changes neither the set nor the attacker", function()
    fresh()
    classDetect.validCuringsets.magi = true
    hit("Agathon", "Serpent")
    expect(classDetect.state.currentCuringset).toBe("serpent")
    mock.reset()
    classDetect.onTargetChanged()
    expect(#mock.sent_commands).toBe(0)
    expect(classDetect.state.currentCuringset).toBe("serpent")
    expect(classDetect.state.attackerName).toBe("Agathon")
    expect(classDetect.state.attackerClass).toBe("Serpent")
  end)

  it("with an attacker still looks up a class the NDB lacks", function()
    fresh()
    hit("Agathon", "Serpent")
    target = "Newguy"
    local asked
    classDetect.config.apiLookupEnabled = true
    classDetect.apiLookup = function(n) asked = n end
    classDetect.onTargetChanged()
    expect(asked).toBe("Newguy")
  end)

  it("an API answer with an attacker fills the NDB and leaves the set", function()
    fresh()
    classDetect.validCuringsets.druid = true
    hit("Agathon", "Serpent")
    target = "Newguy"
    now = 1010                                  -- past the 500 ms switch delay
    mock.reset()
    local savedYajl, savedOpen, savedRemove = yajl, io.open, os.remove
    yajl = { to_value = function() return { class = "Druid" } end }
    io.open = function() return { read = function() return "x" end, close = function() end } end
    os.remove = function() end
    classDetect.onApiResponse(nil, "/home/classDetect_newguy.json")
    yajl, io.open, os.remove = savedYajl, savedOpen, savedRemove
    expect(ataxiaNDB.players.Newguy.class).toBe("Druid")
    expect(#mock.sent_commands).toBe(0)
    expect(classDetect.state.currentCuringset).toBe("serpent")
  end)
end)

describe("the anti-class defences", function()
  local function handlers()
    Algedonic.AntiSerpent = function() handled[#handled + 1] = "Serpent" end
    Algedonic.AntiMagi = function() handled[#handled + 1] = "Magi" end
  end

  it("run the attacker's handler, not the target's", function()
    fresh()
    handlers()
    hit("Agathon", "Serpent")
    Algedonic.Prioritize()
    expect(handled[1]).toBe("Serpent")
  end)

  it("run the target's handler while no one has hit us", function()
    fresh()
    handlers()
    Algedonic.Prioritize()
    expect(handled[1]).toBe("Magi")
  end)

  it("reach the Unnamable handler under the class name the game uses", function()
    fresh()
    hit("Agathon", "Unnamable")
    ataxia.afflictions = { damagedhead = true, horror = 5 }
    Algedonic.Prioritize()
    expect(sent("curing prioaff horror5")).toBeTrue()
  end)

  it("run nothing with no attacker and no target", function()
    fresh()
    handlers()
    target = nil
    Algedonic.Prioritize()
    expect(#handled).toBe(0)
  end)

  it("a stale NDB class gives way at the first hit (Aerion, 2026-11-03)", function()
    fresh()
    handlers()
    target = "Aerion"
    ataxiaNDB.players.Aerion = { class = "Magi" }
    Algedonic.AntiBlademaster = function() handled[#handled + 1] = "Blademaster" end
    Algedonic._handlers.Blademaster = "AntiBlademaster"
    hit("Aerion", "Blademaster", "Aerion slashes into you with his blade.")
    Algedonic.Prioritize()
    expect(handled[1]).toBe("Blademaster")
    expect(ataxiaNDB.players.Aerion.class).toBe("Blademaster")
  end)
end)

describe("lock-breaker, then shield", function()
  local function impatient(extra)
    fresh()
    ataxia.afflictions = { impatience = true, asthma = true }
    for k, v in pairs(extra or {}) do ataxia.afflictions[k] = v end
  end

  it("AntiSerpent holds the shield while the lock-breaker is due; the prioaff still goes", function()
    impatient()
    Algedonic.AntiSerpent()
    expect(sent("curing prioaff impatience")).toBeTrue()
    expect(sent("cq all;touch shield")).toBeFalse()
    expect(ataxiaTemp.serpentShieldThrottle).toBeNil()
  end)

  it("the shield goes once the lock-breaker is used", function()
    impatient()
    Algedonic.AntiSerpent()
    ataxiaTemp.activeCureUsed = true
    Algedonic.AntiSerpent()
    expect(sent("cq all;touch shield")).toBeTrue()
    expect(ataxiaTemp.shieldWaitSince).toBeNil()
  end)

  it("a blocked lock-breaker does not hold the shield", function()
    impatient({ stupidity = true })
    Algedonic.AntiSerpent()
    expect(sent("cq all;touch shield")).toBeTrue()
  end)

  it("impatience alone has no lock-breaker due, so the shield goes", function()
    fresh()
    ataxia.afflictions = { impatience = true }
    Algedonic.AntiSerpent()
    expect(sent("cq all;touch shield")).toBeTrue()
  end)

  it("a cure held for equilibrium counts as due", function()
    impatient()
    ataxiaTemp.class = "Serpent"
    ataxia.vitals.eq = false
    expect(ataxia_activeCureHeldForEq()).toBeTrue()
    expect(ataxia_shieldWaitsForLockBreak()).toBeTrue()
  end)

  it("the wait ends after 4 s if the lock-breaker never fires", function()
    impatient()
    expect(ataxia_shieldWaitsForLockBreak()).toBeTrue()
    now = 1003.9
    expect(ataxia_shieldWaitsForLockBreak()).toBeTrue()
    now = 1004
    expect(ataxia_shieldWaitsForLockBreak()).toBeFalse()
    Algedonic.AntiSerpent()
    expect(sent("cq all;touch shield")).toBeTrue()
  end)

  it("a new lock-breaker episode starts a new wait", function()
    impatient()
    ataxia_shieldWaitsForLockBreak()
    now = 1005
    ataxia.afflictions = { impatience = true }
    expect(ataxia_shieldWaitsForLockBreak()).toBeFalse()
    ataxia.afflictions.asthma = true
    expect(ataxia_shieldWaitsForLockBreak()).toBeTrue()
  end)

  it("combatQueue's aeon path clears nothing while a lock-breaker is due", function()
    impatient()
    myaeon = true
    combatQueue()
    expect(sent("cq all;touch shield")).toBeFalse()
    expect(ataxiaTemp.cheeseAt).toBeNil()
    ataxiaTemp.activeCureUsed = true
    combatQueue()
    expect(sent("cq all;touch shield")).toBeTrue()
  end)

  it("AntiWaterlord still endures and sends no shield while the lock-breaker is due", function()
    fresh()
    ataxia.afflictions = { paralysis = true, asthma = true, slickness = true, anorexia = true }
    Algedonic.AntiWaterlord()
    expect(sent("endure")).toBeTrue()
    expect(sent("cq all;endure;touch shield")).toBeFalse()
    expect(sent("curing prioaff paralysis")).toBeTrue()
    ataxiaTemp.activeCureUsed = true
    Algedonic.AntiWaterlord()
    expect(sent("cq all;endure;touch shield")).toBeTrue()
  end)

  it("AntiPriest holds its shield too, and keeps its prioaff", function()
    impatient({ guilt = true, spiritburn = true })
    Algedonic.AntiPriest()
    expect(sent("touch shield")).toBeFalse()
    expect(sent("curing prioaff guilt")).toBeTrue()
  end)
end)

end)

for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
table.save, table.load, io.exists, table.contains = tableSave, tableLoad, ioExists, tableContains
mock.reset()
if not ok then error(err) end
