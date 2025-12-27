--[[mudlet
type: trigger
name: Person
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- People here
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'yes'
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
mFgColor: '#aaff00'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ([A-Z][a-z]+)
  type: 1
]]--

for i = 1, #matches, 2 do
  mmp.pdb[matches[i]] = mmp.currentroomname
  mmp.pdb_lastupdate[matches[i]] = true
  raiseEvent("mmapper updated pdb")
end