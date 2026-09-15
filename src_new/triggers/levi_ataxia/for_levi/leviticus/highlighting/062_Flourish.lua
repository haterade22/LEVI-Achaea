--[[mudlet
type: trigger
name: Flourish Landed
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
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: through the air in a dazzling display
  type: 0
- pattern: while your feet shift to a new stance
  type: 0
]]--

-- BLADE FLOURISH landed. Captured live 2026-09-15:
--
--   "You weave a Soulpiercer through the air in a dazzling display, the music of your bladesong
--    sweeping forth to wash over Seasone the Industrious while your feet shift to a new stance."
--
-- TWO SUBSTRING FRAGMENTS because the line is ~190 characters and Achaea wraps server-side at the
-- player's WIDTH (v4.7.286, the 057/058 convention): one early, after the variable weapon name,
-- one at the very end after the variable target name. Either confirms; when the wrap splits them
-- onto two physical lines both rows get coloured and the confirm runs twice, which is harmless --
-- it re-stamps the same moment.
--
-- The word "flourish" is deliberately NOT in either fragment: HIGHSUN's line begins "With a
-- flourish of <weapon>..." (blade_dance/005) and an enemy bard's class-grab line uses it too.
--
-- Feeds `ataxiaBasher_bardFlourishConfirm` (basher/002): the Deadly Flourish boon's 15s restarts
-- from the LANDED moment and the in-flight replay is released. The line prints for a flourish
-- with or without the boon, so it does NOT latch the flag. `chartreuse` bold is this package's
-- attack-landed colour (Arc, Thunderclap bisect, Spirit Rend).
selectString(line, 1)
fg("chartreuse")
setBold(true)
deselect()
resetFormat()

if ataxiaBasher_bardFlourishConfirm then
  ataxiaBasher_bardFlourishConfirm()
end
