--[[mudlet
type: trigger
name: Applied Torso
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
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
- pattern: ^(\w+) takes some salve from a vial and rubs it on \w+ torso.$
  type: 1
- pattern: ^(\w+) takes some salve from a vial and rubs it on \w+ body\.$
  type: 1
]]--

if isTargeted(matches[2]) then
  -- restore passive cures if needed
  if passiveFailsafe then restorePassiveCure() end

  -- Before the erase, which would leave the branches this proof rules out standing (007).
  if proveAffAbsentV3 then proveAffAbsentV3("slickness", "salve") end
  -- slickness and bloodfire always applied
  erAff("slickness")
  erAff("bloodfire")

  -- Central crushedthroat check (head apply could have been pending)
  if ataxiaTemp.crushedCheck and ataxiaTemp.crushedCheck.pending then
      local now = getEpoch()
      if now - ataxiaTemp.crushedCheck.lastApply < 1.2 then
          if haveAff("crushedthroat") then
              erAff("crushedthroat")
          end
          killTimer(ataxiaTemp.crushedCheck.timer)
          ataxiaTemp.crushedCheck.pending = false
          ataxiaTemp.crushedCheck.timer = nil
          target_salveBal(1.1)
      end
  end

  local salvetimer = false
  -- The torso's damage from the limb counter (lb, limb/002), read before this application
  -- changes it: lb.salve (trigger limb/003) resets a broken torso 4.0 s after the line, so the
  -- branches below do not reset it themselves. This read the global tLimbs, which nothing defines
  -- since it was removed, so every body or torso application without hypothermia raised an error
  -- here. With a calcified torso, 391 leaves the application to this trigger, so nothing counted
  -- the restoration down.
  local L = lb and lb[target] and lb[target].hits
  local torso = (L and L.torso) or 0

  -- Hypothermia logic
  if haveAff("hypothermia") then
      if haveAff("timeflux") then
          tempTimer(6.5, function()
              erAff("hypothermia")
              ataxia_boxEcho("they cured hypothermia", "DodgerBlue")
          end)
          salvetimer = 6.5
      else
          tempTimer(3.5, function()
              erAff("hypothermia")
              ataxia_boxEcho("they cured hypothermia", "DodgerBlue")
          end)
          salvetimer = 3.5
      end

  -- Scalded + Calcified Torso
  elseif haveAff("scalded") and haveAff("calcifiedtorso") and torso <= 199 then
      tempTimer(6.5, function()
          erAff("calcifiedtorso")
          ataxia_boxEcho("they cured Torso Damage", "DodgerBlue")
      end)
      salvetimer = 6.5
  elseif haveAff("scalded") and haveAff("calcifiedtorso") and torso >= 200 then
      tempTimer(6.5, function()
          erAff("calcifiedtorso")
          ataxia_boxEcho("they cured ******* Lvl 2 Torso *****", "DodgerBlue")
      end)
      salvetimer = 6.5

  -- Calcified torso only (no scald)
  elseif haveAff("calcifiedtorso") and not haveAff("scalded") and torso <= 199 then
      tempTimer(4, function()
          erAff("calcifiedtorso")
          ataxia_boxEcho("they cured Torso Damage", "DodgerBlue")
      end)
      salvetimer = 3.5
  elseif haveAff("calcifiedtorso") and not haveAff("scalded") and torso >= 200 then
      tempTimer(4, function()
          erAff("calcifiedtorso")
          ataxia_boxEcho("they cured ******* Lvl 2 Torso *****", "DodgerBlue")
      end)
      salvetimer = 3.5

  -- Normal torso break checks (lb.salve resets the counter itself)
  elseif torso >= 98 then
      salvetimer = 3.5
  end

  -- Apply salve balance if any timer was set
  if salvetimer ~= false then
      target_salveBal(salvetimer)
  end

  -- Target still present
  targetIshere = true
end