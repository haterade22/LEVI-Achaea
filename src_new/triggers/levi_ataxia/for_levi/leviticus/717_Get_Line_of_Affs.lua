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

-- Our own read after a switch hides the row and fills that set's baseline, in 002_Prio_Management.
if ataxia_prioListRow(matches[2], matches[3]) then return end

-- A list the user typed. Keys are lowercase like every other reader and writer of
-- ataxia.curingprio. The game prints a per-stack row as `burning(5)`; ataxia_prioRowNames turns it
-- into `burning5`, which is the name a write takes. A row that wraps is read only as far as its
-- first line here.
for _, aff in ipairs(ataxia_prioRowNames(matches[3])) do
	ataxia.curingprio[aff] = tonumber(matches[2])
end
