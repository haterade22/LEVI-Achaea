--[[mudlet
type: trigger
name: 2Kuro (weariness/lethargy)
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
- pattern: ^Falling back into a low crouch, you lash out with a swift strike at the \w+ thigh of (\w+).$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^As your blow lands with a crunch, you perceive that you have dealt ([0-9\.]+)\% damage to (\w+)'s (left leg|right
    leg)\.$
  type: 1
]]--

local person = multimatches[1][2]
local maybemiss = multimatches[3][1]



if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  ignoreThirdPerson = true
  
  
  if partyrelay and not haveAff("weariness") then
  send("pt "..target..": weariness")
  elseif
partyrelay and  haveAff("weariness") then send("pt "..target..": lethargy weariness")

   end 

    moveCursor(0, getLineNumber()-1)
    
      if haveAff("weariness") then
        tarAffed("lethargy")
        if applyAffV3 then applyAffV3("lethargy") end
      else
        tarAffed("weariness")
        if applyAffV3 then applyAffV3("weariness") end
      end
       
    moveCursorEnd()
    lastLimbAttack = "shikKuro"

 

   
end


local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikKuro = damage
