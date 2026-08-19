--[[mudlet
type: trigger
name: Target Shielded
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Misc Alerts
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
- pattern: ^A nearly invisible magical shield forms around (.+).$
  type: 1
- pattern: ^A shimmering barrier of crystal forms about (\w+).$
  type: 1
- pattern: ^The magical shield surrounding (\w+) makes that impossible.$
  type: 1
]]--

if type(target) == "string" and isTargeted(matches[2]) then
	selectString(line, 1)
	fg("orange")
	setBold(true)
	resetFormat()
	send("cq eqbal")
	-- v4.7.275: `cq eqbal` does not touch the `freestand` queue the Blademaster dispatch uses,
	-- so a shield raised after we queued still ate the swing (2026-08-19, 09:58:07 -- the attack
	-- rebounded off it and stunned us). Convert the pending swing to a raze instead.
	if blademaster and blademaster.onTargetDefenceUp then
		blademaster.onTargetDefenceUp("Shield")
	end
  if target == "Kshavatra" then
  erAff("shield")
  else
	tarAffed("shield")
  end
  
end