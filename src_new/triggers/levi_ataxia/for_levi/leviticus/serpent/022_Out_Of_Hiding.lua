--[[mudlet
type: trigger
name: Out Of Hiding
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
- pattern: Your attack has brought you out of hiding
  type: 2
]]--

-- OUT OF HIDING (v4.7.412, user-supplied):
--
--   Your attack has brought you out of hiding.
--
-- The game's own word that we are no longer hidden, whatever the attack was. Same handling as the
-- landed backstab (serpent/021): drop the hidden window and the `hiding` defence, so the next round
-- swings normally until Darkwalker or a HIDE hides us again. No highlight: it is not an attack.
if ataxiaBasher_serpentBackstabbed then ataxiaBasher_serpentBackstabbed() end
