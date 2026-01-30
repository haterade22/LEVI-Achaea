local minList = {
  "ferrum", "stannum", "dolomite", "antimony", "bisemutum", "cuprum",
  "magnesium", "calamine", "malachite", "azurite", "plumbum",
  "realgar", "arsenic", "gypsum", "argentum", "calcite", "potash",
  "quicksilver", "aurum", "quartz", "cinnabar",
}
if table.contains(minList, matches[2]:lower()) then
  ataxiaExtraction[gmcp.Room.Info.area] = matches[2]:lower()
end