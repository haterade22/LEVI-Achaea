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

-- Chat colours are the GAME'S colours (v4.7.375). Comm.Channel.Text.text carries the ANSI of the
-- player's CONFIG COLOUR (clans: CONFIG COLOUR CLANS), e.g. "\27[0;1;36mYou say, ..." for Says = 14,
-- so the chat window matches the main window and changing a colour in-game changes both. The old
-- "GMCP only sends white" note was wrong: the channels it was tested on are SET to 7 (white).
--
-- A local converter rather than Mudlet's ansi2decho: misc_scripts/007_Custom_Colour_Table.lua
-- replaces color_table wholesale and has no ansi_* names, and this one is pure, so it is testable.

-- Mudlet's default 16 ANSI colours; Achaea's CONFIG COLOUR numbers 0-15 index this table.
local ANSI16 = {
  [0] = { 0, 0, 0 }, [1] = { 128, 0, 0 }, [2] = { 0, 179, 0 }, [3] = { 128, 128, 0 },
  [4] = { 0, 0, 128 }, [5] = { 128, 0, 128 }, [6] = { 0, 128, 128 }, [7] = { 192, 192, 192 },
  [8] = { 128, 128, 128 }, [9] = { 255, 0, 0 }, [10] = { 0, 255, 0 }, [11] = { 255, 255, 0 },
  [12] = { 0, 0, 255 }, [13] = { 255, 0, 255 }, [14] = { 0, 255, 255 }, [15] = { 255, 255, 255 },
}
local DEFAULT_FG = 7
local CUBE = { 0, 95, 135, 175, 215, 255 }

-- 256-colour index -> r, g, b
local function rgbOf(n)
  n = math.max(0, math.min(255, math.floor(n)))
  if n < 16 then
    local c = ANSI16[n]
    return c[1], c[2], c[3]
  elseif n < 232 then
    n = n - 16
    return CUBE[math.floor(n / 36) + 1], CUBE[math.floor(n / 6) % 6 + 1], CUBE[n % 6 + 1]
  end
  local g = 8 + (n - 232) * 10
  return g, g, g
end

-- GMCP channel text (with ANSI) -> decho string. Foreground only: every channel's BG is 0 and the
-- consoles are black. Any escape that is not a colour is dropped, never printed.
function ataxiagui_chatAnsiToDecho(text)
  if type(text) ~= "string" then return "" end
  local fg, bright, rgb = DEFAULT_FG, false, nil -- rgb = an explicit 256/true colour, wins over fg
  local function tag()
    local r, g, b
    if rgb then
      r, g, b = rgb[1], rgb[2], rgb[3]
    else
      r, g, b = rgbOf((bright and fg < 8) and fg + 8 or fg)
    end
    return string.format("<%d,%d,%d>", r, g, b)
  end

  local last = tag()
  local out, pos = { last }, 1
  local tagAt = 1 -- index in `out` of the last tag; a tag with no text after it is overwritten
  while true do
    local s, e, params, final = text:find("\27%[([%d;]*)(%a)", pos)
    if not s then break end
    if s > pos then out[#out + 1] = text:sub(pos, s - 1) end
    pos = e + 1
    if final == "m" then
      local codes = {}
      for c in (params .. ";"):gmatch("(%d*);") do codes[#codes + 1] = tonumber(c) or 0 end
      local i = 1
      while i <= #codes do
        local c = codes[i]
        if c == 0 then
          fg, bright, rgb = DEFAULT_FG, false, nil
        elseif c == 1 then
          bright = true
        elseif c == 22 then
          bright = false
        elseif c >= 30 and c <= 37 then
          fg, rgb = c - 30, nil
        elseif c >= 90 and c <= 97 then
          fg, rgb = c - 90 + 8, nil
        elseif c == 39 then
          fg, rgb = DEFAULT_FG, nil
        elseif (c == 38 or c == 48) and codes[i + 1] == 5 then
          if c == 38 and codes[i + 2] then rgb = { rgbOf(codes[i + 2]) } end
          i = i + 2
        elseif (c == 38 or c == 48) and codes[i + 1] == 2 then
          if c == 38 and codes[i + 4] then rgb = { codes[i + 2], codes[i + 3], codes[i + 4] } end
          i = i + 4
        end
        i = i + 1
      end
      local t = tag()
      if t ~= last then
        if tagAt == #out then
          out[tagAt] = t
        else
          out[#out + 1] = t
          tagAt = #out
        end
        last = t
      end
    end
  end
  out[#out + 1] = text:sub(pos)
  return (table.concat(out):gsub("\27%[[%d;?]*%a", ""):gsub("\27", ""))
end

-- The channel of the message being shown. Text.channel arrives in the SAME payload as the talker
-- and the text; the deprecated Comm.Channel.Start arrives AFTER Text, so on the Text event it
-- still names the PREVIOUS message's channel. Reading it first (v4.7.100) coloured and routed every
-- line as the one before it. Start is a fallback for a Text with no channel only.
function ataxiagui_chatChannel()
  local c = gmcp and gmcp.Comm and gmcp.Comm.Channel
  if not c then return "" end
  local t = c.Text
  if t and type(t.channel) == "string" and t.channel ~= "" then return t.channel end
  return type(c.Start) == "string" and c.Start or ""
end

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
  local chatWindow = false
  local channel = ataxiagui_chatChannel()
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
    if string.starts(channel, chan) then
      chatWindow = wind
      break
    end
  end

  -- Override for "says" - check if it's actually a city/party tell based on text
  local detectedFromText = false
  if channel == "says" then
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
    if string.starts(channel, chan) then
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

  local coloredText = ataxiagui_chatAnsiToDecho(gmcp.Comm.Channel.Text.text)

  if person == gmcp.Char.Status.name or person == "You" then
    decho(chatWindow, coloredText .. "\n")
    if chatWindow ~= "All" then
      decho("All", coloredText .. "\n")
    end
  elseif report then
    if channel == "shout" then
      cecho(chatWindow, "<cyan> " .. person .. "<red>: ")
    end
    decho(chatWindow, coloredText .. "\n")

    if not only_to_misc and chatWindow ~= "All" then
      if channel == "shout" then
        cecho("All", "<cyan> " .. gmcp.Comm.Channel.Text.talker .. "<red>: ")
      end
      decho("All", coloredText .. "\n")
    end

    if string.find(channel:lower(), "tell") and not string.find(channel:lower(), "army") and not muteList[person] and person ~= "You" then
      ataxiaBasher_alert("Normal")
    end

  end
	only_to_misc = false	

  enableTrigger("Ataxia Chat Capture")
end

-- Register on the non-deprecated Comm.Channel.Text (carries channel+talker+text atomically);
-- Comm.Channel.Start/End are deprecated and Start lags Text by one message (see ataxiagui_chatChannel).
registerAnonymousEventHandler("gmcp.Comm.Channel.Text", "zgui.showChat")