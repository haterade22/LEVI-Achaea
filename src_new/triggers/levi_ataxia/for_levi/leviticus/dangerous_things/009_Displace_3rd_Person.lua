--[[mudlet
type: trigger
name: Displace 3rd Person
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
- pattern: ^(\w+) twitches slightly, and the air immediately surrounding \w+ comes alight with a pale, etheric fire as a strange
    hissing noise fills the air\.$
  type: 1
]]--

if ataxia.settings.raid and ataxia.settings.raid.enabled then
  if not ataxia.retardation then
    sendAll("pt "..matches[2].." you're being displaced! MOVE NOW!","pt "..matches[2].." you're being displaced! MOVE NOW!", "pt "..matches[2].." you're being displaced! MOVE NOW!",false)
  end
end