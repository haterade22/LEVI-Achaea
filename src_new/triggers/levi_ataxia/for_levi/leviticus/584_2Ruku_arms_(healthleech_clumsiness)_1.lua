--[[mudlet
type: trigger
name: 2Ruku arms (healthleech/clumsiness)
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
- pattern: ^You whip .+ at (\w+) in a controlled arc, bringing its length to crack against \w+ \w+ arm.$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^^^As your blow lands with a crunch, you perceive that you have dealt ([0-9\.]+)\% damage to (\w+)'s (left arm|right
    arm)\.$
  type: 1
]]--

local person = multimatches[1][2]
local maybemiss = multimatches[3][1]

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  ignoreThirdPerson = true
      if partyrelay and not haveAff("clumsiness") then
  send("pt "..target..": clumsiness")
   elseif
partyrelay and haveAff("clumsiness") then send("pt "..target..": healthleech clumsiness")
   end 
      
        if haveAff("clumsiness") then
        tarAffed("healthleech")
      else
        tarAffed("clumsiness")
      end
     
    lastLimbAttack = "shikRuku"

     
end
 



local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikRuku = damage
