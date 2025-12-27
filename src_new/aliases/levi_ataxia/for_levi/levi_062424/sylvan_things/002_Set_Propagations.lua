--[[mudlet
type: alias
name: Set Propagations
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Installation / Configuration
- Sylvan Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^prop (\w+) (\w+)$
command: ''
packageName: ''
]]--

if not ataxia_isClass("Sylvan") then 
	return
end

if not ataxia.sylvanStuff then
	ataxia.sylvanStuff = {propagateList = {arms = false, legs = false, head = false, body = false}}
	ataxiaEcho("Sylvan stuff defaulted to normal values. Check <red>aconfig sylvan help<Navajowhite> for info.")
end

local loc, herb = matches[2]:lower(), matches[3]:lower()
local props = {
	"bloodroot", "kelp", "bellwort", "valerian", "lobelia", "elm", "sileris", "kola",
	"goldenseal", "skullcap", "hawthorn",
}

if ataxia.sylvanStuff.propagateList[loc] ~= nil then
	if table.contains(props, herb) then
		ataxia.sylvanStuff.propagateList[loc] = herb
		ataxiaEcho("Will now propagate "..loc.." with "..herb..".")
	elseif herb == "none" then
		ataxia.sylvanStuff.propagateList[loc] = false
		ataxiaEcho("No longer propagating "..loc.." with anything.")
	else
		ataxiaEcho("Invalid propagation, choose from: "..table.concat(props, ", ").." or none.")
	end
else
	ataxiaEcho("Invalid propagation location.")
end