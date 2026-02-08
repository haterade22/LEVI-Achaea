if matches[4] then
	shaman.spiritlore.attunements = { matches[2], matches[3], matches[4] }
elseif matches[3] then
	shaman.spiritlore.attunements = { matches[2], matches[3] }
else
	shaman.spiritlore.attunements = { matches[2] }
end