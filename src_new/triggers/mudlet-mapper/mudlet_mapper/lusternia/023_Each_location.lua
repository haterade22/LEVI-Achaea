--[[mudlet
type: trigger
name: Each location
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Lusternia
- Pyramid probe
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
- pattern: ^Puzzle point \d+ is set to (.+) \(
  type: 1
]]--

local t = mmp.getnums(matches[2])
if not t then return end

if #t == 1 then
	cecho("<red> (in <orange_red>"..mmp.areatabler[getRoomArea(t[1])].."<red>)")
else
	cecho("<red> (might be in <orange_red>"..mmp.areatabler[getRoomArea(t[1])].."<red>)")
end