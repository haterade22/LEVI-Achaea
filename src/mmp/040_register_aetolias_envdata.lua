-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Game-specific > Aetolia > register_aetolias_envdata

function register_aetolias_envdata(_, game)
  if game ~= "Aetolia" then return end

  mmp.envids =
  {
    ["a bridge"]                = 55,
    ["Airship wreckage"]        = 62,
    ["camp site"]               = 57,
    ["Constructed underground"] = 2,
    ["Deep ocean"]              = 24,
    ["lifeless sands"]          = 54,
    ["logged forest"]           = 56,
    ["Natural underground"]     = 3,
    ["Tsol'aa city"]            = 19,
    ["Underwater city"]         = 28,
    ["within a tree"]           = 36,
    Beach                       = 5,
    Canyon                      = 34,
    Castle                      = 61,
    Cavern                      = 69,
    Chaos                       = 1,
    Crater                      = 37,
    Desert                      = 6,
    Ethereal                    = 67,
    Forest                      = 4,
    Freshwater                  = 22,
    Garden                      = 21,
    Grasslands                  = 7,
    Graveyard                   = 31,
    grotto                      = 70,
    Hills                       = 9,
    Ice                         = 30,
    Jungle                      = 17,
    lava                        = 39,
    Mines                       = 32,
    Mountains                   = 14,
    Ocean                       = 20,
    Onboard                     = 33,
    Path                        = 11,
    Reef                        = 25,
    River                       = 10,
    Road                        = 12,
    Ruins                       = 26,
    Sewer                       = 23,
    Shadows                     = 58,
    Swamp                       = 15,
    Temple                      = 29,
    Tundra                      = 16,
    Urban                       = 8,
    Valley                      = 13,
    Village                     = 27,
  }

  mmp.waterenvs = {}
  local waterids = { "River", "Freshwater", "Deep ocean", "Reef", "Underwater city" }
  for i = 1, #waterids do mmp.waterenvs[mmp.envids[waterids[i]]] = true end

  mmp.envidsr = {};
  for name, id in pairs(mmp.envids) do mmp.envidsr[id] = name end
end