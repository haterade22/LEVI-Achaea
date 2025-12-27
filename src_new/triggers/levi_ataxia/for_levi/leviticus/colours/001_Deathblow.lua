--[[mudlet
type: trigger
name: Deathblow
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Psion
- Colours
attributes:
  isActive: 'no'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 2
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You weave a translucent dagger into being, its ethereal form firming to corporeality in your hands. translucent
    dagger in a spray of crimson.
  type: 1
- pattern: ' Striking like coiled lightning, your hand flashes out and lays open the throat of \w+ with a translucent dagger
    in a spray of crimson.'
  type: 0
]]--

deleteLine()
cecho("\n<red>[<white>Levi<red>]: Deathblow")