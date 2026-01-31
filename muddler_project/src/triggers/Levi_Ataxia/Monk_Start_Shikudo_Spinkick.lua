local limb_map = {
 ["temple"] = "head",
 ["ribs"] = "torso"
 }
if isTarget(matches[4]) then
 if matches[3] == "temple" then
  if not tarAff["prone"] then
	 gotAff("prone")
	end
 end
 limbhit(limb_map[matches[3]], "shikudo", "spinkick"..limb_map[matches[3]])
 monk.shikudo.limb_hit(limb_map[matches[3]], "spinkick")
end
