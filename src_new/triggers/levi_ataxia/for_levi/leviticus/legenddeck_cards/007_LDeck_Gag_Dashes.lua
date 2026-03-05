--[[mudlet
type: trigger
name: LDM Gag Dashes
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- LegendDeck Cards
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
- pattern: '-------------------------------------------------------------------------------'
  type: 3
]]--

-- Gag separator dashes during ldeck list parsing
if ldm and ldm.state and ldm.state.parsing then
    deleteLine()
end
