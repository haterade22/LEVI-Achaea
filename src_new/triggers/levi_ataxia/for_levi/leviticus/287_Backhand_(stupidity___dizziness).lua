--[[mudlet
type: trigger
name: Backhand (stupidity | dizziness)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Psion
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
- pattern: ^You deliver a savage backhanded blow with a translucent mace to the face of \w+.$
  type: 1
]]--

if tprepare == "disruption" then
send("pt " ..target..": Stupidity and Dizziness and Paralysis")
elseif tprepare == "laceration" then
send("pt " ..target..": Stupidity and Dizziness and Haemophilia")
elseif tprepare == "dazzle" then
send("pt " ..target..": Stupidity and Dizziness and Clumsiness")
elseif tprepare == "rattle" then
send("pt " ..target..": Stupidity and Dizziness and Epilepsy")
elseif tprepare == "vapours" then
send("pt " ..target..": Stupidity and Dizziness and Asthma")
else
send("pt " ..target..": Stupidity and Dizziness")
end


