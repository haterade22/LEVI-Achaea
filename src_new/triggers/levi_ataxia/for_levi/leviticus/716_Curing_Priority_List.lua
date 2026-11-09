--[[mudlet
type: trigger
name: Curing Priority List
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Priority Management
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
mStayOpen: 99
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: '^Your affliction curing priorities for the priority set (\S+):'
  type: 1
]]--

-- The game names the set in this line (kb/raw/live/curing-priority-list_normal_2026-10-10.txt).
-- The old pattern had no set name, so this chain could not open on that line.
-- A list the user typed prints as the game sent it. Our own read after a switch is hidden.
if ataxia_prioListHeader(matches[2]) then return end
ataxia.curingprio = {}
