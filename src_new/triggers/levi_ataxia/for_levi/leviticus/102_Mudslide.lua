--[[mudlet
type: trigger
name: Mudslide
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- General
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
- pattern: ^You weave earth and water and a torrent of thick mud thunders forth to roll over (\w+), knocking (.+) sprawling\.$
  type: 1
]]--

tarAffed("slickness")
if applyAffV3 then applyAffV3("slickness") end
tarAffed("prone")
if applyAffV3 then applyAffV3("prone") end
if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Prone and Slickness") end
