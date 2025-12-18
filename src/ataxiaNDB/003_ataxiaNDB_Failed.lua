-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Ataxia NDB > Get Information > ataxiaNDB_Failed

function ataxiaNDB_Failed(_, filepath)
	ataxiaEcho("Error downloading information.")
	
	if filepath:match("server replied: Not Found") then
		echo("\n"..filepath)
		local person = filepath:match("/(%w+).json")
		local fpr = getMudletHomeDir().."/ataxiaNDB/"..person..".json"

		ataxiaEcho("This person does not exist: "..person)
		ataxiaNDB_Remove(person)
		os.remove(fpr)
	else
		ataxiaEcho("Unknown error while downloading: " .. filepath)
	end
end