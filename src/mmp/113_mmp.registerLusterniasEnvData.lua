-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Game-specific > Lusternia > mmp.registerLusterniasEnvData

function mmp.registerLusterniasEnvData(_, game)
  if game ~= "Lusternia" then return end

  mmp.envids =
  {
    ["constructed underground"] = 2,
    ["deep ocean"]              = 24,
    ["natural underground"]     = 3,
    ["constructed underwater"]  = 41,
    aether                      = 36,
    astral                      = 35,
    beach                       = 5,
    chaos                       = 39,
    clouds                      = 37,
    concordance                 = 38,
    darkness                    = 1,
    desert                      = 6,
    divine                      = 33,
    farmlands                   = 30,
    flesh                       = 18,
    forest                      = 4,
    freshwater                  = 22,
    garden                      = 21,
    grasslands                  = 7,
    hills                       = 9,
    jungle                      = 17,
    mountains                   = 14,
    netherworld                 = 34,
    ocean                       = 20,
    path                        = 11,
    polar                       = 27,
    reef                        = 25,
    river                       = 10,
    road                        = 12,
    ruins                       = 19,
    sewer                       = 23,
    swamp                       = 15,
    trees                       = 28,
    tundra                      = 16,
    urban                       = 8,
    valley                      = 13,
    volcanic                    = 32,
    wasteland                   = 29,
    badlands                    = 40,
    wetlands                    = 31,
  }

  mmp.waterenvs = {}
  local waterids = { "river", "ocean", "freshwater", "deep ocean" }
  for i = 1, #waterids do mmp.waterenvs[mmp.envids[waterids[i]]] = true end

  mmp.envidsr = {};
  for name, id in pairs(mmp.envids) do mmp.envidsr[id] = name end
end