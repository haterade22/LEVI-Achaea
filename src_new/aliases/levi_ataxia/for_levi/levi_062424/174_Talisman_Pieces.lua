--[[mudlet
type: alias
name: Talisman Pieces
hierarchy:
- Levi_Ataxia
- Ataxia
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^tpcs$
command: ''
packageName: ''
]]--

for piece, count in pairs(talismanPieces) do
	echo("\n"..piece:title()..string.rep(" ", 40-string.len(piece)).."x"..count)
end
send(" ")