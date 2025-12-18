-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Game-specific > Lusternia > Astral utilities

local astralExits =
  {
    {5079, 5175, "n"},
    {5072, 5065, "w"},
    {5088, 5132, "e"},
    {5145, 5176, "s"},
    {5138, 5146, "e"},
    {5158, 5192, "s"},
    {5152, 5041, "e"},
    {5031, 5042, "e"},
    {5022, 5131, "n"},
    {5116, 5198, "w"},
    {5130, 5096, "e"},
    {5089, 5058, "n"},
    {5102, 5115, "e"},
    {5111, 5159, "e"},
    {5103, 5071, "n"},
    {5059, 5053, "w"},
    {5187, 5169, "w"},
    {5190, 5204, "e"},
    {5065, 5072, "e"},
    {45333, 5093, "u"},
    {45334, 5113, "u"},
    {45356, 5075, "u"},
    {45335, 5171, "u"},
    {45357, 5066, "u"},
    {45329, 5156, "u"},
    {45330, 5201, "u"},
    {45331, 5121, "u"},
    {45324, 5055, "u"},
    {45354, 5177, "u"},
    {45325, 5024, "u"},
    {45355, 5133, "u"},
  }
local mirror =
  {
    n = "s",
    ne = "sw",
    e = "w",
    se = "nw",
    s = "n",
    sw = "ne",
    w = "e",
    nw = "se",
    u = "d",
    d = "u",
    out = "in",
    ["in"] = "out",
  }

function mmp.astroboots()
  if mmp.game ~= "lusternia" then
    return
  end
  local option = mmp.settings.astrojump
  mmp.echo("<green>" .. (option and "Set up" or "Removed") .. " <white>Astrojump <green>exits")
  local exitString = [[script:if gmcp.Room.Info.exits.%s then send("%s", false) else send("astrojump", false) end]]
  for k, v in pairs(astralExits) do
    if option then
      addSpecialExit(v[1], v[2], string.format(exitString, v[3], v[3]))
      addSpecialExit(v[2], v[1], string.format(exitString, mirror[v[3]], mirror[v[3]]))
    else
      removeSpecialExit(v[1], "astrojump")
      removeSpecialExit(v[2], "astrojump")
      removeSpecialExit(v[1], string.format(exitString, v[3], v[3]))
      removeSpecialExit(v[2], string.format(exitString, mirror[v[3]], mirror[v[3]]))
    end
  end
end

function mmp.wildnodes(create)
  if mmp.game ~= "lusternia" then
    return
  end
  for k, v in pairs(astralExits) do
    if create then
      mmp.setExit(v[1], v[2], v[3])
      mmp.setExit(v[2], v[1], mirrorExits[v[3]])
    else
      mmp.setExit(v[1], -1, v[3])
      mmp.setExit(v[2], -1, mirrorExits[v[3]])
    end
  end
end