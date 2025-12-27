--[[mudlet
type: trigger
name: Astrology scry
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
- pattern: Gazing up at the sky, you bring the image of
  type: 2
- pattern: ^Gazing up at the sky, you bring the image of (\w+) into your mind's eye and overlay it on the constellations\.
    The power of the stars manifests as an image of (.+?) forms before your eyes\.$
  type: 1
]]--

mmp.locateAndEcho(multimatches[2][3], multimatches[2][2])