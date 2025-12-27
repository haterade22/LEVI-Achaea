--[[mudlet
type: script
name: functions
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- slc
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

registerAnonymousEventHandler("gmcp.Char.Vitals","slc_displayLC")

slc_displayLC = function()

if not slc.percentages then slc_init() end 

   	local head_color = "<green>"     
  	local left_leg = "<green>"
  	local right_leg = "<green>"
  	local left_arm = "<green>"
  	local right_arm = "<green>"
  	local torso_color = "<green>"
  	                      
  	for x, y in ipairs({"left arm","right arm","left leg","right leg","head","torso"}) do
  		if y == "head" then
    		if     slc.percentages[y] >= 75 then head_color = "<red>"
    		elseif slc.percentages[y] >= 66 then head_color = "<orange>"
    		elseif slc.percentages[y] >= 33 then head_color = "<yellow>"
  			end
    	end
  		if y == "left leg" then
    		if     slc.percentages[y] >= 75 then left_leg = "<red>"
    		elseif slc.percentages[y] >= 66 then left_leg = "<orange>"
    		elseif slc.percentages[y] >= 33 then left_leg = "<yellow>"
    		end
  		end
  		if y == "right leg" then
    		if     slc.percentages[y] >= 75 then right_leg = "<red>"
    		elseif slc.percentages[y] >= 66 then right_leg = "<orange>"
    		elseif slc.percentages[y] >= 33 then right_leg = "<yellow>"
    		end
  		end
  		if y == "left arm" then
    		if     slc.percentages[y] >= 75 then left_arm = "<red>"
    		elseif slc.percentages[y] >= 66 then left_arm = "<orange>"
    		elseif slc.percentages[y] >= 33 then left_arm = "<yellow>"
    		end
  		end
  		if y == "right arm" then
    		if     slc.percentages[y] >= 75 then right_arm = "<red>"
    		elseif slc.percentages[y] >= 66 then right_arm = "<orange>"
    		elseif slc.percentages[y] >= 33 then right_arm = "<yellow>"
    		end
  		end
  		if y == "torso" then
    		if     slc.percentages[y] >= 75 then torso_color = "<red>"
    		elseif slc.percentages[y] >= 66 then torso_color = "<orange>"
    		elseif slc.percentages[y] >= 33 then torso_color = "<yellow>"
    		end
  		end										
  	end
  
	--clearUserWindow("slc_LimbcounterDisp")
  --cecho("slc_LimbcounterDisp", "<white>     <green>SLC<white>\n")
  --cecho("slc_LimbcounterDisp", "<white>      "..head_color..""..round(slc.percentages["head"]).."<white>")
  --cecho("slc_LimbcounterDisp","  <gray>      ^")
  --cecho("slc_LimbcounterDisp", "<white>  "..left_arm..""..round(slc.percentages["left arm"]).."<white> <gray>< <white>"..torso_color..""..round(slc.percentages["torso"]).."<white> <gray>> <white>"..right_arm..""..round(slc.percentages["right arm"]).."<white>") 
  --cecho("slc_LimbcounterDisp","<gray>    v   v")
  --cecho("slc_LimbcounterDisp","  <white> "..left_leg..""..round(slc.percentages["left leg"]).."<white>     "..right_leg..""..round(slc.percentages["right leg"]).."<white>")
  

end

function SLC_connects(limb,attack)
		slc_last_attack = attack

		if slc.attacks[attack] == nil then
			--cecho("<red>Error: <white> Bad input to SLC_Connects (attack) : "..attack..".  Using \"other\"")
			attack = "other"
		end
--==change: added attack_mod==--
        local attack_mod = 1.00
        if attack=="tekurakick" then
           attack="tekura"
        elseif attack == "legslash" or attack == "compassslash" or attack == "armslash" then
           attack_mod = slc_stance_mod()
        end
--------------------------------
		slc.hitcount[limb] = slc.hitcount[limb] + 1
		slc.percentages[limb] = slc.percentages[limb] + 100/slc.attacks[attack]
		
--==Change: Added last_attack and attack modifiers==--
		    if slc.last_attack == "tekurakick" then
                slc.hitcount[limb] = slc.hitcount[limb] + .334
                slc.percentages[limb] = slc.percentages[limb] + (100/slc.attacks[attack])/3
        end
        if attack == "legslash" then
                if limb == "right leg" then    
                        slc.hitcount["left leg"] = slc.hitcount["left leg"] + slc.bm_ratio * attack_mod
                        slc.percentages["left leg"] = slc.percentages["left leg"] + 100/slc.attacks[attack]*slc.bm_ratio * attack_mod
                else
                        slc.hitcount["right leg"] = slc.hitcount["right leg"] + (slc.bm_ratio * attack_mod)
                        slc.percentages["right leg"] = slc.percentages["right leg"] + 100/slc.attacks[attack]*slc.bm_ratio * attack_mod
                end
        elseif attack == "armslash" then
                if limb == "right arm" then    
                        slc.hitcount["left arm"] = slc.hitcount["left arm"] + slc.bm_ratio * attack_mod
                        slc.percentages["left arm"] = slc.percentages["left arm"] + 100/slc.attacks[attack]*slc.bm_ratio * attack_mod
                else
                        slc.hitcount["right arm"] = slc.hitcount["right arm"] + slc.bm_ratio * attack_mod
                        slc.percentages["right arm"] = slc.percentages["right arm"] + 100/slc.attacks[attack]*slc.bm_ratio * attack_mod
                end
        elseif attack == "centreslash" then
                if limb == "torso" then
                        slc.hitcount["head"] = slc.hitcount["head"] + slc.bm_ratio * attack_mod
                        slc.percentages["head"] = slc.percentages["head"] + 100/slc.attacks[attack]*slc.bm_ratio * attack_mod
                else
                        slc.hitcount["torso"] = slc.hitcount["torso"] + slc.bm_ratio * attack_mod
                        slc.percentages["torso"] = slc.percentages["torso"] + 100/slc.attacks[attack]*slc.bm_ratio * attack_mod
                end
        end
--------------------------------------------------------
		local limb_color = "white:black"
		if     slc.hitcount[limb] >= slc.attacks[attack]-1 then limb_color = "white:red"
		elseif slc.percentages[limb] >= 66 then limb_color = "orange"
		elseif slc.percentages[limb] >= 33 then limb_color = "yellow"
		end

		--slc_evaluate()
		--SLC_display()
end

--==change: added stance and stance_mod==--
slc_stance = function(stance)
        if slc.bm_stance ~= stance then
                local old = slc.bm_stance
                slc.bm_stance = stance
              --  cecho("<white>BM stance changed from <cyan>"..old.." <white>to <red>"..stance.."<white>.")
        end
end
 
slc_stance_mod = function ()
        return slc.bm_stance_modifiers[slc.bm_stance]
end
-------------------------------------------

function slc_evaluate()



end

function SLC_broke(limb)
	slc.percentages[limb] = 100
	if slc.hitcount[limb] ~= slc.attacks[slc_last_attack] then
		slc.attacks[slc_last_attack] = slc.hitcount[limb]
		for x, y in ipairs({"left arm","right arm","left leg","right leg","head","torso"}) do
			slc.percentages[y] = slc.hitcount[y]*100/slc.attacks[slc_last_attack]
		end
	--	cecho("<blue>(<white>SLC<blue>) <white>"..slc_last_attack:upper().." hits needed to break set to "..slc.hitcount[limb]..".")
	--	cecho("<blue>(<white>SLC<blue>) <white>Limb percentages adjusted to reflect new count")
		--SLC_longdisplay()
	end
	--slc_evaluate()
end


function SLC_display()
	if slc.display == "short" then
		--cecho(""..SLC_shortdisplay())
	elseif slc.display == "long" then
		--cecho(""..SLC_longdisplay())
	end
		--	slc_displayLC()
end

function SLC_force_display()
	if slc.display == "short" then
		cecho("\n"..SLC_shortdisplay())
	else
		cecho("\n"..SLC_longdisplay())
	end
		--slc_displayLC()
end

function SLC_shortdisplay() -- RETURNS A STRING
	local out = "<blue>("
	
		for x, y in ipairs({"left arm","right arm","left leg","right leg","head","torso"}) do
		local limb_color = "white"
		if     slc.percentages[y] >= 75 then limb_color = "red"
		elseif slc.percentages[y] >= 66 then limb_color = "orange"
		elseif slc.percentages[y] >= 33 then limb_color = "yellow"
		end
		out = out.." <"..limb_color..">"..round(slc.percentages[y]).."%"
		if x == 2 or x == 4 then echo(" ") end
	end

	out = out.."<blue> )"

	return out
end

function SLC_longdisplay() -- RETURNS A STRING
	clearWindow("lCount.middle")
	--local out = "<blue>( "
	local out = "     "

	for x, y in ipairs({"left arm","right arm","left leg","right leg","head","torso"}) do
		if     x == 1 then out = out.."<magenta>["
		elseif x == 2 then out = out.."<magenta> | "
		elseif x == 3 then out = out.."<magenta> ]   <yellow>["
		elseif x == 4 then out = out.."<yellow> | "
		elseif x == 5 then out = out.."<yellow> ]   <white>["
		elseif x == 6 then out = out.."<white> ] <green> [\["
		end


		local limb_color = "white"
		if     slc.percentages[y] >= 75 then limb_color = "red"
		elseif slc.percentages[y] >= 66 then limb_color = "orange"
		elseif slc.percentages[y] >= 33 then limb_color = "yellow"
		end

		out = out.." <"..limb_color..">"..round(slc.percentages[y]).."%"
		
	end

	out = out.."<green> ]\]"

	--lCount.middle:cecho(out)
	cecho(out)
	return out

end

function SLC_blocked(line)
	if string.starts(line, "You move inside ") or 
		string.starts(line, "You parry the attack with a deft manoeuvre.") or 
		string.starts(line, "One of your reflections has been destroyed!") or
		string.starts(line, "You twist your body out of harm's way.") or
		string.starts(line, "You dodge nimbly out of the way.") or
		string.starts(line, "You quickly jump back, avoiding the attack.")
	then return true
	else return false
	end
end

function slc_reset()
	slc_init()
	--cecho("<blue>(<white>SLC<blue>) <white>Limb damage reset.")
	--SLC_longdisplay()
end

function SLC_set_attack(attack,n)

if slc.attacks[attack] == nil then
	cecho("<blue>(<white>SLC<blue>) Bad attack type: "..matches[2]:upper())
	cecho("<white Valid attack types: Tekura DSL Rend Thornrend Maul Throwingaxe Staffstraike Smite Crush Other")
else
	slc.attacks[attack] = n
	for x, y in ipairs({"left arm","right arm","left leg","right leg","head","torso"}) do
			slc.percentages[y] = slc.hitcount[y]*100/slc.attacks[slc_last_attack]
	end
	--cecho("<blue>(<white>SLC<blue>) Number of hits needed for <white>"..attack:title().." <blue>set to <white>"..n.."<blue>.")
	--cecho("<blue>(<white>SLC<blue>)<white> Current limbs adjusted for change.")
end

end

function round(num)
   return math.floor(num+0.5)
end

function slc_test()
	slc_reset()
	slc_last_attack = "dsl"
	slc.hitcount.head = 3
	slc.hitcount["right leg"] = 10
	slc.hitcount["left leg"] = 7
	slc.hitcount["right arm"] = 8
	slc.percentages.head = 21
	slc.percentages["right leg"] = 70
	slc.percentages["left leg"] = 49
	slc.percentages["right arm"] = 56
	--SLC_longdisplay()
	--slc_displayLC()
	SLC_broke("right leg")
end

