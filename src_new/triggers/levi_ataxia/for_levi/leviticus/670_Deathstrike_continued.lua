--[[mudlet
type: trigger
name: Deathstrike continued
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Warnings
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
- pattern: 'Leaping forwards with lightning speed, '
  type: 2
- pattern: ^Leaping forwards with lightning speed, (\w+) strikes you in the chest with a single, powerful blow\. Its rhythm
    interrupted by (?:his|her) precise attack, your heartbeat begins to fluctuate erratically, a painful pressure building
    in your arteries\.$
  type: 1
]]--

ataxia_setWarning(multimatches[2][2].." deathstriking you still", 2)
