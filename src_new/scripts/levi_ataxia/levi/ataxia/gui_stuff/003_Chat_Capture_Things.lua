--[[mudlet
type: script
name: Chat Capture Things
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Gui Stuff
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

local channelColors = {
  ["says"]       = "<cyan>",
  ["ct"]         = "<red>",
  ["ht"]         = "<yellow>",
  ["hts"]        = "<yellow>",
  ["hnt"]        = "<yellow>",
  ["ot"]         = "<white>",
  ["party"]      = "<magenta>",
  ["tell"]       = "<yellow>",
  ["clt"]        = "<white>",
  ["market"]     = "<white>",
  ["newbie"]     = "<green>",
  ["shout"]      = "<blue>",
  ["yell"]       = "<white>",
  ["armytell"]   = "<white>",
}

-- Look up channel color using prefix matching (GMCP names have suffixes like "tells Proficy", "clt Holocaust Inc")
local function getChannelColor(ch)
  for prefix, color in pairs(channelColors) do
    if string.starts(ch, prefix) then
      return color
    end
  end
  return "<white>"
end

-- Strip ANSI escape sequences from GMCP text (they render as raw [0;37m etc. in miniconsoles)
local function stripAnsi(s)
  return s:gsub("\27%[[%d;]*m", "")
end

function ataxiagui_processChat(channel)
  if ataxia.usegui ~= nil and ataxia.usegui == false then return end

	local text = stripAnsi(gmcp.Comm.Channel.Text.text)
	local person = gmcp.Comm.Channel.Text.talker:title()
	local color = getChannelColor(gmcp.Comm.Channel.Start)
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
		ataxiagui.Chat[channel.."center"]:cecho(color .. text .. "<reset>\n")
		ataxiagui.Chat.Allcenter:cecho(color .. text .. "<reset>\n")
	elseif report then
		ataxiagui.Chat[channel.."center"]:cecho(color .. text .. "<reset>\n")

		if not only_to_misc then
			ataxiagui.Chat.Allcenter:cecho(color .. text .. "<reset>\n")
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