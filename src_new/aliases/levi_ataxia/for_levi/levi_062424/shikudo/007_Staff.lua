--[[mudlet
type: alias
name: Shikudo Staff
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Shikudo
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^skstaff(?: (\S+))?$'
command: ''
packageName: ''
]]--

-- `skstaff`          -- the staff the Shikudo offense wields
-- `skstaff <item>`   -- wield this one: an item id (staff489282) or a keyword
-- `skstaff clear`    -- back to the bare keyword "staff"
-- Read by the dispatch offense (006, shikudo.staffRef) and trigger 168 (v4.7.420).
shikudo.staffCommand(matches[2])
