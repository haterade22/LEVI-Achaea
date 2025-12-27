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
  if tAffs.burns == 0 then 
     tAffs.burns = 1
  elseif tAffs.burns == 1 then
    tAffs.burns = 2
  elseif tAffs.burns == 2 then
    tAffs.burns = 3
  elseif tAffs.burns == 3 then
    tAffs.burns = 4
  elseif tAffs.burns == 4 then
    tAffs.burns = 5
  elseif tAffs.burns == 5 then
    tAffs.burn = 5
  end
  if tburns == 0 or nil then
     tburns = 1
  elseif tburns == 1 then
    tburns = 2
  elseif tburns == 2 then
    tburns = 3
  elseif tburns == 3 then
    tburns = 4
  elseif tburns == 4 then
    tburns = 5
  elseif tburns == 5 then
    tAffs.burn = 5
  end
cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
end

if not magi.firestorm then
  magi.firestorm = gmcp.Room.Info.num
end

magi.firestormm = true

tarAffed("firestorm")