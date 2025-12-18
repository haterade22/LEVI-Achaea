-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Game-specific > Achaea > mmp Achaea Orb of Confinement

--returns a table depending on current crowdmap settings. Functionized so that these tables will only have to be stored in one location.
function mmp.getAchaeaOrbTable()
  return
  --first table is areas in each org for the crowdmap, second is for the game provided map.
    mmp.settings.crowdmap and
    {
      ashtan = {49, 53},
      cyrene = {57, 59, 62, 63, 68, 70},
      eleusis = {51},
      hashan = {55, 56, 267},
      mhaldor = {44, 40, 48},
      targossas = {368},
    } or
    {
      ashtan = {49, 53, 54, 60},
      cyrene = {57, 62, 67, 174, 189, 292, 293, 294},
      eleusis = {51},
      hashan = {55, 56},
      mhaldor = {44, 48, 295, 296, 297},
      targossas = {271, 277, 298, 299, 300},
    }
end

--roomID is optional, if not it will default to current room. Returns true if you're in an area covered by the orb of confinement.
function mmp.orbed(roomID)
  if mmp.game ~= "achaea" then
    return false
  end
  local orbTable = mmp.getAchaeaOrbTable()
  --first table is the areas in the city for the crowdmap, second is for the game provided map.
  local areaID = getRoomArea(roomID or mmp.currentroom)
  for city, areaTable in pairs(orbTable) do
    if table.contains(areaTable, areaID) then
      return mmp.settings["orb" .. city]
    end
  end
  return false
end