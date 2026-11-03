--- test_depthswalker_watch.lua -- the display-only alert for a Depthswalker's shadow route (v4.7.476)
--
-- Two Depthswalkers killed us on 2026-11-03 (fightlogs 102138_Tabethys, rows 8749-9313). The lines below are the
-- log's. These run the REAL trigger, the REAL script and the REAL ataxia_promptLocks. Every global they change is
-- restored at the end.

local mock = require("mock_mudlet")
local TL = dofile("src_new/tests/trigger_lib.lua")

local before = {}
for k, v in pairs(_G) do before[k] = v end

local TRIG = "src_new/triggers/levi_ataxia/for_levi/leviticus/determine_class/031_Depthswalker_Watch.lua"
local WATCH = "src_new/scripts/levi_ataxia/levi/levi_scripts/class_detect/002_Depthswalker_Watch.lua"
local LOCKS = "src_new/scripts/levi_ataxia/levi/ataxia/can(x)/003_Lock_breakers.lua"

local ATTUNE = "Akri reaches past you, plunging Gattan'lier's hunger into your shadow."
local STRIKE = "Kutcher delivers a lightning-fast strike to you with an ancient shadowed scythe."
local AKRI_STRIKE = "Akri delivers a lightning-fast strike to you with Agith'maal's ire."
local SWING = "Kutcher swings an ancient shadowed scythe at you."
local SHADOW = "As the scythe comes away, the writhing figure of your shadow clings to the blade."
local PHYLACTERY = "Drawing a shadow from a bone phylactery, Akri raises Gattan'lier's hunger aloft and plunges the blade into the ephemeral mass."
local AGONY = "You feel a deep, piercing agony, that radiates outward from the centre of your chest and claws with icy fingers at your insides."
local SLAIN = "You have been slain by Akri."

local function read(p) local f = assert(io.open(p, "r")); local s = f:read("*a"); f:close(); return s end
local body = assert((loadstring or load)(read(TRIG):match("%]%]%-%-\r?\n(.*)$"), TRIG))

local now, boxes, sends = 1000, {}, {}
getEpoch = function() return now end
ataxia_boxEcho = function(msg, color) boxes[#boxes + 1] = msg end
send = function(c) sends[#sends + 1] = c end
sendAll = send
function affed(what) return ataxia.afflictions[what] end
function ataxia_paused() return false end
ataxia = { settings = {}, vitals = {}, afflictions = {}, defences = {} }
ataxiaTemp = {}

assert(pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/can(x)/001_Various__can_do__stuff.lua"))
assert(pcall(dofile, LOCKS))
dofile(WATCH)

local PATTERNS = TL.patterns(TRIG)

-- The game line, through the real pattern list and the real trigger body.
local function line(text)
  if not TL.anyMatches(PATTERNS, text) then error("no pattern takes this line: " .. text, 2) end
  -- The capture each pattern takes: the phylactery line's name comes after its first words.
  matches = { text, text:match("bone phylactery, (%w+) raises") or text:match("^(%w+) ") }
  body()
  return true
end

local function fresh()
  now, boxes, sends = 1000, {}, {}
  ataxiaTemp = {}
  ataxia.vitals = { hpp = 100 }
  ataxia.afflictions = {}
end

describe("the Depthswalker watch", function()
  it("takes every line from the log", function()
    fresh()
    for _, text in ipairs({ ATTUNE, STRIKE, AKRI_STRIKE, SWING, SHADOW, PHYLACTERY, AGONY, SLAIN }) do
      expect(line(text)).toBeTrue()
    end
  end)

  it("sends nothing to the game, whatever it reads", function()
    fresh()
    for _, text in ipairs({ ATTUNE, STRIKE, SHADOW, PHYLACTERY, AGONY, SLAIN }) do line(text) end
    dwWatch.promptLabel()
    expect(#sends).toBe(0)
    expect(#mock.sent_commands).toBe(0)
  end)

  it("an attune gets one box, not one per repeat", function()
    fresh()
    line(ATTUNE)
    line(ATTUNE)
    expect(#boxes).toBe(1)
    expect(boxes[1]:find("Akri attuned", 1, true) ~= nil).toBeTrue()
    now = now + 31
    line(ATTUNE)
    expect(#boxes).toBe(2)
  end)

  it("a strike alone shows nothing", function()
    fresh()
    line(STRIKE)
    expect(#boxes).toBe(0)
    expect(dwWatch.promptLabel()).toBeNil()
  end)

  it("the shadow line names the striker from the same packet", function()
    fresh()
    line(STRIKE)
    now = now + 0.01
    line(SHADOW)
    expect(boxes[1]:find("Shadow taken: Kutcher", 1, true) ~= nil).toBeTrue()
    expect(dwWatch.promptLabel()).toBe("SHADOW(Kutcher)")
  end)

  it("an old strike names nobody", function()
    fresh()
    line(STRIKE)
    now = now + 2
    line(SHADOW)
    expect(dwWatch.promptLabel()).toBe("SHADOW(?)")
  end)

  it("two holders both show, and low health shows the number", function()
    fresh()
    line(STRIKE)
    line(SHADOW)
    now = now + 1.7
    line(AKRI_STRIKE)
    line(SHADOW)
    expect(dwWatch.promptLabel()).toBe("SHADOW(Akri,Kutcher)")
    ataxia.vitals.hpp = 38
    expect(dwWatch.promptLabel()).toBe("SHADOW(Akri,Kutcher) 38%")
    ataxia.vitals.hpp = 50
    expect(dwWatch.promptLabel()).toBe("SHADOW(Akri,Kutcher)")
  end)

  it("a phylactery strike that lands and leaves us alive spends that holder's shadow", function()
    fresh()
    line(AKRI_STRIKE)
    line(SHADOW)
    line(STRIKE)
    line(SHADOW)
    line(PHYLACTERY)
    line(AGONY)
    expect(dwWatch.promptLabel()).toBe("SHADOW(Kutcher)")
  end)

  it("a phylactery strike at someone else spends nothing of ours", function()
    fresh()
    line(AKRI_STRIKE)
    line(SHADOW)
    line(PHYLACTERY)
    now = now + 3
    line(AGONY)
    expect(dwWatch.promptLabel()).toBe("SHADOW(Akri)")
  end)

  it("a shadow leaves the prompt after its hold, and our death clears it", function()
    fresh()
    line(STRIKE)
    line(SHADOW)
    now = now + 59
    expect(dwWatch.promptLabel()).toBe("SHADOW(Kutcher)")
    now = now + 2
    expect(dwWatch.promptLabel()).toBeNil()
    line(STRIKE)
    line(SHADOW)
    line(SLAIN)
    expect(dwWatch.promptLabel()).toBeNil()
  end)
end)

describe("the prompt", function()
  it("names a held shadow, beside the locks", function()
    fresh()
    line(STRIKE)
    line(SHADOW)
    local s = ataxia_promptLocks()
    expect(s:find("SHADOW(Kutcher)", 1, true) ~= nil).toBeTrue()
    expect(s:find("Locks:", 1, true) ~= nil).toBeTrue()
  end)

  it("says nothing with no shadow held", function()
    fresh()
    expect(ataxia_promptLocks():find("SHADOW", 1, true)).toBeNil()
  end)
end)

for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
mock.reset()
