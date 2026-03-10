-- Global curing priority throttle (5 commands/second limit per Announce #5450)
ataxia.prioThrottle = ataxia.prioThrottle or {
  commands = {},
  sentThisSecond = 0,
  windowStart = 0,
  MAX_PER_SECOND = 4,
  drainTimer = nil,
}

function ataxia_sendCuringPriority(cmd, silent)
  local now = getEpoch()
  local throttle = ataxia.prioThrottle

  if (now - throttle.windowStart) >= 1.0 then
    throttle.sentThisSecond = 0
    throttle.windowStart = now
  end

  if throttle.sentThisSecond < throttle.MAX_PER_SECOND then
    throttle.sentThisSecond = throttle.sentThisSecond + 1
    send(cmd, silent or false)
  else
    table.insert(throttle.commands, {cmd = cmd, silent = silent or false})
    if not throttle.drainTimer then
      throttle.drainTimer = tempTimer(0.25, function() ataxia_drainPrioQueue() end)
    end
  end
end

function ataxia_drainPrioQueue()
  local throttle = ataxia.prioThrottle
  throttle.drainTimer = nil

  local now = getEpoch()
  if (now - throttle.windowStart) >= 1.0 then
    throttle.sentThisSecond = 0
    throttle.windowStart = now
  end

  while #throttle.commands > 0 and throttle.sentThisSecond < throttle.MAX_PER_SECOND do
    local entry = table.remove(throttle.commands, 1)
    throttle.sentThisSecond = throttle.sentThisSecond + 1
    send(entry.cmd, entry.silent)
  end

  if #throttle.commands > 0 then
    throttle.drainTimer = tempTimer(0.25, function() ataxia_drainPrioQueue() end)
  end
end

function ataxia_defaultPrioAff(aff)
	local defaultPrios = ataxia_defaultCuringPrios()
	return defaultPrios[aff]
end

function ataxia_setAffPrio(aff, num)
	prioWaitfor = prioWaitfor or {}
	if not prioWaitfor[aff] then
		prioWaitfor[aff] = tempTimer(1, [[ prioWaitfor["]]..aff..[["] = nil ]])
		ataxia_sendCuringPriority("curing priority "..aff.. " "..num, false)
	end
end

function ataxia_restorePrio(aff)
	local defaultPrios = ataxia_defaultCuringPrios()
	ataxia.curingprio = ataxia.curingprio or {}
	
	prioWaitrestore = prioWaitrestore or {}
	
	if ataxia_getPrio(aff) == ataxia_defaultPrioAff(aff) then return end
	if not prioWaitrestore[aff] then
		prioWaitrestore[aff] = tempTimer(1, [[ prioWaitrestore["]]..aff..[["] = nil ]])
		ataxia_sendCuringPriority("curing priority "..aff.." "..defaultPrios[aff])
	end
end

function ataxia_showPrios(num)
	ataxiaEcho("Displaying our current curing priorities:")
	for prio = 1, num do
		for aff, num in pairs(ataxia.curingprio) do
			if num == prio then
				echo("\n")
				fg("green")
				echoLink(" [+]", [[ataxia_raisePrio("]]..aff..[[")]], "Raise "..aff.." to priority of "..(ataxia.curingprio[aff] + 1)..".",true)
				fg("red")
				echoLink(" [-]", [[ataxia_lowerPrio("]]..aff..[[")]], "Lower "..aff.." to priority of "..(ataxia.curingprio[aff] - 1)..".",true)
				cecho("<white>: <DimGrey>(<LightSlateGrey>"..prio.."<DimGrey>) <NavajoWhite>"..aff)
			end
		end	
	end
	send(" ")
end

function ataxia_getPrio(aff)
	if not ataxia.curingprio[aff] then
		return 0
	else
		return ataxia.curingprio[aff]
	end
end

function ataxia_raisePrio(aff, hide)
	local newprio = (ataxia.curingprio[aff] - 1)
	ataxia.curingprio[aff] = newprio
	ataxia_sendCuringPriority("curing priority "..aff.." "..newprio)

	if not hide then
		ataxiaEcho("Raised "..aff.." to a priority of "..newprio)
		ataxia_showPrios(newprio)
	end
end

function ataxia_lowerPrio(aff, hide)
	local newprio = (ataxia.curingprio[aff] + 1)
	ataxia.curingprio[aff] = newprio
	ataxia_sendCuringPriority("curing priority "..aff.." "..newprio)

	if not hide then
		ataxiaEcho("Lowered "..aff.." to a priority of "..newprio)
		ataxia_showPrios(newprio)
	end
end