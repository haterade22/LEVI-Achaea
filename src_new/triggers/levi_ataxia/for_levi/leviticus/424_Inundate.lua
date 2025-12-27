--[[mudlet
type: trigger
name: Inundate
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Alchemist
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You inundate \w+'s (melancholic|sanguine|choleric|phlegmatic) humour(.+).$
  type: 1
]]--

local humour = matches[2]
if humour == "phlegmatic" then
	if not tAffs.phlegmatic then
		return
	else
		local affList = {}
		if not ataxia.vitals.class or ataxia.vitals.class == 0 then
			affList = {lethargy = 1, anorexia = 3, slickness = 5, weariness = 7}
		else
			affList = {lethargy = 1, anorexia = 5, slickness = 7}
		end
		local afflicted = {}
		for aff, count in pairs(affList) do
			if tAffs.phlegmatic > count then
				table.insert(afflicted, aff)
				tAffs[aff] = true
			end
		end
		raiseEvent("tar afflicted", afflicted)	
		checkTargetLocks()
	end
	tAffs.phlegmatic = nil
elseif humour == "sanguine" then
	selectString(line,1)
	fg("a_darkred")
	resetFormat()
	tAffs.sanguine = nil
elseif humour == "choleric" then
	selectString(line,1)
	fg("a_darkgreen")
	resetFormat()
	tAffs.choleric = nil
else
	selectString(line,1)
	fg("DeepSkyBlue")
	resetFormat()
	tAffs.melancholic = nil
end