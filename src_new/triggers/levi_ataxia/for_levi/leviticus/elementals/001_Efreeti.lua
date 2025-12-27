--[[mudlet
type: trigger
name: Efreeti
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- Elementals
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
- pattern: ^(\w+) bursts into flame as a fiery efreeti spins into (\w+)\.$
  type: 1
]]--

if isTargeted(matches[2]) then
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
    tAffs.burns = 5
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
	tburns= 5
  end
  cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
end