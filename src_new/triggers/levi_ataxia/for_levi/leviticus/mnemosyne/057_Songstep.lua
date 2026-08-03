--[[mudlet
type: trigger
name: Mnemosyne Songstep
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
- pattern: ^Songstep\s+\d+\s+\w+
  type: 1
]]--

-- BOONS row (legendary): "Your dances gain additional bonuses. Hawkstep: Gain 25% resistance
-- to damage. Wavedance: Ignore 75% of a denizen's resistance. Harrying: Deal 50% bonus
-- damage."
--
-- THE COST IS THE WHOLE DESIGN. AB Hawkstep (3193) is "3.00 seconds of BALANCE", and the AB
-- states outright that "you can only dance one thing at a time" -- the dances are mutually
-- exclusive. So unlike the Shindo storms (equilibrium, free beside the swing) a dance is a
-- STATE, and every switch costs a full attack. The rotation therefore switches RARELY:
-- `ataxiaBasher_bardDance` returns "" on almost every round, and a naive "keep the right
-- dance up" rider would have attacked never.
--
-- Which dance, per the user (2026-08-03):
--   Wavedance  bosses -- ignoring 75% resistance is the answer to the one denizen whose
--              resistance actually matters
--   Hawkstep   higher ripples and ANY room with 2+ denizens -- 25% damage resistance is a
--              survival stat and those are the rooms that kill
--   Harrying   lower ripples, the default -- +50% damage when nothing is threatening
-- Boss beats crowd: a boss room may hold adds, but the boss is what the round is about.
--
-- `ataxiaBasher.bardHawkstepRipple` defaults to 25: the user's number for where the tower's
-- difficulty actually steps up (2026-08-03). The first cut guessed 5 off the boss cadence,
-- which was the wrong reasoning -- boss frequency is not difficulty. All three thresholds
-- (this, `bardHawkstepAt` 2, and the boss rule) are now the user's, not inferred.
--
-- Cleared on run start and on the confirmed run end.
mnemSongstep = true
