--[[mudlet
type: trigger
name: Asthma
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Pariah
- Heartbeat 1st Person
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
- pattern: As the logograph becomes fully formed it leaps for you, vanishing into your skin just below your throat.
  type: 3
]]--

ataxia.afflictions.incoming_asthma = true
cecho("\n<purple>     -= INCOMING ASTHMA =-")

tempTimer(5.1, [[ if affed("incoming_asthma") then ataxia.afflictions.incoming_asthma = nil end ]])