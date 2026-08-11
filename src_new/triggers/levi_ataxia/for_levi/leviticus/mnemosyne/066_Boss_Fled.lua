--[[mudlet
type: trigger
name: Boss Fled
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
- pattern: \bout to the (north|northeast|east|southeast|south|southwest|west|northwest|up|down)\b
  type: 1
]]--

-- The departure half. Live capture:
--
--   His fingers plucking a plaintive melody on his lyre, a satyri bard strolls out to the
--   southeast, the sorrowful music gradually fading in his wake.
--
-- MATCHED ON THE DIRECTION FRAGMENT, NOT THE WHOLE SENTENCE, and deliberately so. Every
-- denizen words its exit differently -- "strolls out to", "prowls out to", "stomps out to"
-- (see the PvP set in trigger 637) -- and enumerating them is how you end up with a trigger
-- that works for one boss and silently misses the next. "out to the <direction>" is the part
-- they share, and the DIRECTIONS ARE ENUMERATED so the pattern cannot match arbitrary prose.
--
-- That breadth is safe because it decides nothing on its own: M.onDenizenFled follows only when
-- a matching boss panicked within the last few seconds (trigger 065), the basher is on, we are
-- in the tower, and we are not escaping, recovering, standing in lava or below the escape
-- threshold. An ordinary denizen wandering off costs one table lookup here.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onDenizenFled then
	ataxia.mnemosyne.onDenizenFled(matches[2])
end
