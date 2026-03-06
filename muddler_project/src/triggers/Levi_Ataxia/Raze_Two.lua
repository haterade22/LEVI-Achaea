if tAffs.shield and tAffs.rebounding then
erAff("rebounding")
if removeAffV3 then removeAffV3("rebounding") end
elseif tAffs.rebounding then
erAff("rebounding")
if removeAffV3 then removeAffV3("rebounding") end
elseif tAffs.shield and not tAffs.rebounding then
erAff("shield")
if removeAffV3 then removeAffV3("shield") end
end


bardtemposequence = bardtemposequence + 1

