--[[mudlet
type: trigger
name: Gained Rebounding
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
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
- pattern: ^You suddenly perceive the vague outline of an aura of rebounding around (\w+).$
  type: 1
]]--


if target == matches[2] then
	tAffs.rebounding = true
		tarAffed("rebounding")
	-- v4.7.275: the raze-vs-attack choice is made at dispatch time, so a rebounding raised after
	-- we queued is eaten. On 2026-08-19 this line printed 830ms before our armslash landed; the
	-- reflection put 18.1% into our own left arm and was the hit that broke it.
	if blademaster and blademaster.onTargetDefenceUp then
		blademaster.onTargetDefenceUp("Rebounding")
	end
	selectString(line,1)
	setBold(true)
	fg("NavajoWhite")
	resetFormat()
end

--Archaeon reaches out and nimbly plucks the arrow from the air.
--You begin sketching a thurisaz rune on the ground.