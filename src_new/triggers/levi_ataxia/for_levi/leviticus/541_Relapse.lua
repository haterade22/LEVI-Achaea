--[[mudlet
type: trigger
name: Relapse
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Shaman
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
- pattern: ^You manipulate the (\w+) affliction affecting (\w+), altering it to relapse at a later time.$
  type: 1
]]--

ataxiaTemp.relapse = true
ataxiaTemp.relapseAff = matches[2]

if ataxiaTemp.relapseAff ~= "paralysis" then
	ataxiaTemp.relapseWait = tempTimer(1.8, [[ataxiaTemp.relapseWait = nil]])
end