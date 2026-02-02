--[[mudlet
type: trigger
name: DWB Arms - Affliction 2 - Flails
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
- pattern: ^The wet crunch of bone can be heard as the flail smashes into the \w+ \w+ of \w+\.$
  type: 0
]]--

if ataxiaTemp.fractures.wristfractures == 0 or ataxiaTemp.fractures.wristfractures == nil then
  ataxiaTemp.fractures.wristfractures = 1
  twohanded_armsHit()
else
  ataxiaTemp.fractures.wristfractures =  ataxiaTemp.fractures.wristfractures + 1
  twohanded_armsHit()
end
tarAffed("paralysis")
if applyAffV3 then applyAffV3("paralysis") end

if partyrelay then send("pt "..target..": paralysis and " ..ataxiaTemp.fractures.wristfractures.. " wristfractures") end

tempTimer(2.5, [[tarAffed("paralysis"); if applyAffV3 then applyAffV3("paralysis") end]])