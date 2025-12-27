--[[mudlet
type: trigger
name: FIRE ABLAZE
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Unknown Checks
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
- pattern: A greater fire elemental flares brightly as it emits a pulse of flame, scorching everything within reach.
  type: 3
- pattern: A greater fire elemental claws at you with its spindly arms, burning wounds deep into your torso.
  type: 3
- pattern: A greater fire elemental makes a winding gesture in your direction, igniting a fiery pain in your stomach.
  type: 3
]]--

if ataxia.afflictions.blackout then		expandAlias("diag") end
send("curing priority defense blind reset")