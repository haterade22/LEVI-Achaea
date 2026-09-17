--[[mudlet
type: trigger
name: Kai Choke Landed
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
- pattern: gasps and stumbles as an unseen force
  type: 0
- pattern: crushes the life breath out of
  type: 0
]]--

-- KAI CHOKE, the TARGET's half. Live-captured 2026-09-17:
--
--   "A revolting ghoul gasps and stumbles as an unseen force crushes the life breath out of him."
--
-- The cast line (`leviatax/004_Kai_Choke.lua`) says we tried; THIS says it landed on something.
-- Nothing in the tree matched it before, which is why a choke without the Kai Unleashed boon had
-- no visible confirmation at all -- the only confirmed-landing line we had was the boon's BURST
-- ("Your surroundings ripple like a lake's surface struck...", `mnemosyne/031`), and that one
-- cannot print unless the boon is held.
--
-- TWO SUBSTRING FRAGMENTS, and here the name forces it: the denizen's short description opens the
-- line and is of arbitrary length, so an anchored pattern spanning it breaks on Achaea's
-- server-side wrap (v4.7.286, and the v4.7.313 `\w+` lesson -- "A revolting ghoul" is three words,
-- never the one a player name would be). Both fragments start well clear of the name, and the
-- trailing pronoun ("him"/"her"/"it", by the denizen's gender) is never matched.
--
-- PURE HIGHLIGHT, deliberately. It is tempting to clear `ataxiaTemp.kaiChokePendingAt` here -- it
-- would be an honest confirmation, where today that guard just ages out after KAI_CHOKE_RETRY --
-- but the guard exists so an EATEN choke retries, and a flag cleared only by a confirmation is a
-- livelock the moment the confirmation cannot arrive (the v4.7.167 rule). That is a behaviour
-- change worth making on its own evidence, not a side effect of adding a colour.
--
-- `chartreuse` bold: this package's attack-LANDED colour, matching the cast line and the Spirit
-- Rend confirmation (`mnemosyne/080`).
selectString(line, 1)
fg("chartreuse")
setBold(true)
deselect()
resetFormat()
