--[[mudlet
type: trigger
name: Vibe Found
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Magi
- Vibes
- VIBES in room
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
- pattern: ^(\w+)\s+(\w+) \s+(\d+)
  type: 1
- pattern: ^(\w+)\s+(\w+) \s+Muffled
  type: 1
]]--

magiVibes_isHere(matches[2])

local vibe = matches[2]:lower()

if ataxiaTemp.embeddingVibes then
	if table.contains(ataxiaTemp.vibes, vibe) then
		table.remove(ataxiaTemp.vibes, table.index_of(ataxiaTemp.vibes, vibe))
  end
end
