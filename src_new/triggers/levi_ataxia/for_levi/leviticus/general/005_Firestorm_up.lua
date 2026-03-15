--[[mudlet
type: trigger
name: Firestorm up
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- General
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
- pattern: You summon up the might of Elemental Fire, and in an instant a raging firestorm explodes into being to devour all
    who would oppose you.
  type: 3
]]--

selectCurrentLine() fg("red")

-- Burns tracking handled by 025_Burns_Tracking.lua on firestorm ticks
if not magi.firestorm then
  magi.firestorm = gmcp.Room.Info.num
end

-- magi.firestorm already set above (stores room number)

tarAffed("firestorm")