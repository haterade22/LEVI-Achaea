--[[mudlet
type: trigger
name: Trip (mounted)
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
- pattern: ^You deftly hook .+ behind (\w+)'s foot and send \w+ tumbling off .+ before driving the point of the weapon into
    (\w+) (.*).$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^As you carve into (\w+), you perceive that you have dealt (.+)\% damage to \w+ (torso|head|left arm|right arm|right
    leg|left leg).$
  type: 1
]]--

if isTargeted(multimatches[1][2]) then
	lastLimbAttack = "sentTrip"
end