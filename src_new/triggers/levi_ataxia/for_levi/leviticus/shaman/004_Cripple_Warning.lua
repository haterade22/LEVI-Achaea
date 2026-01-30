--[[mudlet
type: trigger
name: Cripple Warning
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Shaman
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'yes'
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
mFgColor: '#000000'
mBgColor: '#ff0004'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: As all four of your limbs break, pain overwhelms you and you wonder what you've done to deserve such a fate.
  type: 3
]]--

if not ataxiaTemp.usedTree then
	ataxia_boxEcho("Salvelock maybe incoming! Hold for tree")
	ataxiaTemp.salvelockWait = tempTimer(3.5, [[ killTimer(ataxiaTemp.salvelockWait); ataxiaTemp.salvelockWait = nil ]])
	
	local sp = ataxia.settings.separator or ";"
	send("curing predict manaleech"..sp.."focus")

end