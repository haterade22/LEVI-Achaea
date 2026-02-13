--[[mudlet
type: trigger
name: Balance Time
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: BALANCE
  type: 0
]]--

local balTime = tonumber(line:match("BALANCE:%s*(%d+%.?%d*)"))

if balTime and bashStats then
  bashStats.lastBalanceTime = balTime
  bashStats.lastBalanceDamage = bashStats.currentBalanceDamage or 0
  bashStats.currentBalanceDamage = 0
  if tarc and tarc.write then tarc.write() end
end