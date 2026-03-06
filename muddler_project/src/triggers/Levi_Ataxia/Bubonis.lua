if not isTargeted(matches[2]) then return end

if not haveAff("asthma") then
  tarAffed("asthma")
  if applyAffV3 then applyAffV3("asthma") end
else
  tarAffed("slickness")
  if applyAffV3 then applyAffV3("slickness") end
end

predictBal("class", 1.8)	