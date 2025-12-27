--[[mudlet
type: trigger
name: Alchemist ether seek
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Achaea
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
- pattern: You reach out into the ether, folding it aside to reveal
  type: 2
- pattern: ^You reach out into the ether, folding it aside to reveal (\w+)\. As you peer into the opening, the image of (.+)
    swims into view, then fades away as the ether seeps back into place\.$
  type: 1
]]--

mmp.locateAndEcho(multimatches[2][3], multimatches[2][2])