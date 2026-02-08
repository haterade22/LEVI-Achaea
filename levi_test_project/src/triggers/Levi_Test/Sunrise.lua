if matches[2] == "left" then
tarAffed("damagedleftleg")
if applyAffV3 then applyAffV3("damagedleftleg") end
tarAffed("mildtrauma")
if applyAffV3 then applyAffV3("mildtrauma") end
tarAffed("prone")
if applyAffV3 then applyAffV3("prone") end
tarAffed("asthma")
if applyAffV3 then applyAffV3("asthma") end

lb[target].hits["left leg"] = lb[target].hits["left leg"] + rapierdamage
lb[target].hits["torso"] = lb[target].hits["torso"] + rapierdamage



elseif matches[2] == "right" then
tarAffed("damagedrightleg")
if applyAffV3 then applyAffV3("damagedrightleg") end
tarAffed("prone")
if applyAffV3 then applyAffV3("prone") end
tarAffed("asthma")
if applyAffV3 then applyAffV3("asthma") end
tarAffed("mildtrauma")
if applyAffV3 then applyAffV3("mildtrauma") end

lb[target].hits["right leg"] = lb[target].hits["right leg"] + rapierdamage
lb[target].hits["torso"] = lb[target].hits["torso"] + rapierdamage


end
bardsunrise = true
tempTimer(2.3, [[bardsunrise = false]])
