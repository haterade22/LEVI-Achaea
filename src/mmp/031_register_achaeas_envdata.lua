-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Game-specific > Achaea > register_achaeas_envdata

function register_achaeas_envdata(_, game)
  if game ~= "Achaea" then
    return
  end
  mmp.envids =
    {
      ["Constructed underground"] = 2,
      ["Crimson Sea"] = 45,
      ["Deep Ocean"] = 24,
      ["Deep Ocean floor"] = 30,
      ["Dwarven city"] = 18,
      ["Lava Fields"] = 39,
      ["Magma Caves"] = 31,
      ["Natural underground"] = 3,
      ["Ocean floor"] = 34,
      ["Planar Highway"] = 42,
      ["Sanguine River"] = 44,
      ["Tsol'aa city"] = 19,
      ["Vast Ocean"] = 40,
      Abstract = 37,
      Agrarian = 48,
      Ausafoss = 47,
      Beach = 5,
      Blighted = 29,
      Catacombs = 14,
      Chaos = 38,
      Desert = 6,
      Earthen = 43,
      Flames = 49,
      Forest = 4,
      Freshwater = 22,
      Garden = 21,
      Grasslands = 7,
      Hills = 9,
      Jungle = 17,
      Mountains = 14,
      Nothing = 0,
      Ocean = 20,
      Path = 11,
      Polar = 27,
      Reef = 25,
      River = 10,
      Road = 12,
      Ruins = 32,
      Sewer = 23,
      Skies = 10,
      Storm = 50,
      Swamp = 15,
      Trees = 28,
      Tundra = 16,
      Urban = 8,
      Valley = 13,
      Vessel = 36,
      Viscera = 46,
      Wastelands = 41,
      Water = 30,
    }
  mmp.waterenvs = {}
  local waterids =
    {"Freshwater", "Ocean", "River", "Deep Ocean", "Water", "Reef", "Ocean floor", "Vast Ocean"}
  for i = 1, #waterids do
    mmp.waterenvs[mmp.envids[waterids[i]]] = true
  end
  mmp.envidsr = {}
  for name, id in pairs(mmp.envids) do
    mmp.envidsr[id] = name
  end
end