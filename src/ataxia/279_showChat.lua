-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > ZulahGUI - Saonji Edit > zGUI Redux > Update Windows > showChat

function zgui.showChat()
  local shortName = ""
  local chatWindow = false
	local ofr, ofg, ofb = getFgColor()
	local obr, obg, obb = getBgColor()  
  local text = ansi2decho(gmcp.Comm.Channel.Text.text)
  local person = gmcp.Comm.Channel.Text.talker:title()
  
  for k,v in pairs(gmcp.Comm.Channel.List) do
    shortName = gmcp.Comm.Channel.List[k].command
  end
  local chatChannels = {
      ["says"] = "All",
      ["armytell"] = "City",
      ["yell"] = "Misc",
      ["shout"] = "Misc",
      ["ct"] = "City",
      ["newbie"] = "Misc",
      ["market"] = "Market", 
      ["ht"] = "House",
      ["hts"] = "House",
      ["hnt"] = "House",
      ["clt"] = "Clans",
      ["party"] = "Party",
      ["tell"] = "Tells",
      ["ot"] = "Order",
    }

  for chan, wind in pairs(chatChannels) do
    if string.starts(gmcp.Comm.Channel.Start, chan) then
      chatWindow = wind 
      break
    end
  end
  if not chatWindow then chatWindow = "Misc" end

	
	if person == "The guardian spirit of the totem" then 
		only_to_misc = false
		return
	end
  local report = false
  
  if ataxiaNDB_Exists(person) or table.contains(ataxiaNDB.divine, person) or gmcp.Comm.Channel.Start == "shout" or person == "You" then
    report = true
  end
  
  
  if person == gmcp.Char.Status.name or person == "You" then
    decho(chatWindow, text.."\n")
    if chatWindow ~= "All" then
		  decho("All", text.."\n")
    end
	elseif report then    
		if gmcp.Comm.Channel.Start == "shout" then
      cecho(chatWindow, "<cyan> "..person.."<red>: ")
		end	
		decho(chatWindow, text.."\n")
	
		if not only_to_misc and chatWindow ~= "All" then
			if gmcp.Comm.Channel.Start == "shout" then
				cecho("All", "<cyan> "..gmcp.Comm.Channel.Text.talker.."<red>: ")
			end			
			decho("All", text.."\n")
		end

    if string.find(gmcp.Comm.Channel.Start:lower(), "tell") and not string.find(gmcp.Comm.Channel.Start:lower(), "army") and not muteList[person] and person ~= "You" then 
        ataxiaBasher_alert("Normal") 
    end    

	end
	only_to_misc = false	

  enableTrigger("Ataxia Chat Capture")
end

registerAnonymousEventHandler("gmcp.Comm.Channel.Start", "zgui.showChat")