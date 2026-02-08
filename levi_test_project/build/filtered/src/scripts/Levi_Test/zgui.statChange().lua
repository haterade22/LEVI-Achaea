function zgui.statChange()
  zgui.trueTime = string.cut(getTime(true, "hh:mm:ss:zzz"), 11)
	local changeAmount = 0
	local sendThisString = ""
  zgui.tempOh = zgui.tempOh or 0
  if zgui.vitals.oh then
    if zgui.vitals.oh > 0 then
      zgui.tempOh = zgui.vitals.oh
    end
  end
  if not zgui.vitals.h then
--BLACKOUT Most likely, don't even try.
  else
  if not zgui.vitals.oh then
    zgui.vitals.oh = 0
  end
	if (zgui.vitals.oh + 100) < zgui.vitals.h then
		changeAmount = zgui.vitals.h - zgui.vitals.oh
		sendThisString = changeAmount.." Health Gain"
		cecho("logDisplay", "<green>"..zgui.trueTime)
		cecho("logDisplay", "<green>   "..sendThisString.."\n")
	elseif zgui.vitals.oh > (zgui.vitals.h + 100) then
		changeAmount = zgui.vitals.oh - zgui.vitals.h
		sendThisString = changeAmount.." Health Loss"
		cecho("logDisplay", "<red>"..zgui.trueTime)
		cecho("logDisplay", "<red>   "..sendThisString.."\n")
	end
  if not zgui.vitals.om then
    zgui.vitals.om = 0
  end
	if (zgui.vitals.om + 100) < zgui.vitals.m then
		changeAmount = zgui.vitals.m - zgui.vitals.om
		sendThisString = changeAmount.." Mana Gain"
		cecho("logDisplay", "<blue>"..zgui.trueTime)
		cecho("logDisplay", "<blue>   "..sendThisString.."\n")
	elseif zgui.vitals.om > (zgui.vitals.m + 100) then
		changeAmount = zgui.vitals.om - zgui.vitals.m
		sendThisString = changeAmount.." Mana Loss"
		cecho("logDisplay", "<red>"..zgui.trueTime)
		cecho("logDisplay", "<red>   "..sendThisString.."\n")
	end
	end
  
end