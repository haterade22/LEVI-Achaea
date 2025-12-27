--[[mudlet
type: trigger
name: DWB Torso - Affliction 2 - Flails
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
- pattern: ^\w+ doubles over as the flail savagely crunches into \w+ ribcage\.$
  type: 1
]]--

if ataxiaTemp.fractures.crackedribs == 0 or ataxiaTemp.fractures.crackedribs == nil then
    ataxiaTemp.fractures.crackedribs = 1
    twohanded_torsoHit()
else
    ataxiaTemp.fractures.crackedribs = math.min(7, ataxiaTemp.fractures.crackedribs + 1)
    twohanded_torsoHit()
end
if partyrelay then send("pt "..target..": asthma and " ..ataxiaTemp.fractures.crackedribs.. " crackedribs") end

tarAffed("asthma")
tempTimer(2.5, [[tarAffed("asthma"]])
   
