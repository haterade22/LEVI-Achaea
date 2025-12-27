--[[mudlet
type: trigger
name: Birdseye
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Lusternia
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
- pattern: From your vantage point in the sky, your crow senses perceive that
  type: 2
- pattern: ^From your vantage point in the sky, your crow senses perceive that (\w+) is (.*) within the vicinity of (.*)\.$
  type: 1
]]--

mmp.locateAndEcho(multimatches[2][3], multimatches[2][2])