--[[mudlet
type: trigger
name: Chemwood walk delay
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Lusternia
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
- pattern: ^You struggle to push through \w+'s thick, swirling mists\.$
  type: 1
- pattern: ^You struggle to move with \w+'s amplified fields disrupting your muscular impulses, but you stumble determinedly
    in an effort to leave\.$
  type: 1
- pattern: ^\w+'s whirling leaves harry you as you try to leave, slowing your egress\.$
  type: 1
- pattern: ^You begin moving through the thick, swirling flurries of \w+'s spores\.$
  type: 1
- pattern: You stumble through the thick smog, coughing and sputtering as you try to find cleaner air.
  type: 3
- pattern: ^You stumble around stupidly as \w+'s mind-dulling effluvia seeps into you, fighting against a strangely dull mind
    to make your legs take you out of here\.$
  type: 1
]]--

mmp.customwalkdelay(2)