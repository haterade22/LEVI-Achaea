--[[mudlet
type: trigger
name: Emanation Air
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Magi
- Magi Offense Tracking
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
- pattern: ^You sweep .+ over your head and a great wind rises, picking up (\w+) and dashing them violently about before casting them back to the ground\.$
  type: 1
]]--

if isTargeted(matches[2]) then
  tarAffed("paralysis")
  tarAffed("dizziness")
end
