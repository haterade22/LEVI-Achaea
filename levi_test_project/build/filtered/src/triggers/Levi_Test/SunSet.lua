if matches[2] == "right" then
tarAffed("damagedhead")
if applyAffV3 then applyAffV3("damagedhead") end
tarAffed("damagedrightarm")
if applyAffV3 then applyAffV3("damagedrightarm") end
tarAffed("impatience")
if applyAffV3 then applyAffV3("impatience") end
tarAffed("stupidity")
if applyAffV3 then applyAffV3("stupidity") end
tarAffed("slickness")
if applyAffV3 then applyAffV3("slickness") end
lb[target].hits["right arm"] = lb[target].hits["right arm"] + rapierdamage
lb[target].hits["head"] = lb[target].hits["head"] + rapierdamage
elseif matches[2] == "left" then
tarAffed("damagedhead")
if applyAffV3 then applyAffV3("damagedhead") end
tarAffed("damagedleftarm")
if applyAffV3 then applyAffV3("damagedleftarm") end
tarAffed("impatience")
if applyAffV3 then applyAffV3("impatience") end
tarAffed("stupidity")
if applyAffV3 then applyAffV3("stupidity") end
tarAffed("slickness")
if applyAffV3 then applyAffV3("slickness") end
lb[target].hits["left arm"] = lb[target].hits["left arm"] + rapierdamage
lb[target].hits["head"] = lb[target].hits["head"] + rapierdamage
end
bardsunset = true
tempTimer(2.5, [[bardsunset = false]])