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

if ataxiaBasher and ataxiaBasher.enabled then
	if type(target) == "number" then
		bashConsoleEcho("denizen", "Target is gone!")
		if not ataxiaBasher.manual then
			deleteFull()
		end
	end
	-- The room contents are stale: we swung at a denizen that's already dead/gone
	-- but GMCP still lists it in ataxia.denizensHere. A QL forces Achaea to re-push
	-- the room so denizensHere resyncs -- otherwise (especially in MANUAL / Mnemosyne
	-- mode, where deleteFull() is skipped) we keep swinging at a phantom. Debounced
	-- so a burst of these on one target = a single QL.
	if not ataxiaBasher._targetGoneQL then
		ataxiaBasher._targetGoneQL = true
		send("ql")
		tempTimer(1.5, function() ataxiaBasher._targetGoneQL = false end)
	end
end
