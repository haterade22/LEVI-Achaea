--[[mudlet
type: trigger
name: Mnemosyne Dizzy Fall
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
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
- pattern: ^The ground seems to tilt and you fall with a thump
  type: 1
]]--

-- DIZZINESS (v4.7.426, user 2026-10-15): the move failed, we fell prone and lost balance, but the exit
-- is fine. Dizziness can be uncurable, so this can happen on every step of a run. Let the explorer
-- re-send the move instead of condemning the exit. The logic is in ataxia.mnemosyne.onDizzyFall
-- (008), where the tests can see it.
if ataxia.mnemosyne and ataxia.mnemosyne.onDizzyFall then ataxia.mnemosyne.onDizzyFall() end
