if isTarget(matches[3]) then
 flash_leg = matches[2]
 local limb = flash_leg.." leg"
 monk.shikudo.limb_hit(limb, "flashheel")
else
 flash_leg = "none"
end