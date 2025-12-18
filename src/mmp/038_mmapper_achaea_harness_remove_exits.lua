-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Game-specific > Achaea > mmapper_achaea_harness_remove_exits

function mmapper_achaea_harness_remove_exits()
  local areaID = getRoomArea(mmp.currentroom) or 0
  if not (mmp.game == "achaea" and mmp.settings.harness) then
    return
  end
  if mmp.oncontinent(areaID, "Eastern_Isles") then
    mmp.clearspecials({54231})
  elseif mmp.oncontinent(areaID, "Northern_Isles") then
    mmp.clearspecials({48719})
  elseif mmp.oncontinent(areaID, "Western_Isles") then
    mmp.clearspecials({54632})
  end
end