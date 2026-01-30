--[[mudlet
type: trigger
name: 1Jinzuku (addiction)
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
- pattern: ^Stepping to the side of (\w+)\, you drive .+ at \w+ kidneys.$
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
  ignoreThirdPerson = true

    moveCursor(0, getLineNumber()-1)
    tarAffed("addiction")
    moveCursorEnd()
    lastLimbAttack = "shikJinzuku"
if partyrelay and not ataxia.afflictions.aeon then send("pt "..target..": addiction")
      end
end

local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikJinzuku = damage
