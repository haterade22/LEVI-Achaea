--[[mudlet
type: trigger
name: Shadow Stolen
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Depthwalker
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
- pattern: ^You claim the shadow of (\w+), storing it within your phylactery.$
  type: 1
]]--


	selectString(line,1)
	fg("white")
	bg("SeaGreen")
	setBold(true)
	resetFormat()
	ataxia_boxEcho(target:upper().."'S SHADOW HAS BEEN STOLEN", "purple")
  ataxia_boxEcho(target:upper().."'S SHADOW HAS BEEN STOLEN", "purple")
	tAffs.parasite = true
	if applyAffV3 then applyAffV3("parasite") end
	tAffs.healthleech = true
	if applyAffV3 then applyAffV3("healthleech") end
	tAffs.manaleech = true
	if applyAffV3 then applyAffV3("manaleech") end
  haveshadow = true
