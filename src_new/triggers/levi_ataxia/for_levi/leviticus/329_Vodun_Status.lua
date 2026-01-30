--[[mudlet
type: trigger
name: Vodun Status
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Vodun
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
- pattern: ^You gaze into the eyes of the doll and see that \w+ has a health of (\d+)/(\d+) and a mana of (\d+)/(\d+).$
  type: 1
]]--

local mp, mmp, hp, mhp = matches[4], matches[5], matches[2], matches[3]
deleteLine()
cecho("\n<orange>  [<white>"..target:title().."<orange>]  <red>HP: <firebrick>"..math.floor((hp/mhp)*100).."%<white>  |  <blue>MP: <DodgerBlue>"..math.floor((mp/mmp)*100).."%<orange>  [<white>"..target:title().."<orange>]")
manapercent = math.floor((mp/mmp)*100)