local t, hp, mhp = matches[2], tonumber(matches[4]), tonumber(matches[5])
local php = math.floor((hp/mhp)*100)
local hpb = math.floor(php/5)

if not isTargeted(t) then return end
ataxiaTemp.lastAssess = php


if type(target) == "string" then
	if isTargeted(t) then
		deleteLine()
		cecho("\n<red> +[<NavajoWhite>"..target.."<red>] HP: <SeaGreen>[<green>"..string.rep("=", hpb)..string.rep(" ", 20-hpb).."<SeaGreen>] <red>"..php.."% -- <NavajoWhite>"..hp.."/"..mhp.." ")
		if ataxia_isClass("magi") then
			magi_setBreakpoint(mhp)
			magi_setDestroy(php)
		end
    
    if php <= 49.99 and (ataxia_isClass("Druid") or ataxia_isClass("monk")) then
      ataxia_boxEcho("TARGET IS IN INSTAKILL RANGE", "NavajoWhite:chat_bg")
    end
    
	end
end
