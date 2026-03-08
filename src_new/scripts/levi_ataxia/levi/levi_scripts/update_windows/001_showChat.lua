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
  ["shout"]      = "<teal>",
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

function zgui.showChat()
  local shortName = ""
  local chatWindow = false
  local text = stripAnsi(gmcp.Comm.Channel.Text.text)
  local person = gmcp.Comm.Channel.Text.talker:title()
  local color = getChannelColor(gmcp.Comm.Channel.Start)
  
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

  -- Always report direct channel messages (ct, ht, ot, tells, etc.)
  -- Only filter ambient "says" messages based on database
  local alwaysShowChannels = {"ct", "ht", "hts", "hnt", "ot", "clt", "party", "tell", "market", "armytell", "newbie", "shout", "yell"}
  local isDirectChannel = false
  for _, chan in ipairs(alwaysShowChannels) do
    if string.starts(gmcp.Comm.Channel.Start, chan) then
      isDirectChannel = true
      break
    end
  end

  if isDirectChannel or detectedFromText or ataxiaNDB_Exists(person) or table.contains(ataxiaNDB.divine, person) or person == "You" then
    report = true
  end
  
  
  if person == gmcp.Char.Status.name or person == "You" then
    cecho(chatWindow, color .. text .. "<reset>\n")
    if chatWindow ~= "All" then
      cecho("All", color .. text .. "<reset>\n")
    end
	elseif report then
		cecho(chatWindow, color .. text .. "<reset>\n")

		if not only_to_misc and chatWindow ~= "All" then
			cecho("All", color .. text .. "<reset>\n")
		end

    if string.find(gmcp.Comm.Channel.Start:lower(), "tell") and not string.find(gmcp.Comm.Channel.Start:lower(), "army") and not muteList[person] and person ~= "You" then 
        ataxiaBasher_alert("Normal") 
    end    

	end
	only_to_misc = false	

  enableTrigger("Ataxia Chat Capture")
end

registerAnonymousEventHandler("gmcp.Comm.Channel.Start", "zgui.showChat")