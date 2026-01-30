function zgui.showAllies()
  clearWindow("allyDisplay")
	for i=1, table.size(zgui.allies), 1 do
		cecho("allyDisplay", "<white>"..i.."- <gray>"..zgui.allies[i].."\n")
	end
end