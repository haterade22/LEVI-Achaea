--- test_basher_shield_resend.lua -- a denizen shield re-sends the round ONCE (v4.7.469)
--
-- A Two Handed Runewarden's log: one "A nearly invisible magical shield forms around a dwarf
-- initiate." and then about 200 "...your attack rebounds off of a dwarf initiate's shield." lines
-- in 3 seconds. Trigger 336 matches both lines and called ataxiaBasher_shieldRaised on each; that
-- re-sent the round, and each re-send drew another rebound. Its 1/sec throttle compared two
-- getEpoch() values with `==`, and Mudlet's getEpoch() has milliseconds, so it stopped nothing.

require("mock_mudlet")

target = 12740
secondTarget = "a dwarf initiate"
ataxia = {
  settings = { separator = ";" },
  vitals = { rage = 0, knight = "Two Handed" },
  defences = {},
  afflictions = {},
}
ataxiaBasher = { enabled = true, battlerage = {} }
ataxiaTemp = {}
gmcp = {
  Room = { Info = { area = "", num = 5 } },
  Char = { Status = { class = "Runewarden" }, Vitals = {} },
  IRE = { Target = { Info = {} } },
}
function ataxiaEcho() end
function bashConsoleEcho() end

local _epoch = getEpoch
local clock = 500000.000
getEpoch = function() return clock end

local ok = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua")
if not ok then error("Failed to load bashing functions") end

local sends = 0
ataxiaBasher_attack = function() sends = sends + 1 end
ataxiaBasher_validTargets = function() return 1 end

local TRIGGER = "src_new/triggers/levi_ataxia/for_levi/leviticus/336_Mob_Shielded.lua"
local fh = assert(io.open(TRIGGER, "r"))
local body = assert((loadstring or load)(fh:read("*a"):match("%]%]%-%-\r?\n(.*)$")))
fh:close()

local function fire(name)
  matches = { "", name }
  body()
end

local function reset()
  sends = 0
  ataxiaTemp = {}
  ataxiaBasher.shielded = false
  ataxiaBasher.paused = nil
  clock = 500000.000
end

describe("denizen shield re-send (trigger 336)", function()
  it("re-sends once for the shield line, and not for the rebounds that follow", function()
    reset()
    fire("a dwarf initiate") -- "A nearly invisible magical shield forms around a dwarf initiate."
    expect(sends).toBe(1)
    for _ = 1, 50 do
      clock = clock + 0.006
      fire("a dwarf initiate") -- "...rebounds off of a dwarf initiate's shield."
    end
    expect(sends).toBe(1)
    expect(ataxiaBasher.shielded).toBeTrue()
  end)

  it("re-sends for a rebound when no shield line was seen", function()
    reset()
    fire("a dwarf initiate") -- only "...rebounds off of a dwarf initiate's shield."
    expect(sends).toBe(1)
  end)

  it("re-sends again once the shield was cleared", function()
    reset()
    fire("a dwarf initiate")
    ataxiaBasher.shielded = false -- trigger 335 or the expiry timer
    clock = clock + 5
    fire("a dwarf initiate")
    expect(sends).toBe(2)
  end)
end)

describe("shield re-send throttle", function()
  it("holds a raise for one second on a clock with milliseconds", function()
    reset()
    ataxiaBasher_shieldRaised()
    clock = clock + 0.006
    ataxiaBasher_shieldRaised()
    clock = clock + 0.5
    ataxiaBasher_shieldRaised()
    expect(sends).toBe(1)
    clock = clock + 0.6
    ataxiaBasher_shieldRaised()
    expect(sends).toBe(2)
  end)

  it("holds a drop for one second on a clock with milliseconds", function()
    reset()
    ataxiaBasher_shieldDropped()
    clock = clock + 0.006
    ataxiaBasher_shieldDropped()
    expect(sends).toBe(1)
    clock = clock + 1.1
    ataxiaBasher_shieldDropped()
    expect(sends).toBe(2)
  end)

  it("keeps a raise and a drop on separate stamps", function()
    reset()
    ataxiaBasher_shieldRaised()
    ataxiaBasher_shieldDropped()
    expect(sends).toBe(2)
  end)
end)

getEpoch = _epoch
