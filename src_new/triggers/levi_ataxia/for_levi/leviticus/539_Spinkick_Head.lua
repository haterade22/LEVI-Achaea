--[[mudlet
type: trigger
name: Spinkick Head
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
- pattern: ^Whirling around, you bring the ball of your foot crashing into the temple of (\w+).$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^As your blow lands with a crunch, you perceive that you have dealt ([0-9\.]+)\% damage to (\w+)'s head\.$
  type: 1
]]--

local person = multimatches[1][2]
local maybemiss = multimatches[3][1]

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  ignoreThirdPerson = true

    lastLimbAttack = "shikSpinkickHead"
    if  ataxiaTemp.shikCombo.attackone == "kuro" and ataxiaTemp.shikCombo.attacktwo == "kuro" then
relaydoublekuro = true else relaydoublekuro = false  end
if  ataxiaTemp.shikCombo.attackone == "ruku" and ataxiaTemp.shikCombo.attacktwo == "ruku" then
relaydoubleruku = true else relaydoubleruku = false  end


if partyrelay and relaydoublekuro then  send("pt "..target..": weariness lethargy")
elseif partyrelay and relaydoubleruku then  send("pt "..target..": clumsiness healthleech")


end
end



local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikSpinkickHead = damage
if tAffs.damagedhead then tAffs.mangledhead = true tLimbs.H = 200 end
