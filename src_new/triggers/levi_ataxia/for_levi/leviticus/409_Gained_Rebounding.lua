--[[mudlet
type: trigger
name: Gained Rebounding
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
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
- pattern: ^You suddenly perceive the vague outline of an aura of rebounding around (\w+).$
  type: 1
]]--

if target == matches[2] then
	tAffs.rebounding = true
	selectString(line,1)
	setBold(true)
	fg("NavajoWhite")
	resetFormat()
end

--Archaeon reaches out and nimbly plucks the arrow from the air.
--You begin sketching a thurisaz rune on the ground.