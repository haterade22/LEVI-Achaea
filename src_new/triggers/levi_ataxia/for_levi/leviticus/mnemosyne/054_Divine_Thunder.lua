--[[mudlet
type: trigger
name: Mnemosyne Divine Thunder Cataclysm
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
- pattern: ^Divine Thunder Cataclysm\s+\d+\s+\w+
  type: 1
]]--

-- BOONS row: "Your Shindo thunderstorm ability now deals electric damage to all denizens in
-- your location."
--
-- SHIN THUNDERSTORM is already a room ability (AB 314, "Works on/against: Room"); the boon
-- is what makes it hurt DENIZENS, which turns it into free crowd damage while bashing. The
-- Blademaster basher casts it at 3+ denizens (ataxiaBasher_bmThunderstorm, basher/002 --
-- ataxiaBasher.thunderstormAt to tune).
--
-- IT RIDES, IT DOES NOT REPLACE: AB says 4.00s of EQUILIBRIUM, so the balance swing is
-- untouched and the storm costs us no attack. Contrast the Thunderclap bisect, which spends
-- 4s of BALANCE and therefore displaces the swing -- the same "crowd AoE" idea, wired
-- oppositely because the resource differs. That distinction is the thing to check first for
-- any new AoE.
--
-- Gated at 3+ rather than the 2+ used for the balance-spending crowd swings, because the
-- binding resource here is not balance but SHIN: 30 per cast, from a pool that infuse and
-- the Bladed Reflexes SHIN AUGMENT are also drawing on (ataxiaBasher.thunderstormReserve
-- keeps a buffer back for them if wanted).
--
-- Cleared on run start and on the confirmed run end.
mnemDivineThunder = true
