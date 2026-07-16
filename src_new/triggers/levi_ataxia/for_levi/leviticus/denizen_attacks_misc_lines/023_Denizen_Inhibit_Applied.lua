--[[mudlet
type: trigger
name: Denizen Inhibit Applied
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
- pattern: ^You quickly strike (.+) with the tips of your fingers, targeting specific nerves\.$
  type: 1
]]--

-- Our Ripplestrike (RPST, 25 rage) landed -> the denizen has INHIBIT (cannot heal, 9s).
-- This is the anti-healer tool: it is what the Mnemosyne "Sanguine Restoration" affix ("Pools
-- of blood shall heal nearby denizens.") is answered with -- see ataxiaBasher_monkBattlerage.
--
-- Also stamps Ripplestrike's cooldown from the REAL fire. Nothing else tracks it: there is no
-- shared battleRage_Timers entry for `specialafflict` (330/331/332 only cover small/large/
-- special), so without this the rotation would re-fire RPST on every attack while healing was
-- up and waste the rage on a 27s cooldown it cannot see. TIMESTAMP, not a tempTimer id, so a
-- stale value just expires after a reload rather than skipping the ability forever.
--
-- Denizen + basher only (numeric target guards it out of PvP).
if type(target) == "number" and ataxiaBasher and ataxiaBasher.enabled then
  if ataxiaBasher_dsSetAff then ataxiaBasher_dsSetAff(target, "inhibit") end
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.monkRipplestrikeReadyAt = getEpoch() + 27
  if ataxiaBasher_dsAlert then
    ataxiaBasher_dsAlert("INHIBIT on " .. tostring(target) .. " -- mob cannot heal (9s)", "orange_red")
  end
end
