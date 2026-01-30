if isTargeted(multimatches[1][3]) then
  if next(envenomList) then
    moveCursor(0, getLineNumber()-1)
    tarAffed(envenomList[1])
    table.remove(envenomList, 1)
    moveCursorEnd()
  end
	lastLimbAttack = "sentSpear"
end