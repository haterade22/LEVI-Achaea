--[[mudlet
type: trigger
name: DWC Stuff
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Self Limb Tracking
- Attacks
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
- pattern: ^(\w+) swings .+ at your (.+) with all \w+ might\.$
  type: 1
- pattern: ^(\w+) slashes into your (.+) with.+\.$
  type: 1
- pattern: ^Lightning\-quick\, (\w+) jabs your (.+) with .+\.$
  type: 1
]]--

local class = ataxiaNDB_getClass(matches[2]) or "Unknown"
local knights = {"Paladin", "Infernal", "Runewarden", "Unnamable"}
if table.contains(knights, class) then
  dwc_selfLimbHit(matches[3])
end