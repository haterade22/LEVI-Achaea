--tAffs.burrow = true

local burrowed, tar = string.match(multimatches[1][2]:lower(), "swarm burrow ([!@#$%^&*-=_+~]?[a-z0-9]+)")

if isTargeted(multimatches[2][2]) then
  tAffs.burrow = true
  if applyAffV3 then applyAffV3("burrow") end
  pariah.burrow = string.trim(burrowed)

  selectString(line,1)
  fg("green")
  deselect()
  resetFormat()

  cecho("   <DimGrey>>><NavajoWhite>"..string.trim(burrowed).."<DimGrey><<")
end

