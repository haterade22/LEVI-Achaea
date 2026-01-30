--[[mudlet
type: trigger
name: Impaled
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes Other
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
- pattern: ^You draw your blade back and plunge it deep into the body of (\w+) impaling \w+ to the hilt.$
  type: 1
- pattern: You cannot do that while your weapon remains deep in your victim's gut.
  type: 3
]]--

selectString(line,1)
fg("black")
bg("DodgerBlue")
if ataxia_isClass("runewarden") or ataxia_isClass("paladin") or ataxia_isClass("infernal") or ataxia_isClass("unnamable") then
  send("fury on")
end

tAffs.impaled = true

disableTimer("Battlefury Perceive")