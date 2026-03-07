-- Wire into the revamped SLC system
local limb = matches[2]
if limb and selfLimbDamage and selfLimbDamage[limb] then
	ataxia_clearLimbDamage(limb)
end