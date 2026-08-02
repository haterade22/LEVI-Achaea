--[[mudlet
type: script
name: Vulture Talon
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Curing Stuff
- Priority-related
- Swaps
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- Vulture's Talon: SCRATCH MYSELF WITH TALON for caloric defense
-- Fires when shivering/frozen gained vs Blademaster or Magi while off salve balance.
-- Toggle: ataxia.settings.user.artefacts.talon = true/false

-- CONFIG ONLY on the saved namespace. `ataxia` is serialized wholesale
-- (`table.save(file_loc, sanitizeForSave(ataxia))`) and deepMerged back with an
-- unconditional `dst[k] = v`, so anything transient stored here comes back from disk
-- exactly as it was when we last saved -- while the tempTimer that was supposed to clear
-- it does NOT survive a relog or a SYSUPDATE package reload.
--
-- That is what `onCooldown = true` + `cooldownTimer = <id>` did (v4.7.194): save while the
-- talon was cooling down, and it reloaded permanently on cooldown with nothing alive to
-- reset it -- the artefact silently never fired again. The stale `cooldownTimer` integer
-- was the second half of it, since `killTimer` would then aim at whatever timer had since
-- been handed that id.
ataxia.vultureTalon = ataxia.vultureTalon or {}
if ataxia.vultureTalon.cooldownDuration == nil then
  ataxia.vultureTalon.cooldownDuration = 180 -- 3 minutes; adjust after in-game testing
end
-- Legacy transient keys from before the split; drop them so a saved `true` cannot
-- resurrect the permanent-cooldown state on the next load.
ataxia.vultureTalon.onCooldown, ataxia.vultureTalon.cooldownTimer = nil, nil

-- Reload-safe cooldown: a TIMESTAMP on ataxiaTemp, the convention every other
-- fire-line-less cooldown in this package uses (bmHeadstrikeReadyAt, rwBrAt, ...).
-- Worst case after a reload is one early re-use, never a permanent lockout.
function ataxia_vultureTalonReady()
  local at = tonumber(ataxiaTemp and ataxiaTemp.vultureTalonAt)
  if not at then return true end
  local dur = tonumber(ataxia.vultureTalon.cooldownDuration) or 180
  return ((getEpoch and getEpoch() or 0) - at) >= dur
end

function ataxia_tryVultureTalon()
  -- Gate 1: artefact enabled
  if not ataxia.getArtefact("talon") then return end
  -- Gate 2: not on cooldown
  if not ataxia_vultureTalonReady() then return end
  -- Gate 3: must have shivering or frozen
  if not affed("shivering") and not affed("frozen") then return end
  -- Gate 4: class filter — only vs Blademaster or Magi
  local tc = ataxiaNDB_getClass(target)
  if tc ~= "Blademaster" and tc ~= "Magi" then return end
  -- Gate 5: off salve balance
  if ataxia.bals.used.salve then return end

  -- Fire. Stamped on SEND, which is the same trade every fire-line-less ability in this
  -- package makes: the talon's success and refusal lines have never been captured, so
  -- there is nothing to confirm against. Believing it fired when it did not costs one
  -- missed re-use that self-corrects; the reverse would spam a refused command.
  send("scratch myself with talon")
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.vultureTalonAt = (getEpoch and getEpoch()) or 0
  Algedonic.Echo("<LightSkyBlue>Vulture's Talon<white> used for caloric defense.")
end
