--[[mudlet
type: trigger
name: Transmuted
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
- pattern: You call upon your Kai training and transmute your mana into pure health.
  type: 3
]]--

if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("curing", "Transmuted!")
elseif not ataxiaBasher.enabled then
	selectString(line, 1)
	setItalics(true)
	fg("DodgerBlue")
	resetFormat()
end