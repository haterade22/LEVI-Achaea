if matches[2] == "right" then
tarAffed("damagedhead")
tarAffed("damagedrightarm")
tarAffed("impatience")
tarAffed("stupidity")
tarAffed("slickness")
lb[target].hits["right arm"] = lb[target].hits["right arm"] + rapierdamage
lb[target].hits["head"] = lb[target].hits["head"] + rapierdamage
elseif matches[2] == "left" then
tarAffed("damagedhead")
tarAffed("damagedleftarm")
tarAffed("impatience")
tarAffed("stupidity")
tarAffed("slickness")
lb[target].hits["left arm"] = lb[target].hits["left arm"] + rapierdamage
lb[target].hits["head"] = lb[target].hits["head"] + rapierdamage
end
bardsunset = true
tempTimer(2.5, [[bardsunset = false]])