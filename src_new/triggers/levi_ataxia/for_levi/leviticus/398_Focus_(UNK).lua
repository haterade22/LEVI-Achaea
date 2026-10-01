--[[mudlet
type: trigger
name: Focus (UNK)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
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
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^A look of extreme focus crosses the face of (\w+)\.$
  type: 1
]]--

if isTargeted(matches[2]) and tBals.focus then
	-- V3 owns the focus cure when it is loaded: onTargetFocusV3 clears
	-- impatience from every branch (a focus proves it absent) and removes ONE
	-- focus-curable aff -- and it refuses an illusion focus (off focus balance,
	-- or impatience confirmed). The unconditional erAff + tFocused below used
	-- to run as well, overriding those guards and removing a SECOND aff from
	-- every branch (v4.7.372, deep review). They remain the non-V3 path.
	if onTargetFocusV3 then
		onTargetFocusV3()
	else
		erAff("impatience")
		tFocused()
	end
end
	tBals.focus = false
	tBals.focusUsedAt = getEpoch()

  if tBals.timers.focus then killTimer(tBals.timers.focus) end
	if haveAff("shadowmadness") then
		tBals.timers.focus = tempTimer(5, [[tBals.focus = true; tBals.timers.focus = nil]])
	else
		tBals.timers.focus = tempTimer(2, [[tBals.focus = true; tBals.timers.focus = nil]])
	end  
	targetIshere = true
