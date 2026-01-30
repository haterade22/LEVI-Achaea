if tAffs.nocaloric == true and tAffs.shivering then
tarAffed("shivering")
tarAffed("disrupted")
tarAffed("frozen")
  if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Shivering, Disrupted and Frozen") end
elseif tAffs.nocaloric == true and not tAffs.shivering then
tarAffed("shivering")
tarAffed("disrupted")
  if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Shivering and Disrupted") end
else
tarAffed("nocaloric")
tarAffed("disrupted")
  if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Disrupted") end
end