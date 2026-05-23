--[[mudlet
type: trigger
name: Phantom Mount Whip
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Sentinel
- Skirmishing
- Targeted Strikes
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 4
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You whip (.+) into a fury, bucking and racing dangerously in a circle, trampling the ground in a frenzy\.$
  type: 1
- pattern: ^.+ breaks the left leg of (\w+)\.$
  type: 1
- pattern: ^.+ crushes the right leg of \w+\.$
  type: 1
- pattern: ^.+ pulverises the left arm of \w+\.$
  type: 1
- pattern: ^.+ smashes the right arm of \w+\.$
  type: 1
]]--

local tgt = multimatches[2][2]
if isTargeted(tgt) then
  tarAffed("brokenleftleg", "brokenrightleg", "brokenleftarm", "brokenrightarm", "prone")
end
