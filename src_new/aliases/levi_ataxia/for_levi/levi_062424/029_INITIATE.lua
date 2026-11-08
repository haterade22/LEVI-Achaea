--[[mudlet
type: alias
name: INITIATE
hierarchy:
- Levi_Ataxia
- General
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^init$
command: ''
packageName: ''
]]--

-- No revision of this repo defines svo_init_system(); guarded, because this alias only threw.
if svo_init_system then svo_init_system() end