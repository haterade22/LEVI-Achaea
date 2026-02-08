local class = ataxiaNDB_getClass(matches[2]) or "Unknown"
local knights = {"Paladin", "Infernal", "Runewarden", "Unnamable"}
if table.contains(knights, class) then
  dwc_selfLimbHit(matches[3])
end