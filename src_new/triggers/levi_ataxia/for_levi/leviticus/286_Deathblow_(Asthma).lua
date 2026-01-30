--[[mudlet
type: trigger
name: Deathblow (Asthma)
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
- pattern: ^Striking like coiled lightning, your hand flashes out and lays open the throat of \w+ with a translucent dagger
    in a spray of crimson.$
  type: 1
]]--


if partyrelay and not ataxia.afflictions.aeon then
if tprepare == "disruption" then
send("pt " ..target..": Asthma and Paralysis")
elseif tprepare == "laceration" then
send("pt " ..target..": Asthma and Haemophilia")
elseif tprepare == "dazzle" then
send("pt " ..target..": Asthma and Clumsiness")
elseif tprepare == "rattle" then
send("pt " ..target..": Asthma and Epilepsy")
elseif tprepare == "vapours" then
send("pt " ..target..": Asthma and Asthma")
else
send("pt " ..target..": Asthma")
end
end
