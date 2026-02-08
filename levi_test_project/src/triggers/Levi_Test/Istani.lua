if not ataxia.settings.highlighting or not ataxia.settings.highlighting.guards then return end

for i = 1, #matches, 2 do
  local line = matches[i]
  local pos = selectString(line, 1)
  moveCursor("main", pos+#line-1, getLineNumber())

  cinsertText("<LightSkyBlue> (<SlateGrey>istani: <orange>hinders<LightSkyBlue>)")
end

deselect()
resetFormat()
moveCursorEnd()

