-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > ZulahGUI - Saonji Edit > zGUI Redux > Update Windows > showAllies

function zgui.showAllies()
  clearWindow("allyDisplay")
	for i=1, table.size(zgui.allies), 1 do
		cecho("allyDisplay", "<white>"..i.."- <gray>"..zgui.allies[i].."\n")
	end
end