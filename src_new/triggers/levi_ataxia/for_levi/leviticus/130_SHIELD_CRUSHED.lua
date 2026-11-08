--[[mudlet
type: trigger
name: SHIELD CRUSHED
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- EARTH LORD
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
- pattern: ^You bring a magma-wreathed fist around, pulverising the magical shield surrounding (\w+) with a single blow.$
  type: 1
]]--

-- `ak` is another system's table (AK). No file of this package creates it, so the bare write threw
-- on every crush, before the gag and the echo below ran. 335 records the shield on this line.
if ak and ak.defs then ak.defs.shield = false end
deleteFull()
local stats = gmcp and gmcp.Char and gmcp.Char.Vitals and gmcp.Char.Vitals.charstats
cecho("<magenta>\n CRUSHED THAT SHIELD !!! AND KEPT SHAPE >>>>>>>>>>>>>>> <white>"..tostring(stats and stats[3] or ""))