--[[mudlet
type: timer
name: TargetOutOfRoom
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- leviticus
- Levi Ataxia
- MY TIMERS
attributes:
  isActive: 'no'
  isFolder: 'no'
  isTempTimer: 'no'
  isOffsetTimer: 'no'
time: '00:00:01.400'
command: ''
packageName: ''
]]--

if targetIshere or not tAffs then
	disableTimer("TargetOutOfRoom")
	return
else
	if haveAff("anorexia") then
		if not haveAff("impatience") then
			erAff("anorexia")
		elseif not haveAff("slickness") then
			erAff("anorexia")
		end
	end

	if tAffs.slickness and not tAffs.asthma then
		erAff("slickness")
	end

	if not haveAff("anorexia") then
		if haveAff("impatience") and not haveAff("whisperingmadness") then
			erAff("impatience"); erAff("confusion"); erAff("epilepsy") erAff("stupidity"); erAff("masochism"); erAff("dizziness")
		elseif haveAff("paralysis") then
			erAff("paralysis")
		elseif haveAff("asthma") then
			erAff("asthma")
			erAff("weariness")
			if haveAff("slickness") then erAff("slickness") end
		elseif haveAff("haemophilia") then
			erAff("haemophilia")
			tAffs.bleed = 0
		elseif tarIsTempered() then
			taTempers()
		else
			tAffs = {blindness = true, deafness = true, shield = false, rebounding = false, curseward = false}
      affTimers = {}
			if ataxiaTemp.hypnoseal then tAffs.hypnoseal = true end
      if pariah and pariah.ensorcell then tAffs.ensorcelled = true end
      if pariah and pariah.burrow then tAffs.burrow = true end
			if bmFistTimer then tAffs.airfist = true end
			disableTimer("TargetOutOfRoom")
		end
	end
end