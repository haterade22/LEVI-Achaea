--[[mudlet
type: trigger
name: Mnemosyne Icy Heart
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
- pattern: ^Midnight Snow's Icy Heart\s+\d+\s+\w+
  type: 1
]]--

-- BOONS row: "Your Shindo blizzard ability now deals cold damage to all denizens in your
-- location."
--
-- The exact twin of Divine Thunder Cataclysm (trigger 054), and AB BLIZZARD (315) matches it
-- number for number: SHIN BLIZZARD, "Works on/against: Room", 4.00s of EQUILIBRIUM, 30 Shin
-- energy. Only the damage TYPE differs -- cold, against the thunderstorm's electric.
--
-- Because every cost is identical, these two boons are NOT two riders. They are one slot with
-- a choice of damage type, so `ataxiaBasher_bmShinStorm` (basher/002) picks between them
-- rather than casting both: 60 shin and two 4s equilibrium spends in one queued line is the
-- v4.7.193 same-resource collision, and the second command would simply be rejected.
--
-- Owning BOTH is the good case. The tower's suppression affixes name a damage TYPE in their
-- sentence ("All cold damage you deal is reduced by 33%" -- Iceproof), so with two types
-- available the picker steps around whichever is nulled this ripple, exactly as
-- ataxiaBasher_bmInfuse does across the four infuses. With only one boon it simply casts it.
--
-- IT RIDES, IT DOES NOT REPLACE -- equilibrium, not balance, so the swing is untouched. Same
-- 3+ denizen gate as the thunderstorm (`ataxiaBasher.blizzardAt` to tune it separately,
-- otherwise it follows `thunderstormAt`), because the binding resource is the 30 shin that
-- infuse and the Bladed Reflexes SHIN AUGMENT also draw on.
--
-- Not modelled: the AB also promises a "temporary obscuring snowstorm" left in the room. No
-- observation of whether that hinders our own targeting, so nothing reads it -- but it is the
-- first suspect if the basher starts losing track of mobs in rooms it just blizzarded.
--
-- Cleared on run start and on the confirmed run end.
mnemIcyHeart = true
