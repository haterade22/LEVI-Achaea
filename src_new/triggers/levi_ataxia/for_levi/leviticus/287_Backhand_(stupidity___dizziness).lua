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
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Stupidity Dizziness Paralysis") end
elseif tprepare == "laceration" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Stupidity Dizziness Haemophilia") end
elseif tprepare == "dazzle" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Stupidity Dizziness Clumsiness") end
elseif tprepare == "rattle" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Stupidity Dizziness Epilepsy") end
elseif tprepare == "vapours" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Stupidity Dizziness Asthma") end
else
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Stupidity Dizziness") end
end


