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

local propAff = sylvan_propagateAff()

local person = multimatches[1][3]
local propAff = sylvan_propagateAff()

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  moveCursor(0, getLineNumber()-1)
	if next(envenomList) then	
		tarAffed(envenomList[1], propAff)
		if applyAffV3 then applyAffV3(envenomList[1], propAff) end
		table.remove(envenomList, 1)
  else
    tarAffed(propAff)
    if applyAffV3 then applyAffV3(propAff) end
	end
	moveCursorEnd()
end

