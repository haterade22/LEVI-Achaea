--[[mudlet
type: trigger
name: Real Exits
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: ^You see (?:a single exit|exits) leading (.+)\.$
  type: 1
]]--

-- The room's REAL exits, taken from the text.
--
-- This line is TRUE even under the Mnemosyne boon "Creville's Legacy" (attack 20% faster,
-- INCURABLE dementia), which fabricates the rest of the room wholesale. Observed in a ripple:
-- the room rendered as "Within the hills." with a Neraeos/ocean description and gmcp reported
-- exits {n=773, nw=797, sw=775, w=798} (a real Northern Ithmia room) -- while this line said
-- "north and south", which is what actually existed. gmcp.Room.Info.exits is therefore NOT a
-- usable adjacency source in the tower; this is. Everything that has to navigate a ripple
-- (the 4x4 sweep) must read these rather than gmcp's.
--
-- Kept in ataxiaTemp (never serialized) since it describes only the room we are standing in.
local SHORT = {
  north = "n", south = "s", east = "e", west = "w",
  northeast = "ne", northwest = "nw", southeast = "se", southwest = "sw",
  up = "up", down = "down", inwards = "in", outwards = "out",
}

ataxiaTemp = ataxiaTemp or {}
local exits = {}
local n = 0
-- gmatch over words also yields the "and"/"a"/"single" filler, which simply isn't in SHORT.
for word in matches[2]:gmatch("%a+") do
  local d = SHORT[word:lower()]
  if d and not exits[d] then
    exits[d] = true
    n = n + 1
  end
end

if n > 0 then
  ataxiaTemp.realExits = exits
  ataxiaTemp.realExitsAt = getEpoch()
end
