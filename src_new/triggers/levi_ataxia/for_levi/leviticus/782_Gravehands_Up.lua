--[[mudlet
type: trigger
name: Gravehands Up
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: ^You mutter words of death and decay, and suddenly the ground breaks open
  type: 1
]]--

-- THE HANDS ARE UP (v4.7.347, user, live: "You mutter words of death and decay, and suddenly the
-- ground breaks open all around as hands of rotting flesh and white bone push out of the ground.")
--
-- The once-per-room latch is stamped optimistically when we SEND, so without this line a refused
-- summon burns the room for the rest of the visit. This is what turns the stamp into a fact.
--
-- MATCHED EARLY, BECAUSE THE SERVER WRAPS (v4.7.351, deep review). This user's Achaea wraps
-- at 119-124 columns (measured from the break points in their pastes), and the full line is
-- longer than that. A pattern that runs past the break -- or a fragment that straddles it --
-- can never match, and this one did exactly that from the day it shipped.
--
-- The line is 148 characters and the old fragment ("hands of rotting flesh and white bone push
-- out of the ground") began at column 88 -- so the break fell THROUGH it and the confirmation
-- never arrived. Every room's summon then read as lost and was re-cast six seconds later: an
-- extra 350 mana and 1.5% life essence per room, every room once Graveborn made that the rule.
--
-- The opening words fix a second fault for free: they are FIRST-PERSON. The old fragment would
-- have matched another necromancer's gravehands in the room just as well, and a false
-- confirmation spends our one retry.
if ataxiaBasher_gravehandsUp then ataxiaBasher_gravehandsUp() end
