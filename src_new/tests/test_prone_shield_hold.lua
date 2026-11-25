--- test_prone_shield_hold.lua -- v4.7.524: a prone shield holds the attack rounds until it rises.
---
--- Prone, ataxiaBasher_queueShield leaves `queue addclear freestand touch shield` (held until we stand)
--- and `queue prepend eqbal stand` in the server queue. Every attack round sends `queue addclearfull`
--- (or `queue addclear freestand|eqbal`), which deletes them (HELP 4.6.1). The fix: one bounded hold,
--- gated in the send wrapper (misc_scripts/031), which every offence's line passes.
---
--- Runs the REAL wrapper (031), the REAL hold (ataxia/003), the REAL basher (basher/001) and the REAL
--- body of trigger 022. `ataxia_rawSend` is the recorder: it is what reaches the game. Every global these
--- files create or change is put back at the end (one Lua state for all test files).

local mock = require("mock_mudlet")

local before = {}
for k, v in pairs(_G) do before[k] = v end
local beforeAtaxia, beforeBasher, beforeTemp = {}, {}, {}
ataxia = ataxia or {}
ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = ataxiaTemp or {}
for k, v in pairs(ataxia) do beforeAtaxia[k] = v end
for k, v in pairs(ataxiaBasher) do beforeBasher[k] = v end
for k, v in pairs(ataxiaTemp) do beforeTemp[k] = v end

local TL = dofile("src_new/tests/trigger_lib.lua")
local LEVI = "src_new/scripts/levi_ataxia/levi/ataxia/"
local QUEUEING = LEVI .. "ataxia/003_Queueing_Related.lua"
local TRAITS = LEVI .. "misc_scripts/031_Traits.lua"
local BASHER = LEVI .. "basher/001_Bashing_Functions.lua"
local SHIELDED = "src_new/triggers/levi_ataxia/for_levi/leviticus/022_SHIELDED.lua"
local SHIELD_LINE = "You touch the tattoo and a nearly invisible magical shield forms around you."

local function read(p) local f = assert(io.open(p, "r")); local s = f:read("*a"); f:close(); return s end
local function body(p) return assert((loadstring or load)(read(p):match("%]%]%-%-\r?\n(.*)$"), p)) end

