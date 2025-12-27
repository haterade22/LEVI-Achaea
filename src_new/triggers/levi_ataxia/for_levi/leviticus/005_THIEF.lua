--[[mudlet
type: trigger
name: THIEF
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MINE ALL MINE
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
- pattern: ^(\w+) snaps (\w+) fingers in front of you.$
  type: 1
]]--

target = matches[2]
moveCursor(0,getLineCount())
deleteFull()
cecho("\n<white>(((((((((((((((((((( " .. matches[2] .. " ))))))))))))))))))))\n ((((((((((((((( YOU WERE SNAPPED! A THIEF? )))))))))))))))")


if isAnsiFgColor(5) then
send("curing prioaff impatience")
send("cq all;touch shield")
myaeon = true
tempTimer(3,[[myaeon = false]])
end
