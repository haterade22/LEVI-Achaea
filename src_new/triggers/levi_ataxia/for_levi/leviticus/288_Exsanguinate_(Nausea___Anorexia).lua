--[[mudlet
type: trigger
name: Exsanguinate (Nausea | Anorexia)
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
- pattern: ^Stepping forward, you brutally drive a translucent sword into \w+'s guts, ripping it free in a spray of crimson.$
  type: 1
]]--



if tprepare == "disruption" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Nausea Paralysis") end
elseif tprepare == "laceration" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Nausea Haemophilia") end
elseif tprepare == "dazzle" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Nausea Clumsiness") end
elseif tprepare == "rattle" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Nausea Epilepsy") end
elseif tprepare == "vapours" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Nausea Asthma") end
else
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Nausea") end
end




