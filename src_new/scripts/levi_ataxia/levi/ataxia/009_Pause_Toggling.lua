--[[mudlet
type: script
name: Pause Toggling
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

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