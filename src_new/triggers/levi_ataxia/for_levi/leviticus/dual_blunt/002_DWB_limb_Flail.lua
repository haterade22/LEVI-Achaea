--[[mudlet
type: trigger
name: DWB limb Flail
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
- Dual Blunt
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
- pattern: ^You skilfully whirl a Braincrusher flail toward the (.+) of (\w+).$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^As your blow lands with a crunch, you perceive that you have dealt ([\d.]+)%  damage to (\w+)'s (left leg|right
    leg|left arm|right arm|head|torso)\.$
  type: 1
]]--

ataxiaTemp.lastLimbHit = multimatches[1][2]
cecho("THIS WORKS")
local person = multimatches[1][4]
local maybemiss = multimatches[3][1]

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  ignoreThirdPerson = true

    moveCursor(0, getLineNumber()-1)
   
    moveCursorEnd()
    --lastLimbAttack = "dwbFWhirl"
    lastLimbAttack = "dwbWhirl"
 
      
end

local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.dwbWhirl = damage
 
fldamage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.dwbFWhirl = fldamage
   
