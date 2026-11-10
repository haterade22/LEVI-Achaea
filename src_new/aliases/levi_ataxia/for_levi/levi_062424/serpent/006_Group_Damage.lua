--[[mudlet
type: alias
name: Serpent Group Damage
hierarchy:
- Levi_Ataxia
- Classes
- Serpent
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^srd$
command: ''
packageName: ''
]]--

-- `srd` -- one round of the Serpent group damage route: scytherus mode, which builds addiction +
-- nausea, delivers scytherus, then bites it for camus damage. `sr` is the group lock route.
-- The user: "the goal of this should be damage route with camus and scytherus".
-- Shikudo has its own `srd` (shikudo/009); each alias checks the class, so only one acts.
if gmcp.Char.Status.class == "Serpent" then
  serp_setmode_scytherus()
  serp_ekanelia_offense()
end
