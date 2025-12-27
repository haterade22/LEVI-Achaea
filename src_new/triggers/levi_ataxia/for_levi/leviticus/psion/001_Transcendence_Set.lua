--[[mudlet
type: trigger
name: Transcendence Set
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Psion
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
- pattern: '^Your body and mind continue to harmonise\: you are (\d+) percent of the way to full transcendence.$'
  type: 1
- pattern: '^Your inaction causes the harmonisation of your body and mind to falter\: you are now only (\d+) percent of the
    way to transcendence.$'
  type: 1
]]--

ataxiaTemp.transcendence = tonumber(matches[2])
if ataxiaBasher.enabled and not ataxiaBasher.manual then
	deleteFull()
end