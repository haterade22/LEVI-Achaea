--[[mudlet
type: alias
name: Metabolise
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aconfig metabolise(?: (\w+))?$
command: ''
packageName: ''
]]--

-- `aconfig metabolise`         -- which affliction defup metabolises, and whether the game confirmed it.
-- `aconfig metabolise <aff>`   -- change it (default paralysis) and send it now.
-- `aconfig metabolise off`     -- stop sending it on defup/login.
-- Not a bare `metabolise`: that would swallow the game command.
ataxia_setMetabolise(matches[2])
if matches[2] then ataxia_saveSettings(false) end
