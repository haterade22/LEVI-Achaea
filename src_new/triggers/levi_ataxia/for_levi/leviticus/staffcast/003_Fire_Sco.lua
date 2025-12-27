--[[mudlet
type: trigger
name: Fire Sco
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- Staffcast
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
- pattern: ^Flames ignite all over the body of (\w+), fanned to intensity in an instant\.$
  type: 1
]]--

if isTargeted(matches[2]) then
  if tAffs.burns == 0 or tAffs.burns == nil then 
     tAffs.burns = 1
  else
    tAffs.burns = tAffs.burns + 1
  end


  if tburns == 0 or nil then
     tburns = 1
  else
    tburns = tburns + 1
  end
timmolation = false
cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
end
