--[[mudlet
type: trigger
name: Empathy Done
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
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
- pattern: With a thought you project your power into the heart of your angel guardian.
  type: 3
- pattern: The guardian angel seems to shine with fresh power.
  type: 3
]]--

if ataxiaBasher.enabled and not ataxiaBasher.manual then
	deleteFull()
	if not powerEcho then
		bashConsoleEcho("curing", "Powered angel.")
		powerEcho = tempTimer(0.5, [[powerEcho = nil]])
	end
end
empathyTick = 0