--[[mudlet
type: trigger
name: Breathrain
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
- pattern: A massive shadow begins to circle in the skies above.
  type: 3
]]--

ataxia_boxEcho("BREATHRAIN INCOMING - SHIELD SHIELD SHIELD!", "NavajoWhite:DarkSlateGrey")
send("queue addclear free touch shield",false)

if ataxia.settings.raid and ataxia.settings.raid.enabled then
  if not ataxia.retardation then
    sendAll("pt BREATHRAIN INCOMING! TOUCH SHIELD!", "pt BREATHRAIN INCOMING! TOUCH SHIELD!", false)
  end
end