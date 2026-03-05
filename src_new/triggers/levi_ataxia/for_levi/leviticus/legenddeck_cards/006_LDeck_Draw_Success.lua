--[[mudlet
type: trigger
name: LDM Draw Success
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- LegendDeck Cards
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
- pattern: ^You draw forth the power of (\w+)
  type: 1
]]--

if ldm and ldm.onDraw then
    local cardKey = matches[2]
    ldm.onDraw(cardKey)
end
