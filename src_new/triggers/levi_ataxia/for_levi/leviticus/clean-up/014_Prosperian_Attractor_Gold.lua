--[[mudlet
type: trigger
name: Prosperian Attractor Gold
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
- Clean-up
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
- pattern: ^.+ from the corpse, flying into your hands before they can reach the ground.$
  type: 1
]]--

if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("denizen", "Yoinked their gold!")
  ataxiaTemp.goldinhand = true
  if not ataxiaBasher.manual then
  	deleteFull()
  end
end
