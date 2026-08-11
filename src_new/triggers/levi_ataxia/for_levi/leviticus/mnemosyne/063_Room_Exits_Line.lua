--[[mudlet
type: trigger
name: Room Exits Line
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
- pattern: ^You see exits leading .+\.$
  type: 1
]]--

-- THE ONLY HONEST EXIT READING UNDER DEMENTIA (v4.7.251).
--
-- User: "we need to track by exits and map it out like that" / "if needed the auto mapper
-- should do a QL to see room exits".
--
-- gmcp's exit table pairs each direction with a DESTINATION room id, and under dementia those
-- ids are inventions that match nothing we hold -- so the table is unusable for linking and
-- its directions arrive wrapped in noise. This line carries directions and nothing else, which
-- is exactly the half that survives, and QL re-requests it on demand (the explorer sends one
-- when it lands on a cell whose exits it does not know yet).
--
-- Handing off to MAP.onExitsLine rather than parsing here: the module owns the parse, so it is
-- unit-testable against captured strings, and this trigger stays a one-line adapter.
--
-- Self-limiting: onExitsLine no-ops unless dead reckoning is active (dementia + in the tower),
-- so outside the tower this costs a table lookup and does nothing. Deliberately NOT gated on
-- the explorer running -- the swarm moves us too, and a cell's exits are worth recording
-- whoever walked us into it.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.map
   and ataxia.mnemosyne.map.onExitsLine then
  ataxia.mnemosyne.map.onExitsLine(line)
end
