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

ataxia.vultureTalon = ataxia.vultureTalon or {
  onCooldown = false,
  cooldownTimer = nil,
  cooldownDuration = 20,  -- seconds; adjust after in-game testing
}

function ataxia_tryVultureTalon()
  -- Gate 1: artefact enabled
  if not ataxia.getArtefact("talon") then return end
  -- Gate 2: not on cooldown
  if ataxia.vultureTalon.onCooldown then return end
  -- Gate 3: must have shivering or frozen
  if not affed("shivering") and not affed("frozen") then return end
  -- Gate 4: class filter — only vs Blademaster or Magi
  local tc = ataxiaNDB_getClass(target)
  if tc ~= "Blademaster" and tc ~= "Magi" then return end
  -- Gate 5: off salve balance
  if ataxia.bals.used.salve then return end

  -- Fire
  send("scratch myself with talon")
  ataxia.vultureTalon.onCooldown = true

  if ataxia.vultureTalon.cooldownTimer then
    killTimer(ataxia.vultureTalon.cooldownTimer)
  end
  ataxia.vultureTalon.cooldownTimer = tempTimer(
    ataxia.vultureTalon.cooldownDuration,
    function()
      ataxia.vultureTalon.onCooldown = false
      ataxia.vultureTalon.cooldownTimer = nil
    end
  )
  Algedonic.Echo("<LightSkyBlue>Vulture's Talon<white> used for caloric defense.")
end
