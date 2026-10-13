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
  -- No st.hypothermia latch since v4.7.420. P3, P7 and `mm status` read hypothermia from V3
  -- (004_Magi_Offense.lua), and the latch, cleared only by a target change or `mm reset`, outlived
  -- the target's cure.
end
