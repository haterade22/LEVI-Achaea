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
- pattern: hands of rotting flesh and white bone push out of the ground
  type: 0
]]--

-- THE HANDS ARE UP (v4.7.347, user, live: "You mutter words of death and decay, and suddenly the
-- ground breaks open all around as hands of rotting flesh and white bone push out of the ground.")
--
-- The once-per-room latch is stamped optimistically when we SEND, so without this line a refused
-- summon burns the room for the rest of the visit. This is what turns the stamp into a fact.
--
-- A SUBSTRING, because the line is long enough that Achaea wraps it server-side -- the same
-- reason the soulstorm landing beside this one is matched on a fragment (v4.7.286). The fragment
-- is the distinctive half and carries no name or pronoun to vary.
if ataxiaBasher_gravehandsUp then ataxiaBasher_gravehandsUp() end
