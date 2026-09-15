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
- pattern: ^(.+?) exudes an aura of (.+?)\.$
  type: 1
]]--

-- CONSIDER output -> the denizen resistance database (basher/001, v4.7.306). Captured live
-- 2026-09-15:
--
--   A stout footsoldier exudes an aura of overwhelming power.
--   a stout footsoldier has a significant resistance against physical cutting damage.
--   a stout footsoldier has a significant resistance against physical blunt damage.
--
-- Pattern 1 is the resistance row exactly as seen ("against"), with "to" tolerated. Pattern 2 is
-- the WEAKNESS row and has NEVER been seen -- it is the resistance row with the noun swapped, so a
-- line of that shape has somewhere to land; if the game words it differently the row stays empty
-- and nothing breaks. Pattern 3 is the aura line, which records the mob even when it resists
-- nothing. The qualifier ("significant") and the damage type ("physical cutting") are stored as
-- printed, lowercased; the name is keyed with its article stripped so "A stout footsoldier",
-- "a stout footsoldier" and gmcp's item name all land on one row.
local name = matches[2]
if not (ataxiaBasher_considerResist and name) then return end
if matches[4] then
  local isWeak = line:find(" weakness ", 1, true) ~= nil
  if isWeak then
    ataxiaBasher_considerWeakness(name, matches[3], matches[4])
  else
    ataxiaBasher_considerResist(name, matches[3], matches[4])
  end
else
  ataxiaBasher_considerAura(name, matches[3])
end
