--- test_basher_stun.lua — stun flag lifecycle (basher/001, triggers 722/723)
-- User, 2026-08-06: "there is a noticeable lag from this message to actually doing
-- something." The dispatch off the clear line was already immediate; what was not was the
-- state around it -- a stale re-queue cooldown surviving the stun, and a stun flag with
-- exactly one line able to clear it and no failsafe behind it.

local mock = require("mock_mudlet")

function ataxiaEcho(...) end
function get_Battlerage() end
function ataxiaBasher_canShield() return true end
function table.contains(t, v)
  if type(t) ~= "table" then return false end
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

-- Controllable clock + timer bookkeeping. The real tempTimer is fire-and-forget; here we
-- capture the callbacks so the failsafe can be fired deliberately instead of waited for.
-- Saved so they can be put back at the END of this file: test files share one Lua state and
-- discovery order differs between Windows (dir) and CI (find), so a leaked override breaks
-- whoever runs after us. (Same reason test_swarm_tactics.lua restores `send`.)
local _mockTempTimer, _mockKillTimer, _mockGetEpoch = tempTimer, killTimer, getEpoch
local clock = 5000
function getEpoch() return clock end
local timers, killed = {}, {}
local nextId = 0
function tempTimer(delay, fn)
  nextId = nextId + 1
  timers[nextId] = { delay = delay, fn = fn }
  return nextId
end
function killTimer(id) killed[id] = true; timers[id] = nil; return true end
local function fire(id)
  local t = timers[id]
  if not t then error("timer " .. tostring(id) .. " is not armed") end
  timers[id] = nil
  t.fn()
end

ataxia = ataxia or {}
ataxia.settings = ataxia.settings or { separator = ";" }
ataxia.vitals = { hpp = 100, maxhp = 5000, rage = 0 }
ataxia.afflictions = {}
ataxia.defences = {}
ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = ataxiaTemp or {}
gmcp = { Room = { Info = { area = "" } } }

local basher_file = "src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua"
local ok, err = pcall(dofile, basher_file)
if not ok then error("Failed to load basher functions file: " .. tostring(err)) end

-- Count dispatches without running a real attack round: the round assembly is not what is
-- under test here, and stubbing the unit under test is how a test stops testing anything.
local dispatched = 0
ataxiaBasher_attack = function() dispatched = dispatched + 1 end

local function baseline()
  ataxia.afflictions = {}
  ataxiaTemp = {}
  ataxiaBasher.enabled = true
  ataxiaBasher_atk = false
  ataxiaBasher_atkTimer = nil
  ataxiaBasher_stunT = nil
  timers, killed = {}, {}
  dispatched = 0
  clock = 5000
end

describe("stun flag lifecycle", function()
  it("sets the flag and arms a failsafe on the stun line", function()
    baseline()
    ataxiaBasher_stunStart()
    expect(ataxia.afflictions.stun).toBeTrue()
    expect(ataxiaTemp.stunAt).toBe(5000)
    expect(ataxiaBasher_stunT ~= nil).toBeTrue()
  end)

  it("clears the flag and dispatches on the clear line", function()
    baseline()
    ataxiaBasher_stunStart()
    ataxiaBasher_stunEnd()
    expect(ataxia.afflictions.stun).toBe(nil)
    expect(ataxiaTemp.stunAt).toBe(nil)
    expect(dispatched).toBe(1)
  end)

  -- THE LAG. ataxiaBasher_atk is the 0.3s re-queue cooldown; it is armed by the last dispatch
  -- BEFORE the stun latched and its clearing timer runs the whole way through. 723's direct
  -- call ignores it, but the follow-up prompt dispatch does not -- so a refused or wiped round
  -- sat out a window that was armed for a completely different reason.
  it("drops the stale re-queue cooldown that outlived the stun", function()
    baseline()
    ataxiaBasher_stunStart()
    ataxiaBasher_atk = true                 -- armed just before the stun landed
    ataxiaBasher_atkTimer = tempTimer(0.3, function() end)
    local staleTimer = ataxiaBasher_atkTimer
    ataxiaBasher_stunEnd()
    expect(ataxiaBasher_atk).toBeFalse()
    expect(ataxiaBasher_atkTimer).toBe(nil)
    expect(killed[staleTimer]).toBeTrue()   -- and it cannot fire later and clobber a fresh one
  end)

  it("kills the failsafe when the real clear line arrives", function()
    baseline()
    ataxiaBasher_stunStart()
    local fs = ataxiaBasher_stunT
    ataxiaBasher_stunEnd()
    expect(ataxiaBasher_stunT).toBe(nil)
    expect(killed[fs]).toBeTrue()
  end)

  -- THE STALL. Exactly one line clears this flag, and two of the three setter patterns are
  -- Vertani-specific -- so in practice the setter is the refusal line, which fires for ANY
  -- stun source. Miss the clear (different wording, split line, lost packet) and the
  -- affliction gate in tryAttack blocked the basher until the next stun happened to print it.
  it("self-expires if the clear line never comes, and dispatches", function()
    baseline()
    ataxiaBasher_stunStart()
    fire(ataxiaBasher_stunT)
    expect(ataxia.afflictions.stun).toBe(nil)
    expect(dispatched).toBe(1)
  end)

  it("the failsafe is inert once the clear line has already run", function()
    baseline()
    ataxiaBasher_stunStart()
    local fs = ataxiaBasher_stunT
    ataxiaBasher_stunEnd()
    expect(dispatched).toBe(1)
    expect(timers[fs]).toBe(nil) -- killed, so it can never double-dispatch
  end)

  -- A re-stun mid-stun must not leave the first failsafe running: it would expire early and
  -- clear a flag that is legitimately still set.
  it("re-arming replaces the previous failsafe", function()
    baseline()
    ataxiaBasher_stunStart()
    local first = ataxiaBasher_stunT
    clock = clock + 2
    ataxiaBasher_stunStart()
    expect(killed[first]).toBeTrue()
    expect(ataxiaBasher_stunT ~= first).toBeTrue()
    expect(ataxiaTemp.stunAt).toBe(5002) -- re-stamped from the newer stun
  end)

  it("does not dispatch while the basher is off", function()
    baseline()
    ataxiaBasher.enabled = false
    ataxiaBasher_stunStart()
    ataxiaBasher_stunEnd()
    expect(ataxia.afflictions.stun).toBe(nil) -- flag still cleared: nothing else clears it
    expect(dispatched).toBe(0)
  end)
end)

-- Restore the mock's timer/clock functions for whoever runs after us (see the note above).
tempTimer, killTimer, getEpoch = _mockTempTimer, _mockKillTimer, _mockGetEpoch
