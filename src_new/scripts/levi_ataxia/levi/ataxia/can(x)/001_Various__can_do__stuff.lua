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

-- PARRY spends neither balance nor equilibrium, and a REFUSED parry costs nothing but an error
-- line -- while a parry that never moves costs limb breaks. The gate is therefore deliberately
-- permissive: it blocks only on states that make the command genuinely impossible.
--
-- Rewritten v4.7.275 after the 2026-08-19 Grulk (Sentinel) log, where we parried 2 of 44 throws
-- while he walked right leg -> left leg -> left arm -> right leg -> HEAD and killed us on the
-- broken head. Every clause removed below was a state a LIMB-PREP class manufactures on purpose,
-- so the old gate tightened exactly as the opponent's setup improved -- it inverted:
--
--   * `ataxia.vitals.bal and ataxia.vitals.eq` -- parry spends neither. Requiring both excluded
--     every moment of our own attack recovery, for no game reason.
--   * `canStand()` -- returns false on ANY damaged/broken/mangled LEG. A damaged leg does not
--     stop an already-standing character changing cover, and `prone` is checked directly below.
--     His right leg prep alone would have frozen the parry permanently.
--   * `damagedleftarm` / `damagedrightarm` -- sub-break damage. `broken*` / `mangled*` are
--     checked separately, so these two clauses could only ever block, never permit.
--
-- A single broken arm no longer blocks either: you parry with the other one. Both do.
-- Same inversion 003_Parrying.lua fixed in the PvE *selection* path in v4.7.221 ("It used to
-- skip any limb already broken, which is precisely backwards"); the SEND gate was never revisited.
function canParry()
	if ataxia_paused() then return false end

	-- States that stop us issuing or executing any command at all.
	if affed("prone") or affed("paralysis") or affed("aeon")
		or affed("sleep") or affed("stun")
	then
		return false
	end

	-- Nothing left to parry with only when BOTH arms are out.
	local leftOut  = affed("brokenleftarm")  or affed("mangledleftarm")
	local rightOut = affed("brokenrightarm") or affed("mangledrightarm")
	if leftOut and rightOut then return false end

	return true
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