if isTargeted(matches[2]) then
  tAffs.frozen = true; tAffs.shivering = true; tAffs.nocaloric = true
  if applyAffV3 then applyAffV3("frozen"); applyAffV3("shivering"); applyAffV3("nocaloric") end
	tarAffed("hypothermia")
	if applyAffV3 then applyAffV3("hypothermia") end
  
  ataxia_boxEcho("PUMMEL ME DADDY", "black:DodgerBlue")
end