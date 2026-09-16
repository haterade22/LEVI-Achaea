--[[mudlet
type: trigger
name: Consider Lines
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
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
- pattern: ^(.+?) has (?:an? )?(\w+) resistance (?:against|to) (.+?) damage\.$
  type: 1
- pattern: ^(.+?) has (?:an? )?(\w+) weakness (?:against|to) (.+?) damage\.$
  type: 1
- pattern: ^(.+?) (?:exudes an aura of|has an air of) (.+?)\.$
  type: 1
- pattern: ^Sentience governs this creature's actions\.$
  type: 1
- pattern: ^(?:He|She|It|They) (?:has|have) (\d+)% health remaining\.$
  type: 1
]]--

-- CONSIDER output -> the denizen resistance database (basher/001, v4.7.306), and HIGHLIGHTED
-- (v4.7.310, user: "Please highlight these lines to make it easier to read"). Two blocks captured
-- live:
--
--   A stout footsoldier exudes an aura of overwhelming power.        (2026-09-15)
--   Sentience governs this creature's actions.
--   He has 86% health remaining.
--   a stout footsoldier has a significant resistance against physical cutting damage.
--   a stout footsoldier has a significant resistance against physical blunt damage.
--
--   A blood-spattered jester has an air of extreme strength.         (2026-09-16)
--   Sentience governs this creature's actions.
--   He has 77% health remaining.
--   a blood-spattered jester has a significant resistance against psychic damage.
--
-- THE STRENGTH LINE HAS AT LEAST TWO GRAMMARS -- "exudes an aura of <x>" and "has an air of <x>"
-- -- so pattern 3 names both; a third wording would leave that mob unrecorded until seen, so
-- paste any new one. Pattern 1 is the resistance row as seen ("against"), "to" tolerated. Pattern
-- 2 is the WEAKNESS row and has never been seen: the resistance row with the noun swapped, so a
-- line of that shape has somewhere to land. The qualifier ("significant") and the damage type
-- ("physical cutting", "psychic") are stored as printed, lowercased; the name is keyed with its
-- article stripped so "A blood-spattered jester", "a blood-spattered jester" and gmcp's item name
-- land on one row.
--
-- COLOURS (every name verified in 007_Custom_Colour_Table, which replaces Mudlet's): strength
-- line `gold` bold -- the threat read; resistance `indian_red` bold -- the thing to route
-- around; weakness `spring_green` bold -- the thing to exploit; sentience `dim_grey` -- noise;
-- health `gold` -- part of the same read.
local function paint(colour, bold)
  selectString(line, 1)
  fg(colour)
  if bold then setBold(true) end
  deselect()
  resetFormat()
end

local name = matches[2]
if matches[4] and line:find(" weakness ", 1, true) then
  paint("spring_green", true)
  if ataxiaBasher_considerWeakness then ataxiaBasher_considerWeakness(name, matches[3], matches[4]) end
elseif matches[4] then
  paint("indian_red", true)
  if ataxiaBasher_considerResist then ataxiaBasher_considerResist(name, matches[3], matches[4]) end
elseif line:find("Sentience governs", 1, true) then
  paint("dim_grey", false)
elseif line:find("% health remaining", 1, true) then
  paint("gold", false)
elseif matches[3] then
  paint("gold", true)
  if ataxiaBasher_considerAura then ataxiaBasher_considerAura(name, matches[3]) end
end
