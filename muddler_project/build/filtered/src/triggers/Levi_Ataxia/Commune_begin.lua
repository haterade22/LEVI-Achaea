echo("\n")
if shaman.spiritlore.autobind then
	shaman.bindspirits()
	if #shaman.spiritlore.unwanted_bindings > 0 then
		shaman.unbindspirits()
	end
end