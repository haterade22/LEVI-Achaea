--[[mudlet
type: trigger
name: Litany
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
- pattern: ^The ominously haunting sound of (\w+) suddenly fills your head, threatening to drown out all other sound.$
  type: 1
]]--

ataxia_boxEcho("LITANY INCOMING - SHIELD SHIELD SHIELD!", "NavajoWhite:DarkSlateGrey")
send("queue addclear free touch shield",false)

if ataxia.settings.raid and ataxia.settings.raid.enabled then
  if not ataxia.retardation then
    sendAll("pt LITANY INCOMING! TOUCH SHIELD!", "pt CANCEL TUMBLES IF FORCED","pt LITANY INCOMING! TOUCH SHIELD!", "pt CANCEL TUMBLES IF FORCED",false)
  end
end