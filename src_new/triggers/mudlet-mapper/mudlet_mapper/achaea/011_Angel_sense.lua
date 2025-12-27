--[[mudlet
type: trigger
name: Angel sense
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
mStayOpen: 100
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: 'Your guardian angel senses '
  type: 2
- pattern: ^Your guardian angel senses .+? at (.+?),
  type: 1
]]--

local t = mmp.getnums(multimatches[2][2], true)
if not t then return end
if #t == 1 then
	cecho(" <orange_red>("..mmp.cleanAreaName(mmp.areatabler[getRoomArea(t[1])])..")")
else
	cecho(" <orange_red>Maybe ("..mmp.cleanAreaName(mmp.areatabler[getRoomArea(t[1])])..")")
end
echo " "; mmp.echonums(multimatches[2][2])

mmp.temp_room = multimatches[2][2]