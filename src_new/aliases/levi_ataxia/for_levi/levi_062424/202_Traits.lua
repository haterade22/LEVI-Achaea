--[[mudlet
type: alias
name: Traits
hierarchy:
- Levi_Ataxia
- General
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^traits(?: (show))?$'
command: ''
packageName: ''
]]--

-- `traits`       -- read TRAIT LIST KNOWN again (triggers 792/793 keep it, saved)
-- `traits show`  -- what is saved, and whether ASSESS / CONTEMPLATE are free (misc_scripts/031)
ataxia_traitCommand(matches[2])
