ragewindow=ragewindow or false
--if matches[2] == nil and huntVar.on then
if not ragewindow then
	slc_LimbcounterDisp:show()
	ragewindow = true
else
	ragewindow = false
	slc_LimbcounterDisp:hide()
end