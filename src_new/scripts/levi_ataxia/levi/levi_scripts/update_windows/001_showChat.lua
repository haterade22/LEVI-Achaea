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

-- Channel color map for decho (GMCP text only has white ANSI, so we colorize by channel)
local channelColors = {
  ct = "<0,200,0>",           -- city tell: green
  armytell = "<0,200,0>",     -- army: green
  ht = "<200,200,0>",         -- house tell: yellow
  hts = "<200,200,0>",
  hnt = "<200,200,0>",
  ot = "<180,100,255>",       -- order: purple
  clt = "<200,100,50>",       -- clan: orange
  party = "<0,200,200>",      -- party: cyan
  tell = "<200,0,200>",       -- tells: magenta
  market = "<0,180,180>",     -- market: teal
  says = "<200,200,200>",     -- says: light gray
  shout = "<255,100,100>",    -- shout: red
  yell = "<255,100,100>",     -- yell: red
  newbie = "<255,255,0>",     -- newbie: yellow
}

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

-- Get decho color prefix for a GMCP channel
local function getChannelColor(channel)
  for prefix, color in pairs(channelColors) do
    if string.starts(channel, prefix) then
      return color
    end
  end
  return "<200,200,200>"
end

function zgui.showChat()
  local chatWindow = false
  local text = ansi2string(gmcp.Comm.Channel.Text.text)  -- strip ANSI (GMCP only sends white)
  local color = getChannelColor(gmcp.Comm.Channel.Start)
  local person = gmcp.Comm.Channel.Text.talker:title()

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

  -- Suppress muted users in chat windows
  if muteList[person] then
    enableTrigger("Ataxia Chat Capture")
    return
  end

  local coloredText = color .. text

  if person == gmcp.Char.Status.name or person == "You" then
    decho(chatWindow, coloredText .. "\n")
    if chatWindow ~= "All" then
      decho("All", coloredText .. "\n")
    end
  elseif report then
    if gmcp.Comm.Channel.Start == "shout" then
      cecho(chatWindow, "<cyan> " .. person .. "<red>: ")
    end
    decho(chatWindow, coloredText .. "\n")

    if not only_to_misc and chatWindow ~= "All" then
      if gmcp.Comm.Channel.Start == "shout" then
        cecho("All", "<cyan> " .. gmcp.Comm.Channel.Text.talker .. "<red>: ")
      end
      decho("All", coloredText .. "\n")
    end

    if string.find(gmcp.Comm.Channel.Start:lower(), "tell") and not string.find(gmcp.Comm.Channel.Start:lower(), "army") and not muteList[person] and person ~= "You" then
      ataxiaBasher_alert("Normal")
    end

  end
	only_to_misc = false	

  enableTrigger("Ataxia Chat Capture")
end

registerAnonymousEventHandler("gmcp.Comm.Channel.Start", "zgui.showChat")