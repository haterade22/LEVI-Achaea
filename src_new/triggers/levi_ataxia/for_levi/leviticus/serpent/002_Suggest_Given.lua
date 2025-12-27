--[[mudlet
type: trigger
name: Suggest Given
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Serpent
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
- pattern: ^You issue the suggestion, concealing it deep within (\w+)'s mind\.$
  type: 1
- pattern: ^(\w+)'s mind is already holding something quite similar to that suggestion\.$
  type: 1
]]--

--cecho("<a_brown> (<a_darkcyan>"..ataxiaTemp.suggestAff.."<a_brown>)")
--table.insert(ataxiaTemp.suggestions, 1, ataxiaTemp.suggestAff)
ataxia_boxEcho("SUGGESTION GIVEN!", "gold:white")
serpentsuggest = true