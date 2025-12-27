--[[mudlet
type: trigger
name: Impatience
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
- pattern: ^As \w+ completes the logograph (\w+) brings \w+ knife slashing down, severing it in twain. You feel a tightening
    around your heart, a certainty that something terrible shall befall you.$
  type: 1
]]--

ataxia.afflictions.incoming_impatience = true
cecho("\n<yellow>     -= INCOMING IMPATIENCE =-")

tempTimer(5.1, [[ if affed("incoming_impatience") then ataxia.afflictions.incoming_impatience = nil end ]])