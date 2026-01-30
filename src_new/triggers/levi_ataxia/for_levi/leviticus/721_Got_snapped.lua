--[[mudlet
type: trigger
name: Got snapped
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
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^(\w+) snaps \w+ fingers in front of you.$
  type: 1
]]--

if ataxiaNDB_getClass(matches[2]) == "Serpent" then
  if ataxia.prioritySwaps.impSnap and ataxia.prioritySwaps.impSnap.active then
    if ataxia_getPrio("impatience") ~= 1 then
      ataxia_setAffPrio("impatience", 1)
      tempTimer(10, [[ ataxia_restorePrio("impatience") ]])
    end
  end
end