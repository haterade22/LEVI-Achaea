--[[mudlet
type: script
name: Sylvan Propagation
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Offensive Things
- Limb Management
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- The affliction a Sylvan's thornrend carries from the herb propagated into OUR ARMS, or false.
-- Restored 2026-11-08 from the old "Sylvan Limbcounting" script, which 3c312975 (2026-03-16)
-- deleted with the tLimbs counters while the thornrend triggers (sylvan/014, 015) still called
-- it: each thornrend line threw before any affliction was recorded. Only this helper came back;
-- the old sylvan_hitLimb wrote the deleted tLimbs table, and lb tracks limb damage now.
--
-- ataxiaTemp.currentProps is filled by the `prop` alias (sylvan_things/003) and the queue
-- scanner (misc_scripts/001); before the first `prop` it does not exist, so that reads as none.
local PROPAGATED_AFF = {
  kelp = "healthleech",
  bellwort = "weariness",
  valerian = "slickness",
  lobelia = "vertigo",
  elm = "dizziness",
  goldenseal = "epilepsy",
  hawthorn = "sensitivity",
}

function sylvan_propagateAff()
  local props = ataxiaTemp and ataxiaTemp.currentProps
  local arm = props and props.arms
  return arm and PROPAGATED_AFF[arm] or false
end
