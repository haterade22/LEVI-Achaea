--[[mudlet
type: trigger
name: Boon Combo Granted
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
- pattern: ^With every required boon now in hand, the mist of the Mnemosyne parts and bestows upon you another: (.+)\.$
  type: 1
]]--

-- The COMBO REWARD, granted rather than claimed (live 2026-09-19):
--   With every required boon now in hand, the mist of the Mnemosyne parts and bestows upon you
--   another: Lightning Soul.
-- Nothing else sees this boon -- it is never offered and never claimed -- so `onComboBoonGranted`
-- records it, names the recipe it finished, and asks for its contemplate (which carries the
-- recipe for the NEXT chain).
local M = ataxia and ataxia.mnemosyne
if M and M.onComboBoonGranted then M.onComboBoonGranted(matches[2]) end
