--[[mudlet
type: trigger
name: Hiraku (ano/stutt)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
- 3rd Person Shikudo
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
- pattern: ^The staff smashes into the face of (\w+) with a sickening crunch.$
  type: 1
]]--

if isTargeted(matches[2]) then
  if not ignoreThirdPerson then
    tarAffed("anorexia", "stuttering")
    if applyAffV3 then applyAffV3("anorexia"); applyAffV3("stuttering") end
  else
    ignoreThirdPerson = nil
  end
end