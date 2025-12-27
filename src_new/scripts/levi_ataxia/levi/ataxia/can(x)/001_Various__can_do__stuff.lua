--[[mudlet
type: script
name: Various "can do" stuff
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Curing Stuff
- Can(x)
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function canBals()
	if ataxia_paused() then return false end
	if ataxia.vitals.bal and ataxia.vitals.eq then
		return true
	else
		return false
	end
end

function canStand()
	if ataxia_paused() then return false end
	if not affed("damagedrightleg") and not affed("brokenrightleg") and not affed("mangledrightleg")
		and not affed("damagedleftleg") and not affed("brokenleftleg") and not affed("mangledleftleg")
		and not affed("impaled") and not affed("transfixation") and not affed("roped") and not affed("webbed")
		and not affed("entangled") and not affed("sleep") and not affed("stun")
	then
		return true
	else
		return false
	end
end

function canParry()
	if ataxia_paused() then return false end
	if canStand() and ataxia.vitals.bal and ataxia.vitals.eq
		and not affed("damagedleftarm") and not affed("damagedrightarm") and not affed("prone")
		and not affed("mangledleftarm") and not affed("mangledrightarm") and not affed("aeon")
		and not affed("brokenleftarm") and not affed("brokenrightarm") and not affed("paralysis")
	then
		return true
	else
		return false
	end
end

function canOutrift()
	if ataxia_paused() then return false end
	if not affed("damagedrightarm") and not affed("brokenrightarm") and not affed("mangledrightarm")
		and not affed("damagedleftarm") and not affed("brokenleftarm") and not affed("mangledleftarm")
		and not affed("impaled") and not affed("transfixed") and not affed("roped") and not affed("webbed")
		and not affed("entangled") and not affed("sleep") and not affed("aeon")
	then
		return true
	else
		return false
	end
end