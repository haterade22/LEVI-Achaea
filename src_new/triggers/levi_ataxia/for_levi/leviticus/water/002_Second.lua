--[[mudlet
type: trigger
name: Second
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- RESONANCE
- Water
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
- pattern: ^You summon up a flurry of icicles to slash at Antoninus in a shower of freezing daggers\.$
  type: 1
]]--

if target == matches[2] then
  tarAffed("stuttering")
  if applyAffV3 then applyAffV3("stuttering") end
   if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Stuttering") end
end