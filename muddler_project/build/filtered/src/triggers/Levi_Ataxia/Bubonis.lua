if not isTargeted(matches[2]) then return end

if not haveAff("asthma") then
  tarAffed("asthma")
else
  tarAffed("slickness")
end

predictBal("class", 1.8)	