if not ataxia.settings.lustlist then
	ataxia.settings.lustlist = {}
end

if not ataxia.lustedto then
	ataxia.lustedto = {}
end

local person = matches[2]
if ataxia.reject and ataxia.reject == person then ataxia.reject = nil end
for n, p in pairs(ataxia.lustedto) do
	if p == person then
		table.remove(ataxia.lustedto, n)
	end
end

ataxia_boxEcho("rejected lust of "..person, "green")
