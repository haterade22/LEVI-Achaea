--[[mudlet
type: trigger
name: Ruinate Wheel
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
- pattern: Vibrant indigo rays of light lash out from the Wheel of Chaos.
  type: 3
]]--

cecho("\n<green> -= AEON WILL BE COMING IN 7 SECONDS =-")
tempTimer(3, [[ cecho("\n <yellow>-= AEON WILL BE COMING IN 4 SECONDS =-") ]])
tempTimer(5.2, [[ cecho("\n <orange>-= AEON WILL BE COMING IN 2 SECONDS =-") ]])
tempTimer(6.5, [[ ataxia_boxEcho("AEON IS IMMINENT", "purple");myaeon = true ]])
