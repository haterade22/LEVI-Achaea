if isTargeted(matches[2]) then
tdeliverance = false
  if passiveFailsafe then restorePassiveCure() end
	-- V2 tracking support: head salve cures slickness and other affs
	if onTargetSalveHeadV2 then onTargetSalveHeadV2(matches[2]) end
	-- V3 integration: head salve cure branching
	if onSalveCureV3 then onSalveCureV3("head") end
	erAff("slickness")
	if haveAff("crushedthroat") then
		erAff("crushedthroat")
	elseif tLimbs.H >= 98 and tLimbs.H < 200 then
		tempTimer(4, [[target_resetLimb("head");erAff("damagedhead")]])
    target_salveBal(4)
  elseif lb[target].hits["head"] >= 100 and lb[target].hits["head"] < 200 then
    tempTimer(4, [[erAff("damagedhead")]])
    target_salveBal(4)
  elseif lb[target].hits["head"] >= 200 then
    tempTimer(4, [[erAff("mangledhead")]])
    target_salveBal(4)
  elseif tLimbs.H >= 200 then
		tempTimer(4, [[tLimbs.H = 100]])
    tempTimer(4, [[erAff("mangledhead")]])
    target_salveBal(4)
   
  elseif vodunCheck then
    target_salveBal(4)
    vodunCheck = nil
  else
    --check epidermal stuff
    for _, aff in pairs({ "blindness", "scalded", "epidermal" }) do
      if haveAff(aff) then
        erAff(aff)
        break
      end
    end
	end
	erAff("bloodfire")
	targetIshere = true
end

if isTargeted(matches[2]) then 
  if magi.calcifying_head or lb[target].hits["head"] > 100 then
    magi.calficy_resto = true
    if resto_timer then
      killTimer(resto_timer)
    end
    resto_timer = tempTimer(4, [[magi.calcify_resto = false]])
    end
end