--[[mudlet
type: trigger
name: Fortify
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- General
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
- pattern: You forge a channel through to the elemental skein of the universe.
  type: 3
]]--

if ataxia and ataxia.defences then
  ataxia.defences["simultaneity"] = true
end
-- Master of Four clock: the cast line is the stamp (basher/002 ataxiaBasher_magiMasterOfFour).
ataxiaTemp = ataxiaTemp or {}
ataxiaTemp.simultaneityCastAt = getEpoch()
-- While autobash runs, do not queue fortify/bind: Master of Four casts simultaneity every 30 s,
-- and these would add two more eq actions each time. Outside bashing nothing changes.
if not (ataxiaBasher and ataxiaBasher.enabled) then
  send ("queue add eqbal fortify all")
  send ("queue add eqbal bind all")
end