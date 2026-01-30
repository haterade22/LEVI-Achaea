--[[mudlet
type: trigger
name: Coagulate
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Shaman
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
- pattern: ^With methodical ruthlessness you cast your hand at \w+, a wash of cold causing \w+ blood to evolve into something
    new.$
  type: 1
]]--

ataxiaTemp.coagulate = true
tarAffed(ataxiaTemp.coagulateAff)
if partyrelay and not ataxia.afflictions.aeon then send("pt "..target..": "..ataxiaTemp.coagulateAff) end
tAffs.bleed = tAffs.bleed - 140
if tAffs.bleed < 0 then tAffs.bleed = nil end