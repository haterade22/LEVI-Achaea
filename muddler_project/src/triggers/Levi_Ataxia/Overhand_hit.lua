--dbg(matches[1])
if SLC_blocked(matches[1]) == false then
 if slc.overhand_weapon == "hammer" then
  SLC_connects(slc_last_limb,"overhand_hammer")
 elseif slc.overhand_weapon == "blade" then
  SLC_connects(slc_last_limb,"overhand_blade")
 end
end