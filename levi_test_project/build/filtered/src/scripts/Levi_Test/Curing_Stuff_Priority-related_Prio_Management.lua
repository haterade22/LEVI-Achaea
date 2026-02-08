function ataxia_defaultPrioAff(aff)
	local defaultPrios = ataxia_defaultCuringPrios()
	return defaultPrios[aff]
end

function ataxia_setAffPrio(aff, num)
	prioWaitfor = prioWaitfor or {}
	if not prioWaitfor[aff] then
		prioWaitfor[aff] = tempTimer(1, [[ prioWaitfor["]]..aff..[["] = nil ]])
		send("curing priority "..aff.. " "..num,false)
	end
end

function ataxia_restorePrio(aff)
	local defaultPrios = ataxia_defaultCuringPrios()
	ataxia.curingprio = ataxia.curingprio or {}
	
	prioWaitrestore = prioWaitrestore or {}
	
	if ataxia_getPrio(aff) == ataxia_defaultPrioAff(aff) then return end
	if not prioWaitrestore[aff] then
		prioWaitrestore[aff] = tempTimer(1, [[ prioWaitrestore["]]..aff..[["] = nil ]])
		send("curing priority "..aff.." "..defaultPrios[aff])
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
	send("curing priority "..aff.." "..newprio)
	
	if not hide then
		ataxiaEcho("Raised "..aff.." to a priority of "..newprio)
		ataxia_showPrios(newprio)
	end
end

function ataxia_lowerPrio(aff, hide)
	local newprio = (ataxia.curingprio[aff] + 1)
	ataxia.curingprio[aff] = newprio
	send("curing priority "..aff.." "..newprio)
	
	if not hide then
		ataxiaEcho("Lowered "..aff.." to a priority of "..newprio)
		ataxia_showPrios(newprio)
	end
end