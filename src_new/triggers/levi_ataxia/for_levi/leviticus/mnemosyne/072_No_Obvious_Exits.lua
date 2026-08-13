--[[mudlet
type: trigger
name: No Obvious Exits
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
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
packageName: ''
patterns:
- pattern: ^There are no obvious exits\.$
  type: 1
]]--

-- ZERO IS AN ANSWER (v4.7.263). Until now nothing in this package parsed this line -- the only
-- match anywhere was the bundled third-party mapper's wormhole trigger, which feeds nothing in
-- ataxia.mnemosyne. So an empty `room.exits` meant BOTH "the room has none" and "we have not
-- been told", the explorer read the honest zero as ignorance, and asked again forever. In the
-- Mnemosyne holding room -- the one room guaranteed to print this, and the room the boon screen
-- appears in -- that was an unbounded `ql` loop, ~15 room descriptions in half a second.
--
-- `type: 1` anchored perl regex, never `type: 3`: exact-whole-line has silently killed triggers
-- in this tree before, and every other mnemosyne trigger (063, 064, 071) uses this shape.
--
-- NOT gated here -- gated in the module. "There are no obvious exits." occurs all over Achaea
-- (closets, vaults, ship holds), and MAP.onNoExits opens with MAP.inMnem() exactly as
-- MAP.onExitsLine does. One gate, in the place that is unit-testable, and the trigger stays a
-- one-line adapter. Deliberately NOT gated on the explorer running either, for the same reason
-- 063 is not: the swarm moves us too, and a room's exits are worth recording whoever walked us
-- in.
--
-- What the handler does with it is deliberately small: it sets a marker that STOPS THE ASKING,
-- and touches nothing else. It never writes room.exits and no consumer of the exit graph reads
-- it -- because "no OBVIOUS exits" is not "no exits", and the holding room proves it by printing
-- this line while still holding the `down` the sweep descends by.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.map
   and ataxia.mnemosyne.map.onNoExits then
	ataxia.mnemosyne.map.onNoExits()
end
