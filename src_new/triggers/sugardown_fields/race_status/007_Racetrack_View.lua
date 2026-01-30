--[[mudlet
type: trigger
name: Racetrack View
hierarchy:
- Sugardown Fields
- Race Status
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: '^\d+(?:st|nd|rd|th):\s+(.+?)\s+\(rider:'
  type: 1
]]--

local humgiiName = matches[2]

local place
if line:find("^1st:") then
  place = 1
elseif line:find("^2nd:") then
  place = 2
elseif line:find("^3rd:") then
  place = 3
else
  place = 4
end

local b = (sugardown.betsByRacer or {})[humgiiName]
if not b then return end

local winAmt   = tonumber(b.winAmt) or 0
local placeAmt = tonumber(b.placeAmt) or 0
local showAmt  = tonumber(b.showAmt) or 0
if winAmt == 0 and placeAmt == 0 and showAmt == 0 then return end

local crWin, crPlace, crShow
if humgiiList then
  for _, h in ipairs(humgiiList) do
    if h.name == humgiiName then
      crWin   = tonumber(h.winCr)
      crPlace = tonumber(h.placeCr)
      crShow  = tonumber(h.showCr)
      break
    end
  end
end

local function payoutForType(t)
  if t == "win" then
    if winAmt <= 0 or place ~= 1 then return nil end
    if not crWin or crWin <= 0 then return nil end
    return winAmt * crWin
  elseif t == "place" then
    if placeAmt <= 0 or place > 2 then return nil end
    if not crPlace or crPlace <= 0 then return nil end
    return placeAmt * crPlace
  elseif t == "show" then
    if showAmt <= 0 or place > 3 then return nil end
    if not crShow or crShow <= 0 then return nil end
    return showAmt * crShow
  end
end

local pWin   = payoutForType("win")
local pPlace = payoutForType("place")
local pShow  = payoutForType("show")

local payout
local function consider(v)
  if v and ((not payout) or v > payout) then payout = v end
end
consider(pWin)
consider(pPlace)
consider(pShow)

local pays = payout ~= nil

if selectString(humgiiName, 1) == -1 then return end
if pays then fg("PaleGreen") else fg("IndianRed") end
resetFormat()

if payout then
  cecho(string.format("  <white>(payout: %d cr)<reset>", payout))
end

do
  local parts = {}
  if winAmt > 0   then parts[#parts + 1] = "<green>W<reset>" end
  if placeAmt > 0 then parts[#parts + 1] = "<yellow>P<reset>" end
  if showAmt > 0  then parts[#parts + 1] = "<magenta>S<reset>" end

  if #parts > 0 then
    cecho("  <white>[" .. table.concat(parts, " ") .. "]<reset>")
  end
end
