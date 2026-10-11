--[[mudlet
type: trigger
name: Hiru (dizzy)
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
conditonLineDelta: 2
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^Whirling .+ in a tight arc, you bring
  type: 1
- pattern: '1'
  type: 5
- pattern: ^As your blow lands with a crunch, you perceive that you have dealt ([0-9\.]+)\% damage to (\w+)'s head\.$
  type: 1
]]--
-- v4.7.413: line 1 is a START fragment and the window is 2 lines, so a strike line that wraps
-- (it carries the staff's name; 127-147 columns against a 119-124 wrap) still pairs with its
-- damage line. Target, damage and limb come from the damage line: 3 = name, 2 = %, 4 = limb.
local person = multimatches[3][3]
local maybemiss = multimatches[3][1]



if isTargeted(person) then
  targetIshere = true
  erAff("shield")
  ignoreThirdPerson = true

    moveCursor(0, getLineNumber()-1)
    tarAffed("dizziness")
    if haveAff("prone") then tarAffed("confusion") end  -- wiki: confusion too if prone (v4.7.413)
    moveCursorEnd()
    lastLimbAttack = "shikHiru"

end
if partyrelay and tAffs.prone then send("pt "..target..": dizziness confusion")
elseif partyrelay and not tAffs.prone then send("pt "..target..": dizziness")
      end
local damage = tonumber(multimatches[3][2])
   ataxiaTables.limbData.shikHiru = damage
