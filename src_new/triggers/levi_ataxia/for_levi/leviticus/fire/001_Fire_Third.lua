--[[mudlet
type: trigger
name: Fire Third
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
  isActive: 'no'
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
- pattern: ^The incandescent might of Elemental Fire filling you, you command (\w+) to burn from within\.$
  type: 1
]]--

if target == matches[2] then
  if tAffs.blistered then
    magi.offense = magi.offense or {}
    magi.offense.state = magi.offense.state or {}
    magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
    tburns = magi.offense.state.burns -- backward compat
    tarAffed("burning")
    cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
  elseif not tAffs.blistered then
    tarAffed("blistered")
    tempTimer(15, [[erAff("blistered")]])
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Blistered and Scalded") end
  end
end
  
  

 
