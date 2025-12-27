--[[mudlet
type: trigger
name: Symphony
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Bard
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
- pattern: You play a rousing symphony, your music filling the location with the swelling notes of your inspiration.
  type: 3
]]--

ataxiaTemp.needSymphony = false
if ataxiaTemp.symphTimer then killTimer(ataxiaTemp.symphTimer) end
ataxiaTemp.symphTimer = tempTimer(600, [[ataxiaTemp.symphTimer = nil;
	ataxiaTemp.needSymphony = true
]])

bashConsoleEchom("HAR", "Symphony used.", "goldenrod", "green")