local amt, loc, col = tonumber(matches[2]), matches[3], ""
local tocol = { ["skull fractures"] = "SF", ["wrist fractures"] = "WF", ["cracked ribs"] = "CR",
	["torn tendons"] = "TT" }
	
if trackingFractures then


	if amt < 2 then
		col = "DimGrey"
	elseif amt < 4 then
		col = "yellow"
	elseif amt < 6 then
		col = "orange"
	else
		col = "red"
	end
  
  ataxiaTemp.fractures[loc:gsub(" ", "")] = amt
  
	deleteLine()
	cecho(" <green>(<"..col..">"..amt.." <white>"..tocol[loc].."<green>)")
end

tfractureamt = matches[2]
tfractureloc = matches[3]


ataxiaTemp.fractures.tfractureloc = tfractureamt




