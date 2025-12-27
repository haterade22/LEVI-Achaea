--[[mudlet
type: trigger
name: DWB Head - Affliction 2 - Morningstars
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- DWB
- Dual Blunt
- Expend Afflictions
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
- pattern: ^(\w+) staggers back as the morningstar catches \w+ a glancing blow to the head\.$
  type: 1
]]--

if target == matches[2] then
if tAffs.damagedhead then
  if ataxiaTemp.fractures.skullfractures == 0 or ataxiaTemp.fractures.skullfractures == nil then
  ataxiaTemp.fractures.skullfractures = 2
  twohanded_headHit()
  else
  ataxiaTemp.fractures.skullfractures = ataxiaTemp.fractures.skullfractures + 2
  twohanded_headHit()
  end

elseif not tAffs.damagedhead and ataxiaTemp.fractures.skullfractures == 0 or ataxiaTemp.fractures.skullfractures == nil then
  ataxiaTemp.fractures.skullfractures = 1
  twohanded_headHit()
else
  ataxiaTemp.fractures.skullfractures = ataxiaTemp.fractures.skullfractures + 1
  twohanded_headHit()
end
end