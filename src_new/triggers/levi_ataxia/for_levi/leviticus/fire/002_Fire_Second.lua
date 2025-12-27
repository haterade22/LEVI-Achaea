--[[mudlet
type: trigger
name: Fire Second
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- RESONANCE
- Fire
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
mStayOpen: 15
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You will that (\w+) should burn, and so \w+ does\.$
  type: 1
]]--

if target == matches[2] then
  if tAffs.scalded then
    if tburns == 0 or nil then
     tburns = 1
    else
    tburns = tburns + 1
    end
  cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Burning") end
  elseif not tAffs.scalded then
    tarAffed("scalded")
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Scalded") end
    tempTimer(20, [[erAff("scalded")]])
  end

  
end
  
 

