--- test_balance_timers.lua -- the balance/equilibrium stopwatches (ataxia/014_Balance_Timers.lua)
--
-- Written for a live symptom (user, 2026-09-02): the banner kept printing
--
--     (((((((((((((((((((( BALANCE: 0.000 ))))))))))))))))))))
--
-- "quite a bit". The cause is that TWO triggers stop this one stopwatch --
-- `balances/001_Limb_Balance` on "You have recovered balance on your legs." and
-- `balances/006_All_Limbs` on "You have recovered balance on all limbs." -- and both lines arrive
-- in the same round. The first stopped and RESET the watch; the second stopped an already-reset
-- watch, read zero, and printed it as though it were a measurement.
--
-- The start side was always guarded (`timerOnBalUsed` refuses while one is running); the stop side
-- never got the matching guard. A stopwatch with a guarded start and an unguarded stop is not a
-- pair.

require("mock_mudlet")

-- EVERY GLOBAL TOUCHED HERE IS SAVED AND PUT BACK AT THE BOTTOM. Test files share ONE Lua state,
-- so a stub left behind -- or a real mock function nil'd out -- breaks whichever suite happens to
-- run next; `test_mnemosyne.lua`'s header records the same lesson. The first cut of this file
-- nil'd `cecho` and `gmcp` in its teardown and took nine unrelated tests down with it.
local _saved = {
  createStopWatch = createStopWatch, startStopWatch = startStopWatch,
  stopStopWatch = stopStopWatch, resetStopWatch = resetStopWatch,
  cecho = cecho, gmcp = gmcp, bashStats = bashStats, tarc = tarc,
}

-- The mock has no stopwatches, so model one: a monotonic clock we control, and the same
-- start/stop/reset semantics Mudlet gives. `stopStopWatch` on a reset-and-not-restarted watch
-- returns 0, which is exactly the value that was reaching the screen.
local NOW, watches, nextId = 0, {}, 0
function createStopWatch() nextId = nextId + 1; watches[nextId] = { t0 = nil }; return nextId end
function startStopWatch(id) watches[id].t0 = NOW end
function stopStopWatch(id)
  local w = watches[id]
  return w.t0 and (NOW - w.t0) or 0
end
function resetStopWatch(id) watches[id].t0 = nil end

