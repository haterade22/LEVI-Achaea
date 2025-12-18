-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Prompt Substitution

function alertnessDisplay()
  moveCursor(0, getLineNumber())
  local ppl 
  for dir, list in pairs(ataxiaTemp.alertness) do
    ppl = {}
    for _, person in pairs(ataxiaTemp.alertness[dir]) do
      table.insert(ppl, "<"..ataxiaNDB_getColour(person)..">"..person)
    end
    cinsertText("<firebrick>[<LightSkyBlue>"..dir.."<firebrick>]: "..table.concat(ppl, ", ").. "<cyan> (<NavajoWhite>"..#ppl.."<cyan>)\n")
  end

  moveCursorEnd()


  ataxiaTemp.alertness = nil
end

function ataxiaPrompt_getColour(tag)
	for k,v in pairs(ataxiaPromptColours) do
		if table.contains(ataxiaPromptColours, tag) then
			if type(ataxiaPromptColours[tag]) == "function" then
				return "<"..ataxiaPromptColours[tag]()..">"
			elseif type(ataxiaPromptColours[tag]) == "string" then
				return "<"..ataxiaPromptColours[tag]..">"
			end
		else
			return "<"..tag..">"
		end
	end
end

function ataxiaPrompt_getTag(tag)
  local theTag = false
  local tailEnd = false
    for k,v in pairs(ataxiaPromptTags) do
      if string.starts(tag, k) then
        theTag = k
        tailEnd = string.gsub(tag, theTag, "")
      end
    end
  local th = ataxiaPromptTags[theTag]
  if type(th) == "function" then
    return _G["ataxiaPromptTags"][theTag]() .. tailEnd
  elseif type(th) == "string" then
    return _G["ataxiaPromptTags"][theTag] .. tailEnd
  end
end

function ataxiaPromptSub()
	if not ataxia.settings.customprompt or ataxia.settings.customprompt == "" then return end
	
	selectCurrentLine(); replace("");

	if affed("blackout") then
		if ataxia_paused() then cecho("<red>(paused)") end
		cecho("<black:red> [BLACKOUT]")
		return
	end

	local promptString = string.gsub(ataxia.settings.customprompt, "#([A-Za-z_:]+)", ataxiaPrompt_getColour)
	promptString = string.gsub(promptString, "@(%w+)", ataxiaPrompt_getTag)
	
	local last_colour = nil
	local promptEcho = ""
	
	for colour, text in string.gmatch("<white>"..promptString, "<([A-Za-z_:]+)>([^<]*)" ) do
    if not string.match( colour, "[A-Za-z_]+:[A-Za-z_]+" ) and not color_table[colour] then
      promptEcho = promptEcho .. "<"..colour..">"..text
    else
      if not last_colour then last_colour = colour end

      if not string.find( colour, ":" ) and not string.find( last_colour, ":" ) then
        promptEcho = "<"..last_colour..">"..promptEcho
      end
      promptEcho = promptEcho.."<"..colour..">"..text
      cecho(promptEcho)
      promptEcho = ""
      last_colour = colour
    end
  end
end

--Tables for prompt stuff.
ataxiaPromptTags = {
						--Vitals related things
	["health"] = function() return ataxia.vitals.hp end,
	["percenthealth"] = function() return ataxia.vitals.hpp end,
	["mana"] = function() return ataxia.vitals.mp end,
	["percentmana"] = function() return ataxia.vitals.mpp end,
	["endurance"] = function() return ataxia.vitals.ep end,
	["percentendurance"] = function() return ataxia.vitals.epp end,
	["willpower"] = function() return ataxia.vitals.wp end,
	["percentwillpower"] = function() return ataxia.vitals.wpp end,
	["bleeding"] = function() return ataxia.vitals.bleed end,
	["bal"] = function() if ataxia.vitals.bal then return "x" else return "" end end,
	["eq"] = function() if ataxia.vitals.eq then return "e" else return "" end end,
	["exp"] = function() return gmcp.Char.Status.xp end,
	["rage"] = function() return ataxia.vitals.rage end,
	["hseed"] = function() if ataxiaTemp.heartseedMode then return "HS" else return "" end end,
  ["warning"] = function() return ataxiaTemp.warningText end,

						--Useful tags
	["affs"] = function() return ataxia_promptAffs() end,
	["age"] = function() return (ataxiaTemp.class == "Depthswalker" and " "..ataxiaTables.depthswalker.age.." " or "") end,
	["defs"] = function()
			local defStr = ""
			if ataxia.defences.blindness then defStr = defStr.."<DimGrey>b" end
			if ataxia.defences.deafness then defStr = defStr.."<DimGrey>d" end
			if ataxia.defences.cloak then defStr = defStr.."<DimGrey>c" end
			if ataxia.defences.kola then defStr = defStr.."<DimGrey>k" end
			if ataxia.defences.mass then defStr = defStr.."<DimGrey>m" end
			return defStr
		end,
	["metawake"] = function() if ataxia.defences.metawake then return "<pink>MW" end end,
	["tlimbs"] = function() return limbCounter_textTag() end,
  ["nlimbs"] = function() return limbCounter_numberTag() end,
  ["tarbals"] = function()
    local balStr = ""
    balStr = balStr.."<green>"..(tBals.plant and "H" or "_")
    balStr = balStr.."<DodgerBlue>"..(tBals.salve and "S" or "_")
    balStr = balStr.."<sienna>"..(tBals.tree and "T" or "_")
    balStr = balStr.."<yellow>"..(tBals.focus and "F" or "_")
    return balStr
  end,
	
						--Miscellaneous
            
  ["stance"] = function()
    local sStr = ""
    if ataxiaTemp.class == "Blademaster" then
      sStr = ataxia.vitals.stance or ""
    elseif ataxiaTemp.class == "Monk" then
      if not ataxia.vitals.kata then
        sStr = ataxia.vitals.stance or ""
      else
        sStr = string.sub(ataxia.vitals.form, 1, 2):title().."-"..(ataxia.vitals.kata or 0)
      end
    end
    return sStr
  end,            
  ["shaman"] = function()
    local shamStr = ""
    if ataxiaTemp.class == "Shaman" then
		  if not ataxiaTemp.dollFashions or ataxiaTemp.dollFashions <= 0 then
  			shamStr = "_<magenta>|"
  		else
  			shamStr = ""..ataxiaTemp.dollFashions.."<magenta>|"
  		end
      shamStr = shamStr..(ataxiaTemp.bloodlet and "<green>_" or "<green>B")
      shamStr = shamStr..(ataxiaTemp.coagulate and "<red>_" or "<red>C")
      shamStr = shamStr..(ataxiaTemp.relapse and "<purple>_" or "<purple>R")
    end
    return shamStr
  end,
  		     
	["depthswalker"] = function()
			local dwStr = ""
			if ataxiaTemp.class == "Depthswalker" then
				dwStr = dwStr.."<DimGrey>(<"..getAgeColour()..">"..ataxiaTables.depthswalker.age.."<DimGrey>|"
				dwStr = dwStr..(ataxiaTables.depthswalker.canPreempt and "<green>P" or "<DimGrey>p")
				dwStr = dwStr..(ataxiaTables.depthswalker.causalityBal and "<green>C" or "<DimGrey>c")
				dwStr = dwStr..(ataxiaTables.depthswalker.wordBal and "<green>W<DimGrey>)" or "<DimGrey>w)")
			end
			return dwStr
		end,
	["timestamp"] = function()
			local timestamp = tostring(getTime(true,"hh:mm:ss:zzz"))
			return timestamp
		end,	
	["paused"] = function() if ataxia_paused() then return "(paused)" else return "" end end,
	["targetinfo"] = function()
			if not target or target == "Nothing" or target == "nothing" then return "" end
			local str = ""
			if target then str = "<DimGrey>(<white>"..target end
			if gmcp.IRE.Target and gmcp.IRE.Target.Info and gmcp.IRE.Target.Info.hpperc ~= "-1" then
				if ataxiaTemp.mobhealth ~= 0 then
					str = str.."<DimGrey>|<white>"..gmcp.IRE.Target.Info.hpperc
				end
			end
			str = str.."<DimGrey>)"
			return str
		end,
		
		["class"] = function()
			local power = ataxia.vitals.class or 0
			local str = ""
			if power == 0 then
				str = ""
			elseif power <= 20 then
				str = "<DimGrey>"..power
			elseif power <= 40 then
				str = "<red>"..power
			elseif power <= 60 then
				str = "<orange>"..power
			elseif power <= 80 then
				str = "<yellow>"..power
			else
				str = "<green>"..power
			end
			return str 
		end,
	
}

ataxiaPromptColours = {
	["hcolour"] = function()
			if ataxia.vitals.hpp > 75 then return "green"
			elseif ataxia.vitals.hpp > 50 then return "yellow"
			elseif ataxia.vitals.hpp > 25 then return "orange"
			else return "red" end
		end,
		
	["mcolour"] = function()
			if ataxia.vitals.mpp > 75 then return "green"
			elseif ataxia.vitals.mpp > 50 then return "yellow"
			elseif ataxia.vitals.mpp > 25 then return "orange"
			else return "red" end
		end,
		
	["ecolour"] = function()
			if ataxia.vitals.epp > 75 then return "green"
			elseif ataxia.vitals.epp > 50 then return "yellow"
			elseif ataxia.vitals.epp > 25 then return "orange"
			else return "red" end
		end,
		
	["wcolour"] = function()
			if ataxia.vitals.wpp > 75 then return "green"
			elseif ataxia.vitals.wpp > 50 then return "yellow"
			elseif ataxia.vitals.wpp > 25 then return "orange"
			else return "a_darkred" end
		end,
    
	["darkh"] = function()
			if ataxia.vitals.hpp > 75 then return "a_darkgreen"
			elseif ataxia.vitals.hpp > 50 then return "goldenrod"
			elseif ataxia.vitals.hpp > 25 then return "dark_orange"
			else return "a_darkred" end
		end,
		
	["darkm"] = function()
			if ataxia.vitals.mpp > 75 then return "a_darkgreen"
			elseif ataxia.vitals.mpp > 50 then return "goldenrod"
			elseif ataxia.vitals.mpp > 25 then return "dark_orange"
			else return "a_darkred" end
		end,
		
	["darke"] = function()
			if ataxia.vitals.epp > 75 then return "a_darkgreen"
			elseif ataxia.vitals.epp > 50 then return "goldenrod"
			elseif ataxia.vitals.epp > 25 then return "dark_orange"
			else return "a_darkred" end
		end,
		
	["darkw"] = function()
			if ataxia.vitals.wpp > 75 then return "a_darkgreen"
			elseif ataxia.vitals.wpp > 50 then return "goldenrod"
			elseif ataxia.vitals.wpp > 25 then return "dark_orange"
			else return "a_darkred" end
		end,    
}