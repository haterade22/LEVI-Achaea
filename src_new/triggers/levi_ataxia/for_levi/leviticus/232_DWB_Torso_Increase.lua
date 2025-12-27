--[[mudlet
type: trigger
name: DWB Torso Increase
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- DWB
- Dual Blunt
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
- pattern: ^(\w+) doubles over as the morningstar savagely crunches into \w+ ribcage\.$
  type: 1
]]--

if target == matches[2] then
  if ataxiaTemp.fractures.crackedribs == 0 or ataxiaTemp.fractures.crackedribs == nil then
  ataxiaTemp.fractures.crackedribs = 1
  else
  ataxiaTemp.fractures.crackedribs = ataxiaTemp.fractures.crackedribs + 1
  end
end
  
  
  
  
  