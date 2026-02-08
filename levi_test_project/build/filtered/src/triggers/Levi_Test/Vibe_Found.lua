magiVibes_isHere(matches[2])

local vibe = matches[2]:lower()

if ataxiaTemp.embeddingVibes then
	if table.contains(ataxiaTemp.vibes, vibe) then
		table.remove(ataxiaTemp.vibes, table.index_of(ataxiaTemp.vibes, vibe))
  end
end
