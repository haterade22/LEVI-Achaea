--[[mudlet
type: trigger
name: Party Targeting
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- PARTY TARGETTING
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
- pattern: '^\(Party\): (\w+) says, "Target: (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "Target (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "TARGET: (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "Target changed to (\w+)."$'
  type: 1
]]--

if partyleader and partyleader == matches[2] then
partyrelay = false
expandAlias("t "..matches[3])
end