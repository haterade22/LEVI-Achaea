if not ataxia.settings.lustlist then
	ataxia.settings.lustlist = {}
end

local person = matches[2]

if not table.contains(ataxia.settings.lustlist, person) then
	ataxia_boxEcho("FORCED TO FOLLOW "..person, "red")
	send("queue addclear free lose "..person,false)
end
