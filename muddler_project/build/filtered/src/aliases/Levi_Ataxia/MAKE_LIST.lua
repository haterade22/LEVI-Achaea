local enemies = {}
  for enemy in string.gmatch(matches[2], '[^, ]+') do
    if enemy ~= 'and' then
      enemies[#enemies + 1] = string.lower(enemy)
    end
  end
sendAll('unenemy all', 'enemy '.. table.concat(enemies, ' ; enemy '))