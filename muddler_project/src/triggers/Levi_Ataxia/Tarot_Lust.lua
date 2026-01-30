if not ataxia.settings.lustlist then
	ataxia.settings.lustlist = {}
end

if not ataxia.lustedto then
	ataxia.lustedto = {}
end

local person = matches[2]
if not table.contains(ataxia.lustedto, person) then
  table.insert(ataxia.lustedto, person)
end

ataxia_boxEcho("Got lusted by "..person, "red")

if ataxia_needReject() then
	send("queue addclear free reject "..person..ataxia.settings.separator.."enemy "..person,false)
end
