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
  ataxiaEQTime = stopStopWatch(ataxiaEQStopwatch)
  resetStopWatch(ataxiaEQStopwatch)
  ataxiaEQStopwatchStarted = false
end

function EQHighlight()
etime = ataxiaEQTime or '0.000'
cecho("\n<blue>(((((((((((((((((((( EQUILIBRIUM:<white>" ..etime.. " <blue>))))))))))))))))))))")
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
  ataxiaBalTime = stopStopWatch(ataxiaBalStopwatch)
  resetStopWatch(ataxiaBalStopwatch)
  ataxiaBalStopwatchStarted = false
end

function balanceHighlight()
btime = ataxiaBalTime or '0.000'
cecho("\n<red>(((((((((((((((((((( BALANCE: <white>"..btime.. " <red>))))))))))))))))))))")
end