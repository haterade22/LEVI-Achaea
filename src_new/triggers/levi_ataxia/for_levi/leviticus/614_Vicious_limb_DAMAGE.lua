--[[mudlet
type: trigger
name: Vicious limb DAMAGE
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Limb Got Hit
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
- pattern: ^You viciously jab a (.+) into (\w+)'s (.+)\.$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^As you carve into (\w+), you perceive that you have dealt ([0-9\.]+)\% damage to (\w+) (left leg|right leg|left
    arm|right arm|head|torso)\.$
  type: 1
]]--


local person = multimatches[1][3]
local maybemiss = multimatches[3][1]
ataxiaTemp.lastLimbHit = multimatches[1][4]

if isTargeted(person) then

  targetIshere = true
  tAffs.shield = false

	ataxiaTemp.ignoreShield = false
	if next(envenomList) then
			moveCursor(0, getLineNumber()-1)
			tarAffed(envenomList[1])
     local affstruck = envenomList[1]
       if partyrelay then send("pt "..target..": "..affstruck)
      end
      cecho("this is "..affstruck)
			table.remove(envenomList, 1)
			moveCursorEnd()
       lastLimbAttack = "bardRapier"

	end
end

local damage = tonumber(multimatches[3][3])
   ataxiaTables.limbData.bardRapier = damage
