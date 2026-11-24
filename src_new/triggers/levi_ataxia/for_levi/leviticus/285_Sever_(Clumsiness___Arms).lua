--[[mudlet
type: trigger
name: Sever (Clumsiness | Arms)
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
- pattern: ^With a precise strike you sever the muscles in the (left|right) arm of \w+.$
  type: 1
]]--


if tprepare == "disruption" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Clumsiness Paralysis") end
elseif tprepare == "laceration" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Clumsiness Haemophilia") end
elseif tprepare == "dazzle" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Clumsiness Clumsiness") end
elseif tprepare == "rattle" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Clumsiness Epilepsy") end
elseif tprepare == "vapours" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Clumsiness Asthma") end
else
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Clumsiness") end
end
