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
- Earth
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
- pattern: ^You bleed off residual power from your connection with the Elemental Plane of Earth, directing it in an unfocussed
    blast of arcane might at (\w+).
  type: 1
]]--

if target == matches[2] then
  if not tAffs.paralysis then
    tarAffed("paralysis")
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Paralysis") end
  end
end