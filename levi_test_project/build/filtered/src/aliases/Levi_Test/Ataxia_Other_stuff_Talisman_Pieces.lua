for piece, count in pairs(talismanPieces) do
	echo("\n"..piece:title()..string.rep(" ", 40-string.len(piece)).."x"..count)
end
send(" ")