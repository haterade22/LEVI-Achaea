--[[mudlet
type: trigger
name: Scrying bowl
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
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: You dip your fingers into the cool water of the bowl, willing it to reveal the location of
  type: 2
- pattern: ^You dip your fingers into the cool water of the bowl, willing it to reveal the location of (\w+)\.$
  type: 1
- pattern: ^An image of (.+) appears reflected within the bowl, shifting with the rippling water to display (.+)\.$
  type: 1
]]--

mmp.locateAndEcho(multimatches[3][3], multimatches[2][2], multimatches[3][2])