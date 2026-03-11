local name = matches[2]

if isTargeted(name) then
  erAff("sleep")
  selectString(line, 1)
  fg("NavajoWhite")
  resetFormat()
  targetIshere = true
end
