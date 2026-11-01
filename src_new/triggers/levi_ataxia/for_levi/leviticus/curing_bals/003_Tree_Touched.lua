--[[mudlet
type: trigger
name: Tree Touched
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Curing Bals
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'yes'
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
mFgColor: '#000000'
mBgColor: '#75d16a'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: You touch the tree of life tattoo.
  type: 3
]]--

-- This line prints on every touch of ours. It hung under trigger 002 (`[Curing]: TOUCH TREE`), so it
-- ran only on the line after that report. We expect no such report for a `touch tree` we send
-- ourselves, so AntiSerpent's and Mnemosyne's own touches did not mark the tree down.
ataxiaTemp.usedTree = true