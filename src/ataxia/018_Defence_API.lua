-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Deffing > Defence API

function haveDef(def)
	if ataxia.defences[def] then
		return true
	else
		return false
	end
end

function supportedDefence(def)
	buildDefsTable()
	local support = false
	for csd, ssd in pairs(ataxiaTables.defences, def) do
		if (csd == def) or (ssd == def) then
			support = true
			break
		end
	end
	return support
end

function addToDefup(defence)
	local cur = ataxia.settings.defences.current
	if cur == "" then
		ataxiaEcho("Not currently in a defup profile. Please fix it.")
		return
	end

	if not ataxia.settings.defences.defup[cur][defence] then
		ataxia.settings.defences.defup[cur][defence] = true
		ataxiaEcho(defence.." has been added to the "..cur.." defup profile.")
	else
		ataxiaEcho(defence.." is already in the "..cur.." defup profile.")
	end
end

function addToKeepup(defence)
	local cur = ataxia.settings.defences.current
	if cur == "" then
		ataxiaEcho("Not currently in a defup profile. Please fix it.")
		return
	end

	if not ataxia.settings.defences.keepup[cur][defence] then
		ataxia.settings.defences.defup[cur][defence] = true
		ataxia.settings.defences.keepup[cur][defence] = true
		ataxiaEcho(defence.." has been added to the "..cur.." keepup profile.")
		send("curing priority defence "..defence.." 25")
	else
		ataxiaEcho(defence.." is already in the "..cur.." keepup profile.")
	end
end

function toggleKeepup(defence, option)
	local cur = ataxia.settings.defences.current
	if cur == "" then
		ataxiaEcho("Not currently in a defup profile. Please fix it.")
		return
	end

	if option == nil then
		if not ataxia.settings.defences.keepup[cur][defence] then
			ataxia.settings.defences.keepup[cur][defence] = true
			ataxiaEcho(defence.." has been added to the "..cur.." keepup profile.")
		else
			ataxia.settings.defences.keepup[cur][defence] = nil
			ataxiaEcho(defence.." has been removed to the "..cur.." keepup profile.")
		end
	elseif type(option) == "boolean" then
		ataxia.settings.defences.keepup[cur][defence] = (option == true and true or nil)
		ataxiaEcho((option == true and "Added" or "Removed").." "..defence.." "..(option == true and "to" or "from").." the "..cur.." keepup profile.")
	else
		ataxiaEcho("Toggling must be either true, or false, for defences.")
	end
end

function gotDef()
	local def = trueDef(gmcp.Char.Defences.Add.name)
	local cur = ataxia.settings.defences.current

	if not def:find("parrying") and not ataxiaBasher.enabled then
		cecho("\n<green>+ ( def <NavajoWhite>"..def:lower().."<green> ) +")
	end
	ataxia.defences[def:lower()] = true

	if cur ~= "" and not def:find("parrying") and not def:find("blocking") then
		if not ataxia.settings.defences.keepup[cur][def] and not ataxiaBasher.enabled then
			send("curing priority defence "..def:lower().." reset",false)
		end
    
    if def:lower() == "shield" or def:lower() == "curseward" then
      if ataxia.prioritySwaps and ataxia.prioritySwaps.parshield and ataxia.prioritySwaps.parshield.active then
        sendAll("curing priority slickness 25;curing priority paralysis 25",false)
        tempTimer(1.4, [[ ataxia_restorePrio("paralysis");ataxia_restorePrio("slickness") ]])
      end
    elseif def == "alertness" then
      enableTrigger("Alertness Tracking")
    end
	end
end

function lostDef()
	local def = gmcp.Char.Defences.Remove
	if def[1] == "hyperfocus" then
		ataxiaEcho("No longer hyperfocusing a limb.")
  elseif def[1] == "alertness" then
    disableTrigger("Alertness Tracking")
  elseif def[1] == "prismatic" and ataxiaTemp.lyreMode then
    send("curing on",false)
    local sp = ataxia.settings.separator 
    send("queue addclear free stand"..sp.."curing off"..sp.."strum lyre",false)
	elseif not ataxiaBasher.enabled then
		cecho("\n<red>- ( def <NavajoWhite>"..def[1]:lower().."<red> ) -")
		if def[1]:lower() == "speed" then
			ataxia_boxEcho("BEWARE OF AEON - SPEED HAS BEEN STRIPPED", "NavajoWhite:a_darkmagenta")
		end
	end
	ataxia.defences[def[1]:lower()] = nil
	ataxiaTemp.lokiCheck = true

end

function defenceList()
	local defs = gmcp.Char.Defences.List
	ataxia.defences = {}

	for _, def in pairs(defs) do
		ataxia.defences[def.name:lower()] = true
	end
end

registerAnonymousEventHandler("gmcp.Char.Defences.List", "defenceList")
registerAnonymousEventHandler("gmcp.Char.Defences.Add", "gotDef")
registerAnonymousEventHandler("gmcp.Char.Defences.Remove", "lostDef")

-- Avoid defence type management
-- Valid types: physical, mental, arcane, aoe
function setAvoidType(avoidType)
  local validTypes = {physical = true, mental = true, arcane = true, aoe = true}
  avoidType = avoidType and avoidType:lower() or "physical"

  if not validTypes[avoidType] then
    ataxiaEcho("Invalid avoid type. Valid options: physical, mental, arcane, aoe")
    return false
  end

  ataxia.settings.avoidType = avoidType
  buildDefsTable()  -- Rebuild tables with new avoid type
  ataxiaEcho("Avoid type set to: " .. avoidType:upper())
  ataxiaEcho("Use 'defup' to apply the new setting.")
  return true
end

function getAvoidType()
  return ataxia.settings.avoidType or "physical"
end