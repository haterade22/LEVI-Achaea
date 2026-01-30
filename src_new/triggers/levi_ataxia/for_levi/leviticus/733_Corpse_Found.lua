--[[mudlet
type: trigger
name: Corpse Found
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
- Reagent Butchering
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
- pattern: ^\s+(.+)the corpse of (.+)
  type: 1
]]--

local corpseTypes = {
	"a shaggy buffalo", "a rugged buffalo",
	"a hideous, writhing squid", 
	"a black sea bass", "a school of clownfish", "a school of fish",
	"a giant red scorpion", "a yellow scorpion",
	"a man-eating shark", "a spearhead shark", "a large bull shark", "a fearsome tiger shark",
	"a fire wyrm", "an ancient wyrm", "a pregnant wyrm", "the Wyrm Lord",
}
local corpseid = string.trim(matches[2])
local corpse = matches[3]

if table.contains(corpseTypes, corpse) then
	table.insert(ataxiaTemp.toButcher, corpseid)
end