if affTimers.voyria then
  affTimers.voyria = affTimers.voyria - 10
  local timeRemaining = 30 - affDuration("voyria")
  deleteLine()
  cecho("\n   <green>"..utf8.char(187).." <Orange>Accelerated VOYRIA <green>"..utf8.char(171))
  if timeRemaining < 0 then
    cecho(" <red>Used too many times, duration reset!")
  else
    cecho(" <green>Time left: "..timeRemaining)
  end
end

if taccelerates == 0 then
taccelerates = 1
elseif taccelerates == 1 then
taccelerates = 2
end