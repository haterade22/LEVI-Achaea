-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Game-specific > Dragonswords > mmp.registerDragonswordsEnvData

function mmp.registerDragonswordsEnvData(_, game)
  if game ~= "dragonswords" then
    return
  end
  mmp.envids =
    {
      ["inside"] = 1,
        ["city"] = 2,
        ["field"] = 3,
        ["forest"] = 4,
        ["hills"] = 5,
        ["mountain"] = 6,
        ["swim"] = 7,
        ["noswim"] = 8,
        ["underwater"] = 9,
        ["air"] = 10,
        ["desert"] = 11,
        ["river"] = 12,
        ["oceanfloor"] = 13,
        ["underground"] = 14,
        ["jungle"] = 15,
        ["swamp"] = 16,
        ["tundra"] = 17,
        ["ice"] = 18,
        ["ocean"] = 19,
        ["lava"] = 20,
        ["shore"] = 21,
        ["tree"] = 22,
        ["stone"] = 23,
        ["quicksand"] = 24,
        ["wall"] = 25,
        ["glacier"] = 26,
        ["exit"] = 27,
        ["trail"] = 28,
        ["badlands"] = 29,
        ["grassland"] = 30,
        ["scrub"] = 31,
        ["barren"] = 32,
        ["bridge"] = 33,
        ["road"] = 34,
    }
  mmp.waterenvs = {}
  mmp.envidsr = {}
  for name, id in pairs(mmp.envids) do
    mmp.envidsr[id] = name
  end
end