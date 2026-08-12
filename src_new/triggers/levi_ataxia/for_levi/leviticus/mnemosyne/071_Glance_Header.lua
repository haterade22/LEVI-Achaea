--[[mudlet
type: trigger
name: Glance Header
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
- pattern: ^Glancing (?:to the )?(\w+), you see:$
  type: 1
]]--

-- A GLANCE PRINTS SOMEONE ELSE'S ROOM (v4.7.262, captured live).
--
-- `Glancing to the northwest, you see:` is followed by the NEIGHBOUR's description and the
-- NEIGHBOUR's exits line -- and trigger 063 hands every "You see exits leading ..." line to
-- MAP.onExitsLine with no notion of whose room it describes. So a glance grafted the neighbour's
-- exits onto the room we are standing in. Observed: room 67777, whose own description lists two
-- exits (northeast, northwest), holding FOUR -- with the extras being exactly `north` and
-- `southeast`, the glanced room's pair.
--
-- Not cosmetic. Text-derived exits store as destination 0, which `unexploredExits` reads as an
-- unwalked door, so `_nextExploreStep` returned nil before the glance and `se` after it: the
-- sweep would walk a door that does not exist, burn MOVE_TIMEOUT plus a retry, and then condemn
-- a direction that was never real.
--
-- This is a REGRESSION from v4.7.260, which ungated `onExitsLine` from dementia so the prose
-- could feed the map at all. That change was right and this is its missing half -- widening what
-- a parser accepts obliges you to say what it must still refuse.
--
-- Decides nothing on its own: it only arms a one-shot token that the next exits line spends.
-- Deliberately NOT used to populate the glanced room -- tempting, and a separate change with its
-- own failure modes (a glanced room has no id at all under dementia).
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.map
   and ataxia.mnemosyne.map.onGlance then
	ataxia.mnemosyne.map.onGlance(matches[2])
end
