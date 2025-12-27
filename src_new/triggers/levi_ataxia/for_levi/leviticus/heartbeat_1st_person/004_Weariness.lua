--[[mudlet
type: trigger
name: Weariness
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
- pattern: The logograph seems to pulse before your eyes, growing closer, closer...
  type: 3
]]--

ataxia.afflictions.incoming_weariness = true
cecho("\n<purple>     -= INCOMING WEARINESS =-")

tempTimer(5.1, [[ if affed("incoming_weariness") then ataxia.afflictions.incoming_weariness = nil end ]])