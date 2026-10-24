--- test_v451_triggers.lua
-- v4.7.451: STRIKE TEMPLE gives dizziness on a broken head (Striking 270, 2026-10-23), and the
-- DWB flail expend triggers 007 (relapse key) and 011 (pattern type).

local L = require("trigger_lib")

local T = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local TEMPLE = T .. "striking/008_Stupidity_(temple).lua"
local LEGS = T .. "expend_afflictions/007_DWB_Legs_-_Affliction_-_Flails.lua"
local ARMS2 = T .. "expend_afflictions/011_DWB_Arms_-_Affliction_2_-_Flails.lua"

local _saved = { tarAffed = tarAffed, isTargeted = isTargeted, tempTimer = tempTimer,
  send = send, matches = matches, tAffs = tAffs, target = target, partyrelay = partyrelay }

local given, sent, timers
local function reset(head)
  given, sent, timers = {}, {}, {}
  tarAffed = function(a) given[#given + 1] = a end
  isTargeted = function() return true end
  send = function(c) sent[#sent + 1] = c end
  tempTimer = function(_, code) timers[#timers + 1] = code end
  tAffs = { damagedhead = head or nil }
  target, partyrelay = "Bob", false
  ataxia = ataxia or {}; ataxia.afflictions = ataxia.afflictions or {}
end
local function has(list, v) for _, x in ipairs(list) do if x == v then return true end end return false end

describe("STRIKE TEMPLE (v4.7.451)", function()
  it("gives stupidity only on an unbroken head", function()
    reset(false); matches = { "", "Bob" }
    dofile(TEMPLE)
    expect(has(given, "stupidity")).toBeTrue()
    expect(has(given, "dizziness")).toBeFalse()
  end)

  it("also gives dizziness on a broken head", function()
    reset(true); matches = { "", "Bob" }
    dofile(TEMPLE)
    expect(has(given, "stupidity")).toBeTrue()
    expect(has(given, "dizziness")).toBeTrue()
  end)

  it("relays both on a broken head, in the two-affliction party form", function()
    reset(true); partyrelay = true; matches = { "", "Bob" }
    dofile(TEMPLE)
    expect(has(sent, "pt Bob: stupidity dizziness")).toBeTrue()
  end)
end)

describe("DWB flail expend triggers (v4.7.451)", function()
  it("007's relapse re-adds clumsiness, the name V3 uses (was 'clumsy')", function()
    reset(); matches = { "" }
    dofile(LEGS)
    expect(#timers).toBe(1)
    expect(timers[1]:find('"clumsiness"', 1, true) ~= nil).toBeTrue()
  end)

  it("011's pattern is a regex trigger and matches its line", function()
    local pats = L.patterns(ARMS2)
    expect(pats[1].type).toBe(1)
    expect(L.matches(pats[1].pat, pats[1].type,
      "The wet crunch of bone can be heard as the flail smashes into the left arm of Bob.")).toBeTrue()
  end)
end)

tarAffed, isTargeted, tempTimer, send = _saved.tarAffed, _saved.isTargeted, _saved.tempTimer, _saved.send
matches, tAffs, target, partyrelay = _saved.matches, _saved.tAffs, _saved.target, _saved.partyrelay
