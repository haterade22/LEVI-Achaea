--[[mudlet
type: trigger
name: Shin Augment Channel
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Highlighting
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
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
packageName: ''
patterns:
- pattern: ^You focus inward, drawing upon your reserves of shin energy\.$
  type: 1
]]--

-- SHIN AUGMENT, the CHANNEL BEGINNING (captured live 2026-08-12). AB 316 takes 4 seconds to
-- activate in all cases, and this is second zero of that window -- not the moment cover starts.
--
-- Wired because it is the only proof the command was ACCEPTED. The Lua-side attempt-hold is armed
-- at SEND time, which is a guess; this is the game agreeing. It re-arms the hold from the confirmed
-- start, so the 4s activation is measured from when it really began rather than from when we asked.
if ataxiaBasher_bmAugmentChannel then ataxiaBasher_bmAugmentChannel() end

selectString(line, 1)
fg("light_blue")
deselect()
resetFormat()
