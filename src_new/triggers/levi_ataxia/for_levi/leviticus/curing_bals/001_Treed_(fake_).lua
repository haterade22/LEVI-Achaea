--[[mudlet
type: trigger
name: Treed (fake?)
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
- pattern: Your tree of life tattoo glows faintly for a moment then fades, leaving you unchanged.
  type: 3
]]--

ataxiaTemp.canTree = false
-- This "glows faintly...leaving you unchanged" line is a REAL tree fire that consumed tree balance
-- but cured nothing -- the regain line "You may utilise the tree tattoo again." (004_Got_Tree_Bal,
-- which clears usedTree) follows it. So the tree IS now on cooldown: mark it, exactly like the
-- successful-cure line (003_Tree_Touched). Without this, usedTree never latches during bashing
-- (SSC emits this "unchanged" variant, not "You touch the tree of life tattoo."), which left the
-- Magi Bloodboil "off tree balance" gate (ataxiaBasher_magiShouldBloodboil) permanently dead.
ataxiaTemp.usedTree = true