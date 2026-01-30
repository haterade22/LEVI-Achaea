if tAffs and haveAff("timeloop") and not checkTimeloop then
	tAffs.timeloop = nil
	disableTrigger("Timeloop Failsafe Update")
end