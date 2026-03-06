if tAffs.nocaloric == true and tAffs.shivering then
tarAffed("shivering")
if applyAffV3 then applyAffV3("shivering") end
tarAffed("disrupted")
if applyAffV3 then applyAffV3("disrupted") end
tarAffed("frozen")
if applyAffV3 then applyAffV3("frozen") end
  if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Shivering, Disrupted and Frozen") end
elseif tAffs.nocaloric == true and not tAffs.shivering then
tarAffed("shivering")
if applyAffV3 then applyAffV3("shivering") end
tarAffed("disrupted")
if applyAffV3 then applyAffV3("disrupted") end
  if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Shivering and Disrupted") end
else
tarAffed("nocaloric")
if applyAffV3 then applyAffV3("nocaloric") end
tarAffed("disrupted")
if applyAffV3 then applyAffV3("disrupted") end
  if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Disrupted") end
end