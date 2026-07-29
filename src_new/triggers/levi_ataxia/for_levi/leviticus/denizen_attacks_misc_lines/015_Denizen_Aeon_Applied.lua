--[[mudlet
type: trigger
name: Denizen Aeon Applied
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
- Denizen Attacks / Misc Lines
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: Your foe blurs and begins to move slower in time.
  type: 3
- pattern: ^Bending your formidable will upon (.+), you slow the passage of time about \w+ to a
    crawl\.$
  type: 1
]]--

-- Aeon landed on our current target -- the denizen attacks at 66% speed for ~6s (a
-- mitigation aff; no bonus-damage exploit). Record it. Denizen + basher only.
--
-- The second pattern is the Depthswalker CHRONO CURSE fire line, captured live
-- 2026-07-29 ("Bending your formidable will upon a steel-encased Death Knight, you slow
-- the passage of time about him to a crawl."). It is the first confirmed `apply` line for
-- denizen aeon in the whole system -- BR_AFFS.aeon.apply was nil for every class. It also
-- CONFIRMS the cast so the DW rotation restarts curse's 35s cooldown from the landed
-- moment and releases its in-flight hold.
if type(target) == "number" and ataxiaBasher and ataxiaBasher.enabled and ataxiaBasher_dsSetAff then
  ataxiaBasher_dsSetAff(target, "aeon")
  if ataxiaBasher_dwConfirm and line:find("Bending your formidable will", 1, true) then
    ataxiaBasher_dwConfirm("curse")
  end
  if ataxiaBasher_dsAlert then
    ataxiaBasher_dsAlert("AEON on " .. tostring(target) .. " -- mob attacks slower", "yellow")
  end
end
