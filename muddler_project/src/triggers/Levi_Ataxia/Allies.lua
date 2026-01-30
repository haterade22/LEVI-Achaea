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

selectString(matches[2], 1)
fg("red")
deselect()

if ataxia_needReject() then
	send("queue addclear free reject "..ataxiaTemp.reject..ataxia.settings.separator.."enemy "..person,false)
end
