--[[mudlet
type: trigger
name: Swing
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Knight
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
- pattern: ^You swing (.+) at the (.+) of (\w+) with all your might.$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^As you carve into (\w+), you perceive that you have dealt (.+)\% damage to \w+ (torso|head|left arm|right arm|right
    leg|left leg).$
  type: 1
]]--

local person = multimatches[1][4]
local maybemiss = multimatches[3][1]

if ataxiaTemp.class == "Bard" then return end

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end

	ataxiaTemp.ignoreShield = false
  lastLimbAttack = "dwcSlash"
  moveCursor(0, getLineNumber()-1)
  if ataxiaTemp.hitCount == 0 then
    if next(envenomList) then	
		  tarAffed(envenomList[1])
		  if applyAffV3 then applyAffV3(envenomList[1]) end
		  table.remove(envenomList, 1)
    end
  else  
    if envenomListTwo and next(envenomListTwo) then
      tarAffed(envenomListTwo[1])
      if applyAffV3 then applyAffV3(envenomListTwo[1]) end
      table.remove(envenomListTwo,1)
    else
      if next(envenomList) then	
  		  tarAffed(envenomList[1])
  		  if applyAffV3 then applyAffV3(envenomList[1]) end
  		  table.remove(envenomList, 1)
      end    
    end
	end
  moveCursorEnd()
end


ataxiaTemp.hitCount = ataxiaTemp.hitCount + 1