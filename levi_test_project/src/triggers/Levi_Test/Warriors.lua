if not ataxia.settings.highlighting or not ataxia.settings.highlighting.guards then return end

for i = 1, #matches, 2 do
  local line = matches[i]
  local pos = selectString(line, 1)
  moveCursor("main", pos+#line-1, getLineNumber())

  cinsertText("<purple> (<SlateGrey>warrior: <orange>prone/breaks<purple>)")
end

deselect()
resetFormat()
moveCursorEnd()