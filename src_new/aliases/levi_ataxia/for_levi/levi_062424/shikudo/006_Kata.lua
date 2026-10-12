--[[mudlet
type: alias
name: Kata Caps
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Shikudo
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^skata(?: (\w+)(?: (\w+))?)?$'
command: ''
packageName: ''
]]--

-- `skata`                  -- every form's kata cap: the chain after the combo at which it is left
-- `skata <form>`           -- one form's cap
-- `skata <form> <n>`       -- override it (warns past the longest chain seen without a stumble)
-- `skata <form> default`   -- drop the override
-- The caps are policy, not game limits (monk/004, ataxia_KATA); only overrides are saved.
ataxia_kataCommand(matches[2], matches[3])
