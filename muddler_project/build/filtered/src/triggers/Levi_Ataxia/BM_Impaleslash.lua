selectString(line,1)
  setBold(true)
  fg("gold")
  deselect()
  resetFormat()
timpaleslash = true
tempTimer(29, [[timpaleslash = false]])

-- BM Brokenstar phase engine callback
if blademaster and blademaster.onImpaleslashSuccess then blademaster.onImpaleslashSuccess() end