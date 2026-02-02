--[[mudlet
type: trigger
name: Water First
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
- pattern: ^As you begin to tap your connection with the Elemental Plane of Water, you summon up a freezing wave to deluge
    (\w+)\.$
  type: 1
]]--

if target == matches[2] then
  tarAffed("frostbite")
  if applyAffV3 then applyAffV3("frostbite") end
  if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Frostbite") end
end