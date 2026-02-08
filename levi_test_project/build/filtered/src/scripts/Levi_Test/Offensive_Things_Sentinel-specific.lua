function haveAnimal(what)
	if table.contains(sAnimals, what) then
		return true
	else
		return false
	end
end