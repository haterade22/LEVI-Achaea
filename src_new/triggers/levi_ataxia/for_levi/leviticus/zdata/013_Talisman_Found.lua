--[[mudlet
type: trigger
name: Talisman Found
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- zData
- zData
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 2
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You have slain (.*), retrieving the corpse.$
  type: 1
- pattern: ^You have found (.+) \(level (\d+)\) talisman piece!$
  type: 1
]]--

zData.char.taliCount = zData.char.taliCount + 1
local tempName = multimatches[2][2].." : "..multimatches[1][2] 
table.insert(zData.char.taliList, 1, tempName)