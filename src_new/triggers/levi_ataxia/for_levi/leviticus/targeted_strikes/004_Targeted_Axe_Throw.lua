--[[mudlet
type: trigger
name: Targeted Axe Throw
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Sentinel
- Skirmishing
- Targeted Strikes
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
- pattern: ^You cock back your arm and throw (.+) at (\w+)'s (.+).$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^As you carve into (\w+), you perceive that you have dealt (.+)\% damage to \w+ (torso|head|left arm|right arm|right
    leg|left leg).$
  type: 1
]]--

local axe = multimatches[1][2]
if isTargeted(multimatches[1][3]) then
  if next(envenomList) then
    moveCursor(0, getLineNumber()-1)
    tarAffed(envenomList[1])
    table.remove(envenomList, 1)
    moveCursorEnd()
  end
  lastLimbAttack = "weaponryAxe"
end