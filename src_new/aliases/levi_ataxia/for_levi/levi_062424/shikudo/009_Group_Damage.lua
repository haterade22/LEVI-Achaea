--[[mudlet
type: alias
name: Shikudo Group Damage
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Shikudo
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^srd$'
command: ''
packageName: ''
]]--

-- `srd` -- one round of the Shikudo group damage route (shikudo/013, v4.7.456). `sr` is the lock
-- (007). The user: "sr should be lock, srd should be damage".
-- Class guard: Serpent also owns `srd` (serpent/006), and Mudlet fires every matching alias.
if gmcp.Char.Status.class == "Monk" then
  shikudoDmg.group()
end
