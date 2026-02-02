--[[mudlet
type: trigger
name: Dehydrate
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Magi
- Destroy-related
attributes:
  isActive: 'no'
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
- pattern: ^(\w+) winces in evident discomfort as .+ points a single appendage at \w+.$
  type: 1
]]--

if isTargeted(matches[2]) then
		tarAffed("dehydrate")
		if applyAffV3 then applyAffV3("dehydrate") end
		if dehydrateTimer then killTimer(dehydrateTimer) end
		dehydrateTimer = tempTimer(46, [[tAffs.burns = 0; tAffs.dehydrate = false; if removeAffV3 then removeAffV3("dehydrate") end]])
end