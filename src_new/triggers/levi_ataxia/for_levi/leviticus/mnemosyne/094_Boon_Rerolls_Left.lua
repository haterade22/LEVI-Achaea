--[[mudlet
type: trigger
name: Boon Rerolls Left
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
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
- pattern: ^BOON REROLL to discard these options and see new ones \((\d+) remaining\)
  type: 1
]]--

-- The offer screen's footer (live, 2026-09-19):
--   BOON REROLL to discard these options and see new ones (1 remaining).
-- The advisor (v4.7.327) suggests a reroll only when one is left.
local M = ataxia and ataxia.mnemosyne
if M and M.onRerollsRemaining then M.onRerollsRemaining(matches[2]) end
