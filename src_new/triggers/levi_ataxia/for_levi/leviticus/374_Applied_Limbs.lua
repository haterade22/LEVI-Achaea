--[[mudlet
type: trigger
name: Applied Limbs
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
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
- pattern: ^(\w+) takes some salve from a vial and rubs it on \w+ (arms|legs).$
  type: 1
]]--

if isTargeted(matches[2]) then
tdeliverance = false
  if passiveFailsafe then restorePassiveCure() end
	erAff("slickness")
	target_appliedTo(matches[3])
	targetIshere = true
	erAff("bloodfire")
end
 
--Pre-Apply Counter
if isTargeted(matches[2]) and matches[3] == "legs" then
  if mprepped_leftleg == true and mprepped_rightleg == true then
    tarpreapply = true
    tempTimer(4, [[tarpreapply = false]] )	
    else 
    tarpreapply = false
  end
end