--[[mudlet
type: trigger
name: Epilepsy
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
- pattern: As the logograph fully forms it begins to burn brighter and brighter, before flashing from air to your brow and
    blossoming into searing heat.
  type: 3
]]--

ataxia.afflictions.incoming_epilepsy = true
cecho("\n<yellow>     -= INCOMING EPILEPSY =-")

tempTimer(5.1, [[ if affed("incoming_epilepsy") then ataxia.afflictions.incoming_epilepsy = nil end ]])