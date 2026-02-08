--if last hit was a limb then set parry
if table.contains(monk.shikudo.limb_table, monk.shikudo.limbs_hit[#monk.shikudo.limbs_hit]) then
	monk.shikudo.target_parry = monk.shikudo.limbs_hit[#monk.shikudo.limbs_hit]
	tparry = monk.shikudo.target_parry 
	cecho("<red>\n TARGET IS PARRYING " ..tparry)
	raiseEvent("target_window_change")
	if not table.contains(monk.shikudo.parrying, monk.shikudo.limbs_hit[#monk.shikudo.limbs_hit])  then
	 monk.shikudo.parrying[#monk.shikudo.parrying+1] = monk.shikudo.limbs_hit[#monk.shikudo.limbs_hit]
	end
end