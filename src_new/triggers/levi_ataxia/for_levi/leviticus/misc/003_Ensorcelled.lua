--[[mudlet
type: trigger
name: Ensorcelled
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Pariah
- Misc
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
- pattern: ^You sweep your blade in a circle above your head, the point coming to rest pointed at (\w+). A fine crimson spray
    follows the arc of your blade, and you know that your ensorcelment has born fruit.$
  type: 1
]]--

pariah.bladePrepared = true
tarAffed("ensorcelled")

if pariah.ensorcell then killTimer(pariah.ensorcell) end
pariah.ensorcell = tempTimer(21, [[ erAff("ensorcelled") ]])