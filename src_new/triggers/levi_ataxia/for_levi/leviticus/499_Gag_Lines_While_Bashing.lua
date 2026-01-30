--[[mudlet
type: trigger
name: Gag Lines While Bashing
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Fire Lord
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
- pattern: The very air warps about you as your flames burn ever brighter.
  type: 3
- pattern: Your fires begin to rage with the desire to consume.
  type: 3
- pattern: The fires crackling across your primal form bolster your eternal flame.
  type: 3
- pattern: A crown of flames ignites about your head, a mark of Kkractle's esteem.
  type: 3
]]--

if ataxiaBasher.enabled then
  deleteFull()
end