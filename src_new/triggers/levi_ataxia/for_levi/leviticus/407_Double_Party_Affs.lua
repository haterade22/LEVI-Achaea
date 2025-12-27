--[[mudlet
type: trigger
name: Double Party Affs
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
- pattern: '^\(Party\): (\w+) says, "(\w+) wracked: (\w+) (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "(\w+) truewracked: (\w+) (\w+)."$'
  type: 1
- pattern: '^\(Party\)\: (\w+) says\, "(\w+) hit with (\w+) and (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "(\w+): (\w+) (\w+)."$'
  type: 1
]]--

if isTargeted(matches[3]) then
	paAff(matches[4])
	paAff(matches[5])
end