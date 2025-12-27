--[[mudlet
type: trigger
name: BEHEAD STOP
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- WEAPONS
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
- pattern: It would be folly to start a beheading on one so free to move about.
  type: 3
- pattern: You must be wielding a longsword, broadsword, scimitar, bastard sword, or battleaxe to behead someone.
  type: 3
]]--

send("curing on")

ataxiaEcho("System has been "..(ataxia.settings.paused and "<red>paused." or "<green>unpaused."))