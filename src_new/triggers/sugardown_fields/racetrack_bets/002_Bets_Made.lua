--[[mudlet
type: trigger
name: Bets Made
hierarchy:
- Sugardown Fields
- Racetrack Bets
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'yes'
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
- pattern: ^(.+?)\s{2,}(.+?)\s{2,}(\d+)\s{2,}(Win|Place|Show)\s*$
  type: 1
]]--

local track    = (matches[2] or ""):gsub("%s+$","")
local racer    = (matches[3] or ""):gsub("%s+$","")
local tickets  = tonumber(matches[4]) or 0
local posWord  = matches[5]

sugardown.betsByRacer = sugardown.betsByRacer or {}

local b = sugardown.betsByRacer[racer] or {
  win = false, place = false, show = false,
  winAmt = 0, placeAmt = 0, showAmt = 0,
  track = track,
}
b.track = track

if posWord == "Win" then
  b.win = true
  b.winAmt = tickets
elseif posWord == "Place" then
  b.place = true
  b.placeAmt = tickets
elseif posWord == "Show" then
  b.show = true
  b.showAmt = tickets
end

sugardown.betsByRacer[racer] = b
