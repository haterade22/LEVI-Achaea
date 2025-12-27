--[[mudlet
type: trigger
name: Mayology
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Dangerous Things
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
- pattern: ^(\w+)'s face contorts as if in great pain, and the muscles beneath \w+ skin flex and spasm uncontrollably.$
  type: 1
]]--

ataxia_boxEcho(matches[2].." USED MAYOLOGY! GET OUTTA THERE!", "black:red")

if ataxia.settings.raid and ataxia.settings.raid.enabled then
  if not ataxia.retardation then
    sendAll("pt "..matches[2]:upper().." USED MAYOLOGY - FOCUS THEM DOWN!")
  end
end