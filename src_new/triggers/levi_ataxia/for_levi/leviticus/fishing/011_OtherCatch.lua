--[[mudlet
type: trigger
name: OtherCatch
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Fishing
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
- pattern: '^With a final tug, (\w+) finishes reeling in h(?:is|er) fishing line and lands (.+) weighing (\d+) pounds(?: and
    (\d+) ounces?)?!$'
  type: 1
- pattern: '^(\w+) reels in the last bit of h(?:is|er) line and lands (.+) weighing (\d+) pounds(?: and (\d+) ounces?)?\.$'
  type: 1
]]--

--fishParse(matches[3],matches[4],matches[5],matches[2]:lower())
