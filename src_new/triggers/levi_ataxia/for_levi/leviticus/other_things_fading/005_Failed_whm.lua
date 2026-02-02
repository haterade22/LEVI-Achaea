--[[mudlet
type: trigger
name: Failed whm
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Other Things Fading
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
- pattern: ^You pass your hand in front of (\w+)\. \w+ shakes \w+ head as if clearing \w+ mind.$
  type: 1
]]--

local whm = {"dementia", "stupidity", "confusion", "hypersomnia", "paranoia", "hallucinations", "impatience", "addiction", "agoraphobia", "lovers", "loneliness", "recklessness", "masochism"}

selectString(line,1)
fg("black")
bg("orange")
deselect()
resetFormat()

for _, aff in pairs(whm) do
  erAff(aff)
  if removeAffV3 then removeAffV3(aff) end
end