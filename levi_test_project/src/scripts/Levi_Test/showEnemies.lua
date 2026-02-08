function zgui.showEnemies()
  clearWindow("enemyDisplay")
	for i=1, table.size(zgui.enemies), 1 do
		cecho("enemyDisplay", "<white>"..i.."- <gray>"..zgui.enemies[i].."\n")
	end
end