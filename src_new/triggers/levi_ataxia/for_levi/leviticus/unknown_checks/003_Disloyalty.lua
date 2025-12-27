--[[mudlet
type: trigger
name: Disloyalty
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Unknown Checks
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
- pattern: ^Your (.+) refuses to work with such a disloyal coward such as you.$
  type: 1
]]--

if ataxia.afflictions.unknown and ataxia.afflictions.unknown > 0 then
		ataxia.afflictions.unknown = ataxia.afflictions.unknown - 1
		if ataxia.afflictions.unknown == 0 then ataxia.afflictions.unknown = nil end
		send("curing predict disloyalty")
end