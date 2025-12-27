--[[mudlet
type: trigger
name: Crit Hit
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- zData
- zData
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
mFgColor: '#ffaa00'
mBgColor: '#000000'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You have scored (an|a) (.*) hit!$
  type: 1
- pattern: ^You have scored (an|a) (.*) hit!!!$
  type: 1
]]--

zData.db.addChar("crithits")
if matches[3] == "CRITICAL" then
  zData.db.addChar("crit1")
elseif matches[3] == "CRUSHING CRITICAL" then
  zData.db.addChar("crit2")
elseif matches[3] == "OBLITERATING CRITICAL" then
  zData.db.addChar("crit3")
elseif matches[3] == "ANNIHILATINGLY POWERFUL CRITICAL" then
  zData.db.addChar("crit4")
elseif matches[3] == "WORLD-SHATTERING CRITICAL" then
  zData.db.addChar("crit5")
elseif matches[3] == "PLANE-RAZING CRITICAL" then
  zData.db.addChar("crit6")
end