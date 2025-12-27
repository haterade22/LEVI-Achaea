--[[mudlet
type: trigger
name: 'Pyramid probe #'
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
- pattern: You lightly caress a button on a paradox puzzle pyramid and suddenly a hazy image of
  type: 2
- pattern: ^You lightly caress a button on a paradox puzzle pyramid and suddenly a hazy image of (.*) flashes momentarily
    in front of you\.$
  type: 1
]]--

local t = mmp.getnums(multimatches[2][2])
if not t then return end

echo"\n"

if #t == 1 then
	cecho("<red>From your knowledge, that room is in <orange_red>"..mmp.areatabler[getRoomArea(t[1])].."<red>.")
else
	cecho("<red>From your knowledge, that room might be in <orange_red>"..mmp.areatabler[getRoomArea(t[1])].."<red>.")
end