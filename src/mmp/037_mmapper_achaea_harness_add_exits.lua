-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Game-specific > Achaea > mmapper_achaea_harness_add_exits

function mmapper_achaea_harness_add_exits()
  if not (mmp.game == "achaea" and mmp.settings.harness) then
    return
  end
	local cmd = [[script:send("shake harness",false)]]
  local areaID = getRoomArea(mmp.currentroom) or 0
  if mmp.oncontinent(areaID, "Eastern_Isles") then
    if not mmp.inside then
      -- make it here
      addSpecialExit(mmp.currentroom, 54231, cmd)
    elseif areaID == 192 then
      -- Zanzibaar
      addSpecialExit(31215, 54231, cmd)
    elseif areaID == 191 then
      -- Clockwork Isle
      addSpecialExit(23351, 54231, cmd)
    elseif areaID == 180 then
      -- Colchis, the Isle of
      addSpecialExit(19786, 54231, cmd)
    else
      --if areaID == 181 then -- Umbrin, the Port of
      addSpecialExit(18443, 54231, cmd)
    end
    --madeEast = true
  elseif mmp.oncontinent(areaID, "Northern_Isles") then
    if not mmp.inside then
      -- make it here
      addSpecialExit(mmp.currentroom, 48719, cmd)
    elseif areaID == 194 then
      -- Ilyrean
      addSpecialExit(13373, 48719, cmd)
    elseif areaID == 351 then
      -- Karbaz
      addSpecialExit(19740, 48719, cmd)
    else
      --if areaID == 206 or getRoomArea(mmp.currentroom) = 294 then -- Suliel Island / Suliel Island (Barricades)
      addSpecialExit(17768, 48719, cmd)
    end
  elseif mmp.oncontinent(areaID, "Western_Isles") then
    if not mmp.inside then
      -- make it here
      addSpecialExit(mmp.currentroom, 54632, cmd)
    elseif areaID == 162 then
      --Tapoa
      addSpecialExit(21184, 54632, cmd)
    elseif areaID == 207 then
      --Tuar
      addSpecialExit(19219, 54632, cmd)
    else
      --if areaID == 209 then --Ageiro
      addSpecialExit(30222, 54632, cmd)
    end
  end
end