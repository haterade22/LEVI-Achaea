--[[mudlet
type: trigger
name: copy qwc trigger
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- AzzysEnemyManagement
- Enemy Management
attributes:
  isActive: 'no'
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
- pattern: ^(\w+),
  type: 1
- pattern: return not isPrompt()
  type: 4
]]--

local data = string.split(line, ", ")

-- fix last name that ends with a dot
data[#data] = string.sub(data[#data], 1, #data[#data] - 1)

-- fix the 'and Name' from qw2
if data[#data]:starts("and ") then
  data[#data] = data[#data]:match("and (%w+)")
end

for _, name in ipairs(data) do
  EnemyCity(name, enemycity)
end