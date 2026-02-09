--[[mudlet
type: trigger
name: Flayed Sileris
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
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
- pattern: ^You flay the metallic coating from \w+\.$
  type: 1
- pattern: ^You try to flay a non-existent sileris coating from (\w+)\.$
  type: 1
- pattern: ^A death adder lunges for the throat of (\w+), fangs sinking through \w+ fang barrier defence\.$
  type: 1
- pattern: ^The protective coating covering the skin of \w+ is ripped away with \w+ protections\.$
  type: 1
- pattern: ^The protective coating covering the skin of \w+ sloughs off\.$
  type: 1
]]--

tAffs.fangbarrier = false
if removeAffV3 then removeAffV3("fangbarrier") end
tAffs.sileris = false
if removeAffV3 then removeAffV3("sileris") end