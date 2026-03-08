deleteLine()
if matches[2] == "strength" then
  ataxia.data.char.str = matches[3]
elseif matches[2] == "dexterity" then
  ataxia.data.char.dex = matches[3]
elseif matches[2] == "intelligence" then
  ataxia.data.char.int = matches[3]
elseif matches[2] == "constitution" then
  ataxia.data.char.con = matches[3]
end