if matches[2] == target then
tdeliverance = false
-- Eating proves no anorexia (anorexia blocks eating)
erAff("anorexia")
if removeAffV3 then removeAffV3("anorexia") end
erAff("slickness")
if removeAffV3 then removeAffV3("slickness") end
end