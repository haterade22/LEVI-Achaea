--[[mudlet
type: trigger
name: Arms
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- INFERNAL
- Fractures
- Decrease Fracture Count
- Devastate
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
- pattern: ^Bringing (.+?) around in a savage arc, you viciously pulverise the already injured arms of (\w+).$
  type: 1
]]--

if isTargeted(matches[3]) then

  if ataxiaTemp.fractures.torntendons >= 6 then
    tarAffed("mangledleftarm", "mangledrightarm")
  elseif ataxiaTemp.fractures.torntendons >= 4 then
    tarAffed("damagedleftarm", "damagedrightarm")
  else
    tarAffed("brokenleftarm", "brokenrightarm")
  end
  
  ataxiaTemp.fractures.wristfractures = 0
  twohanded_armsHit()  
end