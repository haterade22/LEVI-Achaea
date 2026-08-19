--[[mudlet
type: trigger
name: Get Line of Affs
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Priority Management
- Curing Priority List
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
- pattern: ^(\d+)\:\s+(.+)
  type: 1
]]--

-- :lower() to match trigger 719, which already normalises. ataxia.curingprio has two
-- writers and every reader (ataxia_getPrio, ataxia_defaultPrioAff, the default table) is
-- lowercase-keyed, so differing casing between the two would split the key silently.
--
-- %w+ keeps a per-stack token whole (`burning5` is one word). If the server ever renders a
-- stack row as `burning (5)` this yields TWO tokens and writes a junk numeric key -- which
-- is why the CURING PRIORITY LIST readback is worth eyeballing after any change to the
-- stack table. Nothing parses a rejected priority, so this is the only place a wrong
-- assumption about the row format would surface.
for aff in matches[3]:gmatch("%w+") do
	ataxia.curingprio[aff:lower()] = tonumber(matches[2]) 
end