local printed
function cecho(s) printed[#printed + 1] = s end

gmcp = { Char = { Vitals = { bal = "1", eq = "1" } } }
bashStats = nil
tarc = nil

dofile("src_new/scripts/levi_ataxia/levi/ataxia/014_Balance_Timers.lua")

local function reset()
  NOW, printed = 0, {}
  ataxiaBalStopwatch, ataxiaBalStopwatchStarted, ataxiaBalTime, ataxiaBalTimeFresh = nil, nil, nil, nil
  ataxiaEQStopwatch, ataxiaEQStopwatchStarted, ataxiaEQTime, ataxiaEQTimeFresh = nil, nil, nil, nil
  gmcp.Char.Vitals.bal, gmcp.Char.Vitals.eq = "1", "1"
end

local function banners()
  local n = 0
  for _, s in ipairs(printed) do if s:find("BALANCE", 1, true) then n = n + 1 end end
  return n
end

describe("the balance stopwatch", function()
  it("times a normal cycle and reports it once", function()
    reset()
    gmcp.Char.Vitals.bal = "0"; timerOnBalUsed()   -- prompt says balance is gone -> start
    NOW = 2.75
    endBalTimer(); balanceHighlight()
    expect(banners()).toBe(1)
    expect(printed[1]:find("2.75", 1, true) ~= nil).toBeTrue()
  end)

  -- THE REPORTED BUG. Both recovery lines land in one round; only the first has anything to time.
  it("does NOT print a second, fabricated 0.000 when a second trigger stops it", function()
    reset()
    gmcp.Char.Vitals.bal = "0"; timerOnBalUsed()
    NOW = 2.75
    endBalTimer(); balanceHighlight()              -- "recovered balance on your legs"
    endBalTimer(); balanceHighlight()              -- "recovered balance on all limbs"
    expect(banners()).toBe(1)
    for _, s in ipairs(printed) do
      expect(s:find("0.000", 1, true)).toBe(nil)
    end
  end)

  -- Not merely cosmetic: the fabricated zero was written into the DPS stats, so a round's damage
  -- was attributed to a balance of no length at all.
  it("does not poison bashStats with the fabricated zero", function()
    reset()
    bashStats = { currentBalanceDamage = 900 }
    gmcp.Char.Vitals.bal = "0"; timerOnBalUsed()
    NOW = 2.5
    endBalTimer(); balanceHighlight()
    expect(bashStats.lastBalanceTime).toBe(2.5)
    expect(bashStats.lastBalanceDamage).toBe(900)
    bashStats.currentBalanceDamage = 400
    endBalTimer(); balanceHighlight()              -- the second stopper
    expect(bashStats.lastBalanceTime).toBe(2.5)    -- still the real reading, not 0
    expect(bashStats.currentBalanceDamage).toBe(400) -- and the new round's damage was not eaten
    bashStats = nil
  end)

  it("reports again on the NEXT real cycle", function()
    reset()
    gmcp.Char.Vitals.bal = "0"; timerOnBalUsed()
    NOW = 2.0; endBalTimer(); balanceHighlight()
    endBalTimer(); balanceHighlight()              -- the duplicate, silent
    gmcp.Char.Vitals.bal = "0"; timerOnBalUsed()   -- next attack
    NOW = 5.5; endBalTimer(); balanceHighlight()
    expect(banners()).toBe(2)
    expect(printed[#printed]:find("3.5", 1, true) ~= nil).toBeTrue()
  end)

  -- A recovery line arriving with no attack behind it (a refused command, a relog) has nothing to
  -- measure. Printing a zero there would be a reading we never took.
  it("stays silent when nothing was ever started", function()
    reset()
    endBalTimer(); balanceHighlight()
    expect(banners()).toBe(0)
  end)

  it("survives a stop on a fresh session where the watch does not exist yet", function()
    reset()
    local ok = pcall(function() endBalTimer(); balanceHighlight() end)
    expect(ok).toBeTrue()
  end)
end)

-- EQ has only ONE stopper (`003_EQUILIBRIUM`), so it never showed the double-print. It is guarded
-- symmetrically anyway: the ASYMMETRY was the defect, and fixing only the half that happens to
-- bite leaves the other half waiting for a second trigger to be added.
describe("the equilibrium stopwatch", function()
  it("times a normal cycle and reports it once", function()
    reset()
    gmcp.Char.Vitals.eq = "0"; timerOnEQUsed()
    NOW = 3.1
    endEQTimer(); EQHighlight()
    local n = 0
    for _, s in ipairs(printed) do if s:find("EQUILIBRIUM", 1, true) then n = n + 1 end end
    expect(n).toBe(1)
  end)

  it("is guarded against a second stop in the same way", function()
    reset()
    gmcp.Char.Vitals.eq = "0"; timerOnEQUsed()
    NOW = 3.1
    endEQTimer(); EQHighlight()
    endEQTimer(); EQHighlight()
    local n = 0
    for _, s in ipairs(printed) do if s:find("EQUILIBRIUM", 1, true) then n = n + 1 end end
    expect(n).toBe(1)
  end)
end)

-- Restore, do not blank: `cecho` and `gmcp` come from `mock_mudlet` and later suites call them.
createStopWatch, startStopWatch = _saved.createStopWatch, _saved.startStopWatch
stopStopWatch, resetStopWatch = _saved.stopStopWatch, _saved.resetStopWatch
cecho, gmcp, bashStats, tarc = _saved.cecho, _saved.gmcp, _saved.bashStats, _saved.tarc
ataxiaBalStopwatch, ataxiaBalStopwatchStarted, ataxiaBalTime, ataxiaBalTimeFresh = nil, nil, nil, nil
ataxiaEQStopwatch, ataxiaEQStopwatchStarted, ataxiaEQTime, ataxiaEQTimeFresh = nil, nil, nil, nil
