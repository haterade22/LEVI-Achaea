--[[mudlet
type: trigger
name: Pyramid port
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
- pattern: Your hands become a blur as you twist and turn a paradox puzzle pyramid until each side is made up of the same
    colour, solving the puzzle in mere moments. Suddenly the image of
  type: 2
- pattern: ^Your hands become a blur as you twist and turn a paradox puzzle pyramid until each side is made up of the same
    colour, solving the puzzle in mere moments. Suddenly the image of (.*) appears in the back of your mind and you feel drawn
    towards it\.$
  type: 1
]]--

local t = mmp.getnums(multimatches[2][2])
if not t then return end

echo"\n"

if #t == 1 then
	cecho("<red>Porting to <orange_red>"..mmp.areatabler[getRoomArea(t[1])].."<red>.")
else
	cecho("<red>Might be porting to <orange_red>"..mmp.areatabler[getRoomArea(t[1])].."<red>.")
end	