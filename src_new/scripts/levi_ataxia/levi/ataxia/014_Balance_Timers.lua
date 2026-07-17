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
  if ataxiaEQStopwatch then
    ataxiaEQTime = stopStopWatch(ataxiaEQStopwatch)
    resetStopWatch(ataxiaEQStopwatch)
  end
  ataxiaEQStopwatchStarted = false
end

function EQHighlight()
etime = ataxiaEQTime or '0.000'
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

function endBalTimer()
  if ataxiaBalStopwatch then           -- same nil guard as endEQTimer (fresh/reloaded session)
    ataxiaBalTime = stopStopWatch(ataxiaBalStopwatch)
    resetStopWatch(ataxiaBalStopwatch)
  end
  ataxiaBalStopwatchStarted = false
end

function balanceHighlight()
btime = ataxiaBalTime or '0.000'
cecho("\n<red>(((((((((((((((((((( BALANCE: <white>"..btime.. " <red>))))))))))))))))))))")
if bashStats then
  local balTime = tonumber(btime) or 0
  bashStats.lastBalanceTime = balTime
  bashStats.lastBalanceDamage = bashStats.currentBalanceDamage or 0
  bashStats.currentBalanceDamage = 0
  if tarc and tarc.write then tarc.write() end
end
end