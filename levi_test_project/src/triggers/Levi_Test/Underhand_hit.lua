--dbg(matches[1])
if SLC_blocked(matches[1]) == false then
 if slc.underhand_weapon == "hammer" then
  SLC_connects(slc_last_limb,"underhand_hammer")
 elseif slc.underhand_weapon == "blade" then
  SLC_connects(slc_last_limb,"underhand_blade")
 end
end