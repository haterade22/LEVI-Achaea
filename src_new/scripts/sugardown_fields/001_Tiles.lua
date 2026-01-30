--[[mudlet
type: script
name: Tiles
hierarchy:
- Sugardown Fields
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

sugardown = sugardown or {}
sugardown.betsByRacer = {}

-- toggle: true = click sends immediately, false = click fills input line
local AUTOSEND = true

-- layout
local TILE_WIDTH  = 30
local TILE_HEIGHT = 8
local COLUMNS     = 2
local GAP         = "  "

-- bet button
local BET_BTN_TEXT = "<black:gold>  Bet  <reset>"
local BET_SPACER   = "  "
local RIGHT_PAD    = 2

-- utils
local function stripColors(s)
  return tostring(s or ""):gsub("<.->", "")
end

local function pad(s, len)
  s = tostring(s or "")
  local n = #stripColors(s)
  if n >= len then return s:sub(1, len) end
  return s .. string.rep(" ", len - n)
end

-- put command in input
function sugardown.putInCmdLine(cmd)
  if type(clearCmdLine) == "function" then clearCmdLine() end
  if type(appendCmdLine) == "function" then appendCmdLine(cmd) end
end

-- click handler
function sugardown.bet(name, betType, amount)
  name    = tostring(name or "")
  betType = tostring(betType or "win")
  amount  = tonumber(amount) or 1

  local cmd = string.format("racetrack bet %d ticket on %s to %s", amount, name, betType)

  if AUTOSEND then
    send(cmd)
  else
    sugardown.putInCmdLine(cmd)
  end
end

-- render helpers
local function lineBox(text, w)
  cecho("│")
  cecho(pad(text, w))
  cecho("│")
end

local function lineBet(label, credits, betType, name, w)
  local left = string.format("%s %s cr", label, credits or 0)

  local btnLen   = #stripColors(BET_BTN_TEXT)
  local leftRoom = w - btnLen - RIGHT_PAD - #BET_SPACER
  if leftRoom < 1 then leftRoom = 1 end

  cecho("│")
  cecho(pad(left, leftRoom))
  cecho(BET_SPACER)

  local clickCmd = string.format([[sugardown.bet(%q, %q)]], name or "", betType or "win")

  cechoLink(
    BET_BTN_TEXT,
    clickCmd,
    "Bet on " .. (name or "") .. " to " .. (betType or "win"),
    true
  )

  cecho(string.rep(" ", RIGHT_PAD))
  cecho("│")
end

-- main render
function sugardown.renderHumgiiTiles()
  if not racetrackList then return end
  if not humgiiList or #humgiiList == 0 then return end
  racetrackList = false

  cecho("\n")
  local w = TILE_WIDTH - 2

  for i = 1, #humgiiList, COLUMNS do
    local row = {}
    for c = 0, COLUMNS - 1 do
      local h = humgiiList[i + c]
      if h then row[#row + 1] = h end
    end

    for line = 1, TILE_HEIGHT + 1 do
      for t = 1, #row do
        local h = row[t]

        if line == 1 then
          cecho("┌" .. string.rep("─", TILE_WIDTH - 2) .. "┐")

        elseif line == 2 then
          lineBox(
            string.format("<gold>%s<reset> <white>(%s)<reset>", h.name or "", h.points or ""),
            w
          )

        elseif line == 3 then
          lineBox(
            string.format("<cyan>%s<reset> <white>(%s)<reset>", h.jockey or "", h.jockeyPts or ""),
            w
          )

        elseif line == 4 then
          lineBet("<green>W:<reset>", h.winCr, "win", h.name, w)

        elseif line == 5 then
          lineBet("<yellow>P:<reset>", h.placeCr, "place", h.name, w)

        elseif line == 6 then
          lineBet("<magenta>S:<reset>", h.showCr, "show", h.name, w)

        elseif line == 7 then
          lineBox("", w)

        elseif line == 8 then
          cecho("└" .. string.rep("─", TILE_WIDTH - 2) .. "┘")
        end

        if t < #row then cecho(GAP) end
      end
      cecho("\n")
    end

    cecho("\n")
  end
end
