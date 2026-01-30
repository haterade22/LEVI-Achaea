if matches[2] == "left" then
tarAffed("damagedleftleg")
tarAffed("mildtrauma")
tarAffed("prone")
tarAffed("asthma")

lb[target].hits["left leg"] = lb[target].hits["left leg"] + rapierdamage
lb[target].hits["torso"] = lb[target].hits["torso"] + rapierdamage



elseif matches[2] == "right" then
tarAffed("damagedrightleg")
tarAffed("prone")
tarAffed("asthma")
tarAffed("mildtrauma")

lb[target].hits["right leg"] = lb[target].hits["right leg"] + rapierdamage
lb[target].hits["torso"] = lb[target].hits["torso"] + rapierdamage


end
bardsunrise = true
tempTimer(2.3, [[bardsunrise = false]])
