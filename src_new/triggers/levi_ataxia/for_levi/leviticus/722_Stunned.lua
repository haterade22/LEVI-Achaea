--[[mudlet
type: trigger
name: Stunned
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
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
- pattern: You gnash your teeth as a scimitar-wielding Vertani soldier brings the butt of his scimitar down on your head,
    splitting your skull.
  type: 3
- pattern: Lunging at you, a scimitar-wielding Vertani soldier slams his gigantic head into yours. You are stunned from the
    blow.
  type: 3
- pattern: You are too stunned to be able to do anything.
  type: 3
]]--

ataxia.afflictions.stun = true

