--[[mudlet
type: alias
name: Relay Limbs
hierarchy:
- Levi_Ataxia
- General
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^relaylimbs(?: (on|off))?$'
command: ''
packageName: ''
]]--

-- `relaylimbs`         -- show whether each limb hit is called to the party ("Hit X left arm for 9.2%")
-- `relaylimbs on|off`  -- set it (saved). Unset: off for a Monk, on for other classes (misc_scripts/031).
ataxia_relayLimbsCommand(matches[2])
