--[[mudlet
type: trigger
name: Mnemosyne Thunderclap
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
- pattern: ^Thunderclap\s+\d+\s+\w+
  type: 1
]]--

-- BOONS row: "Your bisect ability now strikes a third time, dealing bonus electric damage
-- to all denizens in your location."
--
-- That converts BISECT from a single-target finisher into a ROOM hit, so the Runewarden
-- basher swings it instead of the normal attack at 2+ denizens (ataxiaBasher_rwBisect,
-- basher/002 -- ataxiaBasher.bisectAt to tune).
--
-- Crowd-gated rather than default because bisect spends 4.00s of BALANCE (AB) against the
-- SnB combination's ~2s: it is roughly a double-length swing and only pays for itself when
-- the third strike lands on more than one mob. Exactly the Infernal Arc trade.
--
-- Two things from the AB entry that deliberately do NOT drive logic: the "slain outright at
-- <=20% health" execute is ADVENTURERS ONLY (no PvE value), and bisect bypasses rebounding
-- and reflections while leaving them intact (so it needs no raze handling and provides none
-- -- a denizen shield must still be broken first).
--
-- PREREQUISITE the system does NOT manage: bisect needs an edged runeblade with the HUGALAZ
-- rune on the blade. Nothing here knows hugalaz and the blade-sketch syntax was never
-- captured, so keeping it on the weapon is the user's setup (their decision, 2026-07-31).
mnemThunderclap = true
