--[[mudlet
type: trigger
name: Got Unknown Aff
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
- pattern: You are confused as to the effects of the venom.
  type: 3
- pattern: The Contradanse melody swells sharply in your ear with a discombobulating sonic burst.
  type: 3
]]--

gotUnknownAff()

if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("denizen", "Unknown affliction!")
	if not ataxiaBasher.manual then
		deleteFull()
	end
elseif not ataxiaBasher.enabled then
	selectString(line, 1)
	setBold(true)
	fg("DarkGreen")
	resetFormat()
end