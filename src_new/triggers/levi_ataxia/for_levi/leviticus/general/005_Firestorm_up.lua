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

if target == matches[2] then
selectCurrentLine() fg("red")
  magi.offense = magi.offense or {}
  magi.offense.state = magi.offense.state or {}
  magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
  tburns = magi.offense.state.burns -- backward compat
  tAffs.burns = tburns
  tarAffed("burning")
cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
end

if not magi.firestorm then
  magi.firestorm = gmcp.Room.Info.num
end

magi.firestormm = true

tarAffed("firestorm")