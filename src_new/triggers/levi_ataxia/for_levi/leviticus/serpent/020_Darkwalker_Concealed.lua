--[[mudlet
type: trigger
name: Darkwalker Concealed
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
- pattern: You swiftly return to concealment in the wake of your triumph
  type: 2
]]--

-- DARKWALKER REHIDES US (v4.7.408, user: "this rehides us also").
--
--   You swiftly return to concealment in the wake of your triumph.
--
-- Darkwalker ("Defeating a denizen will render you hidden") prints this on the kill. With Assassin's
-- Blade the basher opens on the next denizen with `wield dirk;backstab <target>`, and this line lets
-- it do so before GMCP's `hiding` defence arrives. The logic is in basher/002 so it is testable.
if ataxiaBasher_serpentConcealed then ataxiaBasher_serpentConcealed() end
