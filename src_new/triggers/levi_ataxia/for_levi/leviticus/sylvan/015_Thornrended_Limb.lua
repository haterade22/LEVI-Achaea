--[[mudlet
type: trigger
name: Thornrended Limb
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
- pattern: ^You command the razor-edged thorny vines around you to lash out and rend the (.+) of (\w+).$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^As you carve into (\w+), you perceive that you have dealt (.+)\% damage to \w+ (torso|head|left arm|right arm|right
    leg|left leg).$
  type: 1
]]--

local person = multimatches[1][3]
local propAff = sylvan_propagateAff()

if isTargeted(person) then
  targetIshere = true
  erAff("shield")
  moveCursor(0, getLineNumber()-1)
	-- propAff is false when nothing is propagated (limb_management/011): tarAffed(false) would
	-- record an affliction named false, so only a real one is passed on.
	if next(envenomList) then	
		if propAff then tarAffed(envenomList[1], propAff) else tarAffed(envenomList[1]) end
		table.remove(envenomList, 1)
  elseif propAff then
    tarAffed(propAff)
	end
	moveCursorEnd()
  lastLimbAttack = "thornrend"  
end

