--- test_bard_compose.lua — the Bard bash-performance compose sequence (basher/002)
--
-- From a live log, 2026-08-07:
--   (LEVI): Bard bash: composed paean prelude scherzo sonata maqam
--   You aren't wearing a Lasallian lyre.
--   How are you going to perform a song without your instrument wielded?
--
-- The three commands went out RAW and the basher dispatches an attack on the very next prompt.
-- That attack re-wields the SHIELD into the left hand, so the lyre was pulled back out between
-- `wield` and `compose` -- and the echo still claimed success, announcing a performance that
-- never started.

require("mock_mudlet")

local sent = {}
local _mockSend = send
function send(cmd) sent[#sent + 1] = cmd end

local timers, killed, nextId = {}, {}, 0
local _mockTempTimer, _mockKillTimer = tempTimer, killTimer
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
  if type(t.fn) == "function" then t.fn() end
end

function enableTimer() end
function ataxiaEcho() end
function ataxia_isClass() return false end

ataxia = ataxia or {}
ataxia.settings = { separator = ";" }
ataxia.bardStuff = {}
ataxia.vitals = { rage = 0 }
ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = {}
bardComposePending = false

-- basher/002 is large and pulls in a lot at load; slice out just the compose functions, which
-- are self-contained. Slicing the REAL source (never a re-typed copy) is what keeps this
-- honest -- a hand-written duplicate stops being the thing under test the moment 002 changes.
local src = io.open("src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua"):read("*a")
local i = src:find("ataxiaBasher_BARD_COMPOSE_HOLD = 3", 1, true)
local j = src:find("\nend", src:find("function ataxiaBasher_bardComposeDone", 1, true), true)
assert(i and j, "could not slice the compose functions out of basher/002")
local chunk = assert(loadstring or load)(src:sub(i, j + 4), "compose")
chunk()

local function reset()
  sent, timers, killed, nextId = {}, {}, {}, 0
  ataxiaTemp = {}
  bardComposePending = false
  ataxiaBasher_bardComposeT = nil
end

describe("ataxiaBasher_bardCompose", function()
  it("sends remove -> wield -> compose as ONE queued line", function()
    reset()
    ataxiaBasher_bardCompose()
    expect(#sent).toBe(1)
    expect(sent[1]).toBe("queue addclear free remove lyre;wield lyre;compose paean prelude scherzo sonata maqam")
  end)

  -- The whole point: an attack landing mid-sequence re-wields the shield and the compose fails.
  it("holds the attack before sending, not after", function()
    reset()
    -- Capture the hold state at send time, which is what actually matters -- setting it after
    -- the send leaves exactly the gap this bug lived in.
    local heldAtSend
    send = function(cmd)
      heldAtSend = ataxiaTemp.bardComposeHold
      sent[#sent + 1] = cmd
    end
    ataxiaBasher_bardCompose()
    send = function(cmd) sent[#sent + 1] = cmd end
    expect(heldAtSend).toBeTrue()
    expect(ataxiaTemp.bardComposeHold).toBeTrue()
  end)

  it("releases the hold when its timer expires, so it can never wedge", function()
    reset()
    ataxiaBasher_bardCompose()
    local id = ataxiaBasher_bardComposeT
    expect(id ~= nil).toBeTrue()
    fire(id)
    expect(ataxiaTemp.bardComposeHold).toBe(nil)
  end)

  it("releases early once a performance is confirmed running", function()
    reset()
    ataxiaBasher_bardCompose()
    local id = ataxiaBasher_bardComposeT
    ataxiaBasher_bardComposeDone()
    expect(ataxiaTemp.bardComposeHold).toBe(nil)
    expect(killed[id]).toBeTrue() -- and the timer is killed, not left to fire later
    expect(ataxiaBasher_bardComposeT).toBe(nil)
  end)

  it("is safe to confirm when nothing is composing", function()
    reset()
    ataxiaBasher_bardComposeDone()
    expect(ataxiaTemp.bardComposeHold).toBe(nil)
  end)

  it("debounces repeat calls", function()
    reset()
    ataxiaBasher_bardCompose()
    ataxiaBasher_bardCompose()
    expect(#sent).toBe(1)
  end)

  it("honours a configured compose list", function()
    reset()
    ataxia.bardStuff.bashCompose = "paean sonata"
    ataxiaBasher_bardCompose()
    expect(sent[1]).toContain("compose paean sonata")
    ataxia.bardStuff.bashCompose = nil
  end)

  -- Re-arming must kill the previous timer, or the OLD one fires later and drops the hold
  -- belonging to a NEWER compose -- the same stale-timer shape as the stun throttle and the
  -- parry cooldown.
  it("kills the previous hold timer when re-arming", function()
    reset()
    ataxiaBasher_bardCompose()
    local first = ataxiaBasher_bardComposeT
    bardComposePending = false -- past the debounce
    ataxiaBasher_bardCompose()
    expect(killed[first]).toBeTrue()
    expect(ataxiaBasher_bardComposeT ~= first).toBeTrue()
  end)
end)

-- Restore the mock's globals for whoever runs after us (shared Lua state).
send, tempTimer, killTimer = _mockSend, _mockTempTimer, _mockKillTimer
