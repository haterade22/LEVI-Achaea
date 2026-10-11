--[[mudlet
type: trigger
name: Backstab Refused
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
- pattern: You must be hiding or phased to backstab
  type: 2
]]--

-- THE BACKSTAB WAS REFUSED (v4.7.413, user: "this should mean that we are not hidden and need to
-- continue with attacking with garrote or biting"):
--
--   You must be hiding or phased to backstab.
--
-- We are not hidden: drop the hidden window and the `hiding` defence and re-send the round, which is
-- then the normal garrote (or the camus bite with the venom boons). Logic in basher/002.
if ataxiaBasher_serpentBackstabRefused then ataxiaBasher_serpentBackstabRefused() end
