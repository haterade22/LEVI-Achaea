--- test_launch_land.lua -- LAND when an enemy launches us into the sky (v4.7.491)
--
-- User: "We need to LAND when this happens." Dunn's piercing note, then
-- "A violent force suddenly takes hold of you and launches you high into the sky."
-- (kb/raw/logs/ours/2026-11-03_102828_Harkon.log rows 503, 1578, 7302).

local mock = require("mock_mudlet")
local TL = dofile("src_new/tests/trigger_lib.lua")

local NOW = 50000
local realEpoch, realSLC, realTemp = getEpoch, selfLimbDamage, ataxiaTemp
getEpoch = function() return NOW end
ataxia = ataxia or {}
ataxia.mnemosyne = ataxia.mnemosyne or {}
ataxia.mnemosyne.swarm = ataxia.mnemosyne.swarm or {}
local SW = ataxia.mnemosyne.swarm
local realFlying = SW.flying

dofile("src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/032_Launch_Land.lua")

local TRIG = "src_new/triggers/levi_ataxia/for_levi/leviticus/801_Launched_Into_Sky.lua"
local LINE = "A violent force suddenly takes hold of you and launches you high into the sky."

-- Run the timers that exist now, one step of 0.5 s. mock.fire_timers() also deletes the timers
-- the callbacks make, so a retry loop needs this instead.
local function step()
  NOW = NOW + 0.5
  local ids = {}
  for id in pairs(mock.active_timers) do ids[#ids + 1] = id end
  for _, id in ipairs(ids) do
    local t = mock.active_timers[id]
    mock.active_timers[id] = nil
    if t and type(t.callback) == "function" then t.callback() end
  end
end

local function timerCount()
  local n = 0
  for _ in pairs(mock.active_timers) do n = n + 1 end
  return n
end

local function lands()
  local n = 0
  for _, c in ipairs(mock.sent_commands) do if c == "land" then n = n + 1 end end
  return n
end

local function setRoom(name)
  gmcp = gmcp or {}
  gmcp.Room = { Info = { name = name } }
end

local function reset()
  mock.reset()
  ataxiaTemp = {}
  selfLimbDamage = nil
  SW.flying = nil
  setRoom("Flying above A rotting treetrunk.")
end

describe("launched into the sky: LAND", function()
  it("the trigger pattern matches the game's line, whole and wrapped at 119/124", function()
    local pats = TL.patterns(TRIG)
    expect(#pats).toBe(1)
    expect(pats[1].type).toBe(0)
    expect(LINE:find(pats[1].pat, 1, true) ~= nil).toBeTrue()
    for _, w in ipairs({ 100, 119, 124 }) do
      expect(#TL.wrap(LINE, w)).toBe(1)
    end
  end)

  it("sends LAND at once, directly, not through the queue", function()
    reset()
    dofile(TRIG)
    expect(mock.sent_commands[1]).toBe("land")
    expect(#mock.sent_commands).toBe(1)
  end)

  it("sends LAND again while gmcp still says Flying above", function()
    reset()
    ataxia_launchedLand()
    step()
    step()
    expect(lands()).toBe(3)
  end)

  it("stops when the room name loses Flying above", function()
    reset()
    ataxia_launchedLand()
    setRoom("A rotting treetrunk.")
    step()
    expect(lands()).toBe(1)
    expect(timerCount()).toBe(0)
    expect(ataxiaTemp.launchLandTimer).toBeNil()
  end)

  it("gives up after 6 s in the air", function()
    reset()
    ataxia_launchedLand()
    for _ = 1, 20 do step() end
    expect(lands()).toBe(1 + 12)
    expect(timerCount()).toBe(0)
  end)

  it("a second launch restarts the loop and leaves one timer", function()
    reset()
    ataxia_launchedLand()
    step()
    ataxia_launchedLand()
    expect(timerCount()).toBe(1)
  end)

  it("stays up during the SLC both-arms flee", function()
    reset()
    selfLimbDamage = { bothArmsFlee = true }
    ataxia_launchedLand()
    expect(lands()).toBe(0)
    expect(timerCount()).toBe(0)
  end)

  it("stays up during a Mnemosyne flight", function()
    reset()
    SW.flying = true
    ataxia_launchedLand()
    expect(lands()).toBe(0)
  end)

  it("a hold that starts mid-loop stops the retries", function()
    reset()
    ataxia_launchedLand()
    selfLimbDamage = { bothArmsFlee = true }
    step()
    expect(lands()).toBe(1)
    expect(timerCount()).toBe(0)
  end)
end)

-- Give the globals back to the test files that run after this one.
mock.reset()
getEpoch, selfLimbDamage, ataxiaTemp = realEpoch, realSLC, realTemp
SW.flying = realFlying
