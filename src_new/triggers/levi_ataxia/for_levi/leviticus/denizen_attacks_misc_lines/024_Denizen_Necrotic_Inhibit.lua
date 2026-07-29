--[[mudlet
type: trigger
name: Denizen Necrotic Inhibit
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
- pattern: ^Your sickening aura of death empowers your attack, denying vitality from suffusing
    your foe\.$
  type: 1
]]--

-- NECROTIC AURA proc (Mnemosyne boon, live capture 2026-07-29): our attack infected the
-- denizen, so it cannot heal. That is exactly the `inhibit` state the denizen-state layer
-- already models (basher/008_Denizen_State, BR_AFFS.inhibit -- Monk's Ripplestrike is the
-- other source), so record it here too: it stops a second inhibit being spent on a mob
-- that already has one, and it is the direct counter to the self-healing denizens that
-- otherwise out-heal a slow kill ("...ceases tending to his wounds").
--
-- The line names no target, so it applies to whatever we just hit -- our current target.
if type(target) == "number" and ataxiaBasher and ataxiaBasher.enabled and ataxiaBasher_dsSetAff then
	ataxiaBasher_dsSetAff(target, "inhibit")
end

selectString(line, 1)
fg("medium_sea_green")
deselect()
resetFormat()
