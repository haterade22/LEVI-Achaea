--[[mudlet
type: trigger
name: Stood Up
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^(\w+) stands up.$
  type: 1
]]--

if isTargeted(matches[2]) then
	local rem = {"prone", "paralysis", "brokenleftleg", "damagedleftleg", "brokenrightleg", "damagedrightleg"}
	if tLimbs.LL >= 100 then tLimbs.LL = 0 end
	if tLimbs.RL >= 100 then tLimbs.RL = 0 end
  if lb[target].hits["left leg"] >= 100 then lb[target].hits["left leg"] = 0 end
  if lb[target].hits["right leg"] >= 100 then lb[target].hits["right leg"] = 0 end
	for _, aff in pairs(rem) do
		erAff(aff)
	end
end