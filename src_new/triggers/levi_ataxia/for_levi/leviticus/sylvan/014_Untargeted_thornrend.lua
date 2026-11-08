--[[mudlet
type: trigger
name: Untargeted thornrend
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Sylvan
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
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
- pattern: ^You command the razor-edged thorny vines around you to lash out and rend the flesh of (\w+).$
  type: 1
- pattern: '1'
  type: 5
- pattern: (.*)
  type: 1
]]--

-- The pattern has ONE capture, so the name is [1][2]. This read [1][3] (nil), and isTargeted(nil)
-- throws. sylvan_propagateAff was deleted in 3c312975 and is restored in
-- limb_management/011_Sylvan_Propagation; it returns false when nothing is propagated, and
-- tarAffed(false) would record an affliction named false, so only a real one is passed on.
local person = multimatches[1][2]
local propAff = sylvan_propagateAff()

if isTargeted(person) then
  targetIshere = true
  erAff("shield")
  moveCursor(0, getLineNumber()-1)
	if next(envenomList) then	
		if propAff then tarAffed(envenomList[1], propAff) else tarAffed(envenomList[1]) end
		table.remove(envenomList, 1)
  elseif propAff then
    tarAffed(propAff)
	end
	moveCursorEnd()
end

