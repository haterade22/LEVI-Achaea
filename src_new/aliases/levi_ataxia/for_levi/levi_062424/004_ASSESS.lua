--[[mudlet
type: alias
name: ASSESS
hierarchy:
- Levi_Ataxia
- General
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^assess$
command: ''
packageName: ''
]]--

-- Asked for by hand, so the trait gate (misc_scripts/031) does not remove it (v4.7.456).
local sendRaw = ataxia_rawSend or send
sendRaw("assess " .. target)