ataxiaTemp.lastLimbHit = multimatches[1][3]

if isTargeted(multimatches[1][2]) then
  lastLimbAttack = "dragonRend"
  moveCursor(0, getLineNumber()-1)
  tarAffed(envenomList[1])
  if applyAffV3 then applyAffV3(envenomList[1]) end
  table.remove(envenomList, 1)
end
