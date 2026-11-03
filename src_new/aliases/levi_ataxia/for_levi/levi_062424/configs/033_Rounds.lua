--[[mudlet
type: alias
name: Rounds
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aconfig rounds(?: (alias|raw))?$
command: ''
packageName: ''
]]--

-- `aconfig rounds`        -- show the setting.
-- `aconfig rounds alias`  -- send each round as one server alias (ataxia/003). Monk only for now, with
--                            one group fight behind it so far.
-- `aconfig rounds raw`    -- send rounds as before. This is the default.
ataxia_roundCommand(matches[2])
