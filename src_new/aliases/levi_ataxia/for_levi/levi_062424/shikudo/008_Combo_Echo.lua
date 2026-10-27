--[[mudlet
type: alias
name: Shikudo Combo Echo
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Shikudo
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^skecho(?: (on|off))?$'
command: ''
packageName: ''
]]--

-- `skecho`          -- show whether each combo ends with its [SK] summary line
-- `skecho on|off`   -- turn it on or off (saved). Off also gags our strike lines in PvP again.
-- The line and how it is read: shikudo/012 (v4.7.456).
shikudoEcho.command(matches[2])
