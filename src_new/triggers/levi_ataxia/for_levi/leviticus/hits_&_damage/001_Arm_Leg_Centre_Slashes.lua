--[[mudlet
type: trigger
name: Arm|Leg|Centre Slashes
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- BM
- Hits & Damage
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
- pattern: As you carve into \w+, you perceive that you have dealt ([\d.]+)% damage to \w+ (left leg|right leg|left arm|right
    arm|head|torso)\.$
  type: 1
- pattern: '1'
  type: 5
- pattern: As you carve into \w+, you perceive that you have dealt ([\d.]+)% damage to \w+ (left leg|right leg|left arm|right
    arm|head|torso)\.$
  type: 1
]]--

if gmcp.Char.Status.class == "Blademaster" then

ataxiaTables.limbData.bmSlash = tonumber(multimatches[1][2])
ataxiaTables.limbData.bmOffSlash = tonumber(multimatches[3][2])

ataxiaTables.limbData.bmBaseSlash = tonumber(multimatches[1][2])
ataxiaTables.limbData.bmBaseOffSlash = tonumber(multimatches[3][2])


bmslash1 = tonumber(multimatches[1][2])
bmslash2 = tonumber(multimatches[3][2])


end
