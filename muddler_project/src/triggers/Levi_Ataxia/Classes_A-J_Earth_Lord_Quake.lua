if targetIshere or table.contains(ataxia.playersHere) then
  tAffs.prone = true
  if applyAffV3 then applyAffV3("prone") end
  selectString(line,1)
  fg("purple")
  deselect()
  resetFormat()
end