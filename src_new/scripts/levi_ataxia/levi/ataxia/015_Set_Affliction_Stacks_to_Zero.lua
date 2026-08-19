--[[mudlet
type: script
name: Set Affliction Stacks to Zero
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- Drives off ataxia_stackAffs() (004_Aff_gains_losses.lua), the single owner of the list. The hand-written copy this replaces had drifted twice: `temperedcholeric` was
-- MISSING, so an alchemist's fourth humour was never reset, and `burns` was a name nothing
-- else in the package uses.
function setafflictionstackslevi()
  ataxia.afflictions = ataxia.afflictions or {}
  if not ataxia_stackAffs then
    -- Load order broke. Saying so beats resetting nothing and looking like it worked --
    -- which is the exact failure this rewrite existed to remove.
    if ataxiaEcho then ataxiaEcho("stack reset skipped: ataxia_stackAffs is not loaded") end
    return
  end
  for _, aff in ipairs(ataxia_stackAffs()) do
    ataxia.afflictions[aff] = 0
  end
end
