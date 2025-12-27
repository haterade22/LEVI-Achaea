--[[mudlet
type: trigger
name: Percussia
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Bard
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
- pattern: You play the harsh beats of a Percussia, overpowering common sounds with the irresistible pounding.
  type: 3
]]--

if ataxiaTemp.percussiaTiming then
  ataxiaTemp.percussiaTiming = tonumber(ataxiaTemp.percussiaTiming)
  ataxiaTemp.percussiaTimer = tempTimer(ataxiaTemp.percussiaTiming-0.25, [[ ataxiaTemp.percussiaTimer = nil ]])
  ataxiaTemp.percussiaTiming = nil
  
  selectString(line,1)
  fg("NavyBlue")
  bg("DarkOrchid")
end