--[[mudlet
type: trigger
name: Fulminate
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
- pattern: ^You click your fingers and lightning strikes from the air to smite (\w+)\.$
  type: 1
]]--

if target == matches[2] then
  if tAffs.epilepsy and tAffs.fulminated and not tAffs.paralysis then
    tarAffed("paralysis")
    if applyAffV3 then applyAffV3("paralysis") end
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Paralysis") end
  elseif not tAffs.epilepsy and tAffs.fulminated then
    tarAffed("epilepsy")
    if applyAffV3 then applyAffV3("epilepsy") end
    if partyrelay and not ataxia.afflictions.aeon  then send("pt " ..target.. ": Epilepsy") end
  else
  tarAffed("fulminated")
  if applyAffV3 then applyAffV3("fulminated") end
  if partyrelay and not ataxia.afflictions.aeon  then send("pt " ..target.. ": Fulminated") end
  end

end
  
 
