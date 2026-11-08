--[[mudlet
type: trigger
name: Save Priorities
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
- pattern: Affs with priority 26 are ignored.
  type: 3
]]--

-- Our own read after a switch ends here and prints nothing.
if ataxia_prioListEnd() then return end

-- A list the user typed. Its output stays exactly what the game sent.
setTriggerStayOpen("Curing Priority List", 0)
ataxia_saveSettings(false)
