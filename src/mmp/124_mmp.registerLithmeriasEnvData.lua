-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Game-specific > Lithmeria > mmp.registerLithmeriasEnvData

function mmp.registerLithmeriasEnvData(_, game)
  if game ~= "Lithmeria" then return end

  mmp.envids =
  {
    ["deep water"] = 4,
    beach          = 11,
    bridge         = 6,
    building       = 13,
    cliffs         = 1,
    desert         = 11,
    forest         = 2,
    highway        = 6,
    jungle         = 10,
    mountain       = 1,
    ocean          = 4,
    path           = 6,
    plains         = 3,
    river          = 4,
    road           = 6,
    shallowwater   = 4,
    swamp          = 2,
    tundra         = 7,
    underground    = 8,
    urban          = 8,
    water          = 4,
  }

  for name, number in pairs(mmp.envids) do
    mmp.envids[name] = number+256 -- adjust for in-built colors
  end

  mmp.waterenvs = {}
  local waterids = { "shallowwater", "river", "water", "deep water", "ocean" }
  for i = 1, #waterids do mmp.waterenvs[mmp.envids[waterids[i]]] = true end

  mmp.envidsr = {};
  for name, id in pairs(mmp.envids) do mmp.envidsr[id] = name end
end