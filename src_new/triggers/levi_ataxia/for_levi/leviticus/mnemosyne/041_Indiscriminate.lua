--[[mudlet
type: trigger
name: Mnemosyne Indiscriminate
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
- pattern: ^Indiscriminate\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Indiscriminate is active: "Your Arc is now effective
-- against denizens." ARC normally reads "Works on: Adventurers and room", so it is dead
-- weight in PvE; with this boon the untargeted room form (4.75s of balance) becomes a
-- genuine AoE.
--
-- EVERY KNIGHT swings it instead of the single-target attack at 3+ denizens -- Infernal,
-- Paladin, Runewarden and Unnamable, since Arc is WEAPONMASTERY and shared by all four
-- (v4.7.244; it was Infernal-only before, purely because that was the class in the tower
-- when the boon was captured). `ataxiaBasher_knightArc`, basher/002 -- tune with
-- `ataxiaBasher.arcAt`. For Runewarden a Thunderclap BISECT outranks it: same room-wide
-- reach for the price of a normal swing instead of 4.75s of balance.
--
-- The flag keeps its legacy `infIndiscriminate` name deliberately -- it is reset in three
-- places and a missed rename would leave arc armed outside the tower.
-- Cleared on Mnemosyne run start/end. Type BOONS to re-sync if needed.
infIndiscriminate = true
