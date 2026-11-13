--[[mudlet
type: alias
name: Artefact
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aconfig artefacts?(?: (.+))?$
command: ''
packageName: ''
]]--

-- `aconfig artefact`                   -- what we own that changes a number, and which code reads it
-- `aconfig artefact scan`              -- send ARTEFACT POWER LIST OWNED and save the answer
-- `aconfig artefact <power> off`       -- treat an owned power as absent (e.g. a diadem not worn)
-- `aconfig artefact <power> on [lvl]`  -- treat a power as owned (a borrowed artefact)
-- `aconfig artefact <power> auto`      -- back to what the list says
-- Script: misc_scripts/033_Artefacts.lua.
if ataxia_artefactCommand then ataxia_artefactCommand(matches[2]) end
