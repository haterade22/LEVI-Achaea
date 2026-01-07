--[[mudlet
type: script
name: showChat
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- ZulahGUI - Saonji Edit
- zGUI Redux
- Update Windows
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- Detect channel from message text when GMCP reports "says"
local function detectChannelFromText(text)
  -- City channels - check for (CityName): pattern
  local cities = {"Mhaldor", "Ashtan", "Cyrene", "Eleusis", "Hashan", "Targossas"}
  for _, city in ipairs(cities) do
    if text:match("%(" .. city .. "%)") then
      return "City"
    end
  end

  -- Party channel
  if text:match("%(Party%)") then
    return "Party"
  end

  return nil
end

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

  -- Override for "says" - check if it's actually a city/party tell based on text
  local detectedFromText = false
  if gmcp.Comm.Channel.Start == "says" then
    local detectedChannel = detectChannelFromText(gmcp.Comm.Channel.Text.text)
    if detectedChannel then
      chatWindow = detectedChannel
      detectedFromText = true
    end
  end

  if not chatWindow then chatWindow = "Misc" end


	if person == "The guardian spirit of the totem" then
		only_to_misc = false
		return
	end
  local report = false

  -- Always report city/party channel messages detected from text (NPCs like Weltar)
  if detectedFromText or ataxiaNDB_Exists(person) or table.contains(ataxiaNDB.divine, person) or gmcp.Comm.Channel.Start == "shout" or person == "You" then
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