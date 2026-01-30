local removeThisEnemy = table.index_of(zgui.enemies, matches[2])
table.remove(zgui.enemies, removeThisEnemy) 	
zgui.showEnemies()