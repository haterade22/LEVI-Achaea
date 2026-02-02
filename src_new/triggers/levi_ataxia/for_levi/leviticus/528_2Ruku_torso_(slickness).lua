--[[mudlet
type: trigger
name: 2Ruku torso (slickness)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Monk
- Shikudo
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
- pattern: ^You spin a full rotation, bringing .+ around in a blur of motion to smash into the \w+ of (\w+).$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^As your blow lands with a crunch, you perceive that you have dealt ([0-9\.]+)\% damage to (\w+)'s torso\.$
  type: 1
]]--

local person = multimatches[1][2]
local maybemiss = multimatches[3][1]


if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  ignoreThirdPerson = true




      tarAffed("slickness")
      if applyAffV3 then applyAffV3("slickness") end
      
      if
partyrelay then
  send("pt "..target..": slickness")
   end 
     
    end
    lastLimbAttack = "shikRuku"


local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikRuku = damage
