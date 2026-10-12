--[[mudlet
type: trigger
name: Kai Surge
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Monk
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
- pattern: ^As the power of your kai builds within you, you lift a hand towards (\w+)\.
  type: 1
]]--

if isTargeted(matches[2]) then
  erAff("shield")
  selectString(line, 1)
  setBold(true)
  fg("violet")
  resetFormat()
  tarAffed("prone")

  -- Mount lockout window: the target cannot remount, so TK6 sweeps and punches its parried limb
  -- (tekura/002 buildPrepAttack). 15 s has no source -- the wiki says only "The effect will fade
  -- over time" (Kaido.wiki:322) -- so it is kept as the code's own guess. Each surge restarts the
  -- window: the last surge's timer is killed first, or it would close this window early. Its id
  -- lives on ataxiaTemp, which is never saved (a saved id names a stranger's timer after a reload).
  -- kaiSurgeWho is whom the surge holds down: TK6 skips its dismount for that target only.
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.kaiSurgeWindow = true
  ataxiaTemp.kaiSurgeWho = matches[2]
  if ataxiaTemp.kaiSurgeTimer then killTimer(ataxiaTemp.kaiSurgeTimer) end
  ataxiaTemp.kaiSurgeTimer = tempTimer(15, function()
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.kaiSurgeWindow = false
    ataxiaTemp.kaiSurgeWho = nil
    ataxiaTemp.kaiSurgeTimer = nil
    cecho("\n<yellow>[Monk] Kai Surge mount window expired")
  end)
end

if partyrelay and not ataxia.afflictions.aeon then
  send("pt " .. matches[2] .. ": Kai Surged (prone)")
end
