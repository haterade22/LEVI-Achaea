--[[mudlet
type: alias
name: Mineral Locations
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Other stuff
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^extract$
command: ''
packageName: ''
]]--

ataxiaExtraction = ataxiaExtraction or {}
local minList = {
  "ferrum", "stannum", "dolomite", "antimony", "bisemutum", "cuprum",
  "magnesium", "calamine", "malachite", "azurite", "plumbum",
  "realgar", "arsenic", "gypsum", "argentum", "calcite", "potash",
  "quicksilver", "aurum", "quartz", "cinnabar",
}
cecho("\n<LightSkyBlue>These are the areas we have found minerals in so far...\n")
for _, mineral in ipairs(minList) do
  cecho("\n  <green>[<NavajoWhite>"..mineral:title().."<green>]: ")
  for area, min in spairs(ataxiaExtraction) do
    if min == mineral then
      echo(area..", ")
    end
  end
  echo("\n ")
end