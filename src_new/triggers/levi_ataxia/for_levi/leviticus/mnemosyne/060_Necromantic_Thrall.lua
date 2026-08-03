--[[mudlet
type: trigger
name: Mnemosyne Necromantic Thrall
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
- pattern: ^The dead rise once more as mindless thralls!$
  type: 1
]]--

-- THE NECROMANTIC AFFIX FIRING. "Denizens may revive as mindless thralls." -- and this is the
-- line, captured live 2026-08-03. It was flagged as wanted twice (v4.7.196, v4.7.206) for one
-- specific reason: **a thrall is a NEW DENIZEN IN A ROOM WE JUST CLEARED.**
--
-- That is the exact state the auto-explorer trusts to decide it is done here. `_roomHasDenizens`
-- reads `ataxia.denizensHere` (GMCP Char.Items), the room reads CLEAR the instant the last mob
-- dies, and the sweep steps out -- while the corpse behind us stands back up. The room-clear
-- decision and the revival are racing, and nothing told the explorer to look again.
--
-- So this does two things:
--   1. HIGHLIGHT + ECHO. The line is easy to lose in a kill's worth of scroll, and it changes
--      what the room is.
--   2. Force a re-look. `M._watchdogNudge()` is the existing "re-read the room and re-decide on
--      fresh data" path (a QL refresh plus a re-tick), so the sweep re-evaluates instead of
--      walking out on a stale snapshot. Deliberately reusing that rather than inventing a new
--      nudge: it already handles the moving/paused guards.
--
-- GMCP usually updates on its own, so this is a belt-and-braces re-check rather than the only
-- signal -- but the cost of missing it is trailing an aggressive denizen through the grid,
-- which is precisely the failure v4.7.169/170 documented for shadowed own-denizens.
selectString(line, 1)
setBold(true)
fg("medium_orchid")
deselect()
resetFormat()

if ataxiaEcho then
  ataxiaEcho("<medium_orchid>NECROMANTIC<reset> -- the dead rose as thralls; this room is NOT clear.")
end

local M = ataxia and ataxia.mnemosyne
if M and M.explore and M.explore.on and M._watchdogNudge then
  pcall(M._watchdogNudge)
end
