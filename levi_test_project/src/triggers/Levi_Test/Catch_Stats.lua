deleteLine()
if matches[2] == "strength" then
  zData.char.str = matches[3]
elseif matches[2] == "dexterity" then
  zData.char.dex = matches[3]
elseif matches[2] == "intelligence" then
  zData.char.int = matches[3]
elseif matches[2] == "constitution" then
  zData.char.con = matches[3]
end