--[[mudlet
type: alias
name: Mounts
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Lists
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bash mounts ?(.*)$
command: ''
packageName: ''
]]--

-- Our own mounts, which the basher must never treat as denizens (v4.7.335).
--   bash mounts        - what has been learned, by id
--   bash mounts clear  - forget them all (a sold mount, or a bad reading)
-- Learned passively: list your mounts in game and the rows are read. They are skipped BY ID, so a
-- wild denizen of the same species is still a target.
local arg = (matches[2] or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()

if arg == "clear" then
  ataxiaBasher_mountsClear()
else
  ataxiaBasher_mountsReport()
end
