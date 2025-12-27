--[[mudlet
type: trigger
name: Angel trace
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
- pattern: Your guardian angel reports that
  type: 2
- pattern: ^Your guardian angel reports that (\w+) has moved to (.+)\.$
  type: 1
]]--

selectCurrentLine() replace("")
cecho("<grey>Angel trace: <a_darkcyan>"..multimatches[2][2].."<grey> moved to <a_darkcyan>" .. multimatches[2][3])
mmp.locateAndEchoInternal(multimatches[2][3], multimatches[2][2])