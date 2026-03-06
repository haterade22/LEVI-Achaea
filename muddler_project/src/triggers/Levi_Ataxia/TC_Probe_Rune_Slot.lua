if totemChecker and totemChecker.state and totemChecker.state.active
   and totemChecker.state.phase == "probing" then
  local runeDesc = matches[2]
  local slotNum = tonumber(matches[3])
  local runeName = totemChecker.runeDescToName[runeDesc] or "unknown"
  totemChecker.onProbeSlot(slotNum, runeName)
end
