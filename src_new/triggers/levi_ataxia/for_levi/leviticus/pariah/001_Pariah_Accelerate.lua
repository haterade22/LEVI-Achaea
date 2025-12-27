--[[mudlet
type: trigger
name: Pariah Accelerate
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Pariah
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
- pattern: ^(\w+) fixes \w+ gaze to yours, raising \w+ \w+ \w+, before sharply snapping \w+ fingers\.$
  type: 1
]]--

if target == matches[2] then
ataxia_boxEcho("THEY ARE ACCELERATING FOR THE VOYRIA KILL|RUNNNNNNNNNN", "red")
end