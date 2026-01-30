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

function ataxiagui_populateChannels()
  if ataxia.usegui == true or ataxia.usegui == nil then
    ataxiagui.Chat.Channels = ataxiagui.Chat.Channels or {}
    ataxiagui.Chat.Channels.last = ataxiagui.Chat.Channels.last or ""
    ataxiagui.Chat.Channels.types = {
      ["newbie"] = "Misc",
      ["market"] = "Misc", 
      ["ct"] = "City",
      ["ht"] = "Tells",
      ["hts"] = "Tells",
      ["hnt"] = "Tells",
      ["clt"] = "Clans",
      ["party"] = "Party",
      ["tell"] = "Tells",
      ["says"] = "Misc",
      ["ot"] = "Order",
    }
    cecho("\n<green>Chat channels updated!")
  end
end

function ataxiagui_processChat(channel)
  if ataxia.usegui ~= nil and ataxia.usegui == false then return end

	local ofr, ofg, ofb = getFgColor()
	local obr, obg, obb = getBgColor()
	local text = ansi2decho(gmcp.Comm.Channel.Text.text)
	local person = gmcp.Comm.Channel.Text.talker:title()
	if person == "The guardian spirit of the totem" then 
		only_to_misc = false
		return
	end
  local report = false
  -- Always report city/party channel messages detected from text (NPCs like Weltar)
  if ataxiagui.Chat.Channels.detectedFromText or ataxiaNDB_Exists(person) or table.contains(ataxiaNDB.divine, person) or gmcp.Comm.Channel.Start == "shout" or person == "You" then
    report = true
  end
  
  
  if person == gmcp.Char.Status.name or person == "You" then
		ataxiagui.Chat[channel.."center"]:decho(text.."\n")
		ataxiagui.Chat.Allcenter:decho(text.."\n")	
	elseif report then
    
		if gmcp.Comm.Channel.Start == "shout" then
			ataxiagui.Chat[channel.."center"]:cecho("<cyan> "..gmcp.Comm.Channel.Text.talker.."<red>: ")
		end	
		ataxiagui.Chat[channel.."center"]:decho(text.."\n")
	
		if not only_to_misc then
			if gmcp.Comm.Channel.Start == "shout" then
				ataxiagui.Chat.Allcenter:cecho("<cyan> "..gmcp.Comm.Channel.Text.talker.."<red>: ")
			end			
			ataxiagui.Chat.Allcenter:decho(text.."\n")
		end

    if string.find(gmcp.Comm.Channel.Start:lower(), "tell") and not string.find(gmcp.Comm.Channel.Start:lower(), "army") and not muteList[person] and person ~= "You" then 
        ataxiaBasher_alert("Normal") 
    end    

	end
	only_to_misc = false	
	
end

function ataxiagui_captureChat()
  if ataxia.usegui ~= nil and ataxia.usegui == false then return end
	local ch = gmcp.Comm.Channel.Start

	if not ataxiagui.Chat.Channels then
		ataxiagui_populateChannels()
	end
	ataxiagui.Chat.Channels.talker = gmcp.Comm.Channel.Text.talker:title()
	ataxiagui.Chat.Channels.last = "Misc"

	for c, t in pairs(ataxiagui.Chat.Channels.types) do
		if ch:find(c) then
			ataxiagui.Chat.Channels.last = t
			break
		end
	end

	-- Override for "says" - check if it's actually a city/party tell based on text
	ataxiagui.Chat.Channels.detectedFromText = false
	if ch == "says" then
		local detectedChannel = detectChannelFromText(gmcp.Comm.Channel.Text.text)
		if detectedChannel then
			ataxiagui.Chat.Channels.last = detectedChannel
			ataxiagui.Chat.Channels.detectedFromText = true
		end
	end

	if t == "Tells" and not muteList[ataxiagui.Chat.Channels.talker] and ataxiagui.Chat.Channels.talker ~= "You" then 
    ataxiaBasher_alert("Normal") 
  end

	enableTrigger("Ataxia Chat Capture")

	
	--Check if it was over Party, and if it was a target call.
--	if ch == "web" and helixTemp.webListen and helixTemp.webListen[helixgui.Chat.Channels.talker] then
--		local spoken = gmcp.Comm.Channel.Text.text
--		if spoken:find("Target") then
--			local tc = string.match(spoken, "Target: (%w+)%.")
--			--If it was matched correctly, then change target!
--			switchTarget(tc)
--		end
--	end
	
	ataxiagui_processChat(ataxiagui.Chat.Channels.last)



end

registerAnonymousEventHandler("gmcp.Comm.Channel.Start", "ataxiagui_captureChat")