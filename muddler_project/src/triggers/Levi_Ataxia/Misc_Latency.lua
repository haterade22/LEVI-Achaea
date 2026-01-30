if isTargeted(matches[2]) then
  tAffs.burrow = true

  if pariah.latency then killTimer(pariah.latency) end
  pariah.latency = tempTimer(12, [[ pariah.latency = nil ]])

  if haveAff("voyria") then
    ataxia_boxEcho("TARGET PRIMED FOR DEATH", "DimGrey")
  end
end

ataxia_boxEcho("TARGET HAS LATENCY", "DimGrey")