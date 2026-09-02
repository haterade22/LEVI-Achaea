--[[mudlet
type: script
name: Balance Timers
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function timerOnEQUsed()
  if gmcp.Char.Vitals.eq == '0' and ataxiaEQStopwatchStarted ~= true then
    startEQTimer()
  end
end

function startEQTimer()
  ataxiaEQStopwatch = ataxiaEQStopwatch or createStopWatch()
  startStopWatch(ataxiaEQStopwatch)
  ataxiaEQStopwatchStarted = true
end

function endEQTimer()
  -- Guard the stopwatch: on a fresh/reloaded session ataxiaEQStopwatch is nil (globals aren't
  -- persisted), so stopStopWatch(nil) threw -- and that error aborted the EQUILIBRIUM trigger
  -- BEFORE EQHighlight() ran, which is why the eq/balance bars vanished while bashing.
  if not ataxiaEQStopwatchStarted then
    ataxiaEQTimeFresh = false
    return false
  end
  if ataxiaEQStopwatch then
    ataxiaEQTime = stopStopWatch(ataxiaEQStopwatch)
    resetStopWatch(ataxiaEQStopwatch)
    ataxiaEQTimeFresh = true
  end
  ataxiaEQStopwatchStarted = false
  return ataxiaEQTimeFresh == true
end

function EQHighlight()
  if ataxiaEQTimeFresh ~= true then return end
  ataxiaEQTimeFresh = false
  local etime = ataxiaEQTime or '0.000'
  cecho("\n<blue>(((((((((((((((((((( EQUILIBRIUM:<white>" ..etime.. " <blue>))))))))))))))))))))")
  if bashStats then
    local eqTime = tonumber(etime) or 0
    bashStats.lastBalanceTime = eqTime
    bashStats.lastBalanceDamage = bashStats.currentBalanceDamage or 0
    bashStats.currentBalanceDamage = 0
    if tarc and tarc.write then tarc.write() end
  end
end


function timerOnBalUsed()
  if gmcp.Char.Vitals.bal == '0' and ataxiaBalStopwatchStarted ~= true then
    startBalTimer()
  end
end

function startBalTimer()
  ataxiaBalStopwatch = ataxiaBalStopwatch or createStopWatch()
  startStopWatch(ataxiaBalStopwatch)
  ataxiaBalStopwatchStarted = true
end

-- TWO TRIGGERS STOP THIS WATCH, AND THE SECOND ONE HAD NOTHING LEFT TO MEASURE (v4.7.292).
--
-- `balances/001_Limb_Balance` fires on "You have recovered balance on your legs." and
-- `balances/006_All_Limbs` on "You have recovered balance on all limbs." Both call
-- `endBalTimer()` + `balanceHighlight()`, and both lines routinely arrive in the same round. The
-- first stopped the watch, RESET it to zero and cleared `ataxiaBalStopwatchStarted`; the second
-- then stopped an already-reset watch, read ~0, and printed
--
--     (((((((((((((((((((( BALANCE: 0.000 ))))))))))))))))))))
--
-- The start side has always been guarded -- `timerOnBalUsed` refuses when
-- `ataxiaBalStopwatchStarted` is already true -- and the stop side simply never got the matching
-- guard. **A stopwatch with a guarded start and an unguarded stop is not a pair.** (EQ has only
-- ONE stopper, `003_EQUILIBRIUM`, so it never showed this; guarded here too, because the
-- asymmetry was the defect and correcting only the half that happens to bite invites the next one.)
--
-- Returns whether a real interval was measured, so the display can tell "0.000 seconds" from
-- "nothing was running" -- they are different answers and must not print alike.
function endBalTimer()
  if not ataxiaBalStopwatchStarted then
    ataxiaBalTimeFresh = false
    return false
  end
  if ataxiaBalStopwatch then           -- same nil guard as endEQTimer (fresh/reloaded session)
    ataxiaBalTime = stopStopWatch(ataxiaBalStopwatch)
    resetStopWatch(ataxiaBalStopwatch)
    ataxiaBalTimeFresh = true
  end
  ataxiaBalStopwatchStarted = false
  return ataxiaBalTimeFresh == true
end

-- Prints ONLY for a balance we actually timed. The second stopper of a round now reports nothing
-- rather than a fabricated `0.000` -- which was not merely cosmetic: `bashStats.lastBalanceTime`
-- was being overwritten with 0 and `currentBalanceDamage` zeroed a second time, so the round's
-- damage was attributed to a balance of zero length.
function balanceHighlight()
  if ataxiaBalTimeFresh ~= true then return end
  ataxiaBalTimeFresh = false
  local btime = ataxiaBalTime or '0.000'
  cecho("\n<red>(((((((((((((((((((( BALANCE: <white>"..btime.. " <red>))))))))))))))))))))")
  if bashStats then
    local balTime = tonumber(btime) or 0
    bashStats.lastBalanceTime = balTime
    bashStats.lastBalanceDamage = bashStats.currentBalanceDamage or 0
    bashStats.currentBalanceDamage = 0
    if tarc and tarc.write then tarc.write() end
  end
end