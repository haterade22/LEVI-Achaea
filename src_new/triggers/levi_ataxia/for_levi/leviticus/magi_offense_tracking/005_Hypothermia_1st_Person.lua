--[[mudlet
type: trigger
name: Hypothermia 1st Person
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
- pattern: ^You blast (\w+) with an icy stream of water, and \w+ begins to shiver uncontrollably\.$
  type: 1
]]--

if isTargeted(matches[2]) then
  tarAffed("hypothermia")
  -- Hypothermia implies all prior freeze-chain affs
  tarAffed("frozen")
  tarAffed("shivering")
  tarAffed("nocaloric")
  -- Update magi offense state
  magi = magi or {}
  magi.offense = magi.offense or {}
  magi.offense.state = magi.offense.state or {}
  magi.offense.state.hypothermia = true
end
