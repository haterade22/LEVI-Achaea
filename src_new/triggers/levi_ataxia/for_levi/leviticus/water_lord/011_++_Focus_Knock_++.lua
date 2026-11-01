--[[mudlet
type: trigger
name: ++ Focus Knock ++
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes Other
- Water Lord
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
- pattern: ^You wave a hand in the direction of (\w+) roiling the liquid that flows throughout \w+ and disrupting \w+ mental
    stability.$
  type: 1
]]--

local name = matches[2]

if isTargeted(matches[2]) and tBals.focus then
	tarAffed("nausea")
	tBals.focus = false
	-- A named timer, as in 398: ataxia_resetTargetBals can kill it, so an old target's knock cannot
	-- mark the new target's focus up early.
	if tBals.timers.focus then killTimer(tBals.timers.focus) end
	tBals.timers.focus = tempTimer(2, [[tBals.focus = true; tBals.timers.focus = nil]])
	targetIshere = true
end