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
    magi.offense = magi.offense or {}
    magi.offense.state = magi.offense.state or {}
    magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
    tburns = magi.offense.state.burns -- backward compat
    tarAffed("burning")
  cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Burning") end
  elseif not tAffs.scalded then
    tarAffed("scalded")
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Scalded") end
    tempTimer(20, [[erAff("scalded")]])
  end

  
end
  
 

