--[[mudlet
type: trigger
name: Puncture (Weariness | Arms)
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
- pattern: ^With a lightning-fast jab of your blade you puncture the cluster of nerves just below the (left|right) shoulder
    of \w+.$
  type: 1
]]--



if tprepare == "disruption" then
send("pt " ..target..": Weariness Paralysis")
elseif tprepare == "laceration" then
send("pt " ..target..": Weariness Haemophilia")
elseif tprepare == "dazzle" then
send("pt " ..target..": Weariness Clumsiness")
elseif tprepare == "rattle" then
send("pt " ..target..": Weariness Epilepsy")
elseif tprepare == "vapours" then
send("pt " ..target..": Weariness Asthma")
else
send("pt " ..target..": Weariness")
end
