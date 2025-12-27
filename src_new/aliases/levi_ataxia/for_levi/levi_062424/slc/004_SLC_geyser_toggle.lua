--[[mudlet
type: alias
name: SLC geyser toggle
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- slc
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^slc$
command: ''
packageName: ''
]]--

ragewindow=ragewindow or false
--if matches[2] == nil and huntVar.on then
if not ragewindow then
	slc_LimbcounterDisp:show()
	ragewindow = true
else
	ragewindow = false
	slc_LimbcounterDisp:hide()
end