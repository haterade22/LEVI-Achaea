--[[mudlet
type: alias
name: Talisman Pieces
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Other stuff
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