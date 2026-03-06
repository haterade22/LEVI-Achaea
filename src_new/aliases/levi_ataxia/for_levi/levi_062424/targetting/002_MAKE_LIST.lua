--[[mudlet
type: alias
name: MAKE LIST
hierarchy:
- Levi_Ataxia
- General
- Targeting
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^sete (\w+(,? a?n?d? ?\w+)*){1}\.?$
command: ''
packageName: ''
]]--

 local enemies = {}
  for enemy in string.gmatch(matches[2], '[^, ]+') do
    if enemy ~= 'and' then
      enemies[#enemies + 1] = string.lower(enemy)
    end
  end
sendAll('unenemy all', 'enemy '.. table.concat(enemies, ' ; enemy '))