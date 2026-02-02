--[[mudlet
type: trigger
name: DWB Torso - Affliction - Flails
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
- pattern: ^Your blow crunches home into the chest of \w+\.$
  type: 1
]]--

if not tAffs.asthma then
  tarAffed("asthma")
  if applyAffV3 then applyAffV3("asthma") end
   if partyrelay then send("pt "..target..": asthma") end

end


tempTimer(2.5, [[tarAffed("asthma"); if applyAffV3 then applyAffV3("asthma") end]])