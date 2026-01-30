--[[mudlet
type: trigger
name: Flashheel (break leg)
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
- pattern: ^Snapping your leg out to its full extent, you drive a heel into the (\w+) knee of (\w+).$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^As your blow lands with a crunch, you perceive that you have dealt ([0-9\.]+)\% damage to (\w+)'s (left leg|right
    leg)\.$
  type: 1
]]--

local person = multimatches[1][3]
local maybemiss = multimatches[3][1]
ataxiaTemp.lastLimbHit = multimatches[1][3]

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  moveCursor(0, getLineNumber()-1)
  tarAffed("broken"..multimatches[1][2].."leg")
  moveCursorEnd()
  lastLimbAttack = "shikFlashheel"
end

local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikFlashheel = damage
