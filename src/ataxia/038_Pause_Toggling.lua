-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Pause Toggling

function ataxiaToggle(opt)
	if opt == nil then
		if ataxia.settings.paused then
			send("curing on")
		else
			send("curing off")
		end
	else
		send("curing "..opt)
	end
end