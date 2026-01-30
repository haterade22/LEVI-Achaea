--[[mudlet
type: trigger
name: Gold Pack - Bash Gag
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: You close a dragonskin pack.
  type: 3
- pattern: A dragonskin pack is already open.
  type: 3
- pattern: You open a dragonskin pack.
  type: 3
- pattern: You must wait a short time before you can use a battlerage ability again.
  type: 3
]]--

if not ataxiaBasher.manual and ataxiaBasher.enabled then
		deleteFull()
	end