--[[mudlet
type: trigger
name: DWB Arms - Affliction - Flails
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- DWB
- Dual Blunt
- Expend Afflictions
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
- pattern: ^Your flail rips at the \w+ \w+ of \w+, leaving it a raw and bloody mess\.$
  type: 1
]]--

if tAffs.paralysis then
  if ataxiaTemp.fractures.wristfractures == 0 or ataxiaTemp.fractures.wristfractures == nil then
    ataxiaTemp.fractures.wristfractures = 1
    twohanded_armsHit()
  else
    ataxiaTemp.fractures.wristfractures =  ataxiaTemp.fractures.wristfractures + 1
    twohanded_armsHit()
  end
   if partyrelay then send("pt "..target..": paralysis and " ..ataxiaTemp.fractures.wristfractures.. " wristfractures") end
   
else
  tarAffed("paralysis")
  if applyAffV3 then applyAffV3("paralysis") end
   if partyrelay then send("pt "..target..": paralysis") end

end

tempTimer(2.5, [[tarAffed("paralysis"); if applyAffV3 then applyAffV3("paralysis") end]])