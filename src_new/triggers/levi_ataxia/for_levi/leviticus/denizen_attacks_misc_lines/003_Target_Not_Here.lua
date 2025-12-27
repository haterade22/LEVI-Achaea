--[[mudlet
type: trigger
name: Target Not Here
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
- Denizen Attacks / Misc Lines
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
- pattern: You detect nothing here by that name.
  type: 3
- pattern: You cannot see that being here.
  type: 3
- pattern: I do not recognise anything called that here.
  type: 3
- pattern: Nothing can be seen here by that name.
  type: 3
- pattern: Ahh, I am truly sorry, but I do not see anyone by that name here.
  type: 3
]]--

if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("denizen", "Target is gone!")
	if not ataxiaBasher.manual then
		deleteFull()
	end
end