local clock, raw, said, swung = 1000, {}, {}, 0
getEpoch = function() return clock end
ataxiaEcho = function(m) said[#said + 1] = tostring(m) end
cecho = function() end
tempTimer = function() return 1 end
get_Battlerage = function() end
ataxiaBasher_canShield = function() return false end
registerAnonymousEventHandler = function() return 1 end

-- The wrapper wraps whatever `send` is when 031 loads; an earlier file may have left its flag set.
ataxia_sendWrapped, ataxia_rawSend = nil, nil
send = function(c) raw[#raw + 1] = c end
for _, f in ipairs({ QUEUEING, TRAITS, BASHER }) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end
local shieldedBody = body(SHIELDED)

local function fresh()
  clock, raw, said, swung = 1000, {}, {}, 0
  for k in pairs(ataxiaTemp) do ataxiaTemp[k] = nil end
  ataxia.settings = { separator = ";" }
  ataxia.vitals = { hpp = 100, hp = 11400, maxhp = 11400 }
  ataxia.afflictions, ataxia.defences = {}, {}
  ataxia.denizensHere = {}
  ataxia.mnemosyne = nil
  ataxiaBasher.enabled, ataxiaBasher.inMnemosyne, ataxiaBasher.manual = true, false, true
  ataxiaBasher.lastStand, ataxiaBasher.lastStandRelease = nil, nil
  ataxiaBasher.fleeThresholdPct, ataxiaBasher.shieldThresholdPct = 25, 40
  ataxiaBasher.paused = nil
  ataxia_effHp, ataxia_effHpp, mnemBravado, mnemRimewrought = nil, nil, nil, nil
  bashStats_recordIncoming = nil
  ataxiaBasher_isDamageRateExtreme = function() return false end
  ataxiaBasher_checkPlayerFlee = function() return false end
  -- The class round, as assembleAttack sends it (basher/001: `queue addclearfull freestand stand;...`).
  ataxiaBasher_assembleAttack = function()
    swung = swung + 1
    send("queue addclearfull freestand stand;bite 101")
  end
  ataxiaBasher_bashingFuncs = { Serpent = "ataxiaBasher_serpentBashing" }
  gmcp = { Room = { Info = { area = "", num = 5150 } }, Char = { Status = { class = "Serpent" } } }
end

local function rawHas(cmd)
  for _, c in ipairs(raw) do if c == cmd then return true end end
  return false
end
local function rawFind(piece)
  for _, c in ipairs(raw) do if c:find(piece, 1, true) then return true end end
  return false
end
local function saidHas(piece)
  for _, m in ipairs(said) do if m:find(piece, 1, true) then return true end end
  return false
end

-- Prone, through the real helper and the real wrapper: the two entries go out and the hold starts.
local function proneShield()
  ataxia.afflictions.prone = true
  local ok = ataxiaBasher_queueShield(false)
  expect(ok).toBe(true)
  expect(rawHas("queue addclear freestand touch shield")).toBe(true)
  expect(rawHas("queue prepend eqbal stand")).toBe(true)
  raw, said = {}, {}
end

describe("v4.7.524 -- a prone shield holds the attack rounds", function()
  it("the basher's next round is held: no addclearfull reaches the game, and the reason is said", function()
    fresh()
    proneShield()
    ataxiaBasher_attack()
    expect(swung).toBe(0)
    expect(rawFind("addclearfull")).toBe(false)
    expect(saidHas("SHIELD HOLD")).toBe(true)
    expect(saidHas("the basher's attack round held")).toBe(true)
  end)

  it("a PvP round sent straight (addclearfull, addclear freestand, addclear eqbal) is dropped by the wrapper", function()
    fresh()
    proneShield()
    send("queue addclearfull freestand garrote Sadey")
    send("queue addclear freestand bite Sadey")
    send("queue addclear eqbal combo Sadey a b c")
    expect(#raw).toBe(0)
    expect(saidHas("SHIELD HOLD: `queue addclearfull freestand` held")).toBe(true)
  end)

  it("the held-round line is throttled to one per 2 s", function()
    fresh()
    proneShield()
    send("queue addclearfull freestand garrote Sadey")
    send("queue addclearfull freestand garrote Sadey")
    expect(#said).toBe(1)
    clock = clock + 2.1
    send("queue addclearfull freestand garrote Sadey")
    expect(#said).toBe(2)
  end)

  it("what does not clear our entries still goes: addclear free, cq all, our own entries, plain lines", function()
    fresh()
    proneShield()
    send("queue addclear free bite Sadey")
    send("cq all")
    send("queue addclear freestand touch shield")
    send("queue prepend eqbal stand")
    send("outr bellwort")
    expect(#raw).toBe(5)
    expect(ataxiaTemp.proneShieldHold ~= nil).toBe(true)
  end)

  it("a move goes and ends the hold (leaving outranks the shield)", function()
    fresh()
    proneShield()
    send("queue addclearfull freestand leap ne")
    expect(rawHas("queue addclearfull freestand leap ne")).toBe(true)
    expect(ataxiaTemp.proneShieldHold).toBeNil()
    expect(saidHas("a move replaced the queue")).toBe(true)
  end)
end)

describe("v4.7.524 -- every end of the hold, with its reason", function()
  it("the shield line (trigger 022's real pattern and body) ends it, and the next round goes", function()
    fresh()
    proneShield()
    expect(TL.anyMatches(TL.patterns(SHIELDED), SHIELD_LINE)).toBe(true)
    shieldedBody()
    expect(ataxiaTemp.proneShieldHold).toBeNil()
    expect(saidHas("SHIELD HOLD ends: the shield formed")).toBe(true)
    send("queue addclearfull freestand garrote Sadey")
    expect(rawHas("queue addclearfull freestand garrote Sadey")).toBe(true)
  end)

  it("the shield defence (GMCP) ends it too", function()
    fresh()
    proneShield()
    ataxia.defences.shield = true
    send("queue addclearfull freestand garrote Sadey")
    expect(rawHas("queue addclearfull freestand garrote Sadey")).toBe(true)
    expect(saidHas("SHIELD HOLD ends: the shield is up")).toBe(true)
  end)

  it("the 9 s bound ends it, and the basher swings again", function()
    fresh()
    proneShield()
    clock = clock + 8.9
    ataxiaBasher_attack()
    expect(swung).toBe(0)
    clock = clock + 0.1
    ataxiaBasher_attack()
    expect(swung).toBe(1)
    expect(rawHas("queue addclearfull freestand stand;bite 101")).toBe(true)
    expect(saidHas("9 s passed without the shield")).toBe(true)
  end)

  it("a re-sent shield does not stretch the bound", function()
    fresh()
    proneShield()
    clock = clock + 5
    ataxiaBasher_queueShield(false)
    clock = clock + 4
    send("queue addclearfull freestand garrote Sadey")
    expect(rawHas("queue addclearfull freestand garrote Sadey")).toBe(true)
  end)

  it("a bad leg while prone ends it: the stand is refused", function()
    fresh()
    proneShield()
    ataxia.afflictions.brokenleftleg = true
    send("queue addclearfull freestand garrote Sadey")
    expect(rawHas("queue addclearfull freestand garrote Sadey")).toBe(true)
    expect(saidHas("SHIELD HOLD ends: prone on a bad leg")).toBe(true)
  end)

  it("a manual end works once; a second end is silent", function()
    fresh()
    proneShield()
    expect(ataxia_proneShieldHoldEnd("manual")).toBe(true)
    expect(ataxia_proneShieldHoldEnd("manual")).toBe(false)
    expect(#said).toBe(1)
  end)
end)

describe("v4.7.524 -- standing, nothing is held", function()
  it("a standing shield starts no hold, and the next round goes", function()
    fresh()
    expect(ataxiaBasher_queueShield(false)).toBe(true)
    expect(rawHas("queue prepend eqbal stand")).toBe(false)
    expect(ataxiaTemp.proneShieldHold).toBeNil()
    ataxiaBasher_attack()
    expect(swung).toBe(1)
    expect(rawHas("queue addclearfull freestand stand;bite 101")).toBe(true)
  end)

  it("standing again with no shield: the hold ends 1.5 s after the stand (the entry is gone)", function()
    fresh()
    proneShield()
    ataxia.afflictions.prone = nil -- we stood; the shield entry was wiped, so no shield follows
    send("queue addclearfull freestand garrote Sadey")
    expect(rawHas("queue addclearfull freestand garrote Sadey")).toBe(false)
    clock = clock + 1.4
    send("queue addclearfull freestand garrote Sadey")
    expect(rawHas("queue addclearfull freestand garrote Sadey")).toBe(false)
    clock = clock + 0.1
    send("queue addclearfull freestand garrote Sadey")
    expect(rawHas("queue addclearfull freestand garrote Sadey")).toBe(true)
    expect(saidHas("standing, and no shield 1.5 s after the stand")).toBe(true)
  end)

  it("prone again before the grace ends restarts the grace", function()
    fresh()
    proneShield()
    ataxia.afflictions.prone = nil
    send("queue addclearfull freestand garrote Sadey")
    clock = clock + 1.0
    ataxia.afflictions.prone = true
    send("queue addclearfull freestand garrote Sadey")
    ataxia.afflictions.prone = nil
    clock = clock + 0.1
    send("queue addclearfull freestand garrote Sadey")
    clock = clock + 1.0
    send("queue addclearfull freestand garrote Sadey")
    expect(rawHas("queue addclearfull freestand garrote Sadey")).toBe(false)
  end)
end)

-- Put back everything these loads and stubs changed.
for k in pairs(ataxiaTemp) do ataxiaTemp[k] = nil end
for k, v in pairs(beforeTemp) do ataxiaTemp[k] = v end
for k in pairs(ataxiaBasher) do if beforeBasher[k] == nil then ataxiaBasher[k] = nil end end
for k, v in pairs(beforeBasher) do ataxiaBasher[k] = v end
for k in pairs(ataxia) do if beforeAtaxia[k] == nil then ataxia[k] = nil end end
for k, v in pairs(beforeAtaxia) do ataxia[k] = v end
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
mock.reset()
