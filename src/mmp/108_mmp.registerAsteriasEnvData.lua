-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Game-specific > Asteria > mmp.registerAsteriasEnvData

function mmp.registerAsteriasEnvData(_, game)
  if game ~= "Asteria" then
    return
  end
  mmp.envids =
    {
      Air = 20,
      Airship = 21,
      Badland = 22,
      Beach = 23,
      Carriage = 24,
      Cave = 25,
      City = 26,
      Coast = 27,
      Default = 28,
      Desert = 29,
      Field = 30,
      Forest = 31,
      Ghetto = 32,
      Hills = 33,
      Home = 34,
      Inn = 35,
      Inside = 36,
      Marsh = 37,
      Mountain = 38,
      Road = 39,
      Ship = 40,
      Shop = 41,
      Temple = 42,
      Tundra = 43,
      Underwater = 44,
      Vehicle = 45,
      Water = 46,
    }
  mmp.waterenvs = {}
  mmp.envidsr = {}
  for name, id in pairs(mmp.envids) do
    mmp.envidsr[id] = name
  end


mmp.colorcodes = {}
mmp.colorcodes[20] = {176, 224, 230, 255}
mmp.colorcodes[21] = {160, 82, 45, 255}
mmp.colorcodes[22] = {205, 133, 63, 255}
mmp.colorcodes[23] = {218, 165, 32, 255}
mmp.colorcodes[24] = {132, 112, 255, 255}
mmp.colorcodes[25] = {47, 79, 79, 255}
mmp.colorcodes[26] = {190, 190, 190, 255}
mmp.colorcodes[27] = {210, 180, 140, 255}
mmp.colorcodes[28] = {255, 69, 0, 255}
mmp.colorcodes[29] = {255, 215, 0, 255}
mmp.colorcodes[30] = {127, 255, 0, 255}
mmp.colorcodes[31] = {0, 100, 0, 255}
mmp.colorcodes[32] = {184, 134, 11, 255}
mmp.colorcodes[33] = {50, 205, 50, 255}
mmp.colorcodes[34] = {102, 205, 170, 255}
mmp.colorcodes[35] = {0, 128, 128, 255}
mmp.colorcodes[36] = {255, 250, 205, 255}
mmp.colorcodes[37] = {107, 142, 35, 255}
mmp.colorcodes[38] = {139, 69, 19, 255}
mmp.colorcodes[39] = {112, 128, 144, 255}
mmp.colorcodes[40] = {265, 42, 42, 255}
mmp.colorcodes[41] = {0, 190, 255, 255}
mmp.colorcodes[42] = {138, 43, 226, 255}
mmp.colorcodes[43] = {255, 250, 250, 255}
mmp.colorcodes[44] = {65, 105, 225, 255}
mmp.colorcodes[45] = {90, 158, 160, 255}
mmp.colorcodes[46] = {30, 144, 255, 255}

function mmp.setAsteriaColorcodes()
  for id, rgba in pairs(mmp.colorcodes) do
    setCustomEnvColor(id, rgba[1], rgba[2], rgba[3], rgba[4])
  end
 end
end