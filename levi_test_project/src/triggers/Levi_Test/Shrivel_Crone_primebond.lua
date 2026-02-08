local limb = ""
if isTargeted(matches[2]) then
  limb = matches[3]
elseif isTargeted(matches[3]) then
  limb = matches[2]
else
  return
end
tarAffed("broken"..limb:gsub(" ", ""))
if applyAffV3 then applyAffV3("broken"); applyAffV3(" ") end