--[[mudlet
type: trigger
name: Aeonic Deteriorate Proc
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
- pattern: ^Time wreaks ruin upon (.+), deteriorating before your eyes\.$
  type: 1
]]--

-- CHRONO DETERIORATE landing (captured live 2026-08-12, ~129 psychic a tick on an haruspex of
-- Life). It is the confirmation the aeonic cash-in needs and the only evidence it has: the ability
-- carries no cooldown feed of its own.
--
-- Two jobs, both in ataxiaBasher_dwAeonicConfirm:
--   * RELEASE the in-flight replay, so the round stops re-queueing a cast that already fired and
--     goes back to swinging.
--   * SPEND the affliction in our denizen model. Without that the very next rebuild sees the same
--     affliction still recorded and cashes in again at 300-700 age -- on a 30s amnesia that is up
--     to five casts for one application.
--
-- The line REPEATS as the effect ticks. That is harmless: the first call releases the replay and
-- clears the affliction, and every later one is a no-op on both counts.
if ataxiaBasher_dwAeonicConfirm then ataxiaBasher_dwAeonicConfirm() end

-- chartreuse bold: the attack-landing family, as arc / Thunderclap bisect / the distortion proc.
selectString(line, 1)
setBold(true)
fg("chartreuse")
deselect()
resetFormat()
